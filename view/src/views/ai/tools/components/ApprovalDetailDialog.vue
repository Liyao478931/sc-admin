<template>
  <el-dialog title="审批详情" :visible.sync="visible" width="680px" append-to-body>
    <div v-if="detail" class="detail-dialog">
      <el-descriptions :column="3" size="small" border>
        <el-descriptions-item label="审批编号">{{ detail.approval_id }}</el-descriptions-item>
        <el-descriptions-item label="工具名称">{{ detail.tool_name }}</el-descriptions-item>
        <el-descriptions-item label="操作类型">
          <el-tag size="mini" :type="actionType(detail.action_type)">{{ detail.action_text }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="申请人">{{ detail.applicant_name }}</el-descriptions-item>
        <el-descriptions-item label="申请时间">{{ detail.apply_time }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag size="mini" :type="statusType(detail.approval_status)">{{ detail.status_text }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="申请说明" :span="3">{{ detail.apply_remark || '--' }}</el-descriptions-item>
        <el-descriptions-item label="审批人">{{ detail.approver_name || '--' }}</el-descriptions-item>
        <el-descriptions-item label="审批时间">{{ detail.approval_time || '--' }}</el-descriptions-item>
        <el-descriptions-item label="审批意见">{{ detail.approval_comment || '--' }}</el-descriptions-item>
        <el-descriptions-item label="驳回原因" :span="3">
          <span class="reject-text">{{ detail.reject_reason || '--' }}</span>
        </el-descriptions-item>
      </el-descriptions>

      <div class="sub-title">工具配置快照</div>
      <el-descriptions :column="2" size="small" border>
        <el-descriptions-item label="工具名称">{{ snap.tool_name || '--' }}</el-descriptions-item>
        <el-descriptions-item label="显示名称">{{ snap.tool_display_name || '--' }}</el-descriptions-item>
        <el-descriptions-item label="分类">{{ snap.category || '--' }}</el-descriptions-item>
        <el-descriptions-item label="请求方法">{{ snap.method || '--' }}</el-descriptions-item>
        <el-descriptions-item label="API路径" :span="2">{{ snap.api_path || '--' }}</el-descriptions-item>
        <el-descriptions-item label="超时">{{ snap.timeout || '--' }}s</el-descriptions-item>
        <el-descriptions-item label="重试">{{ snap.retry_count || 0 }}次</el-descriptions-item>
        <el-descriptions-item label="描述" :span="2">{{ snap.description || '--' }}</el-descriptions-item>
      </el-descriptions>
    </div>
    <div slot="footer">
      <el-button size="small" type="primary" @click="visible = false">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getToolApprovalDetail } from '../../../../api/aiToolApproval'

export default {
  name: 'ApprovalDetailDialog',
  data() {
    return { visible: false, detail: null }
  },
  computed: {
    snap() {
      if (!this.detail || !this.detail.tool_snapshot) return {}
      return typeof this.detail.tool_snapshot === 'string' ? JSON.parse(this.detail.tool_snapshot) : this.detail.tool_snapshot
    }
  },
  methods: {
    actionType(t) { return { create: 'success', update: 'warning', delete: 'danger' }[t] || 'info' },
    statusType(st) { return { pending: 'warning', processing: 'primary', approved: 'success', rejected: 'danger' }[st] || 'info' },
    async open(id) {
      this.visible = true
      this.detail = null
      try {
        const res = await getToolApprovalDetail(id)
        this.detail = res.data || {}
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.sub-title { font-weight: 600; margin: 14px 0 8px; font-size: 13px; }
.reject-text { color: #f56c6c; }
</style>
