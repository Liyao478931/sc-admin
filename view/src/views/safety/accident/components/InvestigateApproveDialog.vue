<template>
  <el-dialog title="调查报告审批" :visible="visible" width="480px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <el-form label-width="100px" size="small">
      <el-form-item label="事故">
        <span style="font-size:13px;color:#606266;">{{ row ? row.accident_name : '' }}</span>
      </el-form-item>
      <el-form-item label="审批结果">
        <el-radio-group v-model="action">
          <el-radio label="approve">通过</el-radio>
          <el-radio label="reject">驳回</el-radio>
        </el-radio-group>
      </el-form-item>
      <el-form-item v-if="action === 'reject'" label="驳回原因" required>
        <el-input v-model="reason" type="textarea" :rows="3" placeholder="请填写驳回原因" maxlength="500" />
      </el-form-item>
    </el-form>
    <div slot="footer">
      <el-button size="small" @click="handleVisibleChange(false)">取消</el-button>
      <el-button size="small" :type="action === 'approve' ? 'success' : 'danger'" :loading="saving" @click="submit">确认{{ action === 'approve' ? '通过' : '驳回' }}</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { approveInvestigate, rejectInvestigate } from '@/api/safetyAccident'

export default {
  name: 'InvestigateApproveDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null },
  },
  data() {
    return { action: 'approve', reason: '', saving: false }
  },
  watch: {
    visible(val) { if (val) { this.action = 'approve'; this.reason = '' } },
  },
  methods: {
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    async submit() {
      if (this.action === 'reject' && !this.reason.trim()) { this.$message.warning('请填写驳回原因'); return }
      this.saving = true
      try {
        const r = this.action === 'approve'
          ? await approveInvestigate(this.row.id)
          : await rejectInvestigate(this.row.id, this.reason)
        if (r.code === 0) {
          this.$message.success(r.msg || '操作成功')
          this.handleVisibleChange(false)
          this.$emit('saved')
        }
      } catch (e) {}
      this.saving = false
    },
  },
}
</script>
