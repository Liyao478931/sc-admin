<template>
  <div class="rt-page">
    <el-breadcrumb separator="/" class="rt-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>报表统计</el-breadcrumb-item>
      <el-breadcrumb-item>调拨统计报表</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 提示横幅 -->
    <div v-if="showBanner" class="rt-banner">
      <i class="el-icon-info rt-banner-icon"></i>
      <span class="rt-banner-text">调拨统计报表：资产调拨多维度统计分析。帮助了解资产流转趋势和调拨行为。</span>
      <i class="el-icon-close rt-banner-close" @click="showBanner = false; localStorage.setItem('rt_banner_closed', '1')"></i>
    </div>

    <!-- 筛选 -->
    <div class="rt-filter">
      <el-select v-model="year" size="small" style="width:110px">
        <el-option v-for="y in yearOptions" :key="y" :label="y + '年'" :value="y" />
      </el-select>
      <el-date-picker v-model="customRange" type="daterange" value-format="yyyy-MM-dd" range-separator="~" start-placeholder="开始" end-placeholder="结束" size="small" style="width:230px;margin-left:10px" />
      <el-select v-if="isAdmin" v-model="deptFilter" size="small" clearable placeholder="全部部门" style="width:140px;margin-left:10px">
        <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
      </el-select>
      <el-button size="small" type="primary" icon="el-icon-search" style="margin-left:10px" @click="loadAll">查询</el-button>
      <el-button size="small" icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
      <el-button size="small" type="primary" icon="el-icon-download" :loading="exporting" style="margin-left:10px" @click="handleExport">导出报表</el-button>
    </div>

    <!-- 统计卡片 -->
    <div class="rt-stats">
      <div class="rt-stat-card"><div class="rt-stat-info"><div class="rt-stat-num" style="color:#409EFF">{{ overview.total_count }}</div><div class="rt-stat-label">总调拨</div></div><div class="rt-stat-icon" style="background:#ecf5ff"><i class="el-icon-document" style="color:#409EFF"></i></div></div>
      <div class="rt-stat-card"><div class="rt-stat-info"><div class="rt-stat-num" style="color:#67C23A">{{ overview.total_quantity }}</div><div class="rt-stat-label">总数量</div></div><div class="rt-stat-icon" style="background:#f0f9eb"><i class="el-icon-box" style="color:#67C23A"></i></div></div>
      <div class="rt-stat-card"><div class="rt-stat-info"><div class="rt-stat-num" style="color:#E6A23C">{{ overview.involved_employees }}</div><div class="rt-stat-label">涉及员工</div></div><div class="rt-stat-icon" style="background:#fdf6ec"><i class="el-icon-user" style="color:#E6A23C"></i></div></div>
      <div class="rt-stat-card"><div class="rt-stat-info"><div class="rt-stat-num" style="color:#9B59B6">{{ overview.involved_assets }}</div><div class="rt-stat-label">涉及资产</div></div><div class="rt-stat-icon" style="background:#f5f0fa"><i class="el-icon-setting" style="color:#9B59B6"></i></div></div>
    </div>

    <!-- 图表区 -->
    <div class="rt-charts">
      <div class="rt-chart-box">
        <div class="rt-chart-title">调拨趋势</div>
        <div ref="trendChart" class="rt-chart" />
      </div>
      <div class="rt-chart-box">
        <div class="rt-chart-title">调拨类型分布</div>
        <div ref="typeChart" class="rt-chart" />
      </div>
    </div>

    <!-- 排行区 -->
    <div class="rt-ranks">
      <div class="rt-rank-box">
        <div class="rt-chart-title">调出排行 TOP10</div>
        <div v-if="sourceRanking.length" class="rt-rank-list">
          <div v-for="(p, i) in sourceRanking" :key="i" class="rt-rank-item">
            <span class="rt-rank-no">{{ i < 3 ? ['🥇', '🥈', '🥉'][i] : i + 1 }}</span>
            <span class="rt-rank-name">{{ p.user_name }}{{ p.department ? '（' + p.department + '）' : '' }}</span>
            <span class="rt-rank-qty">调出 {{ p.transfer_quantity }} 件 / {{ p.transfer_count }} 次</span>
          </div>
        </div>
        <div v-else class="rt-empty">暂无调拨数据</div>
      </div>
      <div class="rt-rank-box">
        <div class="rt-chart-title">调入排行 TOP10</div>
        <div v-if="targetRanking.length" class="rt-rank-list">
          <div v-for="(p, i) in targetRanking" :key="i" class="rt-rank-item">
            <span class="rt-rank-no">{{ i < 3 ? ['🥇', '🥈', '🥉'][i] : i + 1 }}</span>
            <span class="rt-rank-name">{{ p.user_name }}{{ p.department ? '（' + p.department + '）' : '' }}</span>
            <span class="rt-rank-qty">调入 {{ p.transfer_quantity }} 件 / {{ p.transfer_count }} 次</span>
          </div>
        </div>
        <div v-else class="rt-empty">暂无调拨数据</div>
      </div>
    </div>

    <!-- 明细列表 -->
    <div class="rt-list-box">
      <div class="rt-chart-title">调拨明细</div>
      <el-table :data="list" v-loading="listLoading" size="small" border stripe empty-text="暂无调拨数据">
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column prop="transfer_no" label="调拨单号" width="150" />
        <el-table-column prop="transfer_type_label" label="类型" width="90" align="center" />
        <el-table-column prop="asset_name" label="资产名称" min-width="110" show-overflow-tooltip />
        <el-table-column prop="specification" label="规格型号" width="100" show-overflow-tooltip />
        <el-table-column prop="from_name" label="调出人" width="80" />
        <el-table-column prop="to_name" label="调入人" width="80" />
        <el-table-column label="数量" width="80" align="right"><template slot-scope="s">{{ s.row.transfer_quantity }} {{ s.row.unit }}</template></el-table-column>
        <el-table-column label="调拨时间" width="150"><template slot-scope="s">{{ String(s.row.created_at).slice(0, 16) }}</template></el-table-column>
      </el-table>
      <div class="rt-pagination">
        <el-pagination background layout="total, prev, pager, next" :total="total" :current-page="page" :page-size="limit" @current-change="handlePageChange" />
      </div>
    </div>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getReportTransferOverview, getReportTransferTrend, getReportTransferType, getReportTransferSource, getReportTransferTarget, getReportTransferDetail, exportReportTransfer } from '../../api/personalAssets'
