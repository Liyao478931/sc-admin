<!--
  文件：admin/src/views/hr/assessment/dashboard/Index.vue
  功能：考核看板（时间筛选 + 概览卡片 + 部门排名/等级分布/高频扣分/趋势 + 预警/个人排名）
  视觉：对齐参考模板（主色 #1e6fff）
-->
<template>
  <div class="wh-page assessment-dashboard-page">
    <div class="page-header">
      <div class="header-left">
        <el-breadcrumb separator="/" class="breadcrumb">
          <el-breadcrumb-item>人事管理</el-breadcrumb-item>
          <el-breadcrumb-item>绩效考核</el-breadcrumb-item>
          <el-breadcrumb-item>考核看板</el-breadcrumb-item>
        </el-breadcrumb>
        <span class="badge-module">📊 考核看板</span>
      </div>
      <div class="header-actions">
        <el-button v-permission="'assessment:task:view'" size="small" icon="el-icon-right" @click="drillTask()">下钻到任务列表</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadAll">刷新</el-button>
      </div>
    </div>

    <div class="board-layout">
      <!-- 筛选栏 -->
      <div class="filter-bar">
        <div class="filter-left">
          <el-select v-model="query.year" size="small" style="width:90px" @change="loadAll">
            <el-option v-for="y in filterOptions.years" :key="y" :label="y + '年'" :value="y" />
          </el-select>
          <template v-if="query.period_type === 1">
            <el-select v-model="query.month" size="small" style="width:90px" @change="loadAll">
              <el-option v-for="m in 12" :key="m" :label="m + '月'" :value="m" />
            </el-select>
          </template>
          <template v-else-if="query.period_type === 2">
            <el-select v-model="query.quarter" size="small" style="width:90px" @change="loadAll">
              <el-option v-for="q in 4" :key="q" :label="'Q' + q" :value="q" />
            </el-select>
          </template>
          <el-radio-group v-model="query.period_type" size="small" @change="onPeriodTypeChange">
            <el-radio-button :label="1">月度</el-radio-button>
            <el-radio-button :label="2">季度</el-radio-button>
            <el-radio-button :label="3">年度</el-radio-button>
          </el-radio-group>
          <el-select v-model="query.department_id" size="small" clearable placeholder="全部部门" style="width:130px" @change="loadAll">
            <el-option v-for="d in filterOptions.departments" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </div>
      </div>

      <!-- 概览卡片 -->
      <div class="board-section">
        <stat-cards :data="overview" @click-card="onCardClick" />
      </div>

      <!-- 图表区域 -->
      <div class="chart-grid">
        <dept-ranking-chart :list="deptRanking" :overall-avg="overallAvg" @click-dept="d => drillTask({ department_id: d.department_id })" />
        <grade-distribution-chart :grade-dist="overview.grade_distribution || {}" :total="overview.total_employees || 0" />
        <top-deduction-chart :list="deductionAnalysis" />
        <trend-chart :periods="trend.periods" :current="trend.current_dept" :compare="trend.compare_dept" />
      </div>

      <!-- 列表区域 -->
      <div class="list-grid">
        <warning-list :list="warningList" @view="row => drillTask({ keyword: row.employee_name })" />
        <employee-ranking-list :list="rankingList" :order="rankingOrder" @order-change="onRankingOrder" @view="row => drillTask({ keyword: row.employee_name })" />
      </div>
    </div>
  </div>
</template>

<script>
import StatCards from './components/StatCards.vue'
import DeptRankingChart from './components/DeptRankingChart.vue'
import GradeDistributionChart from './components/GradeDistributionChart.vue'
import TopDeductionChart from './components/TopDeductionChart.vue'
import TrendChart from './components/TrendChart.vue'
import WarningList from './components/WarningList.vue'
import EmployeeRankingList from './components/EmployeeRankingList.vue'
import {
  getDashboardOverview, getDeptRanking, getDeductionAnalysis, getAssessmentTrend,
  getAssessmentWarning, getDashboardFilters
} from '@/api/assessment'
import request from '@/api/request'

