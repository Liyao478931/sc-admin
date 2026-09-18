<template>
  <el-dialog title="修改签到地点" :visible.sync="dialogVisible" width="500px" append-to-body>
    <el-form :model="form" :rules="rules" ref="formRef" label-width="110px" size="small">
      <el-form-item label="签到地点名称" prop="checkin_location">
        <el-input v-model="form.checkin_location" placeholder="如：一号会议室" />
      </el-form-item>
      <el-row :gutter="12">
        <el-col :span="12">
          <el-form-item label="纬度"><el-input v-model="form.checkin_lat" placeholder="如：39.9081234" /></el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="经度"><el-input v-model="form.checkin_lng" placeholder="如：116.3971234" /></el-form-item>
        </el-col>
      </el-row>
      <el-form-item label="获取位置">
        <el-button size="small" type="primary" icon="el-icon-location" :loading="locating" @click="getCurrentPos">自动获取当前位置</el-button>
        <el-button size="small" icon="el-icon-position" :loading="geocoding" @click="getAddress">根据经纬度获取地址</el-button>
        <span style="color:#909399;font-size:12px;margin-left:8px">先定位获取经纬度，再解析地址名称</span>
      </el-form-item>
      <el-form-item label="签到范围(米)">
        <el-input-number v-model="form.checkin_radius" :min="10" :max="5000" :step="10" style="width:100%" />
      </el-form-item>
      <el-row :gutter="12">
        <el-col :span="12">
          <el-form-item label="签到开始时间"><el-date-picker v-model="form.checkin_start_time" type="datetime" value-format="yyyy-MM-dd HH:mm:ss" style="width:100%" /></el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="签到结束时间"><el-date-picker v-model="form.checkin_end_time" type="datetime" value-format="yyyy-MM-dd HH:mm:ss" style="width:100%" /></el-form-item>
        </el-col>
      </el-row>
      <div style="color:#909399;font-size:12px;line-height:1.7">提示：签到地点经纬度用于员工扫码签到时 GPS 距离校验；未设置经纬度则不校验地点。</div>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">保存</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { updateExecution } from '@/api/safetyTrainingRecord'

export default {
  name: 'LocationDialog',
  props: {
    visible: Boolean,
    record: { type: Object, default: () => ({}) },
  },
  data() {
    return {
      dialogVisible: this.visible,
      saving: false,
      locating: false,
      geocoding: false,
      form: {},
      rules: { checkin_location: [{ required: true, message: '请输入签到地点名称', trigger: 'blur' }] }
    }
  },
  watch: {
    visible(val) {
      this.dialogVisible = val
      if (val) {
        this.form = {
          checkin_location: this.record.checkin_location || '',
          checkin_lat: this.record.checkin_lat != null ? String(this.record.checkin_lat) : '',
          checkin_lng: this.record.checkin_lng != null ? String(this.record.checkin_lng) : '',
          checkin_radius: this.record.checkin_radius || 100,
          checkin_start_time: this.record.checkin_start_time || '',
          checkin_end_time: this.record.checkin_end_time || ''
        }
      }
    },
    dialogVisible(val) { this.$emit('update:visible', val) },
  },
  methods: {
    /** WGS-84 转 GCJ-02（火星坐标），用于与员工端微信定位坐标统一 */
    wgs84ToGcj02(lng, lat) {
      const PI = 3.1415926535897932384626
      const a = 6378245.0
      const ee = 0.00669342162296594323
      if (lng < 72.004 || lng > 137.8347 || lat < 0.8293 || lat > 55.8271) return { lng, lat }
      const transformLat = (x, y) => {
        let ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * Math.sqrt(Math.abs(x))
        ret += (20.0 * Math.sin(6.0 * x * PI) + 20.0 * Math.sin(2.0 * x * PI)) * 2.0 / 3.0
        ret += (20.0 * Math.sin(y * PI) + 40.0 * Math.sin(y / 3.0 * PI)) * 2.0 / 3.0
        ret += (160.0 * Math.sin(y / 12.0 * PI) + 320 * Math.sin(y * PI / 30.0)) * 2.0 / 3.0
        return ret
      }
      const transformLng = (x, y) => {
        let ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * Math.sqrt(Math.abs(x))
        ret += (20.0 * Math.sin(6.0 * x * PI) + 20.0 * Math.sin(2.0 * x * PI)) * 2.0 / 3.0
        ret += (20.0 * Math.sin(x * PI) + 40.0 * Math.sin(x / 3.0 * PI)) * 2.0 / 3.0
        ret += (150.0 * Math.sin(x / 12.0 * PI) + 300.0 * Math.sin(x / 30.0 * PI)) * 2.0 / 3.0
        return ret
      }
      let dLat = transformLat(lng - 105.0, lat - 35.0)
      let dLng = transformLng(lng - 105.0, lat - 35.0)
      const radLat = lat / 180.0 * PI
      let magic = Math.sin(radLat)
      magic = 1 - ee * magic * magic
      const sqrtMagic = Math.sqrt(magic)
      dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * PI)
      dLng = (dLng * 180.0) / (a / sqrtMagic * Math.cos(radLat) * PI)
      return { lng: lng + dLng, lat: lat + dLat }
    },
    /** 浏览器定位自动获取当前位置经纬度（自动转换为 GCJ-02） */
    getCurrentPos() {
      if (!navigator.geolocation) { this.$message.error('当前浏览器不支持定位'); return }
      this.locating = true
      navigator.geolocation.getCurrentPosition((pos) => {
        const g = this.wgs84ToGcj02(pos.coords.longitude, pos.coords.latitude)
        this.form.checkin_lat = g.lat.toFixed(7)
        this.form.checkin_lng = g.lng.toFixed(7)
        this.$message.success('已获取当前位置经纬度（GCJ-02）')
        this.locating = false
      }, () => {
        this.locating = false
        this.$message.error('定位失败，请在浏览器设置中允许定位权限后重试')
      }, { enableHighAccuracy: true, timeout: 10000 })
    },
    /** 根据经纬度调用地图服务反向编码获取地址 */
    async getAddress() {
      if (!this.form.checkin_lat || !this.form.checkin_lng) { this.$message.warning('请先获取或填写经纬度'); return }
      this.geocoding = true
      try {
        const { reverseGeocode } = await import('@/api/safetyTrainingRecord')
        const r = await reverseGeocode(this.form.checkin_lat, this.form.checkin_lng)
        if (r.code === 0 && r.data && r.data.address) {
          this.form.checkin_location = r.data.address
          this.$message.success('已解析地址')
        } else { this.$message.error(r.msg || '地址解析失败，请确认已在地图服务配置 Key') }
      } catch (e) { this.$message.error('地址解析失败') }
      this.geocoding = false
    },
    submit() {
      this.$refs.formRef.validate(async (valid) => {
        if (!valid) return
        this.saving = true
        try {
          const r = await updateExecution(this.record.id, this.form)
          if (r.code === 0) { this.$message.success('签到地点已更新'); this.dialogVisible = false; this.$emit('saved') }
        } catch (e) {}
        this.saving = false
      })
    }
  }
}
</script>
