<!--
  文件：admin/src/views/business/sales/statistics/Customer.vue
  功能：客户排行（时间维度/客户名/等级/流失风险筛选 + 可排序表格 + 排名变化 + 导出）
  权限：sales:statistics:customer:view / export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>销售管理</el-breadcrumb-item>
      <el-breadcrumb-item>客户排行</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="时间维度">
          <el-select v-model="searchForm.time_dimension" style="width:110px" @change="handleDimensionChange">
            <el-option v-for="d in dimensionOptions" :key="d.value" :label="d.label" :value="d.value" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="searchForm.time_dimension === 'custom'" label="日期">
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:230px" @change="applyCustomRange" />
        </el-form-item>
        <el-form-item label="客户名称"><el-input v-model="searchForm.customer_name" placeholder="请输入客户名称" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="客户等级">
          <el-select v-model="searchForm.levels" multiple collapse-tags placeholder="全部" style="width:130px">
            <el-option label="A级" value="A" /><el-option label="B级" value="B" /><el-option label="C级" value="C" /><el-option label="D级" value="D" />
          </el-select>
        </el-form-item>
        <el-form-item label="流失风险">
          <el-select v-model="searchForm.churn_risk" clearable placeholder="全部" style="width:110px">
            <el-option label="正常" value="normal" /><el-option label="预警" value="warning" /><el-option label="流失" value="lost" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'sales:statistics:customer:export'" type="primary" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 家客户</span>
    </div>

    <el-table :data="tableData" v-loading="loading" size="small" border stripe @sort-change="handleSortChange">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="排名" width="70" align="center">
        <template slot-scope="s">
          <span v-if="s.row.rank <= 3" style="font-size:18px;">{{ rankMedal[s.row.rank] }}</span>
          <span v-else>{{ s.row.rank }}</span>
        </template>
      </el-table-column>
      <el-table-column label="排名变化" width="80" align="center">
        <template slot-scope="s">
          <span :class="rankChangeClass(s.row.rank_change)">{{ s.row.rank_change_label }}</span>
        </template>
      </el-table-column>
      <el-table-column label="客户名称" min-width="140">
        <template slot-scope="s"><el-link type="primary" @click="$router.push({ path: '/business/customer' })">{{ s.row.customer_name }}</el-link></template>
      </el-table-column>
      <el-table-column label="客户等级" width="90" align="center">
        <template slot-scope="s"><el-tag :type="s.row.level_tag" size="mini">{{ s.row.level_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="total_revenue" label="总销售额" width="140" align="right" sortable="custom">
        <template slot-scope="s">¥{{ s.row.total_revenue_formatted }}</template>
      </el-table-column>
      <el-table-column prop="order_count" label="订单数" width="80" align="center" sortable="custom" />
      <el-table-column prop="avg_order_value" label="客单价" width="120" align="right" sortable="custom">
        <template slot-scope="s">¥{{ s.row.avg_order_value_formatted }}</template>
      </el-table-column>
      <el-table-column prop="last_order_date" label="最近购买" width="110" align="center" sortable="custom">
        <template slot-scope="s">{{ s.row.last_order_date || '-' }}</template>
      </el-table-column>
      <el-table-column label="流失风险" width="90" align="center">
        <template slot-scope="s"><el-tag :type="s.row.churn_risk_tag" size="mini">{{ s.row.churn_risk_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="100" align="center" fixed="right">
        <template slot-scope="s"><el-button type="text" size="mini" @click="$router.push({ path: '/business/customer' })">查看详情</el-button></template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]"
      @current-change="p => { page = p; loadList() }" @size-change="s => { limit = s; page = 1; loadList() }" />
  </div>
</template>

<script>
import { getCustomerRankingList, exportCustomerRanking } from '@/api/sales'

const dimensionOptions = [
  { label: '今日', value: 'today' }, { label: '本周', value: 'week' }, { label: '本月', value: 'month' },
  { label: '本季', value: 'quarter' }, { label: '本年', value: 'year' }, { label: '自定义', value: 'custom' }
]

export default {
  name: 'SalesStatisticsCustomer',
  data () {
    return {
      dimensionOptions,
      searchForm: { time_dimension: 'month', customer_name: '', levels: [], churn_risk: '' },
      dateRange: [],
      tableData: [], total: 0, page: 1, limit: 20, loading: false, exporting: false,
      sortField: 'total_revenue', sortOrder: 'desc',
      rankMedal: { 1: '🥇', 2: '🥈', 3: '🥉' }
    }
  },
  created () {
    this.setDefaultRange()
    this.loadList()
  },
  methods: {
    fmt (d) { return d.toISOString().slice(0, 10) },
    setDefaultRange () {
      const now = new Date()
      const ranges = {
        today: [this.fmt(now), this.fmt(now)],
        week: [this.fmt(new Date(now.getTime() - (now.getDay() || 7) * 86400000 + 86400000)), this.fmt(now)],
        month: [this.fmt(new Date(now.getFullYear(), now.getMonth(), 1)), this.fmt(now)],
        quarter: [this.fmt(new Date(now.getFullYear(), Math.floor(now.getMonth() / 3) * 3, 1)), this.fmt(now)],
        year: [this.fmt(new Date(now.getFullYear(), 0, 1)), this.fmt(now)]
      }
      const r = ranges[this.searchForm.time_dimension]
      if (r && this.searchForm.time_dimension !== 'custom') { this.dateRange = r; this.searchForm.start_date = r[0]; this.searchForm.end_date = r[1] }
    },
    applyCustomRange () {
      if (this.dateRange && this.dateRange.length === 2) { this.searchForm.start_date = this.dateRange[0]; this.searchForm.end_date = this.dateRange[1] }
    },
    buildParams () {
      const p = { page: this.page, limit: this.limit, start_date: this.searchForm.start_date, end_date: this.searchForm.end_date, sort_field: this.sortField, sort_order: this.sortOrder }
      if (this.searchForm.customer_name) p.customer_name = this.searchForm.customer_name
      if (this.searchForm.levels && this.searchForm.levels.length) p.levels = this.searchForm.levels
      if (this.searchForm.churn_risk) p.churn_risk = this.searchForm.churn_risk
      return p
    },
    handleDimensionChange (val) { if (val === 'custom') return; this.setDefaultRange(); this.handleSearch() },
    handleSearch () { this.setDefaultRange(); this.page = 1; this.loadList() },
    handleReset () {
      this.searchForm = { time_dimension: 'month', customer_name: '', levels: [], churn_risk: '' }
      this.dateRange = []
      this.setDefaultRange()
      this.handleSearch()
    },
    handleSortChange ({ prop, order }) {
      const map = { total_revenue: 'total_revenue', order_count: 'order_count', avg_order_value: 'avg_order_value', last_order_date: 'last_order_date' }
      if (!order) { this.sortField = 'total_revenue'; this.sortOrder = 'desc' } else { this.sortField = map[prop] || 'total_revenue'; this.sortOrder = order === 'ascending' ? 'asc' : 'desc' }
      this.page = 1
      this.loadList()
    },
    rankChangeClass (change) {
      if (change === null) return 'rank-new'
      if (change > 0) return 'rank-up'
      if (change < 0) return 'rank-down'
      return 'rank-flat'
    },
    async loadList () {
      this.loading = true
      try {
        const r = await getCustomerRankingList(this.buildParams())
        if (r.code === 0 && r.data) { this.tableData = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    async handleExport () {
      this.exporting = true
      try {
        const p = { ...this.buildParams() }
        delete p.page; delete p.limit
        const r = await exportCustomerRanking(p)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `客户排行_${new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14)}.xlsx`
          a.click()
          window.URL.revokeObjectURL(url)
        }
      } catch (e) {} finally { this.exporting = false }
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.rank-up { color: #67C23A; font-weight: bold; }
.rank-down { color: #F56C6C; font-weight: bold; }
.rank-flat { color: #909399; }
.rank-new { color: #409EFF; }
</style>
