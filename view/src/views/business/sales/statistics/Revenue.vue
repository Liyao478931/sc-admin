<!--
  文件：admin/src/views/business/sales/statistics/Revenue.vue
  功能：销售额分析看板（筛选 / 指标卡 / 趋势图 / 品类饼图 / 客户+业务员排行 / 明细表格联动钻取 / 导出）
  权限：sales:statistics:revenue:view / export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>销售管理</el-breadcrumb-item>
      <el-breadcrumb-item>销售额分析</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="filter-bar">
      <el-form inline size="small" label-width="70px" @submit.native.prevent>
        <el-form-item label="时间维度">
          <el-select v-model="searchForm.time_dimension" style="width:110px" @change="handleDimensionChange">
            <el-option v-for="d in dimensionOptions" :key="d.value" :label="d.label" :value="d.value" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="searchForm.time_dimension === 'custom'" label="日期">
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:230px" @change="applyCustomRange" />
        </el-form-item>
        <el-form-item label="产品分类">
          <el-select v-model="searchForm.category_ids" multiple collapse-tags placeholder="全部" style="width:200px">
            <el-option v-for="c in categoryOptions" :key="c.id" :label="c.name" :value="c.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="业务员">
          <el-select v-model="searchForm.sales_person_ids" multiple collapse-tags placeholder="全部" style="width:160px">
            <el-option v-for="s in salespersonOptions" :key="s.id" :label="s.name" :value="s.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">查询</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
          <el-button v-permission="'sales:statistics:revenue:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
          <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadDashboard">刷新</el-button>
        </el-form-item>
      </el-form>
    </div>

    <el-row :gutter="20" class="stat-row">
      <el-col :span="6" v-for="s in statCards" :key="s.key">
        <el-card shadow="hover" class="stat-card" :style="{ background: s.bg }">
          <div class="stat-inner">
            <i :class="s.icon" :style="{ color: s.color, fontSize: '30px' }"></i>
            <div>
              <div class="stat-val" :style="{ color: s.color }">{{ s.value }}</div>
              <div class="stat-lbl">{{ s.label }}
                <span v-if="s.trend !== null && s.trend !== undefined" class="stat-trend">
                  <i :class="s.trend > 0 ? 'el-icon-top trend-up' : (s.trend < 0 ? 'el-icon-bottom trend-down' : 'el-icon-minus trend-flat')"></i>
                  {{ Math.abs(s.trend) }}%
                </span>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20">
      <el-col :span="15">
        <el-card shadow="never">
          <div slot="header" class="chart-header">
            <span>销售额趋势</span>
            <el-radio-group v-model="trendMode" size="mini" @change="handleTrendModeChange">
              <el-radio-button label="day">日</el-radio-button>
              <el-radio-button label="week">周</el-radio-button>
              <el-radio-button label="month">月</el-radio-button>
              <el-radio-button label="quarter">季</el-radio-button>
              <el-radio-button label="year">年</el-radio-button>
            </el-radio-group>
          </div>
          <div ref="trendChart" class="chart-box"></div>
        </el-card>
      </el-col>
      <el-col :span="9">
        <el-card shadow="never">
          <div slot="header"><span>品类销售占比</span></div>
          <div ref="categoryChart" class="chart-box"></div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="20" style="margin-top:20px;">
      <el-col :span="12">
        <el-card shadow="never">
          <div slot="header"><span>客户销售额 TOP10</span></div>
          <div ref="customerChart" class="chart-box"></div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card shadow="never">
          <div slot="header"><span>业务员业绩 TOP10</span></div>
          <div ref="salespersonChart" class="chart-box"></div>
        </el-card>
      </el-col>
    </el-row>

    <el-card shadow="never" class="table-card">
      <div slot="header" class="chart-header">
        <span>销售额明细
          <el-tag v-for="(v, k) in drillFilters" :key="k" v-if="v" closable size="small" class="drill-tag" @close="clearDrillFilter(k)">{{ drillLabel(k) }}：{{ v }}</el-tag>
          <el-button v-if="hasDrill" type="text" size="mini" @click="clearAllDrillFilters">清除全部筛选</el-button>
        </span>
      </div>
      <el-table :data="tableData" v-loading="tableLoading" size="small" border stripe>
        <el-table-column type="index" label="#" width="55" align="center" />
        <el-table-column label="订单编号" width="150">
          <template slot-scope="s"><el-link type="primary" @click="$router.push({ path: '/business/order' })">{{ s.row.order_no }}</el-link></template>
        </el-table-column>
        <el-table-column prop="customer_name" label="客户名称" width="130" show-overflow-tooltip />
        <el-table-column prop="sales_person" label="业务员" width="80" align="center" />
        <el-table-column prop="category_name" label="产品分类" width="100" show-overflow-tooltip />
        <el-table-column label="订单金额" width="120" align="right"><template slot-scope="s">{{ money(s.row.order_amount) }}</template></el-table-column>
        <el-table-column label="状态" width="100" align="center">
          <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="order_date" label="订单日期" width="120" align="center" />
        <el-table-column label="操作" width="90" align="center">
          <template slot-scope="s"><el-button type="text" size="mini" @click="$router.push({ path: '/business/order' })">查看详情</el-button></template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
        :total="total" :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]"
        @current-change="p => { page = p; loadTable() }" @size-change="s => { limit = s; page = 1; loadTable() }" />
    </el-card>
  </div>
