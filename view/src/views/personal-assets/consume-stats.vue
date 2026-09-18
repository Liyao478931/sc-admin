<template>
  <div class="cs-page">
    <el-breadcrumb separator="/" class="cs-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>消耗统计</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 提示横幅 -->
    <div v-if="showBanner" class="cs-banner">
      <i class="el-icon-info cs-banner-icon"></i>
      <span class="cs-banner-text">消耗统计：个人配件消耗数据分析看板。数据来源于报工单中的个人资产消耗记录。</span>
      <i class="el-icon-close cs-banner-close" @click="showBanner = false; localStorage.setItem('cs_banner_closed', '1')"></i>
    </div>

    <!-- 时间筛选 -->
    <div class="cs-filter">
      <el-radio-group v-model="timeDim" size="small" @change="onTimeDimChange">
        <el-radio-button label="today">今日</el-radio-button>
        <el-radio-button label="week">本周</el-radio-button>
        <el-radio-button label="month">本月</el-radio-button>
        <el-radio-button label="year">本年</el-radio-button>
        <el-radio-button label="custom">自定义</el-radio-button>
      </el-radio-group>
      <template v-if="timeDim === 'custom'">
        <el-date-picker v-model="customRange" type="daterange" value-format="yyyy-MM-dd" range-separator="~" start-placeholder="开始" end-placeholder="结束" size="small" style="width:240px;margin-left:12px" />
      </template>
      <el-button size="small" type="primary" icon="el-icon-search" style="margin-left:12px" @click="handleQuery">查询</el-button>
      <el-button size="small" icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
    </div>

    <!-- 统计卡片 -->
    <div class="cs-stats">
      <div class="cs-stat-card"><div class="cs-stat-info"><div class="cs-stat-num" style="color:#409EFF">{{ overview.total_count }}</div><div class="cs-stat-label">总消耗次数</div></div><div class="cs-stat-icon" style="background:#ecf5ff"><i class="el-icon-document" style="color:#409EFF"></i></div></div>
      <div class="cs-stat-card"><div class="cs-stat-info"><div class="cs-stat-num" style="color:#67C23A">{{ overview.total_quantity }}</div><div class="cs-stat-label">总消耗数量</div></div><div class="cs-stat-icon" style="background:#f0f9eb"><i class="el-icon-box" style="color:#67C23A"></i></div></div>
      <div class="cs-stat-card"><div class="cs-stat-info"><div class="cs-stat-num" style="color:#E6A23C">{{ overview.total_types }}</div><div class="cs-stat-label">消耗种类</div></div><div class="cs-stat-icon" style="background:#fdf6ec"><i class="el-icon-setting" style="color:#E6A23C"></i></div></div>
      <div class="cs-stat-card"><div class="cs-stat-info"><div class="cs-stat-num" style="color:#9B59B6;font-size:16px">{{ overview.last_consume_time ? String(overview.last_consume_time).slice(0, 16) : '-' }}</div><div class="cs-stat-label">最近消耗</div></div><div class="cs-stat-icon" style="background:#f5f0fa"><i class="el-icon-time" style="color:#9B59B6"></i></div></div>
    </div>

    <!-- 图表区 -->
    <div class="cs-charts">
      <div class="cs-chart-box">
        <div class="cs-chart-head">
          <span class="cs-chart-title">消耗趋势</span>
          <el-radio-group v-model="granularity" size="mini" @change="loadTrend">
            <el-radio-button label="day">按日</el-radio-button>
            <el-radio-button label="week">按周</el-radio-button>
            <el-radio-button label="month">按月</el-radio-button>
          </el-radio-group>
        </div>
        <div v-loading="trendLoading" ref="trendChart" class="cs-chart" />
      </div>
      <div class="cs-chart-box">
        <div class="cs-chart-head"><span class="cs-chart-title">消耗分类占比</span></div>
        <div v-loading="categoryLoading" ref="categoryChart" class="cs-chart" />
      </div>
    </div>

    <!-- 排行区 -->
    <div class="cs-ranks">
      <div class="cs-rank-box">
        <div class="cs-chart-head"><span class="cs-chart-title">配件消耗排行 TOP10</span></div>
        <div v-if="partRanking.length" class="cs-rank-list">
          <div v-for="(p, i) in partRanking" :key="i" class="cs-rank-item">
            <span class="cs-rank-no">{{ i < 3 ? ['🥇', '🥈', '🥉'][i] : i + 1 }}</span>
            <span class="cs-rank-name">{{ p.asset_name }}{{ p.specification ? '（' + p.specification + '）' : '' }}</span>
            <span class="cs-rank-bar"><span class="cs-rank-bar-inner" :style="{ width: p.percentage + '%' }"></span></span>
            <span class="cs-rank-qty">{{ p.total_quantity }} {{ p.unit }}</span>
            <span class="cs-rank-pct">{{ p.percentage }}%</span>
          </div>
        </div>
        <div v-else class="cs-empty">暂无消耗数据</div>
      </div>
      <div class="cs-rank-box">
        <div class="cs-chart-head"><span class="cs-chart-title">工单消耗排名 TOP10</span></div>
        <div v-if="orderRanking.length" class="cs-rank-list">
          <div v-for="(o, i) in orderRanking" :key="i" class="cs-rank-item">
            <span class="cs-rank-no">{{ i + 1 }}</span>
            <span class="cs-rank-name"><el-link type="primary" @click="goOrder(o)">{{ o.order_no }}</el-link></span>
            <span class="cs-rank-desc">{{ o.product_name }}</span>
            <span class="cs-rank-qty">{{ o.total_quantity }} 件 / {{ o.total_types }} 种</span>
            <span class="cs-rank-pct">{{ o.percentage }}%</span>
          </div>
        </div>
        <div v-else class="cs-empty">暂无消耗数据</div>
      </div>
    </div>

    <!-- 明细列表 -->
    <div class="cs-list-box">
      <div class="cs-chart-head"><span class="cs-chart-title">消耗明细</span></div>
      <el-table :data="list" v-loading="listLoading" size="small" border stripe empty-text="暂无消耗数据，请调整筛选条件。">
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column label="报工单号" width="160"><template slot-scope="s"><el-link type="primary" @click="goReport(s.row)">{{ s.row.report_no }}</el-link></template></el-table-column>
        <el-table-column prop="order_no" label="工单编号" width="140" show-overflow-tooltip />
        <el-table-column prop="product_name" label="产品名称" min-width="110" show-overflow-tooltip />
        <el-table-column prop="asset_name" label="配件名称" min-width="110" show-overflow-tooltip />
        <el-table-column prop="specification" label="规格型号" width="100" show-overflow-tooltip />
        <el-table-column label="消耗数量" width="90" align="right"><template slot-scope="s">{{ s.row.consume_quantity }} {{ s.row.unit }}</template></el-table-column>
        <el-table-column label="消耗时间" width="150"><template slot-scope="s">{{ String(s.row.created_at).slice(0, 16) }}</template></el-table-column>
      </el-table>
      <div class="cs-pagination">
        <el-pagination background layout="total, prev, pager, next" :total="total" :current-page="page" :page-size="limit" @current-change="handlePageChange" />
      </div>
    </div>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getConsumeStatsOverview, getConsumeStatsTrend, getConsumeStatsPartRanking, getConsumeStatsOrderRanking, getConsumeStatsCategory, getConsumeRecords } from '../../api/personalAssets'

