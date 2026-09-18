<!--
  文件：admin/src/views/production/dashboard/Index.vue
  功能：生产看板（数据驾驶舱风格：KPI 指标卡 + 4 图表 + 进度预警 + 自动刷新）
  权限：production:dashboard:view
-->
<template>
  <div class="dashboard-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>生产看板</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 顶部标题栏 -->
    <div class="top-bar">
      <div class="top-left">
        <span class="top-title">📊 生产看板</span>
        <span class="status-dot" :class="{ offline: !dataOk }" />
        <span class="status-text">{{ dataOk ? '数据实时' : '数据更新中…' }}</span>
      </div>
      <div class="top-right">
        <span class="live-time">{{ now }}</span>
        <el-button size="small" :icon="refreshing ? 'el-icon-loading' : 'el-icon-refresh'" @click="loadData">刷新数据</el-button>
        <span class="auto-label">自动刷新</span>
        <el-switch v-model="autoRefresh" size="mini" />
      </div>
    </div>

    <!-- 核心 KPI 指标卡 -->
    <el-row :gutter="16" class="kpi-row">
      <el-col :span="6"><div class="kpi-card"><div class="kpi-icon" style="background:#ECF5FF;color:#409EFF"><i class="el-icon-check" /></div><div class="kpi-num">{{ kpi.today_production.value }}</div><div class="kpi-label">今日产量</div><div class="kpi-change" :class="kpi.today_production.change >= 0 ? 'up' : 'down'">{{ kpi.today_production.change >= 0 ? '▲' : '▼' }} {{ Math.abs(kpi.today_production.change) }}</div></div></el-col>
      <el-col :span="6"><div class="kpi-card"><div class="kpi-icon" style="background:#FDF6EC;color:#E6A23C"><i class="el-icon-loading" /></div><div class="kpi-num">{{ kpi.in_progress_orders.value }}</div><div class="kpi-label">进行中工单</div><div class="kpi-change up">实时</div></div></el-col>
      <el-col :span="6"><div class="kpi-card"><div class="kpi-icon" style="background:#F4ECF7;color:#9B59B6"><i class="el-icon-document-checked" /></div><div class="kpi-num">{{ kpi.pending_quality_orders.value }}</div><div class="kpi-label">待质检工单</div><div class="kpi-change up">实时</div></div></el-col>
      <el-col :span="6"><div class="kpi-card"><div class="kpi-icon" style="background:#FEF0F0;color:#F56C6C"><i class="el-icon-warning" /></div><div class="kpi-num" style="color:#F56C6C">{{ kpi.overdue_orders.value }}</div><div class="kpi-label">延期工单</div><div class="kpi-change down">预警</div></div></el-col>
    </el-row>
    <el-row :gutter="16" class="kpi-row kpi-row2">
      <el-col :span="6" :offset="6"><div class="kpi-card"><div class="kpi-icon" style="background:#ECF5FF;color:#409EFF"><i class="el-icon-data-line" /></div><div class="kpi-num">{{ Number(kpi.workstation_utilization.value).toFixed(1) }}%</div><div class="kpi-label">工位利用率</div><div class="kpi-change" :class="kpi.workstation_utilization.change >= 0 ? 'up' : 'down'">{{ kpi.workstation_utilization.change >= 0 ? '▲' : '▼' }} {{ Math.abs(kpi.workstation_utilization.change) }}%</div></div></el-col>
      <el-col :span="6"><div class="kpi-card"><div class="kpi-icon" style="background:#F0F9EB;color:#67C23A"><i class="el-icon-circle-check" /></div><div class="kpi-num" style="color:#67C23A">{{ Number(kpi.quality_pass_rate.value).toFixed(1) }}%</div><div class="kpi-label">合格率</div><div class="kpi-change" :class="kpi.quality_pass_rate.change >= 0 ? 'up' : 'down'">{{ kpi.quality_pass_rate.change >= 0 ? '▲' : '▼' }} {{ Math.abs(kpi.quality_pass_rate.change) }}%</div></div></el-col>
    </el-row>

    <!-- 图表区域 第一行 -->
    <el-row :gutter="16" class="chart-row">
      <el-col :span="12">
        <div class="chart-card">
          <div class="chart-header"><span class="chart-title"><i class="el-icon-pie-chart" /> 工单状态分布</span></div>
          <div ref="statusChart" class="chart-box" />
        </div>
      </el-col>
      <el-col :span="12">
        <div class="chart-card">
          <div class="chart-header"><span class="chart-title"><i class="el-icon-data-line" /> 工位负荷率</span></div>
          <div ref="wsChart" class="chart-box" />
        </div>
      </el-col>
    </el-row>
    <!-- 图表区域 第二行 -->
    <el-row :gutter="16" class="chart-row">
      <el-col :span="12">
        <div class="chart-card">
          <div class="chart-header"><span class="chart-title"><i class="el-icon-trend-charts" /> 每日产量趋势</span></div>
          <div ref="dailyChart" class="chart-box" />
        </div>
      </el-col>
      <el-col :span="12">
        <div class="chart-card">
          <div class="chart-header"><span class="chart-title"><i class="el-icon-circle-check" /> 质量概况</span></div>
          <div class="quality-wrap">
            <div ref="gaugeChart" class="chart-box-half" />
            <div ref="rejectChart" class="chart-box-half" />
          </div>
        </div>
      </el-col>
    </el-row>

    <!-- 预警列表 -->
    <div class="alert-card">
      <div class="alert-header"><span class="chart-title" style="color:#fff"><i class="el-icon-warning-outline" /> 进度预警</span><span class="alert-count">共 {{ alerts.length }} 个预警</span></div>
      <el-table :data="alerts" size="small" border class="alert-table" empty-text="暂无预警">
        <el-table-column label="工单编号" width="180"><template slot-scope="s"><span class="link-blue" @click="$router.push(`/production/plan/order/detail/${s.row.id}`)">{{ s.row.order_no }}</span></template></el-table-column>
        <el-table-column prop="product_name" label="产品名称" min-width="140" show-overflow-tooltip />
        <el-table-column prop="planned_end_date" label="计划完成日期" width="120" align="center" />
        <el-table-column label="当前进度" width="180">
          <template slot-scope="s">
            <div class="progress-cell">
              <el-progress :percentage="Number(s.row.progress)" :color="progressColor(s.row.progress)" :show-text="false" style="width:100px" />
              <span class="progress-text">{{ Number(s.row.progress) }}%</span>
            </div>
          </template>
        </el-table-column>
        <el-table-column label="延期状态" width="100" align="center">
          <template slot-scope="s"><el-tag :type="s.row.overdue_status === '已延期' ? 'danger' : 'warning'" size="mini">{{ s.row.overdue_status }}</el-tag></template>
        </el-table-column>
        <el-table-column label="延期天数" width="90" align="center"><template slot-scope="s">{{ s.row.overdue_days ? `${s.row.overdue_days} 天` : '-' }}</template></el-table-column>
        <el-table-column label="操作" width="100" align="center"><template slot-scope="s"><el-button type="text" size="mini" @click="$router.push(`/production/plan/order/detail/${s.row.id}`)">查看详情</el-button></template></el-table-column>
      </el-table>
      <div class="alert-footer"><el-button type="text" size="small" @click="$router.push('/production/execute/progress')">查看全部 →</el-button></div>
    </div>
  </div>
