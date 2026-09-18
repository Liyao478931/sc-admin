/**
 * ECharts 按需引入（减少打包体积）
 * 说明：除图表/组件外必须注册渲染器（CanvasRenderer），否则图表不渲染
 */
import * as echarts from 'echarts/core'
import { BarChart, LineChart, PieChart, GaugeChart } from 'echarts/charts'
import { TitleComponent, TooltipComponent, LegendComponent, GridComponent } from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'

echarts.use([
  BarChart,
  LineChart,
  PieChart,
  GaugeChart,
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  GridComponent,
  CanvasRenderer
])

export default echarts
