<template>
  <div ref="chart" style="width:100%;height:300px;"></div>
</template>

<script>
import * as echarts from 'echarts'
import { getScoreTrend } from '@/api/trainingExam'

export default {
  name: 'ScoreTrendChart',
  data() {
    return { chart: null }
  },
  mounted() {
    this.chart = echarts.init(this.$refs.chart)
    this.load()
    window.addEventListener('resize', this.resize)
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.resize)
    if (this.chart) this.chart.dispose()
  },
  methods: {
    resize() { if (this.chart) this.chart.resize() },
    async load() {
      try {
        const r = await getScoreTrend(12)
        if (r.code === 0) this.render(r.data)
      } catch (e) {}
    },
    render(d) {
      if (!this.chart) return
      this.chart.setOption({
        tooltip: { trigger: 'axis' },
        legend: { data: ['平均分', '考试人次'], top: 0 },
        grid: { left: 50, right: 50, top: 40, bottom: 30 },
        xAxis: { type: 'category', data: d.months || [] },
        yAxis: [
          { type: 'value', name: '平均分', min: 0, max: 100 },
          { type: 'value', name: '人次', minInterval: 1 },
        ],
        series: [
          { name: '平均分', type: 'line', smooth: true, data: d.avg_scores || [], yAxisIndex: 0, itemStyle: { color: '#409EFF' } },
          { name: '考试人次', type: 'bar', data: d.counts || [], yAxisIndex: 1, itemStyle: { color: '#67C23A' } },
        ],
      })
    },
  },
}
</script>
