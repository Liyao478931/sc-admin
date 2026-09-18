<!--
  文件：admin/src/views/warehouse/parts/purchase-in/Statistics.vue
  功能：入库统计看板（指标卡 + 趋势/供应商/仓库/物料）
  权限：warehouse:purchase:in:statistics:view
-->
<template>
  <div class="stats-page">
    <div class="top-bar">
      <div>
        <div class="top-title">📊 入库统计看板</div>
        <el-breadcrumb separator="/" class="top-breadcrumb">
          <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
          <el-breadcrumb-item>配件出入库</el-breadcrumb-item>
          <el-breadcrumb-item>入库统计</el-breadcrumb-item>
        </el-breadcrumb>
      </div>
      <div class="top-right">
        <span class="live-dot"></span><span class="live-text">数据实时</span>
        <el-button size="small" icon="el-icon-refresh" class="refresh-btn" :loading="loading" @click="loadData">刷新数据</el-button>
      </div>
    </div>

    <div class="filter-bar">
      <el-form inline size="small" label-width="80px">
        <el-form-item label="时间类型">
          <el-select v-model="f.time_type" style="width:120px" @change="loadData">
            <el-option label="按日" value="day" /><el-option label="按周" value="week" /><el-option label="按月" value="month" /><el-option label="按年" value="year" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="loadData">查询</el-button>
        </el-form-item>
      </el-form>
    </div>

    <el-row :gutter="16" class="cards-row">
      <el-col :span="6" v-for="c in cards" :key="c.key">
        <div class="stat-card">
          <div class="stat-num">{{ c.value }}</div>
          <div class="stat-label">{{ c.label }}</div>
          <div v-if="c.change !== 0" class="stat-change" :class="c.change >= 0 ? 'up' : 'down'">
            <i :class="c.change >= 0 ? 'el-icon-caret-top' : 'el-icon-caret-bottom'" /> {{ Math.abs(c.change) }}% 环比
          </div>
        </div>
      </el-col>
    </el-row>

    <el-row :gutter="16">
      <el-col :span="12"><div class="chart-card"><div class="chart-head">📈 入库趋势</div><div ref="chart_trend" class="chart-box" /></div></el-col>
      <el-col :span="12"><div class="chart-card"><div class="chart-head">🏢 供应商入库排行 TOP10</div><div ref="chart_supplier" class="chart-box" /></div></el-col>
      <el-col :span="12"><div class="chart-card"><div class="chart-head">🏬 仓库入库分布</div><div ref="chart_warehouse" class="chart-box" /></div></el-col>
      <el-col :span="12"><div class="chart-card"><div class="chart-head">📦 物料入库排行 TOP10</div><div ref="chart_material" class="chart-box" /></div></el-col>
    </el-row>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getPurchaseInStatistics } from '../../../../api/warehouse'

const PALETTE = ['#409EFF', '#67C23A', '#E6A23C', '#F56C6C', '#909399', '#9B59B6', '#1ABC9C', '#F39C12', '#2ECC71', '#E74C3C']

