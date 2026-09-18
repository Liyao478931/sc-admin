<template>
  <div class="rp-page">
    <el-breadcrumb separator="/" class="rp-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>报表统计</el-breadcrumb-item>
      <el-breadcrumb-item>个人资产报表</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 提示横幅 -->
    <div v-if="showBanner" class="rp-banner">
      <i class="el-icon-info rp-banner-icon"></i>
      <span class="rp-banner-text">个人资产报表：个人名下资产的全面统计分析。数据来源于您的领用、调拨、消耗和退还记录。</span>
      <i class="el-icon-close rp-banner-close" @click="showBanner = false; localStorage.setItem('rp_banner_closed', '1')"></i>
    </div>

    <!-- 时间筛选 -->
    <div class="rp-filter">
      <el-select v-model="year" size="small" style="width:120px">
        <el-option v-for="y in yearOptions" :key="y" :label="y + '年'" :value="y" />
      </el-select>
      <el-button size="small" type="primary" icon="el-icon-search" style="margin-left:10px" @click="loadAll">查询</el-button>
      <el-button size="small" icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
      <el-button size="small" type="primary" icon="el-icon-download" :loading="exporting" style="margin-left:10px" @click="handleExport">导出报表</el-button>
    </div>

    <!-- 统计卡片 -->
    <div class="rp-stats">
      <div class="rp-stat-card"><div class="rp-stat-info"><div class="rp-stat-num" style="color:#409EFF">{{ overview.total_quantity }}</div><div class="rp-stat-label">总数量</div></div><div class="rp-stat-icon" style="background:#ecf5ff"><i class="el-icon-box" style="color:#409EFF"></i></div></div>
      <div class="rp-stat-card"><div class="rp-stat-info"><div class="rp-stat-num" style="color:#67C23A">{{ overview.total_types }}</div><div class="rp-stat-label">总种类</div></div><div class="rp-stat-icon" style="background:#f0f9eb"><i class="el-icon-document" style="color:#67C23A"></i></div></div>
      <div class="rp-stat-card"><div class="rp-stat-info"><div class="rp-stat-num" style="color:#E6A23C">¥{{ Number(overview.total_value).toLocaleString() }}</div><div class="rp-stat-label">总价值</div></div><div class="rp-stat-icon" style="background:#fdf6ec"><i class="el-icon-money" style="color:#E6A23C"></i></div></div>
      <div class="rp-stat-card"><div class="rp-stat-info"><div class="rp-stat-num" style="color:#9B59B6;font-size:16px">正常{{ overview.status_distribution ? overview.status_distribution.normal : 0 }} · 维修{{ overview.status_distribution ? overview.status_distribution.repairing : 0 }} · 闲置{{ overview.status_distribution ? overview.status_distribution.idle : 0 }}</div><div class="rp-stat-label">状态分布</div></div><div class="rp-stat-icon" style="background:#f5f0fa"><i class="el-icon-data-analysis" style="color:#9B59B6"></i></div></div>
    </div>

    <!-- 图表区 -->
    <div class="rp-charts">
      <div class="rp-chart-box">
        <div class="rp-chart-title">资产类型分布</div>
        <div ref="typeChart" class="rp-chart" />
      </div>
      <div class="rp-chart-box">
        <div class="rp-chart-title">资产状态分布</div>
        <div ref="statusChart" class="rp-chart" />
      </div>
    </div>

    <!-- 趋势图 -->
    <div class="rp-chart-box rp-trend-box">
      <div class="rp-chart-title">月度资产变动趋势</div>
      <div ref="trendChart" class="rp-chart rp-trend-chart" />
    </div>

    <!-- 明细列表 -->
    <div class="rp-list-box">
      <div class="rp-chart-title">资产明细</div>
      <el-table :data="list" v-loading="listLoading" size="small" border stripe empty-text="暂无个人资产数据">
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column prop="asset_name" label="资产名称" min-width="120" show-overflow-tooltip />
        <el-table-column prop="specification" label="规格型号" width="110" show-overflow-tooltip />
        <el-table-column prop="asset_code" label="资产编码" width="120" show-overflow-tooltip />
        <el-table-column prop="asset_type_label" label="资产类型" width="90" align="center" />
        <el-table-column label="数量" width="70" align="right"><template slot-scope="s">{{ s.row.quantity }}</template></el-table-column>
        <el-table-column prop="unit" label="单位" width="55" align="center" />
        <el-table-column prop="asset_status_label" label="状态" width="80" align="center" />
        <el-table-column prop="source_type_label" label="来源" width="90" align="center" />
        <el-table-column label="入库时间" width="140"><template slot-scope="s">{{ String(s.row.created_at).slice(0, 16) }}</template></el-table-column>
      </el-table>
      <div class="rp-pagination">
        <el-pagination background layout="total, prev, pager, next" :total="total" :current-page="page" :page-size="limit" @current-change="handlePageChange" />
      </div>
    </div>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getReportPersonalOverview, getReportTypeDistribution, getReportStatusDistribution, getReportPersonalTrend, getReportPersonalDetail, exportReportPersonal } from '../../api/personalAssets'

