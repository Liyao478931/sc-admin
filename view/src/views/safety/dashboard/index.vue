<template>
  <div class="safety-dashboard">
    <!-- 顶部操作栏 -->
    <div class="dash-header">
      <div class="dash-title">
        <h2>安全驾驶舱</h2>
        <span class="dash-sub">安全管理 · 决策指挥中心</span>
      </div>
      <div class="dash-actions">
        <span class="update-time" v-if="lastUpdate">最后更新：{{ lastUpdate }}</span>
        <el-select v-model="refreshInterval" size="mini" style="width:120px;margin-right:8px;" @change="restartAutoRefresh">
          <el-option v-for="opt in refreshOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
        </el-select>
        <el-button size="mini" icon="el-icon-refresh" :loading="refreshing" @click="refreshAll">刷新</el-button>
      </div>
    </div>

    <!-- 核心指标卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="4" v-for="card in statCards" :key="card.key">
        <div class="stat-card" :style="{ borderTopColor: card.color }">
          <div class="stat-icon" :style="{ background: card.color + '1a', color: card.color }">
            <i :class="card.icon"></i>
          </div>
          <div class="stat-body">
            <div class="stat-value" :style="{ color: card.color }">{{ displayValue(card) }}</div>
            <div class="stat-label">{{ card.label }}</div>
            <div class="stat-trend">
              <span v-if="card.trend === 'up'" style="color:#F56C6C;"><i class="el-icon-top"></i> 较上月 +{{ card.trendValue }}</span>
              <span v-else-if="card.trend === 'down'" style="color:#67C23A;"><i class="el-icon-bottom"></i> 较上月 -{{ card.trendValue }}</span>
              <span v-else style="color:#909399;">持平</span>
            </div>
          </div>
        </div>
      </el-col>
    </el-row>

    <!-- 第一行：隐患趋势 / 事故趋势 -->
    <el-row :gutter="16" class="chart-row">
      <el-col :span="12">
        <div class="panel">
          <div class="panel-head">
            <span class="panel-title">隐患趋势</span>
            <el-radio-group v-model="hazardMonths" size="mini" @change="loadHazardTrend">
              <el-radio-button :label="6">6个月</el-radio-button>
              <el-radio-button :label="12">12个月</el-radio-button>
              <el-radio-button :label="24">24个月</el-radio-button>
            </el-radio-group>
          </div>
          <div ref="hazardTrend" class="chart-box"></div>
        </div>
      </el-col>
      <el-col :span="12">
        <div class="panel">
          <div class="panel-head">
            <span class="panel-title">事故趋势</span>
            <el-radio-group v-model="accidentMonths" size="mini" @change="loadAccidentTrend">
              <el-radio-button :label="6">6个月</el-radio-button>
              <el-radio-button :label="12">12个月</el-radio-button>
              <el-radio-button :label="24">24个月</el-radio-button>
            </el-radio-group>
          </div>
          <div ref="accidentTrend" class="chart-box"></div>
        </div>
      </el-col>
    </el-row>

    <!-- 第二行：隐患等级 / 风险等级 -->
    <el-row :gutter="16" class="chart-row">
      <el-col :span="12">
        <div class="panel">
          <div class="panel-head"><span class="panel-title">隐患等级分布</span></div>
          <div ref="hazardLevel" class="chart-box"></div>
        </div>
      </el-col>
      <el-col :span="12">
        <div class="panel">
          <div class="panel-head"><span class="panel-title">风险等级分布</span></div>
          <div ref="riskLevel" class="chart-box"></div>
        </div>
      </el-col>
    </el-row>

    <!-- 第三行：今日待办 / 即将到期预警 -->
    <el-row :gutter="16" class="chart-row">
      <el-col :span="12">
        <div class="panel">
          <div class="panel-head">
            <span class="panel-title">今日待办事项</span>
            <span class="panel-count">共 {{ todos.total }} 项</span>
          </div>
          <el-table :data="todos.list" size="mini" empty-text="暂无待办事项">
            <el-table-column label="事项名称" min-width="170" show-overflow-tooltip>
              <template slot-scope="{ row }">
                <span :style="row.overdue ? 'color:#F56C6C;font-weight:600;' : ''">{{ row.name }}</span>
              </template>
            </el-table-column>
            <el-table-column label="类型" width="88">
              <template slot-scope="{ row }">
                <el-tag size="mini" :type="todoTagType(row.type)">{{ row.type_label }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="截止日期" width="100">
              <template slot-scope="{ row }">
                <span :style="row.overdue ? 'color:#F56C6C;' : ''">{{ row.deadline }}</span>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="70">
              <template slot-scope="{ row }">
                <el-button type="text" size="mini" @click="go(row.url)">处理</el-button>
              </template>
            </el-table-column>
          </el-table>
          <div v-if="todos.total > 10" class="panel-more" @click="goAllTodos">查看全部 <i class="el-icon-arrow-right"></i></div>
        </div>
      </el-col>
      <el-col :span="12">
        <div class="panel">
          <div class="panel-head">
            <span class="panel-title">即将到期预警</span>
            <span class="panel-count">共 {{ warnings.total }} 项</span>
          </div>
          <el-table :data="warnings.list" size="mini" empty-text="暂无预警事项">
            <el-table-column label="预警名称" min-width="170" show-overflow-tooltip>
              <template slot-scope="{ row }">{{ row.name }}</template>
            </el-table-column>
            <el-table-column label="类型" width="88">
              <template slot-scope="{ row }">
                <el-tag size="mini" :type="warnTagType(row.type)">{{ row.type_label }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="到期日期" width="100">
              <template slot-scope="{ row }">{{ row.expire_date }}</template>
            </el-table-column>
            <el-table-column label="剩余" width="70">
              <template slot-scope="{ row }">
                <span :style="row.days_left <= 7 ? 'color:#F56C6C;font-weight:600;' : (row.days_left <= 30 ? 'color:#E6A23C;' : '')">{{ row.days_left }}天</span>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="70">
              <template slot-scope="{ row }">
                <el-button type="text" size="mini" @click="go(row.url)">查看</el-button>
              </template>
            </el-table-column>
          </el-table>
          <div v-if="warnings.total > 10" class="panel-more" @click="goAllWarnings">查看全部 <i class="el-icon-arrow-right"></i></div>
        </div>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import {
  getDashboardOverview, getHazardTrend, getAccidentTrend,
  getHazardLevel, getRiskLevel, getDashboardTodos, getUpcomingWarnings
} from '@/api/safetyDashboard'

export default {
  name: 'SafetyDashboard',
  data () {
    return {
      // 概览
      overview: {},
      lastUpdate: '',
      // 趋势时间范围
      hazardMonths: 12,
      accidentMonths: 12,
      // 待办 / 预警
      todos: { list: [], total: 0 },
      warnings: { list: [], total: 0 },
      // 自动刷新
      refreshInterval: 300000,
      refreshOptions: [
        { label: '自动刷新：1分钟', value: 60000 },
        { label: '自动刷新：5分钟', value: 300000 },
        { label: '自动刷新：10分钟', value: 600000 },
        { label: '自动刷新：30分钟', value: 1800000 },
        { label: '关闭自动刷新', value: 0 }
      ],
      refreshTimer: null,
      refreshing: false,
      // 图表实例
      charts: {}
    }
  },
  computed: {
    // 六个指标卡配置
    statCards () {
      const o = this.overview
      const v = (key) => (o[key] || {}).value
      const t = (key) => (o[key] || {}).trend || 'flat'
      const tv = (key) => (o[key] || {}).trend_value || 0
      return [
        { key: 'safe_days', label: '安全运行天数', icon: 'el-icon-clock', color: '#67C23A', value: v('safe_days'), trend: t('safe_days'), trendValue: tv('safe_days') },
        { key: 'hazard_total', label: '隐患总数', icon: 'el-icon-warning', color: '#E6A23C', value: v('hazard_total'), trend: t('hazard_total'), trendValue: tv('hazard_total') },
        { key: 'hazard_rate', label: '整改率', icon: 'el-icon-circle-check', color: '#409EFF', value: v('hazard_rate'), suffix: '%', trend: t('hazard_rate'), trendValue: tv('hazard_rate') },
        { key: 'training_rate', label: '培训完成率', icon: 'el-icon-reading', color: '#67C23A', value: v('training_rate'), suffix: '%', trend: t('training_rate'), trendValue: tv('training_rate') },
        { key: 'accident_rate', label: '事故率(百万工时)', icon: 'el-icon-danger', color: '#F56C6C', value: v('accident_rate'), trend: t('accident_rate'), trendValue: tv('accident_rate') },
        { key: 'risk_total', label: '风险总数', icon: 'el-icon-s-flag', color: '#E6A23C', value: v('risk_total'), trend: t('risk_total'), trendValue: tv('risk_total') }
      ]
    }
  },
  mounted () {
    this.refreshAll()
    this.initCharts()
    window.addEventListener('resize', this.resizeCharts)
    this.restartAutoRefresh()
  },
  beforeDestroy () {
    window.removeEventListener('resize', this.resizeCharts)
    if (this.refreshTimer) clearInterval(this.refreshTimer)
    Object.values(this.charts).forEach(c => c && c.dispose())
    this.charts = {}
  },
  methods: {
    // ---------- 数据加载 ----------
    async refreshAll () {
      if (this.refreshing) return
      this.refreshing = true
      try {
        await Promise.all([
          this.loadOverview(),
          this.loadHazardTrend(),
          this.loadAccidentTrend(),
          this.loadHazardLevel(),
          this.loadRiskLevel(),
          this.loadTodos(),
          this.loadWarnings()
        ])
      } catch (e) {
        this.$message.error('看板数据加载失败')
      } finally {
        this.refreshing = false
      }
    },
    async loadOverview () {
      const r = await getDashboardOverview()
      if (r.code === 0) {
        this.overview = r.data || {}
        this.lastUpdate = (r.data && r.data.last_update) || ''
      }
    },
    async loadHazardTrend () {
      const r = await getHazardTrend(this.hazardMonths)
      if (r.code === 0) this.renderHazardTrend(r.data || {})
    },
    async loadAccidentTrend () {
      const r = await getAccidentTrend(this.accidentMonths)
      if (r.code === 0) this.renderAccidentTrend(r.data || {})
    },
    async loadHazardLevel () {
      const r = await getHazardLevel()
      if (r.code === 0) this.renderHazardLevel(r.data || {})
    },
    async loadRiskLevel () {
      const r = await getRiskLevel()
      if (r.code === 0) this.renderRiskLevel(r.data || {})
    },
    async loadTodos () {
      const r = await getDashboardTodos()
      if (r.code === 0) this.todos = r.data || { list: [], total: 0 }
    },
    async loadWarnings () {
      const r = await getUpcomingWarnings()
      if (r.code === 0) this.warnings = r.data || { list: [], total: 0 }
    },

    // ---------- 图表渲染 ----------
    initCharts () {
      ;['hazardTrend', 'accidentTrend', 'hazardLevel', 'riskLevel'].forEach(key => {
        if (this.$refs[key]) {
          this.charts[key] = echarts.init(this.$refs[key])
        }
      })
    },
    resizeCharts () {
      Object.values(this.charts).forEach(c => c && c.resize())
    },
    renderHazardTrend (data) {
      const chart = this.charts.hazardTrend
      if (!chart) return
      chart.setOption({
        tooltip: { trigger: 'axis' },
        legend: { data: ['发现隐患', '关闭隐患'], top: 0 },
        grid: { left: 40, right: 20, top: 36, bottom: 30 },
        xAxis: { type: 'category', data: data.months || [] },
        yAxis: { type: 'value', minInterval: 1 },
        series: [
          {
            name: '发现隐患', type: 'line', smooth: true, symbolSize: 6,
            data: data.found || [], color: '#E6A23C', lineStyle: { width: 2 },
            label: { show: true, position: 'top', fontSize: 10 }
          },
          {
            name: '关闭隐患', type: 'line', smooth: true, symbolSize: 6,
            data: data.closed || [], color: '#67C23A', lineStyle: { width: 2 },
            label: { show: true, position: 'top', fontSize: 10 }
          }
        ]
      }, true)
    },
    renderAccidentTrend (data) {
      const chart = this.charts.accidentTrend
      if (!chart) return
      chart.setOption({
        tooltip: { trigger: 'axis' },
        grid: { left: 40, right: 20, top: 30, bottom: 30 },
        xAxis: { type: 'category', data: data.months || [] },
        yAxis: { type: 'value', minInterval: 1 },
        series: [
          {
            name: '事故数量', type: 'bar', barWidth: '40%',
            data: data.counts || [],
            itemStyle: {
              color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
                { offset: 0, color: '#F56C6C' },
                { offset: 1, color: '#fadbd8' }
              ])
            },
            label: { show: true, position: 'top', fontSize: 10 }
          }
        ]
      }, true)
    },
    renderHazardLevel (data) {
      const chart = this.charts.hazardLevel
      if (!chart) return
      const colors = { '轻微': '#909399', '一般': '#409EFF', '严重': '#E6A23C', '紧急': '#F56C6C' }
      const list = (data.list || []).map(x => ({ ...x, itemStyle: { color: colors[x.name] || '#909399' } }))
      chart.setOption(this.pieOption(list, '隐患等级分布'), true)
    },
    renderRiskLevel (data) {
      const chart = this.charts.riskLevel
      if (!chart) return
      const colors = { '低风险': '#67C23A', '一般风险': '#409EFF', '较大风险': '#E6A23C', '重大风险': '#F56C6C' }
      const list = (data.list || []).map(x => ({ ...x, itemStyle: { color: colors[x.name] || '#909399' } }))
      chart.setOption(this.pieOption(list, '风险等级分布'), true)
    },
    pieOption (list, title) {
      return {
        tooltip: {
          trigger: 'item',
          formatter: '{b}：{c}（{d}%）'
        },
        legend: { orient: 'vertical', right: 10, top: 'middle' },
        series: [
          {
            name: title, type: 'pie', radius: '55%', center: ['40%', '50%'],
            label: { show: true, formatter: '{b}: {c}' },
            emphasis: { label: { show: true, fontSize: 14, fontWeight: 'bold' } },
            data: list
          }
        ]
      }
    },

    // ---------- 展示辅助 ----------
    displayValue (card) {
      if (card.value === null || card.value === undefined) return '—'
      if (card.suffix) return card.value + card.suffix
      return card.value
    },
    // 待办类型标签颜色（隐患橙/检查蓝/培训绿/考试紫/措施青）
    todoTagType (type) {
      return { hazard: 'warning', inspection: 'primary', training: 'success', exam: 'danger', measure: 'info' }[type] || 'info'
    },
    // 预警类型标签颜色
    warnTagType (type) {
      return { certificate: 'warning', device: 'primary', risk: 'danger' }[type] || 'info'
    },
    go (url) {
      if (url) this.$router.push(url)
    },
    goAllTodos () { this.go('/safety/hazard/handle') },
    goAllWarnings () { this.go('/safety/training/certificate') },

    // ---------- 自动刷新 ----------
    restartAutoRefresh () {
      if (this.refreshTimer) clearInterval(this.refreshTimer)
      if (this.refreshInterval > 0) {
        this.refreshTimer = setInterval(() => this.refreshAll(), this.refreshInterval)
      }
    }
  }
}
</script>

