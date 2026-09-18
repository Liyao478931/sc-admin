<template>
  <div class="ai-dashboard-page">
    <!-- ===== 时间筛选栏 ===== -->
    <div class="filter-bar">
      <el-radio-group v-model="range" size="small" @change="onRangeChange">
        <el-radio-button label="today">今日</el-radio-button>
        <el-radio-button label="week">本周</el-radio-button>
        <el-radio-button label="month">本月</el-radio-button>
      </el-radio-group>
      <el-switch v-model="autoRefresh" active-text="自动刷新(30s)" inactive-text="" style="margin-left:16px;" />
      <span class="flex-1"></span>
      <span class="update-time">最后更新：{{ checkTime || '--' }}</span>
      <el-button size="small" icon="el-icon-refresh" :loading="loading" style="margin-left:10px;" @click="refreshAll">刷新</el-button>
    </div>

    <!-- ===== 核心指标卡片 ===== -->
    <el-row :gutter="14" class="metrics-row">
      <el-col v-for="m in metrics" :key="m.key" :span="4">
        <el-card shadow="never" class="metric-card" @click.native="goLink(m.link)">
          <div class="metric-label">{{ m.label }}</div>
          <div class="metric-value">{{ formatValue(m) }}</div>
          <div class="metric-trend" :class="trendClass(m.trend)">
            <i :class="trendIcon(m.trend)"></i>{{ Math.abs(m.trend) }}%
            <span class="trend-text">较上期</span>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- ===== 趋势分析 ===== -->
    <el-card shadow="never" class="section-card">
      <div slot="header" class="sec-head">
        <span>趋势分析</span>
        <div class="sec-tools">
          <el-select v-model="trendMetric" size="mini" style="width:140px;" @change="loadTrend">
            <el-option label="对话次数" value="chat" />
            <el-option label="工具调用次数" value="tool" />
            <el-option label="Token消耗" value="token" />
          </el-select>
        </div>
      </div>
      <div ref="trendChart" class="chart-box"></div>
    </el-card>

    <!-- ===== 资源分布 ===== -->
    <el-row :gutter="14" class="rank-row">
      <el-col :span="8">
        <el-card shadow="never" class="section-card">
          <div slot="header">工具调用排行 TOP10</div>
          <div ref="toolRankChart" class="chart-box-sm"></div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="never" class="section-card">
          <div slot="header">智能体使用排行 TOP10</div>
          <div ref="agentRankChart" class="chart-box-sm"></div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="never" class="section-card">
          <div slot="header">应用调用排行 TOP10</div>
          <div ref="appRankChart" class="chart-box-sm"></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- ===== 实时动态 ===== -->
    <el-row :gutter="14" class="recent-row">
      <el-col :span="8">
        <el-card shadow="never" class="section-card">
          <div slot="header">最近对话</div>
          <el-table :data="recent.chats || []" size="mini" :show-header="false">
            <el-table-column label="内容" min-width="200">
              <template slot-scope="s">
                <div class="recent-title">{{ s.row.summary || '(空)' }}</div>
                <div class="recent-meta">{{ s.row.user_name }} · {{ s.row.agent_name || '通用' }} · {{ s.row.create_time }}</div>
              </template>
            </el-table-column>
          </el-table>
          <el-empty v-if="!(recent.chats || []).length" description="暂无对话" :image-size="50" />
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="never" class="section-card">
          <div slot="header">最近工具调用</div>
          <el-table :data="recent.tools || []" size="mini" :show-header="false">
            <el-table-column label="工具" min-width="200">
              <template slot-scope="s">
                <div class="recent-title">{{ s.row.tool_display_name || s.row.tool_name }}</div>
                <div class="recent-meta">{{ s.row.user_name || '-' }} · <el-tag size="mini" :type="s.row.status === 'success' ? 'success' : 'danger'">{{ s.row.status }}</el-tag> · {{ s.row.create_time }}</div>
              </template>
            </el-table-column>
          </el-table>
          <el-empty v-if="!(recent.tools || []).length" description="暂无工具调用" :image-size="50" />
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="never" class="section-card">
          <div slot="header">最新告警</div>
          <el-table :data="recent.alerts || []" size="mini" :show-header="false">
            <el-table-column label="告警" min-width="200">
              <template slot-scope="s">
                <div class="recent-title">{{ s.row.rule_name }}</div>
                <div class="recent-meta">
                  <el-tag size="mini" :type="alertLevelType(s.row.level)">{{ s.row.level_text }}</el-tag>
                  <el-tag size="mini" type="danger" style="margin-left:4px;">{{ s.row.status_text }}</el-tag>
                  <span style="margin-left:4px;">{{ s.row.trigger_time }}</span>
                </div>
              </template>
            </el-table-column>
          </el-table>
          <el-empty v-if="!(recent.alerts || []).length" description="暂无告警" :image-size="50" />
        </el-card>
      </el-col>
    </el-row>

    <!-- ===== 系统状态 ===== -->
    <el-card shadow="never" class="section-card">
      <div slot="header">系统状态</div>
      <div class="status-list">
        <div v-for="s in statusList" :key="s.name" class="status-item">
          <span class="status-dot" :class="'dot-' + s.status"></span>
          <span class="status-name">{{ s.name }}</span>
          <span v-if="s.rt" class="status-rt">{{ s.rt }}ms</span>
          <span class="status-desc">{{ s.desc }}</span>
        </div>
      </div>
    </el-card>

    <!-- ===== 快捷操作 ===== -->
    <el-card shadow="never" class="section-card">
      <div slot="header">快捷操作</div>
      <div class="quick-actions">
        <div v-for="a in quickActions" :key="a.key" class="quick-item" @click="goLink(a.path)">
          <i :class="a.icon"></i><span>{{ a.label }}</span>
        </div>
      </div>
    </el-card>

    <!-- 悬浮聊天入口已全局挂载于 App.vue（所有页面显示） -->
  </div>
