<!--
  文件：admin/src/views/business/purchase/statistics/Supplier.vue
  功能：供应商排行（4 指标 + TOP10/占比/合作趋势 + 排行表）
  权限：business:purchase:statistics:view / export
-->
<template>
  <div class="stats-page">
    <div class="top-bar">
      <div>
        <div class="top-title">🏆 供应商排行</div>
        <el-breadcrumb separator="/" class="top-breadcrumb">
          <el-breadcrumb-item>经营管理</el-breadcrumb-item>
          <el-breadcrumb-item>采购管理</el-breadcrumb-item>
          <el-breadcrumb-item>采购统计</el-breadcrumb-item>
          <el-breadcrumb-item>供应商排行</el-breadcrumb-item>
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
        <el-form-item label="供应商分类">
          <el-select v-model="f.supplier_category" clearable style="width:150px">
            <el-option v-for="(t, v) in SUPPLIER_CATS" :key="v" :label="t" :value="v" />
          </el-select>
        </el-form-item>
        <div class="filter-btns">
          <el-button type="primary" icon="el-icon-search" @click="loadData">查询</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
          <el-button v-permission="'business:purchase:statistics:export'" icon="el-icon-download" :loading="exporting" @click="handleExport">导出排行</el-button>
        </div>
      </el-form>
    </div>

    <el-row :gutter="20" class="cards-row">
      <el-col :span="6" v-for="c in cards" :key="c.key">
        <div class="stat-card">
          <div class="stat-num">{{ c.value }}</div>
          <div class="stat-label">{{ c.label }}</div>
          <div v-if="c.change" class="stat-change" :class="c.change >= 0 ? 'up' : 'down'"><i :class="c.change >= 0 ? 'el-icon-top' : 'el-icon-bottom'" /> {{ Math.abs(c.change) }}{{ ['concentration'].includes(c.key) ? '%' : '' }} 环比</div>
        </div>
      </el-col>
    </el-row>

    <el-row :gutter="20">
      <el-col :span="12">
        <div class="chart-card">
          <div class="chart-head"><span>🏆 供应商采购额排行 TOP10</span></div>
          <div ref="chart_top10" class="chart-box" />
        </div>
      </el-col>
      <el-col :span="12">
        <div class="chart-card">
          <div class="chart-head"><span>🥧 供应商采购占比分布</span></div>
          <div ref="chart_pie" class="chart-box" />
        </div>
      </el-col>
    </el-row>

    <div class="chart-card" style="margin-bottom:16px;">
      <div class="chart-head"><span>📈 供应商合作趋势（TOP5）</span></div>
      <div ref="chart_trend" class="chart-box" />
    </div>

    <!-- 排行表 -->
    <div class="table-card">
      <div class="chart-head"><span>📋 供应商排行明细</span></div>
      <div class="table-toolbar">
        <el-input v-model="keyword" placeholder="按供应商名称搜索" clearable size="small" style="width:220px" @keyup.enter.native="loadRank" @clear="loadRank" />
        <span class="total-tip">共 {{ rank.total }} 家</span>
      </div>
      <el-table :data="rank.list" size="small" border empty-text="暂无数据" class="stats-table">
        <el-table-column label="排名" width="80" align="center">
          <template slot-scope="s"><span v-if="s.$index < 3" class="medal">{{ ['🥇', '🥈', '🥉'][s.$index] }}</span><span v-else>{{ (rank.page - 1) * rank.limit + s.$index + 1 }}</span></template>
        </el-table-column>
        <el-table-column label="供应商名称" min-width="180">
          <template slot-scope="s"><span class="link">{{ s.row.supplier_name }}</span></template>
        </el-table-column>
        <el-table-column prop="supplier_type" label="分类" width="100" align="center" />
        <el-table-column prop="count" label="合作次数" width="90" align="center" />
        <el-table-column prop="total" label="采购总额" width="130" align="right" sortable>
          <template slot-scope="s">¥ {{ Number(s.row.total || 0).toFixed(2) }}</template>
        </el-table-column>
        <el-table-column prop="avg" label="平均单价" width="120" align="right">
          <template slot-scope="s">¥ {{ Number(s.row.avg || 0).toFixed(2) }}</template>
        </el-table-column>
        <el-table-column prop="max" label="最高单价" width="120" align="right">
          <template slot-scope="s">¥ {{ Number(s.row.max || 0).toFixed(2) }}</template>
        </el-table-column>
        <el-table-column prop="min" label="最低单价" width="120" align="right">
          <template slot-scope="s">¥ {{ Number(s.row.min || 0).toFixed(2) }}</template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, sizes, prev, pager, next" :total="rank.total" :page-sizes="[10, 20, 50]" :page-size="rank.limit" :current-page="rank.page" @current-change="p => { rank.page = p; loadRank() }" @size-change="s => { rank.limit = s; rank.page = 1; loadRank() }" />
    </div>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getPurchaseSupplier, exportPurchaseSupplier } from '../../../../api/purchase'

const TIME_TYPES = { 30: '近30天', 90: '近90天', 180: '近180天', year: '本年', custom: '自定义' }
const SUPPLIER_CATS = { manufacturer: '生产厂家', trader: '贸易商', outsource: '外协加工', service: '服务商', gonghuoshang: '供货商', other: '其他' }
const PALETTE = ['#409EFF', '#67C23A', '#E6A23C', '#F56C6C', '#909399', '#9B59B6', '#1ABC9C', '#F39C12', '#2ECC71', '#E74C3C']

