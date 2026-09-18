<!-- 文件：admin/src/views/ai/forecast/sales.vue（v1.65.0 销售预测看板） -->
<template>
  <div class="forecast">
    <div class="crumb"><span>AI智能平台</span><i class="el-icon-arrow-right"></i><span>销售预测</span><i class="el-icon-arrow-right"></i><span class="cur">预测看板</span></div>

    <!-- 筛选栏 -->
    <div class="toolbar">
      <span class="lbl">预测范围：</span>
      <el-radio-group v-model="months" size="small" @change="loadAll">
        <el-radio-button :label="1">未来1个月</el-radio-button>
        <el-radio-button :label="3">未来3个月</el-radio-button>
        <el-radio-button :label="6">未来6个月</el-radio-button>
      </el-radio-group>
      <span class="lbl" style="margin-left:16px;">预测维度：</span>
      <el-select v-model="dimension" size="small" style="width:140px" @change="loadAll">
        <el-option label="整体" value="overall" />
        <el-option label="按产品分类" value="category" />
        <el-option label="按客户等级" value="customer_level" />
        <el-option label="按业务员" value="sales_person" />
      </el-select>
      <el-button size="small" icon="el-icon-refresh" style="margin-left:12px;" @click="loadAll">刷新</el-button>
      <el-button size="small" type="primary" icon="el-icon-download" @click="doExport">导出报告</el-button>
    </div>

    <!-- 指标卡 -->
    <div class="cards">
      <div class="card">
        <div class="card-label">下月预测销售额</div>
        <div class="card-value">{{ overview.next_month ? overview.next_month.revenue_range_formatted + '万' : '-' }}</div>
        <div class="card-sub" v-if="overview.next_month">中位值 ¥{{ fmtWan(overview.next_month.revenue_mid) }}万</div>
      </div>
      <div class="card">
        <div class="card-label">下月预测订单数</div>
        <div class="card-value" v-if="overview.next_month">{{ overview.next_month.order_count_lower }} - {{ overview.next_month.order_count_upper }}单</div>
        <div class="card-value" v-else>-</div>
        <div class="card-sub" v-if="overview.next_month">中位值 {{ overview.next_month.order_count_mid }}单</div>
      </div>
      <div class="card">
        <div class="card-label">预测准确率</div>
        <div class="card-value">{{ overview.accuracy ? overview.accuracy + '%' : '-' }}</div>
        <div class="card-sub">基于历史回测（MAPE）</div>
      </div>
    </div>

    <!-- 趋势图 -->
    <div class="panel">
      <div class="panel-head"><span>销售额预测趋势图</span><span class="hint">实际值（实线）/ 预测值（虚线）/ 95%置信区间（阴影带）</span></div>
      <div ref="chart" class="chart"></div>
    </div>

    <div class="two-col">
      <!-- 产品预测排行 -->
      <div class="panel">
        <div class="panel-head"><span>产品预测排行</span></div>
        <div v-if="products.length" class="prod-list">
          <div v-for="(p, i) in products" :key="p.product_id" class="prod-item">
            <span class="rank">{{ i + 1 }}</span>
            <span class="pname" :title="p.product_name">{{ p.product_name }}</span>
            <span class="pchg" :class="p.change_pct >= 0 ? 'up' : 'down'">{{ p.change_pct >= 0 ? '↑' : '↓' }}{{ Math.abs(p.change_pct) }}%</span>
            <span class="pval">¥{{ fmtWan(p.forecast_revenue) }}万</span>
          </div>
        </div>
        <el-empty v-else description="暂无产品预测数据" :image-size="60" />
      </div>
      <!-- 因子分析 -->
      <div class="panel">
        <div class="panel-head"><span>预测因子分析</span></div>
        <div v-if="factors.length" class="factor-list">
          <div v-for="f in factors" :key="f.key" class="factor-item">
            <span class="fname">{{ f.name }}</span>
            <el-progress :percentage="Math.min(100, Math.abs(f.value) * 3)" :color="f.value >= 0 ? '#409eff' : '#f56c6c'" :stroke-width="10" />
            <span class="fval" :class="f.value >= 0 ? 'up' : 'down'">{{ f.value >= 0 ? '+' : '' }}{{ f.value }}%</span>
          </div>
        </div>
        <el-empty v-else description="暂无因子数据" :image-size="60" />
        <div class="forecast-note">基于过去24个月历史数据时间序列预测，置信区间95%。预测仅供参考，实际销售可能受市场变化影响。</div>
      </div>
    </div>
  </div>
</template>

<script>
import echarts from '@/utils/echarts'
import { getForecastOverview, getForecastTrend, getForecastProducts, getForecastFactors, exportForecastFile } from '@/api/aiForecast'

