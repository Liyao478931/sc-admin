<template>
  <div class="schedule-page">
    <!-- 顶部：年月 + 筛选 + 操作 -->
    <el-card shadow="never" class="toolbar-card">
      <div class="toolbar">
        <div class="month-nav">
          <el-button size="small" icon="el-icon-arrow-left" @click="changeMonth(-1)" />
          <el-button size="small" @click="goToday">今天</el-button>
          <el-button size="small" icon="el-icon-arrow-right" @click="changeMonth(1)" />
          <span class="month-label">{{ year }}年{{ month }}月</span>
        </div>
        <div class="filters">
          <el-select v-model="filters.department_id" clearable placeholder="全部部门" style="width:150px" @change="onDeptChange">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
          <el-select v-model="employeeId" filterable clearable placeholder="选择员工" style="width:200px" @change="onEmployeeChange">
            <el-option v-for="e in empOptions" :key="e.id" :label="e.name + '（' + (e.employee_id || '') + '）'" :value="e.id" />
          </el-select>
        </div>
        <div class="actions">
          <el-button size="small" type="primary" icon="el-icon-date" @click="batchVisible = true">批量排班</el-button>
          <el-button size="small" icon="el-icon-swap" @click="swapVisible = true">调班</el-button>
          <el-button size="small" icon="el-icon-download" :loading="exporting" @click="doExport">导出</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadAll">刷新</el-button>
        </div>
      </div>
    </el-card>

    <!-- 月历 -->
    <el-card shadow="never" class="cal-card" v-loading="loading">
      <div class="cal-head">
        <span v-for="w in weekLabels" :key="w" class="cal-head-cell">{{ w }}</span>
      </div>
      <div class="cal-body">
        <div v-for="cell in calendarCells" :key="cell.key" class="cal-cell" :class="{ 'other-month': !cell.inMonth, 'is-rest': cell.isRest }" @click="cell.inMonth && openSetDialog(cell)">
          <div class="cal-date">{{ cell.day }}</div>
          <div v-if="cell.inMonth && cell.shiftName" class="cal-shift" :style="shiftStyle(cell.shiftId)">{{ cell.shiftName }}</div>
          <div v-if="cell.inMonth && cell.isRest" class="cal-rest">休</div>
        </div>
      </div>
      <div v-if="!employeeId" class="cal-tip">请选择员工查看排班日历</div>
    </el-card>

    <!-- 统计 -->
    <el-card shadow="never" class="stat-card" v-if="employeeId">
      <div class="stat-title">本月排班统计</div>
      <div class="stat-items">
        <span>总排班：<b>{{ stats.total }}</b></span>
        <span>休息日：<b>{{ stats.rest }}</b></span>
        <template v-for="s in stats.by_shift" :key="s.shift_id">
          <span>{{ s.shift_name }}：<b>{{ s.count }}</b></span>
        </template>
      </div>
      <div v-if="stats.unassigned && stats.unassigned.length" class="stat-unassigned">
        未排班员工（{{ stats.unassigned.length }}）：{{ stats.unassigned.map(u => u.name).join('、') }}
      </div>
    </el-card>

    <!-- 单个排班弹窗 -->
    <schedule-set-dialog v-if="setVisible" :visible.sync="setVisible" :employee-id="employeeId" :employee-name="currentEmpName" :date="currentDate" :existing="currentCell" @saved="loadCalendar" />

    <!-- 批量排班弹窗 -->
    <schedule-batch-dialog v-if="batchVisible" :visible.sync="batchVisible" @saved="loadAll" />

    <!-- 调班弹窗 -->
    <schedule-swap-dialog v-if="swapVisible" :visible.sync="swapVisible" @saved="loadAll" />
  </div>
</template>

<script>
import { getScheduleCalendar, getScheduleEmployees, getScheduleStatistics, exportSchedule } from '@/api/attendanceSchedule'
import { getDeptTree } from '@/api/organization'
import ScheduleSetDialog from './components/ScheduleSetDialog.vue'
import ScheduleBatchDialog from './components/ScheduleBatchDialog.vue'
import ScheduleSwapDialog from './components/ScheduleSwapDialog.vue'

const SHIFT_COLORS = ['#409EFF', '#67C23A', '#E6A23C', '#F56C6C', '#8E44AD', '#00BFA5', '#FF7043', '#5C6BC0']
const weekLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']

function flattenDept (nodes) {
  let r = []
  for (const n of nodes || []) { r.push(n); if (n.children) r = r.concat(flattenDept(n.children)) }
  return r
}