</template>

<script>
import * as echarts from 'echarts'
import {
  getDashboardMetrics, getDashboardTrend, getDashboardRanking,
  getDashboardRecent, getDashboardStatus, getDashboardQuickActions
} from '../../../api/aiDashboard'

export default {
  name: 'AiDashboard',
  data() {
    return {
      range: 'week',
      trendMetric: 'chat',
      autoRefresh: true,
      loading: false,
      checkTime: '',
      metrics: [],
      trendData: [],
      recent: { chats: [], tools: [], alerts: [] },
      statusList: [],
      quickActions: [],
      charts: {},
      timer: null
    }
  },
  created() {
    // 恢复 localStorage 时间偏好
    const savedRange = localStorage.getItem('ai_dashboard_range')
    if (savedRange) this.range = savedRange
    this.refreshAll()
    this.timer = setInterval(() => { if (this.autoRefresh) this.refreshAll() }, 30000)
  },
  mounted() {
    this.$nextTick(() => this.initCharts())
  },
  beforeDestroy() {
    if (this.timer) clearInterval(this.timer)
    Object.values(this.charts).forEach(c => { if (c) c.dispose() })
    this.charts = {}
  },
  methods: {
    onRangeChange() {
      localStorage.setItem('ai_dashboard_range', this.range)
      this.refreshAll()
    },
    async refreshAll() {
      this.loading = true
      await Promise.all([this.loadMetrics(), this.loadTrend(), this.loadRankings(), this.loadRecent(), this.loadStatus(), this.loadQuickActions()])
      this.checkTime = new Date().toLocaleTimeString('zh-CN', { hour12: false })
      this.loading = false
    },
    async loadMetrics() {
      try {
        const res = await getDashboardMetrics({ range: this.range })
        const d = res.data || {}
        this.metrics = d.metrics || []
        this.checkTime = d.check_time || this.checkTime
      } catch (e) {}
    },
    async loadTrend() {
      try {
        // 后端 trend 支持 day/week/month；前端 today 映射为 day
        const trendRange = this.range === 'today' ? 'day' : this.range
        const res = await getDashboardTrend({ range: trendRange, metric: this.trendMetric })
        this.trendData = (res.data && res.data.list) || []
        this.renderTrend()
      } catch (e) {}
    },
    async loadRankings() {
      try {
        const [tool, agent, app] = await Promise.all([
          getDashboardRanking({ type: 'tool', limit: 10 }),
          getDashboardRanking({ type: 'agent', limit: 10 }),
          getDashboardRanking({ type: 'app', limit: 10 })
        ])
        this.renderRank('toolRankChart', (tool.data && tool.data.list) || [])
        this.renderRank('agentRankChart', (agent.data && agent.data.list) || [])
        this.renderRank('appRankChart', (app.data && app.data.list) || [])
      } catch (e) {}
    },
    async loadRecent() {
      try { this.recent = (await getDashboardRecent({ limit: 10 })).data || { chats: [], tools: [], alerts: [] } } catch (e) {}
    },
    async loadStatus() {
      try {
        const res = await getDashboardStatus()
        this.statusList = (res.data && res.data.services) || []
      } catch (e) {}
    },
    async loadQuickActions() {
      try {
        const res = await getDashboardQuickActions()
        const d = res.data || {}
        this.quickActions = d.quick_actions || []
      } catch (e) {}
    },
    initCharts() {
      ['trendChart', 'toolRankChart', 'agentRankChart', 'appRankChart'].forEach(k => {
        if (this.$refs[k]) this.charts[k] = echarts.init(this.$refs[k])
      })
      this.renderTrend()
      this.loadRankings()
    },
    renderTrend() {
      if (!this.charts.trendChart) return
      const times = this.trendData.map(d => d.time)
      const values = this.trendData.map(d => d.value)
      this.charts.trendChart.setOption({
        tooltip: { trigger: 'axis' },
        grid: { left: 60, right: 20, top: 30, bottom: 40 },
        xAxis: { type: 'category', data: times, boundaryGap: false, axisLabel: { fontSize: 10 } },
        yAxis: { type: 'value' },
        series: [{
          name: { chat: '对话次数', tool: '工具调用', token: 'Token消耗' }[this.trendMetric],
          type: 'line', smooth: true, data: values, areaStyle: { opacity: 0.15 }
        }]
      })
    },
    renderRank(ref, list) {
      const chart = this.charts[ref]
      if (!chart) return
      const names = list.map(r => r.name || '-')
      const counts = list.map(r => r.cnt || 0)
      chart.setOption({
        tooltip: { trigger: 'axis' },
        grid: { left: 80, right: 20, top: 20, bottom: 40 },
        xAxis: { type: 'value' },
        yAxis: { type: 'category', data: names.reverse(), axisLabel: { fontSize: 10, width: 70, overflow: 'truncate' } },
        series: [{ type: 'bar', data: counts.reverse(), itemStyle: { color: '#409eff' } }]
      })
    },
    formatValue(m) {
      if (m.key === 'cost') return '¥' + (m.value ?? 0)
      return (m.value ?? 0).toLocaleString()
    },
    trendClass(t) {
      if (t > 0) return 'trend-up'
      if (t < 0) return 'trend-down'
      return 'trend-flat'
    },
    trendIcon(t) {
      if (t > 0) return 'el-icon-top'
      if (t < 0) return 'el-icon-bottom'
      return 'el-icon-minus'
    },
    alertLevelType(lv) { return { info: 'primary', warning: 'success', critical: 'warning', emergency: 'danger' }[lv] || 'info' },
    goLink(path) {
      if (path) this.$router.push(path)
    }
  }
}
</script>

