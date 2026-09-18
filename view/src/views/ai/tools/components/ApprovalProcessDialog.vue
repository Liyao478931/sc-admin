<template>
  <el-dialog title="审批处理" :visible.sync="visible" width="640px" append-to-body>
    <div v-if="row" class="process-dialog">
      <!-- 审批信息 -->
      <el-descriptions :column="3" size="small" border>
        <el-descriptions-item label="审批编号">{{ row.approval_id }}</el-descriptions-item>
        <el-descriptions-item label="工具名称">{{ row.tool_name }}</el-descriptions-item>
        <el-descriptions-item label="操作类型">
          <el-tag size="mini" :type="actionType(row.action_type)">{{ row.action_text }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="申请人">{{ row.applicant_name }}</el-descriptions-item>
        <el-descriptions-item label="申请时间">{{ row.apply_time }}</el-descriptions-item>
        <el-descriptions-item label="申请说明">{{ row.apply_remark || '--' }}</el-descriptions-item>
      </el-descriptions>

      <!-- 工具详情（快照） -->
      <div class="sub-title">工具配置（快照）</div>
      <el-descriptions :column="2" size="small" border>
        <el-descriptions-item label="工具名称">{{ snap.tool_name || '--' }}</el-descriptions-item>
        <el-descriptions-item label="显示名称">{{ snap.tool_display_name || '--' }}</el-descriptions-item>
        <el-descriptions-item label="分类">{{ snap.category || '--' }}</el-descriptions-item>
        <el-descriptions-item label="请求方法">{{ snap.method || '--' }}</el-descriptions-item>
        <el-descriptions-item label="API路径" :span="2">{{ snap.api_path || '--' }}</el-descriptions-item>
        <el-descriptions-item label="描述" :span="2">{{ snap.description || '--' }}</el-descriptions-item>
      </el-descriptions>

      <!-- 审批意见 -->
      <div class="sub-title">审批意见</div>
      <el-input v-model="comment" type="textarea" :rows="3" placeholder="驳回时必须填写原因" />
    </div>
    <div slot="footer">
      <el-button size="small" @click="visible = false">取消</el-button>
      <el-button size="small" type="danger" :loading="processing" @click="doProcess('reject')">驳回</el-button>
      <el-button size="small" type="success" :loading="processing" @click="doProcess('approve')">通过</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { processToolApproval } from '../../../../api/aiToolApproval'

export default {
  name: 'ApprovalProcessDialog',
  data() {
    return {
      visible: false,
      processing: false,
      row: null,
      comment: ''
    }
  },
  computed: {
    snap() {
      if (!this.row || !this.row.tool_snapshot) return {}
      return typeof this.row.tool_snapshot === 'string' ? JSON.parse(this.row.tool_snapshot) : this.row.tool_snapshot
    }
  },
  methods: {
    actionType(t) { return { create: 'success', update: 'warning', delete: 'danger' }[t] || 'info' },
    open(row) {
      this.row = row
      this.comment = ''
      this.visible = true
    },
    async doProcess(action) {
      if (action === 'reject' && !this.comment.trim()) return this.$message.warning('驳回必须填写原因')
      this.processing = true
      try {
        const res = await processToolApproval(this.row.id, { action, comment: this.comment })
        this.$message.success(res.msg || (action === 'approve' ? '审批已通过' : '审批已驳回'))
        this.visible = false
        this.$emit('saved')
      } catch (e) {}
      this.processing = false
    }
  }
}
</script>

<style scoped>
.sub-title { font-weight: 600; margin: 14px 0 8px; font-size: 13px; }
</style>
