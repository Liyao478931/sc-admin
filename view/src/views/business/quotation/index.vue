<!--
  文件：admin/src/views/business/quotation/index.vue
  功能：经营管理 → 订单中心 → 报价管理
    - 统计卡片（总数/待审核/本月报价数/本月金额/转化率）
    - 筛选（关键词/类别/状态/报价日期/有效期/业务员）
    - 报价单列表 Tab + 报价单审核 Tab
    - 操作：详情/编辑/提交审核/审核/转订单/复制/删除/打印
    - 弹窗：新增编辑/详情/审核
-->
<template>
  <div class="quotation-page">
    <!-- ===== 统计卡片 ===== -->
    <el-row :gutter="14" class="stat-row">
      <el-col :span="4"><el-card shadow="never" class="stat-card"><div class="stat-num">{{ stats.total || 0 }}</div><div class="stat-label">报价单总数</div></el-card></el-col>
      <el-col :span="4"><el-card shadow="never" class="stat-card"><div class="stat-num orange">{{ stats.pending || 0 }}</div><div class="stat-label">待审核</div></el-card></el-col>
      <el-col :span="4"><el-card shadow="never" class="stat-card"><div class="stat-num blue">{{ stats.month_new || 0 }}</div><div class="stat-label">本月报价</div></el-card></el-col>
      <el-col :span="8"><el-card shadow="never" class="stat-card"><div class="stat-num red">¥{{ Number(stats.month_amount || 0).toLocaleString() }}</div><div class="stat-label">本月报价金额</div></el-card></el-col>
      <el-col :span="4"><el-card shadow="never" class="stat-card"><div class="stat-num green">{{ stats.conversion_rate || 0 }}%</div><div class="stat-label">转化率</div></el-card></el-col>
    </el-row>

    <el-tabs v-model="activeTab" type="border-card">
      <!-- ===== 报价单列表 ===== -->
      <el-tab-pane label="报价单列表" name="list">
        <el-card shadow="never" class="filter-card">
          <el-form inline size="small" @submit.native.prevent>
            <el-form-item label="关键词">
              <el-input v-model="filter.keyword" placeholder="报价编号/客户/业务员" clearable style="width:170px" @keyup.enter.native="search" />
            </el-form-item>
            <el-form-item label="报价类别">
              <el-select v-model="filter.quotation_category" placeholder="全部" clearable style="width:110px">
                <el-option v-for="opt in categoryOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
              </el-select>
            </el-form-item>
            <el-form-item label="报价状态">
              <el-select v-model="filter.quotation_status" placeholder="全部" clearable style="width:110px">
                <el-option v-for="opt in statusOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
              </el-select>
            </el-form-item>
            <el-form-item label="报价日期">
              <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:210px" />
            </el-form-item>
            <el-form-item label="有效期">
              <el-date-picker v-model="validityRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:210px" />
            </el-form-item>
            <el-form-item label="业务员">
              <el-select v-model="filter.salesperson_id" placeholder="全部" clearable filterable style="width:120px">
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
          <el-button v-if="hasPerm('business:quotation:add')" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增报价单</el-button>
          <el-button v-if="hasPerm('business:quotation:export')" size="small" icon="el-icon-download" @click="handleExport">导出报价单</el-button>
          <span class="flex-1"></span>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </div>

        <el-table :data="list" v-loading="loading" size="small" stripe border>
          <el-table-column prop="quotation_no" label="报价单编号" width="160" show-overflow-tooltip />
          <el-table-column label="报价类别" width="90" align="center">
            <template slot-scope="s"><el-tag size="mini" :type="s.row.quotation_category === 'repair' ? 'warning' : 'primary'">{{ s.row.quotation_category_text }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="customer_name" label="客户名称" min-width="150" show-overflow-tooltip />
          <el-table-column label="报价金额" width="110">
            <template slot-scope="s">¥{{ Number(s.row.quotation_amount || 0).toLocaleString() }}</template>
          </el-table-column>
          <el-table-column label="报价状态" width="90" align="center">
            <template slot-scope="s"><el-tag size="mini" :type="statusTag(s.row.quotation_status)">{{ s.row.quotation_status_text }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="quotation_date" label="报价日期" width="105" />
          <el-table-column prop="validity_date" label="有效期" width="105" />
          <el-table-column prop="salesperson_name" label="业务员" width="90" />
          <el-table-column label="操作" width="280" align="center" fixed="right">
            <template slot-scope="s">
              <el-button type="text" size="mini" @click="openDetail(s.row.id)">详情</el-button>
              <el-button type="text" size="mini" @click="openPrint(s.row)">打印</el-button>
              <el-button v-if="hasPerm('business:quotation:edit') && ['draft','pending','rejected'].includes(s.row.quotation_status)" type="text" size="mini" @click="openForm(s.row)">编辑</el-button>
              <el-button v-if="hasPerm('business:quotation:edit') && ['draft','rejected'].includes(s.row.quotation_status)" type="text" size="mini" @click="handleSubmit(s.row)">提交审核</el-button>
              <el-button v-if="hasPerm('business:quotation:review') && s.row.quotation_status === 'pending'" type="text" size="mini" class="orange" @click="openReview(s.row.id)">审核</el-button>
              <el-button v-if="hasPerm('business:quotation:convert') && s.row.quotation_status === 'approved'" type="text" size="mini" class="green" @click="handleConvert(s.row)">转订单</el-button>
              <el-button v-if="hasPerm('business:quotation:add')" type="text" size="mini" @click="handleCopy(s.row)">复制</el-button>
              <el-button v-if="hasPerm('business:quotation:delete') && s.row.quotation_status === 'draft'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
        <el-pagination class="pager" small background layout="total, prev, pager, next" :total="total" :page-size="pageSize" :current-page="page" @current-change="p => { page = p; loadList() }" />
      </el-tab-pane>

      <!-- ===== 报价单审核 ===== -->
      <el-tab-pane label="报价单审核" name="review">
        <div class="toolbar">
          <el-input v-model="reviewKeyword" placeholder="报价编号/客户搜索" size="small" clearable style="width:200px" @keyup.enter.native="loadReview" />
          <el-select v-model="reviewStatus" placeholder="全部状态" clearable size="small" style="width:130px;margin-left:10px" @change="loadReview">
            <el-option v-for="opt in statusOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
          <span class="flex-1"></span>
          <el-button size="small" icon="el-icon-refresh" @click="loadReview">刷新</el-button>
        </div>
        <el-table :data="reviewList" v-loading="reviewLoading" size="small" stripe border>
          <el-table-column prop="quotation_no" label="报价单编号" width="160" />
          <el-table-column prop="customer_name" label="客户名称" min-width="150" show-overflow-tooltip />
          <el-table-column label="报价类别" width="90" align="center"><template slot-scope="s"><el-tag size="mini" :type="s.row.quotation_category === 'repair' ? 'warning' : 'primary'">{{ s.row.quotation_category_text }}</el-tag></template></el-table-column>
          <el-table-column label="报价金额" width="110"><template slot-scope="s">¥{{ Number(s.row.quotation_amount || 0).toLocaleString() }}</template></el-table-column>
          <el-table-column label="状态" width="90" align="center"><template slot-scope="s"><el-tag size="mini" :type="statusTag(s.row.quotation_status)">{{ s.row.quotation_status_text }}</el-tag></template></el-table-column>
          <el-table-column prop="quotation_date" label="报价日期" width="105" />
          <el-table-column label="最近审核" min-width="150">
            <template slot-scope="s">
              <template v-if="s.row.last_review">{{ s.row.last_review.result_text }} · {{ s.row.last_review.reviewer }} · {{ s.row.last_review.time }}</template>
              <span v-else class="gray">--</span>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="90" align="center">
            <template slot-scope="s">
              <el-button v-if="hasPerm('business:quotation:review') && s.row.quotation_status === 'pending'" type="text" size="mini" class="orange" @click="openReview(s.row.id)">审核</el-button>
              <el-button v-else type="text" size="mini" @click="openDetail(s.row.id)">详情</el-button>
            </template>
          </el-table-column>
        </el-table>
        <el-pagination class="pager" small background layout="total, prev, pager, next" :total="reviewTotal" :page-size="20" :current-page="reviewPage" @current-change="p => { reviewPage = p; loadReview() }" />
      </el-tab-pane>
    </el-tabs>

    <!-- ===== 弹窗 ===== -->
    <QuotationFormDialog :visible="formVisible" :row="currentRow" @update:visible="v => (formVisible = v)" @success="onFormSuccess" />
    <QuotationDetailDialog :visible="detailVisible" :quotation-id="detailId" @update:visible="v => (detailVisible = v)" @convert="handleConvert" />
    <QuotationReviewDialog :visible="reviewVisible" :quotation-id="reviewQuotationId" @update:visible="v => (reviewVisible = v)" @success="onReviewSuccess" />
  </div>
</template>

<script>
import QuotationFormDialog from './components/QuotationFormDialog.vue'
import QuotationDetailDialog from './components/QuotationDetailDialog.vue'
import QuotationReviewDialog from './components/QuotationReviewDialog.vue'
import {
  getQuotationList, getQuotationStatistics, deleteQuotation, submitQuotation,
  convertQuotation, copyQuotation, exportQuotation, getQuotationReviewList
} from '../../../api/businessQuotation'
import { getDictByCode } from '../../../api/dictionary'
import { isCarouselMode } from '@/utils/kioskMode'

export default {
  name: 'BusinessQuotation',
  components: { QuotationFormDialog, QuotationDetailDialog, QuotationReviewDialog },
  data() {
    return {
      activeTab: 'list',
      loading: false,
      list: [], total: 0, page: 1, pageSize: 20,
      stats: {},
      filter: { keyword: '', quotation_category: '', quotation_status: '', salesperson_id: null },
      dateRange: [], validityRange: [],
      categoryOptions: [], statusOptions: [], userOptions: [],
      reviewLoading: false, reviewList: [], reviewTotal: 0, reviewPage: 1,
      reviewKeyword: '', reviewStatus: '',
      formVisible: false, currentRow: null,
      detailVisible: false, detailId: 0,
      reviewVisible: false, reviewQuotationId: 0
    }
  },
  created() {
    this.loadStats()
    this.loadList()
    this.loadDicts()
    this.loadUsers()
    if (this.$route.path === '/business/quotation/review') {
      this.activeTab = 'review'
      this.loadReview()
    }
    // 大屏轮播/展示模式下禁止自动打开新增报价单写弹窗
    if (this.$route.path === '/business/quotation/add' && !isCarouselMode()) {
      this.$nextTick(() => { this.formVisible = true })
    }
  },
  methods: {
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    statusTag(s) { return { draft: 'info', pending: 'warning', approved: 'success', rejected: 'danger', converted: 'primary' }[s] || 'info' },
    async loadDicts() {
      try { const r = await getDictByCode('quotation_category'); this.categoryOptions = r.data || [] } catch (e) { this.categoryOptions = [] }
      try { const r = await getDictByCode('quotation_status'); this.statusOptions = r.data || [] } catch (e) { this.statusOptions = [] }
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
      this.filter = { keyword: '', quotation_category: '', quotation_status: '', salesperson_id: null }
      this.dateRange = []; this.validityRange = []
      this.page = 1
      this.loadList()
    },
    async loadList() {
      this.loading = true
      try {
        const r = await getQuotationList({
          ...this.filter,
          page: this.page, limit: this.pageSize,
          date_start: this.dateRange && this.dateRange[0] || '',
          date_end: this.dateRange && this.dateRange[1] || '',
          validity_start: this.validityRange && this.validityRange[0] || '',
          validity_end: this.validityRange && this.validityRange[1] || ''
        })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    async loadStats() {
      try { const r = await getQuotationStatistics(); if (r.code === 0) this.stats = r.data || {} } catch (e) {}
    },
    async loadReview() {
      this.reviewLoading = true
      try {
        const r = await getQuotationReviewList({ keyword: this.reviewKeyword, status: this.reviewStatus, page: this.reviewPage, limit: 20 })
        if (r.code === 0) { this.reviewList = r.data.list || []; this.reviewTotal = r.data.total || 0 }
      } catch (e) {}
      this.reviewLoading = false
    },
    openForm(row) { this.currentRow = row || null; this.formVisible = true },
    onFormSuccess() { this.formVisible = false; this.loadList(); this.loadStats() },
    openDetail(id) { this.detailId = id; this.detailVisible = true },
    openReview(id) { this.reviewQuotationId = id; this.reviewVisible = true },
    onReviewSuccess() { this.reviewVisible = false; this.loadList(); this.loadStats(); this.loadReview() },
    handleSubmit(row) {
      this.$confirm(`确认提交报价单「${row.quotation_no}」进行审核？`, '提交审核', { type: 'warning' }).then(async () => {
        try {
          const r = await submitQuotation(row.id)
          if (r.code === 0) { this.$message.success(r.msg); this.loadList() }
        } catch (e) {}
      }).catch(() => {})
    },
    handleDelete(row) {
      this.$confirm(`确定删除报价单「${row.quotation_no}」？仅草稿可删除。`, '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteQuotation(row.id)
          if (r.code === 0) { this.$message.success('报价单已删除'); this.loadList(); this.loadStats() }
        } catch (e) {}
      }).catch(() => {})
    },
    handleConvert(row) {
      this.$confirm(`确认将报价单「${row.quotation_no}」转为正式订单？`, '转订单', { type: 'warning' }).then(async () => {
        try {
          const r = await convertQuotation(row.id)
          if (r.code === 0) { this.$message.success(r.msg); this.detailVisible = false; this.loadList(); this.loadStats(); this.loadReview() }
        } catch (e) {}
      }).catch(() => {})
    },
    handleCopy(row) {
      this.$confirm(`复制报价单「${row.quotation_no}」生成新报价单？`, '复制报价单', { type: 'warning' }).then(async () => {
        try {
          const r = await copyQuotation(row.id)
          if (r.code === 0) { this.$message.success(r.msg); this.loadList(); this.loadStats() }
        } catch (e) {}
      }).catch(() => {})
    },
    async handleExport() {
      try {
        const res = await exportQuotation({ ...this.filter })
        const blob = res.data
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = 'quotations_' + new Date().toISOString().slice(0, 10) + '.xlsx'
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
      } catch (e) {}
    },
    openPrint(row) {
      this.detailId = row.id
      this.detailVisible = true
      setTimeout(() => { window.print() }, 800)
    }
  }
}
</script>

<style scoped>
.quotation-page { padding: 4px 16px; }
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
.green { color: #67c23a; }
.gray { color: #c0c4cc; }
</style>
