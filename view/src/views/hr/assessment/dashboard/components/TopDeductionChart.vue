<!-- 高频扣分项 TOP10 横向柱状图 -->
<template>
  <div class="chart-card">
    <div class="chart-title">高频扣分项 TOP{{ list.length }}</div>
    <div ref="chart" class="chart-body"></div>
  </div>
</template>

<script>
import chartMixin from './chartMixin.js'

const CATEGORY_COLORS = { 履职情况: '#1e6fff', 公共量化指标: '#00b42a', 安全: '#f53f3f', 纪律行为规范: '#ffb020' }

export default {
  name: 'TopDeductionChart',
  mixins: [chartMixin],
  props: {
    list: { type: Array, default: () => [] }
  },
  watch: {
    list () { this.reRenderChart() }
  },
  methods: {
    renderChart () {
      const inst = this.chartInstance
      if (!inst) return
      const names = this.list.map(d => d.indicator_name)
      const values = this.list.map(d => d.total_count)
      const colors = this.list.map(d => CATEGORY_COLORS[d.category] || '#909399')
      inst.setOption({
        tooltip: {
          trigger: 'axis',
          formatter: params => {
            const i = params[0].dataIndex
            const d = this.list[i]
            return `${d.indicator_name}<br/>大类：${d.category || '-'}<br/>扣分次数：${d.total_count}<br/>涉及人数：${d.affected_employees}<br/>扣分合计：${d.total_deduct}`
          }
        },
        grid: { left: 10, right: 40, top: 20, bottom: 20, containLabel: true },
        xAxis: { type: 'value' },
        yAxis: { type: 'category', data: names, axisLabel: { fontSize: 11 } },
        series: [{
          type: 'bar',
          data: values.map((v, i) => ({ value: v, itemStyle: { color: colors[i], borderRadius: [0, 4, 4, 0] } })),
          barMaxWidth: 16,
          label: { show: true, position: 'right', fontSize: 11 }
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
