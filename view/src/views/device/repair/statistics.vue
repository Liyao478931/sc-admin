<template>
  <div class="repair-statistics-page">
    <!-- 概览统计卡片 -->
    <el-row :gutter="16" style="margin-bottom:16px;">
      <el-col :span="4" v-for="card in overviewCards" :key="card.key">
        <el-card shadow="hover" class="stat-card" :body-style="{padding:'16px'}" @click.native="goOrderList(card)">
          <div class="stat-icon" :style="{background: card.color + '1a', color: card.color}"><i :class="card.icon"></i></div>
          <div class="stat-info">
            <div class="stat-val" :style="{color: card.color}">{{ card.value }}</div>
            <div class="stat-label">{{ card.label }}</div>
            <div class="stat-trend" :style="{color: card.trend >= 0 ? '#F56C6C' : '#67C23A'}">
              <i :class="card.trend >= 0 ? 'el-icon-caret-top' : 'el-icon-caret-bottom'"></i>{{ Math.abs(card.trend) }}%
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 同比/环比对比 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <div slot="header" class="card-header"><b>本月 vs 上月 对比</b></div>
      <el-row :gutter="16">
        <el-col :span="6" v-for="item in comparisonItems" :key="item.key">
          <div class="cmp-item">
            <div class="cmp-label">{{ item.label }}</div>
            <div class="cmp-value">
              {{ item.current }} <span class="cmp-unit">{{ item.unit }}</span>
              <span class="cmp-change" :style="{color: item.change >= 0 ? '#F56C6C' : '#67C23A'}">
                <i :class="item.change >= 0 ? 'el-icon-top' : 'el-icon-bottom'"></i>{{ Math.abs(item.change) }}%
              </span>
            </div>
            <div class="cmp-prev">上月：{{ item.prev }}{{ item.unit }}</div>
          </div>
        </el-col>
      </el-row>
    </el-card>

    <!-- 第一行：工单趋势 + 故障类型分布 -->
    <el-row :gutter="16" style="margin-bottom:16px;">
      <el-col :span="12">
        <el-card shadow="never">
          <div slot="header" class="card-header">
            <b>工单趋势</b>
            <el-radio-group size="mini" v-model="trendMonths" @change="loadTrend">
              <el-radio-button :label="6">6个月</el-radio-button>
              <el-radio-button :label="12">12个月</el-radio-button>
              <el-radio-button :label="24">24个月</el-radio-button>
            </el-radio-group>
          </div>
          <div ref="trendChart" class="chart-box" v-loading="loading.trend"></div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card shadow="never">
          <div slot="header" class="card-header"><b>故障类型分布</b></div>
          <div ref="faultChart" class="chart-box" v-loading="loading.fault"></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 第二行：维修人员排行 + 平均维修时长 -->
    <el-row :gutter="16" style="margin-bottom:16px;">
      <el-col :span="12">
        <el-card shadow="never">
          <div slot="header" class="card-header">
            <b>维修人员排行</b>
            <el-radio-group size="mini" v-model="workerLimit" @change="loadWorker">
              <el-radio-button :label="5">TOP5</el-radio-button>
              <el-radio-button :label="10">TOP10</el-radio-button>
              <el-radio-button :label="20">TOP20</el-radio-button>
            </el-radio-group>
          </div>
          <div ref="workerChart" class="chart-box" v-loading="loading.worker"></div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card shadow="never">
          <div slot="header" class="card-header"><b>各故障类型平均维修时长</b></div>
          <div ref="avgChart" class="chart-box" v-loading="loading.avg"></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 第三行：紧急程度分布 + 维修时长分布 -->
    <el-row :gutter="16" style="margin-bottom:16px;">
      <el-col :span="12">
        <el-card shadow="never">
          <div slot="header" class="card-header"><b>紧急程度分布</b></div>
          <div ref="emergencyChart" class="chart-box" v-loading="loading.emergency"></div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card shadow="never">
          <div slot="header" class="card-header"><b>维修时长分布</b></div>
          <div ref="durationChart" class="chart-box" v-loading="loading.duration"></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 设备故障排行 TOP10 -->
    <el-card shadow="never">
      <div slot="header" class="card-header">
        <b>设备故障排行 TOP{{ deviceLimit }}</b>
        <div>
          <el-button v-if="hasPerm('device:repair:statistics:export')" size="small" icon="el-icon-download" @click="handleExport">导出</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadDeviceRanking">刷新</el-button>
        </div>
      </div>
      <el-table :data="deviceList" v-loading="loading.device" border stripe size="small">
        <el-table-column type="index" label="排名" width="70" align="center" />
        <el-table-column prop="device_name" label="设备名称" min-width="150" show-overflow-tooltip />
        <el-table-column prop="device_code" label="设备编码" width="140" />
        <el-table-column prop="department_name" label="所属部门" min-width="120" show-overflow-tooltip />
        <el-table-column label="故障次数" width="100" align="center">
          <template slot-scope="{row}">
            <span :style="{color: row.fault_count >= 3 ? '#F56C6C' : row.fault_count >= 2 ? '#E6A23C' : '#67C23A', fontWeight: '700'}">{{ row.fault_count }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="last_fault_time" label="最近故障时间" width="160" show-overflow-tooltip />
        <el-table-column label="操作" width="180" align="center">
          <template slot-scope="{row}">
            <el-button size="mini" type="text" @click="viewDevice(row)">设备详情</el-button>
            <el-button size="mini" type="text" style="color:#E6A23C" @click="viewHistory(row)">维修履历</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import {
  getRepairOverview, getRepairTrend, getFaultDistribution, getWorkerRanking,
  getAvgDuration, getDeviceRanking, getEmergencyDistribution, getDurationDistribution,
  getComparison, exportDeviceRanking
} from '@/api/repairStatistics'

export default {
  name: 'RepairStatistics',
  data() {
    return {
      overviewCards: [
        { key: 'total', label: '工单总数', icon: 'el-icon-document', color: '#409EFF', value: 0, trend: 0 },
        { key: 'pending', label: '待派单', icon: 'el-icon-s-flag', color: '#909399', value: 0, trend: 0 },
        { key: 'repairing', label: '维修中', icon: 'el-icon-setting', color: '#E6A23C', value: 0, trend: 0 },
        { key: 'accepted', label: '待验收', icon: 'el-icon-check', color: '#9B59B6', value: 0, trend: 0 },
        { key: 'month_done', label: '本月完工', icon: 'el-icon-circle-check', color: '#67C23A', value: 0, trend: 0 },
        { key: 'avg_duration', label: '平均维修时长(小时)', icon: 'el-icon-data-line', color: '#13C2C2', value: 0, trend: 0 },
      ],
      comparisonItems: [
        { key: 'total', label: '工单总数', current: 0, prev: 0, unit: '', change: 0 },
        { key: 'done', label: '完成数', current: 0, prev: 0, unit: '', change: 0 },
        { key: 'avg_duration', label: '平均维修时长', current: 0, prev: 0, unit: 'h', change: 0 },
        { key: 'top_fault', label: '故障TOP1类型', current: '—', prev: '—', unit: '', change: 0 },
      ],
      trendMonths: 12,
      workerLimit: 10,
      deviceLimit: 10,
      deviceList: [],
      loading: { trend: false, fault: false, worker: false, avg: false, emergency: false, duration: false, device: false },
      charts: {},
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
      const keys = ['trendChart', 'faultChart', 'workerChart', 'avgChart', 'emergencyChart', 'durationChart']
      keys.forEach(k => { if (this.$refs[k]) this.charts[k] = echarts.init(this.$refs[k]) })
    },
    handleResize() { Object.keys(this.charts).forEach(k => { if (this.charts[k]) this.charts[k].resize() }) },
    loadAll() {
      this.loadOverview()
      this.loadTrend()
      this.loadFault()
      this.loadWorker()
      this.loadAvg()
      this.loadDeviceRanking()
      this.loadEmergency()
      this.loadDuration()
      this.loadComparison()
    },
    // 概览
    async loadOverview() {
      try {
        const r = await getRepairOverview()
        if (r.code === 0) {
          const d = r.data || {}
          this.overviewCards = this.overviewCards.map(c => ({ ...c, value: d[c.key] !== undefined ? d[c.key] : 0 }))
        }
      } catch (e) {}
    },
    // 工单趋势
    async loadTrend() {
      this.setLoading('trend', true)
      try {
        const r = await getRepairTrend(this.trendMonths)
        if (r.code === 0) {
          const d = r.data || {}
          this.charts.trendChart.setOption({
            tooltip: { trigger: 'axis' },
            legend: { data: ['新增工单', '完成工单'], right: 10 },
            grid: { left: 40, right: 20, top: 40, bottom: 30 },
            xAxis: { type: 'category', data: d.months || [], name: '月份' },
            yAxis: { type: 'value', name: '数量' },
            series: [
              { name: '新增工单', type: 'line', smooth: true, data: d.created || [], lineStyle: { width: 2, color: '#409EFF' }, itemStyle: { color: '#409EFF' }, label: { show: true } },
              { name: '完成工单', type: 'line', smooth: true, data: d.done || [], lineStyle: { width: 2, color: '#67C23A' }, itemStyle: { color: '#67C23A' }, label: { show: true } },
            ],
          })
        }
      } catch (e) {}
      this.setLoading('trend', false)
    },
    // 故障类型分布
    async loadFault() {
      this.setLoading('fault', true)
      try {
        const r = await getFaultDistribution()
        if (r.code === 0) {
          const list = (r.data && r.data.list) || []
          const colorMap = { mechanical: '#409EFF', electrical: '#E6A23C', hydraulic: '#67C23A', pneumatic: '#9B59B6', software: '#13C2C2', other: '#909399' }
          this.charts.faultChart.setOption({
            tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
            legend: { orient: 'vertical', right: 10, top: 'middle' },
            series: [{
              type: 'pie', radius: '50%', center: ['40%', '50%'],
              label: { formatter: '{b}: {c} ({d}%)' },
              data: list.map(i => ({ name: i.name, value: i.count, itemStyle: { color: colorMap[i.type] } })),
            }],
          })
        }
      } catch (e) {}
      this.setLoading('fault', false)
    },
    // 维修人员排行
    async loadWorker() {
      this.setLoading('worker', true)
      try {
        const r = await getWorkerRanking(this.workerLimit)
        if (r.code === 0) {
          const list = r.data || []
          this.charts.workerChart.setOption({
            tooltip: { trigger: 'axis' },
            grid: { left: 40, right: 20, top: 20, bottom: 40 },
            xAxis: { type: 'category', data: list.map(i => i.handler_name), name: '维修人员' },
            yAxis: { type: 'value', name: '完成数量' },
            series: [{
              type: 'bar', data: list.map(i => i.done_count),
              itemStyle: { color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: '#FF9A45' }, { offset: 1, color: '#E6A23C' }]) },
              label: { show: true, position: 'top' },
            }],
          })
        }
      } catch (e) {}
      this.setLoading('worker', false)
    },
    // 平均维修时长
    async loadAvg() {
      this.setLoading('avg', true)
      try {
        const r = await getAvgDuration()
        if (r.code === 0) {
          const d = r.data || {}
          const list = d.list || []
          this.charts.avgChart.setOption({
            tooltip: { trigger: 'axis' },
            grid: { left: 40, right: 20, top: 40, bottom: 40 },
            xAxis: { type: 'category', data: list.map(i => i.name), name: '故障类型' },
            yAxis: { type: 'value', name: '小时' },
            series: [{
              type: 'bar', data: list.map(i => i.avg_hours),
              itemStyle: { color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: '#A67FFB' }, { offset: 1, color: '#9B59B6' }]) },
              label: { show: true, position: 'top' },
              markLine: {
                data: [{ type: 'average', name: '平均' }],
                lineStyle: { color: '#F56C6C', type: 'dashed', width: 2 },
                label: { formatter: '平均 ' + (d.overall_avg || 0) + 'h' },
              },
            }],
          })
        }
      } catch (e) {}
      this.setLoading('avg', false)
    },
    // 紧急程度分布
    async loadEmergency() {
      this.setLoading('emergency', true)
      try {
        const r = await getEmergencyDistribution()
        if (r.code === 0) {
          const list = (r.data && r.data.list) || []
          const colorMap = { normal: '#409EFF', urgent: '#E6A23C', critical: '#F56C6C' }
          this.charts.emergencyChart.setOption({
            tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
            legend: { orient: 'vertical', right: 10, top: 'middle' },
            series: [{
              type: 'pie', radius: '50%', center: ['40%', '50%'],
              label: { formatter: '{b}: {c} ({d}%)' },
              data: list.map(i => ({ name: i.name, value: i.count, itemStyle: { color: colorMap[i.level] } })),
            }],
          })
        }
      } catch (e) {}
      this.setLoading('emergency', false)
    },
    // 维修时长分布
    async loadDuration() {
      this.setLoading('duration', true)
      try {
        const r = await getDurationDistribution()
        if (r.code === 0) {
          const list = r.data || []
          this.charts.durationChart.setOption({
            tooltip: { trigger: 'axis' },
            grid: { left: 40, right: 20, top: 20, bottom: 40 },
            xAxis: { type: 'category', data: list.map(i => i.name), name: '时长区间' },
            yAxis: { type: 'value', name: '数量' },
            series: [{
              type: 'bar', data: list.map(i => i.count),
              itemStyle: { color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: '#36CFC9' }, { offset: 1, color: '#13C2C2' }]) },
              label: { show: true, position: 'top' },
            }],
          })
        }
      } catch (e) {}
      this.setLoading('duration', false)
    },
    // 设备故障排行
    async loadDeviceRanking() {
      this.setLoading('device', true)
      try {
        const r = await getDeviceRanking(this.deviceLimit)
        if (r.code === 0) this.deviceList = r.data || []
      } catch (e) {}
      this.setLoading('device', false)
    },
    // 同比/环比
    async loadComparison() {
      try {
        const r = await getComparison()
        if (r.code === 0) {
          const d = r.data || {}
          const c = d.current || {}, p = d.prev || {}, ch = d.changes || {}
          this.comparisonItems = [
            { key: 'total', label: '工单总数', current: c.total || 0, prev: p.total || 0, unit: '', change: ch.total || 0 },
            { key: 'done', label: '完成数', current: c.done || 0, prev: p.done || 0, unit: '', change: ch.done || 0 },
            { key: 'avg_duration', label: '平均维修时长', current: c.avg_duration || 0, prev: p.avg_duration || 0, unit: 'h', change: ch.avg_duration || 0 },
            { key: 'top_fault', label: '故障TOP1类型', current: c.top_fault || '—', prev: p.top_fault || '—', unit: '', change: 0 },
          ]
        }
      } catch (e) {}
    },
    setLoading(key, val) { this.$set(this.loading, key, val) },
    // 点击概览卡跳转工单列表
    goOrderList(card) {
      const statusMap = { pending: 'pending', repairing: 'repairing', accepted: 'accepted' }
      if (statusMap[card.key]) {
        this.$router.push({ path: '/device/repair/order', query: { status: statusMap[card.key] } })
      } else {
        this.$router.push('/device/repair/order')
      }
    },
    // 设备详情
    viewDevice(row) {
      this.$router.push({ path: '/device/asset', query: { device_id: row.device_id } })
    },
    // 维修履历（跳维修记录页，带设备ID）
    viewHistory(row) {
      this.$router.push({ path: '/device/repair/record', query: { device_id: row.device_id } })
    },
    async handleExport() {
      const r = await exportDeviceRanking(this.deviceLimit)
      if (r.code === 0 && r.data.url) window.open(r.data.url, '_blank')
    },
  },
}
</script>

<style scoped>
.stat-card { cursor: pointer; transition: all .2s; }
.stat-card:hover { transform: translateY(-3px); box-shadow: 0 6px 16px rgba(0,0,0,.1); }
.stat-card .stat-icon { width: 40px; height: 40px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 20px; float: left; margin-right: 10px; }
.stat-card .stat-info { overflow: hidden; }
.stat-card .stat-val { font-size: 20px; font-weight: 700; line-height: 1.2; }
.stat-card .stat-label { font-size: 12px; color: #909399; }
.stat-card .stat-trend { font-size: 11px; margin-top: 2px; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
.chart-box { height: 320px; }
.cmp-item { padding: 12px; border-radius: 8px; background: #f8f9fb; }
.cmp-label { font-size: 12px; color: #909399; margin-bottom: 6px; }
.cmp-value { font-size: 20px; font-weight: 700; }
.cmp-unit { font-size: 12px; color: #909399; font-weight: normal; }
.cmp-change { font-size: 13px; margin-left: 8px; }
.cmp-prev { font-size: 12px; color: #C0C4CC; margin-top: 4px; }
</style>
