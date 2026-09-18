<!--
  文件：admin/src/views/hr/salary/statistics/Index.vue
  功能：薪酬统计（统计卡片 / 月度趋势·部门分布·工资构成·职级对比图表 / 明细分页 / 员工薪酬详情抽屉 / 导出）
  权限：hr:salary:statistics:view / export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>薪酬管理</el-breadcrumb-item>
      <el-breadcrumb-item>薪酬统计</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 筛选条件区域 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="统计年份">
          <el-select v-model="query.year" style="width:110px">
            <el-option v-for="y in yearOptions" :key="y" :label="y + ' 年'" :value="y" />
          </el-select>
        </el-form-item>
        <el-form-item label="月份范围">
          <el-date-picker v-model="query.monthRange" type="monthrange" value-format="yyyy-MM" range-separator="至" start-placeholder="开始月份" end-placeholder="结束月份" style="width:260px" />
        </el-form-item>
        <el-form-item label="部门">
          <el-select v-model="query.department_id" multiple filterable clearable placeholder="全部" style="width:180px">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="员工类型">
          <el-select v-model="query.employee_type" clearable placeholder="全部" style="width:120px">
            <el-option label="车间岗位工" :value="1" />
            <el-option label="科员" :value="2" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">查询</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 统计卡片区域 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="6">
        <div class="stat-card stat-blue" @click="openComposeDialog">
          <div class="stat-icon"><i class="el-icon-money" /></div>
          <div class="stat-info"><div class="stat-num">¥ {{ fmt(cards.total_salary) }}</div><div class="stat-label">薪酬总额（点击查看构成）</div></div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-green">
          <div class="stat-icon"><i class="el-icon-data-line" /></div>
          <div class="stat-info"><div class="stat-num" style="color:#67C23A">¥ {{ fmt(cards.avg_salary) }}</div><div class="stat-label">平均薪酬</div></div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-orange" @click="openPeopleDialog">
          <div class="stat-icon"><i class="el-icon-user" /></div>
          <div class="stat-info"><div class="stat-num" style="color:#E6A23C">{{ cards.employee_count }} <span class="stat-unit">人</span></div><div class="stat-label">总人数（点击查看人员）</div></div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-purple">
          <div class="stat-icon"><i class="el-icon-trophy" /></div>
          <div class="stat-info"><div class="stat-num" style="color:#9B59B6">¥ {{ fmt(cards.max_salary) }}</div><div class="stat-label">最高薪酬（{{ cards.max_user_name || '-' }}）</div></div>
        </div>
      </el-col>
    </el-row>

    <!-- 图表区域 -->
    <el-card class="chart-card" shadow="never">
      <div slot="header" class="chart-header">
        <span class="chart-title">薪酬分析</span>
        <el-button type="text" icon="el-icon-refresh" @click="loadData">刷新图表</el-button>
      </div>
      <el-row :gutter="16">
        <el-col :span="12"><div ref="trendChart" class="chart-box" /></el-col>
        <el-col :span="12"><div ref="deptChart" class="chart-box" /></el-col>
        <el-col :span="12"><div ref="composeChart" class="chart-box" /></el-col>
        <el-col :span="12"><div ref="rankChart" class="chart-box" /></el-col>
      </el-row>
    </el-card>

    <!-- 操作按钮栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'hr:salary:statistics:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出报表</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条记录</span>
    </div>

    <!-- 明细数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无薪酬数据（需先在工资计算中确认工资）">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column prop="calc_month" label="工资月份" width="120" align="center" />
      <el-table-column prop="user_name" label="员工姓名" width="90" />
      <el-table-column prop="department_name" label="部门" width="120" show-overflow-tooltip />
      <el-table-column prop="rank_name" label="职级" width="100" show-overflow-tooltip />
      <el-table-column label="员工类型" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.employee_type === 1 ? 'primary' : 'info'" size="mini">{{ s.row.employee_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="基本工资" width="120" align="right"><template slot-scope="s">¥ {{ fmt(s.row.base_salary) }}</template></el-table-column>
      <el-table-column label="计件工资" width="120" align="right"><template slot-scope="s">{{ s.row.employee_type === 1 ? '¥ ' + fmt(s.row.piecework_wage) : '-' }}</template></el-table-column>
      <el-table-column label="津贴合计" width="110" align="right"><template slot-scope="s">¥ {{ fmt(s.row.allowance_total) }}</template></el-table-column>
      <el-table-column label="扣款合计" width="110" align="right"><template slot-scope="s">¥ {{ fmt(s.row.deduction_total) }}</template></el-table-column>
      <el-table-column label="应发工资" width="120" align="right"><template slot-scope="s">¥ {{ fmt(s.row.gross_salary) }}</template></el-table-column>
      <el-table-column label="实发工资" width="120" align="right"><template slot-scope="s"><b style="color:#67C23A">¥ {{ fmt(s.row.net_salary) }}</b></template></el-table-column>
      <el-table-column label="操作" width="120" align="center" fixed="right">
        <template slot-scope="s"><el-button type="text" size="mini" @click="openDetail(s.row)">查看详情</el-button></template>
      </el-table-column>
    </el-table>

    <!-- 分页组件 -->
    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 工资构成明细对话框 -->
    <el-dialog title="薪酬构成明细" :visible.sync="composeVisible" width="480px" append-to-body>
      <el-table :data="compose" size="small" border>
        <el-table-column prop="name" label="工资项目" />
        <el-table-column prop="value" label="金额" width="180" align="right">
          <template slot-scope="s">¥ {{ fmt(s.row.value) }}</template>
        </el-table-column>
      </el-table>
    </el-dialog>

    <!-- 参与人员列表对话框 -->
    <el-dialog title="参与薪酬统计人员" :visible.sync="peopleVisible" width="480px" append-to-body>
      <el-tag v-for="p in peopleList" :key="p.id" size="small" style="margin:4px">{{ p.user_name }}</el-tag>
      <div v-if="!peopleList.length" class="empty-tip">暂无人员数据</div>
    </el-dialog>

    <!-- 员工薪酬详情抽屉 -->
    <el-drawer :title="`${detail.user_name || ''} 薪酬详情 - ${detail.calc_month || ''}`" :visible.sync="drawerVisible" size="700px">
      <div v-if="detail.user_id" class="drawer-body">
        <el-descriptions :column="2" border size="small" style="margin-bottom:16px">
          <el-descriptions-item label="基本工资">¥ {{ fmt(detail.base_salary) }}</el-descriptions-item>
          <el-descriptions-item label="计件工资">¥ {{ fmt(detail.piecework_wage) }}</el-descriptions-item>
          <el-descriptions-item label="津贴合计">¥ {{ fmt(detail.allowance_total) }}</el-descriptions-item>
          <el-descriptions-item label="扣款合计">¥ {{ fmt(detail.deduction_total) }}</el-descriptions-item>
          <el-descriptions-item label="应发工资">¥ {{ fmt(detail.gross_salary) }}</el-descriptions-item>
          <el-descriptions-item label="实发工资">¥ {{ fmt(detail.net_salary) }}</el-descriptions-item>
        </el-descriptions>
        <el-row :gutter="16">
          <el-col :span="12">
            <div class="sub-title">津贴明细</div>
            <el-table :data="allowanceRows" size="mini" border empty-text="无津贴项">
              <el-table-column prop="name" label="津贴名称" />
              <el-table-column prop="amount" label="金额" width="100" align="right" />
            </el-table>
          </el-col>
          <el-col :span="12">
            <div class="sub-title">扣款明细</div>
            <el-table :data="deductionRows" size="mini" border empty-text="无扣款项">
              <el-table-column prop="name" label="扣款名称" />
              <el-table-column prop="amount" label="金额" width="100" align="right" />
            </el-table>
          </el-col>
        </el-row>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getSalaryStatistics, getSalaryStatisticsDetail, exportSalaryStatistics } from '@/api/salaryStatistics'
