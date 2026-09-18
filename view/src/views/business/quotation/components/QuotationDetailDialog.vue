<!--
  文件：admin/src/views/business/quotation/components/QuotationDetailDialog.vue
  功能：报价单详情弹窗（850px）
    - 基本信息 + 类别/状态标签
    - 明细列表 + 费用汇总
    - 审核记录
    - 已通过状态可转订单
-->
<template>
  <el-dialog
    :title="detail ? detail.quotation_no : '报价单详情'"
    :visible="visible"
    width="850px"
    :close-on-click-modal="false"
    @close="$emit('update:visible', false)"
  >
    <div v-loading="loading" class="detail-wrap">
      <template v-if="detail">
        <el-descriptions :column="3" size="small" border>
          <el-descriptions-item label="报价单编号">{{ detail.quotation_no }}</el-descriptions-item>
          <el-descriptions-item label="报价类别">
            <el-tag size="mini" :type="detail.quotation_category === 'repair' ? 'warning' : 'primary'">{{ detail.quotation_category_text }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="报价状态">
            <el-tag size="mini" :type="statusTag(detail.quotation_status)">{{ detail.quotation_status_text }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="客户">{{ detail.customer_name }}</el-descriptions-item>
          <el-descriptions-item label="报价金额"><b style="color:#f56c6c">¥{{ Number(detail.quotation_amount || 0).toLocaleString() }}</b></el-descriptions-item>
          <el-descriptions-item label="业务员">{{ detail.salesperson_name || '--' }}</el-descriptions-item>
          <el-descriptions-item label="报价日期">{{ detail.quotation_date }}</el-descriptions-item>
          <el-descriptions-item label="有效期至">{{ detail.validity_date || '--' }}</el-descriptions-item>
          <el-descriptions-item label="预计交付">{{ detail.delivery_date || '--' }}</el-descriptions-item>
          <el-descriptions-item label="关联订单" :span="2">{{ detail.converted_order_no || '--' }}</el-descriptions-item>
          <el-descriptions-item label="创建人">{{ detail.created_by_name || '--' }}</el-descriptions-item>
        </el-descriptions>
        <div v-if="detail.remark" class="remark">备注：{{ detail.remark }}</div>

        <!-- 明细 -->
        <el-divider content-position="left">报价明细</el-divider>
        <el-table :data="detail.items || []" size="mini" border>
          <el-table-column prop="item_type_text" label="类型" width="90" />
          <el-table-column prop="item_name" label="项目名称" min-width="160" />
          <el-table-column prop="item_spec" label="规格型号" width="110" />
          <el-table-column prop="quantity" label="数量" width="70" align="center" />
          <el-table-column label="单价" width="100"><template slot-scope="s">¥{{ Number(s.row.unit_price || 0).toLocaleString() }}</template></el-table-column>
          <el-table-column label="金额" width="110"><template slot-scope="s">¥{{ Number(s.row.amount || 0).toLocaleString() }}</template></el-table-column>
        </el-table>
        <div class="total-line">合计：<b>¥{{ Number(detail.quotation_amount || 0).toLocaleString() }}</b></div>

        <!-- 审核记录 -->
        <el-divider content-position="left">审核记录</el-divider>
        <el-table v-if="detail.reviews && detail.reviews.length" :data="detail.reviews" size="mini" border>
          <el-table-column prop="reviewer_name" label="审核人" width="100" />
          <el-table-column label="结果" width="80"><template slot-scope="s"><el-tag size="mini" :type="s.row.review_result === 'pass' ? 'success' : 'danger'">{{ s.row.review_result_text }}</el-tag></template></el-table-column>
          <el-table-column prop="review_comment" label="意见" min-width="200" />
          <el-table-column prop="review_time" label="审核时间" width="160" />
        </el-table>
        <div v-else class="no-data">暂无审核记录</div>

        <div v-if="detail.quotation_status === 'approved'" class="convert-tip">
          <el-button type="success" size="small" icon="el-icon-s-promotion" @click="$emit('convert', detail)">转为订单</el-button>
          <span class="tip-text">审核已通过，可一键转为正式订单</span>
        </div>
      </template>
    </div>
  </el-dialog>
</template>

<script>
import { getQuotationDetail } from '../../../../api/businessQuotation'

export default {
  name: 'QuotationDetailDialog',
  props: {
    visible: { type: Boolean, default: false },
    quotationId: { type: Number, default: 0 }
  },
  data() {
    return { loading: false, detail: null }
  },
  watch: {
    visible(val) { if (val && this.quotationId) this.open() }
  },
  methods: {
    async open() {
      this.loading = true
      this.detail = null
      try {
        const r = await getQuotationDetail(this.quotationId)
        if (r.code === 0) this.detail = r.data
      } catch (e) {}
      this.loading = false
    },
    statusTag(s) { return { draft: 'info', pending: 'warning', approved: 'success', rejected: 'danger', converted: 'primary' }[s] || 'info' }
  }
}
</script>

<style scoped>
.remark { margin-top: 10px; font-size: 13px; color: #606266; background: #f8f9fb; padding: 8px 12px; border-radius: 4px; }
.total-line { text-align: right; font-size: 14px; color: #303133; margin-top: 10px; }
.total-line b { color: #f56c6c; }
.no-data { color: #909399; font-size: 12px; padding: 10px 0; }
.convert-tip { margin-top: 16px; padding: 12px; background: #f0f9eb; border-radius: 6px; display: flex; align-items: center; gap: 10px; }
.tip-text { color: #67c23a; font-size: 13px; }
</style>
