<!--
  文件：admin/src/views/business/order/components/OrderDetailDialog.vue
  功能：订单详情弹窗（850px）
    - 基本信息 + 类别/状态标签
    - 明细列表（销售=产品明细，维修=设备维修明细）
    - 操作日志时间线 + 评审记录
-->
<template>
  <el-dialog
    :title="detail ? detail.order_no : '订单详情'"
    :visible="visible"
    width="850px"
    :close-on-click-modal="false"
    @close="$emit('update:visible', false)"
  >
    <div v-loading="loading" class="detail-wrap">
      <template v-if="detail">
        <div v-if="canGenerateOrder" class="order-action">
          <el-button size="small" type="primary" icon="el-icon-plus" @click="goCreateOrder">生成工单</el-button>
        </div>
        <el-descriptions :column="3" size="small" border>
          <el-descriptions-item label="订单编号">{{ detail.order_no }}</el-descriptions-item>
          <el-descriptions-item label="订单类别">
            <el-tag size="mini" :type="detail.order_category === 'sales' ? 'primary' : 'warning'">{{ detail.order_category_text }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="订单状态">
            <el-tag size="mini" :type="statusTag(detail.order_status)">{{ detail.order_status_text }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="客户">{{ detail.customer_name }}</el-descriptions-item>
          <el-descriptions-item label="业务类型">{{ detail.business_type_text }}</el-descriptions-item>
          <el-descriptions-item label="订单金额"><b style="color:#f56c6c">¥{{ Number(detail.order_amount || 0).toLocaleString() }}</b></el-descriptions-item>
          <el-descriptions-item label="订单日期">{{ detail.order_date }}</el-descriptions-item>
          <el-descriptions-item label="交付日期">{{ detail.delivery_date || '--' }}</el-descriptions-item>
          <el-descriptions-item label="业务员">{{ detail.salesperson_name || '--' }}</el-descriptions-item>
          <el-descriptions-item label="联系人">{{ detail.contact_person || '--' }}</el-descriptions-item>
          <el-descriptions-item label="联系电话">{{ detail.contact_phone || '--' }}</el-descriptions-item>
          <el-descriptions-item label="创建人">{{ detail.created_by_name || '--' }}</el-descriptions-item>
        </el-descriptions>
        <div v-if="detail.remark" class="remark">备注：{{ detail.remark }}</div>

        <!-- 生产进度（关联工单） -->
        <div v-if="linkedOrders && linkedOrders.length" class="production-card">
          <div class="prod-title">生产进度</div>
          <el-table :data="linkedOrders" size="mini" border>
            <el-table-column label="工单编号" width="170">
              <template slot-scope="s"><span class="link-blue" @click="goOrderDetail(s.row.id)">{{ s.row.order_no }}</span></template>
            </el-table-column>
            <el-table-column label="工单状态" width="90" align="center">
              <template slot-scope="s"><el-tag size="mini" :type="s.row.status_tag">{{ s.row.status_label }}</el-tag></template>
            </el-table-column>
            <el-table-column label="生产进度" width="150">
              <template slot-scope="s"><el-progress :percentage="Number(s.row.progress)" :color="progressColor(s.row.progress)" /></template>
            </el-table-column>
            <el-table-column label="完成数量" width="90" align="right"><template slot-scope="s">{{ Number(s.row.completed_quantity) }}</template></el-table-column>
            <el-table-column prop="responsible_person_name" label="负责人" width="80" show-overflow-tooltip />
            <el-table-column prop="planned_end_date" label="预计完成日期" width="110" align="center" />
          </el-table>
        </div>

        <!-- 明细 -->
        <el-divider content-position="left">{{ detail.order_category === 'sales' ? '产品明细' : '产品维修明细' }}</el-divider>
        <el-table v-if="detail.order_category === 'sales'" :data="detail.items || []" size="mini" border>
          <el-table-column prop="product_name" label="产品名称" min-width="160" />
          <el-table-column prop="product_model" label="型号" width="110" />
          <el-table-column prop="quantity" label="数量" width="70" align="center" />
          <el-table-column label="单价" width="100"><template slot-scope="s">¥{{ Number(s.row.unit_price || 0).toLocaleString() }}</template></el-table-column>
          <el-table-column label="金额" width="110"><template slot-scope="s">¥{{ Number(s.row.amount || 0).toLocaleString() }}</template></el-table-column>
        </el-table>
        <el-table v-else :data="detail.items || []" size="mini" border>
          <el-table-column prop="product_code" label="产品编码" width="110" show-overflow-tooltip />
          <el-table-column prop="product_name" label="产品名称" min-width="150" show-overflow-tooltip />
          <el-table-column prop="product_spec" label="规格型号" width="100" show-overflow-tooltip />
          <el-table-column prop="product_unit" label="单位" width="60" align="center" />
          <el-table-column prop="quantity" label="数量" width="70" align="center" />
          <el-table-column label="单价" width="100"><template slot-scope="s">¥{{ Number(s.row.unit_price || 0).toLocaleString() }}</template></el-table-column>
          <el-table-column label="金额" width="110"><template slot-scope="s">¥{{ Number(s.row.total_amount || (Number(s.row.quantity || 0) * Number(s.row.unit_price || 0))).toLocaleString() }}</template></el-table-column>
        </el-table>

        <!-- 操作日志时间线 -->
        <el-divider content-position="left">订单日志</el-divider>
        <el-timeline v-if="detail.logs && detail.logs.length" class="log-timeline">
          <el-timeline-item v-for="l in detail.logs" :key="l.id" :timestamp="l.create_time" placement="top">
            <b>{{ l.action_text }}</b>（{{ l.operator_name }}）<span v-if="l.from_status">：{{ statusText(l.from_status) }} → {{ statusText(l.to_status) }}</span>
            <div v-if="l.remark" class="log-remark">{{ l.remark }}</div>
          </el-timeline-item>
        </el-timeline>
        <div v-else class="no-data">暂无操作日志</div>

        <!-- 评审记录 -->
        <el-divider content-position="left">评审记录</el-divider>
        <el-table v-if="detail.reviews && detail.reviews.length" :data="detail.reviews" size="mini" border>
          <el-table-column prop="reviewer_name" label="评审人" width="100" />
          <el-table-column label="结果" width="80"><template slot-scope="s"><el-tag size="mini" :type="s.row.review_result === 'pass' ? 'success' : 'danger'">{{ s.row.review_result_text }}</el-tag></template></el-table-column>
          <el-table-column prop="review_comment" label="意见" min-width="200" />
          <el-table-column prop="review_time" label="评审时间" width="160" />
        </el-table>
        <div v-else class="no-data">暂无评审记录</div>
      </template>
    </div>
  </el-dialog>
</template>

<script>
import { getOrderDetail } from '../../../../api/businessOrder'
import { getBySource } from '../../../../api/production'

export default {
  name: 'OrderDetailDialog',
  props: {
    visible: { type: Boolean, default: false },
    orderId: { type: Number, default: 0 }
  },
  data() {
    return { loading: false, detail: null, linkedOrders: [] }
  },
  computed: {
    sourceType() { return this.detail && this.detail.order_category === 'sales' ? 1 : 2 },
    canGenerateOrder() {
      return this.detail && ['reviewed', 'production'].includes(this.detail.order_status) && (!this.linkedOrders || !this.linkedOrders.length)
    }
  },
  watch: {
    visible(val) { if (val && this.orderId) this.open() }
  },
  methods: {
    async open() {
      this.loading = true
      this.detail = null
      this.linkedOrders = []
      try {
        const r = await getOrderDetail(this.orderId)
        if (r.code === 0) {
          this.detail = r.data
          // 加载关联工单（生产进度）
          const st = r.data.order_category === 'sales' ? 1 : 2
          try {
            const w = await getBySource({ source_type: st, source_id: this.orderId })
            if (w.code === 0) this.linkedOrders = w.data.list || []
          } catch (e) {}
        }
      } catch (e) {}
      this.loading = false
    },
    goCreateOrder() {
      this.$emit('update:visible', false)
      this.$router.push(`/production/plan/order/add?source_type=${this.sourceType}&source_id=${this.orderId}`)
    },
    goOrderDetail(id) {
      this.$emit('update:visible', false)
      this.$router.push(`/production/plan/order/detail/${id}`)
    },
    progressColor(p) { const v = Number(p); if (v < 30) return '#F56C6C'; if (v < 70) return '#E6A23C'; return '#67C23A' },
    statusTag(s) { return { pending: 'warning', reviewed: 'primary', production: 'danger', shipping: 'success', completed: 'info', cancelled: 'danger' }[s] || 'info' },
    statusText(s) { return { pending: '待评审', reviewed: '已评审', production: '生产中', shipping: '待发货', completed: '已完成', cancelled: '已取消' }[s] || (s || '--') }
  }
}
</script>

<style scoped>
.order-action { margin-bottom: 12px; }
.production-card { margin-top: 12px; background: #f8f9fb; padding: 12px; border-radius: 6px; }
.prod-title { font-size: 14px; font-weight: 600; margin-bottom: 10px; color: #303133; }
.link-blue { color: #409EFF; cursor: pointer; }
.remark { margin-top: 10px; font-size: 13px; color: #606266; background: #f8f9fb; padding: 8px 12px; border-radius: 4px; }
.log-timeline { padding-left: 4px; }
.log-remark { color: #909399; font-size: 12px; }
.no-data { color: #909399; font-size: 12px; padding: 10px 0; }
</style>