<style scoped>
.safety-dashboard { padding: 16px; background: #f0f2f5; min-height: 100%; }
.dash-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.dash-title h2 { margin: 0; font-size: 20px; color: #303133; }
.dash-sub { font-size: 12px; color: #909399; margin-left: 8px; }
.dash-actions { display: flex; align-items: center; }
.update-time { font-size: 12px; color: #909399; margin-right: 12px; }
.stat-row { margin-bottom: 16px; }
.stat-card { background: #fff; border-radius: 8px; border-top: 3px solid #409EFF; padding: 14px; display: flex; align-items: center; box-shadow: 0 1px 4px rgba(0,0,0,.04); }
.stat-icon { width: 44px; height: 44px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 22px; margin-right: 12px; flex-shrink: 0; }
.stat-value { font-size: 24px; font-weight: 700; line-height: 1.2; }
.stat-label { font-size: 12px; color: #909399; margin-top: 2px; }
.stat-trend { font-size: 11px; margin-top: 2px; }
.chart-row { margin-bottom: 16px; }
.panel { background: #fff; border-radius: 8px; padding: 12px 14px; box-shadow: 0 1px 4px rgba(0,0,0,.04); }
.panel-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.panel-title { font-size: 14px; font-weight: 600; color: #303133; }
.panel-count { font-size: 12px; color: #909399; }
.panel-more { text-align: center; font-size: 12px; color: #409EFF; cursor: pointer; padding-top: 8px; }
.chart-box { width: 100%; height: 300px; }
</style>
