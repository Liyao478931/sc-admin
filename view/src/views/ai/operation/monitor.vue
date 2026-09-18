<template>
  <div class="ai-monitor-page">
    <el-tabs v-model="activeTab" type="border-card">
      <!-- ==================== Tab1 监控总览 ==================== -->
      <el-tab-pane label="监控总览" name="overview">
        <!-- 服务健康状态卡片 -->
        <div class="sec-title">服务健康状态</div>
        <el-row :gutter="16">
          <el-col v-for="s in services" :key="s.name" :span="4" style="margin-bottom: 12px;">
            <el-card shadow="never" :class="['svc-card', 'svc-' + s.status]">
              <div class="svc-name">{{ s.name }}</div>
              <el-tag size="mini" :type="statusType(s.status)">{{ statusText(s.status) }}</el-tag>
              <div class="svc-meta">响应：{{ s.rt ? s.rt + 'ms' : (s.status === 'normal' ? '空闲' : '--') }}</div>
              <div class="svc-meta">可用率：{{ s.availability !== null && s.availability !== undefined ? s.availability + '%' : '--' }}</div>
              <div class="svc-desc" :title="s.desc">{{ s.desc }}</div>
            </el-card>
          </el-col>
        </el-row>
        <div class="overall">整体状态：<b :style="{ color: overallColor }">{{ overall }}</b> <span class="check-time">检查时间：{{ checkTime }}</span></div>

        <!-- 核心指标卡片 -->
        <div class="sec-title">核心指标</div>
        <el-row :gutter="16">
          <el-col v-for="m in metricCards" :key="m.key" :span="3" style="margin-bottom: 12px;">
            <el-card shadow="never" class="metric-card">
              <div class="metric-label">{{ m.label }}</div>
              <div class="metric-value">{{ m.value }}<span class="metric-unit">{{ m.unit }}</span></div>
            </el-card>
          </el-col>
        </el-row>

        <!-- 趋势图 -->
        <div class="sec-title">
          指标趋势
          <div class="trend-tools">
            <el-select v-model="trendMetric" size="mini" style="width: 150px; margin-right: 10px;" @change="loadTrend">
              <el-option v-for="opt in metricOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
            </el-select>
            <el-radio-group v-model="trendRange" size="mini" @change="loadTrend">
              <el-radio-button label="1h">1小时</el-radio-button>
              <el-radio-button label="6h">6小时</el-radio-button>
              <el-radio-button label="24h">24小时</el-radio-button>
              <el-radio-button label="7d">7天</el-radio-button>
            </el-radio-group>
          </div>
        </div>
        <div ref="trendChart" class="trend-chart"></div>
      </el-tab-pane>

      <!-- ==================== Tab2 告警规则 ==================== -->
      <el-tab-pane label="告警规则" name="rules">
        <div class="filter-bar">
          <el-select v-model="ruleFilter.metric" placeholder="指标筛选" clearable size="small" style="width: 150px;" @change="p => { rulePage = 1; loadRules() }">
            <el-option v-for="(v, k) in metricMap" :key="k" :label="v" :value="k" />
          </el-select>
          <el-select v-model="ruleFilter.status" placeholder="状态筛选" clearable size="small" style="width: 130px; margin-left: 10px;" @change="p => { rulePage = 1; loadRules() }">
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
          </el-select>
          <el-input v-model="ruleFilter.keyword" placeholder="规则名称搜索" size="small" clearable style="width: 180px; margin-left: 10px;" @keyup.enter.native="p => { rulePage = 1; loadRules() }" @clear="p => { rulePage = 1; loadRules() }" />
          <span class="flex-1"></span>
          <el-button size="small" type="primary" icon="el-icon-plus" @click="$refs.ruleDialog.open()">新增规则</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadRules">刷新</el-button>
        </div>

        <el-table :data="ruleList" size="small" stripe v-loading="ruleLoading">
          <el-table-column prop="rule_name" label="规则名称" min-width="140" show-overflow-tooltip />
          <el-table-column prop="metric_text" label="监控指标" width="110" />
          <el-table-column label="告警条件" width="130">
            <template slot-scope="s">{{ s.row.metric_text }} {{ s.row.operator }} {{ s.row.threshold }}</template>
          </el-table-column>
          <el-table-column prop="duration" label="持续(分)" width="80" />
          <el-table-column label="告警级别" width="90">
            <template slot-scope="s">
              <el-tag size="mini" :type="levelType(s.row.level)">{{ s.row.level_text }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="通知渠道" width="160">
            <template slot-scope="s">
              <el-tag v-for="c in s.row.channels" :key="c" size="mini" class="ch-tag">{{ channelText(c) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="状态" width="80">
            <template slot-scope="s">
              <el-tag size="mini" :type="s.row.status === 1 ? 'success' : 'info'">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="170" align="center">
            <template slot-scope="s">
              <el-button type="text" size="mini" @click="$refs.ruleDialog.open(s.row)">编辑</el-button>
              <el-button type="text" size="mini" @click="toggleRule(s.row)">{{ s.row.status === 1 ? '停用' : '启用' }}</el-button>
              <el-button type="text" size="mini" class="danger" @click="deleteRule(s.row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
        <el-pagination class="pager" small background layout="total, prev, pager, next" :total="ruleTotal" :page-size="rulePageSize" :current-page="rulePage" @current-change="p => { rulePage = p; loadRules() }" />
      </el-tab-pane>

      <!-- ==================== Tab3 告警历史 ==================== -->
      <el-tab-pane label="告警历史" name="history">
        <!-- 统计卡片 -->
        <el-row :gutter="16" class="stat-row">
          <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num">{{ histStats.total || 0 }}</div><div class="stat-label">总告警</div></el-card></el-col>
          <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num danger">{{ histStats.triggered || 0 }}</div><div class="stat-label">触发中</div></el-card></el-col>
          <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num warning">{{ histStats.confirmed || 0 }}</div><div class="stat-label">已确认</div></el-card></el-col>
          <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num success">{{ histStats.recovered || 0 }}</div><div class="stat-label">已恢复</div></el-card></el-col>
        </el-row>

        <div class="filter-bar">
          <el-select v-model="histFilter.level" placeholder="级别筛选" clearable size="small" style="width: 130px;" @change="p => { histPage = 1; loadHistory() }">
            <el-option v-for="opt in levelOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
          <el-select v-model="histFilter.status" placeholder="状态筛选" clearable size="small" style="width: 130px; margin-left: 10px;" @change="p => { histPage = 1; loadHistory() }">
            <el-option v-for="opt in statusOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
          <el-date-picker v-model="histDateRange" type="daterange" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" value-format="yyyy-MM-dd" size="small" style="margin-left: 10px;" @change="p => { histPage = 1; loadHistory() }" />
          <span class="flex-1"></span>
          <el-button size="small" icon="el-icon-refresh" @click="loadHistory">刷新</el-button>
        </div>

        <el-table :data="histList" size="small" stripe v-loading="histLoading">
          <el-table-column prop="rule_name" label="告警名称" min-width="150" show-overflow-tooltip />
          <el-table-column prop="metric_text" label="监控指标" width="110" />
          <el-table-column label="告警级别" width="90">
            <template slot-scope="s">
              <el-tag size="mini" :type="levelType(s.row.level)">{{ s.row.level_text }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="trigger_time" label="触发时间" width="165" />
          <el-table-column prop="recover_time" label="恢复时间" width="165">
            <template slot-scope="s">{{ s.row.recover_time || '--' }}</template>
          </el-table-column>
          <el-table-column label="状态" width="90">
            <template slot-scope="s">
              <el-tag size="mini" :type="statusType2(s.row.status)">{{ s.row.status_text }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="130" align="center">
            <template slot-scope="s">
              <el-button type="text" size="mini" @click="$refs.detailDialog.open(s.row.id)">查看详情</el-button>
              <el-button v-if="s.row.status === 'triggered'" type="text" size="mini" @click="confirmAlert(s.row)">确认</el-button>
            </template>
          </el-table-column>
        </el-table>
        <el-pagination class="pager" small background layout="total, prev, pager, next" :total="histTotal" :page-size="histPageSize" :current-page="histPage" @current-change="p => { histPage = p; loadHistory() }" />
      </el-tab-pane>
    </el-tabs>

    <!-- 弹窗 -->
    <AlertRuleDialog ref="ruleDialog" @saved="loadRules" />
    <AlertHistoryDetailDialog ref="detailDialog" />
  </div>
</template>

<script>
import * as echarts from 'echarts'
import {
  getMonitorHealth, getMonitorMetrics, getMonitorTrend,
  getAlertRules, deleteAlertRule, updateAlertRuleStatus,
  getAlertHistory, confirmAlertHistory, getAlertHistoryStatistics
} from '../../../api/aiMonitor'
import AlertRuleDialog from './components/AlertRuleDialog.vue'
import AlertHistoryDetailDialog from './components/AlertHistoryDetailDialog.vue'

export default {
  name: 'AiOperationMonitor',
  components: { AlertRuleDialog, AlertHistoryDetailDialog },
  data() {
    return {
      activeTab: this.$route.query.tab || 'overview',
      // 健康状态
      services: [], overall: '--', checkTime: '', overallColor: '#909399',
      // 指标
      metrics: {},
      // 趋势
      trendMetric: 'call_count', trendRange: '7d', trendChart: null, trendData: [],
      // 规则
      ruleLoading: false, ruleList: [], ruleTotal: 0, rulePage: 1, rulePageSize: 20,
      ruleFilter: { metric: '', status: '', keyword: '' },
      // 历史
      histLoading: false, histList: [], histTotal: 0, histPage: 1, histPageSize: 20,
      histFilter: { level: '', status: '' }, histDateRange: [], histStats: {},
      metricMap: {
        error_rate: '错误率', response_time: '响应时间', call_count: '调用次数',
        token_consumption: 'Token消耗', service_availability: '服务可用性',
        cpu_usage: 'CPU使用率', memory_usage: '内存使用率'
      },
      levelMap: { info: '提示', warning: '一般', critical: '重要', emergency: '紧急' },
      metricOptions: [], statusOptions: [], levelOptions: []
    }
  },
  computed: {
    metricCards() {
      const m = this.metrics || {}
      return [
        { key: 'total_calls', label: '7天请求总数', value: m.total_calls ?? 0, unit: '次' },
        { key: 'total_errors', label: '7天错误数', value: m.total_errors ?? 0, unit: '次' },
        { key: 'error_rate', label: '错误率', value: m.error_rate ?? 0, unit: '%' },
        { key: 'avg_response_time', label: '平均响应时间', value: m.avg_response_time ?? 0, unit: 'ms' },
        { key: 'p95_response_time', label: 'P95响应时间', value: m.p95_response_time ?? 0, unit: 'ms' },
        { key: 'token_rate', label: 'Token消耗速率', value: m.token_rate ?? 0, unit: '/s' },
        { key: 'availability', label: '服务可用率', value: m.availability ?? 100, unit: '%' }
      ]
    }
  },
  created() {
    this.loadHealth()
    this.loadMetrics()
    this.loadTrend()
    this.loadRules()
    this.loadHistory()
    this.loadHistoryStats()
    this.loadDicts()
    // 每30秒轮询健康状态与指标
    this.timer = setInterval(() => { this.loadHealth(); this.loadMetrics() }, 30000)
  },
  mounted() {
    this.$nextTick(() => this.initTrendChart())
  },
  beforeDestroy() {
    if (this.timer) clearInterval(this.timer)
    if (this.trendChart) { this.trendChart.dispose(); this.trendChart = null }
  },
  methods: {
    // 指标/级别/状态从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../api/dictionary')
      try { const r = await getDictByCode('alert_metric'); this.metricOptions = r.data || [] } catch (e) { this.metricOptions = [] }
      try { const r = await getDictByCode('alert_level'); this.levelOptions = r.data || [] } catch (e) { this.levelOptions = [] }
      try { const r = await getDictByCode('alert_status'); this.statusOptions = r.data || [] } catch (e) { this.statusOptions = [] }
    },
    // ===== 监控总览 =====
    async loadHealth() {
      try {
        const res = await getMonitorHealth()
        const d = res.data || {}
        this.services = d.services || []
        this.overall = d.overall || '--'
        this.checkTime = d.check_time || ''
        this.overallColor = { '全部正常': '#67c23a', '部分异常': '#e6a23c', '严重异常': '#f56c6c' }[d.overall] || '#909399'
      } catch (e) {}
    },
    async loadMetrics() {
      try { this.metrics = (await getMonitorMetrics()).data || {} } catch (e) {}
    },
    async loadTrend() {
      try {
        const res = await getMonitorTrend({ metric: this.trendMetric, range: this.trendRange })
        this.trendData = (res.data && res.data.list) || []
        this.renderTrend()
      } catch (e) {}
    },
    initTrendChart() {
      if (!this.$refs.trendChart) return
      this.trendChart = echarts.init(this.$refs.trendChart)
      this.renderTrend()
    },
    renderTrend() {
      if (!this.trendChart) return
      const times = this.trendData.map(d => d.time)
      const values = this.trendData.map(d => d.value)
      this.trendChart.setOption({
        tooltip: { trigger: 'axis' },
        grid: { left: 60, right: 20, top: 30, bottom: 40 },
        xAxis: { type: 'category', data: times, boundaryGap: false, axisLabel: { fontSize: 10 } },
        yAxis: { type: 'value' },
        series: [{
          name: this.metricMap[this.trendMetric] || this.trendMetric,
          type: 'line', smooth: true, data: values,
          areaStyle: { opacity: 0.15 }, itemStyle: { color: '#409eff' }
        }]
      })
    },
    // ===== 告警规则 =====
    async loadRules() {
      this.ruleLoading = true
      try {
        const params = { page: this.rulePage, limit: this.rulePageSize }
        if (this.ruleFilter.metric) params.metric = this.ruleFilter.metric
        if (this.ruleFilter.status !== '') params.status = this.ruleFilter.status
        if (this.ruleFilter.keyword) params.keyword = this.ruleFilter.keyword
        const res = await getAlertRules(params)
        this.ruleList = res.data.list || []
        this.ruleTotal = res.data.total || 0
      } catch (e) {}
      this.ruleLoading = false
    },
    toggleRule(row) {
      const newStatus = row.status === 1 ? 0 : 1
      updateAlertRuleStatus(row.id, newStatus).then(res => {
        this.$message.success(res.msg || '操作成功')
        this.loadRules()
      }).catch(() => {})
    },
    deleteRule(row) {
      this.$confirm(`确定删除告警规则「${row.rule_name}」？`, '提示', { type: 'warning' }).then(async () => {
        try { await deleteAlertRule(row.id); this.$message.success('已删除'); this.loadRules() } catch (e) {}
      }).catch(() => {})
    },
    // ===== 告警历史 =====
    async loadHistory() {
      this.histLoading = true
      try {
        const params = { page: this.histPage, limit: this.histPageSize }
        if (this.histFilter.level) params.level = this.histFilter.level
        if (this.histFilter.status) params.status = this.histFilter.status
        if (this.histDateRange && this.histDateRange.length === 2) {
          params.start_date = this.histDateRange[0]
          params.end_date = this.histDateRange[1]
        }
        const res = await getAlertHistory(params)
        this.histList = res.data.list || []
        this.histTotal = res.data.total || 0
      } catch (e) {}
      this.histLoading = false
    },
    async loadHistoryStats() {
      try { this.histStats = (await getAlertHistoryStatistics()).data || {} } catch (e) {}
    },
    confirmAlert(row) {
      this.$confirm(`确定确认告警「${row.rule_name}」？`, '提示', { type: 'warning' }).then(async () => {
        try { await confirmAlertHistory(row.id); this.$message.success('已确认'); this.loadHistory(); this.loadHistoryStats() } catch (e) {}
      }).catch(() => {})
    },
    // ===== 辅助 =====
    statusType(s) { return { normal: 'success', error: 'danger', unknown: 'info' }[s] || 'info' },
    statusText(s) { return { normal: '正常', error: '异常', unknown: '未知' }[s] || s },
    levelType(lv) { return { info: 'primary', warning: 'success', critical: 'warning', emergency: 'danger' }[lv] || 'info' },
    statusType2(st) { return { triggered: 'danger', confirmed: 'warning', recovered: 'success' }[st] || 'info' },
    channelText(c) { return { inbox: '站内信', email: '邮件', dingtalk: '钉钉', workwx: '企微' }[c] || c }
  }
}
</script>

<style scoped>
.ai-monitor-page { padding: 4px 16px; }
.sec-title { font-weight: 600; margin: 14px 0 10px; display: flex; align-items: center; }
.trend-tools { margin-left: auto; display: flex; align-items: center; }
.svc-card { text-align: center; }
.svc-card.svc-normal { border-top: 3px solid #67c23a; }
.svc-card.svc-error { border-top: 3px solid #f56c6c; }
.svc-card.svc-unknown { border-top: 3px solid #909399; }
.svc-name { font-weight: 600; margin-bottom: 6px; }
.svc-meta { color: #606266; font-size: 12px; margin-top: 6px; }
.svc-desc { color: #909399; font-size: 12px; margin-top: 4px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.overall { margin: 8px 0 4px; color: #606266; font-size: 14px; }
.check-time { color: #c0c4cc; font-size: 12px; margin-left: 10px; }
.metric-card { text-align: center; }
.metric-label { color: #909399; font-size: 12px; }
.metric-value { font-size: 22px; font-weight: 700; color: #303133; margin-top: 4px; }
.metric-unit { font-size: 12px; color: #909399; margin-left: 2px; font-weight: 400; }
.trend-chart { width: 100%; height: 320px; }
.filter-bar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.pager { margin-top: 10px; text-align: right; }
.ch-tag { margin-right: 4px; }
.stat-row { margin-bottom: 14px; }
.stat-card { text-align: center; }
.stat-num { font-size: 26px; font-weight: 700; color: #303133; }
.stat-num.danger { color: #f56c6c; }
.stat-num.warning { color: #e6a23c; }
.stat-num.success { color: #67c23a; }
.stat-label { color: #909399; font-size: 12px; margin-top: 2px; }
</style>
