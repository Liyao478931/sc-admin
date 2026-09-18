<template>
  <el-dialog title="变更记录详情" :visible.sync="dialogVisible" width="800px" top="5vh" @open="loadData">
    <div v-loading="loading">
      <el-descriptions :column="2" border size="small" title="变更信息">
        <el-descriptions-item label="设备编码">{{ detail.device_code || '-' }}</el-descriptions-item>
        <el-descriptions-item label="设备名称">{{ detail.device_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="变更前状态"><el-tag :type="statusTagType(detail.from_status)" size="small">{{ statusLabel(detail.from_status) || '初始' }}</el-tag></el-descriptions-item>
        <el-descriptions-item label="变更后状态"><el-tag :type="statusTagType(detail.to_status)" size="small">{{ statusLabel(detail.to_status) }}</el-tag></el-descriptions-item>
        <el-descriptions-item label="变更类型"><el-tag :type="detail.change_type === 'rollback' ? 'danger' : 'primary'" size="mini">{{ detail.change_type === 'rollback' ? '撤销回退' : '正常变更' }}</el-tag></el-descriptions-item>
        <el-descriptions-item label="变更时间">{{ detail.change_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="变更人">{{ detail.operator_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="关联单据">{{ detail.related_order_no || '-' }}<span v-if="detail.related_order_type">（{{ orderTypeLabel }}）</span></el-descriptions-item>
        <el-descriptions-item label="变更原因" :span="2">{{ detail.reason || '-' }}</el-descriptions-item>
      </el-descriptions>

      <el-divider content-position="left">变更时设备快照</el-divider>
      <el-descriptions :column="3" border size="small">
        <el-descriptions-item label="分类">{{ snapshot.category_path || snapshot.category_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="型号">{{ snapshot.model || '-' }}</el-descriptions-item>
        <el-descriptions-item label="品牌">{{ snapshot.brand || '-' }}</el-descriptions-item>
        <el-descriptions-item label="部门">{{ snapshot.department_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="负责人">{{ snapshot.manager_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="存放位置">{{ snapshot.location || '-' }}</el-descriptions-item>
      </el-descriptions>

      <el-divider content-position="left">设备当前状态</el-divider>
      <div v-if="detail.asset_current">
        <el-tag :type="statusTagType(detail.asset_current.status)" size="small">{{ statusLabel(detail.asset_current.status) }}</el-tag>
        <span style="color:#909399;font-size:12px;margin-left:8px">{{ detail.asset_current.department_name }} / {{ detail.asset_current.manager_name }}</span>
      </div>
      <span v-else style="color:#C0C4CC">设备不存在或已删除</span>

      <el-divider content-position="left">该设备完整变更时间线</el-divider>
      <el-timeline v-if="history.length">
        <el-timeline-item v-for="h in history" :key="h.id" :timestamp="h.change_time" placement="top">
          <span>{{ statusLabel(h.from_status) || '初始' }}</span><i class="el-icon-right"></i><span>{{ statusLabel(h.to_status) }}</span>
          <el-tag v-if="h.change_type === 'rollback'" type="danger" size="mini">撤销</el-tag>
          <div style="color:#909399;font-size:12px">原因：{{ h.reason || '-' }}　操作人：{{ h.operator_name }}</div>
        </el-timeline-item>
      </el-timeline>
      <el-empty v-else description="暂无变更记录" :image-size="60" />
    </div>
  </el-dialog>
</template>

<script>
import { getStatusChangeDetail, getDeviceHistory } from '@/api/deviceStatusChange'

export default {
  name: 'StatusChangeDetailDialog',
  props: {
    visible: Boolean,
    recordId: { type: Number, default: 0 },
    statusOptions: { type: Array, default: () => [] },
    changeTypeOptions: { type: Array, default: () => [] }
  },
  data() {
    return {
      dialogVisible: this.visible,
      loading: false,
      detail: {},
      history: []
    }
  },
  watch: {
    visible(val) { this.dialogVisible = val }
  },
  computed: {
    snapshot() { return this.detail.snapshot_data || {} },
    orderTypeLabel() {
      const t = this.changeTypeOptions.find(x => x.value === this.detail.related_order_type)
      return t ? t.label : (this.detail.related_order_type || '-')
    }
  },
  methods: {
    statusLabel(v) { const s = this.statusOptions.find(x => x.value === v); return s ? s.label : (v || '-') },
    statusTagType(v) { const s = this.statusOptions.find(x => x.value === v); return (s && s.style) || 'info' },
    async loadData() {
      if (!this.recordId) return
      this.loading = true
      try {
        const res = await getStatusChangeDetail(this.recordId)
        if (res.code === 0) this.detail = res.data
        if (this.detail.asset_id) {
          const h = await getDeviceHistory(this.detail.asset_id)
          if (h.code === 0) this.history = h.data
        }
      } catch (e) { /* 拦截器已提示 */ }
      this.loading = false
    }
  }
}
</script>