export default {
  name: 'AttendanceSchedule',
  components: { ScheduleSetDialog, ScheduleBatchDialog, ScheduleSwapDialog },
  data () {
    const now = new Date()
    return {
      weekLabels,
      year: now.getFullYear(),
      month: now.getMonth() + 1,
      loading: false, exporting: false,
      deptOptions: [], empOptions: [],
      filters: { department_id: '' },
      employeeId: 0,
      dayMap: {}, // date -> calendar item
      stats: { total: 0, rest: 0, by_shift: [], unassigned: [] },
      setVisible: false, batchVisible: false, swapVisible: false,
      currentDate: '', currentCell: null
    }
  },
  computed: {
    currentEmpName () {
      const e = this.empOptions.find(x => x.id === this.employeeId)
      return e ? e.name : ''
    },
    // 月历单元格（42格，周一起始）
    calendarCells () {
      const first = new Date(this.year, this.month - 1, 1)
      const offset = (first.getDay() + 6) % 7 // 周一=0
      const daysInMonth = new Date(this.year, this.month, 0).getDate()
      const cells = []
      for (let i = 0; i < 42; i++) {
        const dayNum = i - offset + 1
        const inMonth = dayNum >= 1 && dayNum <= daysInMonth
        let date = ''
        let shiftName = ''
        let isRest = false
        let shiftId = null
        if (inMonth) {
          date = `${this.year}-${String(this.month).padStart(2, '0')}-${String(dayNum).padStart(2, '0')}`
          const item = this.dayMap[date]
          if (item) { shiftName = item.shift_name; isRest = !!item.is_rest; shiftId = item.shift_id }
        }
        cells.push({ key: i, day: inMonth ? dayNum : '', inMonth, date, shiftName, isRest, shiftId })
      }
      return cells
    }
  },
  created () {
    this.loadDepts()
    this.loadAll()
  },
  methods: {
    shiftStyle (id) {
      if (!id) return {}
      const c = SHIFT_COLORS[id % SHIFT_COLORS.length]
      return { background: c + '1a', color: c, borderColor: c }
    },
    async loadDepts () {
      try {
        const r = await getDeptTree()
        if (r.code === 0) this.deptOptions = flattenDept(r.data || []).map(d => ({ id: d.id, name: d.name }))
      } catch (e) {}
    },
    async loadEmployees () {
      try {
        const r = await getScheduleEmployees({ department_id: this.filters.department_id || 0 })
        if (r.code === 0) {
          this.empOptions = r.data || []
          if (!this.empOptions.find(x => x.id === this.employeeId)) this.employeeId = this.empOptions.length ? this.empOptions[0].id : 0
        }
      } catch (e) {}
    },
    async loadCalendar () {
      if (!this.employeeId) return
      this.loading = true
      try {
        const r = await getScheduleCalendar({ year: this.year, month: this.month, employee_id: this.employeeId })
        if (r.code === 0) {
          const days = r.data.days || []
          this.dayMap = {}
          days.forEach(d => { if (d.shift_name || d.is_rest) this.dayMap[d.date] = d })
        }
      } catch (e) {} finally { this.loading = false }
    },
    async loadStats () {
      if (!this.employeeId) return
      try {
        const r = await getScheduleStatistics({ year_month: `${this.year}-${String(this.month).padStart(2, '0')}`, department_id: this.filters.department_id || 0 })
        if (r.code === 0) this.stats = r.data || { total: 0, rest: 0, by_shift: [], unassigned: [] }
      } catch (e) {}
    },
    async loadAll () {
      await this.loadEmployees()
      await Promise.all([this.loadCalendar(), this.loadStats()])
    },
    onDeptChange () { this.loadAll() },
    onEmployeeChange () { this.loadCalendar(); this.loadStats() },
    changeMonth (delta) {
      let m = this.month + delta
      let y = this.year
      if (m < 1) { m = 12; y-- }
      if (m > 12) { m = 1; y++ }
      this.year = y; this.month = m
      this.loadCalendar(); this.loadStats()
    },
    goToday () {
      const now = new Date()
      this.year = now.getFullYear(); this.month = now.getMonth() + 1
      this.loadCalendar(); this.loadStats()
    },
    openSetDialog (cell) {
      this.currentDate = cell.date
      this.currentCell = this.dayMap[cell.date] || null
      this.setVisible = true
    },
    async doExport () {
      this.exporting = true
      try {
        const params = { start_date: `${this.year}-${String(this.month).padStart(2, '0')}-01`, end_date: `${this.year}-${String(this.month).padStart(2, '0')}-${String(new Date(this.year, this.month, 0).getDate()).padStart(2, '0')}` }
        if (this.filters.department_id) params.department_id = this.filters.department_id
        if (this.employeeId) params.employee_id = this.employeeId
        const r = await exportSchedule(params)
        if (r.code === 0 && r.data && r.data.url) window.open(r.data.url, '_blank')
        else this.$message.error('导出失败')
      } catch (e) {} finally { this.exporting = false }
    }
  }
}
</script>

<style scoped>
.schedule-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.toolbar-card { margin-bottom: 16px; }
.toolbar { display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
.month-nav, .filters, .actions { display: flex; align-items: center; gap: 6px; }
.month-label { font-size: 16px; font-weight: 600; margin-left: 6px; }
.cal-card { margin-bottom: 16px; }
.cal-head { display: grid; grid-template-columns: repeat(7, 1fr); background: #f5f7fa; border-radius: 6px 6px 0 0; }
.cal-head-cell { text-align: center; padding: 10px 0; font-size: 13px; color: #606266; font-weight: 600; }
.cal-body { display: grid; grid-template-columns: repeat(7, 1fr); border: 1px solid #EBEEF5; border-top: none; }
.cal-cell { min-height: 72px; border: 1px solid #f0f2f5; padding: 4px 6px; cursor: pointer; position: relative; }
.cal-cell:hover { background: #f5f7fa; }
.cal-cell.is-rest { background: #fafafa; }
.cal-date { font-size: 12px; color: #909399; }
.cal-shift { margin-top: 4px; font-size: 11px; padding: 2px 6px; border-radius: 4px; border: 1px solid; display: inline-block; max-width: 100%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.cal-rest { margin-top: 4px; font-size: 11px; color: #C0C4CC; }
.cal-tip { padding: 30px; text-align: center; color: #909399; }
.stat-card { margin-bottom: 16px; }
.stat-title { font-size: 14px; font-weight: 600; margin-bottom: 10px; }
.stat-items { display: flex; gap: 20px; font-size: 13px; color: #606266; flex-wrap: wrap; }
.stat-unassigned { margin-top: 10px; font-size: 12px; color: #E6A23C; }
</style>
