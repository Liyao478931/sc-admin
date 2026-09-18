<template>
  <div class="maintenance-statistics-page">
    <!-- 概览统计卡片 -->
    <el-row :gutter="16" style="margin-bottom:16px;">
      <el-col :span="6" v-for="card in overviewCards" :key="card.key">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-icon" :style="{background: card.color + '1a', color: card.color}"><i :class="card.icon"></i></div>
          <div class="stat-info"><div class="stat-val" :style="{color: card.color}">{{ card.value }}</div><div class="stat-label">{{ card.label }}</div></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 第一行：完成率趋势 + 等级分布 -->
    <el-row :gutter="16" style="margin-bottom:16px;">
      <el-col :span="12">
        <el-card shadow="never" v-loading="loading.trend">
          <div class="chart-title">完成率趋势</div>
          <div ref="trendChart" class="chart-box"></div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card shadow="never" v-loading="loading.level">
          <div class="chart-title">保养等级分布</div>
          <div ref="levelChart" class="chart-box"></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 第二行：设备覆盖率 + 执行人排行 -->
    <el-row :gutter="16" style="margin-bottom:16px;">
      <el-col :span="12">
        <el-card shadow="never" v-loading="loading.coverage">
          <div class="chart-title">设备保养覆盖率</div>
          <div ref="coverageChart" class="chart-box"></div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card shadow="never" v-loading="loading.executor">
          <div class="chart-title">执行人排行（TOP{{ executorLimit }}）</div>
          <div ref="executorChart" class="chart-box"></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 第三行：故障率对比 + 成本统计 -->
    <el-row :gutter="16" style="margin-bottom:16px;">
      <el-col :span="12">
        <el-card shadow="never" v-loading="loading.failure">
          <div class="chart-title">设备故障率对比</div>
          <div ref="failureChart" class="chart-box"></div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card shadow="never" v-loading="loading.cost">
          <div class="chart-title">保养成本统计（单位：{{ costUnit }}）</div>
          <div ref="costChart" class="chart-box"></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 逾期未保养设备 -->
    <el-card shadow="never">
      <div class="card-header">
        <span>逾期未保养设备（{{ overdueTotal }} 台）</span>
        <div>
          <el-button v-if="hasPerm('device:maintenance:statistics:export')" size="small" icon="el-icon-download" @click="handleExport">导出</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadOverdue">刷新</el-button>
        </div>
      </div>
      <el-table :data="overdueList" v-loading="loading.overdue" stripe border size="small">
        <el-table-column type="index" label="#" width="60" />
        <el-table-column label="设备名称" min-width="150" show-overflow-tooltip>
          <template slot-scope="{row}"><el-link type="primary" @click="goDevice(row)">{{ row.device_name }}</el-link></template>
        </el-table-column>
        <el-table-column prop="device_code" label="设备编码" width="150" />
        <el-table-column prop="department_name" label="所属部门" min-width="120" />
        <el-table-column prop="level_name" label="保养等级" width="110" />
        <el-table-column prop="last_maintenance_date" label="上次保养日期" width="130" />
        <el-table-column label="逾期天数" width="100">
          <template slot-scope="{row}"><span :style="{color: row.overdue_days > 30 ? '#F56C6C' : '#E6A23C', fontWeight: row.overdue_days > 30 ? 600 : 'normal'}">{{ row.overdue_days }} 天</span></template>
        </el-table-column>
        <el-table-column label="操作" width="120" fixed="right">
          <template slot-scope="{row}"><el-button size="mini" type="text" @click="goDevice(row)">查看设备</el-button></template>
        </el-table-column>
      </el-table>
      <el-empty v-if="!loading.overdue && !overdueList.length" description="暂无逾期设备" :image-size="80" />
    </el-card>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import {
  getStatisticsOverview, getTrend, getLevelDistribution, getCoverage, getExecutorTop,
  getFailureRate, getCost, getOverdueDevices, exportOverdueDevices
} from '@/api/maintenanceStatistics'

