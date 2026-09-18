<!-- 部门排名柱状图 -->
<template>
  <div class="chart-card">
    <div class="chart-title">部门排名</div>
    <div ref="chart" class="chart-body"></div>
  </div>
</template>

<script>
import chartMixin from './chartMixin.js'

export default {
  name: 'DeptRankingChart',
  mixins: [chartMixin],
  props: {
    list: { type: Array, default: () => [] },
    overallAvg: { type: Number, default: 0 }
  },
  watch: {
    list () { this.reRenderChart() },
    overallAvg () { this.reRenderChart() }
  },
  methods: {
    renderChart () {
      const inst = this.chartInstance
      if (!inst) return
      const names = this.list.map(d => d.department_name)
      const values = this.list.map(d => d.avg_score)
      inst.setOption({
        tooltip: {
          trigger: 'axis',
          formatter: params => {
            const i = params[0].dataIndex
            const d = this.list[i]
            return `${d.department_name}<br/>平均分：${d.avg_score}<br/>人数：${d.employee_count}<br/>最高：${d.max_score} / 最低：${d.min_score}`
          }
        },
        grid: { left: 40, right: 20, top: 40, bottom: 30 },
        xAxis: { type: 'category', data: names, axisLabel: { interval: 0, rotate: 30, fontSize: 11 } },
        yAxis: { type: 'value', min: 0, max: 100 },
        series: [{
          type: 'bar',
          data: values,
          barMaxWidth: 28,
          itemStyle: { color: '#1e6fff', borderRadius: [4, 4, 0, 0] },
          label: { show: true, position: 'top', fontSize: 11 },
          markLine: this.overallAvg > 0 ? { silent: true, symbol: 'none', lineStyle: { type: 'dashed', color: '#f77234' }, label: { formatter: '全员 ' + this.overallAvg, position: 'end' }, data: [{ yAxis: this.overallAvg }] } : undefined
        }]
      }, true)
    }
  }
}
</script>

<style scoped>
.chart-card { background: #fff; border: 1px solid #e8ecf1; border-radius: 12px; padding: 14px 16px; }
.chart-title { font-size: 14px; font-weight: 600; color: #1d2129; margin-bottom: 8px; }
.chart-body { height: 260px; }
</style>
