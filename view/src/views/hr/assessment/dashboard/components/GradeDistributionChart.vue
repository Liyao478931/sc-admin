<!-- 等级分布饼图 -->
<template>
  <div class="chart-card">
    <div class="chart-title">等级分布</div>
    <div ref="chart" class="chart-body"></div>
  </div>
</template>

<script>
import chartMixin from './chartMixin.js'

const GRADE_COLORS = { A: '#00b42a', B: '#1e6fff', C: '#ffb020', D: '#f53f3f' }
const GRADE_LABELS = { A: 'A (≥90) 优秀', B: 'B (80-89) 良好', C: 'C (70-79) 合格', D: 'D (<70) 待改进' }

export default {
  name: 'GradeDistributionChart',
  mixins: [chartMixin],
  props: {
    gradeDist: { type: Object, default: () => ({ A: 0, B: 0, C: 0, D: 0 }) },
    total: { type: Number, default: 0 }
  },
  watch: {
    gradeDist () { this.reRenderChart() },
    total () { this.reRenderChart() }
  },
  methods: {
    renderChart () {
      const inst = this.chartInstance
      if (!inst) return
      const data = Object.keys(GRADE_COLORS).map(k => ({
        value: this.gradeDist[k] || 0,
        name: GRADE_LABELS[k],
        itemStyle: { color: GRADE_COLORS[k] }
      }))
      inst.setOption({
        tooltip: { trigger: 'item', formatter: '{b}: {c}人 ({d}%)' },
        legend: { bottom: 0, textStyle: { fontSize: 11 } },
        title: {
          text: String(this.total), subtext: '总人数',
          left: 'center', top: '38%',
          textStyle: { fontSize: 22, fontWeight: 600, color: '#1d2129' },
          subtextStyle: { fontSize: 11, color: '#8c8f9c' }
        },
        series: [{
          type: 'pie',
          radius: ['42%', '68%'],
          center: ['50%', '44%'],
          data,
          label: { formatter: '{b}\n{d}%', fontSize: 11 },
          emphasis: { itemStyle: { shadowBlur: 10, shadowColor: 'rgba(0,0,0,0.2)' } }
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
