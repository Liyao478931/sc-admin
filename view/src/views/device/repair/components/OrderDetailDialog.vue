<template>
  <el-dialog title="维修工单详情" :visible.sync="visible" width="900px" :close-on-click-modal="false">
    <div v-loading="loading">
      <el-tabs v-model="activeTab">
        <!-- 基本信息 -->
        <el-tab-pane label="基本信息" name="info">
          <el-descriptions :column="2" border size="small">
            <el-descriptions-item label="工单编号">{{ detail.order_code || '-' }}</el-descriptions-item>
            <el-descriptions-item label="状态"><el-tag :type="statusType(detail.status)" size="mini">{{ detail.status_text }}</el-tag></el-descriptions-item>
            <el-descriptions-item label="设备名称">{{ detail.device_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="设备编码">{{ detail.device_code || '-' }}</el-descriptions-item>
            <el-descriptions-item label="故障类型">{{ faultLabel(detail.fault_type) }}</el-descriptions-item>
            <el-descriptions-item label="紧急程度"><el-tag :type="emergencyType(detail.emergency_level)" size="mini">{{ detail.emergency_text }}</el-tag></el-descriptions-item>
            <el-descriptions-item label="来源类型">{{ sourceLabel(detail.source_type) }}</el-descriptions-item>
            <el-descriptions-item label="报修人">{{ detail.reporter_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="报修时间">{{ detail.report_time || '-' }}</el-descriptions-item>
            <el-descriptions-item label="处理人">{{ detail.handler_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="派单时间">{{ detail.assign_time || '-' }}</el-descriptions-item>
            <el-descriptions-item label="计划完成">{{ detail.plan_complete_time || '-' }}</el-descriptions-item>
            <el-descriptions-item label="实际完成">{{ detail.actual_complete_time || '-' }}</el-descriptions-item>
            <el-descriptions-item label="验收人">{{ detail.acceptor_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="验收时间">{{ detail.accept_time || '-' }}</el-descriptions-item>
            <el-descriptions-item label="驳回次数">{{ detail.reject_count || 0 }}</el-descriptions-item>
            <el-descriptions-item label="故障描述" :span="2">{{ detail.fault_description || '-' }}</el-descriptions-item>
            <el-descriptions-item label="验收意见" :span="2">{{ detail.accept_remark || '-' }}</el-descriptions-item>
            <el-descriptions-item label="驳回原因" :span="2"><span style="color:#F56C6C">{{ detail.reject_reason || '-' }}</span></el-descriptions-item>
            <el-descriptions-item label="备注" :span="2">{{ detail.remark || '-' }}</el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>

        <!-- 状态流转历史（转派记录） -->
        <el-tab-pane label="状态流转历史" name="history">
          <el-timeline v-if="(detail.transfer_history || []).length">
            <el-timeline-item v-for="(h, i) in detail.transfer_history" :key="i" :timestamp="h.time" placement="top" color="#E6A23C">
              <strong>转派：{{ h.from }} → {{ h.to }}</strong>
              <div style="color:#909399;font-size:13px">原因：{{ h.reason }}</div>
            </el-timeline-item>
          </el-timeline>
          <el-empty v-else description="暂无转派记录" :image-size="80" />
        </el-tab-pane>

        <!-- 操作日志 -->
        <el-tab-pane label="操作日志" name="logs">
          <el-table :data="detail.logs || []" size="small" border stripe>
            <el-table-column prop="create_time" label="时间" width="170" />
            <el-table-column prop="operator_name" label="操作人" width="100" />
            <el-table-column label="操作" width="110">
              <template slot-scope="{row}"><el-tag size="mini">{{ row.action_text }}</el-tag></template>
            </el-table-column>
            <el-table-column prop="action_desc" label="描述" min-width="200" show-overflow-tooltip />
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </div>
    <span slot="footer"><el-button type="primary" @click="visible = false">关闭</el-button></span>
  </el-dialog>
</template>

<script>
import { getOrderDetail } from '@/api/repairOrder'

export default {
  name: 'OrderDetailDialog',
  props: {
    visible: Boolean,
    orderId: { type: Number, default: 0 }
  },
  data() {
    return {
      activeTab: 'info', loading: false, detail: {},
      faultOptions: [],
      sourceOptions: []
    }
  },
  watch: { visible(v) { if (v) { this.loadDetail(); this.loadDicts() } } },
  methods: {
    async loadDicts() {
      const { getDictByCode } = await import('../../../../api/dictionary')
      try { const r = await getDictByCode('repair_fault_type'); this.faultOptions = r.data || [] } catch (e) { this.faultOptions = [] }
      try { const r = await getDictByCode('repair_source_type'); this.sourceOptions = r.data || [] } catch (e) { this.sourceOptions = [] }
    },
    async loadDetail() {
      this.loading = true
      try { const r = await getOrderDetail(this.orderId); if (r.code === 0) this.detail = r.data } catch (e) {}
      this.loading = false
    },
    statusType(s) { return { pending: 'info', assigned: 'primary', repairing: 'warning', accepted: 'warning', approved: 'success', closed: 'info', rejected: 'danger' }[s] || '' },
    emergencyType(e) { return { critical: 'danger', urgent: 'warning', normal: 'info' }[e] || '' },
    faultLabel(v) { const f = this.faultOptions.find(x => x.value === v); return f ? f.label : v },
    sourceLabel(v) { const s = this.sourceOptions.find(x => x.value === v); return s ? s.label : v }
  }
}
</script>
