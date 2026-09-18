<!--
  文件：admin/src/views/production/quality/statistics/Index.vue
  功能：质量统计（统计卡片 + 质量趋势/不合格类型/工位合格率/检验员工作量 4 图表 + 导出）
  权限：quality:statistics:view / export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>质量管理</el-breadcrumb-item>
      <el-breadcrumb-item>质量统计</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="统计周期">
          <el-date-picker v-model="query.month" type="month" value-format="yyyy-MM" placeholder="选择月份" style="width:130px" />
        </el-form-item>
        <el-form-item label="产品类型">
          <el-select v-model="query.product_type" clearable placeholder="全部" style="width:120px">
            <el-option v-for="t in productTypes" :key="t" :label="t" :value="t" />
          </el-select>
        </el-form-item>
        <el-form-item label="工单类型">
          <el-select v-model="query.order_type" clearable placeholder="全部" style="width:120px">
            <el-option label="生产工单" :value="1" />
            <el-option label="维修工单" :value="2" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="loadData">查询</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
          <el-button v-permission="'quality:statistics:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="8"><div class="stat-card stat-blue"><div class="stat-icon"><i class="el-icon-document" /></div><div class="stat-info"><div class="stat-num" style="color:#409EFF">{{ cards.total }}</div><div class="stat-label">总检验数</div></div></div></el-col>
      <el-col :span="8"><div class="stat-card stat-green"><div class="stat-icon"><i class="el-icon-check" /></div><div class="stat-info"><div class="stat-num" style="color:#67C23A">{{ cards.qualified }}</div><div class="stat-label">合格数</div></div></div></el-col>
      <el-col :span="8"><div class="stat-card stat-purple"><div class="stat-icon"><i class="el-icon-data-line" /></div><div class="stat-info"><div class="stat-num" style="color:#9B59B6">{{ Number(cards.rate || 0).toFixed(1) }}%</div><div class="stat-label">合格率</div></div></div></el-col>
    </el-row>

    <!-- 图表区域 -->
    <el-row :gutter="16" class="chart-row">
      <el-col :span="12"><el-card shadow="never" class="chart-card"><div slot="header">质量趋势（近 12 个月合格率）</div><div ref="trendChart" class="chart-box" /></el-card></el-col>
      <el-col :span="12"><el-card shadow="never" class="chart-card"><div slot="header">不合格类型分布</div><div ref="distChart" class="chart-box" /></el-card></el-col>
      <el-col :span="12"><el-card shadow="never" class="chart-card"><div slot="header">工位合格率排行</div><div ref="wsChart" class="chart-box" /></el-card></el-col>
      <el-col :span="12"><el-card shadow="never" class="chart-card"><div slot="header">检验员工作量</div><div ref="inspChart" class="chart-box" /></el-card></el-col>
    </el-row>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getQualityStatistics, exportQualityStatistics } from '@/api/production'