export default {
  name: 'ReportPersonal',
  data () {
    const currentYear = new Date().getFullYear()
    return {
      showBanner: localStorage.getItem('rp_banner_closed') !== '1',
      year: currentYear,
      yearOptions: [currentYear, currentYear - 1, currentYear - 2, currentYear - 3],
      overview: { total_quantity: 0, total_types: 0, total_value: 0, status_distribution: {} },
      list: [], total: 0, page: 1, limit: 20, listLoading: false, exporting: false,
      charts: {}
    }
  },
  created () { this.loadAll() },
  methods: {
    buildParams () { return { year: this.year } },
    async loadAll () {
      this.loadOverview()
      this.loadType()
      this.loadStatus()
      this.loadTrend()
      this.loadList()
    },
    handleReset () {
      this.year = new Date().getFullYear()
      this.loadAll()
    },
    async loadOverview () {
      try { const r = await getReportPersonalOverview(this.buildParams()); if (r.code === 0) this.overview = r.data } catch (e) {}
    },
    async loadType () {
      try {
        const r = await getReportTypeDistribution(this.buildParams())
        if (r.code === 0) this.renderType(r.data || [])
      } catch (e) {}
    },
    async loadStatus () {
      try {
        const r = await getReportStatusDistribution(this.buildParams())
        if (r.code === 0) this.renderStatus(r.data || [])
      } catch (e) {}
    },
    async loadTrend () {
      try {
        const r = await getReportPersonalTrend(this.buildParams())
        if (r.code === 0) this.renderTrend(r.data)
      } catch (e) {}
    },
    async loadList () {
      this.listLoading = true
      try {
        const r = await getReportPersonalDetail({ ...this.buildParams(), page: this.page, limit: this.limit })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.listLoading = false
    },
    handlePageChange (p) { this.page = p; this.loadList() },
    renderType (data) {
      const el = this.$refs.typeChart
      if (!el) return
      if (!this.charts.type) this.charts.type = echarts.init(el)
      const colors = { 1: '#E6A23C', 2: '#409EFF', 3: '#9B59B6' }
      this.charts.type.setOption({
        tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
        legend: { orient: 'vertical', right: 10, top: 'center' },
        series: [{
          type: 'pie',
          radius: ['40%', '68%'],
          center: ['42%', '50%'],
          itemStyle: { borderRadius: 6, borderColor: '#fff', borderWidth: 2 },
          label: { formatter: '{b}\n{d}%' },
          emphasis: { scale: true },
          data: data.map(d => ({ name: d.type_label, value: d.quantity, itemStyle: { color: colors[d.type] } }))
        }]
      }, true)
    },
    renderStatus (data) {
      const el = this.$refs.statusChart
      if (!el) return
      if (!this.charts.status) this.charts.status = echarts.init(el)
      const colors = { 1: '#67C23A', 2: '#E6A23C', 3: '#909399', 4: '#F56C6C', 5: '#A0A0A0' }
      this.charts.status.setOption({
        tooltip: { trigger: 'axis' },
        grid: { left: 40, right: 20, bottom: 30, top: 30 },
        xAxis: { type: 'category', data: data.map(d => d.status_label) },
        yAxis: { type: 'value', name: '数量' },
        series: [{
          type: 'bar',
          barWidth: '50%',
          data: data.map(d => ({ value: d.quantity, itemStyle: { color: colors[d.status] || '#409EFF' } }))
        }]
      }, true)
    },
    renderTrend (data) {
      const el = this.$refs.trendChart
      if (!el) return
      if (!this.charts.trend) this.charts.trend = echarts.init(el)
      const labels = (data.months || []).map(m => m + '月')
      this.charts.trend.setOption({
        tooltip: { trigger: 'axis' },
        legend: { data: ['领用', '消耗', '调拨', '退还'], top: 0 },
        grid: { left: 50, right: 20, bottom: 30, top: 40 },
        xAxis: { type: 'category', data: labels },
        yAxis: { type: 'value', name: '数量' },
        series: [
          { name: '领用', type: 'line', smooth: true, symbol: 'circle', symbolSize: 6, color: '#409EFF', data: data.pick || [] },
          { name: '消耗', type: 'line', smooth: true, symbol: 'circle', symbolSize: 6, color: '#67C23A', data: data.consume || [] },
          { name: '调拨', type: 'line', smooth: true, symbol: 'circle', symbolSize: 6, color: '#E6A23C', data: data.transfer || [] },
          { name: '退还', type: 'line', smooth: true, symbol: 'circle', symbolSize: 6, color: '#F56C6C', data: data.return || [] }
        ]
      }, true)
    },
    async handleExport () {
      this.exporting = true
      try {
        const res = await exportReportPersonal({ year: this.year })
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('导出失败'); return }
        const url = window.URL.createObjectURL(new Blob([blob]))
        const a = document.createElement('a')
        a.href = url
        a.download = '个人资产报表_' + this.year + '.xlsx'
        a.click()
        window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') }
      this.exporting = false
    }
  },
  beforeDestroy () {
    Object.values(this.charts).forEach(c => { if (c) c.dispose() })
  }
}
</script>

<style scoped>
.rp-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.rp-breadcrumb { margin-bottom: 12px; }
.rp-banner { display: flex; align-items: center; background: #ecf5ff; border: 1px solid #d9ecff; border-radius: 4px; padding: 12px 16px; margin-bottom: 16px; }
.rp-banner-icon { color: #409EFF; font-size: 16px; margin-right: 8px; }
.rp-banner-text { flex: 1; font-size: 14px; color: #5a6b7f; }
.rp-banner-close { color: #909399; cursor: pointer; font-size: 14px; }
.rp-filter { background: #fff; border-radius: 8px; padding: 14px 16px; margin-bottom: 12px; display: flex; align-items: center; }
.rp-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 16px; }
.rp-stat-card { background: #fff; border-radius: 8px; padding: 18px 20px; border: 1px solid #ebeef5; box-shadow: 0 2px 8px rgba(31,45,61,.04); display: flex; align-items: center; justify-content: space-between; }
.rp-stat-num { font-size: 22px; font-weight: 700; }
.rp-stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.rp-stat-icon { width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px; }
.rp-charts { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 16px; }
.rp-chart-box { background: #fff; border-radius: 8px; padding: 16px; border: 1px solid #ebeef5; }
.rp-trend-box { margin-bottom: 16px; }
.rp-chart-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 12px; }
.rp-chart { height: 300px; }
.rp-trend-chart { height: 320px; }
.rp-list-box { background: #fff; border-radius: 8px; padding: 16px; border: 1px solid #ebeef5; }
.rp-pagination { display: flex; justify-content: flex-end; margin-top: 16px; }
</style>