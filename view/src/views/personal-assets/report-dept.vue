<template>
  <div class="rd-page">
    <el-breadcrumb separator="/" class="rd-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>报表统计</el-breadcrumb-item>
      <el-breadcrumb-item>部门资产汇总</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 提示横幅 -->
    <div v-if="showBanner" class="rd-banner">
      <i class="el-icon-info rd-banner-icon"></i>
      <span class="rd-banner-text">部门资产汇总：各部门资产分布与对比分析。帮助管理者了解各部门资产配置情况。</span>
      <i class="el-icon-close rd-banner-close" @click="showBanner = false; localStorage.setItem('rd_banner_closed', '1')"></i>
    </div>

    <!-- 筛选 -->
    <div class="rd-filter">
      <el-select v-model="year" size="small" style="width:120px">
        <el-option v-for="y in yearOptions" :key="y" :label="y + '年'" :value="y" />
      </el-select>
      <el-select v-if="isAdmin" v-model="deptFilter" size="small" clearable placeholder="全部部门" style="width:150px;margin-left:10px">
        <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
      </el-select>
      <el-button size="small" type="primary" icon="el-icon-search" style="margin-left:10px" @click="loadAll">查询</el-button>
      <el-button size="small" icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
      <el-button size="small" type="primary" icon="el-icon-download" :loading="exporting" style="margin-left:10px" @click="handleExport">导出报表</el-button>
    </div>

    <!-- 统计卡片 -->
    <div class="rd-stats">
      <div class="rd-stat-card"><div class="rd-stat-info"><div class="rd-stat-num" style="color:#409EFF">{{ overview.total_quantity }}</div><div class="rd-stat-label">总数量</div></div><div class="rd-stat-icon" style="background:#ecf5ff"><i class="el-icon-box" style="color:#409EFF"></i></div></div>
      <div class="rd-stat-card"><div class="rd-stat-info"><div class="rd-stat-num" style="color:#67C23A">{{ overview.total_types }}</div><div class="rd-stat-label">总种类</div></div><div class="rd-stat-icon" style="background:#f0f9eb"><i class="el-icon-document" style="color:#67C23A"></i></div></div>
      <div class="rd-stat-card"><div class="rd-stat-info"><div class="rd-stat-num" style="color:#E6A23C">¥{{ Number(overview.total_value).toLocaleString() }}</div><div class="rd-stat-label">总价值</div></div><div class="rd-stat-icon" style="background:#fdf6ec"><i class="el-icon-money" style="color:#E6A23C"></i></div></div>
      <div class="rd-stat-card"><div class="rd-stat-info"><div class="rd-stat-num" style="color:#9B59B6">{{ overview.dept_count }}</div><div class="rd-stat-label">覆盖部门</div></div><div class="rd-stat-icon" style="background:#f5f0fa"><i class="el-icon-office-building" style="color:#9B59B6"></i></div></div>
    </div>

    <!-- 图表区 -->
    <div class="rd-charts">
      <div class="rd-chart-box">
        <div class="rd-chart-head">
          <span class="rd-chart-title">部门资产排行</span>
          <el-radio-group v-model="rankSort" size="mini" @change="loadRanking">
            <el-radio-button label="quantity">按数量</el-radio-button>
            <el-radio-button label="value">按价值</el-radio-button>
          </el-radio-group>
        </div>
        <div ref="rankChart" class="rd-chart" />
      </div>
      <div class="rd-chart-box">
        <div class="rd-chart-title">部门资产类型分布</div>
        <div ref="typeChart" class="rd-chart" />
      </div>
    </div>

    <!-- 对比表 -->
    <div class="rd-list-box">
      <div class="rd-chart-title">部门资产对比</div>
      <el-table :data="comparison" size="small" border stripe empty-text="暂无部门资产数据">
        <el-table-column prop="rank" label="排名" width="60" align="center" />
        <el-table-column prop="department_name" label="部门名称" min-width="140" show-overflow-tooltip />
        <el-table-column prop="employee_count" label="员工人数" width="90" align="right" />
        <el-table-column prop="total_quantity" label="资产数量" width="100" align="right" />
        <el-table-column prop="total_types" label="资产种类" width="90" align="right" />
        <el-table-column label="资产价值" width="120" align="right"><template slot-scope="s">¥{{ Number(s.row.total_value).toLocaleString() }}</template></el-table-column>
        <el-table-column prop="avg_per_person" label="人均数量" width="90" align="right" />
        <el-table-column prop="part_count" label="配件数" width="80" align="right" />
        <el-table-column prop="asset_count" label="固定资产数" width="100" align="right" />
        <el-table-column prop="tool_count" label="工具数" width="80" align="right" />
        <el-table-column label="操作" width="100" align="center">
          <template slot-scope="s"><el-button type="text" size="mini" @click="goDept(s.row)">查看详情</el-button></template>
        </el-table-column>
      </el-table>
    </div>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getReportDeptOverview, getReportDeptRanking, getReportDeptTypeDistribution, getReportDeptComparison, exportReportDept } from '../../api/personalAssets'
import { getAssetDepartments } from '../../api/personalAssets'

