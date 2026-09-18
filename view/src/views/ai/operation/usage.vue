<!-- 文件：admin/src/views/ai/operation/usage.vue -->
<!-- 用量统计：筛选 / 统计卡片 / 趋势·Token·费用图表 / 排行 / 明细 -->
<template>
  <div class="usage-page">
    <!-- 筛选 -->
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item>
          <el-select v-model="filters.timeRange" placeholder="时间范围" clearable style="width:130px" @change="onTimeRangeChange">
            <el-option label="今日" value="today" />
            <el-option label="昨日" value="yesterday" />
            <el-option label="本周" value="week" />
            <el-option label="本月" value="month" />
            <el-option label="自定义" value="custom" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="filters.timeRange === 'custom'">
          <el-date-picker v-model="filters.dateRange" type="daterange" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期"
            value-format="yyyy-MM-dd" style="width:230px" @change="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.resource_type" placeholder="全部资源" clearable style="width:120px" @change="onSearch">
            <el-option label="对话" value="chat" />
            <el-option label="工具" value="tool" />
            <el-option label="工作流" value="workflow" />
            <el-option label="应用" value="app" />
            <el-option label="API" value="api" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilter">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 统计卡片（6 个） -->
    <el-row :gutter="12" class="stat-row">
      <el-col :span="4">
        <div class="stat-card">
          <div class="stat-icon" style="background:#409EFF1a;color:#409EFF;"><i class="el-icon-s-data"></i></div>
          <div class="stat-body"><div class="stat-value">{{ overview.total_calls || 0 }}</div><div class="stat-label">总调用次数</div></div>
        </div>
      </el-col>
      <el-col :span="4">
        <div class="stat-card">
          <div class="stat-icon" style="background:#8E44AD1a;color:#8E44AD;"><i class="el-icon-document"></i></div>
          <div class="stat-body"><div class="stat-value">{{ fmtM(overview.total_tokens) }}</div><div class="stat-label">Token总消耗(M)</div></div>
        </div>
      </el-col>
      <el-col :span="4">
        <div class="stat-card">
          <div class="stat-icon" style="background:#67C23A1a;color:#67C23A;"><i class="el-icon-money"></i></div>
          <div class="stat-body"><div class="stat-value">{{ overview.total_cost || 0 }}</div><div class="stat-label">总费用(元·估算)</div></div>
        </div>
      </el-col>
      <el-col :span="4">
        <div class="stat-card">
          <div class="stat-icon" style="background:#E6A23C1a;color:#E6A23C;"><i class="el-icon-user"></i></div>
          <div class="stat-body"><div class="stat-value">{{ overview.active_users || 0 }}</div><div class="stat-label">活跃用户数</div></div>
        </div>
      </el-col>
      <el-col :span="4">
        <div class="stat-card">
          <div class="stat-icon" style="background:#409EFF1a;color:#409EFF;"><i class="el-icon-date"></i></div>
          <div class="stat-body"><div class="stat-value">{{ overview.today_calls || 0 }}</div><div class="stat-label">今日调用</div></div>
        </div>
      </el-col>
      <el-col :span="4">
        <div class="stat-card">
          <div class="stat-icon" style="background:#409EFF1a;color:#409EFF;"><i class="el-icon-calendar"></i></div>
          <div class="stat-body"><div class="stat-value">{{ overview.month_calls || 0 }}</div><div class="stat-label">本月调用</div></div>
        </div>
      </el-col>
    </el-row>

    <!-- 图表区第一行：趋势 + Token分布 -->
    <el-row :gutter="12" class="chart-row">
      <el-col :span="14">
        <div class="chart-box">
          <div class="chart-head">
            <span class="chart-title">调用趋势</span>
            <el-select v-model="trendResource" size="mini" style="width:110px" @change="loadTrend">
              <el-option label="全部" value="" />
              <el-option label="对话" value="chat" />
              <el-option label="工具" value="tool" />
            </el-select>
          </div>
          <div ref="trendChart" class="chart" style="height:280px;"></div>
        </div>
      </el-col>
      <el-col :span="10">
        <div class="chart-box">
          <div class="chart-head">
            <span class="chart-title">Token消耗分布</span>
            <el-select v-model="tokenDim" size="mini" style="width:120px" @change="loadTokenDist">
              <el-option label="按资源类型" value="resource_type" />
              <el-option label="按模型" value="model" />
            </el-select>
          </div>
          <div ref="tokenChart" class="chart" style="height:280px;"></div>
        </div>
      </el-col>
    </el-row>

    <!-- 图表区第二行：费用趋势 + 费用分布 -->
    <el-row :gutter="12" class="chart-row">
      <el-col :span="14">
        <div class="chart-box">
          <div class="chart-head"><span class="chart-title">费用趋势（估算）</span></div>
          <div ref="costTrendChart" class="chart" style="height:260px;"></div>
        </div>
      </el-col>
      <el-col :span="10">
        <div class="chart-box">
          <div class="chart-head"><span class="chart-title">费用分布</span></div>
          <div ref="costDistChart" class="chart" style="height:260px;"></div>
        </div>
      </el-col>
    </el-row>

    <!-- 排行区（4 个） -->
    <el-row :gutter="12" class="chart-row">
      <el-col :span="6"><div class="chart-box"><div class="chart-head"><span class="chart-title">工具调用TOP10</span></div><div ref="rankTool" class="chart" style="height:240px;"></div></div></el-col>
      <el-col :span="6"><div class="chart-box"><div class="chart-head"><span class="chart-title">工作流运行TOP10</span></div><div ref="rankWf" class="chart" style="height:240px;"></div></div></el-col>
      <el-col :span="6"><div class="chart-box"><div class="chart-head"><span class="chart-title">应用调用TOP10</span></div><div ref="rankApp" class="chart" style="height:240px;"></div></div></el-col>
      <el-col :span="6"><div class="chart-box"><div class="chart-head"><span class="chart-title">用户使用TOP10</span></div><div ref="rankUser" class="chart" style="height:240px;"></div></div></el-col>
    </el-row>

    <!-- 明细 -->
    <el-card shadow="never" class="list-card">
      <div class="toolbar">
        <span class="chart-title">用量明细</span>
        <div>
          <el-button v-if="hasPerm('ai:operation:usage:export')" size="small" icon="el-icon-download" @click="doExport">导出</el-button>
          <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadAll">刷新</el-button>
        </div>
      </div>
      <el-table :data="detailList" v-loading="loading" size="small" stripe>
        <el-table-column prop="time" label="时间" width="160" />
        <el-table-column prop="resource_type" label="资源类型" width="90" align="center" />
        <el-table-column prop="resource_name" label="资源名称" min-width="120" show-overflow-tooltip />
        <el-table-column prop="model" label="模型" width="80" />
        <el-table-column prop="caller" label="调用人" width="100" show-overflow-tooltip />
        <el-table-column prop="calls" label="调用次数" width="90" align="center" />
        <el-table-column prop="input_tokens" label="输入Token" width="100" align="center" />
        <el-table-column prop="output_tokens" label="输出Token" width="100" align="center" />
        <el-table-column prop="total_tokens" label="总Token" width="100" align="center" />
        <el-table-column prop="cost" label="费用" width="80" align="center" />
      </el-table>
      <el-pagination class="pager" background layout="total, sizes, prev, pager, next" :total="detailTotal"
        :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50]"
        @size-change="s => { limit = s; page = 1; loadDetail() }"
        @current-change="p => { page = p; loadDetail() }" />
    </el-card>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getUsageOverview, getUsageTrend, getUsageTokenDist, getUsageRanking, getUsageCostAnalysis, getUsageDetail, exportUsageReport } from '@/api/aiUsage'

