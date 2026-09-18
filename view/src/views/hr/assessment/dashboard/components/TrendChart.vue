<!-- 得分趋势折线图（双线） -->
<template>
  <div class="chart-card">
    <div class="chart-title">得分趋势（近 {{ periods.length }} 个月）</div>
    <div ref="chart" class="chart-body"></div>
  </div>
</template>

<script>
import chartMixin from './chartMixin.js'

export default {
  name: 'TrendChart',
  mixins: [chartMixin],
  props: {
    periods: { type: Array, default: () => [] },
    current: { type: Object, default: () => ({ name: '', scores: [] }) },
    compare: { type: Object, default: () => ({ name: '', scores: [] }) }
  },
  watch: {
    periods () { this.reRenderChart() },
    current () { this.reRenderChart() },
    compare () { this.reRenderChart() }
  },
  methods: {
    renderChart () {
      const inst = this.chartInstance
      if (!inst) return
      const labels = (this.periods || []).map(p => String(p).slice(5) + '月')
      const series = []
      if (this.current && this.current.scores && this.current.scores.length) {
        series.push({
          name: this.current.name || '当前',
          type: 'line',
          data: this.current.scores,
          smooth: true,
          symbolSize: 6,
          lineStyle: { width: 2.5, color: '#1e6fff' },
          itemStyle: { color: '#1e6fff' },
          markPoint: { data: [{ type: 'max' }, { type: 'min' }], symbolSize: 40 }
        })
      }
      if (this.compare && this.compare.scores && this.compare.scores.length && this.compare.name) {
        series.push({
          name: this.compare.name,
          type: 'line',
          data: this.compare.scores,
          smooth: true,
          symbolSize: 5,
          lineStyle: { width: 2, type: 'dashed', color: '#f77234' },
          itemStyle: { color: '#f77234' }
        })
      }
      inst.setOption({
        tooltip: { trigger: 'axis', formatter: params => {
          const i = params[0].dataIndex
          let html = `${this.periods[i] || ''}<br/>`
          params.forEach(p => { html += `${p.marker}${p.seriesName}：${p.value}<br/>` })
          if (this.current.employee_counts && this.current.employee_counts[i]) html += `参与人数：${this.current.employee_counts[i]}`
          return html
        } },
        legend: { top: 0, textStyle: { fontSize: 11 } },
        grid: { left: 40, right: 20, top: 30, bottom: 30 },
        xAxis: { type: 'category', data: labels, boundaryGap: false },
        yAxis: { type: 'value', min: 60, max: 100 },
        series
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