export default {
  name: 'WarehousePurchaseInStatistics',
  data () {
    return {
      loading: false,
      f: { time_type: 'month' },
      cards: [], chartInstances: {}
    }
  },
  mounted () { this.loadData() },
  beforeDestroy () { Object.values(this.chartInstances).forEach(c => c && c.dispose()) },
  methods: {
    getChart (key) {
      const el = this.$refs['chart_' + key]
      if (!el) return null
      if (!this.chartInstances[key]) this.chartInstances[key] = echarts.init(el)
      return this.chartInstances[key]
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getPurchaseInStatistics({ time_type: this.f.time_type })
        if (r.code === 0 && r.data) {
          this.cards = r.data.cards || []
          this.$nextTick(() => {
            this.renderTrend(r.data.trend || { labels: [], qty: [], amount: [] })
            this.renderSupplier(r.data.supplier_rank || [])
            this.renderWarehouse(r.data.warehouse_dist || [])
            this.renderMaterial(r.data.material_rank || [])
          })
        }
      } catch (e) {} finally { this.loading = false }
    },
    renderTrend (t) {
      const c = this.getChart('trend')
      if (!c) return
      c.setOption({
        color: PALETTE,
        tooltip: { trigger: 'axis' },
        legend: { data: ['入库数量', '入库金额'], textStyle: { color: '#ddd' } },
        grid: { left: 60, right: 60, top: 40, bottom: 30 },
        xAxis: { type: 'category', data: t.labels, axisLabel: { color: '#aaa' } },
        yAxis: [
          { type: 'value', name: '数量', axisLabel: { color: '#aaa' }, splitLine: { lineStyle: { color: 'rgba(255,255,255,0.1)' } } },
          { type: 'value', name: '金额(元)', axisLabel: { color: '#aaa' }, splitLine: { show: false } }
        ],
        series: [
          { name: '入库数量', type: 'line', smooth: true, data: t.qty, itemStyle: { color: '#409EFF' }, areaStyle: { opacity: 0.12 } },
          { name: '入库金额', type: 'line', smooth: true, yAxisIndex: 1, data: t.amount, itemStyle: { color: '#67C23A' } }
        ]
      }, true)
    },
    renderSupplier (list) {
      const c = this.getChart('supplier')
      if (!c) return
      const names = list.slice().reverse().map(v => v.name)
      const values = list.slice().reverse().map(v => v.amount)
      c.setOption({
        color: PALETTE,
        tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
        grid: { left: 90, right: 40, top: 20, bottom: 30 },
        xAxis: { type: 'value', axisLabel: { color: '#aaa' }, splitLine: { lineStyle: { color: 'rgba(255,255,255,0.1)' } } },
        yAxis: { type: 'category', data: names, axisLabel: { color: '#aaa' } },
        series: [{ type: 'bar', data: values, label: { show: true, position: 'right', color: '#ddd' }, itemStyle: { color: { type: 'linear', x: 0, y: 0, x2: 1, y2: 0, colorStops: [{ offset: 0, color: '#409EFF' }, { offset: 1, color: '#2B6CB0' }] } } }]
      }, true)
    },
    renderWarehouse (list) {
      const c = this.getChart('warehouse')
      if (!c) return
      const total = list.reduce((s, v) => s + Number(v.amount || 0), 0)
      c.setOption({
        color: PALETTE,
        tooltip: { trigger: 'item', formatter: p => `${p.name}：¥${Number(p.value).toLocaleString()}（${total > 0 ? ((p.value / total) * 100).toFixed(1) : 0}%）` },
        legend: { textStyle: { color: '#ddd' } },
        series: [{ type: 'pie', radius: ['40%', '66%'], center: ['50%', '55%'], label: { color: '#ddd' }, data: list.map(v => ({ name: v.name, value: Number(v.amount || 0) })) }]
      }, true)
    },
    renderMaterial (list) {
      const c = this.getChart('material')
      if (!c) return
      c.setOption({
        color: PALETTE,
        tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
        grid: { left: 60, right: 40, top: 20, bottom: 60 },
        xAxis: { type: 'category', data: list.map(v => v.name), axisLabel: { color: '#aaa', interval: 0, rotate: 30 } },
        yAxis: { type: 'value', axisLabel: { color: '#aaa' }, splitLine: { lineStyle: { color: 'rgba(255,255,255,0.1)' } } },
        series: [{ type: 'bar', barWidth: 26, data: list.map(v => v.amount), label: { show: true, position: 'top', color: '#ddd' }, itemStyle: { color: { type: 'linear', x: 0, y: 0, x2: 0, y2: 1, colorStops: [{ offset: 0, color: '#E6A23C' }, { offset: 1, color: '#B8860B' }] } } }]
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
.refresh-btn { background: rgba(255, 255, 255, 0.1); color: #fff; border: none; }
.filter-bar { background: #fff; padding: 14px 16px 0; border-radius: 12px; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08); margin-bottom: 16px; }
.cards-row { margin-bottom: 16px; }
.stat-card { background: #fff; border-radius: 12px; padding: 16px; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08); }
.stat-num { font-size: 22px; font-weight: 700; color: #303133; }
.stat-label { font-size: 14px; color: #909399; margin-top: 6px; }
.stat-change { font-size: 12px; margin-top: 6px; }
.stat-change.up { color: #67C23A; }
.stat-change.down { color: #F56C6C; }
.chart-card { background: #fff; border-radius: 12px; overflow: hidden; margin-bottom: 16px; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08); }
.chart-head { background: linear-gradient(135deg, #2C3E50, #34495E); color: #fff; font-size: 15px; font-weight: 600; padding: 10px 16px; }
.chart-box { height: 300px; padding: 8px; }
</style>
