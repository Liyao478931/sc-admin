<template>
  <el-dialog :title="pointId ? '编辑打卡点' : '新增打卡点'" :visible.sync="visible" width="720px" :close-on-click-modal="false" @closed="reset">
    <el-form ref="formRef" :model="form" :rules="rules" label-width="90px" size="small">
      <!-- 基础信息 -->
      <el-form-item label="打卡点名称" prop="point_name">
        <el-input v-model="form.point_name" placeholder="请输入打卡点名称" maxlength="100" />
      </el-form-item>
      <el-form-item label="详细地址" prop="address">
        <el-input v-model="form.address" placeholder="请输入详细地址">
          <template slot="append">
            <el-button size="mini" :loading="locating" @click="getCurrentLocation">📍 获取当前位置</el-button>
          </template>
        </el-input>
      </el-form-item>
      <div class="addr-actions">
        <el-button size="mini" :loading="searching" @click="searchAddress" icon="el-icon-search">地址搜索定位</el-button>
        <span class="addr-hint">或输入地址后点击「地址搜索定位」；「获取当前位置」使用浏览器定位</span>
      </div>

      <!-- 地图选点 -->
      <el-form-item label="地图选点">
        <div class="map-wrap">
          <div id="pointMap" class="map-container"></div>
          <div class="map-tip">拖动红色标记选择打卡点位置，或使用上方按钮自动定位</div>
        </div>
      </el-form-item>

      <!-- 经纬度 -->
      <el-form-item label="经纬度">
        <div class="lnglat-row">
          <el-input :value="form.latitude" readonly placeholder="纬度">
            <template slot="prepend">纬度</template>
          </el-input>
          <el-input :value="form.longitude" readonly placeholder="经度">
            <template slot="prepend">经度</template>
          </el-input>
        </div>
      </el-form-item>

      <!-- 打卡配置 -->
      <el-row :gutter="12">
        <el-col :span="12">
          <el-form-item label="打卡半径" prop="radius">
            <el-input-number v-model="form.radius" :min="100" :max="3000" :step="50" style="width:100%" />
            <span class="unit">米</span>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="打卡时间">
            <el-time-picker v-model="timeRange" is-range range-separator="-" start-placeholder="开始" end-placeholder="结束"
              format="HH:mm" value-format="HH:mm" style="width:100%" />
          </el-form-item>
        </el-col>
      </el-row>
      <el-form-item label="有效星期">
        <el-checkbox-group v-model="form.weekdays">
          <el-checkbox v-for="w in weekOptions" :key="w.value" :label="w.value">{{ w.label }}</el-checkbox>
        </el-checkbox-group>
      </el-form-item>
      <el-form-item label="关联部门">
        <el-select v-model="form.department_ids" multiple filterable collapse-tags clearable placeholder="留空表示全部部门" style="width:100%">
          <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
        </el-select>
        <div class="form-hint">仅选中的部门员工可使用此打卡点，留空 = 全部部门</div>
      </el-form-item>
      <el-form-item label="状态">
        <el-radio-group v-model="form.status">
          <el-radio :label="1">启用</el-radio>
          <el-radio :label="0">停用</el-radio>
        </el-radio-group>
      </el-form-item>
    </el-form>

    <span slot="footer">
      <el-button size="small" @click="visible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="save">保存</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { createPoint, updatePoint, getPointDetail } from '@/api/attendancePoints'
import { getDeptTree } from '@/api/organization'
import request from '@/api/request'

function flattenDept (nodes) {
  let r = []
  for (const n of nodes || []) { r.push(n); if (n.children) r = r.concat(flattenDept(n.children)) }
  return r
}