import { getDepartmentOptions } from '@/api/attendanceStatistics'

export default {
  name: 'HrSalaryStatistics',
  data () {
    return {
      yearOptions: this.buildYears(),
      query: { year: new Date().getFullYear(), monthRange: [], department_id: [], employee_type: '' },
      cards: { total_salary: 0, avg_salary: 0, employee_count: 0, max_salary: 0, max_user_name: '' },
      trend: { months: [], totals: [], avgs: [] },
      deptDist: { names: [], totals: [] },
      compose: [],
      rankDist: { names: [], avgs: [] },
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false,
      deptOptions: [],
      composeVisible: false, peopleVisible: false, peopleList: [],
      drawerVisible: false, detail: {}, allowanceRows: [], deductionRows: [],
      charts: {}
    }
  },
  created () {
    this.loadDepts()
    this.loadData()
  },
  mounted () {
    this.$nextTick(() => this.initCharts())
    window.addEventListener('resize', this.handleResize)
  },
  beforeDestroy () {
    window.removeEventListener('resize', this.handleResize)
    Object.values(this.charts).forEach(c => { if (c) c.dispose() })
    this.charts = {}
  },
  methods: {
    buildYears () {
      const y = new Date().getFullYear()
      return [y, y - 1, y - 2, y - 3, y - 4]
    },
    fmt (v) { return Number(v || 0).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) },
    fmtW (v) { return (Number(v || 0) / 10000).toFixed(2) },
    async loadDepts () {
      try {
        const r = await getDepartmentOptions()
        const out = []; const walk = (nodes) => { (nodes || []).forEach(n => { out.push({ id: n.id, name: n.name }); walk(n.children) }) }
        walk(r.data); this.deptOptions = out
      } catch (e) { this.deptOptions = [] }
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize, year: this.query.year }
      if (this.query.monthRange && this.query.monthRange.length === 2) {
        p.start_month = this.query.monthRange[0]
        p.end_month = this.query.monthRange[1]
      }
      if (this.query.department_id && this.query.department_id.length) p.department_id = this.query.department_id
      if (this.query.employee_type !== '' && this.query.employee_type !== null) p.employee_type = this.query.employee_type
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getSalaryStatistics(this.buildParams())
        if (r.code === 0 && r.data) {
          const d = r.data
          this.cards = d.cards || this.cards
          this.trend = d.trend || { months: [], totals: [], avgs: [] }
          this.deptDist = d.dept_dist || { names: [], totals: [] }
          this.compose = d.compose || []
          this.rankDist = d.rank_dist || { names: [], avgs: [] }
          this.list = d.list || []
          this.total = d.total || 0
          this.$nextTick(() => this.renderCharts())
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () {
      this.query = { year: new Date().getFullYear(), monthRange: [], department_id: [], employee_type: '' }
      this.handleSearch()
    },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    handleResize () { Object.values(this.charts).forEach(c => { if (c) c.resize() }) },
    initCharts () {
      this.charts.trend = echarts.init(this.$refs.trendChart)
      this.charts.dept = echarts.init(this.$refs.deptChart)
      this.charts.compose = echarts.init(this.$refs.composeChart)
      this.charts.rank = echarts.init(this.$refs.rankChart)
    },
    renderCharts () {
      if (!this.charts.trend) this.initCharts()
      // 月度趋势（双 Y 轴：总额万元 / 平均元）
      this.charts.trend.setOption({
        title: { text: '月度薪酬趋势', textStyle: { fontSize: 14 } },
        tooltip: { trigger: 'axis' },
        legend: { data: ['总薪酬', '平均薪酬'], top: 0, right: 10 },
        grid: { left: 60, right: 60, top: 40, bottom: 30 },
        xAxis: { type: 'category', data: this.trend.months },
        yAxis: [
          { type: 'value', name: '总额(万元)', axisLabel: { formatter: '{value}' } },
          { type: 'value', name: '平均(元)' }
        ],
        series: [
          { name: '总薪酬', type: 'line', smooth: true, yAxisIndex: 0, data: this.trend.totals.map(v => this.fmtW(v)), itemStyle: { color: '#409EFF' } },
          { name: '平均薪酬', type: 'line', smooth: true, yAxisIndex: 1, data: this.trend.avgs, itemStyle: { color: '#67C23A' }, lineStyle: { type: 'dashed' } }
        ]
      })
      // 部门分布（柱状，降序）
      this.charts.dept.setOption({
        title: { text: '部门薪酬分布', textStyle: { fontSize: 14 } },
        tooltip: { trigger: 'axis' },
        grid: { left: 60, right: 20, top: 40, bottom: 60 },
        xAxis: { type: 'category', data: this.deptDist.names, axisLabel: { interval: 0, rotate: 30 } },
        yAxis: { type: 'value', name: '万元' },
        series: [{
          name: '薪酬总额', type: 'bar', barMaxWidth: 40,
          data: this.deptDist.totals.map(v => this.fmtW(v)),
          itemStyle: { color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: '#409EFF' }, { offset: 1, color: '#a0cfff' }]) },
          label: { show: true, position: 'top', formatter: '{c}' }
        }]
      })
      // 工资构成（饼图）
      this.charts.compose.setOption({
        title: { text: '工资构成分析', textStyle: { fontSize: 14 }, left: 'center' },
        tooltip: { trigger: 'item', formatter: '{b}: ¥{c} ({d}%)' },
        legend: { bottom: 0 },
        series: [{
          name: '工资构成', type: 'pie', radius: ['40%', '65%'], center: ['50%', '50%'],
          label: { formatter: '{b} {d}%' },
          data: this.compose.map(c => ({ name: c.name, value: c.value, itemStyle: { color: c.color } }))
        }]
      })
      // 职级对比（柱状）
      this.charts.rank.setOption({
        title: { text: '职级薪酬对比', textStyle: { fontSize: 14 } },
        tooltip: { trigger: 'axis' },
        grid: { left: 60, right: 20, top: 40, bottom: 60 },
        xAxis: { type: 'category', data: this.rankDist.names, axisLabel: { interval: 0, rotate: 30 } },
        yAxis: { type: 'value', name: '平均薪酬(元)' },
        series: [{
          name: '平均薪酬', type: 'bar', barMaxWidth: 40,
          data: this.rankDist.avgs,
          itemStyle: { color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: '#9B59B6' }, { offset: 1, color: '#d7bde2' }]) },
          label: { show: true, position: 'top', formatter: '{c}' }
        }]
      })
    },
    openComposeDialog () { this.composeVisible = true },
    openPeopleDialog () {
      this.peopleList = this.list.filter((v, i, arr) => arr.findIndex(x => x.user_id === v.user_id) === i)
      this.peopleVisible = true
    },
    async openDetail (row) {
      this.drawerVisible = true
      this.detail = {}
      this.allowanceRows = []
      this.deductionRows = []
      try {
        const r = await getSalaryStatisticsDetail(row.user_id, { month: row.calc_month })
        if (r.code === 0 && r.data) {
          this.detail = r.data
          this.allowanceRows = Object.entries(r.data.allowance_json || {}).map(([name, amount]) => ({ name, amount }))
          this.deductionRows = Object.entries(r.data.deduction_json || {}).map(([name, amount]) => ({ name, amount }))
        } else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
    },
    async handleExport () {
      this.exporting = true
      try {
        const params = { ...this.buildParams() }
        delete params.page
        delete params.pageSize
        const r = await exportSalaryStatistics(params)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `薪酬统计报表_${this.query.year}.xlsx`
          a.click()
          window.URL.revokeObjectURL(url)
        }
      } catch (e) {} finally { this.exporting = false }
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.stat-row { margin-top: 16px; }
.stat-card { display: flex; align-items: center; padding: 16px 20px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); cursor: pointer; transition: transform .2s; }
.stat-card:hover { transform: translateY(-3px); }
.stat-blue { background: linear-gradient(135deg, #ecf5ff, #d9ecff); }
.stat-green { background: linear-gradient(135deg, #f0f9eb, #e1f3d8); }
.stat-orange { background: linear-gradient(135deg, #fdf6ec, #fae8cd); }
.stat-purple { background: linear-gradient(135deg, #f5ecfb, #ecd9f7); }
.stat-icon { font-size: 30px; margin-right: 14px; }
.stat-blue .stat-icon { color: #409EFF; }
.stat-green .stat-icon { color: #67C23A; }
.stat-orange .stat-icon { color: #E6A23C; }
.stat-purple .stat-icon { color: #9B59B6; }
.stat-num { font-size: 20px; font-weight: bold; color: #303133; line-height: 1.2; }
.stat-unit { font-size: 13px; color: #909399; font-weight: normal; }
.stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.chart-card { margin-top: 16px; border-radius: 8px; }
.chart-header { display: flex; justify-content: space-between; align-items: center; }
.chart-title { font-weight: 600; }
.chart-box { width: 100%; height: 320px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; margin-top: 16px; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.drawer-body { padding: 0 20px; }
.sub-title { font-size: 14px; font-weight: 600; margin-bottom: 8px; }
.empty-tip { color: #909399; font-size: 14px; text-align: center; padding: 20px 0; }
</style>
