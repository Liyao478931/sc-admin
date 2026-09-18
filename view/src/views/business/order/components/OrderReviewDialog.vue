<!--
  文件：admin/src/views/business/order/components/OrderReviewDialog.vue
  功能：订单评审弹窗（550px）
    - 订单基本信息摘要
    - 评审意见（必填）
    - 通过/驳回按钮
-->
<template>
  <el-dialog title="订单评审" :visible="visible" width="550px" :close-on-click-modal="false" @close="$emit('update:visible', false)">
    <div v-loading="loading">
      <template v-if="detail">
        <el-descriptions :column="2" size="small" border>
          <el-descriptions-item label="订单编号">{{ detail.order_no }}</el-descriptions-item>
          <el-descriptions-item label="客户">{{ detail.customer_name }}</el-descriptions-item>
          <el-descriptions-item label="订单类别">{{ detail.order_category_text }}</el-descriptions-item>
          <el-descriptions-item label="订单金额">¥{{ Number(detail.order_amount || 0).toLocaleString() }}</el-descriptions-item>
          <el-descriptions-item label="订单日期">{{ detail.order_date }}</el-descriptions-item>
          <el-descriptions-item label="业务员">{{ detail.salesperson_name || '--' }}</el-descriptions-item>
        </el-descriptions>
        <div v-if="detail.remark" class="remark">备注：{{ detail.remark }}</div>
      </template>
      <el-form label-width="80px" size="small" style="margin-top:12px">
        <el-form-item label="评审意见" required>
          <el-input v-model="comment" type="textarea" :rows="4" maxlength="500" placeholder="请填写评审意见（驳回时必须填写原因）" />
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
import { getReviewDetail, reviewPassOrder, reviewRejectOrder } from '../../../../api/businessOrder'

export default {
  name: 'OrderReviewDialog',
  props: {
    visible: { type: Boolean, default: false },
    orderId: { type: Number, default: 0 }
  },
  data() {
    return { loading: false, submitting: false, detail: null, comment: '' }
  },
  watch: {
    visible(val) { if (val && this.orderId) this.open() }
  },
  methods: {
    async open() {
      this.loading = true
      this.detail = null
      this.comment = ''
      try {
        const r = await getReviewDetail(this.orderId)
        if (r.code === 0) this.detail = r.data
      } catch (e) {}
      this.loading = false
    },
    async handleReview(result) {
      if (!this.comment.trim()) { this.$message.warning('请填写评审意见'); return }
      this.submitting = true
      try {
        const r = result === 'pass'
          ? await reviewPassOrder(this.orderId, { review_comment: this.comment })
          : await reviewRejectOrder(this.orderId, { review_comment: this.comment })
        if (r.code === 0) { this.$message.success(r.msg); this.$emit('success') }
      } catch (e) {}
      this.submitting = false
    }
  }
}
</script>

<style scoped>
.remark { margin-top: 10px; font-size: 13px; color: #606266; background: #f8f9fb; padding: 8px 12px; border-radius: 4px; }
</style>
