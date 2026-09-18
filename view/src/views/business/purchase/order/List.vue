<!--
  文件：admin/src/views/business/purchase/order/List.vue
  功能：采购订单列表（搜索/分页/状态机操作/来源申请追溯/执行日志/导出）
  权限：business:purchase:order:list/add/edit/delete/export/approve
-->
<template>
  <div class="po-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购订单</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索区 -->
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="订单编号">
          <el-input v-model="q.order_no" placeholder="请输入订单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="订单标题">
          <el-input v-model="q.title" placeholder="请输入订单标题" clearable style="width:150px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="供应商">
          <el-select v-model="q.supplier_id" placeholder="全部" clearable filterable style="width:150px" @change="handleSearch">
            <el-option v-for="s in supplierOptions" :key="s.id" :label="s.supplier_name" :value="s.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="来源申请">
          <el-input v-model="q.request_no" placeholder="请输入来源申请编号" clearable style="width:140px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="订单状态">
          <el-select v-model="q.order_status" placeholder="全部" clearable style="width:110px" @change="handleSearch">
            <el-option label="全部" value="" /><el-option label="草稿" value="0" /><el-option label="已确认" value="1" /><el-option label="已发货" value="2" /><el-option label="部分入库" value="3" /><el-option label="已入库" value="4" /><el-option label="已关闭" value="5" /><el-option label="已中止" value="6" />
          </el-select>
        </el-form-item>
        <el-form-item label="付款状态">
          <el-select v-model="q.payment_status" placeholder="全部" clearable style="width:110px" @change="handleSearch">
            <el-option label="全部" value="" /><el-option label="未付款" value="0" /><el-option label="部分付款" value="1" /><el-option label="已付款" value="2" />
          </el-select>
        </el-form-item>
        <el-form-item label="审核状态">
          <el-select v-model="q.approval_status" placeholder="全部" clearable style="width:130px" @change="handleSearch">
            <el-option label="全部" value="" />
            <el-option label="草稿" value="0" />
            <el-option :label="'待审核(' + (statusCounts['1'] || 0) + ')'" value="1" />
            <el-option label="已审核" value="2" />
            <el-option label="已驳回" value="3" />
          </el-select>
        </el-form-item>
        <el-form-item label="订单日期">
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始" end-placeholder="结束" value-format="yyyy-MM-dd" style="width:240px" @change="handleSearch" />
        </el-form-item>
        <div class="filter-btns">
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </div>
      </el-form>
    </el-card>

    <!-- 工具栏 + 表格 -->
    <el-card shadow="never">
      <div class="toolbar">
        <el-button v-permission="'business:purchase:order:add'" type="primary" size="small" icon="el-icon-plus" @click="handleAdd">新增订单</el-button>
        <el-button v-permission="'business:purchase:order:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" @click="getList">刷新</el-button>
        <span class="flex-1"></span>
        <span class="total-tip">共 {{ total }} 条</span>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe border empty-text="暂无采购订单数据">
        <el-table-column type="index" label="序号" width="50" align="center" />
        <el-table-column prop="order_no" label="订单编号" width="150" show-overflow-tooltip>
          <template slot-scope="s"><span class="link-text" @click="viewDetail(s.row.id)">{{ s.row.order_no }}</span></template>
        </el-table-column>
        <el-table-column prop="title" label="订单标题" min-width="160" show-overflow-tooltip />
        <el-table-column prop="supplier_name" label="供应商" width="130" show-overflow-tooltip />
        <el-table-column label="来源申请" width="140" show-overflow-tooltip>
          <template slot-scope="s">
            <span v-if="s.row.request_no" class="link-text" @click="viewRequest(s.row.request_id)">{{ s.row.request_no }}</span>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column label="订单总金额" width="120" align="right">
          <template slot-scope="s">¥ {{ s.row.total_amount }}</template>
        </el-table-column>
        <el-table-column label="订单状态" width="100" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="statusTag(s.row.order_status)">{{ s.row.order_status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column label="付款状态" width="90" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="paymentTag(s.row.payment_status)">{{ s.row.payment_status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column label="审核状态" width="100" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="approvalTag(s.row.approval_status)">{{ s.row.approval_status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="order_date" label="订单日期" width="105" align="center" />
        <el-table-column label="期望交货" width="105" align="center">
          <template slot-scope="s">
            <span :class="{ 'date-overdue': s.row.expected_date && s.row.expected_date < today }">{{ s.row.expected_date || '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="250" align="center" fixed="right">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="viewDetail(s.row.id)">详情</el-button>
            <el-button v-if="s.row.order_status === 0 && (s.row.approval_status === 0 || s.row.approval_status === 3)" v-permission="'business:purchase:order:edit'" type="text" size="mini" @click="handleEdit(s.row.id)">编辑</el-button>
            <el-button v-if="s.row.order_status === 0 && (s.row.approval_status === 0 || s.row.approval_status === 3)" v-permission="'business:purchase:order:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row.id)">删除</el-button>
            <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
              <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right"></i></el-button>
              <el-dropdown-menu slot="dropdown">
                <el-dropdown-item v-if="s.row.approval_status === 0" v-permission="'business:purchase:order:approve'" command="submit">提交审核</el-dropdown-item>
                <el-dropdown-item v-if="s.row.approval_status === 1" v-permission="'business:purchase:order:approve'" command="approve">审批通过</el-dropdown-item>
                <el-dropdown-item v-if="s.row.approval_status === 1" v-permission="'business:purchase:order:approve'" command="reject">审批驳回</el-dropdown-item>
                <el-dropdown-item v-if="s.row.approval_status === 2 && s.row.order_status === 0" v-permission="'business:purchase:order:edit'" command="confirm">确认订单</el-dropdown-item>
                <el-dropdown-item v-if="s.row.order_status === 1" v-permission="'business:purchase:order:edit'" command="ship">发货登记</el-dropdown-item>
                <el-dropdown-item v-if="s.row.order_status === 2 || s.row.order_status === 3" v-permission="'business:purchase:order:edit'" command="receive">入库登记</el-dropdown-item>
                <el-dropdown-item v-if="s.row.order_status === 1 || s.row.order_status === 2 || s.row.order_status === 3" v-permission="'business:purchase:order:edit'" command="abort">中止订单</el-dropdown-item>
                <el-dropdown-item command="track">查看执行进度</el-dropdown-item>
                <el-dropdown-item command="logs">查看执行日志</el-dropdown-item>
                <el-dropdown-item v-if="s.row.request_id" command="contract">查看关联合同</el-dropdown-item>
              </el-dropdown-menu>
            </el-dropdown>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper" :total="total" :page-sizes="[10, 20, 50, 100]" :page-size="q.pageSize" :current-page="q.page" @current-change="handlePageChange" @size-change="handleSizeChange" />
    </el-card>

    <!-- 发货登记弹窗 -->
    <el-dialog title="发货登记" :visible="shipVisible" width="480px" :close-on-click-modal="false" @close="shipVisible = false">
      <el-form label-width="100px" size="small">
        <el-form-item label="物流公司">
          <el-input v-model="shipForm.logistics_company" placeholder="物流公司" clearable />
        </el-form-item>
        <el-form-item label="物流单号">
          <el-input v-model="shipForm.tracking_no" placeholder="物流单号" clearable />
        </el-form-item>
        <el-form-item label="发货日期">
          <el-date-picker v-model="shipForm.ship_date" type="date" value-format="yyyy-MM-dd" style="width:100%" />
        </el-form-item>
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
          <el-select v-model="receiveForm.order_item_id" filterable placeholder="选择入库明细（产品/剩余可入库）" style="width:100%" @change="onReceiveItemChange">
            <el-option v-for="it in receiveItems" :key="it.id" :label="it.product_name + '（剩余 ' + remainOf(it) + '）'" :value="it.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="入库数量" required>
          <el-input-number v-model="receiveForm.receive_quantity" :min="0" :precision="0" :max="receiveMax" style="width:100%" />
        </el-form-item>
        <el-form-item label="仓库">
          <el-input v-model="receiveForm.warehouse" placeholder="仓库（可选）" clearable />
        </el-form-item>
        <el-form-item label="入库日期">
          <el-date-picker v-model="receiveForm.receive_date" type="date" value-format="yyyy-MM-dd" style="width:100%" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="receiveVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="receiveSaving" @click="confirmReceive">确认入库</el-button>
      </div>
    </el-dialog>

    <!-- 执行日志弹窗 -->
    <el-dialog title="执行日志" :visible="logVisible" width="680px" :close-on-click-modal="false" @close="logVisible = false">
      <el-table :data="logList" size="small" border>
        <el-table-column prop="action_label" label="操作类型" width="90" align="center" />
        <el-table-column prop="operator_name" label="操作人" width="100" />
        <el-table-column prop="create_time" label="操作时间" width="160" align="center" />
        <el-table-column prop="remark" label="变更详情" min-width="200" show-overflow-tooltip />
      </el-table>
      <el-empty v-if="!logList.length" description="暂无执行日志" :image-size="60" />
    </el-dialog>
  </div>
</template>

<script>
import {
  getOrderList, deleteOrder, submitOrderApproval, confirmOrder, registerShipment, registerReceipt,
  abortOrder, getOrderLogs, getOrderDetail, exportOrders, approveOrder, rejectOrder
} from '../../../../api/purchase'
import { getSupplierList } from '../../../../api/businessSupplier'

export default {
  name: 'BusinessPurchaseOrderList',
  data() {
    return {
      loading: false,
      exporting: false,
      list: [],
      total: 0,
      supplierOptions: [],
      statusCounts: {},
      dateRange: [],
      today: new Date().toISOString().slice(0, 10),
      q: { page: 1, pageSize: 10, order_no: '', title: '', supplier_id: '', request_no: '', order_status: '', payment_status: '', approval_status: '', start_date: '', end_date: '' },
      shipVisible: false, shipSaving: false, shipRow: null, shipForm: { logistics_company: '', tracking_no: '', ship_date: '' },
      receiveVisible: false, receiveSaving: false, receiveRow: null, receiveItems: [], receiveForm: { order_item_id: null, receive_quantity: 0, warehouse: '', receive_date: '' },
      logVisible: false, logList: []
    }
  },
  computed: {
    receiveMax() {
      const it = this.receiveItems.find(x => x.id === this.receiveForm.order_item_id)
      return it ? Math.max(0, Number(it.quantity) - Number(it.received_quantity)) : 0
    }
  },
  created() {
    this.loadSuppliers()
    this.getList()
  },
  methods: {
    statusTag(t) { return ['info', 'primary', 'warning', 'purple', 'success', 'info', 'danger'][t] || 'info' },
    paymentTag(t) { return ['info', 'warning', 'success'][t] || 'info' },
    approvalTag(t) { return ['info', 'warning', 'success', 'danger'][t] || 'info' },
    remainOf(it) { return Math.max(0, Number(it.quantity) - Number(it.received_quantity)) },
    async loadSuppliers() {
      try {
        const r = await getSupplierList({ status: 1, page: 1, pageSize: 100 })
        this.supplierOptions = (r.code === 0 && r.data) ? (r.data.list || []) : []
      } catch (e) { this.supplierOptions = [] }
    },
    buildParams() {
      const p = { ...this.q }
      if (this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] } else { p.start_date = ''; p.end_date = '' }
      return p
    },
    async getList() {
      this.loading = true
      try {
        const r = await getOrderList(this.buildParams())
        if (r.code === 0) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.statusCounts = r.data.status_counts || {}
        }
      } catch (e) {}
      this.loading = false
    },
    handleSearch() { this.q.page = 1; this.getList() },
    handleReset() {
      this.q = { page: 1, pageSize: this.q.pageSize, order_no: '', title: '', supplier_id: '', request_no: '', order_status: '', payment_status: '', approval_status: '', start_date: '', end_date: '' }
      this.dateRange = []
      this.handleSearch()
    },
    handlePageChange(p) { this.q.page = p; this.getList() },
    handleSizeChange(size) { this.q.pageSize = size; this.q.page = 1; this.getList() },
    handleAdd() { this.$router.push('/business/purchase/order/add') },
    viewDetail(id) { this.$router.push(`/business/purchase/order/detail/${id}`) },
    handleEdit(id) { this.$router.push(`/business/purchase/order/edit/${id}`) },
    viewRequest(id) { if (id) this.$router.push(`/business/purchase/request/detail/${id}`) },
    handleDelete(id) {
      this.$confirm('确认删除该采购订单吗？删除后不可恢复', '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteOrder(id)
          if (r.code === 0) {
            this.$message.success('删除成功')
            await this.getList()
            if (!this.list.length && this.q.page > 1) { this.q.page -= 1; await this.getList() }
          }
        } catch (e) {}
      }).catch(() => {})
    },
    async handleMore(cmd, row) {
      if (cmd === 'submit') {
        try {
          const r = await submitOrderApproval(row.id)
          if (r.code === 0) { this.$message.success('已提交审核'); this.getList() }
        } catch (e) {}
      } else if (cmd === 'approve') {
        this.$prompt('请输入审批意见（选填）', '审批通过', { inputPlaceholder: '审批意见', confirmButtonText: '通过', cancelButtonText: '取消', inputValue: '同意' })
          .then(({ value }) => approveOrder(row.id, value || '同意'))
          .then((r) => {
            if (r.code === 0) { this.$message.success('已审批通过'); this.getList() } else this.$message.error(r.msg || '审批失败')
          }).catch(() => {})
      } else if (cmd === 'reject') {
        this.$prompt('请输入驳回原因', '审批驳回', { inputPlaceholder: '驳回原因', confirmButtonText: '驳回', cancelButtonText: '取消' })
          .then(({ value }) => {
            if (!value) { this.$message.warning('请填写驳回原因'); return Promise.reject('empty') }
            return rejectOrder(row.id, value)
          })
          .then((r) => {
            if (r.code === 0) { this.$message.success('已驳回'); this.getList() } else this.$message.error(r.msg || '驳回失败')
          }).catch(() => {})
      } else if (cmd === 'confirm') {
        this.$confirm('确认向供应商发出该采购订单吗？确认后订单进入执行阶段', '确认订单', { type: 'info' }).then(async () => {
          try {
            const r = await confirmOrder(row.id)
            if (r.code === 0) { this.$message.success('订单已确认'); this.getList() }
          } catch (e) {}
        }).catch(() => {})
      } else if (cmd === 'ship') {
        this.shipRow = row
        this.shipForm = { logistics_company: '', tracking_no: '', ship_date: this.today }
        this.shipVisible = true
      } else if (cmd === 'receive') {
        this.receiveRow = row
        this.receiveForm = { order_item_id: null, receive_quantity: 0, warehouse: '', receive_date: this.today }
        try {
          const r = await getOrderDetail(row.id)
          this.receiveItems = (r.code === 0 && r.data && r.data.items) ? r.data.items : []
        } catch (e) { this.receiveItems = [] }
        this.receiveVisible = true
      } else if (cmd === 'abort') {
        this.$confirm('确认中止该采购订单吗？中止后订单将不可继续执行', '中止确认', { type: 'warning' }).then(async () => {
          try {
            const r = await abortOrder(row.id)
            if (r.code === 0) { this.$message.success('订单已中止'); this.getList() }
          } catch (e) {}
        }).catch(() => {})
      } else if (cmd === 'track') {
        this.$router.push({ path: '/business/purchase/order/track', query: { id: row.id } })
      } else if (cmd === 'logs') {
        try {
          const r = await getOrderLogs(row.id)
          this.logList = (r.code === 0 && r.data) ? r.data : []
          this.logVisible = true
        } catch (e) { this.logList = [] }
      } else if (cmd === 'contract') {
        this.$router.push('/business/contract')
      }
    },
    onReceiveItemChange() { this.receiveForm.receive_quantity = 0 },
    async confirmShip() {
      this.shipSaving = true
      try {
        const r = await registerShipment(this.shipRow.id, this.shipForm)
        if (r.code === 0) { this.$message.success('发货登记成功'); this.shipVisible = false; this.getList() }
      } catch (e) {}
      this.shipSaving = false
    },
    async confirmReceive() {
      if (!this.receiveForm.order_item_id) { this.$message.warning('请选择入库明细'); return }
      if (!(this.receiveForm.receive_quantity > 0)) { this.$message.warning('请填写入库数量'); return }
      this.receiveSaving = true
      try {
        const r = await registerReceipt(this.receiveRow.id, this.receiveForm)
        if (r.code === 0) { this.$message.success(r.msg); this.receiveVisible = false; this.getList() }
      } catch (e) {}
      this.receiveSaving = false
    },
    async handleExport() {
      this.exporting = true
      try {
        const res = await exportOrders(this.buildParams())
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('导出失败'); return }
        const filename = this.resolveName(res.headers) || '采购订单列表_' + this.stamp() + '.xlsx'
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = filename
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
      } catch (e) {}
      this.exporting = false
    },
    resolveName(headers) {
      if (!headers) return null
      const d = headers['content-disposition'] || ''
      const star = d.match(/filename\*=(?:UTF-8'')?([^;]+)/i)
      if (star) return decodeURIComponent(star[1].replace(/^"|"$/g, ''))
      const plain = d.match(/filename="?([^";]+)"?/i)
      return plain ? plain[1] : null
    },
    stamp() {
      const n = new Date()
      const pad = x => String(x).padStart(2, '0')
      return `${n.getFullYear()}${pad(n.getMonth() + 1)}${pad(n.getDate())}_${pad(n.getHours())}${pad(n.getMinutes())}${pad(n.getSeconds())}`
    }
  }
}
</script>

<style scoped>
.po-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.filter-card { margin-bottom: 14px; }
.filter-btns { display: flex; align-items: center; margin-left: 8px; }
.filter-btns .el-button + .el-button { margin-left: 10px; }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.total-tip { font-size: 14px; color: #909399; }
.link-text { color: #409eff; cursor: pointer; }
.date-overdue { color: #f56c6c; }
.pager { margin: 20px 0; text-align: right; }
.danger { color: #f56c6c; }
::v-deep .el-tag--purple { background-color: #f3e5f5; border-color: #ce93d8; color: #8e24aa; }
</style>
