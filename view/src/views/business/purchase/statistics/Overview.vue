<!--
  文件：admin/src/views/business/purchase/statistics/Overview.vue
  功能：采购统计总览（6 指标卡 + 趋势/类型/部门/对比 4 图表 + 月度明细）
  权限：business:purchase:statistics:view / export
-->
<template>
  <div class="stats-page">
    <!-- 顶部标题栏 -->
    <div class="top-bar">
      <div>
        <div class="top-title">📊 采购数据驾驶舱</div>
        <el-breadcrumb separator="/" class="top-breadcrumb">
          <el-breadcrumb-item>经营管理</el-breadcrumb-item>
          <el-breadcrumb-item>采购管理</el-breadcrumb-item>
          <el-breadcrumb-item>采购统计</el-breadcrumb-item>
          <el-breadcrumb-item>总览</el-breadcrumb-item>
        </el-breadcrumb>
      </div>
      <div class="top-right">
        <span class="live-dot"></span><span class="live-text">数据实时</span>
        <span class="top-time">{{ now }}</span>
        <el-button size="small" icon="el-icon-refresh" class="refresh-btn" :loading="loading" @click="loadData">刷新数据</el-button>
      </div>
    </div>

    <!-- 筛选 -->
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
        <el-form-item label="采购类型">
          <el-select v-model="f.purchase_type" style="width:140px">
            <el-option label="全部" value="" /><el-option label="日常采购" value="1" /><el-option label="项目采购" value="2" /><el-option label="紧急采购" value="3" /><el-option label="备品备件采购" value="4" />
          </el-select>
        </el-form-item>
        <el-form-item label="统计维度">
          <el-select v-model="f.dimension" style="width:130px" @change="onDimChange">
            <el-option label="按申请部门" value="department" /><el-option label="按采购类型" value="type" /><el-option label="按供应商" value="supplier" />
          </el-select>
        </el-form-item>
        <div class="filter-btns">
          <el-button type="primary" icon="el-icon-search" @click="handleQuery">查询</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
          <el-button v-permission="'business:purchase:statistics:export'" icon="el-icon-download" :loading="exporting" @click="handleExport">导出报表</el-button>
        </div>
      </el-form>
    </div>

    <!-- 指标卡 -->
    <el-row :gutter="20" class="cards-row">
      <el-col :span="4" v-for="c in cards" :key="c.key">
        <div class="stat-card">
          <div class="stat-icon" :style="{ background: cardColor(c.key) }"><i :class="cardIcon(c.key)" /></div>
          <div class="stat-num">{{ c.value }}</div>
          <div class="stat-label">{{ c.label }}</div>
          <div class="stat-change" :class="c.change >= 0 ? 'up' : 'down'">
            <i :class="c.change >= 0 ? 'el-icon-top' : 'el-icon-bottom'" /> {{ Math.abs(c.change) }}{{ ['arrival', 'quality', 'growth'].includes(c.key) ? '%' : '' }} 环比
          </div>
        </div>
      </el-col>
    </el-row>

    <!-- 图表 2x2 -->
    <el-row :gutter="20">
      <el-col :span="12" v-for="g in charts" :key="g.key">
        <div class="chart-card">
          <div class="chart-head"><span>{{ g.key === 'dept' ? dimChartTitle : g.title }}</span></div>
          <div :ref="'chart_' + g.key" class="chart-box" />
        </div>
      </el-col>
    </el-row>

    <!-- 月度明细 -->
    <div class="table-card">
      <div class="chart-head"><span>📋 月度采购明细</span></div>
      <el-table :data="pagedMonthly" size="small" border empty-text="暂无数据" class="stats-table">
        <el-table-column prop="period" label="统计周期" width="120" />
        <el-table-column prop="requests" label="采购申请数" width="110" align="center" />
        <el-table-column prop="orders" label="采购订单数" width="110" align="center" />
        <el-table-column label="采购金额" width="140" align="right">
          <template slot-scope="s">¥ {{ Number(s.row.amount || 0).toFixed(2) }}</template>
        </el-table-column>
        <el-table-column prop="arrival_rate" label="到货及时率" width="110" align="center" />
        <el-table-column prop="quality_rate" label="质检合格率" width="110" align="center" />
        <el-table-column label="操作" min-width="120" align="center">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="goOrders(s.row.period)">查看订单</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, prev, pager, next" :total="monthly.length" :page-size="10" :current-page="1" @current-change="p => monthlyPage = p" v-if="monthly.length > 10" />
    </div>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getPurchaseOverview, exportPurchaseAmount } from '../../../../api/purchase'