export default {
  name: 'AssessmentDashboardIndex',
  components: { StatCards, DeptRankingChart, GradeDistributionChart, TopDeductionChart, TrendChart, WarningList, EmployeeRankingList },
  data () {
    const now = new Date()
    return {
      query: { year: now.getFullYear(), month: now.getMonth() + 1, quarter: 1, period_type: 1, department_id: '' },
      filterOptions: { years: [], months: [], quarters: [1, 2, 3, 4], departments: [] },
      loading: false,
      overview: {},
      deptRanking: [],
      overallAvg: 0,
      deductionAnalysis: [],
      trend: { periods: [], current_dept: {}, compare_dept: {} },
      warningList: [],
      rankingList: [],
      rankingOrder: 'desc'
    }
  },
  created () {
    this.loadFilters()
    this.loadAll()
  },
  methods: {
    async loadFilters () {
      try {
        const r = await getDashboardFilters()
        if (r.code === 0 && r.data) {
          this.filterOptions = r.data
          if (r.data.years && r.data.years.length && !r.data.years.includes(this.query.year)) {
            this.query.year = r.data.years[r.data.years.length - 1]
          }
        }
      } catch (e) {}
    },
    onPeriodTypeChange () {
      this.loadAll()
    },
    async loadAll () {
      this.loading = true
      try {
        const q = this.buildParams()
        const [r1, r2, r3, r4, r5] = await Promise.all([
          getDashboardOverview(q),
          getDeptRanking({ year: q.year, month: q.month, quarter: q.quarter, period_type: q.period_type }),
          getDeductionAnalysis(q),
          getAssessmentTrend({ months: 6, department_id: q.department_id || 0 }),
          getAssessmentWarning({ threshold: 70, months: 3, consecutive_months: 2, department_id: q.department_id || 0 })
        ])
        if (r1.code === 0) this.overview = r1.data || {}
        if (r2.code === 0) { this.deptRanking = r2.data.list || []; this.overallAvg = r2.data.overall_avg || 0 }
        if (r3.code === 0) this.deductionAnalysis = r3.data.list || []
        if (r4.code === 0) this.trend = r4.data || { periods: [], current_dept: {}, compare_dept: {} }
        if (r5.code === 0) this.warningList = r5.data.list || []
        await this.loadRanking()
      } catch (e) {} finally { this.loading = false }
    },
    buildParams () {
      const q = { year: this.query.year, period_type: this.query.period_type }
      if (this.query.period_type === 1) q.month = this.query.month
      else if (this.query.period_type === 2) q.quarter = this.query.quarter
      if (this.query.department_id) q.department_id = this.query.department_id
      return q
    },
    async loadRanking () {
      try {
        const q = this.buildParams()
        q.order = this.rankingOrder
        q.top = 20
        const r = await request({ url: '/assessment/dashboard/employee-ranking', method: 'get', params: q })
        if (r.code === 0) this.rankingList = r.data.list || []
      } catch (e) {}
    },
    onRankingOrder (order) {
      this.rankingOrder = order
      this.loadRanking()
    },
    // ===== 下钻 =====
    drillTask (extra) {
      const query = { year: this.query.year, month: this.query.month }
      if (this.query.department_id) query.department_id = this.query.department_id
      Object.assign(query, extra || {})
      this.$router.push({ path: '/hr/assessment/task', query })
    },
    onCardClick ({ type }) {
      if (type === 'max') this.drillTask({ sort: 'desc' })
      else if (type === 'min') this.drillTask({ sort: 'asc' })
      else if (type === 'warning') this.drillTask({})
    }
  }
}
</script>

<style scoped>
.assessment-dashboard-page { padding: 16px; }
.page-header { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; padding: 12px 18px; background: #fafbfc; border: 1px solid #e8ecf1; border-bottom: none; border-radius: 12px 12px 0 0; }
.header-left { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.header-left .breadcrumb { font-size: 14px; color: #8c8f9c; }
.header-left .breadcrumb >>> .el-breadcrumb__inner { color: #8c8f9c; }
.header-left .breadcrumb >>> .el-breadcrumb__item:last-child .el-breadcrumb__inner { color: #1d2129; font-weight: 500; }
.badge-module { background: #e8f3ff; color: #1e6fff; font-size: 12px; padding: 2px 12px; border-radius: 12px; font-weight: 500; }
.header-actions { display: flex; gap: 8px; }
.board-layout { border: 1px solid #e8ecf1; border-radius: 0 0 12px 12px; background: #f7f9fc; padding: 16px; display: flex; flex-direction: column; gap: 16px; }
.filter-bar { display: flex; align-items: center; background: #fff; border: 1px solid #e8ecf1; border-radius: 12px; padding: 12px 16px; }
.filter-left { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
.board-section { }
.chart-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
.list-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
@media (max-width: 1200px) {
  .chart-grid, .list-grid { grid-template-columns: 1fr; }
}
</style>

<!-- 模块级主题覆盖 -->
<style>
.assessment-dashboard-page .el-button--primary { background-color: #1e6fff; border-color: #1e6fff; }
.assessment-dashboard-page .el-button--primary:hover, .assessment-dashboard-page .el-button--primary:focus { background-color: #4d8bff; border-color: #4d8bff; }
.assessment-dashboard-page .el-radio-button__orig-radio:checked + .el-radio-button__inner { background-color: #1e6fff; border-color: #1e6fff; box-shadow: -1px 0 0 0 #1e6fff; }
.assessment-dashboard-page .el-select .el-input.is-focus .el-input__inner { border-color: #1e6fff; }
</style>