<style scoped>
.ai-dashboard-page { padding: 4px 16px; }
.filter-bar { display: flex; align-items: center; margin-bottom: 14px; }
.update-time { color: #909399; font-size: 12px; }
.metrics-row { margin-bottom: 14px; }
.metric-card { text-align: center; cursor: pointer; }
.metric-card:hover { border-color: #409eff; }
.metric-label { color: #909399; font-size: 12px; }
.metric-value { font-size: 22px; font-weight: 700; color: #303133; margin-top: 4px; }
.metric-trend { font-size: 12px; margin-top: 4px; }
.trend-up { color: #f56c6c; }
.trend-down { color: #67c23a; }
.trend-flat { color: #909399; }
.trend-text { color: #c0c4cc; margin-left: 2px; }
.section-card { margin-bottom: 14px; }
.sec-head { display: flex; align-items: center; justify-content: space-between; }
.chart-box { height: 280px; }
.chart-box-sm { height: 220px; }
.rank-row, .recent-row { margin-bottom: 0; }
.recent-title { font-size: 12px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.recent-meta { color: #909399; font-size: 11px; margin-top: 2px; }
.status-list { display: flex; flex-wrap: wrap; gap: 12px; }
.status-item { display: flex; align-items: center; gap: 8px; padding: 6px 12px; border: 1px solid #ebeef5; border-radius: 4px; }
.status-dot { width: 8px; height: 8px; border-radius: 50%; }
.dot-normal { background: #67c23a; }
.dot-error { background: #f56c6c; }
.dot-unknown { background: #909399; }
.status-name { font-weight: 600; font-size: 13px; }
.status-rt { color: #409eff; font-size: 12px; }
.status-desc { color: #909399; font-size: 12px; }
.quick-actions { display: flex; gap: 12px; flex-wrap: wrap; }
.quick-item { display: flex; align-items: center; gap: 6px; padding: 8px 16px; border: 1px solid #ebeef5; border-radius: 4px; cursor: pointer; color: #606266; }
.quick-item:hover { border-color: #409eff; color: #409eff; }
.quick-item i { font-size: 16px; }
</style>
