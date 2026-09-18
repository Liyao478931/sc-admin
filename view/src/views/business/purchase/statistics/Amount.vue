<!--
  文件：admin/src/views/business/purchase/statistics/Amount.vue
  功能：采购额分析（4 指标 + 趋势三线/构成堆叠/同比环比 + 明细）
  权限：business:purchase:statistics:view / export
-->
<template>
  <div class="stats-page">
    <div class="top-bar">
      <div>
        <div class="top-title">💰 采购额分析</div>
        <el-breadcrumb separator="/" class="top-breadcrumb">
          <el-breadcrumb-item>经营管理</el-breadcrumb-item>
          <el-breadcrumb-item>采购管理</el-breadcrumb-item>
          <el-breadcrumb-item>采购统计</el-breadcrumb-item>
          <el-breadcrumb-item>采购额分析</el-breadcrumb-item>
        </el-breadcrumb>
      </div>
      <div class="top-right">
        <span class="live-dot"></span><span class="live-text">数据实时</span>
        <span class="top-time">{{ now }}</span>
      </div>
    </div>

    <div class="filter-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="时间类型">
          <el-select v-model="f.time_type" style="width:110px" @change="onTimeTypeChange">
            <el-option v-for="(t, v) in TIME_TYPES" :key="v" :label="t" :value="v" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="f.time_type === 'custom'" label="时间范围">
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始" end-placeholder="结束" value-format="yyyy-MM-dd" style="width:240px" />
        </el-form-item>
        <el-form-item label="统计维度">
          <el-select v-model="f.group_by" style="width:100px">
            <el-option label="按天" value="day" /><el-option label="按周" value="week" /><el-option label="按月" value="month" />
          </el-select>
        </el-form-item>
        <el-form-item label="采购类型">
          <el-select v-model="f.purchase_type" style="width:140px">
            <el-option label="全部" value="" /><el-option label="日常采购" value="1" /><el-option label="项目采购" value="2" /><el-option label="紧急采购" value="3" /><el-option label="备品备件采购" value="4" />
          </el-select>
        </el-form-item>
        <el-form-item label="供应商">
          <el-select v-model="f.supplier_id" filterable clearable style="width:180px">
            <el-option v-for="s in supplierOptions" :key="s.id" :label="s.supplier_name" :value="s.id" />
          </el-select>
        </el-form-item>
        <div class="filter-btns">
          <el-button type="primary" icon="el-icon-search" @click="loadData">查询</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
          <el-button v-permission="'business:purchase:statistics:export'" icon="el-icon-download" :loading="exporting" @click="handleExport">导出报表</el-button>
        </div>
      </el-form>
    </div>

    <el-row :gutter="20" class="cards-row">
      <el-col :span="6" v-for="c in cards" :key="c.key">
        <div class="stat-card">
          <div class="stat-num">{{ c.value }}</div>
          <div class="stat-label">{{ c.label }}<span v-if="c.extra" class="stat-extra">（{{ c.extra }}）</span></div>
          <div v-if="c.change" class="stat-change" :class="c.change >= 0 ? 'up' : 'down'"><i :class="c.change >= 0 ? 'el-icon-top' : 'el-icon-bottom'" /> {{ Math.abs(c.change) }}% 环比</div>
        </div>
      </el-col>
    </el-row>

    <el-row :gutter="20">
      <el-col :span="12">
        <div class="chart-card">
          <div class="chart-head">
            <span>📈 采购额趋势分析</span>
            <div class="head-actions">
              <el-radio-group v-model="trendLine" size="mini">
                <el-radio-button label="order">订单金额</el-radio-button>
                <el-radio-button label="arrival">到货金额</el-radio-button>
                <el-radio-button label="payment">付款金额</el-radio-button>
              </el-radio-group>
            </div>
          </div>
          <div ref="chart_trend" class="chart-box" />
        </div>
      </el-col>
      <el-col :span="12">
        <div class="chart-card">
          <div class="chart-head"><span>📊 采购额构成分析</span></div>
          <div ref="chart_comp" class="chart-box" />
        </div>
      </el-col>
    </el-row>

    <div class="chart-card" style="margin-bottom:16px;">
      <div class="chart-head"><span>📊 月度环比分析</span></div>
      <div ref="chart_mom" class="chart-box" />
    </div>

    <!-- 明细表 -->
    <div class="table-card">
      <div class="chart-head"><span>📋 采购额明细</span></div>
      <el-table :data="detail.list" size="small" border empty-text="暂无数据" class="stats-table" @sort-change="onSort">
        <el-table-column prop="order_no" label="订单编号" min-width="140">
          <template slot-scope="s"><span class="link" @click="$router.push('/business/purchase/order/detail/' + s.row.id)">{{ s.row.order_no }}</span></template>
        </el-table-column>
        <el-table-column prop="supplier_name" label="供应商" min-width="150" show-overflow-tooltip />
        <el-table-column prop="type_label" label="采购类型" width="110" align="center" />
        <el-table-column prop="total_amount" label="订单金额" width="130" align="right" sortable="custom" prop-sort="total_amount">
          <template slot-scope="s">¥ {{ Number(s.row.total_amount || 0).toFixed(2) }}</template>
        </el-table-column>
        <el-table-column prop="order_date" label="下单日期" width="110" />
        <el-table-column prop="arrival_date" label="到货日期" width="110" />
        <el-table-column prop="payment_label" label="付款状态" width="95" align="center" />
      </el-table>
      <el-pagination class="pager" background layout="total, sizes, prev, pager, next" :total="detail.total" :page-sizes="[10, 20, 50]" :page-size="detail.limit" :current-page="detail.page" @current-change="p => { detail.page = p; loadDetail() }" @size-change="s => { detail.limit = s; detail.page = 1; loadDetail() }" />
    </div>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getPurchaseAmount, exportPurchaseAmount } from '../../../../api/purchase'