</template>

<script>
import echarts from '@/utils/echarts'
import { getDashboardData } from '@/api/production'

export default {
  name: 'ProductionDashboard',
  data () {
    return {
      now: this.fmtNow(),
      autoRefresh: true,
      refreshing: false,
      dataOk: true,
      kpi: {
        today_production: { value: 0, change: 0 }, in_progress_orders: { value: 0, change: 0 },
        pending_quality_orders: { value: 0, change: 0 }, overdue_orders: { value: 0, change: 0 },
        workstation_utilization: { value: 0, change: 0 }, quality_pass_rate: { value: 0, change: 0 }
      },
      statusDist: [], wsLoad: [], dailyProd: [], quality: { pass_rate: 0, reject_distribution: [] }, alerts: [],
      charts: {}, timers: []
    }
  },
  created () {
    this.loadData()
    this.timers.push(setInterval(() => { this.now = this.fmtNow() }, 1000))
    this.timers.push(setInterval(() => { if (this.autoRefresh) this.loadData() }, 30000))
  },
  mounted () { this.$nextTick(() => this.initCharts()) },
  beforeDestroy () {
    this.timers.forEach(t => clearInterval(t))
    window.removeEventListener('resize', this.handleResize)
    Object.values(this.charts).forEach(c => { if (c) c.dispose() })
    this.charts = {}
  },
  methods: {
    fmtNow () {
      const d = new Date()
      const p = n => String(n).padStart(2, '0')
      return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`
    },
    progressColor (p) { const v = Number(p); if (v < 30) return '#F56C6C'; if (v < 70) return '#E6A23C'; return '#67C23A' },
    async loadData () {
      this.refreshing = true
      this.dataOk = false
      try {
        const r = await getDashboardData()
        if (r.code === 0 && r.data) {
          this.kpi = r.data.kpi || this.kpi
          this.statusDist = r.data.order_status_distribution || []
          this.wsLoad = r.data.workstation_load || []
          this.dailyProd = r.data.daily_production || []
          this.quality = r.data.quality || { pass_rate: 0, reject_distribution: [] }
          this.alerts = r.data.alerts || []
          this.dataOk = true
          this.$nextTick(() => this.renderCharts())
        }
      } catch (e) {} finally { this.refreshing = false }
    },
    handleResize () { Object.values(this.charts).forEach(c => { if (c) c.resize() }) },
    initCharts () {
      const map = { statusChart: 'status', wsChart: 'ws', dailyChart: 'daily', gaugeChart: 'gauge', rejectChart: 'reject' }
      Object.keys(map).forEach(k => { if (this.$refs[k] && !this.charts[map[k]]) this.charts[map[k]] = echarts.init(this.$refs[k]) })
      window.addEventListener('resize', this.handleResize)
    },
    renderCharts () {
      if (!Object.keys(this.charts).length) this.initCharts()
      const statusColor = { 待派工: '#909399', 已派工: '#409EFF', 进行中: '#E6A23C', 待质检: '#9B59B6', 已完成: '#67C23A', 已关闭: '#C0C4CC' }
      const total = this.statusDist.reduce((s, x) => s + x.value, 0)
      // 工单状态分布（环形图）
      if (this.charts.status) {
        this.charts.status.setOption({
          tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
          legend: { bottom: 0 },
          graphic: [{ type: 'text', left: 'center', top: '38%', style: { text: `总工单数\n${total}`, textAlign: 'center', fill: '#606266', fontSize: 13, lineHeight: 20 } }],
          series: [{
            type: 'pie', radius: ['42%', '66%'], center: ['50%', '45%'], avoidLabelOverlap: true,
            label: { show: false }, emphasis: { label: { show: true, fontSize: 12, fontWeight: 'bold' } },
            data: this.statusDist.map(x => ({ name: x.name, value: x.value, itemStyle: { color: statusColor[x.name] } }))
          }]
        }, true)
        this.charts.status.off('click')
        this.charts.status.on('click', p => { if (p.name) this.$router.push({ path: '/production/plan/order/list', query: { status: this.statusNameToVal(p.name) } }) })
      }
      // 工位负荷率（柱状图）
      if (this.charts.ws) {
        this.charts.ws.setOption({
          tooltip: { trigger: 'axis', formatter: p => { const d = p[0] && p[0].data; return d ? `${d.name}<br/>任务数：${d.tasks}<br/>利用率：${d.utilization}%` : '' } },
          grid: { left: 50, right: 30, top: 30, bottom: 60 },
          xAxis: { type: 'category', data: this.wsLoad.map(w => w.name), axisLabel: { rotate: 30, interval: 0 } },
          yAxis: { type: 'value', name: '利用率%', max: 100 },
          series: [{
            type: 'bar', barMaxWidth: 34,
            data: this.wsLoad.map(w => ({ name: w.name, value: w.utilization, tasks: w.tasks, itemStyle: { color: w.utilization > 85 ? '#F56C6C' : (w.utilization >= 60 ? '#409EFF' : '#67C23A') } })),
            label: { show: true, position: 'top', formatter: '{c}%' }
          }]
        }, true)
        this.charts.ws.off('click')
        this.charts.ws.on('click', () => this.$router.push('/production/plan/schedule'))
      }
      // 每日产量趋势（折线图）
      if (this.charts.daily) {
        this.charts.daily.setOption({
          tooltip: { trigger: 'axis' },
          legend: { data: ['计划产量', '实际产量'], top: 0, right: 10 },
          grid: { left: 50, right: 30, top: 40, bottom: 40 },
          xAxis: { type: 'category', data: this.dailyProd.map(d => d.date.slice(5)) },
          yAxis: { type: 'value', name: '产量' },
          series: [
            { name: '计划产量', type: 'line', smooth: true, data: this.dailyProd.map(d => d.planned), itemStyle: { color: '#909399' }, lineStyle: { type: 'dashed' }, symbol: 'circle' },
            { name: '实际产量', type: 'line', smooth: true, data: this.dailyProd.map(d => d.actual), itemStyle: { color: '#409EFF' }, symbol: 'circle' }
          ]
        }, true)
        this.charts.daily.off('click')
        this.charts.daily.on('click', () => this.$router.push('/production/report/list'))
      }
      // 质量概况（仪表盘 + 饼图）
      const rate = Number(this.quality.pass_rate) || 0
      if (this.charts.gauge) {
        this.charts.gauge.setOption({
          series: [{
            type: 'gauge', min: 0, max: 100, radius: '95%', center: ['50%', '55%'],
            axisLine: { lineStyle: { width: 12, color: [[rate < 90 ? 1 : 0.9, rate < 90 ? '#F56C6C' : '#67C23A'], [1, '#e8ecf1']] } },
            pointer: { length: '60%', width: 4 },
            detail: { valueAnimation: true, formatter: '{value}%', fontSize: 18, color: rate < 90 ? '#F56C6C' : '#303133' },
            data: [{ value: rate }],
            title: { show: true, offsetCenter: [0, '70%'], fontSize: 12 }
          }]
        }, true)
        this.charts.gauge.off('click')
        this.charts.gauge.on('click', () => this.$router.push('/production/quality/statistics'))
      }
      if (this.charts.reject) {
        this.charts.reject.setOption({
          tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
          legend: { bottom: 0, type: 'scroll' },
          series: [{ type: 'pie', radius: ['30%', '58%'], center: ['50%', '45%'], data: this.quality.reject_distribution.filter(x => x.value > 0), label: { show: false } }]
        }, true)
        this.charts.reject.off('click')
        this.charts.reject.on('click', () => this.$router.push('/production/quality/reject'))
      }
    },
    statusNameToVal (name) {
      return { 待派工: 0, 已派工: 1, 进行中: 2, 待质检: 3, 已完成: 4, 已关闭: 5 }[name] ?? ''
    }
  }
}
</script>

<style scoped>
.dashboard-page { padding: 16px; background: linear-gradient(180deg, #0a1628 0%, #1a2a4a 100%); min-height: calc(100vh - 60px); border-radius: 8px; }
.breadcrumb { margin-bottom: 12px; }
.breadcrumb >>> .el-breadcrumb__inner, .breadcrumb >>> .el-breadcrumb__separator { color: rgba(255,255,255,0.7); }
.breadcrumb >>> .el-breadcrumb__inner.is-link { color: rgba(255,255,255,0.85); }
.top-bar { display: flex; justify-content: space-between; align-items: center; padding: 16px 24px; background: linear-gradient(90deg, #1A1A2E, #16213E); border-radius: 8px; box-shadow: 0 2px 20px rgba(64,158,255,0.15); }
.top-left { display: flex; align-items: center; gap: 10px; }
.top-title { font-size: 20px; font-weight: 600; color: #fff; }
.status-dot { width: 8px; height: 8px; border-radius: 50%; background: #67C23A; box-shadow: 0 0 6px #67C23A; animation: pulse 1.5s infinite; }
.status-dot.offline { background: #E6A23C; box-shadow: 0 0 6px #E6A23C; }
@keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.3; } 100% { opacity: 1; } }
.status-text { font-size: 13px; color: rgba(255,255,255,0.7); }
.top-right { display: flex; align-items: center; gap: 12px; }
.live-time { font-size: 14px; color: rgba(255,255,255,0.8); }
.auto-label { font-size: 13px; color: rgba(255,255,255,0.7); }
.kpi-row { margin-top: 16px; }
.kpi-row2 { margin-top: 12px; }
.kpi-card { position: relative; background: linear-gradient(180deg, #ffffff, #f5f9ff); border-radius: 10px; padding: 16px 18px; box-shadow: 0 4px 20px rgba(64,158,255,0.08); transition: transform .3s; }
.kpi-card:hover { transform: translateY(-4px); }
.kpi-icon { position: absolute; top: 16px; left: 18px; width: 24px; height: 24px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 14px; }
.kpi-num { font-size: 32px; font-weight: 700; color: #303133; margin: 26px 0 0 40px; line-height: 1.1; }
.kpi-label { font-size: 14px; color: #909399; margin: 4px 0 0 40px; }
.kpi-change { position: absolute; right: 16px; bottom: 18px; font-size: 13px; }
.kpi-change.up { color: #67C23A; }
.kpi-change.down { color: #F56C6C; }
.chart-row { margin-top: 16px; }
.chart-card { background: #fff; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 20px rgba(64,158,255,0.06); margin-bottom: 4px; }
.chart-header { display: flex; justify-content: space-between; align-items: center; padding: 10px 16px; background: #2C3E50; }
.chart-title { font-size: 14px; font-weight: 600; color: #fff; }
.chart-box { width: 100%; height: 340px; }
.chart-box-half { width: 50%; height: 340px; display: inline-block; vertical-align: top; }
.quality-wrap { width: 100%; }
.alert-card { margin-top: 16px; background: #fff; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 20px rgba(64,158,255,0.06); }
.alert-header { display: flex; justify-content: space-between; align-items: center; padding: 10px 16px; background: #2C3E50; }
.alert-count { color: #E6A23C; font-size: 13px; }
.alert-table { width: 100%; }
.alert-table >>> .el-table__header th { background: #2C3E50 !important; color: #fff !important; }
.alert-table >>> .el-table__row--striped td { background: #F5F7FA !important; }
.alert-footer { padding: 8px 16px; text-align: right; }
.link-blue { color: #409EFF; cursor: pointer; }
.progress-cell { display: flex; align-items: center; gap: 6px; }
.progress-text { font-size: 12px; color: #606266; }
</style>
