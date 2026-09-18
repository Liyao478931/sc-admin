<!--
  文件：admin/src/views/business/dashboard/Overview.vue
  功能：经营总览（数据驾驶舱：6 指标卡 + 趋势/类型/等级/状态 4 图表 + 月度明细）
  权限：business:dashboard:view
-->
<template>
  <div class="stats-page">
    <!-- 顶部标题栏 -->
    <div class="top-bar">
      <div>
        <div class="top-title">📊 经营总览</div>
        <el-breadcrumb separator="/" class="top-breadcrumb">
          <el-breadcrumb-item>控制台</el-breadcrumb-item>
          <el-breadcrumb-item>经营总览</el-breadcrumb-item>
        </el-breadcrumb>
      </div>
      <div class="top-right">
        <span class="live-dot"></span><span class="live-text">数据实时</span>
        <span class="top-time">{{ now }}</span>
        <span class="auto-label">自动刷新</span>
        <el-switch v-model="autoRefresh" size="mini" />
        <el-button size="small" icon="el-icon-refresh" class="refresh-btn" :loading="loading" @click="loadData">刷新数据</el-button>
      </div>
    </div>

    <!-- 筛选 -->
    <div class="filter-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="时间范围">
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始" end-placeholder="结束" value-format="yyyy-MM-dd" style="width:240px" />
        </el-form-item>
        <el-form-item label="统计维度">
          <el-select v-model="f.group_by" style="width:120px">
            <el-option label="按天" value="day" /><el-option label="按周" value="week" /><el-option label="按月" value="month" />
          </el-select>
        </el-form-item>
        <el-form-item label="部门">
          <el-select v-model="f.department_id" clearable filterable placeholder="全部部门" style="width:150px">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <div class="filter-btns">
          <el-button type="primary" icon="el-icon-search" @click="handleQuery">查询</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </div>
      </el-form>
    </div>

    <!-- 指标卡 -->
    <el-row :gutter="20" class="cards-row">
      <el-col :xs="12" :sm="8" :md="6" :lg="4" v-for="c in cards" :key="c.key">
        <div class="stat-card">
          <div class="stat-icon" :style="{ background: cardBg(c.key), color: cardColor(c.key) }"><i :class="cardIcon(c.key)" /></div>
          <div class="stat-num">{{ c.value }}</div>
          <div class="stat-label">{{ c.label }}</div>
          <div class="stat-change" :class="Number(c.change) >= 0 ? 'up' : 'down'">
            <i :class="Number(c.change) >= 0 ? 'el-icon-caret-top' : 'el-icon-caret-bottom'" />
            {{ Math.abs(Number(c.change)) }}{{ c.isPercent ? '%' : '' }} 较上期
          </div>
        </div>
      </el-col>
    </el-row>

    <!-- 图表 2x2 -->
    <el-row :gutter="20">
      <el-col :xs="24" :sm="24" :md="12" :lg="12" v-for="g in charts" :key="g.key">
        <div class="chart-card">
          <div class="chart-head"><span>{{ g.title }}</span></div>
          <div :ref="'chart_' + g.key" class="chart-box" />
        </div>
      </el-col>
    </el-row>

    <!-- 明细表格 -->
    <div class="table-card">
      <div class="chart-head"><span>📋 经营月度明细</span></div>
      <el-table :data="pagedDetail" size="small" border empty-text="暂无数据" class="stats-table" :stripe="true">
        <el-table-column prop="period" label="统计周期" width="120" />
        <el-table-column prop="customer_count" label="客户数" width="100" align="center" />
        <el-table-column prop="supplier_count" label="供应商数" width="100" align="center" />
        <el-table-column prop="order_count" label="订单数" width="100" align="center" />
        <el-table-column label="订单金额" width="130" align="right">
          <template slot-scope="s">¥ {{ Number(s.row.order_amount || 0).toLocaleString() }}</template>
        </el-table-column>
        <el-table-column prop="contract_count" label="合同数" width="100" align="center" />
        <el-table-column label="合同金额" width="130" align="right">
          <template slot-scope="s">¥ {{ Number(s.row.contract_amount || 0).toLocaleString() }}</template>
        </el-table-column>
        <el-table-column prop="production_orders" label="生产工单" width="90" align="center" />
        <el-table-column prop="reports" label="报工数" width="80" align="center" />
        <el-table-column label="操作" min-width="110" align="center">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="goOrders(s.row.period)">查看订单</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, prev, pager, next" :total="detail.length" :page-size="10" :current-page="detailPage" @current-change="p => detailPage = p" v-if="detail.length > 10" />
    </div>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getOverviewData, getDepartments } from '../../../api/dashboard'

const PALETTE = ['#409EFF', '#67C23A', '#E6A23C', '#F56C6C', '#909399', '#9B59B6', '#1ABC9C', '#F39C12', '#2ECC71', '#E74C3C']