export default {
  name: 'ConsumeStats',
  data () {
    return {
      showBanner: localStorage.getItem('cs_banner_closed') !== '1',
      timeDim: 'month',
      customRange: [],
      dateRange: { start: '', end: '' },
      granularity: 'day',
      overview: { total_count: 0, total_quantity: 0, total_types: 0, last_consume_time: '' },
      partRanking: [], orderRanking: [],
      trendLoading: false, categoryLoading: false, listLoading: false,
      charts: {},
      list: [], total: 0, page: 1, limit: 20
    }
  },
  created () {
    this.initDateRange()
    this.loadAll()
  },
  methods: {
    initDateRange () {
      const now = new Date()
      const y = now.getFullYear()
      const m = now.getMonth()
      const d = now.getDate()
      const fmt = dt => `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, '0')}-${String(dt.getDate()).padStart(2, '0')}`
      if (this.timeDim === 'today') { this.dateRange = { start: fmt(now), end: fmt(now) } }
      else if (this.timeDim === 'week') {
        const day = now.getDay() || 7
        const start = new Date(now); start.setDate(d - day + 1)
        this.dateRange = { start: fmt(start), end: fmt(now) }
      } else if (this.timeDim === 'month') {
        this.dateRange = { start: `${y}-${String(m + 1).padStart(2, '0')}-01`, end: fmt(now) }
      } else if (this.timeDim === 'year') {
        this.dateRange = { start: `${y}-01-01`, end: fmt(now) }
      } else if (this.customRange && this.customRange.length === 2) {
        this.dateRange = { start: this.customRange[0], end: this.customRange[1] }
      }
    },
    onTimeDimChange () {
      if (this.timeDim === 'custom') { this.customRange = []; return }
      this.initDateRange()
      this.loadAll()
    },
    handleQuery () {
      if (this.timeDim === 'custom') {
        if (!this.customRange || this.customRange.length !== 2) { this.$message.warning('请选择起止日期'); return }
        this.dateRange = { start: this.customRange[0], end: this.customRange[1] }
      }
      this.loadAll()
    },
    handleReset () {
      this.timeDim = 'month'
      this.customRange = []
      this.initDateRange()
      this.loadAll()
    },
    buildParams () {
      const p = {}
      if (this.dateRange.start) p.start_date = this.dateRange.start
      if (this.dateRange.end) p.end_date = this.dateRange.end
      return p
    },
    async loadAll () {
      this.loadOverview()
      this.loadTrend()
      this.loadCategory()
      this.loadRankings()
      this.loadList()
    },
    async loadOverview () {
      try { const r = await getConsumeStatsOverview(this.buildParams()); if (r.code === 0) this.overview = r.data } catch (e) {}
    },
    async loadTrend () {
      this.trendLoading = true
      try {
        const r = await getConsumeStatsTrend({ ...this.buildParams(), granularity: this.granularity })
        if (r.code === 0) this.renderTrend(r.data)
      } catch (e) {}
      this.trendLoading = false
    },
    async loadCategory () {
      this.categoryLoading = true
      try {
        const r = await getConsumeStatsCategory(this.buildParams())
        if (r.code === 0) this.renderCategory(r.data || [])
      } catch (e) {}
      this.categoryLoading = false
    },
    async loadRankings () {
      try {
        const [pr, or] = await Promise.all([
          getConsumeStatsPartRanking({ ...this.buildParams(), limit: 10 }),
          getConsumeStatsOrderRanking({ ...this.buildParams(), limit: 10 })
        ])
        if (pr.code === 0) this.partRanking = pr.data || []
        if (or.code === 0) this.orderRanking = or.data || []
      } catch (e) {}
    },
    async loadList () {
      this.listLoading = true
      try {
        const r = await getConsumeRecords({ ...this.buildParams(), page: this.page, limit: this.limit })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.listLoading = false
    },
    handlePageChange (p) { this.page = p; this.loadList() },
    renderTrend (data) {
      const el = this.$refs.trendChart
      if (!el) return
      if (!this.charts.trend) this.charts.trend = echarts.init(el)
      this.charts.trend.setOption({
        tooltip: { trigger: 'axis', axisPointer: { type: 'cross' } },
        legend: { data: ['消耗数量', '消耗次数'], top: 0, right: 0 },
        grid: { left: 60, right: 60, bottom: 30, top: 50 },
        xAxis: { type: 'category', data: data.dates || [], boundaryGap: true },
        yAxis: [
          { type: 'value', name: '消耗数量', position: 'left' },
          { type: 'value', name: '消耗次数', position: 'right', axisLabel: { formatter: '{value}次' } }
        ],
        series: [
          { name: '消耗数量', type: 'bar', data: data.quantities || [], color: '#409EFF', barWidth: '40%' },
          { name: '消耗次数', type: 'line', smooth: true, symbol: 'circle', symbolSize: 6, yAxisIndex: 1, color: '#E6A23C', data: data.counts || [] }
        ]
      }, true)
    },
    renderCategory (data) {
      const el = this.$refs.categoryChart
      if (!el) return
      if (!this.charts.category) this.charts.category = echarts.init(el)
      const colors = ['#409EFF', '#67C23A', '#E6A23C', '#9B59B6', '#F56C6C', '#50C8FF', '#FA8C16', '#00B578', '#2F54EB', '#EB2F96']
      this.charts.category.setOption({
        tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
        legend: { orient: 'vertical', right: 10, top: 'center', type: 'scroll' },
        color: colors,
        series: [{
          type: 'pie',
          radius: ['40%', '68%'],
          center: ['38%', '50%'],
          avoidLabelOverlap: true,
          itemStyle: { borderRadius: 6, borderColor: '#fff', borderWidth: 2 },
          label: { show: true, formatter: '{b}\n{d}%', fontSize: 11 },
          emphasis: { scale: true },
          data: data
        }]
      }, true)
    },
    goOrder (row) { this.$router.push('/production/plan/order/detail/' + row.order_id) },
    goReport (row) { this.$router.push('/production/report/detail/' + row.report_id) }
  },
  beforeDestroy () {
    Object.values(this.charts).forEach(c => { if (c) c.dispose() })
  }
}
</script>

<style scoped>
.cs-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.cs-breadcrumb { margin-bottom: 12px; }
.cs-banner { display: flex; align-items: center; background: #ecf5ff; border: 1px solid #d9ecff; border-radius: 4px; padding: 12px 16px; margin-bottom: 16px; }
.cs-banner-icon { color: #409EFF; font-size: 16px; margin-right: 8px; }
.cs-banner-text { flex: 1; font-size: 14px; color: #5a6b7f; }
.cs-banner-close { color: #909399; cursor: pointer; font-size: 14px; }
.cs-filter { background: #fff; border-radius: 8px; padding: 14px 16px; margin-bottom: 12px; display: flex; align-items: center; flex-wrap: wrap; }
.cs-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 16px; }
.cs-stat-card { background: #fff; border-radius: 8px; padding: 18px 20px; border: 1px solid #ebeef5; box-shadow: 0 2px 8px rgba(31,45,61,.04); display: flex; align-items: center; justify-content: space-between; }
.cs-stat-num { font-size: 22px; font-weight: 700; }
.cs-stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.cs-stat-icon { width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px; }
.cs-charts { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 16px; }
.cs-chart-box, .cs-rank-box, .cs-list-box { background: #fff; border-radius: 8px; padding: 16px; border: 1px solid #ebeef5; }
.cs-chart-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.cs-chart-title { font-size: 14px; font-weight: 600; color: #1f2d3d; }
.cs-chart { height: 320px; }
.cs-ranks { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 16px; }
.cs-rank-list { display: flex; flex-direction: column; gap: 8px; }
.cs-rank-item { display: flex; align-items: center; gap: 8px; font-size: 13px; }
.cs-rank-no { width: 28px; text-align: center; flex-shrink: 0; color: #909399; }
.cs-rank-name { width: 150px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; flex-shrink: 0; }
.cs-rank-desc { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: #909399; font-size: 12px; }
.cs-rank-bar { flex: 1; height: 8px; background: #f0f2f5; border-radius: 4px; overflow: hidden; }
.cs-rank-bar-inner { display: block; height: 100%; background: linear-gradient(90deg, #409EFF, #79bbff); border-radius: 4px; }
.cs-rank-qty { width: 90px; text-align: right; color: #1f2d3d; flex-shrink: 0; }
.cs-rank-pct { width: 50px; text-align: right; color: #909399; flex-shrink: 0; }
.cs-empty { text-align: center; color: #b0c0cc; padding: 40px 0; font-size: 13px; }
.cs-list-box { margin-bottom: 8px; }
.cs-pagination { display: flex; justify-content: flex-end; margin-top: 16px; }
</style>