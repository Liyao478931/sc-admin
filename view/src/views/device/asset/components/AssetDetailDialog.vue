<template>
  <el-dialog title="设备详情" :visible.sync="dialogVisible" :width="width" top="5vh" @open="loadData">
    <div v-loading="loading">
      <el-tabs v-model="activeTab">
        <!-- Tab1 基础信息 -->
        <el-tab-pane label="基础信息" name="base">
          <el-descriptions :column="3" border size="small">
            <el-descriptions-item label="设备编码">{{ detail.device_code || '-' }}</el-descriptions-item>
            <el-descriptions-item label="设备名称">{{ detail.name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="设备类型">{{ typeLabel }}</el-descriptions-item>
            <el-descriptions-item label="所属分类" :span="2">{{ detail.category_path || '-' }}</el-descriptions-item>
            <el-descriptions-item label="状态"><el-tag :type="statusTagType" size="small">{{ statusLabel }}</el-tag></el-descriptions-item>
            <el-descriptions-item label="型号">{{ detail.model || '-' }}</el-descriptions-item>
            <el-descriptions-item label="规格参数">{{ detail.specification || '-' }}</el-descriptions-item>
            <el-descriptions-item label="品牌">{{ detail.brand || '-' }}</el-descriptions-item>
            <el-descriptions-item label="生产厂家">{{ detail.manufacturer || '-' }}</el-descriptions-item>
            <el-descriptions-item label="供应商">{{ detail.supplier_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="采购日期">{{ detail.purchase_date || '-' }}</el-descriptions-item>
            <el-descriptions-item label="采购价格">{{ detail.purchase_price === null || detail.purchase_price === undefined ? '-' : detail.purchase_price }}</el-descriptions-item>
            <el-descriptions-item label="投入使用日期">{{ detail.put_into_use_date || '-' }}</el-descriptions-item>
            <el-descriptions-item label="使用部门">{{ detail.department_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="存放位置">{{ detail.location || '-' }}</el-descriptions-item>
            <el-descriptions-item label="负责人">{{ detail.manager_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="备注" :span="3">{{ detail.remark || '-' }}</el-descriptions-item>
            <el-descriptions-item label="设备图片" :span="3">
              <el-image v-if="detail.image" :src="detail.image" style="width:120px;height:120px" fit="cover" :preview-src-list="[detail.image]" />
              <span v-else>-</span>
            </el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>

        <!-- Tab2 扩展信息 -->
        <el-tab-pane label="扩展信息" name="ext">
          <el-descriptions v-if="detail.device_type === 'general'" :column="3" border size="small">
            <el-descriptions-item label="额定功率">{{ ext.power_rating || '-' }}</el-descriptions-item>
            <el-descriptions-item label="电压等级">{{ ext.voltage || '-' }}</el-descriptions-item>
            <el-descriptions-item label="重量(kg)">{{ ext.weight ?? '-' }}</el-descriptions-item>
            <el-descriptions-item label="外形尺寸">{{ ext.dimensions || '-' }}</el-descriptions-item>
            <el-descriptions-item label="保修截止日期">{{ ext.warranty_expire_date || '-' }}</el-descriptions-item>
            <el-descriptions-item label="校准周期(月)">{{ ext.calibration_cycle ?? '-' }}</el-descriptions-item>
            <el-descriptions-item label="上次校准日期">{{ ext.last_calibration_date || '-' }}</el-descriptions-item>
            <el-descriptions-item label="下次校准日期">{{ ext.next_calibration_date || '-' }}</el-descriptions-item>
          </el-descriptions>
          <el-descriptions v-else-if="detail.device_type === 'special'" :column="3" border size="small">
            <el-descriptions-item label="特种设备类型">{{ specialTypeLabel }}</el-descriptions-item>
            <el-descriptions-item label="使用登记证编号">{{ ext.registration_code || '-' }}</el-descriptions-item>
            <el-descriptions-item label="登记机关">{{ ext.registration_authority || '-' }}</el-descriptions-item>
            <el-descriptions-item label="检验周期(月)">{{ ext.inspection_cycle ?? '-' }}</el-descriptions-item>
            <el-descriptions-item label="上次检验日期">{{ ext.last_inspection_date || '-' }}</el-descriptions-item>
            <el-descriptions-item label="下次检验日期">{{ ext.next_inspection_date || '-' }}</el-descriptions-item>
            <el-descriptions-item label="最近检验结果">{{ ext.inspection_result || '-' }}</el-descriptions-item>
            <el-descriptions-item label="是否需要操作证">{{ ext.operator_cert_required ? '是' : '否' }}</el-descriptions-item>
            <el-descriptions-item label="操作证编号">{{ ext.operator_cert_number || '-' }}</el-descriptions-item>
            <el-descriptions-item label="设计单位">{{ ext.design_unit || '-' }}</el-descriptions-item>
            <el-descriptions-item label="安装单位">{{ ext.install_unit || '-' }}</el-descriptions-item>
            <el-descriptions-item label="持证操作人员">{{ operatorNames }}</el-descriptions-item>
          </el-descriptions>
          <el-descriptions v-else-if="detail.device_type === 'car' || detail.device_type === 'truck'" :column="3" border size="small">
            <el-descriptions-item label="车牌号">{{ ext.license_plate || '-' }}</el-descriptions-item>
            <el-descriptions-item label="车架号">{{ ext.vin || '-' }}</el-descriptions-item>
            <el-descriptions-item label="发动机号">{{ ext.engine_no || '-' }}</el-descriptions-item>
            <el-descriptions-item label="排量(L)">{{ ext.displacement ?? '-' }}</el-descriptions-item>
            <el-descriptions-item label="燃料类型">{{ fuelTypeLabel }}</el-descriptions-item>
            <el-descriptions-item label="核定载重(kg)">{{ ext.load_capacity ?? '-' }}</el-descriptions-item>
            <el-descriptions-item label="核定载客数">{{ ext.seat_count ?? '-' }}</el-descriptions-item>
            <el-descriptions-item label="当前里程(km)">{{ ext.mileage ?? '-' }}</el-descriptions-item>
            <el-descriptions-item label="保险到期日">{{ ext.insurance_expire_date || '-' }}</el-descriptions-item>
            <el-descriptions-item label="年检到期日">{{ ext.inspection_expire_date || '-' }}</el-descriptions-item>
            <el-descriptions-item label="下次保养里程(km)">{{ ext.next_maintenance_mileage ?? '-' }}</el-descriptions-item>
            <el-descriptions-item label="上次保养日期">{{ ext.last_maintenance_date || '-' }}</el-descriptions-item>
          </el-descriptions>
          <el-empty v-else description="暂无扩展信息" :image-size="60" />
        </el-tab-pane>

        <!-- Tab3 状态变更历史 -->
        <el-tab-pane label="状态变更历史" name="log">
          <el-timeline v-if="statusLogs.length">
            <el-timeline-item v-for="log in statusLogs" :key="log.id" :timestamp="log.create_time" placement="top">
              <span>{{ statusLabelMap[log.from_status] || log.from_status || '初始' }}</span>
              <i class="el-icon-right"></i>
              <span>{{ statusLabelMap[log.to_status] || log.to_status }}</span>
              <span style="margin-left:10px;color:#909399">原因：{{ log.reason || '-' }}</span>
              <div style="color:#C0C4CC;font-size:12px">操作人：{{ log.operator_name || '-' }}</div>
            </el-timeline-item>
          </el-timeline>
          <el-empty v-else description="暂无状态变更记录" :image-size="60" />
        </el-tab-pane>
      </el-tabs>
    </div>
  </el-dialog>
</template>

<script>
import { getAssetDetail, getAssetStatusLog } from '@/api/deviceAsset'

export default {
  name: 'AssetDetailDialog',
  props: {
    visible: Boolean,
    assetId: { type: Number, default: 0 },
    width: { type: String, default: '1000px' },
    typeOptions: { type: Array, default: () => [] },
    specialTypeOptions: { type: Array, default: () => [] },
    fuelTypeOptions: { type: Array, default: () => [] },
    statusOptions: { type: Array, default: () => [] },
    managerList: { type: Array, default: () => [] }
  },
  data() {
    return {
      dialogVisible: this.visible,
      activeTab: 'base',
      loading: false,
      detail: {},
      statusLogs: [],
      statusLabelMap: {}
    }
  },
  watch: {
    visible(val) { this.dialogVisible = val }
  },
  computed: {
    ext() { return this.detail.ext || {} },
    typeLabel() {
      const t = this.typeOptions.find(x => x.value === this.detail.device_type)
      return t ? t.label : (this.detail.device_type || '-')
    },
    statusLabel() {
      const s = this.statusOptions.find(x => x.value === this.detail.status)
      return s ? s.label : (this.detail.status || '-')
    },
    statusTagType() {
      const s = this.statusOptions.find(x => x.value === this.detail.status)
      return (s && s.style) || 'info'
    },
    specialTypeLabel() {
      const s = this.specialTypeOptions.find(x => x.value === this.ext.special_type)
      return s ? s.label : (this.ext.special_type || '-')
    },
    fuelTypeLabel() {
      const f = this.fuelTypeOptions.find(x => x.value === this.ext.fuel_type)
      return f ? f.label : (this.ext.fuel_type || '-')
    },
    operatorNames() {
      const ids = String(this.ext.operator_ids || '').split(',').map(Number).filter(Boolean)
      return ids.map(id => { const m = this.managerList.find(x => x.id === id); return m ? m.name : id }).join('、') || '-'
    }
  },
  created() {
    this.statusOptions.forEach(s => { this.statusLabelMap[s.value] = s.label })
  },
  methods: {
    async loadData() {
      if (!this.assetId) return
      this.loading = true
      try {
        const res = await getAssetDetail(this.assetId)
        if (res.code === 0) this.detail = res.data
        const logRes = await getAssetStatusLog(this.assetId)
        if (logRes.code === 0) this.statusLogs = logRes.data
      } catch (e) { /* 拦截器已提示 */ }
      this.loading = false
    }
  }
}
</script>