export default {
  name: 'ReportDept',
  data () {
    const currentYear = new Date().getFullYear()
    return {
      showBanner: localStorage.getItem('rd_banner_closed') !== '1',
      year: currentYear,
      yearOptions: [currentYear, currentYear - 1, currentYear - 2, currentYear - 3],
      deptFilter: '',
      isAdmin: true,
      deptOptions: [],
      overview: { total_quantity: 0, total_types: 0, total_value: 0, dept_count: 0 },
      ranking: [], rankSort: 'quantity',
      comparison: [],
      exporting: false,
      charts: {}
    }
  },
  created () {
    this.loadOptions()
    this.loadAll()
  },
  methods: {
    buildParams () {
      const p = { year: this.year }
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
      this.loadRanking()
      this.loadType()
      this.loadComparison()
    },
    handleReset () {
      this.year = new Date().getFullYear()
      this.deptFilter = ''
      this.loadAll()
    },
    async loadOverview () {
      try { const r = await getReportDeptOverview(this.buildParams()); if (r.code === 0) this.overview = r.data } catch (e) {}
    },
    async loadRanking () {
      try {
        const r = await getReportDeptRanking({ ...this.buildParams(), sort_field: this.rankSort, limit: 10 })
        if (r.code === 0) { this.ranking = r.data || []; this.renderRanking() }
      } catch (e) {}
    },
    async loadType () {
      try {
        const r = await getReportDeptTypeDistribution(this.buildParams())
        if (r.code === 0) this.renderType(r.data || [])
      } catch (e) {}
    },
    async loadComparison () {
      try {
        const r = await getReportDeptComparison(this.buildParams())
        if (r.code === 0) this.comparison = r.data || []
      } catch (e) {}
    },
    renderRanking () {
      const el = this.$refs.rankChart
      if (!el) return
      if (!this.charts.rank) this.charts.rank = echarts.init(el)
      const data = this.ranking.slice().reverse()
      this.charts.rank.setOption({
        tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
        grid: { left: 90, right: 50, top: 20, bottom: 30 },
        xAxis: { type: 'value', name: this.rankSort === 'value' ? '资产价值' : '资产数量' },
        yAxis: { type: 'category', data: data.map(d => d.department_name) },
        series: [{
          type: 'bar',
          barWidth: '50%',
          itemStyle: { color: '#409EFF', borderRadius: [0, 4, 4, 0] },
          label: { show: true, position: 'right', formatter: (p) => this.rankSort === 'value' ? '¥' + Number(p.value).toLocaleString() : p.value },
          data: data.map(d => this.rankSort === 'value' ? d.total_value : d.total_quantity)
        }]
      }, true)
    },
    renderType (data) {
      const el = this.$refs.typeChart
      if (!el) return
      if (!this.charts.type) this.charts.type = echarts.init(el)
      const names = data.map(d => d.department_name)
      this.charts.type.setOption({
        tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
        legend: { data: ['配件', '固定资产', '工具'], top: 0 },
        grid: { left: 50, right: 20, bottom: 30, top: 40 },
        xAxis: { type: 'category', data: names, axisLabel: { interval: 0, rotate: 30 } },
        yAxis: { type: 'value', name: '数量' },
        series: [
          { name: '配件', type: 'bar', stack: 'total', color: '#E6A23C', data: data.map(d => d.parts) },
          { name: '固定资产', type: 'bar', stack: 'total', color: '#409EFF', data: data.map(d => d.assets) },
          { name: '工具', type: 'bar', stack: 'total', color: '#9B59B6', data: data.map(d => d.tools) }
        ]
      }, true)
    },
    async handleExport () {
      this.exporting = true
      try {
        const res = await exportReportDept(this.buildParams())
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('导出失败'); return }
        const url = window.URL.createObjectURL(new Blob([blob]))
        const a = document.createElement('a')
        a.href = url
        a.download = '部门资产汇总_' + new Date().toISOString().slice(0, 10) + '.xlsx'
        a.click()
        window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') }
      this.exporting = false
    },
    goDept (row) {
      this.$router.push('/personal-assets/dept-list')
    }
  },
  beforeDestroy () {
    Object.values(this.charts).forEach(c => { if (c) c.dispose() })
  }
}
</script>

<style scoped>
.rd-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.rd-breadcrumb { margin-bottom: 12px; }
.rd-banner { display: flex; align-items: center; background: #ecf5ff; border: 1px solid #d9ecff; border-radius: 4px; padding: 12px 16px; margin-bottom: 16px; }
.rd-banner-icon { color: #409EFF; font-size: 16px; margin-right: 8px; }
.rd-banner-text { flex: 1; font-size: 14px; color: #5a6b7f; }
.rd-banner-close { color: #909399; cursor: pointer; font-size: 14px; }
.rd-filter { background: #fff; border-radius: 8px; padding: 14px 16px; margin-bottom: 12px; display: flex; align-items: center; }
.rd-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 16px; }
.rd-stat-card { background: #fff; border-radius: 8px; padding: 18px 20px; border: 1px solid #ebeef5; box-shadow: 0 2px 8px rgba(31,45,61,.04); display: flex; align-items: center; justify-content: space-between; }
.rd-stat-num { font-size: 22px; font-weight: 700; }
.rd-stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.rd-stat-icon { width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px; }
.rd-charts { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 16px; }
.rd-chart-box { background: #fff; border-radius: 8px; padding: 16px; border: 1px solid #ebeef5; }
.rd-chart-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.rd-chart-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 12px; }
.rd-chart { height: 320px; }
.rd-list-box { background: #fff; border-radius: 8px; padding: 16px; border: 1px solid #ebeef5; }
</style>