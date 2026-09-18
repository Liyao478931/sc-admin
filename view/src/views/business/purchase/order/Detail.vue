<!--
  文件：admin/src/views/business/purchase/order/Detail.vue
  功能：采购订单详情（信息卡 + 明细 + 执行日志 + 状态机操作）
  权限：页面 business:purchase:order:list；状态机操作 edit/approve
-->
<template>
  <div class="po-detail-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购订单</el-breadcrumb-item>
      <el-breadcrumb-item>订单详情</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">采购订单详情 - {{ order.order_no || '' }}</span>
      <div class="header-actions">
        <el-button size="small" @click="$router.push('/business/purchase/order/list')">返回列表</el-button>
        <el-button v-if="order.order_status === 0 && (order.approval_status === 0 || order.approval_status === 3)" v-permission="'business:purchase:order:edit'" type="primary" size="small" @click="$router.push(`/business/purchase/order/edit/${id}`)">编辑</el-button>
        <el-button v-if="order.approval_status === 0" v-permission="'business:purchase:order:approve'" type="primary" size="small" @click="handleSubmit">提交审核</el-button>
        <el-button v-if="order.approval_status === 1" v-permission="'business:purchase:order:approve'" type="success" size="small" @click="handleApprove">审批通过</el-button>
        <el-button v-if="order.approval_status === 1" v-permission="'business:purchase:order:approve'" type="danger" size="small" @click="handleReject">审批驳回</el-button>
        <el-button v-if="order.approval_status === 2 && order.order_status === 0" v-permission="'business:purchase:order:edit'" type="primary" size="small" @click="handleConfirm">确认订单</el-button>
        <el-button v-if="order.order_status === 1" v-permission="'business:purchase:order:edit'" size="small" @click="openShip">发货登记</el-button>
        <el-button v-if="order.order_status === 2 || order.order_status === 3" v-permission="'business:purchase:order:edit'" size="small" @click="openReceive">入库登记</el-button>
        <el-button v-if="order.order_status === 1 || order.order_status === 2 || order.order_status === 3" v-permission="'business:purchase:order:edit'" type="danger" size="small" plain @click="handleAbort">中止订单</el-button>
      </div>
    </div>

    <el-card shadow="never" v-loading="loading">
      <template v-if="loadFailed">
        <el-empty description="加载失败，请刷新重试">
          <el-button size="small" @click="$router.push('/business/purchase/order/list')">返回列表</el-button>
        </el-empty>
      </template>
      <template v-else-if="order.id">
        <div class="section-title">订单信息</div>
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="订单编号">{{ order.order_no }}</el-descriptions-item>
          <el-descriptions-item label="订单标题">{{ order.title }}</el-descriptions-item>
          <el-descriptions-item label="供应商">{{ order.supplier_name }}</el-descriptions-item>
          <el-descriptions-item label="来源采购申请">
            <span v-if="order.request_no" class="link-text" @click="$router.push(`/business/purchase/request/detail/${order.request_id}`)">{{ order.request_no }}</span>
            <span v-else>-</span>
          </el-descriptions-item>
          <el-descriptions-item label="订单总金额">¥ {{ order.total_amount }}</el-descriptions-item>
          <el-descriptions-item label="已入库数量">{{ order.received_quantity }}</el-descriptions-item>
          <el-descriptions-item label="订单状态"><el-tag size="mini" :type="statusTag(order.order_status)">{{ order.order_status_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="付款状态"><el-tag size="mini" :type="paymentTag(order.payment_status)">{{ order.payment_status_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="审核状态"><el-tag size="mini" :type="approvalTag(order.approval_status)">{{ order.approval_status_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="订单日期">{{ order.order_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="期望交货日期">{{ order.expected_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="收货地址">{{ order.receive_address || '-' }}</el-descriptions-item>
          <el-descriptions-item label="收货人/电话">{{ (order.receiver || '-') + ' / ' + (order.receiver_phone || '-') }}</el-descriptions-item>
          <el-descriptions-item label="付款条款">{{ order.payment_terms || '-' }}</el-descriptions-item>
          <el-descriptions-item label="运输方式">{{ order.transport_type || '-' }}</el-descriptions-item>
          <el-descriptions-item label="审核人">{{ order.approver_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="审核日期">{{ order.approval_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="审核备注" :span="2">{{ order.approval_remark || '-' }}</el-descriptions-item>
          <el-descriptions-item label="备注" :span="2">{{ order.remark || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建人">{{ order.created_by_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ order.create_time || '-' }}</el-descriptions-item>
        </el-descriptions>

        <div class="section-title">订单明细</div>
        <el-table :data="items" size="small" border>
          <el-table-column type="index" label="序号" width="55" align="center" />
          <el-table-column prop="product_code" label="产品编码" width="120" show-overflow-tooltip />
          <el-table-column prop="product_name" label="产品名称" min-width="140" show-overflow-tooltip />
          <el-table-column prop="product_spec" label="规格型号" width="110" show-overflow-tooltip />
          <el-table-column prop="product_unit" label="单位" width="60" align="center" />
          <el-table-column prop="quantity" label="下单数量" width="90" align="right" />
          <el-table-column prop="received_quantity" label="已入库" width="90" align="right" />
          <el-table-column label="采购单价" width="100" align="right"><template slot-scope="s">¥ {{ s.row.unit_price }}</template></el-table-column>
          <el-table-column label="总价" width="100" align="right"><template slot-scope="s">¥ {{ s.row.total_amount }}</template></el-table-column>
          <el-table-column prop="need_date" label="需求日期" width="100" align="center" />
        </el-table>

        <div class="section-title">执行日志</div>
        <el-table :data="logs" size="small" border>
          <el-table-column prop="action_label" label="操作类型" width="100" align="center" />
          <el-table-column prop="operator_name" label="操作人" width="110" />
          <el-table-column prop="create_time" label="操作时间" width="160" align="center" />
          <el-table-column prop="remark" label="变更详情" min-width="200" show-overflow-tooltip />
        </el-table>
        <el-empty v-if="!logs.length" description="暂无执行日志" :image-size="60" />
      </template>
    </el-card>

    <!-- 发货登记弹窗 -->
    <el-dialog title="发货登记" :visible="shipVisible" width="480px" :close-on-click-modal="false" @close="shipVisible = false">
      <el-form label-width="100px" size="small">
        <el-form-item label="物流公司"><el-input v-model="shipForm.logistics_company" placeholder="物流公司" clearable /></el-form-item>
        <el-form-item label="物流单号"><el-input v-model="shipForm.tracking_no" placeholder="物流单号" clearable /></el-form-item>
        <el-form-item label="发货日期"><el-date-picker v-model="shipForm.ship_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="shipVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="shipSaving" @click="confirmShip">确认登记</el-button>
      </div>
    </el-dialog>

    <!-- 入库登记弹窗 -->
    <el-dialog title="入库登记" :visible="receiveVisible" width="560px" :close-on-click-modal="false" @close="receiveVisible = false">
      <el-form label-width="100px" size="small">
        <el-form-item label="订单明细" required>
          <el-select v-model="receiveForm.order_item_id" filterable placeholder="选择入库明细（产品/剩余可入库）" style="width:100%" @change="receiveForm.receive_quantity = 0">
            <el-option v-for="it in items" :key="it.id" :label="it.product_name + '（剩余 ' + remainOf(it) + '）'" :value="it.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="入库数量" required>
          <el-input-number v-model="receiveForm.receive_quantity" :min="0" :precision="0" :max="receiveMax" style="width:100%" />
        </el-form-item>
        <el-form-item label="仓库"><el-input v-model="receiveForm.warehouse" placeholder="仓库（可选）" clearable /></el-form-item>
        <el-form-item label="入库日期"><el-date-picker v-model="receiveForm.receive_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="receiveVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="receiveSaving" @click="confirmReceive">确认入库</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import {
  getOrderDetail, submitOrderApproval, confirmOrder, registerShipment, registerReceipt, abortOrder, approveOrder, rejectOrder
} from '../../../../api/purchase'

export default {
  name: 'BusinessPurchaseOrderDetail',
  data() {
    return {
      id: Number(this.$route.params.id) || 0,
      loading: false,
      loadFailed: false,
      order: {},
      items: [],
      logs: [],
      shipVisible: false, shipSaving: false, shipForm: { logistics_company: '', tracking_no: '', ship_date: '' },
      receiveVisible: false, receiveSaving: false, receiveForm: { order_item_id: null, receive_quantity: 0, warehouse: '', receive_date: '' }
    }
  },
  computed: {
    receiveMax() {
      const it = this.items.find(x => x.id === this.receiveForm.order_item_id)
      return it ? Math.max(0, Number(it.quantity) - Number(it.received_quantity)) : 0
    }
  },
  created() {
    this.fetchDetail()
  },
  methods: {
    statusTag(t) { return ['info', 'primary', 'warning', 'purple', 'success', 'info', 'danger'][t] || 'info' },
    paymentTag(t) { return ['info', 'warning', 'success'][t] || 'info' },
    approvalTag(t) { return ['info', 'warning', 'success', 'danger'][t] || 'info' },
    remainOf(it) { return Math.max(0, Number(it.quantity) - Number(it.received_quantity)) },
    async fetchDetail() {
      this.loading = true
      this.loadFailed = false
      try {
        const r = await getOrderDetail(this.id)
        if (r.code === 0 && r.data) {
          this.order = r.data.order || {}
          this.items = r.data.items || []
          this.logs = r.data.logs || []
        } else {
          this.loadFailed = true
        }
      } catch (e) { this.loadFailed = true }
      this.loading = false
    },
    async handleSubmit() {
      try {
        const r = await submitOrderApproval(this.id)
        if (r.code === 0) { this.$message.success('已提交审核'); this.fetchDetail() }
      } catch (e) {}
    },
    async handleApprove() {
      try {
        const { value } = await this.$prompt('请输入审批意见（选填）', '审批通过', { inputPlaceholder: '审批意见', confirmButtonText: '通过', cancelButtonText: '取消', inputValue: '同意' })
        const r = await approveOrder(this.id, value || '同意')
        if (r.code === 0) { this.$message.success('已审批通过'); this.fetchDetail() } else this.$message.error(r.msg || '审批失败')
      } catch (e) {}
    },
    async handleReject() {
      try {
        const { value } = await this.$prompt('请输入驳回原因', '审批驳回', { inputPlaceholder: '驳回原因', confirmButtonText: '驳回', cancelButtonText: '取消' })
        if (!value) { this.$message.warning('请填写驳回原因'); return }
        const r = await rejectOrder(this.id, value)
        if (r.code === 0) { this.$message.success('已驳回'); this.fetchDetail() } else this.$message.error(r.msg || '驳回失败')
      } catch (e) {}
    },
    handleConfirm() {
      this.$confirm('确认向供应商发出该采购订单吗？确认后订单进入执行阶段', '确认订单', { type: 'info' }).then(async () => {
        try {
          const r = await confirmOrder(this.id)
          if (r.code === 0) { this.$message.success('订单已确认'); this.fetchDetail() }
        } catch (e) {}
      }).catch(() => {})
    },
    openShip() {
      this.shipForm = { logistics_company: '', tracking_no: '', ship_date: new Date().toISOString().slice(0, 10) }
      this.shipVisible = true
    },
    async confirmShip() {
      this.shipSaving = true
      try {
        const r = await registerShipment(this.id, this.shipForm)
        if (r.code === 0) { this.$message.success('发货登记成功'); this.shipVisible = false; this.fetchDetail() }
      } catch (e) {}
      this.shipSaving = false
    },
    openReceive() {
      this.receiveForm = { order_item_id: null, receive_quantity: 0, warehouse: '', receive_date: new Date().toISOString().slice(0, 10) }
      this.receiveVisible = true
    },
    async confirmReceive() {
      if (!this.receiveForm.order_item_id) { this.$message.warning('请选择入库明细'); return }
      if (!(this.receiveForm.receive_quantity > 0)) { this.$message.warning('请填写入库数量'); return }
      this.receiveSaving = true
      try {
        const r = await registerReceipt(this.id, this.receiveForm)
        if (r.code === 0) { this.$message.success(r.msg); this.receiveVisible = false; this.fetchDetail() }
      } catch (e) {}
      this.receiveSaving = false
    },
    handleAbort() {
      this.$confirm('确认中止该采购订单吗？中止后订单将不可继续执行', '中止确认', { type: 'warning' }).then(async () => {
        try {
          const r = await abortOrder(this.id)
          if (r.code === 0) { this.$message.success('订单已中止'); this.fetchDetail() }
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.po-detail-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 700; color: #303133; }
.header-actions .el-button + .el-button { margin-left: 10px; }
.section-title { display: flex; align-items: center; font-size: 15px; font-weight: 600; margin: 18px 0 12px; }
.section-title::before { content: ''; width: 4px; height: 14px; border-radius: 2px; background: #409eff; margin-right: 8px; }
.link-text { color: #409eff; cursor: pointer; }
</style>