export default {
  name: 'MaintenanceStatistics',
  data() {
    return {
      overviewCards: [
        { key: 'plan_total', label: '计划总数', icon: 'el-icon-document', color: '#409EFF', value: 0 },
        { key: 'today_pending', label: '今日待执行', icon: 'el-icon-time', color: '#E6A23C', value: 0 },
        { key: 'month_done', label: '本月已完成', icon: 'el-icon-circle-check', color: '#67C23A', value: 0 },
        { key: 'overdue', label: '逾期未执行', icon: 'el-icon-warning', color: '#F56C6C', value: 0 }
      ],
      costUnit: '元',
      executorLimit: 10,
      overdueList: [],
      overdueTotal: 0,
      loading: { trend: false, level: false, coverage: false, executor: false, failure: false, cost: false, overdue: false },
      charts: {}
    }
  },
  mounted() {
    this.initCharts()
    this.loadAll()
    window.addEventListener('resize', this.handleResize)
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.handleResize)
    Object.keys(this.charts).forEach(k => { if (this.charts[k]) this.charts[k].dispose() })
    this.charts = {}
  },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    initCharts() {
      const keys = ['trendChart', 'levelChart', 'coverageChart', 'executorChart', 'failureChart', 'costChart']
      keys.forEach(k => { if (this.$refs[k]) this.charts[k] = echarts.init(this.$refs[k]) })
    },
    handleResize() { Object.keys(this.charts).forEach(k => { if (this.charts[k]) this.charts[k].resize() }) },
    setLoading(key, val) { this.$set(this.loading, key, val) },
    loadAll() {
      this.loadOverview()
      this.loadTrend()
      this.loadLevelDistribution()
      this.loadCoverage()
      this.loadExecutorTop()
      this.loadFailureRate()
      this.loadCost()
      this.loadOverdue()
    },
    // ---------- 概览 ----------
    async loadOverview() {
      try { const r = await getStatisticsOverview(); if (r.code === 0) { const d = r.data
        this.overviewCards = [
          { key: 'plan_total', label: '计划总数', icon: 'el-icon-document', color: '#409EFF', value: d.plan_total },
          { key: 'today_pending', label: '今日待执行', icon: 'el-icon-time', color: '#E6A23C', value: d.today_pending },
          { key: 'month_done', label: '本月已完成', icon: 'el-icon-circle-check', color: '#67C23A', value: d.month_done },
          { key: 'overdue', label: '逾期未执行', icon: 'el-icon-warning', color: '#F56C6C', value: d.overdue }
        ]
      } } catch (e) {}
    },
    // ---------- 完成率趋势 ----------
    async loadTrend() {
      this.setLoading('trend', true)
      try {
        const r = await getTrend()
        if (r.code === 0 && this.charts.trendChart) {
          const d = r.data
          this.charts.trendChart.setOption({
            tooltip: { trigger: 'axis' },
            legend: { right: 0, top: 0 },
            grid: { left: 40, right: 20, top: 40, bottom: 30 },
            xAxis: { type: 'category', data: d.months || [] },
            yAxis: { type: 'value', max: 100, name: '%' },
            series: [{
              name: '完成率', type: 'line', smooth: true, data: d.rates || [],
              label: { show: true, formatter: '{c}%' }, itemStyle: { color: '#409EFF' }
            }]
          }, true)
        }
      } catch (e) {}
      this.setLoading('trend', false)
    },
    // ---------- 等级分布 ----------
    async loadLevelDistribution() {
      this.setLoading('level', true)
      try {
        const r = await getLevelDistribution()
        if (r.code === 0 && this.charts.levelChart) {
          const list = r.data.list || []
          const colorMap = { '日常保养': '#409EFF', '一级保养': '#67C23A', '二级保养': '#E6A23C', '三级保养': '#F56C6C' }
          this.charts.levelChart.setOption({
            tooltip: { trigger: 'item', formatter: '{b}: {c} 项（{d}%）' },
            legend: { orient: 'vertical', right: 0, top: 'center' },
            series: [{
              name: '保养等级分布', type: 'pie', radius: '55%', center: ['40%', '50%'],
              label: { formatter: '{b}\n{d}%' },
              data: list.map(x => ({ name: x.level_name, value: x.cnt, itemStyle: { color: colorMap[x.level_name] || '#909399' } }))
            }]
          }, true)
        }
      } catch (e) {}
      this.setLoading('level', false)
    },
    // ---------- 设备覆盖率 ----------
    async loadCoverage() {
      this.setLoading('coverage', true)
      try {
        const r = await getCoverage()
        if (r.code === 0 && this.charts.coverageChart) {
          const list = r.data.list || []
          this.charts.coverageChart.setOption({
            tooltip: { trigger: 'axis', formatter: (p) => { const i = p[0].dataIndex; const row = list[i]; return `${row.device_name}<br/>应保养 ${row.plan_count} 次 / 实际 ${row.actual_count} 次<br/>覆盖率 ${row.coverage}%` } },
            grid: { left: 40, right: 20, top: 40, bottom: 60 },
            xAxis: { type: 'category', data: list.map(x => x.device_name), axisLabel: { rotate: 30, interval: 0 } },
            yAxis: { type: 'value', max: 100, name: '%' },
            series: [{ name: '覆盖率', type: 'bar', data: list.map(x => x.coverage), barMaxWidth: 30,
              label: { show: true, formatter: '{c}%', position: 'top' }, itemStyle: { color: '#67C23A' } }]
          }, true)
        }
      } catch (e) {}
      this.setLoading('coverage', false)
    },
    // ---------- 执行人排行 ----------
    async loadExecutorTop() {
      this.setLoading('executor', true)
      try {
        const r = await getExecutorTop()
        if (r.code === 0 && this.charts.executorChart) {
          const list = r.data.list || []
          this.executorLimit = r.data.limit || 10
          this.charts.executorChart.setOption({
            tooltip: { trigger: 'axis' },
            grid: { left: 40, right: 20, top: 40, bottom: 50 },
            xAxis: { type: 'category', data: list.map(x => x.executor_name || '未分配'), axisLabel: { rotate: 20, interval: 0 } },
            yAxis: { type: 'value', minInterval: 1 },
            series: [{ name: '完成数量', type: 'bar', data: list.map(x => x.cnt), barMaxWidth: 30,
              label: { show: true, position: 'top' }, itemStyle: { color: '#E6A23C' } }]
          }, true)
        }
      } catch (e) {}
      this.setLoading('executor', false)
    },
    // ---------- 故障率对比 ----------
    async loadFailureRate() {
      this.setLoading('failure', true)
      try {
        const r = await getFailureRate()
        if (r.code === 0 && this.charts.failureChart) {
          const d = r.data
          this.charts.failureChart.setOption({
            tooltip: { trigger: 'axis' },
            legend: { right: 0, top: 0 },
            grid: { left: 40, right: 20, top: 40, bottom: 30 },
            xAxis: { type: 'category', data: d.months || [] },
            yAxis: { type: 'value', max: 100, name: '%' },
            series: [
              { name: '保养前故障率', type: 'line', smooth: true, data: d.pre || [], label: { show: true, formatter: '{c}%' }, itemStyle: { color: '#F56C6C' } },
              { name: '保养后故障率', type: 'line', smooth: true, data: d.post || [], label: { show: true, formatter: '{c}%' }, itemStyle: { color: '#67C23A' } }
            ]
          }, true)
        }
      } catch (e) {}
      this.setLoading('failure', false)
    },
    // ---------- 成本统计 ----------
    async loadCost() {
      this.setLoading('cost', true)
      try {
        const r = await getCost()
        if (r.code === 0 && this.charts.costChart) {
          const d = r.data
          this.costUnit = r.data.cost_unit || '元'
          this.charts.costChart.setOption({
            tooltip: { trigger: 'axis' },
            legend: { right: 0, top: 0 },
            grid: { left: 50, right: 20, top: 40, bottom: 30 },
            xAxis: { type: 'category', data: d.months || [] },
            yAxis: { type: 'value', name: '金额' },
            series: [
              { name: '耗材成本', type: 'bar', stack: 'cost', data: d.material || [], label: { show: true, position: 'inside' }, itemStyle: { color: '#409EFF' } },
              { name: '工时成本', type: 'bar', stack: 'cost', data: d.labor || [], label: { show: true, position: 'top' }, itemStyle: { color: '#E6A23C' } }
            ]
          }, true)
        }
      } catch (e) {}
      this.setLoading('cost', false)
    },
    // ---------- 逾期设备 ----------
    async loadOverdue() {
      this.setLoading('overdue', true)
      try {
        const r = await getOverdueDevices()
        if (r.code === 0) { this.overdueList = r.data.list || []; this.overdueTotal = r.data.total || 0 }
      } catch (e) {}
      this.setLoading('overdue', false)
    },
    async handleExport() {
      try {
        const r = await exportOverdueDevices()
        if (r.code === 0 && r.data.url) { window.open(r.data.url, '_blank'); this.$message.success('导出成功') }
      } catch (e) {}
    },
    goDevice(row) { this.$router.push(`/device/asset?device_code=${encodeURIComponent(row.device_code)}`) }
  }
}
</script>

<style scoped>
.maintenance-statistics-page { padding: 0; }
.stat-card { display: flex; align-items: center; border-radius: 8px; }
.stat-icon { width: 48px; height: 48px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 22px; margin-right: 12px; }
.stat-val { font-size: 24px; font-weight: 700; line-height: 1.2; }
.stat-label { color: #909399; font-size: 13px; }
.chart-title { font-size: 15px; font-weight: 600; margin-bottom: 8px; }
.chart-box { width: 100%; height: 320px; }
.card-header { display: flex; align-items: center; justify-content: space-between; }
</style>