import { getSupplierList } from '../../../../api/businessSupplier'

const TIME_TYPES = { 7: '近7天', 30: '近30天', 90: '近90天', year: '本年', custom: '自定义' }
const PALETTE = ['#409EFF', '#67C23A', '#E6A23C', '#F56C6C', '#909399', '#9B59B6', '#1ABC9C', '#F39C12', '#2ECC71', '#E74C3C']

export default {
  name: 'PurchaseStatsAmount',
  data () {
    return {
      TIME_TYPES, now: '', loading: false, exporting: false,
      f: { time_type: '30', group_by: 'month', purchase_type: '', supplier_id: null },
      dateRange: null, supplierOptions: [],
      cards: [], trendLine: 'order',
      trend: { labels: [], order: [], arrival: [], payment: [] },
      comp: { labels: [], series: [] },
      mom: { labels: [], amount: [], rate: [] },
      detail: { list: [], total: 0, page: 1, limit: 20 },
      sort: { prop: '', order: '' },
      charts: {}
    }
  },
  created () {
    this.tick(); setInterval(() => this.tick(), 1000)
    this.loadSuppliers()
  },
  mounted () {
    this.loadData()
    window.addEventListener('resize', this.resizeAll)
  },
  beforeDestroy () {
    window.removeEventListener('resize', this.resizeAll)
    Object.values(this.charts).forEach(c => c && c.dispose())
  },
  methods: {
    tick () { this.now = new Date().toLocaleString('zh-CN', { hour12: false }) },
    onTimeTypeChange () { if (this.f.time_type !== 'custom') this.dateRange = null },
    async loadSuppliers () {
      try { const r = await getSupplierList({ status: 1, page: 1, pageSize: 200 }); this.supplierOptions = (r.data && r.data.list) || [] } catch (e) { this.supplierOptions = [] }
    },
    buildParams () {
      const p = { time_type: this.f.time_type, group_by: this.f.group_by, purchase_type: this.f.purchase_type }
      if (this.f.supplier_id) p.supplier_id = this.f.supplier_id
      if (this.f.time_type === 'custom' && this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] }
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getPurchaseAmount(this.buildParams())
        if (r.code === 0 && r.data) {
          this.cards = r.data.cards || []
          this.trend = r.data.trend || { labels: [], order: [], arrival: [], payment: [] }
          this.comp = r.data.composition || { labels: [], series: [] }
          this.mom = r.data.mom || { labels: [], amount: [], rate: [] }
          this.detail = r.data.detail || { list: [], total: 0, page: 1, limit: 20 }
          this.$nextTick(() => this.renderAll())
        }
      } catch (e) {} finally { this.loading = false }
    },
    async loadDetail () {
      try {
        const r = await getPurchaseAmount({ ...this.buildParams(), page: this.detail.page, pageSize: this.detail.limit, ...(this.sort.prop ? { order_no: '' } : {}) })
        if (r.code === 0 && r.data && r.data.detail) this.detail = r.data.detail
      } catch (e) {}
    },
    handleReset () { this.f = { time_type: '30', group_by: 'month', purchase_type: '', supplier_id: null }; this.dateRange = null; this.loadData() },
    async handleExport () {
      this.exporting = true
      try {
        const blob = await exportPurchaseAmount(this.buildParams())
        const url = window.URL.createObjectURL(new Blob([blob]))
        const a = document.createElement('a'); a.href = url; a.download = `采购额分析_${new Date().toISOString().slice(0, 10)}.xlsx`
        a.click(); window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') } finally { this.exporting = false }
    },
    onSort ({ prop, order }) {
      this.sort = { prop, order }
      if (!order || !prop) return
      const arr = [...this.detail.list]
      arr.sort((a, b) => {
        const va = Number(a[prop]) || 0
        const vb = Number(b[prop]) || 0
        return order === 'ascending' ? va - vb : vb - va
      })
      this.detail.list = arr
    },
    resizeAll () { Object.values(this.charts).forEach(c => c && c.resize()) },
    getChart (key) {
      const el = this.$refs['chart_' + key]
      if (!el) return null
      if (!this.charts[key]) this.charts[key] = echarts.init(el)
      return this.charts[key]
    },
    renderAll () {
      const lineKey = { order: 'order', arrival: 'arrival', payment: 'payment' }[this.trendLine]
      const c1 = this.getChart('trend')
      if (c1) c1.setOption({
        color: PALETTE, tooltip: { trigger: 'axis' },
        grid: { left: 60, right: 20, top: 30, bottom: 60 },
        xAxis: { type: 'category', data: this.trend.labels, axisLabel: { color: '#aaa' } },
        yAxis: { type: 'value', name: '万元', axisLabel: { color: '#aaa' } },
        dataZoom: [{ type: 'inside' }, { type: 'slider', height: 18, bottom: 10 }],
        series: [{ name: this.trendLine === 'order' ? '订单金额' : (this.trendLine === 'arrival' ? '到货金额' : '付款金额'), type: 'line', smooth: true, data: this.trend[lineKey] || [], areaStyle: { opacity: 0.15 } }]
      }, true)
      const c2 = this.getChart('comp')
      if (c2) c2.setOption({
        color: PALETTE, tooltip: { trigger: 'axis' },
        legend: { textStyle: { color: '#666' } },
        grid: { left: 60, right: 20, top: 40, bottom: 30 },
        xAxis: { type: 'category', data: this.comp.labels, axisLabel: { color: '#aaa' } },
        yAxis: { type: 'value', name: '万元', axisLabel: { color: '#aaa' } },
        series: this.comp.series.map(s => ({ name: s.name, type: 'bar', stack: 'total', data: s.data }))
      }, true)
      const c3 = this.getChart('mom')
      if (c3) c3.setOption({
        color: PALETTE, tooltip: { trigger: 'axis' },
        legend: { data: ['采购额', '环比增长率'], textStyle: { color: '#666' } },
        grid: { left: 60, right: 60, top: 40, bottom: 30 },
        xAxis: { type: 'category', data: this.mom.labels, axisLabel: { color: '#aaa' } },
        yAxis: [{ type: 'value', name: '万元', axisLabel: { color: '#aaa' } }, { type: 'value', name: '%', axisLabel: { color: '#aaa' } }],
        series: [
          { name: '采购额', type: 'bar', data: this.mom.amount, itemStyle: { color: '#409EFF' } },
          { name: '环比增长率', type: 'line', yAxisIndex: 1, data: this.mom.rate, itemStyle: { color: '#E6A23C' } }
        ]
      }, true)
    }
  }
}
</script>