</template>

<script>
import echarts from '@/utils/echarts'
import { getRevenueOverview, getRevenueTrend, getRevenueDetails, getRevenueOptions, exportRevenue } from '@/api/sales'

const dimensionOptions = [
  { label: '今日', value: 'today' }, { label: '本周', value: 'week' }, { label: '本月', value: 'month' },
  { label: '本季', value: 'quarter' }, { label: '本年', value: 'year' }, { label: '自定义', value: 'custom' }
]
const CATEGORY_COLORS = ['#409EFF', '#67C23A', '#E6A23C', '#F56C6C', '#909399', '#722ED1', '#13C2C2', '#FA8C16']

export default {
  name: 'SalesStatisticsRevenue',
  data () {
    return {
      dimensionOptions,
      searchForm: { time_dimension: 'month', category_ids: [], sales_person_ids: [] },
      dateRange: [],
      categoryOptions: [], salespersonOptions: [],
      statistics: {},
      trendMode: 'day', trendData: { dates: [], revenue: [], orders: [] },
      categoryData: [], customerRanking: [], salespersonRanking: [],
      tableData: [], total: 0, page: 1, limit: 20, loading: false, tableLoading: false, exporting: false,
      charts: {}, drillFilters: { date: '', category: '', customer: '', salesperson: '' },
      statCards: [
        { key: 'total_revenue', label: '总销售额', value: '¥0', icon: 'el-icon-money', color: '#409EFF', bg: '#ECF5FF', trend: null },
        { key: 'order_count', label: '订单数', value: 0, icon: 'el-icon-document', color: '#67C23A', bg: '#F0F9EB', trend: null },
        { key: 'avg_order_value', label: '客单价', value: '¥0', icon: 'el-icon-user', color: '#E6A23C', bg: '#FDF6EC', trend: null },
        { key: 'yoy_growth', label: '同比增长', value: '0%', icon: 'el-icon-trend-charts', color: '#F56C6C', bg: '#FEF0F0', trend: null }
      ]
    }
  },
  computed: {
    hasDrill () { return Object.values(this.drillFilters).some(v => v) }
  },
  created () {
    this.loadOptions()
    this.setDefaultRange()
    this.loadDashboard()
  },
  mounted () { window.addEventListener('resize', this.resizeCharts) },
  beforeDestroy () {
    window.removeEventListener('resize', this.resizeCharts)
    Object.values(this.charts).forEach(c => { if (c) c.dispose() })
  },
  methods: {
    money (v) { const n = Number(v) || 0; return n ? '¥' + n.toLocaleString('zh-CN', { minimumFractionDigits: 2 }) : '-' },
    async loadOptions () {
      try {
        const r = await getRevenueOptions()
        if (r.code === 0 && r.data) {
          this.categoryOptions = r.data.categories || []
          this.salespersonOptions = r.data.salespersons || []
        }
      } catch (e) {}
    },
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
      const p = { time_dimension: this.searchForm.time_dimension, start_date: this.searchForm.start_date, end_date: this.searchForm.end_date }
      if (this.searchForm.category_ids && this.searchForm.category_ids.length) p.category_ids = this.searchForm.category_ids
      if (this.searchForm.sales_person_ids && this.searchForm.sales_person_ids.length) p.sales_person_ids = this.searchForm.sales_person_ids
      return p
    },
    drillParams () {
      const p = this.buildParams()
      Object.keys(this.drillFilters).forEach(k => { if (this.drillFilters[k]) p['drill_' + k] = this.drillFilters[k] })
      return p
    },
    handleDimensionChange (val) { if (val === 'custom') return; this.setDefaultRange(); this.handleSearch() },
    handleSearch () { this.setDefaultRange(); this.page = 1; this.clearAllDrillFilters(); this.loadDashboard() },
    handleReset () {
      this.searchForm = { time_dimension: 'month', category_ids: [], sales_person_ids: [] }
      this.dateRange = []
      this.setDefaultRange()
      this.clearAllDrillFilters()
      this.loadDashboard()
    },
    async loadDashboard () {
      this.loading = true
      try {
        const r = await getRevenueOverview(this.buildParams())
        if (r.code === 0 && r.data) {
          const d = r.data
          this.statistics = d.statistics || {}
          this.updateStatCards()
          this.trendData = d.trend || { dates: [], revenue: [], orders: [] }
          this.categoryData = d.category || []
          this.customerRanking = d.customer_ranking || []
          this.salespersonRanking = d.salesperson_ranking || []
          this.renderAll()
        }
      } catch (e) {} finally { this.loading = false }
      this.loadTable()
    },
    updateStatCards () {
      const s = this.statistics
      this.statCards[0].value = s.total_revenue_formatted || '¥0'
      this.statCards[0].trend = s.mom_growth
      this.statCards[1].value = s.order_count || 0
      this.statCards[1].trend = s.order_trend
      this.statCards[2].value = s.avg_order_value_formatted || '¥0'
      this.statCards[2].trend = s.avg_trend
      this.statCards[3].value = (s.yoy_growth > 0 ? '+' : '') + (s.yoy_growth || 0) + '%'
      this.statCards[3].trend = null
    },
    async handleTrendModeChange (mode) {
      try {
        const r = await getRevenueTrend({ ...this.buildParams(), trend_mode: mode })
        if (r.code === 0 && r.data) { this.trendData = r.data; this.renderTrend() }
      } catch (e) {}
    },
    async loadTable () {
      this.tableLoading = true
      try {
        const r = await getRevenueDetails({ ...this.drillParams(), page: this.page, limit: this.limit })
        if (r.code === 0 && r.data) { this.tableData = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.tableLoading = false }
    },
    drillLabel (k) { return { date: '日期', category: '品类', customer: '客户', salesperson: '业务员' }[k] || k },
    handleDrillFilter (type, value) { this.drillFilters[type] = value; this.page = 1; this.loadTable() },
    clearDrillFilter (k) { this.drillFilters[k] = ''; this.page = 1; this.loadTable() },
    clearAllDrillFilters () { this.drillFilters = { date: '', category: '', customer: '', salesperson: '' } },
    renderAll () { this.renderTrend(); this.renderCategory(); this.renderRanking('customer'); this.renderRanking('salesperson') },
    renderTrend () {
      if (!this.$refs.trendChart) return
      if (!this.charts.trend) this.charts.trend = echarts.init(this.$refs.trendChart)
      const td = this.trendData
      this.charts.trend.setOption({
        tooltip: { trigger: 'axis' },
        legend: { data: ['销售额', '订单数'], top: 0, right: 0 },
        grid: { left: 50, right: 50, bottom: 30, top: 40 },
        xAxis: { type: 'category', data: td.dates || [], boundaryGap: false },
        yAxis: [
          { type: 'value', name: '销售额（万元）', position: 'left', axisLabel: { formatter: '{value}万' } },
          { type: 'value', name: '订单数（个）', position: 'right', axisLabel: { formatter: '{value}个' }, minInterval: 1 }
        ],
        series: [
          { name: '销售额', type: 'line', smooth: true, symbol: 'circle', symbolSize: 6, data: td.revenue || [], areaStyle: { color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: 'rgba(64,158,255,0.3)' }, { offset: 1, color: 'rgba(64,158,255,0.05)' }]) } },
          { name: '订单数', type: 'line', smooth: true, symbol: 'diamond', symbolSize: 6, yAxisIndex: 1, data: td.orders || [] }
        ]
      }, true)
      this.charts.trend.off('click')
      this.charts.trend.on('click', p => { if (p.componentType === 'series' && td.dates[p.dataIndex]) this.handleDrillFilter('date', td.dates[p.dataIndex]) })
    },
    renderCategory () {
      if (!this.$refs.categoryChart) return
      if (!this.charts.category) this.charts.category = echarts.init(this.$refs.categoryChart)
      const data = (this.categoryData || []).map((x, i) => ({ name: x.category_name, value: x.revenue, itemStyle: { color: CATEGORY_COLORS[i % CATEGORY_COLORS.length] } }))
      const total = data.reduce((s, x) => s + x.value, 0)
      this.charts.category.setOption({
        tooltip: { trigger: 'item', formatter: '{b}: {c}万元 ({d}%)' },
        legend: { orient: 'vertical', right: 10, top: 'center', type: 'scroll' },
        graphic: [{ type: 'text', left: '30%', top: '45%', style: { text: '总销售额\n' + (total.toFixed(1) || 0) + '万', textAlign: 'center', fontSize: 14, fill: '#909399', lineHeight: 22 } }],
        series: [{ type: 'pie', radius: ['40%', '68%'], center: ['38%', '50%'], avoidLabelOverlap: true, itemStyle: { borderRadius: 6, borderColor: '#fff', borderWidth: 2 }, label: { show: true, formatter: '{b}\n{d}%' }, emphasis: { scale: true }, data }]
      }, true)
      this.charts.category.off('click')
      this.charts.category.on('click', p => { if (p.componentType === 'series' && p.name) this.handleDrillFilter('category', p.name) })
    },
    renderRanking (type) {
      const ref = type === 'customer' ? 'customerChart' : 'salespersonChart'
      const key = type === 'customer' ? 'customer_name' : 'sales_person'
      const data = (type === 'customer' ? this.customerRanking : this.salespersonRanking) || []
      if (!this.$refs[ref]) return
      if (!this.charts[type]) this.charts[type] = echarts.init(this.$refs[ref])
      const names = data.map(x => x[key] || '未知').reverse()
      const values = data.map(x => x.revenue || 0).reverse()
      const colors = type === 'customer'
        ? new echarts.graphic.LinearGradient(0, 0, 1, 0, [{ offset: 0, color: '#409EFF' }, { offset: 1, color: '#79bbff' }])
        : new echarts.graphic.LinearGradient(0, 0, 1, 0, [{ offset: 0, color: '#fa8c16' }, { offset: 1, color: '#ffc069' }])
      this.charts[type].setOption({
        tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
        grid: { left: 90, right: 60, bottom: 20, top: 20 },
        xAxis: { type: 'value', axisLabel: { formatter: '{value}万' } },
        yAxis: { type: 'category', data: names, axisLabel: { fontSize: 12 } },
        series: [{ type: 'bar', data: values, barWidth: 18, itemStyle: { color: colors, borderRadius: [0, 4, 4, 0] }, label: { show: true, position: 'right', formatter: '{c}万' } }]
      }, true)
      this.charts[type].off('click')
      this.charts[type].on('click', p => {
        if (p.componentType === 'series') {
          const name = names[p.dataIndex]
          if (name) this.handleDrillFilter(type === 'customer' ? 'customer' : 'salesperson', name)
        }
      })
    },
    resizeCharts () { Object.values(this.charts).forEach(c => { if (c) c.resize() }) },
    async handleExport () {
      this.exporting = true
      try {
        const r = await exportRevenue(this.drillParams())
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `销售额明细_${new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14)}.xlsx`
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
.filter-bar { background: #fff; padding: 14px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; margin-bottom: 16px; }
.stat-row { margin-bottom: 16px; }
.stat-card { cursor: default; }
.stat-inner { display: flex; align-items: center; gap: 14px; }
.stat-val { font-size: 24px; font-weight: bold; }
.stat-lbl { font-size: 13px; color: #909399; }
.stat-trend { margin-left: 6px; font-size: 12px; }
.trend-up { color: #67C23A; }
.trend-down { color: #F56C6C; }
.trend-flat { color: #909399; }
.chart-header { display: flex; justify-content: space-between; align-items: center; }
.chart-box { height: 320px; }
.table-card { margin-top: 20px; }
.pager { margin-top: 16px; text-align: right; }
.drill-tag { margin-left: 8px; }
</style>