export default {
  name: 'BusinessDashboardOverview',
  data () {
    return {
      now: '', loading: false, autoRefresh: true, deptOptions: [],
      f: { group_by: 'month', department_id: '' },
      dateRange: [this.daysAgo(29), this.today()],
      cards: [],
      charts: [
        { key: 'trend', title: '📈 订单趋势分析' },
        { key: 'orderType', title: '🥧 订单类型分布' },
        { key: 'customerLevel', title: '🏢 客户等级分布' },
        { key: 'contractStatus', title: '📄 合同状态分布' }
      ],
      chartInstances: {},
      detail: [],
      pagedDetail: [],
      detailPage: 1
    }
  },
  created () {
    this.tick()
    setInterval(() => this.tick(), 1000)
    setInterval(() => { if (this.autoRefresh) this.loadData() }, 60000)
    this.loadDepartments()
  },
  mounted () { this.loadData() },
  watch: {
    detail (v) {
      this.detailPage = 1
      this.pagedDetail = v.slice(0, 10)
    },
    detailPage (p) { this.pagedDetail = this.detail.slice((p - 1) * 10, p * 10) }
  },
  beforeDestroy () { Object.values(this.chartInstances).forEach(c => c && c.dispose()) },
  methods: {
    today () { const d = new Date(); return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0') },
    daysAgo (n) { const d = new Date(); d.setDate(d.getDate() - n); return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0') },
    tick () { this.now = new Date().toLocaleString('zh-CN', { hour12: false }) },
    cardColor (k) {
      return { customers: '#409EFF', suppliers: '#67C23A', orders: '#E6A23C', contractAmount: '#F56C6C', monthOrders: '#409EFF', monthCustomers: '#67C23A' }[k] || '#409EFF'
    },
    cardBg (k) {
      return { customers: '#ECF5FF', suppliers: '#F0F9EB', orders: '#FDF6EC', contractAmount: '#FEF0F0', monthOrders: '#ECF5FF', monthCustomers: '#F0F9EB' }[k] || '#F0F7FF'
    },
    cardIcon (k) {
      return { customers: 'el-icon-user', suppliers: 'el-icon-truck', orders: 'el-icon-document', contractAmount: 'el-icon-money', monthOrders: 'el-icon-plus', monthCustomers: 'el-icon-user-solid' }[k] || 'el-icon-data-line'
    },
    buildParams () {
      const p = { group_by: this.f.group_by }
      if (this.f.department_id) p.department_id = this.f.department_id
      if (this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] }
      return p
    },
    async loadDepartments () {
      try { const r = await getDepartments(); if (r.code === 0) this.deptOptions = r.data || r.data.list || [] } catch (e) { this.deptOptions = [] }
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getOverviewData(this.buildParams())
        if (r.code === 0 && r.data) {
          this.cards = r.data.cards || []
          this.detail = r.data.detail || []
          this.$nextTick(() => this.renderAll(r.data))
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleQuery () { this.loadData() },
    handleReset () { this.f = { group_by: 'month', department_id: '' }; this.dateRange = [this.daysAgo(29), this.today()]; this.loadData() },
    goOrders (period) { this.$router.push({ path: '/business/order', query: { start_date: period + '-01', end_date: period + '-31' } }) },
    renderAll (d) {
      this.renderTrend(d.trend || { labels: [], count: [], amount: [] })
      this.renderOrderType(d.order_type_dist || [])
      this.renderCustomerLevel(d.customer_level_dist || [])
      this.renderContractStatus(d.contract_status_dist || [])
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
        legend: { data: ['订单数量', '订单金额'], textStyle: { color: '#ddd' } },
        grid: { left: 60, right: 60, top: 40, bottom: 30 },
        xAxis: { type: 'category', data: t.labels, axisLabel: { color: '#aaa' } },
        yAxis: [
          { type: 'value', name: '数量', axisLabel: { color: '#aaa' }, splitLine: { lineStyle: { color: 'rgba(255,255,255,0.1)' } } },
          { type: 'value', name: '金额(万)', axisLabel: { color: '#aaa' }, splitLine: { show: false } }
        ],
        series: [
          { name: '订单数量', type: 'line', smooth: true, symbol: 'circle', data: t.count, itemStyle: { color: '#409EFF' }, areaStyle: { opacity: 0.12 } },
          { name: '订单金额', type: 'line', smooth: true, symbol: 'circle', yAxisIndex: 1, data: t.amount, itemStyle: { color: '#67C23A' } }
        ]
      }, true)
    },
    renderOrderType (list) {
      const c = this.getChart('orderType')
      if (!c) return
      c.off('click')
      const total = list.reduce((s, v) => s + Number(v.value || 0), 0)
      c.setOption({
        color: PALETTE,
        tooltip: { trigger: 'item', formatter: p => `${p.name}：${p.value} 单（${p.percent}%）` },
        legend: { textStyle: { color: '#ddd' } },
        title: { text: String(total), subtext: '总订单数', left: 'center', top: '36%', textStyle: { color: '#fff', fontSize: 22 }, subtextStyle: { color: '#909399', fontSize: 12 } },
        series: [{
          type: 'pie', radius: ['42%', '66%'], center: ['50%', '55%'],
          label: { color: '#ddd', formatter: '{b}\n{d}%' },
          emphasis: { itemStyle: { shadowBlur: 10, shadowOffsetX: 0, shadowColor: 'rgba(0,0,0,0.5)' } },
          data: list
        }]
      }, true)
      c.on('click', p => {
        if (p && p.data && p.data.code) this.$router.push({ path: '/business/order', query: { order_category: p.data.code } })
      })
    },
    renderCustomerLevel (list) {
      const c = this.getChart('customerLevel')
      if (!c) return
      c.off('click')
      const colors = { A: '#F7BA2A', B: '#409EFF', C: '#E6A23C', D: '#909399' }
      c.setOption({
        color: PALETTE,
        tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
        grid: { left: 60, right: 20, top: 30, bottom: 30 },
        xAxis: { type: 'category', data: list.map(v => v.name), axisLabel: { color: '#aaa' } },
        yAxis: { type: 'value', axisLabel: { color: '#aaa' }, splitLine: { lineStyle: { color: 'rgba(255,255,255,0.1)' } } },
        series: [{
          type: 'bar', barWidth: 46,
          label: { show: true, position: 'top', color: '#ddd' },
          data: list.map(v => ({ value: v.value, level: v.level, itemStyle: { color: colors[v.level] || '#409EFF', borderRadius: [6, 6, 0, 0] } }))
        }]
      }, true)
      c.on('click', p => {
        if (p && p.data && p.data.level) this.$router.push({ path: '/business/customer', query: { level: p.data.level } })
      })
    },
    renderContractStatus (list) {
      const c = this.getChart('contractStatus')
      if (!c) return
      c.off('click')
      const total = list.reduce((s, v) => s + Number(v.value || 0), 0)
      const colors = { draft: '#909399', pending: '#E6A23C', approved: '#67C23A', executing: '#409EFF', completed: '#9B59B6', terminated: '#F56C6C', voided: '#C0C4CC' }
      c.setOption({
        tooltip: { trigger: 'item', formatter: p => `${p.name}：${p.value} 份（${p.percent}%）` },
        legend: { textStyle: { color: '#ddd' } },
        title: { text: String(total), subtext: '合同总数', left: 'center', top: '36%', textStyle: { color: '#fff', fontSize: 22 }, subtextStyle: { color: '#909399', fontSize: 12 } },
        series: [{
          type: 'pie', radius: ['42%', '66%'], center: ['50%', '55%'],
          label: { color: '#ddd', formatter: '{b}\n{d}%' },
          emphasis: { itemStyle: { shadowBlur: 10, shadowOffsetX: 0, shadowColor: 'rgba(0,0,0,0.5)' } },
          data: list.map(v => ({ code: v.code, name: v.name, value: v.value, percent: v.percent, itemStyle: { color: colors[v.code] || '#409EFF' } }))
        }]
      }, true)
      c.on('click', p => {
        if (p && p.data && p.data.code) this.$router.push({ path: '/business/contract', query: { contract_status: p.data.code } })
      })
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
.auto-label { color: rgba(255, 255, 255, 0.7); font-size: 13px; }
.refresh-btn { background: rgba(255, 255, 255, 0.1); color: #fff; border: none; }
.filter-bar { background: #fff; padding: 14px 16px 0; border-radius: 12px; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08); margin-bottom: 16px; }
.filter-btns { display: inline-block; margin-left: 4px; }
.cards-row { margin-bottom: 16px; }
.stat-card { background: #fff; border-radius: 12px; padding: 16px; position: relative; box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06); transition: transform 0.3s; }
.stat-card:hover { transform: translateY(-4px); }
.stat-icon { position: absolute; top: 14px; right: 14px; width: 40px; height: 40px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 22px; }
.stat-num { font-size: 24px; font-weight: 700; color: #303133; margin-top: 8px; max-width: 70%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.stat-label { font-size: 14px; color: #909399; margin-top: 4px; }
.stat-change { font-size: 12px; margin-top: 8px; }
.stat-change.up { color: #67C23A; }
.stat-change.down { color: #F56C6C; }
.chart-card { background: #fff; border-radius: 12px; overflow: hidden; margin-bottom: 16px; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08); }
.chart-head { background: linear-gradient(135deg, #2C3E50, #34495E); color: #fff; font-size: 15px; font-weight: 600; padding: 10px 16px; }
.chart-box { height: 320px; padding: 8px; }
.table-card { background: #fff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08); }
.stats-table { width: 100%; }
.stats-table /deep/ .el-table__header th { background: #2C3E50; color: #fff; }
.stats-table /deep/ .el-table__row--striped td { background: #F5F7FA; }
.stats-table /deep/ .el-table__body tr:hover > td { background: #E6F7FF; }
.pager { margin: 12px; text-align: right; }
</style>