export default {
  name: 'QualityStatistics',
  data () {
    const d = new Date()
    return {
      productTypes: ['油缸', '立柱', '减速器', '液压支架', '通用'],
      query: { month: `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`, product_type: '', order_type: '' },
      cards: { total: 0, qualified: 0, rate: 0 },
      charts: {}, exporting: false
    }
  },
  created () { this.loadData() },
  mounted () {
    this.$nextTick(() => this.initCharts())
    window.addEventListener('resize', this.handleResize)
  },
  beforeDestroy () {
    window.removeEventListener('resize', this.handleResize)
    Object.values(this.charts).forEach(c => { if (c) c.dispose() })
    this.charts = {}
  },
  methods: {
    buildParams () {
      const p = { month: this.query.month }
      if (this.query.product_type) p.product_type = this.query.product_type
      if (this.query.order_type !== '' && this.query.order_type !== null) p.order_type = this.query.order_type
      return p
    },
    async loadData () {
      try {
        const r = await getQualityStatistics(this.buildParams())
        if (r.code === 0 && r.data) {
          this.cards = r.data.cards || this.cards
          this.$nextTick(() => this.renderCharts(r.data))
        }
      } catch (e) {}
    },
    handleReset () {
      const d = new Date()
      this.query = { month: `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`, product_type: '', order_type: '' }
      this.loadData()
    },
    handleResize () { Object.values(this.charts).forEach(c => { if (c) c.resize() }) },
    initCharts () {
      const map = { trendChart: 'trend', distChart: 'dist', wsChart: 'ws', inspChart: 'insp' }
      Object.keys(map).forEach(k => { if (this.$refs[k] && !this.charts[map[k]]) this.charts[map[k]] = echarts.init(this.$refs[k]) })
    },
    renderCharts (data) {
      if (!Object.keys(this.charts).length) this.initCharts()
      // 趋势
      if (this.charts.trend) {
        this.charts.trend.setOption({
          tooltip: { trigger: 'axis' },
          grid: { left: 50, right: 30, top: 30, bottom: 40 },
          xAxis: { type: 'category', data: data.trend.months || [], axisLabel: { rotate: 30 } },
          yAxis: { type: 'value', name: '合格率%', max: 100 },
          series: [{ name: '合格率', type: 'line', smooth: true, data: data.trend.rates || [], itemStyle: { color: '#409EFF' }, areaStyle: { opacity: 0.15 } }]
        }, true)
      }
      // 不合格类型分布
      if (this.charts.dist) {
        this.charts.dist.setOption({
          tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
          legend: { bottom: 0 },
          series: [{ type: 'pie', radius: ['35%', '62%'], center: ['50%', '45%'], data: (data.reject_dist || []).filter(x => x.value > 0) }]
        }, true)
      }
      // 工位合格率排行
      if (this.charts.ws) {
        const ws = data.ws_rate || []
        this.charts.ws.setOption({
          tooltip: { trigger: 'axis' },
          grid: { left: 60, right: 30, top: 30, bottom: 60 },
          xAxis: { type: 'category', data: ws.map(w => w.workstation_name), axisLabel: { rotate: 30, interval: 0 } },
          yAxis: { type: 'value', name: '合格率%', max: 100 },
          series: [{ name: '合格率', type: 'bar', data: ws.map(w => w.rate), itemStyle: { color: '#67C23A' } }]
        }, true)
      }
      // 检验员工作量
      if (this.charts.insp) {
        const insp = data.inspector_workload || []
        this.charts.insp.setOption({
          tooltip: { trigger: 'axis' },
          grid: { left: 60, right: 30, top: 30, bottom: 60 },
          xAxis: { type: 'category', data: insp.map(i => i.name), axisLabel: { rotate: 30, interval: 0 } },
          yAxis: { type: 'value', name: '检验数量' },
          series: [{ name: '检验数量', type: 'bar', data: insp.map(i => i.count), itemStyle: { color: '#E6A23C' } }]
        }, true)
      }
    },
    async handleExport () {
      this.exporting = true
      try {
        const r = await exportQualityStatistics(this.buildParams())
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `质量统计_${this.query.month}.xlsx`
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
.stat-row { margin-top: 16px; }
.stat-card { display: flex; align-items: center; padding: 14px 18px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); }
.stat-blue { background: linear-gradient(135deg, #ecf5ff, #d9ecff); }
.stat-green { background: linear-gradient(135deg, #f0f9eb, #e1f3d8); }
.stat-purple { background: linear-gradient(135deg, #f5ecfb, #ecd9f7); }
.stat-icon { font-size: 28px; margin-right: 12px; }
.stat-blue .stat-icon { color: #409EFF; }
.stat-green .stat-icon { color: #67C23A; }
.stat-purple .stat-icon { color: #9B59B6; }
.stat-num { font-size: 20px; font-weight: bold; color: #303133; line-height: 1.2; }
.stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.chart-row { margin-top: 16px; }
.chart-card { border-radius: 8px; margin-bottom: 16px; }
.chart-box { width: 100%; height: 300px; }
</style>
