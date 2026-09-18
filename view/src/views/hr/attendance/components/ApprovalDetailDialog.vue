<template>
  <el-dialog title="审批记录详情" :visible="visible" @update:visible="$emit('update:visible', $event)" width="700px" top="8vh" @open="load">
    <div v-loading="loading">
      <template v-if="detail.id">
        <div class="sec-title">基本信息</div>
        <div class="info-grid">
          <span><b>审批编号：</b>{{ detail.approval_code }}</span>
          <span><b>审批类型：</b><el-tag size="mini" :style="typeStyle(detail.approval_type)">{{ detail.approval_type_text }}</el-tag></span>
          <span><b>申请人：</b>{{ detail.employee_name }}</span>
          <span><b>所属部门：</b>{{ detail.department_name || '-' }}</span>
          <span><b>申请日期：</b>{{ detail.apply_date }}</span>
        </div>
        <div class="sec-title">时间信息</div>
        <div class="info-grid">
          <span><b>开始时间：</b>{{ detail.start_time }}</span>
          <span><b>结束时间：</b>{{ detail.end_time }}</span>
          <span><b>时长：</b>{{ detail.duration }} 小时</span>
        </div>
        <div class="sec-title">审批信息</div>
        <div class="info-grid">
          <span><b>审批状态：</b><el-tag size="mini" :type="statusType(detail.approval_status)">{{ detail.approval_status_text }}</el-tag></span>
          <span><b>审批人：</b>{{ detail.approver || '-' }}</span>
          <span><b>审批时间：</b>{{ detail.approve_time || '-' }}</span>
          <span><b>审批意见：</b>{{ detail.approve_opinion || '-' }}</span>
        </div>
        <div class="sec-title">数据信息</div>
        <div class="info-grid">
          <span><b>数据来源：</b><el-tag size="mini" :type="detail.source === 'manual' ? 'success' : 'primary'">{{ detail.source_text }}</el-tag></span>
          <span><b>同步时间：</b>{{ detail.sync_time || '-' }}</span>
          <span><b>钉钉实例ID：</b>{{ detail.source_id || '-' }}</span>
          <span><b>备注：</b>{{ detail.remark || '-' }}</span>
        </div>
      </template>
    </div>
  </el-dialog>
</template>

<script>
import { getApprovalDetail } from '@/api/attendanceApproval'

const TYPE_COLOR = { leave: '#409EFF', outing: '#E6A23C', travel: '#67C23A', car_apply: '#8E44AD' }

export default {
  name: 'ApprovalDetailDialog',
  props: { visible: { type: Boolean, default: false }, recordId: { type: Number, default: 0 } },
  data () { return { loading: false, detail: {} } },
  methods: {
    typeStyle (t) { const c = TYPE_COLOR[t] || '#909399'; return { color: c, borderColor: c, background: c + '1a' } },
    statusType (s) { return { pending: 'warning', approved: 'success', rejected: 'danger', canceled: 'info' }[s] || 'info' },
    async load () {
      if (!this.recordId) return
      this.loading = true
      try { const r = await getApprovalDetail(this.recordId); if (r.code === 0) this.detail = r.data || {} } catch (e) {} finally { this.loading = false }
    }
  }
}
</script>

<style scoped>
.sec-title { font-size: 13px; font-weight: 600; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; margin: 10px 0 8px; }
.info-grid { display: flex; flex-wrap: wrap; gap: 8px 24px; font-size: 13px; color: #333; margin-bottom: 6px; }
</style>
