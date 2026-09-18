/**
 * ECharts 通用混入：初始化 / 自适应 / 销毁
 * 组件需实现 renderChart()（使用 this.chartInstance.setOption），并在 template 中放置 ref="chart" 容器
 */
import * as echarts from 'echarts'

export default {
  data () {
    return { chartInstance: null }
  },
  mounted () {
    this.$nextTick(() => {
      const el = this.$refs.chart
      if (!el) return
      this.chartInstance = echarts.init(el)
      this.renderChart()
      this._resizeHandler = () => { if (this.chartInstance) this.chartInstance.resize() }
      window.addEventListener('resize', this._resizeHandler)
    })
  },
  beforeDestroy () {
    if (this._resizeHandler) window.removeEventListener('resize', this._resizeHandler)
    if (this.chartInstance) { this.chartInstance.dispose(); this.chartInstance = null }
  },
  methods: {
    reRenderChart () {
      this.$nextTick(() => {
        if (this.chartInstance) this.renderChart()
      })
    }
  }
}
