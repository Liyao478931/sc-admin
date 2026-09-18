<!-- 文件：admin/src/views/ai/workflow/components/WorkflowLogStatsDialog.vue -->
<!-- 运行日志统计图表：运行趋势折线 / 状态分布饼图 / 工作流运行排行柱状（ECharts） -->
<template>
  <el-dialog title="运行日志统计分析" :visible="visible" @update:visible="$emit('update:visible', $event)" width="980px" top="5vh" @open="initCharts">
    <div class="stats-head">
      <span>时间维度：</span>
      <el-radio-group v-model="range" size="small" @change="reloadTrend">
        <el-radio-button label="day">按天</el-radio-button>
        <el-radio-button label="week">按周</el-radio-button>
        <el-radio-button label="month">按月</el-radio-button>
      </el-radio-group>
      <el-button size="small" icon="el-icon-picture-outline" style="margin-left:auto;" @click="exportImage">导出图片</el-button>
    </div>

    <div class="chart-box">
      <div class="chart-title">运行趋势</div>
      <div ref="trendChart" class="chart" style="height:260px;"></div>
    </div>
    <el-row :gutter="14">
      <el-col :span="12">
        <div class="chart-box">
          <div class="chart-title">状态分布</div>
          <div ref="distChart" class="chart" style="height:260px;"></div>
        </div>
      </el-col>
      <el-col :span="12">
        <div class="chart-box">
          <div class="chart-title">工作流运行排行 TOP10</div>
          <div ref="rankChart" class="chart" style="height:260px;"></div>
        </div>
      </el-col>
    </el-row>
  </el-dialog>
</template>

<script>
import * as echarts from 'echarts'
import { getWorkflowLogTrend, getWorkflowLogStatusDist, getWorkflowLogRanking } from '@/api/aiWorkflow'

export default {
  name: 'WorkflowLogStatsDialog',
  props: {
    visible: { type: Boolean, default: false }
  },
  data () {
    return { range: 'day', charts: {} }
  },
  methods: {
    async initCharts () {
      this.$nextTick(() => {
        this.charts.trend = echarts.init(this.$refs.trendChart)
        this.charts.dist = echarts.init(this.$refs.distChart)
        this.charts.rank = echarts.init(this.$refs.rankChart)
        this.loadAll()
      })
    },
    async loadAll () {
      this.loadTrend()
      this.loadDist()
      this.loadRank()
    },
    async reloadTrend () { this.loadTrend() },
    async loadTrend () {
      try {
        const r = await getWorkflowLogTrend({ range: this.range })
        if (r.code === 0 && this.charts.trend) {
          const list = r.data.list || []
          this.charts.trend.setOption({
            tooltip: { trigger: 'axis' },
            grid: { left: 40, right: 20, top: 30, bottom: 30 },
            xAxis: { type: 'category', data: list.map(i => i.date), axisLabel: { fontSize: 11 } },
            yAxis: { type: 'value', minInterval: 1 },
            series: [{ type: 'line', smooth: true, data: list.map(i => i.count), areaStyle: { opacity: 0.15 }, itemStyle: { color: '#409EFF' } }]
          })
        }
      } catch (e) {}
    },
    async loadDist () {
      try {
        const r = await getWorkflowLogStatusDist()
        if (r.code === 0 && this.charts.dist) {
          const list = r.data.list || []
          this.charts.dist.setOption({
            tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
            legend: { bottom: 0 },
            color: ['#409EFF', '#67C23A', '#F56C6C'],
            series: [{
              type: 'pie', radius: ['40%', '68%'], center: ['50%', '45%'],
              data: list.map(i => ({ name: i.name, value: i.count }))
            }]
          })
        }
      } catch (e) {}
    },
    async loadRank () {
      try {
        const r = await getWorkflowLogRanking()
        if (r.code === 0 && this.charts.rank) {
          const list = r.data.list || []
          this.charts.rank.setOption({
            tooltip: { trigger: 'axis' },
            grid: { left: 120, right: 20, top: 20, bottom: 30 },
            xAxis: { type: 'value', minInterval: 1 },
            yAxis: { type: 'category', data: list.map(i => i.name).reverse(), axisLabel: { fontSize: 11 } },
            series: [{ type: 'bar', data: list.map(i => i.count).reverse(), itemStyle: { color: '#8E44AD' }, barMaxWidth: 20 }]
          })
        }
      } catch (e) {}
    },
    exportImage () {
      // 导出当前活动 tab 的图表图片
      for (const key of Object.keys(this.charts)) {
        const c = this.charts[key]
        if (!c) continue
        const url = c.getDataURL({ pixelRatio: 2, backgroundColor: '#fff' })
        const a = document.createElement('a')
        a.href = url
        a.download = 'workflow_stats_' + key + '.png'
        document.body.appendChild(a); a.click(); document.body.removeChild(a)
      }
    }
  },
  beforeDestroy () {
    for (const key of Object.keys(this.charts)) {
      if (this.charts[key]) { this.charts[key].dispose(); this.charts[key] = null }
    }
  }
}
</script>

<style scoped>
.stats-head { display: flex; align-items: center; gap: 10px; margin-bottom: 12px; font-size: 13px; color: #606266; }
.chart-box { background: #fff; border: 1px solid #ebeef5; border-radius: 8px; padding: 10px; margin-bottom: 12px; }
.chart-title { font-size: 13px; font-weight: 600; color: #303133; margin-bottom: 8px; }
</style>
