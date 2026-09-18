<!--
  文件：admin/src/views/hr/recruit/Statistics.vue
  功能：招聘统计（统计卡 + 需求趋势折线 + 简历状态分布饼图 + 渠道效果柱状图）
  权限：hr:recruit:statistics:view
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>招聘管理</el-breadcrumb-item>
      <el-breadcrumb-item>招聘统计</el-breadcrumb-item>
    </el-breadcrumb>

    <el-row :gutter="16" style="margin-bottom:16px;">
      <el-col :span="6" v-for="s in cards" :key="s.label">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-val" :style="{color:s.color}">{{ s.value }}</div>
          <div class="stat-lbl">{{ s.label }}</div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="16">
      <el-col :span="12">
        <el-card shadow="never">
          <div slot="header"><span>招聘需求趋势（近 6 个月）</span></div>
          <div ref="trendChart" class="chart-box"></div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card shadow="never">
          <div slot="header"><span>简历状态分布</span></div>
          <div ref="distChart" class="chart-box"></div>
        </el-card>
      </el-col>
    </el-row>

    <el-card shadow="never" style="margin-top:16px;">
      <div slot="header"><span>招聘渠道效果</span></div>
      <div ref="channelChart" class="chart-box" style="height:320px;"></div>
    </el-card>
  </div>
</template>

<script>
import echarts from '@/utils/echarts'
import { getRecruitStatistics } from '@/api/recruit'

export default {
  name: 'RecruitStatistics',
  data () {
    return { cards: [], charts: {} }
  },
  created () { this.fetchData() },
  beforeDestroy () {
    Object.values(this.charts).forEach(c => { if (c) c.dispose() })
  },
  methods: {
    async fetchData () {
      try {
        const r = await getRecruitStatistics()
        if (r.code === 0 && r.data) {
          const d = r.data
          this.cards = [
            { label: '总需求数', value: d.cards.requirement_total || 0, color: '#409EFF' },
            { label: '在招职位数', value: d.cards.position_on || 0, color: '#67C23A' },
            { label: '待处理简历数', value: d.cards.resume_pending || 0, color: '#E6A23C' },
            { label: '本月入职人数', value: d.cards.join_month || 0, color: '#F56C6C' }
          ]
          this.renderTrend(d.trend)
          this.renderDist(d.resume_dist)
          this.renderChannel(d.channel)
        }
      } catch (e) {}
    },
    renderTrend (trend) {
      if (!this.$refs.trendChart) return
      if (!this.charts.trend) this.charts.trend = echarts.init(this.$refs.trendChart)
      this.charts.trend.setOption({
        tooltip: { trigger: 'axis' },
        legend: { data: ['新增需求', '已满足需求'], bottom: 0 },
        grid: { left: 40, right: 20, top: 20, bottom: 40 },
        xAxis: { type: 'category', data: trend.months || [] },
        yAxis: { type: 'value', minInterval: 1 },
        series: [
          { name: '新增需求', type: 'line', smooth: true, data: trend.created || [], itemStyle: { color: '#409EFF' }, areaStyle: { opacity: 0.1 } },
          { name: '已满足需求', type: 'line', smooth: true, data: trend.passed || [], itemStyle: { color: '#67C23A' }, areaStyle: { opacity: 0.1 } }
        ]
      })
    },
    renderDist (dist) {
      if (!this.$refs.distChart) return
      if (!this.charts.dist) this.charts.dist = echarts.init(this.$refs.distChart)
      const colorMap = { '待筛选': '#E6A23C', '待面试': '#409EFF', '待复试': '#409EFF', '已录用': '#67C23A', '淘汰': '#F56C6C', '已放弃': '#909399' }
      this.charts.dist.setOption({
        tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
        legend: { bottom: 0, type: 'scroll' },
        series: [{
          type: 'pie', radius: ['40%', '65%'], center: ['50%', '45%'],
          data: (dist || []).map(x => ({ name: x.name, value: x.value, itemStyle: { color: colorMap[x.name] || '#409EFF' } }))
        }]
      })
    },
    renderChannel (channel) {
      if (!this.$refs.channelChart) return
      if (!this.charts.channel) this.charts.channel = echarts.init(this.$refs.channelChart)
      this.charts.channel.setOption({
        tooltip: { trigger: 'axis' },
        legend: { data: ['简历数量', '录用数量'], bottom: 0 },
        grid: { left: 40, right: 20, top: 20, bottom: 40 },
        xAxis: { type: 'category', data: channel.sources || [] },
        yAxis: { type: 'value', minInterval: 1 },
        series: [
          { name: '简历数量', type: 'bar', barWidth: 24, data: channel.resumes || [], itemStyle: { color: '#409EFF' } },
          { name: '录用数量', type: 'bar', barWidth: 24, data: channel.hired || [], itemStyle: { color: '#67C23A' } }
        ]
      })
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.stat-card { text-align: center; }
.stat-val { font-size: 30px; font-weight: bold; }
.stat-lbl { font-size: 13px; color: #999; margin-top: 6px; }
.chart-box { height: 300px; }
</style>