import { getAssetDepartments } from '../../api/personalAssets'

export default {
  name: 'ReportTransfer',
  data () {
    const currentYear = new Date().getFullYear()
    return {
      showBanner: localStorage.getItem('rt_banner_closed') !== '1',
      year: currentYear,
      yearOptions: [currentYear, currentYear - 1, currentYear - 2, currentYear - 3],
      customRange: [],
      deptFilter: '',
      isAdmin: true,
      deptOptions: [],
      overview: { total_count: 0, total_quantity: 0, involved_employees: 0, involved_assets: 0 },
      sourceRanking: [], targetRanking: [],
      list: [], total: 0, page: 1, limit: 20, listLoading: false, exporting: false,
      charts: {}
    }
  },
  created () {
    this.loadOptions()
    this.loadAll()
  },
  methods: {
    buildParams () {
      const p = {}
      if (this.customRange && this.customRange.length === 2) {
        p.start_date = this.customRange[0]
        p.end_date = this.customRange[1]
      } else {
        p.year = this.year
      }
      if (this.deptFilter) p.department_id = this.deptFilter
      return p
    },
    async loadOptions () {
      try {
        const r = await getAssetDepartments()
        if (r.code === 0) this.deptOptions = r.data || []
      } catch (e) {}
    },
    async loadAll () {
      this.loadOverview()
      this.loadTrend()
      this.loadType()
      this.loadRankings()
      this.loadList()
    },
    handleReset () {
      this.year = new Date().getFullYear()
      this.customRange = []
      this.deptFilter = ''
      this.loadAll()
    },
    async loadOverview () {
      try { const r = await getReportTransferOverview(this.buildParams()); if (r.code === 0) this.overview = r.data } catch (e) {}
    },
    async loadTrend () {
      try {
        const r = await getReportTransferTrend(this.buildParams())
        if (r.code === 0) this.renderTrend(r.data)
      } catch (e) {}
    },
    async loadType () {
      try {
        const r = await getReportTransferType(this.buildParams())
        if (r.code === 0) this.renderType(r.data || [])
      } catch (e) {}
    },
    async loadRankings () {
      try {
        const [s, t] = await Promise.all([
          getReportTransferSource(this.buildParams()),
          getReportTransferTarget(this.buildParams())
        ])
        if (s.code === 0) this.sourceRanking = s.data || []
        if (t.code === 0) this.targetRanking = t.data || []
      } catch (e) {}
    },
    async loadList () {
      this.listLoading = true
      try {
        const r = await getReportTransferDetail({ ...this.buildParams(), page: this.page, limit: this.limit })
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
        tooltip: { trigger: 'axis' },
        grid: { left: 50, right: 20, bottom: 30, top: 30 },
        xAxis: { type: 'category', data: (data.months || []).map(m => m + '月') },
        yAxis: { type: 'value', name: '数量' },
        series: [{ name: '调拨数量', type: 'line', smooth: true, symbol: 'circle', symbolSize: 6, color: '#409EFF', data: data.quantities || [], areaStyle: { opacity: 0.1 } }]
      }, true)
    },
    renderType (data) {
      const el = this.$refs.typeChart
      if (!el) return
      if (!this.charts.type) this.charts.type = echarts.init(el)
      const colors = { 1: '#409EFF', 2: '#E6A23C' }
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
          data: data.map(d => ({ name: d.type_label, value: d.count, itemStyle: { color: colors[d.type] } }))
        }]
      }, true)
    },
    async handleExport () {
      this.exporting = true
      try {
        const res = await exportReportTransfer(this.buildParams())
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('导出失败'); return }
        const url = window.URL.createObjectURL(new Blob([blob]))
        const a = document.createElement('a')
        a.href = url
        a.download = '调拨统计报表_' + new Date().toISOString().slice(0, 10) + '.xlsx'
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
.rt-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.rt-breadcrumb { margin-bottom: 12px; }
.rt-banner { display: flex; align-items: center; background: #ecf5ff; border: 1px solid #d9ecff; border-radius: 4px; padding: 12px 16px; margin-bottom: 16px; }
.rt-banner-icon { color: #409EFF; font-size: 16px; margin-right: 8px; }
.rt-banner-text { flex: 1; font-size: 14px; color: #5a6b7f; }
.rt-banner-close { color: #909399; cursor: pointer; font-size: 14px; }
.rt-filter { background: #fff; border-radius: 8px; padding: 14px 16px; margin-bottom: 12px; display: flex; align-items: center; flex-wrap: wrap; }
.rt-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 16px; }
.rt-stat-card { background: #fff; border-radius: 8px; padding: 18px 20px; border: 1px solid #ebeef5; box-shadow: 0 2px 8px rgba(31,45,61,.04); display: flex; align-items: center; justify-content: space-between; }
.rt-stat-num { font-size: 22px; font-weight: 700; }
.rt-stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.rt-stat-icon { width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px; }
.rt-charts { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 16px; }
.rt-chart-box { background: #fff; border-radius: 8px; padding: 16px; border: 1px solid #ebeef5; }
.rt-chart-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 12px; }
.rt-chart { height: 300px; }
.rt-ranks { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 16px; }
.rt-rank-box { background: #fff; border-radius: 8px; padding: 16px; border: 1px solid #ebeef5; }
.rt-rank-list { display: flex; flex-direction: column; gap: 8px; }
.rt-rank-item { display: flex; align-items: center; gap: 8px; font-size: 13px; }
.rt-rank-no { width: 28px; text-align: center; flex-shrink: 0; }
.rt-rank-name { flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.rt-rank-qty { color: #606266; flex-shrink: 0; }
.rt-empty { text-align: center; color: #b0c0cc; padding: 40px 0; font-size: 13px; }
.rt-list-box { background: #fff; border-radius: 8px; padding: 16px; border: 1px solid #ebeef5; }
.rt-pagination { display: flex; justify-content: flex-end; margin-top: 16px; }
</style>