export default {
  name: 'AiForecastSales',
  data () {
    return {
      months: 3,
      dimension: 'overall',
      overview: {},
      trendData: [],
      products: [],
      factors: [],
      chart: null
    }
  },
  mounted () { this.loadAll() },
  beforeDestroy () { if (this.chart) this.chart.dispose() },
  methods: {
    fmtWan (v) { return v >= 10000 ? (v / 10000).toFixed(1) : String(Math.round(v)) },
    params () { return { months: this.months, dimension: this.dimension } },
    async loadAll () {
      this.loadOverview(); this.loadTrend(); this.loadProducts(); this.loadFactors()
    },
    async loadOverview () {
      try { const r = await getForecastOverview(this.params()); if (r.code === 0) this.overview = r.data || {} } catch (e) {}
    },
    async loadTrend () {
      try {
        const r = await getForecastTrend(this.params())
        if (r.code === 0) { this.trendData = r.data.data || []; this.renderChart() }
      } catch (e) {}
    },
    async loadProducts () {
      try { const r = await getForecastProducts({ months: this.months, top: 10 }); if (r.code === 0) this.products = r.data.list || [] } catch (e) {}
    },
    async loadFactors () {
      try { const r = await getForecastFactors(this.params()); if (r.code === 0) this.factors = r.data.factors || [] } catch (e) {}
    },
    renderChart () {
      if (!this.$refs.chart) return
      if (!this.chart) this.chart = echarts.init(this.$refs.chart)
      const dates = this.trendData.map(d => d.ym)
      const actual = this.trendData.map(d => d.actual !== null ? (d.actual / 10000).toFixed(2) : null)
      const forecast = this.trendData.map(d => d.forecast !== null ? (d.forecast / 10000).toFixed(2) : null)
      const lower = this.trendData.map(d => d.lower !== null ? (d.lower / 10000).toFixed(2) : null)
      const upper = this.trendData.map(d => d.upper !== null ? (d.upper / 10000).toFixed(2) : null)
      const option = {
        tooltip: { trigger: 'axis' },
        legend: { data: ['实际值', '预测值', '置信区间'], top: 0 },
        grid: { left: 60, right: 20, top: 36, bottom: 30 },
        xAxis: { type: 'category', data: dates },
        yAxis: { type: 'value', name: '万元' },
        series: [
          { name: '置信区间', type: 'line', data: lower, stack: 'ci', lineStyle: { opacity: 0 }, symbol: 'none', areaStyle: { color: 'rgba(64,158,255,0.18)' } },
          { name: '置信区间', type: 'line', data: upper, stack: 'ci', lineStyle: { opacity: 0 }, symbol: 'none', areaStyle: { color: 'rgba(64,158,255,0.18)' } },
          { name: '实际值', type: 'line', data: actual, symbol: 'circle', itemStyle: { color: '#409eff' }, lineStyle: { width: 2, color: '#409eff' } },
          { name: '预测值', type: 'line', data: forecast, symbol: 'circle', itemStyle: { color: '#67c23a' }, lineStyle: { width: 2, type: 'dashed', color: '#67c23a' } }
        ]
      }
      this.chart.setOption(option, true)
    },
    async doExport () {
      try { await exportForecastFile(this.params()); this.$message.success('导出已开始') } catch (e) { this.$message.error('导出失败') }
    }
  }
}
</script>

<style scoped>
.crumb { padding: 10px 16px; background: #fff; border-bottom: 1px solid #e8e8e8; font-size: 13px; color: #909399; }
.crumb i { margin: 0 6px; }
.crumb .cur { color: #303133; }
.toolbar { display: flex; align-items: center; padding: 12px 16px; background: #fff; flex-wrap: wrap; }
.lbl { font-size: 13px; color: #606266; }
.cards { display: flex; gap: 16px; padding: 16px; }
.card { flex: 1; background: #fff; border-radius: 8px; border: 1px solid #ebeef5; padding: 16px; }
.card-label { font-size: 13px; color: #909399; }
.card-value { font-size: 22px; font-weight: 600; color: #409eff; margin: 8px 0 4px; }
.card-sub { font-size: 12px; color: #909399; }
.panel { background: #fff; border: 1px solid #ebeef5; border-radius: 8px; margin: 0 16px 16px; padding: 12px 16px; }
.panel-head { font-weight: 600; margin-bottom: 8px; display: flex; justify-content: space-between; }
.hint { font-weight: 400; font-size: 12px; color: #909399; }
.chart { height: 340px; }
.two-col { display: flex; gap: 16px; padding: 0 16px 16px; }
.two-col .panel { flex: 1; margin: 0; }
.prod-item { display: flex; align-items: center; gap: 8px; padding: 6px 0; border-bottom: 1px dashed #ebeef5; font-size: 13px; }
.rank { width: 20px; height: 20px; border-radius: 50%; background: #ecf5ff; color: #409eff; text-align: center; line-height: 20px; font-size: 12px; flex-shrink: 0; }
.pname { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.pchg.up, .fval.up { color: #f56c6c; }
.pchg.down, .fval.down { color: #67c23a; }
.pval { color: #606266; font-weight: 600; }
.factor-item { display: flex; align-items: center; gap: 10px; padding: 6px 0; font-size: 13px; }
.fname { width: 80px; flex-shrink: 0; }
.factor-item .el-progress { flex: 1; }
.fval { width: 60px; text-align: right; }
.forecast-note { margin-top: 10px; font-size: 12px; color: #909399; background: #f5f7fa; padding: 8px; border-radius: 4px; }
</style>