const TIME_TYPES = { 7: '近7天', 30: '近30天', 90: '近90天', year: '本年', custom: '自定义' }
const PALETTE = ['#409EFF', '#67C23A', '#E6A23C', '#F56C6C', '#909399', '#9B59B6', '#1ABC9C', '#F39C12', '#2ECC71', '#E74C3C']

export default {
  name: 'PurchaseStatsOverview',
  data () {
    return {
      TIME_TYPES,
      now: '', loading: false, exporting: false,
      f: { time_type: '30', purchase_type: '', dimension: 'department' },
      dateRange: null, monthlyPage: 1,
      cards: [],
      charts: [
        { key: 'trend', title: '📈 采购金额趋势' },
        { key: 'type', title: '🥧 采购类型分布' },
        { key: 'dept', title: '🏢 部门采购排行' },
        { key: 'compare', title: '📊 申请 vs 订单 对比' }
      ],
    chartInstances: {},
    monthly: [],
    pagedMonthly: [],
    lastData: null
  }
},
  computed: {
    dimChartTitle () {
      return { department: '🏢 部门采购排行', type: '📊 采购类型排行', supplier: '🏢 供应商排行（请前往供应商排行页查看）' }[this.f.dimension] || '🏢 部门采购排行'
    }
  },
  created () {
    this.tick()
    setInterval(() => this.tick(), 1000)
  },
  mounted () { this.loadData() },
  watch: {
    monthly (v) {
      this.monthlyPage = 1
      this.pagedMonthly = v.slice(0, 10)
    },
    monthlyPage (p) { this.pagedMonthly = this.monthly.slice((p - 1) * 10, p * 10) }
  },
  beforeDestroy () { Object.values(this.chartInstances).forEach(c => c && c.dispose()) },
  methods: {
    tick () { this.now = new Date().toLocaleString('zh-CN', { hour12: false }) },
    cardColor (k) {
      return { amount: '#409EFF', orders: '#67C23A', arrival: '#E6A23C', quality: '#E6A23C', suppliers: '#67C23A', requests: '#409EFF' }[k] || '#409EFF'
    },
    cardIcon (k) {
      return { amount: 'el-icon-money', orders: 'el-icon-s-order', arrival: 'el-icon-van', quality: 'el-icon-circle-check', suppliers: 'el-icon-office-building', requests: 'el-icon-shopping-cart-2' }[k] || 'el-icon-data-line'
    },
    onTimeTypeChange () { if (this.f.time_type !== 'custom') this.dateRange = null },
    buildParams () {
      const p = { time_type: this.f.time_type, purchase_type: this.f.purchase_type }
      if (this.f.time_type === 'custom' && this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] }
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getPurchaseOverview(this.buildParams())
        if (r.code === 0 && r.data) {
          this.lastData = r.data
          this.cards = r.data.cards || []
          this.monthly = r.data.monthly || []
          this.$nextTick(() => this.renderAll(r.data))
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleQuery () { this.loadData() },
    onDimChange () { if (this.lastData) this.renderAll(this.lastData) },
    handleReset () { this.f = { time_type: '30', purchase_type: '', dimension: 'department' }; this.dateRange = null; this.loadData() },
    async handleExport () {
      this.exporting = true
      try {
        const blob = await exportPurchaseAmount(this.buildParams())
        const url = window.URL.createObjectURL(new Blob([blob]))
        const a = document.createElement('a')
        a.href = url; a.download = `采购额分析_${new Date().toISOString().slice(0, 10)}.xlsx`
        a.click(); window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') } finally { this.exporting = false }
    },
    goOrders (period) { this.$router.push({ path: '/business/purchase/order/list', query: { start_date: period + '-01', end_date: period + '-31' } }) },
    renderAll (d) {
      this.lastTypeDist = d.type_dist || []
      this.renderTrend(d.trend || { labels: [], current: [], prev: [] })
      this.renderType(this.lastTypeDist)
      this.renderDept(d.dept_rank || [])
      this.renderCompare(d.compare || { labels: [], request: [], order: [] })
    },
    getChart (key) {
      const el = this.$refs['chart_' + key]
      if (!el || !el[0]) return null
      if (!this.chartInstances[key]) this.chartInstances[key] = echarts.init(el[0])
      return this.chartInstances[key]
    },
    renderTrend (t) {
      const c = this.getChart('trend')
      if (!c) return
      c.setOption({
        color: PALETTE,
        tooltip: { trigger: 'axis' },
        legend: { data: ['本期', '上期'], textStyle: { color: '#ddd' } },
        grid: { left: 60, right: 20, top: 40, bottom: 30 },
        xAxis: { type: 'category', data: t.labels, axisLabel: { color: '#aaa' } },
        yAxis: { type: 'value', name: '万元', axisLabel: { color: '#aaa' } },
        series: [
          { name: '本期', type: 'line', smooth: true, data: t.current, areaStyle: { opacity: 0.15 } },
          { name: '上期', type: 'line', smooth: true, data: t.prev, lineStyle: { type: 'dashed' } }
        ]
      }, true)
    },
    renderType (list) {
      const c = this.getChart('type')
      if (!c) return
      const total = list.reduce((s, v) => s + v.value, 0)
      c.setOption({
        color: PALETTE,
        tooltip: { trigger: 'item', formatter: p => `${p.name}：¥${Number(p.value).toLocaleString()}（${total > 0 ? ((p.value / total) * 100).toFixed(1) : 0}%）` },
        legend: { textStyle: { color: '#ddd' } },
        series: [{
          type: 'pie', radius: ['40%', '68%'], center: ['50%', '55%'],
          label: { color: '#ddd' },
          data: list
        }]
      }, true)
    },
    renderDept (deptList) {
      const c = this.getChart('dept')
      if (!c) return
      // 按统计维度切换图表3 数据：部门 → dept_rank；类型 → type_dist；供应商 → 空（引导至供应商排行页）
      let names = []
      let values = []
      if (this.f.dimension === 'type') {
        names = this.lastTypeDist.map(v => v.name)
        values = this.lastTypeDist.map(v => v.value)
      } else if (this.f.dimension === 'supplier') {
        names = []
        values = []
      } else {
        names = deptList.map(v => v.name)
        values = deptList.map(v => v.value)
      }
      c.setOption({
        color: PALETTE,
        tooltip: { trigger: 'axis' },
        grid: { left: 90, right: 40, top: 20, bottom: 30 },
        xAxis: { type: 'value', name: '万元', axisLabel: { color: '#aaa' } },
        yAxis: { type: 'category', data: names, axisLabel: { color: '#aaa' } },
        series: [{
          type: 'bar', data: values.map(v => Number((v / 10000).toFixed(2))),
          label: { show: true, position: 'right', color: '#ddd' },
          itemStyle: { color: { type: 'linear', x: 0, y: 0, x2: 1, y2: 0, colorStops: [{ offset: 0, color: '#409EFF' }, { offset: 1, color: '#2B6CB0' }] } }
        }]
      }, true)
    },
    renderCompare (d) {
      const c = this.getChart('compare')
      if (!c) return
      c.setOption({
        color: ['#409EFF', '#67C23A'],
        tooltip: { trigger: 'axis' },
        legend: { data: ['采购申请', '采购订单'], textStyle: { color: '#ddd' } },
        grid: { left: 60, right: 20, top: 40, bottom: 30 },
        xAxis: { type: 'category', data: d.labels, axisLabel: { color: '#aaa' } },
        yAxis: { type: 'value', name: '万元', axisLabel: { color: '#aaa' } },
        series: [
          { name: '采购申请', type: 'bar', data: d.request },
          { name: '采购订单', type: 'bar', data: d.order }
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
.live-dot { width: 8px; height: 8px; border-radius: 50%; background: #67C23A; display: inline-block; }
.live-text { color: #67C23A; font-size: 13px; }
.top-time { color: rgba(255, 255, 255, 0.8); font-size: 13px; }
.refresh-btn { background: rgba(255, 255, 255, 0.1); color: #fff; border: none; }
.filter-bar { background: #fff; padding: 14px 16px 0; border-radius: 12px; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08); margin-bottom: 16px; }
.filter-btns { display: inline-block; margin-left: 4px; }
.cards-row { margin-bottom: 16px; }
.stat-card { background: #fff; border-radius: 12px; padding: 16px; position: relative; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08); }
.stat-icon { position: absolute; top: 14px; right: 14px; width: 40px; height: 40px; border-radius: 10px; display: flex; align-items: center; justify-content: center; color: #fff; font-size: 20px; }
.stat-num { font-size: 24px; font-weight: 700; color: #303133; margin-top: 8px; max-width: 70%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.stat-label { font-size: 14px; color: #909399; margin-top: 4px; }
.stat-change { font-size: 12px; margin-top: 8px; }
.stat-change.up { color: #67C23A; }
.stat-change.down { color: #F56C6C; }
.chart-card { background: #fff; border-radius: 12px; overflow: hidden; margin-bottom: 16px; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08); }
.chart-head { background: linear-gradient(135deg, #1A1A2E, #16213E); color: #fff; font-size: 15px; font-weight: 600; padding: 10px 16px; }
.chart-box { height: 320px; padding: 8px; }
.table-card { background: #fff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08); }
.stats-table { width: 100%; }
.stats-table /deep/ .el-table__header th { background: #2C3E50; color: #fff; }
.stats-table /deep/ .el-table__row--striped td { background: #F5F7FA; }
.pager { margin: 12px; text-align: right; }
</style>
