<!--
  文件：admin/src/views/business/order/index.vue
  功能：经营管理 → 订单中心 → 订单管理
    - 统计卡片（总数/待评审/进行中/本月订单数/本月金额）
    - 筛选（关键词/类别/状态/订单日期/交付日期/业务员）
    - 订单列表 Tab + 订单评审 Tab
    - 操作：详情/编辑/提交评审/评审/状态变更/复制/删除/打印
    - 弹窗：新增编辑/详情/评审/状态变更
-->
<template>
  <div class="order-page">
    <!-- ===== 统计卡片 ===== -->
    <el-row :gutter="14" class="stat-row">
      <el-col :span="4"><el-card shadow="never" class="stat-card"><div class="stat-num">{{ stats.total || 0 }}</div><div class="stat-label">订单总数</div></el-card></el-col>
      <el-col :span="4"><el-card shadow="never" class="stat-card"><div class="stat-num orange">{{ stats.pending || 0 }}</div><div class="stat-label">待评审</div></el-card></el-col>
      <el-col :span="4"><el-card shadow="never" class="stat-card"><div class="stat-num blue">{{ stats.progress || 0 }}</div><div class="stat-label">进行中</div></el-card></el-col>
      <el-col :span="4"><el-card shadow="never" class="stat-card"><div class="stat-num green">{{ stats.month_new || 0 }}</div><div class="stat-label">本月订单</div></el-card></el-col>
      <el-col :span="8"><el-card shadow="never" class="stat-card"><div class="stat-num red">¥{{ Number(stats.month_amount || 0).toLocaleString() }}</div><div class="stat-label">本月订单金额</div></el-card></el-col>
    </el-row>

    <el-tabs v-model="activeTab" type="border-card">
      <!-- ===== 订单列表 ===== -->
      <el-tab-pane label="订单列表" name="list">
        <el-card shadow="never" class="filter-card">
          <el-form inline size="small" @submit.native.prevent>
            <el-form-item label="关键词">
              <el-input v-model="filter.keyword" placeholder="订单编号/客户/业务员" clearable style="width:170px" @keyup.enter.native="search" />
            </el-form-item>
            <el-form-item label="订单类别">
              <el-select v-model="filter.order_category" placeholder="全部" clearable style="width:110px">
                <el-option v-for="opt in categoryOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
              </el-select>
            </el-form-item>
            <el-form-item label="订单状态">
              <el-select v-model="filter.order_status" placeholder="全部" clearable style="width:110px">
                <el-option v-for="opt in statusOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
              </el-select>
            </el-form-item>
            <el-form-item label="订单日期">
              <el-date-picker v-model="orderRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:220px" />
            </el-form-item>
            <el-form-item label="交付日期">
              <el-date-picker v-model="deliveryRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:220px" />
            </el-form-item>
            <el-form-item label="业务员">
              <el-select v-model="filter.salesperson_id" placeholder="全部" clearable filterable style="width:130px">
                <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
              </el-select>
            </el-form-item>
            <el-form-item>
              <el-button type="primary" icon="el-icon-search" @click="search">搜索</el-button>
              <el-button icon="el-icon-refresh-left" @click="reset">重置</el-button>
            </el-form-item>
          </el-form>
        </el-card>

        <div class="toolbar">
          <el-button v-if="hasPerm('business:order:add')" type="primary" size="small" icon="el-icon-plus" @click="openAdd">新增订单</el-button>
          <el-button v-if="hasPerm('business:order:export')" size="small" icon="el-icon-download" @click="handleExport">导出订单</el-button>
          <span class="flex-1"></span>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </div>

        <el-table :data="list" v-loading="loading" size="small" stripe border>
          <el-table-column prop="order_no" label="订单编号" width="160" show-overflow-tooltip />
          <el-table-column label="订单类别" width="90" align="center">
            <template slot-scope="s"><el-tag size="mini" :type="s.row.order_category === 'sales' ? 'primary' : 'warning'">{{ s.row.order_category_text }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="customer_name" label="客户名称" min-width="160" show-overflow-tooltip />
          <el-table-column label="订单金额" width="110">
            <template slot-scope="s">¥{{ Number(s.row.order_amount || 0).toLocaleString() }}</template>
          </el-table-column>
          <el-table-column label="订单状态" width="90" align="center">
            <template slot-scope="s"><el-tag size="mini" :type="statusTag(s.row.order_status)">{{ s.row.order_status_text }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="order_date" label="订单日期" width="105" />
          <el-table-column prop="delivery_date" label="交付日期" width="105" />
          <el-table-column prop="salesperson_name" label="业务员" width="90" />
          <el-table-column label="关联合同" width="150" show-overflow-tooltip>
            <template slot-scope="s">
              <span v-if="s.row.contract_no" class="link-text" @click="viewContract(s.row.contract_id)">{{ s.row.contract_no }}</span>
              <span v-else class="gray">未关联</span>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="280" align="center" fixed="right">
            <template slot-scope="s">
              <el-button type="text" size="mini" @click="openDetail(s.row.id)">详情</el-button>
              <el-button v-if="hasPerm('business:order:edit')" type="text" size="mini" @click="openContractBind(s.row)">合同</el-button>
              <el-button type="text" size="mini" @click="openPrint(s.row)">打印</el-button>
              <el-button v-if="hasPerm('business:order:edit') && s.row.order_status === 'pending'" type="text" size="mini" @click="openForm(s.row)">编辑</el-button>
              <el-button v-if="hasPerm('business:order:edit') && s.row.order_status === 'pending'" type="text" size="mini" @click="handleSubmit(s.row)">提交评审</el-button>
              <el-button v-if="hasPerm('business:order:review') && s.row.order_status === 'pending'" type="text" size="mini" class="orange" @click="openReview(s.row.id)">评审</el-button>
              <el-button v-if="hasPerm('business:order:edit') && !['completed','cancelled'].includes(s.row.order_status)" type="text" size="mini" @click="openStatus(s.row)">状态</el-button>
              <el-button v-if="hasPerm('business:order:add')" type="text" size="mini" @click="handleCopy(s.row)">复制</el-button>
              <el-button v-if="hasPerm('business:order:delete') && s.row.order_status === 'pending'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
        <el-pagination class="pager" small background layout="total, prev, pager, next" :total="total" :page-size="pageSize" :current-page="page" @current-change="p => { page = p; loadList() }" />
      </el-tab-pane>

      <!-- ===== 订单评审 ===== -->
      <el-tab-pane label="订单评审" name="review">
        <div class="toolbar">
          <el-input v-model="reviewKeyword" placeholder="订单编号/客户搜索" size="small" clearable style="width:200px" @keyup.enter.native="loadReview" />
          <el-select v-model="reviewStatus" placeholder="全部状态" clearable size="small" style="width:130px;margin-left:10px" @change="loadReview">
            <el-option v-for="opt in statusOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
          <span class="flex-1"></span>
          <el-button size="small" icon="el-icon-refresh" @click="loadReview">刷新</el-button>
        </div>
        <el-table :data="reviewList" v-loading="reviewLoading" size="small" stripe border>
          <el-table-column prop="order_no" label="订单编号" width="160" />
          <el-table-column prop="customer_name" label="客户名称" min-width="160" show-overflow-tooltip />
          <el-table-column label="订单类别" width="90" align="center"><template slot-scope="s"><el-tag size="mini" :type="s.row.order_category === 'sales' ? 'primary' : 'warning'">{{ s.row.order_category_text }}</el-tag></template></el-table-column>
          <el-table-column label="订单金额" width="110"><template slot-scope="s">¥{{ Number(s.row.order_amount || 0).toLocaleString() }}</template></el-table-column>
          <el-table-column label="状态" width="90" align="center"><template slot-scope="s"><el-tag size="mini" :type="statusTag(s.row.order_status)">{{ s.row.order_status_text }}</el-tag></template></el-table-column>
          <el-table-column prop="order_date" label="订单日期" width="105" />
          <el-table-column label="最近评审" min-width="160">
            <template slot-scope="s">
              <template v-if="s.row.last_review">{{ s.row.last_review.result_text }} · {{ s.row.last_review.reviewer }} · {{ s.row.last_review.time }}</template>
              <span v-else class="gray">--</span>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="90" align="center">
            <template slot-scope="s">
              <el-button v-if="hasPerm('business:order:review') && s.row.order_status === 'pending'" type="text" size="mini" class="orange" @click="openReview(s.row.id)">评审</el-button>
              <el-button v-else type="text" size="mini" @click="openDetail(s.row.id)">详情</el-button>
            </template>
          </el-table-column>
        </el-table>
        <el-pagination class="pager" small background layout="total, prev, pager, next" :total="reviewTotal" :page-size="20" :current-page="reviewPage" @current-change="p => { reviewPage = p; loadReview() }" />
      </el-tab-pane>
    </el-tabs>

    <!-- ===== 弹窗 ===== -->
    <OrderAddDialog ref="addDialog" @success="onAddSuccess" />
    <OrderFormDialog :visible="formVisible" :row="currentRow" @update:visible="v => (formVisible = v)" @success="onFormSuccess" />
    <OrderDetailDialog :visible="detailVisible" :order-id="detailId" @update:visible="v => (detailVisible = v)" />
    <OrderReviewDialog :visible="reviewVisible" :order-id="reviewOrderId" @update:visible="v => (reviewVisible = v)" @success="onReviewSuccess" />
    <OrderStatusDialog :visible="statusVisible" :row="currentRow" @update:visible="v => (statusVisible = v)" @success="onStatusSuccess" />

    <!-- 关联合同弹窗（多个订单可关联同一合同） -->
    <el-dialog title="关联合同" :visible="contractDialogVisible" width="680px" :close-on-click-modal="false" @close="contractDialogVisible = false">
      <div class="tip-bar">为订单 [{{ contractDialogRow ? contractDialogRow.order_no : '' }}] 选择合同（点击行完成关联）</div>
      <el-table :data="contractList" size="small" border max-height="320" v-loading="contractLoading" highlight-current-row @row-click="bindContract">
        <el-table-column prop="contract_no" label="合同编号" width="170" show-overflow-tooltip />
        <el-table-column prop="contract_name" label="合同名称" min-width="180" show-overflow-tooltip />
        <el-table-column label="合同金额" width="120" align="right">
          <template slot-scope="s">¥ {{ Number(s.row.contract_amount || 0).toLocaleString() }}</template>
        </el-table-column>
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="s"><el-tag size="mini">{{ s.row.contract_status_text || '-' }}</el-tag></template>
        </el-table-column>
      </el-table>
      <div class="tip-bar" style="margin-top:10px">点击合同行完成关联；如需解除当前关联请点击下方「解除合同」</div>
      <div slot="footer">
        <el-button size="small" @click="contractDialogVisible = false">取消</el-button>
        <el-button v-if="contractDialogRow && contractDialogRow.contract_id" size="small" type="danger" @click="unbindContract">解除合同</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import OrderFormDialog from './components/OrderFormDialog.vue'
import OrderAddDialog from './components/OrderAddDialog.vue'
import OrderDetailDialog from './components/OrderDetailDialog.vue'
import OrderReviewDialog from './components/OrderReviewDialog.vue'
import OrderStatusDialog from './components/OrderStatusDialog.vue'
import {
  getOrderList, getOrderStatistics, deleteOrder, submitOrder, copyOrder,
  exportOrder, getReviewList, bindOrderContract
} from '../../../api/businessOrder'
import { getContractList } from '../../../api/businessContract'
import { getDictByCode } from '../../../api/dictionary'
import { isCarouselMode } from '@/utils/kioskMode'

export default {
  name: 'BusinessOrder',
  components: { OrderFormDialog, OrderAddDialog, OrderDetailDialog, OrderReviewDialog, OrderStatusDialog },
  data() {
    return {
      activeTab: 'list',
      loading: false,
      list: [], total: 0, page: 1, pageSize: 20,
      stats: {},
      filter: { keyword: '', order_category: '', order_status: '', salesperson_id: null },
      orderRange: [], deliveryRange: [],
      categoryOptions: [], statusOptions: [], userOptions: [],
      // 关联合同
      contractDialogVisible: false, contractDialogRow: null, contractList: [], contractLoading: false,
      // 评审
      reviewLoading: false, reviewList: [], reviewTotal: 0, reviewPage: 1,
      reviewKeyword: '', reviewStatus: '',
      // 弹窗
      formVisible: false, currentRow: null,
      detailVisible: false, detailId: 0,
      reviewVisible: false, reviewOrderId: 0,
      statusVisible: false
    }
  },
  created() {
    // 从采购申请等外部跳转按订单类别定位（如 /business/order?category=repair 维修订单）
    if (this.$route.query && this.$route.query.category) {
      this.filter.order_category = this.$route.query.category
    }
    this.loadStats()
    this.loadList()
    this.loadDicts()
    this.loadUsers()
    // 从"订单评审"菜单进入切到评审 Tab
    if (this.$route.path === '/business/order/review') {
      this.activeTab = 'review'
      this.loadReview()
    }
    // 从"新增订单"菜单进入自动打开新增弹窗
    // 大屏轮播/展示模式下禁止自动打开新增订单写弹窗
    if (this.$route.path === '/business/order/add' && !isCarouselMode()) {
      this.$nextTick(() => { if (this.$refs.addDialog) this.$refs.addDialog.open() })
    }
  },
  methods: {
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    // 打开新增订单弹窗
    openAdd() { if (this.$refs.addDialog) this.$refs.addDialog.open() },
    onAddSuccess() { this.loadList(); this.loadStats() },
    statusTag(s) { return { pending: 'warning', reviewed: 'primary', production: 'danger', shipping: 'success', completed: 'info', cancelled: 'danger' }[s] || 'info' },
    async loadDicts() {
      try { const r = await getDictByCode('order_category'); this.categoryOptions = r.data || [] } catch (e) { this.categoryOptions = [] }
      try { const r = await getDictByCode('order_status'); this.statusOptions = r.data || [] } catch (e) { this.statusOptions = [] }
    },
    async loadUsers() {
      try {
        const { getUserList } = await import('../../../api/user')
        const r = await getUserList({ limit: 500 })
        this.userOptions = (r.data && r.data.list) || []
      } catch (e) { this.userOptions = [] }
    },
    search() { this.page = 1; this.loadList() },
    reset() {
      this.filter = { keyword: '', order_category: '', order_status: '', salesperson_id: null }
      this.orderRange = []; this.deliveryRange = []
      this.page = 1
      this.loadList()
    },
    async loadList() {
      this.loading = true
      try {
        const r = await getOrderList({
          ...this.filter,
          page: this.page, limit: this.pageSize,
          order_start: this.orderRange && this.orderRange[0] || '',
          order_end: this.orderRange && this.orderRange[1] || '',
          delivery_start: this.deliveryRange && this.deliveryRange[0] || '',
          delivery_end: this.deliveryRange && this.deliveryRange[1] || ''
        })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    async loadStats() {
      try { const r = await getOrderStatistics(); if (r.code === 0) this.stats = r.data || {} } catch (e) {}
    },
    async loadReview() {
      this.reviewLoading = true
      try {
        const r = await getReviewList({ keyword: this.reviewKeyword, status: this.reviewStatus, page: this.reviewPage, limit: 20 })
        if (r.code === 0) { this.reviewList = r.data.list || []; this.reviewTotal = r.data.total || 0 }
      } catch (e) {}
      this.reviewLoading = false
    },
    openForm(row) { this.currentRow = row || null; this.formVisible = true },
    onFormSuccess() { this.formVisible = false; this.loadList(); this.loadStats() },
    openDetail(id) { this.detailId = id; this.detailVisible = true },
    openReview(id) { this.reviewOrderId = id; this.reviewVisible = true },
    onReviewSuccess() { this.reviewVisible = false; this.loadList(); this.loadStats(); this.loadReview() },
    openStatus(row) { this.currentRow = row; this.statusVisible = true },
    onStatusSuccess() { this.statusVisible = false; this.loadList(); this.loadStats() },
    handleSubmit(row) {
      this.$confirm(`确认提交订单「${row.order_no}」进行评审？`, '提交评审', { type: 'warning' }).then(async () => {
        try {
          const r = await submitOrder(row.id)
          if (r.code === 0) { this.$message.success(r.msg); this.loadList() }
        } catch (e) {}
      }).catch(() => {})
    },
    handleDelete(row) {
      this.$confirm(`确定删除订单「${row.order_no}」？仅待评审订单可删除。`, '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteOrder(row.id)
          if (r.code === 0) { this.$message.success('订单已删除'); this.loadList(); this.loadStats() }
        } catch (e) {}
      }).catch(() => {})
    },
    handleCopy(row) {
      this.$confirm(`复制订单「${row.order_no}」生成新订单？`, '复制订单', { type: 'warning' }).then(async () => {
        try {
          const r = await copyOrder(row.id)
          if (r.code === 0) { this.$message.success(r.msg); this.loadList(); this.loadStats() }
        } catch (e) {}
      }).catch(() => {})
    },
    async handleExport() {
      try {
        const res = await exportOrder({ ...this.filter })
        const blob = res.data
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = 'orders_' + new Date().toISOString().slice(0, 10) + '.xlsx'
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
      } catch (e) {}
    },
    // 打印订单（打开详情并触发浏览器打印）
    openPrint(row) {
      this.detailId = row.id
      this.detailVisible = true
      setTimeout(() => { window.print() }, 800)
    },
    // ===== 关联合同（多订单可关联同一合同）=====
    async openContractBind(row) {
      this.contractDialogRow = row
      this.contractDialogVisible = true
      this.contractLoading = true
      try {
        const r = await getContractList({ page: 1, pageSize: 100 })
        this.contractList = (r.code === 0 && r.data) ? (r.data.list || []) : []
      } catch (e) { this.contractList = [] }
      this.contractLoading = false
    },
    async bindContract(contract) {
      try {
        const r = await bindOrderContract(this.contractDialogRow.id, contract.id)
        if (r.code === 0) {
          this.$message.success(r.msg)
          this.contractDialogVisible = false
          this.loadList()
        }
      } catch (e) {}
    },
    async unbindContract() {
      try {
        const r = await bindOrderContract(this.contractDialogRow.id, 0)
        if (r.code === 0) {
          this.$message.success(r.msg)
          this.contractDialogVisible = false
          this.loadList()
        }
      } catch (e) {}
    },
    viewContract(id) { if (id) this.$router.push('/business/contract') }
  }
}
</script>

<style scoped>
.order-page { padding: 4px 16px; }
.stat-row { margin-bottom: 14px; }
.stat-card { text-align: center; }
.stat-num { font-size: 24px; font-weight: 700; color: #303133; }
.stat-num.orange { color: #e6a23c; }
.stat-num.blue { color: #409eff; }
.stat-num.green { color: #67c23a; }
.stat-num.red { color: #f56c6c; font-size: 18px; }
.stat-label { font-size: 12px; color: #909399; margin-top: 4px; }
.filter-card { margin-bottom: 12px; }
.toolbar { display: flex; align-items: center; margin: 12px 0; }
.flex-1 { flex: 1; }
.pager { margin-top: 12px; text-align: right; }
.danger { color: #f56c6c; }
.orange { color: #e6a23c; }
.gray { color: #c0c4cc; }
</style>