export default {
  name: 'AiUsageStats',
  data () {
    return {
      filters: { timeRange: 'month', dateRange: null, resource_type: '' },
      overview: {},
      trendResource: '', tokenDim: 'resource_type',
      charts: {},
      detailList: [], detailTotal: 0, page: 1, limit: 20, loading: false
    }
  },
  created () { this.loadAll() },
  methods: {
    hasPerm (code) {
      const u = this.$store.state.user.userInfo || {}
      const p = this.$store.state.user.permissions || []
      if (u.is_super_admin || p.indexOf('super_admin') > -1) return true
      return p.indexOf(code) > -1
    },
    dateParams () {
      const p = {}
      if (this.filters.timeRange === 'custom' && this.filters.dateRange && this.filters.dateRange.length === 2) {
        p.start_date = this.filters.dateRange[0]; p.end_date = this.filters.dateRange[1]
      } else {
        const now = new Date()
        const fmt = d => d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0')
        if (this.filters.timeRange === 'today') { p.start_date = fmt(now); p.end_date = fmt(now) }
        else if (this.filters.timeRange === 'yesterday') { const y = new Date(now.getTime() - 86400000); p.start_date = fmt(y); p.end_date = fmt(y) }
        else if (this.filters.timeRange === 'week') { const w = new Date(now); w.setDate(now.getDate() - (now.getDay() || 7) + 1); p.start_date = fmt(w); p.end_date = fmt(now) }
        else { p.start_date = fmt(new Date(now.getFullYear(), now.getMonth(), 1)); p.end_date = fmt(now) }
      }
      return p
    },
    onTimeRangeChange () { if (this.filters.timeRange !== 'custom') this.onSearch() },
    onSearch () { this.loadAll() },
    resetFilter () {
      this.filters = { timeRange: 'month', dateRange: null, resource_type: '' }
      this.page = 1
      this.loadAll()
    },
    async loadAll () {
      const dp = this.dateParams()
      this.loadOverview(dp)
      this.loadTrend(dp)
      this.loadTokenDist(dp)
      this.loadCost(dp)
      this.loadRank('tool', 'rankTool', dp)
      this.loadRank('workflow', 'rankWf', dp)
      this.loadRank('app', 'rankApp', dp)
      this.loadRank('user', 'rankUser', dp)
      this.loadDetail()
    },
    async loadOverview (dp) {
      try { const r = await getUsageOverview({ ...dp, resource_type: this.filters.resource_type }); if (r.code === 0) this.overview = r.data || {} } catch (e) {}
    },
    async loadTrend (dp = null) {
      dp = dp || this.dateParams()
      this.$nextTick(() => {
        if (!this.charts.trend) this.charts.trend = echarts.init(this.$refs.trendChart)
        getUsageTrend({ ...dp, resource_type: this.trendResource }).then(r => {
          if (r.code !== 0 || !this.charts.trend) return
          const list = r.data.list || []
          this.charts.trend.setOption({
            tooltip: { trigger: 'axis' },
            legend: { data: ['调用次数', 'Token'], top: 0 },
            grid: { left: 45, right: 60, top: 30, bottom: 30 },
            xAxis: { type: 'category', data: list.map(i => i.date), axisLabel: { fontSize: 10 } },
            yAxis: [{ type: 'value', name: '次数', minInterval: 1 }, { type: 'value', name: 'Token' }],
            series: [
              { name: '调用次数', type: 'bar', data: list.map(i => i.calls), itemStyle: { color: '#409EFF' } },
              { name: 'Token', type: 'line', yAxisIndex: 1, data: list.map(i => i.tokens), smooth: true, itemStyle: { color: '#8E44AD' } }
            ]
          })
        }).catch(() => {})
      })
    },
    async loadTokenDist (dp = null) {
      dp = dp || this.dateParams()
      this.$nextTick(() => {
        if (!this.charts.token) this.charts.token = echarts.init(this.$refs.tokenChart)
        getUsageTokenDist({ ...dp, dimension: this.tokenDim }).then(r => {
          if (r.code !== 0 || !this.charts.token) return
          const list = r.data.list || []
          this.charts.token.setOption({
            tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
            legend: { bottom: 0 },
            series: [{ type: 'pie', radius: ['35%', '65%'], center: ['50%', '45%'], data: list.map(i => ({ name: i.name, value: i.tokens })) }]
          })
        }).catch(() => {})
      })
    },
    async loadCost (dp) {
      this.$nextTick(() => {
        if (!this.charts.costTrend) this.charts.costTrend = echarts.init(this.$refs.costTrendChart)
        if (!this.charts.costDist) this.charts.costDist = echarts.init(this.$refs.costDistChart)
        getUsageCostAnalysis(dp).then(r => {
          if (r.code !== 0) return
          const trend = r.data.trend || []
          if (this.charts.costTrend) {
            this.charts.costTrend.setOption({
              tooltip: { trigger: 'axis' },
              grid: { left: 45, right: 20, top: 30, bottom: 30 },
              xAxis: { type: 'category', data: trend.map(i => i.date), axisLabel: { fontSize: 10 } },
              yAxis: { type: 'value', name: '元' },
              series: [{ type: 'line', smooth: true, data: trend.map(i => i.cost), areaStyle: { opacity: 0.12 }, itemStyle: { color: '#E6A23C' } }]
            })
          }
          if (this.charts.costDist) {
            this.charts.costDist.setOption({
              tooltip: { trigger: 'item', formatter: '{b}: ¥{c}' },
              legend: { bottom: 0 },
              series: [{
                type: 'pie', radius: ['35%', '65%'], center: ['50%', '45%'],
                data: [{ name: r.data.model_name || '对话模型', value: r.data.total_cost || 0 }]
              }]
            })
          }
        }).catch(() => {})
      })
    },
    async loadRank (type, ref, dp) {
      this.$nextTick(() => {
        if (!this.charts[ref]) this.charts[ref] = echarts.init(this.$refs[ref])
        getUsageRanking({ ...dp, type, limit: 10 }).then(r => {
          if (r.code !== 0 || !this.charts[ref]) return
          const list = r.data.list || []
          this.charts[ref].setOption({
            tooltip: { trigger: 'axis' },
            grid: { left: 20, right: 90, top: 15, bottom: 20 },
            xAxis: { type: 'value', minInterval: 1 },
            yAxis: { type: 'category', data: list.map(i => i.name).reverse(), axisLabel: { fontSize: 10 } },
            series: [{ type: 'bar', data: list.map(i => i.cnt).reverse(), itemStyle: { color: '#409EFF' }, barMaxWidth: 14 }]
          })
        }).catch(() => {})
      })
    },
    async loadDetail () {
      this.loading = true
      try {
        const r = await getUsageDetail({ ...this.dateParams(), resource_type: this.filters.resource_type, page: this.page, limit: this.limit })
        if (r.code === 0) { this.detailList = r.data.list || []; this.detailTotal = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    async doExport () {
      try {
        const resp = await exportUsageReport(this.dateParams())
        const blob = resp.data instanceof Blob ? resp.data : new Blob([resp.data])
        const url = window.URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = 'usage_report_' + new Date().toISOString().slice(0, 10).replace(/-/g, '') + '.csv'
        document.body.appendChild(a); a.click(); document.body.removeChild(a)
        window.URL.revokeObjectURL(url)
      } catch (e) {}
    },
    fmtM (n) { return n ? (n / 1000000).toFixed(2) : '0' }
  },
  beforeDestroy () {
    for (const k of Object.keys(this.charts)) {
      if (this.charts[k]) { this.charts[k].dispose(); this.charts[k] = null }
    }
  }
}
</script>

<style scoped>
.usage-page { padding: 16px; }
.filter-card { margin-bottom: 14px; }
.filter-card /deep/ .el-card__body { padding: 12px 16px 0; }
.stat-row { margin-bottom: 14px; }
.stat-card { display: flex; align-items: center; background: #fff; border-radius: 8px; padding: 12px; box-shadow: 0 1px 3px rgba(0,0,0,.05); }
.stat-icon { width: 40px; height: 40px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 20px; margin-right: 10px; }
.stat-value { font-size: 18px; font-weight: 700; color: #303133; line-height: 1.2; }
.stat-label { font-size: 12px; color: #909399; margin-top: 2px; }
.chart-row { margin-bottom: 14px; }
.chart-box { background: #fff; border-radius: 8px; padding: 10px; box-shadow: 0 1px 3px rgba(0,0,0,.05); }
.chart-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.chart-title { font-size: 13px; font-weight: 600; color: #303133; }
.list-card /deep/ .el-card__body { padding: 12px 16px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.pager { margin-top: 14px; text-align: right; }
</style>