<style scoped>
.stats-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.top-bar { display: flex; justify-content: space-between; align-items: center; padding: 18px 24px; background: linear-gradient(135deg, #1A1A2E, #16213E); border-radius: 12px; margin-bottom: 16px; }
.top-title { font-size: 20px; font-weight: 700; color: #fff; }
.top-breadcrumb { margin-top: 6px; }
.top-breadcrumb /deep/ .el-breadcrumb__inner, .top-breadcrumb /deep/ .el-breadcrumb__separator { color: rgba(255, 255, 255, 0.6); }
.top-right { display: flex; align-items: center; gap: 10px; }
.live-dot { width: 8px; height: 8px; border-radius: 50%; background: #67C23A; }
.live-text { color: #67C23A; font-size: 13px; }
.top-time { color: rgba(255, 255, 255, 0.8); font-size: 13px; }
.filter-bar { background: #fff; padding: 14px 16px 0; border-radius: 12px; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08); margin-bottom: 16px; }
.filter-btns { display: inline-block; margin-left: 4px; }
.cards-row { margin-bottom: 16px; }
.stat-card { background: #fff; border-radius: 12px; padding: 16px; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08); }
.stat-num { font-size: 24px; font-weight: 700; color: #303133; }
.stat-label { font-size: 14px; color: #909399; margin-top: 4px; }
.stat-extra { font-size: 12px; }
.stat-change { font-size: 12px; margin-top: 8px; }
.stat-change.up { color: #67C23A; }
.stat-change.down { color: #F56C6C; }
.chart-card { background: #fff; border-radius: 12px; overflow: hidden; margin-bottom: 16px; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08); }
.chart-head { display: flex; justify-content: space-between; align-items: center; background: linear-gradient(135deg, #1A1A2E, #16213E); color: #fff; font-size: 15px; font-weight: 600; padding: 10px 16px; }
.head-actions /deep/ .el-radio-button__inner { background: transparent; border-color: rgba(255, 255, 255, 0.3); color: #ddd; }
.head-actions /deep/ .el-radio-button__orig-radio:checked + .el-radio-button__inner { background: #409EFF; border-color: #409EFF; color: #fff; }
.chart-box { height: 320px; padding: 8px; }
.table-card { background: #fff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08); }
.stats-table /deep/ .el-table__header th { background: #2C3E50; color: #fff; }
.link { color: #409EFF; cursor: pointer; }
.pager { margin: 12px; text-align: right; }
</style>
