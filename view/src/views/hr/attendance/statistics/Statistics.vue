<!--
  文件：admin/src/views/hr/attendance/statistics/Statistics.vue
  功能：考勤统计（日/周/月维度、统计卡片、趋势/部门/状态图表、明细表、批量标记异常、员工详情抽屉、导出）
  权限：hr:attendance:statistics:view / export / batch
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>考勤管理</el-breadcrumb-item>
      <el-breadcrumb-item>考勤统计</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 筛选条件 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="统计维度">
          <el-select v-model="query.dimension" style="width:110px" @change="handleDimensionChange">
            <el-option label="按日" value="day" /><el-option label="按周" value="week" /><el-option label="按月" value="month" />
          </el-select>
        </el-form-item>
        <el-form-item label="统计周期">
          <el-date-picker v-if="query.dimension === 'day'" v-model="query.date" type="date" value-format="yyyy-MM-dd" style="width:140px" />
          <el-date-picker v-else-if="query.dimension === 'week'" v-model="query.date" type="week" value-format="yyyy-MM-dd" format="yyyy 第 WW 周" style="width:150px" />
          <el-date-picker v-else v-model="query.date" type="month" value-format="yyyy-MM-dd" style="width:130px" />
        </el-form-item>
        <el-form-item label="部门">
          <el-select v-model="query.department_id" multiple filterable clearable placeholder="全部" style="width:180px">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="员工姓名"><el-input v-model="query.user_name" placeholder="请输入员工姓名" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">查询</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="6"><div class="stat-card stat-blue" @click="handleCardClick('all')"><div class="stat-icon"><i class="el-icon-calendar" /></div><div class="stat-info"><div class="stat-num">{{ cards.should_days }} <span class="stat-unit">天</span></div><div class="stat-label">应出勤天数</div></div></div></el-col>
      <el-col :span="6"><div class="stat-card stat-green" @click="handleCardClick('actual')"><div class="stat-icon"><i class="el-icon-check" /></div><div class="stat-info"><div class="stat-num" style="color:#67C23A">{{ cards.actual_days }} <span class="stat-unit">天</span></div><div class="stat-label">实际出勤天数</div></div></div></el-col>
      <el-col :span="6"><div class="stat-card stat-red" @click="handleCardClick('absent')"><div class="stat-icon"><i class="el-icon-close" /></div><div class="stat-info"><div class="stat-num" style="color:#F56C6C">{{ cards.absent_days }} <span class="stat-unit">天</span></div><div class="stat-label">缺勤天数</div></div></div></el-col>
      <el-col :span="6"><div class="stat-card stat-orange"><div class="stat-icon"><i class="el-icon-data-line" /></div><div class="stat-info"><div class="stat-num" style="color:#E6A23C">{{ cards.attendance_rate }}<span class="stat-unit">%</span></div><div class="stat-label">出勤率</div></div></div></el-col>
    </el-row>

    <!-- 图表区域 -->
    <el-card shadow="never" class="chart-card">
      <div slot="header" class="chart-header">
        <span>考勤分析</span>
        <el-button type="text" size="mini" icon="el-icon-refresh" :loading="chartLoading" @click="loadData">刷新图表</el-button>
      </div>
      <el-row :gutter="16">
        <el-col :span="12"><div ref="dailyChart" class="chart-box" /></el-col>
        <el-col :span="12"><div ref="deptChart" class="chart-box" /></el-col>
      </el-row>
      <el-row :gutter="16"><el-col :span="24"><div ref="statusChart" class="chart-box chart-wide" /></el-col></el-row>
    </el-card>

    <!-- 操作按钮栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'hr:attendance:statistics:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出报表</el-button>
        <el-button v-permission="'hr:attendance:statistics:batch'" size="small" icon="el-icon-edit" :disabled="!selectedIds.length" @click="openBatchDialog">批量标记异常</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条记录</span>
    </div>

    <!-- 明细数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无考勤统计数据" @selection-change="handleSelectionChange">
      <el-table-column type="selection" width="55" align="center" />
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column prop="user_name" label="员工姓名" width="90" />
      <el-table-column prop="department_name" label="部门" width="120" show-overflow-tooltip />
      <el-table-column prop="position_name" label="岗位" width="100" show-overflow-tooltip />
      <el-table-column label="应出勤天数" width="110" align="right"><template slot-scope="s">{{ s.row.should_attend_days }} 天</template></el-table-column>
      <el-table-column label="实际出勤天数" width="120" align="right"><template slot-scope="s">{{ s.row.actual_attend_days }} 天</template></el-table-column>
      <el-table-column label="迟到次数" width="90" align="center"><template slot-scope="s"><span :style="{ color: s.row.late_count > 0 ? '#F56C6C' : '' }">{{ s.row.late_count }} 次</span></template></el-table-column>
      <el-table-column label="早退次数" width="90" align="center"><template slot-scope="s"><span :style="{ color: s.row.early_leave_count > 0 ? '#F56C6C' : '' }">{{ s.row.early_leave_count }} 次</span></template></el-table-column>
      <el-table-column label="事假天数" width="90" align="right"><template slot-scope="s"><span :style="{ color: s.row.personal_leave_days > 0 ? '#E6A23C' : '' }">{{ s.row.personal_leave_days }} 天</span></template></el-table-column>
      <el-table-column label="病假天数" width="90" align="right"><template slot-scope="s"><span :style="{ color: s.row.sick_leave_days > 0 ? '#F56C6C' : '' }">{{ s.row.sick_leave_days }} 天</span></template></el-table-column>
      <el-table-column label="加班天数" width="90" align="right"><template slot-scope="s"><span :style="{ color: s.row.overtime_days > 0 ? '#67C23A' : '' }">{{ s.row.overtime_days }} 天</span></template></el-table-column>
      <el-table-column label="出勤率" width="100" align="center">
        <template slot-scope="s">
          <span :style="{ color: rateColor(s.row.attendance_rate) }">{{ s.row.attendance_rate }}%</span>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="120" align="center" fixed="right">
        <template slot-scope="s"><el-button type="text" size="mini" @click="openDetail(s.row)">查看详情</el-button></template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 批量标记异常对话框 -->
    <el-dialog title="批量标记异常考勤" :visible.sync="batchVisible" width="600px" :close-on-click-modal="false">
      <el-form :model="batchForm" label-width="110px" size="small">
        <el-form-item label="选中员工">
          <div v-if="selectedRows.length" class="batch-users">{{ selectedRows.map(r => r.user_name).join('、') }}（共 {{ selectedRows.length }} 人）</div>
          <div v-else class="batch-empty">请先在表格中选择需要标记的员工</div>
        </el-form-item>
        <el-form-item label="标记类型" required>
          <el-select v-model="batchForm.mark_type" style="width:200px">
            <el-option label="迟到" :value="1" /><el-option label="早退" :value="2" /><el-option label="旷工" :value="3" /><el-option label="缺勤" :value="4" />
          </el-select>
        </el-form-item>
        <el-form-item label="标记日期" required>
          <el-date-picker v-model="batchForm.dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:100%" />
        </el-form-item>
        <el-form-item label="标记原因" required>
          <el-input v-model="batchForm.reason" type="textarea" :rows="3" placeholder="请填写标记原因" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="batchVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="batchSaving" @click="handleBatchMark">确认标记</el-button>
      </div>
    </el-dialog>

    <!-- 员工考勤详情抽屉 -->
    <el-drawer :title="`${detail.user ? detail.user.name : ''} 考勤详情 - ${detail.period ? detail.period.start + ' ~ ' + detail.period.end : ''}`" :visible.sync="drawerVisible" size="700px" :close-on-press-escape="true">
      <div v-if="detail.user" class="drawer-body">
        <el-descriptions :column="2" border size="small" style="margin-bottom:16px">
          <el-descriptions-item label="应出勤天数">{{ detail.summary.should }} 天</el-descriptions-item>
          <el-descriptions-item label="实际出勤天数">{{ detail.summary.actual }} 天</el-descriptions-item>
          <el-descriptions-item label="迟到次数">{{ detail.summary.late }} 次</el-descriptions-item>
          <el-descriptions-item label="早退次数">{{ detail.summary.early }} 次</el-descriptions-item>
          <el-descriptions-item label="事假天数">{{ detail.summary.personal }} 天</el-descriptions-item>
          <el-descriptions-item label="病假天数">{{ detail.summary.sick }} 天</el-descriptions-item>
          <el-descriptions-item label="加班天数">{{ detail.summary.overtime }} 天</el-descriptions-item>
          <el-descriptions-item label="出勤率">{{ detail.summary.rate }}%</el-descriptions-item>
        </el-descriptions>
        <el-table :data="detail.daily || []" size="small" border>
          <el-table-column prop="date" label="日期" width="120" />
          <el-table-column prop="week" label="星期" width="80" align="center" />
          <el-table-column prop="check_in" label="打卡时间" width="100" align="center" />
          <el-table-column label="考勤状态" width="100" align="center">
            <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.check_result }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="leave_type" label="假勤类型" width="100" align="center"><template slot-scope="s">{{ s.row.leave_type || '-' }}</template></el-table-column>
          <el-table-column prop="remark" label="备注" min-width="120" show-overflow-tooltip />
        </el-table>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getAttendanceStatistics, getAttendanceDetail, batchMarkAttendance, exportAttendanceStatistics, getDepartmentOptions } from '@/api/attendanceStatistics'