export default {
  name: 'PurchaseStatsSupplier',
  data () {
    return {
      TIME_TYPES, SUPPLIER_CATS, now: '', loading: false, exporting: false,
      f: { time_type: '30', supplier_category: '' },
      dateRange: null, keyword: '',
      cards: [], top10: [], pie: [], trend: { labels: [], series: [] },
      rank: { list: [], total: 0, page: 1, limit: 20 },
      charts: {}
    }
  },
  created () {
    this.tick(); setInterval(() => this.tick(), 1000)
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
    buildParams () {
      const p = { time_type: this.f.time_type, supplier_category: this.f.supplier_category }
      if (this.f.time_type === 'custom' && this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] }
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getPurchaseSupplier(this.buildParams())
        if (r.code === 0 && r.data) {
          this.cards = r.data.cards || []
          this.top10 = r.data.top10 || []
          this.pie = r.data.pie || []
          this.trend = r.data.trend || { labels: [], series: [] }
          this.rank = r.data.rank || { list: [], total: 0, page: 1, limit: 20 }
          this.$nextTick(() => this.renderAll())
        }
      } catch (e) {} finally { this.loading = false }
    },
    async loadRank () {
      try {
        const r = await getPurchaseSupplier({ ...this.buildParams(), keyword: this.keyword, page: this.rank.page, pageSize: this.rank.limit })
        if (r.code === 0 && r.data && r.data.rank) this.rank = r.data.rank
      } catch (e) {}
    },
    handleReset () { this.f = { time_type: '30', supplier_category: '' }; this.dateRange = null; this.keyword = ''; this.loadData() },
    async handleExport () {
      this.exporting = true
      try {
        const blob = await exportPurchaseSupplier(this.buildParams())
        const url = window.URL.createObjectURL(new Blob([blob]))
        const a = document.createElement('a'); a.href = url; a.download = `供应商排行_${new Date().toISOString().slice(0, 10)}.xlsx`
        a.click(); window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') } finally { this.exporting = false }
    },
    resizeAll () { Object.values(this.charts).forEach(c => c && c.resize()) },
    getChart (key) {
      const el = this.$refs['chart_' + key]
      if (!el) return null
      if (!this.charts[key]) this.charts[key] = echarts.init(el)
      return this.charts[key]
    },
    renderAll () {
      const c1 = this.getChart('top10')
      if (c1) c1.setOption({
        color: PALETTE, tooltip: { trigger: 'axis' },
        grid: { left: 140, right: 60, top: 20, bottom: 30 },
        xAxis: { type: 'value', name: '万元', axisLabel: { color: '#aaa' } },
        yAxis: { type: 'category', data: this.top10.map((v, i) => (i < 3 ? ['🥇', '🥈', '🥉'][i] + ' ' : '') + v.supplier_name).reverse(), axisLabel: { color: '#aaa' } },
        series: [{
          type: 'bar', data: this.top10.map(v => Number((v.total / 10000).toFixed(2))).reverse(),
          label: { show: true, position: 'right', color: '#ddd' },
          itemStyle: { color: { type: 'linear', x: 0, y: 0, x2: 1, y2: 0, colorStops: [{ offset: 0, color: '#409EFF' }, { offset: 1, color: '#2B6CB0' }] } }
        }]
      }, true)
      const c2 = this.getChart('pie')
      if (c2) c2.setOption({
        color: PALETTE, tooltip: { trigger: 'item', formatter: p => `${p.name}：¥${Number(p.value).toLocaleString()}（${((p.value / this.pie.reduce((s, v) => s + v.value, 0)) * 100).toFixed(1)}%）` },
        legend: { textStyle: { color: '#666' } },
        series: [{
          type: 'pie', radius: ['40%', '68%'], center: ['50%', '55%'],
          label: { color: '#666' },
          data: this.pie,
          emphasis: { itemStyle: { shadowBlur: 10, shadowOffsetX: 0, shadowColor: 'rgba(0,0,0,0.5)' } }
        }]
      }, true)
      const c3 = this.getChart('trend')
      if (c3) c3.setOption({
        color: PALETTE, tooltip: { trigger: 'axis' },
        legend: { textStyle: { color: '#666' } },
        grid: { left: 60, right: 20, top: 40, bottom: 30 },
        xAxis: { type: 'category', data: this.trend.labels, axisLabel: { color: '#aaa' } },
        yAxis: { type: 'value', name: '万元', axisLabel: { color: '#aaa' } },
        series: this.trend.series.map(s => ({ name: s.name, type: 'line', smooth: true, data: s.data }))
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
.stat-change { font-size: 12px; margin-top: 8px; }
.stat-change.up { color: #67C23A; }
.stat-change.down { color: #F56C6C; }
.chart-card { background: #fff; border-radius: 12px; overflow: hidden; margin-bottom: 16px; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08); }
.chart-head { background: linear-gradient(135deg, #1A1A2E, #16213E); color: #fff; font-size: 15px; font-weight: 600; padding: 10px 16px; }
.chart-box { height: 320px; padding: 8px; }
.table-card { background: #fff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08); }
.table-toolbar { display: flex; align-items: center; padding: 10px 16px; gap: 10px; }
.total-tip { font-size: 14px; color: #909399; }
.stats-table /deep/ .el-table__header th { background: #2C3E50; color: #fff; }
.medal { font-size: 18px; }
.link { color: #409EFF; cursor: pointer; }
.pager { margin: 12px; text-align: right; }
</style>
