<!--
  文件：admin/src/views/business/quotation/components/QuotationReviewDialog.vue
  功能：报价单审核弹窗（550px）
    - 报价单基本信息摘要
    - 审核意见（必填）
    - 通过/驳回按钮
-->
<template>
  <el-dialog title="报价单审核" :visible="visible" width="550px" :close-on-click-modal="false" @close="$emit('update:visible', false)">
    <div v-loading="loading">
      <template v-if="detail">
        <el-descriptions :column="2" size="small" border>
          <el-descriptions-item label="报价单编号">{{ detail.quotation_no }}</el-descriptions-item>
          <el-descriptions-item label="客户">{{ detail.customer_name }}</el-descriptions-item>
          <el-descriptions-item label="报价类别">{{ detail.quotation_category_text }}</el-descriptions-item>
          <el-descriptions-item label="报价金额">¥{{ Number(detail.quotation_amount || 0).toLocaleString() }}</el-descriptions-item>
          <el-descriptions-item label="报价日期">{{ detail.quotation_date }}</el-descriptions-item>
          <el-descriptions-item label="业务员">{{ detail.salesperson_name || '--' }}</el-descriptions-item>
        </el-descriptions>
      </template>
      <el-form label-width="80px" size="small" style="margin-top:12px">
        <el-form-item label="审核意见" required>
          <el-input v-model="comment" type="textarea" :rows="4" maxlength="500" placeholder="请填写审核意见（驳回时必须填写原因）" />
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
import { getQuotationReviewDetail, approveQuotation, rejectQuotation } from '../../../../api/businessQuotation'

export default {
  name: 'QuotationReviewDialog',
  props: {
    visible: { type: Boolean, default: false },
    quotationId: { type: Number, default: 0 }
  },
  data() {
    return { loading: false, submitting: false, detail: null, comment: '' }
  },
  watch: {
    visible(val) { if (val && this.quotationId) this.open() }
  },
  methods: {
    async open() {
      this.loading = true
      this.detail = null
      this.comment = ''
      try {
        const r = await getQuotationReviewDetail(this.quotationId)
        if (r.code === 0) this.detail = r.data
      } catch (e) {}
      this.loading = false
    },
    async handleReview(result) {
      if (!this.comment.trim()) { this.$message.warning('请填写审核意见'); return }
      this.submitting = true
      try {
        const r = result === 'pass'
          ? await approveQuotation(this.quotationId, { review_comment: this.comment })
          : await rejectQuotation(this.quotationId, { review_comment: this.comment })
        if (r.code === 0) { this.$message.success(r.msg); this.$emit('success') }
      } catch (e) {}
      this.submitting = false
    }
  }
}
</script>