export default {
  name: 'HrAttendanceStatistics',
  data () {
    return {
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false, chartLoading: false,
      query: { dimension: 'month', date: this.todayStr(), department_id: [], user_name: '' },
      cards: { should_days: 0, actual_days: 0, absent_days: 0, attendance_rate: 0 },
      charts: { daily: [], dept: [], status: [] },
      deptOptions: [],
      selectedIds: [], selectedRows: [],
      batchVisible: false, batchSaving: false, batchForm: { mark_type: 1, dateRange: [], reason: '' },
      drawerVisible: false, detail: {},
      chartInstances: {}
    }
  },
  created () {
    this.loadDepts()
    this.loadData()
    window.addEventListener('resize', this.resizeCharts)
  },
  beforeDestroy () {
    window.removeEventListener('resize', this.resizeCharts)
    Object.values(this.chartInstances).forEach(c => { if (c) c.dispose() })
  },
  methods: {
    todayStr () {
      const d = new Date()
      return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
    },
    async loadDepts () {
      try {
        const r = await getDepartmentOptions()
        const walk = (nodes, out) => { (nodes || []).forEach(n => { out.push({ id: n.id, name: n.name }); walk(n.children, out) }) }
        const out = []
        walk(r.data, out)
        this.deptOptions = out
      } catch (e) { this.deptOptions = [] }
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize, dimension: this.query.dimension, date: this.query.date }
      if (this.query.department_id && this.query.department_id.length) p.department_id = this.query.department_id
      if (this.query.user_name) p.user_name = this.query.user_name
      return p
    },
    async loadData () {
      this.loading = true
      this.chartLoading = true
      try {
        const r = await getAttendanceStatistics(this.buildParams())
        if (r.code === 0 && r.data) {
          this.cards = r.data.cards || this.cards
          this.charts = { daily: r.data.chart_daily || [], dept: r.data.chart_dept || [], status: r.data.chart_status || [] }
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.$nextTick(() => this.renderCharts())
        }
      } catch (e) {} finally { this.loading = false; this.chartLoading = false }
    },
    handleDimensionChange () { this.loadData() },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () { this.query = { dimension: 'month', date: this.todayStr(), department_id: [], user_name: '' }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    handleCardClick (type) {
      // 实际出勤/缺勤卡片：当前仅刷新（数据为整体汇总，不按员工二次筛选）
      this.loadData()
    },
    rateColor (rate) {
      if (rate < 80) return '#F56C6C'
      if (rate <= 90) return '#E6A23C'
      return '#67C23A'
    },
    handleSelectionChange (rows) { this.selectedRows = rows; this.selectedIds = rows.map(r => r.user_id) },
    openBatchDialog () {
      if (!this.selectedIds.length) { this.$message.warning('请先在表格中选择需要标记的员工'); return }
      this.batchForm = { mark_type: 1, dateRange: [], reason: '' }
      this.batchVisible = true
    },
    async handleBatchMark () {
      if (!this.batchForm.dateRange || this.batchForm.dateRange.length !== 2) { this.$message.warning('请选择标记日期范围'); return }
      if (!this.batchForm.reason.trim()) { this.$message.warning('请填写标记原因'); return }
      this.batchSaving = true
      try {
        const r = await batchMarkAttendance({
          user_ids: this.selectedIds, mark_type: this.batchForm.mark_type,
          start_date: this.batchForm.dateRange[0], end_date: this.batchForm.dateRange[1], reason: this.batchForm.reason
        })
        if (r.code === 0) { this.$message.success(r.msg || '标记成功'); this.batchVisible = false; this.loadData() } else this.$message.error(r.msg || '标记失败')
      } catch (e) {} finally { this.batchSaving = false }
    },
    async openDetail (row) {
      this.drawerVisible = true
      this.detail = {}
      try {
        const r = await getAttendanceDetail(row.user_id, { dimension: this.query.dimension, date: this.query.date })
        if (r.code === 0 && r.data) this.detail = r.data
        else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
    },
    async handleExport () {
      this.exporting = true
      try {
        const p = { dimension: this.query.dimension, date: this.query.date }
        if (this.query.department_id && this.query.department_id.length) p.department_id = this.query.department_id
        if (this.query.user_name) p.user_name = this.query.user_name
        const r = await exportAttendanceStatistics(p)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `考勤统计报表_${new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14)}.xlsx`
          a.click()
          window.URL.revokeObjectURL(url)
        }
      } catch (e) {} finally { this.exporting = false }
    },
    getChart (ref) {
      if (!this.chartInstances[ref]) this.chartInstances[ref] = echarts.init(this.$refs[ref])
      return this.chartInstances[ref]
    },
    renderCharts () {
      // 每日出勤趋势（折线双线）
      const daily = this.charts.daily || []
      const c1 = this.getChart('dailyChart')
      c1.setOption({
        tooltip: { trigger: 'axis' },
        legend: { data: ['应出勤人次', '实际出勤人次'], right: 0 },
        grid: { left: 40, right: 20, top: 40, bottom: 40 },
        xAxis: { type: 'category', data: daily.map(x => x.date.slice(5)) },
        yAxis: { type: 'value', name: '人次' },
        series: [
          { name: '应出勤人次', type: 'line', data: daily.map(x => x.should), lineStyle: { type: 'dashed', color: '#409EFF' }, itemStyle: { color: '#409EFF' } },
          { name: '实际出勤人次', type: 'line', data: daily.map(x => x.actual), areaStyle: { color: 'rgba(103,194,58,0.15)' }, lineStyle: { color: '#67C23A' }, itemStyle: { color: '#67C23A' } }
        ]
      }, true)
      // 部门出勤率对比（柱状）
      const dept = this.charts.dept || []
      const c2 = this.getChart('deptChart')
      c2.setOption({
        tooltip: { trigger: 'axis' },
        grid: { left: 40, right: 20, top: 30, bottom: 40 },
        xAxis: { type: 'category', data: dept.map(x => x.name), axisLabel: { interval: 0, rotate: 20 } },
        yAxis: { type: 'value', name: '出勤率%', max: 100 },
        series: [{
          type: 'bar', data: dept.map(x => x.rate), barMaxWidth: 40,
          label: { show: true, position: 'top', formatter: '{c}%' },
          itemStyle: { color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: '#409EFF' }, { offset: 1, color: '#a0cfff' }]) }
        }]
      }, true)
      // 考勤状态分布（饼图）
      const status = this.charts.status || []
      const totalVal = status.reduce((s, x) => s + (Number(x.value) || 0), 0)
      const colors = ['#67C23A', '#E6A23C', '#E6A23C', '#909399', '#F56C6C', '#E6A23C']
      const c3 = this.getChart('statusChart')
      c3.setOption({
        tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
        legend: { type: 'scroll', orient: 'vertical', right: 20, top: 'middle', textStyle: { fontSize: 11 } },
        graphic: {
          type: 'text', left: '36%', top: '44%', style: {
            text: '总人次\n' + totalVal, textAlign: 'center', fill: '#606266', fontSize: 14, lineHeight: 20, fontWeight: 'bold'
          }
        },
        series: [{
          type: 'pie', radius: ['38%', '62%'], center: ['36%', '50%'], avoidLabelOverlap: true,
          itemStyle: { borderRadius: 4, borderColor: '#fff', borderWidth: 1 },
          label: { formatter: '{b}\n{d}%', fontSize: 11 },
          data: status.map((x, i) => ({ ...x, itemStyle: { color: colors[i % colors.length] } }))
        }]
      }, true)
    },
    resizeCharts () {
      Object.values(this.chartInstances).forEach(c => { if (c) c.resize() })
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
.stat-red { background: linear-gradient(135deg, #fef0f0, #fde2e2); }
.stat-orange { background: linear-gradient(135deg, #fdf6ec, #fae8cd); }
.stat-icon { font-size: 30px; margin-right: 14px; }
.stat-blue .stat-icon { color: #409EFF; }
.stat-green .stat-icon { color: #67C23A; }
.stat-red .stat-icon { color: #F56C6C; }
.stat-orange .stat-icon { color: #E6A23C; }
.stat-num { font-size: 24px; font-weight: bold; color: #303133; line-height: 1.2; }
.stat-unit { font-size: 13px; color: #909399; font-weight: normal; }
.stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.chart-card { margin-top: 16px; }
.chart-header { display: flex; justify-content: space-between; align-items: center; }
.chart-box { height: 260px; }
.chart-wide { height: 300px; margin-top: 16px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; margin-top: 16px; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.batch-users { color: #606266; line-height: 1.7; }
.batch-empty { color: #909399; font-size: 13px; }
.drawer-body { padding: 0 20px; }
</style>