export default {
  name: 'PointsForm',
  props: {
    visible: { type: Boolean, default: false },
    pointId: { type: Number, default: 0 }
  },
  data () {
    return {
      form: {
        id: 0, point_name: '', address: '', latitude: '', longitude: '',
        radius: 300, weekdays: [1, 2, 3, 4, 5], department_ids: [], status: 1
      },
      timeRange: ['08:00', '18:00'],
      weekOptions: [
        { label: '周一', value: 1 }, { label: '周二', value: 2 }, { label: '周三', value: 3 },
        { label: '周四', value: 4 }, { label: '周五', value: 5 }, { label: '周六', value: 6 }, { label: '周日', value: 7 }
      ],
      deptOptions: [],
      rules: {
        point_name: [{ required: true, message: '请输入打卡点名称', trigger: 'blur' }],
        address: [{ required: true, message: '请输入详细地址', trigger: 'blur' }],
        radius: [{ required: true, message: '请设置打卡半径', trigger: 'change' }]
      },
      map: null, marker: null, searching: false, locating: false, saving: false
    }
  },
  watch: {
    visible (v) {
      if (v) {
        if (this.pointId) this.loadDetail()
        else this.$nextTick(() => this.initMap(39.9042, 116.4074))
      }
    }
  },
  created () {
    // 组件挂载即加载部门（父组件 v-if 挂载时 watch.visible 不触发，必须在 created 加载）
    this.loadDepts()
    // 编辑模式：首次挂载直接加载详情（pointId prop 已就绪）
    if (this.pointId) this.loadDetail()
  },
  methods: {
    async loadDepts () {
      try {
        const r = await getDeptTree()
        if (r.code === 0) this.deptOptions = flattenDept(r.data || []).map(d => ({ id: d.id, name: d.name }))
      } catch (e) {}
    },
    async loadDetail () {
      try {
        const r = await getPointDetail(this.pointId)
        if (r.code === 0 && r.data) {
          const d = r.data
          this.form = {
            id: d.id, point_name: d.point_name, address: d.address || '',
            latitude: String(d.latitude), longitude: String(d.longitude),
            radius: Number(d.radius) || 300,
            weekdays: Array.isArray(d.weekdays) ? d.weekdays : [1, 2, 3, 4, 5],
            department_ids: d.department_ids || [],
            status: Number(d.status) === 0 ? 0 : 1
          }
          if (d.start_time_hm) this.timeRange[0] = d.start_time_hm
          if (d.end_time_hm) this.timeRange[1] = d.end_time_hm
          this.$nextTick(() => this.initMap(parseFloat(this.form.latitude), parseFloat(this.form.longitude)))
        }
      } catch (e) {}
    },
    // 初始化腾讯地图（使用基础服务已配置的地图 key）
    initMap (lat, lng) {
      if (typeof window.TMap === 'undefined') {
        this.loadTMap().then(() => this.createMap(lat, lng)).catch(() => this.$message.warning('地图加载失败，请手动填写经纬度'))
        return
      }
      this.createMap(lat, lng)
    },
    loadTMap () {
      return new Promise((resolve, reject) => {
        if (typeof window.TMap !== 'undefined') { resolve(); return }
        const script = document.createElement('script')
        script.src = 'https://map.qq.com/api/gljs?v=1.exp&key=' + this.mapKey()
        script.onload = resolve
        script.onerror = () => reject(new Error('load fail'))
        document.head.appendChild(script)
      })
    },
    mapKey () {
      // 从后端地图配置读取（系统基础服务 → 地图服务 key）
      const cfg = window.__MAP_CONFIG__ || {}
      return cfg.key || 'Z3DBZ-YIKCZ-JZNXJ-ZEUI6-LZACV-ZXBMR'
    },
    createMap (lat, lng) {
      const center = new window.TMap.LatLng(lat || 39.9042, lng || 116.4074)
      if (this.map) { this.map.setCenter(center); if (this.marker) { this.marker.setPosition(center); this.updateLngLat(lat, lng) } return }
      this.map = new window.TMap.Map(document.getElementById('pointMap'), {
        center, zoom: 16, mapStyleId: 'style1'
      })
      this.marker = new window.TMap.MultiMarker({
        map: this.map,
        styles: { default: new window.TMap.MarkerStyle({ width: 25, height: 35, anchor: { x: 12, y: 35 }, src: 'https://mapapi.qq.com/web/lbs/javascriptGL/demo/img/marker.png' }) },
        geometries: [{ id: 'p', styleId: 'default', position: center }]
      })
      // 点击地图移动标记
      this.map.on('click', (e) => {
        const pos = e.latLng
        this.marker.setGeometries([{ id: 'p', styleId: 'default', position: pos }])
        this.updateLngLat(pos.getLat(), pos.getLng())
      })
      this.updateLngLat(lat, lng)
    },
    updateLngLat (lat, lng) {
      if (lat && lng) {
        this.form.latitude = parseFloat(lat).toFixed(7)
        this.form.longitude = parseFloat(lng).toFixed(7)
        // 逆地址解析（经后端地图服务）
        this.reverseGeocode(parseFloat(lat), parseFloat(lng))
      }
    },
    async reverseGeocode (lat, lng) {
      try {
        const r = await request({ url: '/services/map/reverse-geocode', method: 'get', params: { lat, lng } })
        if (r.code === 0 && r.data && r.data.address && !this.form.address) {
          this.form.address = r.data.address
        }
      } catch (e) {}
    },
    /**
     * 一键获取当前位置（浏览器 Geolocation，失败回退腾讯地图 IP 定位）
     */
    getCurrentLocation () {
      this.locating = true
      const done = (lat, lng, source) => {
        this.locating = false
        if (!lat || !lng) { this.$message.error('定位失败，请检查浏览器定位权限'); return }
        this.form.latitude = String(lat)
        this.form.longitude = String(lng)
        // 移动地图标记
        if (this.map && this.marker) {
          const pos = new window.TMap.LatLng(lat, lng)
          this.map.setCenter(pos)
          this.marker.setGeometries([{ id: 'p', styleId: 'default', position: pos }])
        } else {
          this.$nextTick(() => this.initMap(lat, lng))
        }
        this.$message.success(source === 'ip' ? '已定位（IP 定位，精度较低）' : '定位成功')
        // 逆地址解析填充地址
        this.reverseGeocode(lat, lng)
      }
      // 1. 浏览器 Geolocation（GPS 精度）
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
          (pos) => done(pos.coords.latitude, pos.coords.longitude, 'gps'),
          () => this.ipLocate(done),
          { enableHighAccuracy: true, timeout: 8000, maximumAge: 30000 }
        )
      } else {
        this.ipLocate(done)
      }
    },
    // 腾讯地图 IP 定位兜底
    ipLocate (done) {
      request({ url: '/services/map/ip-location', method: 'get', timeout: 10000 })
        .then(r => {
          if (r.code === 0 && r.data && r.data.location) {
            done(r.data.location.lat, r.data.location.lng, 'ip')
          } else {
            this.locating = false
            this.$message.error((r && r.msg) || 'IP 定位失败')
          }
        })
        .catch(() => {
          this.locating = false
          this.$message.error('定位请求失败')
        })
    },
    async searchAddress () {
      if (!this.form.address) { this.$message.warning('请先输入地址'); return }
      this.searching = true
      try {
        const r = await request({ url: '/services/map/geocode', method: 'get', params: { address: this.form.address } })
        if (r.code === 0 && r.data && r.data.location) {
          const { lat, lng } = r.data.location
          this.form.latitude = String(lat)
          this.form.longitude = String(lng)
          if (this.map && this.marker) {
            const pos = new window.TMap.LatLng(lat, lng)
            this.map.setCenter(pos)
            this.marker.setGeometries([{ id: 'p', styleId: 'default', position: pos }])
          } else {
            this.$nextTick(() => this.initMap(lat, lng))
          }
          this.$message.success('定位成功')
        } else {
          this.$message.error((r && r.msg) || '地址定位失败')
        }
      } catch (e) {
        this.$message.error('地址定位失败')
      } finally {
        this.searching = false
      }
    },
    async save () {
      this.$refs.formRef.validate(async (valid) => {
        if (!valid) return
        if (!this.form.latitude || !this.form.longitude) {
          this.$message.warning('请先在地图上选择打卡点位置')
          return
        }
        if (!this.form.weekdays.length) {
          this.$message.warning('请至少选择一个有效星期')
          return
        }
        this.saving = true
        try {
          const data = {
            point_name: this.form.point_name,
            address: this.form.address,
            latitude: this.form.latitude,
            longitude: this.form.longitude,
            radius: this.form.radius,
            start_time: this.timeRange ? this.timeRange[0] : '',
            end_time: this.timeRange ? this.timeRange[1] : '',
            weekdays: this.form.weekdays,
            department_ids: this.form.department_ids || [],
            status: this.form.status
          }
          const r = this.form.id ? await updatePoint(this.form.id, data) : await createPoint(data)
          if (r.code === 0) {
            this.$message.success(r.msg || '保存成功')
            this.visible = false
            this.$emit('saved')
          } else {
            this.$message.error(r.msg || '保存失败')
          }
        } catch (e) {
          this.$message.error('请求失败')
        } finally {
          this.saving = false
        }
      })
    },
    reset () {
      this.form = { id: 0, point_name: '', address: '', latitude: '', longitude: '', radius: 300, weekdays: [1, 2, 3, 4, 5], department_ids: [], status: 1 }
      this.timeRange = ['08:00', '18:00']
    }
  }
}
</script>

<style scoped>
.map-wrap { width: 100%; }
.addr-actions { display: flex; align-items: center; gap: 8px; margin: -8px 0 12px 90px; }
.addr-hint { font-size: 12px; color: #c0c4cc; }
.map-container { width: 100%; height: 300px; border-radius: 8px; border: 1px solid #e4e7ed; }
.map-tip { font-size: 12px; color: #909399; margin-top: 6px; }
.lnglat-row { display: flex; gap: 12px; }
.lnglat-row .el-input { width: 48%; }
.unit { margin-left: 6px; color: #909399; font-size: 12px; }
.form-hint { font-size: 12px; color: #c0c4cc; margin-top: 4px; }
</style>
