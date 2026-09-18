<!--
  文件：admin/src/views/business/contract/components/ContractApprovalDialog.vue
  功能：合同审批弹窗（550px）
    - 合同基本信息摘要
    - 审批意见（必填）
    - 通过/驳回按钮
-->
<template>
  <el-dialog title="合同审批" :visible="visible" width="550px" :close-on-click-modal="false" @close="$emit('update:visible', false)">
    <div v-loading="loading">
      <template v-if="detail">
        <el-descriptions :column="2" size="small" border>
          <el-descriptions-item label="合同编号">{{ detail.contract_no }}</el-descriptions-item>
          <el-descriptions-item label="合同名称">{{ detail.contract_name }}</el-descriptions-item>
          <el-descriptions-item label="合同类型">{{ detail.contract_type_text }}</el-descriptions-item>
          <el-descriptions-item label="合同金额">¥{{ Number(detail.contract_amount || 0).toLocaleString() }}</el-descriptions-item>
          <el-descriptions-item label="对方名称">{{ detail.party_name || '--' }}</el-descriptions-item>
          <el-descriptions-item label="签订日期">{{ detail.sign_date }}</el-descriptions-item>
        </el-descriptions>
      </template>
      <el-form label-width="80px" size="small" style="margin-top:12px">
        <el-form-item label="审批意见" required>
          <el-input v-model="comment" type="textarea" :rows="4" maxlength="500" placeholder="请填写审批意见（驳回时必须填写原因）" />
        </el-form-item>
      </el-form>
    </div>
    <div slot="footer">
      <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
      <el-button size="small" type="danger" :loading="submitting" @click="handleReview('reject')">驳回</el-button>
      <el-button size="small" type="success" :loading="submitting" @click="handleReview('pass')">通过</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getContractDetail, approveContract, rejectContract } from '../../../../api/businessContract'

export default {
  name: 'ContractApprovalDialog',
  props: {
    visible: { type: Boolean, default: false },
    contractId: { type: Number, default: 0 }
  },
  data() {
    return { loading: false, submitting: false, detail: null, comment: '' }
  },
  watch: {
    visible(val) { if (val && this.contractId) this.open() }
  },
  methods: {
    async open() {
      this.loading = true
      this.detail = null
      this.comment = ''
      try {
        const r = await getContractDetail(this.contractId)
        if (r.code === 0) this.detail = r.data
      } catch (e) {}
      this.loading = false
    },
    async handleReview(result) {
      if (!this.comment.trim()) { this.$message.warning('请填写审批意见'); return }
      this.submitting = true
      try {
        const r = result === 'pass'
          ? await approveContract(this.contractId, { approval_comment: this.comment })
          : await rejectContract(this.contractId, { approval_comment: this.comment })
        if (r.code === 0) { this.$message.success(r.msg); this.$emit('success') }
      } catch (e) {}
      this.submitting = false
    }
  }
}
</script>
