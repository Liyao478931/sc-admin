<!--
  文件：admin/src/views/hr/salary/payroll/Index.vue
  功能：工资计算（执行计算/确认/导出/统计卡片/工资明细抽屉）
  权限：hr:salary:payroll:view/calculate/confirm/export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>薪酬管理</el-breadcrumb-item>
      <el-breadcrumb-item>工资核算</el-breadcrumb-item>
      <el-breadcrumb-item>工资计算</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="计算月份">
          <el-date-picker v-model="query.month" type="month" value-format="yyyy-MM" style="width:130px" />
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

    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'hr:salary:payroll:calculate'" type="primary" size="small" icon="el-icon-cpu" :loading="calculating" @click="handleCalculate">执行计算</el-button>
        <el-button v-permission="'hr:salary:config:view'" size="small" icon="el-icon-setting" @click="$router.push({ path: '/hr/salary/config' })">工资配置</el-button>
        <el-button v-if="calc && calc.status === 1" v-permission="'hr:salary:payroll:confirm'" size="small" type="warning" @click="handleConfirm">确认工资</el-button>
        <el-button v-permission="'hr:salary:payroll:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出报表</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 人</span>
    </div>

    <el-row :gutter="16" class="stat-row">
      <el-col :span="6"><div class="stat-card stat-blue"><div class="stat-icon"><i class="el-icon-user" /></div><div class="stat-info"><div class="stat-num">{{ calc ? calc.total_employee : 0 }} <span class="stat-unit">人</span></div><div class="stat-label">总人数</div></div></div></el-col>
      <el-col :span="6"><div class="stat-card stat-green"><div class="stat-icon"><i class="el-icon-money" /></div><div class="stat-info"><div class="stat-num" style="color:#67C23A">¥ {{ calc ? fmt(calc.total_gross_salary) : '0.00' }}</div><div class="stat-label">应发工资合计</div></div></div></el-col>
      <el-col :span="6"><div class="stat-card stat-orange"><div class="stat-icon"><i class="el-icon-coin" /></div><div class="stat-info"><div class="stat-num" style="color:#E6A23C">¥ {{ calc ? fmt(calc.total_net_salary) : '0.00' }}</div><div class="stat-label">实发工资合计</div></div></div></el-col>
      <el-col :span="6"><div class="stat-card stat-purple"><div class="stat-icon"><i class="el-icon-data-line" /></div><div class="stat-info"><div class="stat-num" style="color:#9B59B6">¥ {{ calc && calc.total_employee ? fmt(calc.total_net_salary / calc.total_employee) : '0.00' }}</div><div class="stat-label">平均工资</div></div></div></el-col>
    </el-row>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无工资数据，请点击「执行计算」生成该月工资">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column prop="user_name" label="员工姓名" width="90" />
      <el-table-column prop="department_name" label="部门" width="120" show-overflow-tooltip />
      <el-table-column prop="position_name" label="岗位" width="100" show-overflow-tooltip />
      <el-table-column prop="rank_name" label="职级" width="90" show-overflow-tooltip />
      <el-table-column label="员工类型" width="110" align="center">
        <template slot-scope="s"><el-tag :type="s.row.employee_type === 1 ? 'primary' : 'info'" size="mini">{{ s.row.employee_type === 1 ? '车间岗位工' : '科员' }}</el-tag></template>
      </el-table-column>
      <el-table-column label="基本工资" width="110" align="right"><template slot-scope="s">¥ {{ fmt(s.row.base_salary) }}</template></el-table-column>
      <el-table-column label="工分" width="80" align="right"><template slot-scope="s">{{ s.row.employee_type === 1 ? Number(s.row.piecework_score) + ' 分' : '-' }}</template></el-table-column>
      <el-table-column label="工分单价" width="90" align="right"><template slot-scope="s">{{ s.row.employee_type === 1 ? Number(s.row.piecework_price).toFixed(2) + ' 元/分' : '-' }}</template></el-table-column>
      <el-table-column label="计件工资" width="110" align="right"><template slot-scope="s">{{ s.row.employee_type === 1 ? '¥ ' + fmt(s.row.piecework_wage) : '-' }}</template></el-table-column>
      <el-table-column label="津贴合计" width="100" align="right"><template slot-scope="s">¥ {{ fmt(s.row.allowance_total) }}</template></el-table-column>
      <el-table-column label="扣款合计" width="100" align="right"><template slot-scope="s">¥ {{ fmt(s.row.deduction_total) }}</template></el-table-column>
      <el-table-column label="应发工资" width="110" align="right"><template slot-scope="s"><b>¥ {{ fmt(s.row.gross_salary) }}</b></template></el-table-column>
      <el-table-column label="实发工资" width="110" align="right"><template slot-scope="s"><b style="color:#67C23A">¥ {{ fmt(s.row.net_salary) }}</b></template></el-table-column>
      <el-table-column label="操作" width="120" align="center" fixed="right">
        <template slot-scope="s"><el-button type="text" size="mini" @click="openDetail(s.row)">查看明细</el-button></template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 工资明细抽屉 -->
    <el-drawer :title="`${detail.user_name || ''} ${query.month} 工资明细`" :visible.sync="drawerVisible" size="700px" :close-on-press-escape="true">
      <div v-if="detail.user_id" class="drawer-body">
        <el-descriptions :column="3" border size="small" style="margin-bottom:16px">
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
import { getPayrollList, calculatePayroll, confirmPayroll, getPayrollDetail, exportPayroll } from '@/api/salaryPayroll'
import { getDepartmentOptions } from '@/api/attendanceStatistics'

export default {
  name: 'HrPayrollIndex',
  data () {
    return {
      list: [], total: 0, page: 1, pageSize: 10, loading: false, calculating: false, exporting: false,
      query: { month: this.currentMonth(), department_id: [], user_name: '' },
      calc: null, deptOptions: [],
      drawerVisible: false, detail: {}, allowanceRows: [], deductionRows: []
    }
  },
  created () {
    this.loadDepts()
    this.loadData()
  },
  methods: {
    currentMonth () { const d = new Date(); return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}` },
    fmt (v) { return Number(v || 0).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) },
    async loadDepts () {
      try {
        const r = await getDepartmentOptions()
        const out = []; const walk = (nodes) => { (nodes || []).forEach(n => { out.push({ id: n.id, name: n.name }); walk(n.children) }) }
        walk(r.data); this.deptOptions = out
      } catch (e) { this.deptOptions = [] }
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize, month: this.query.month }
      if (this.query.department_id && this.query.department_id.length) p.department_id = this.query.department_id
      if (this.query.user_name) p.user_name = this.query.user_name
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getPayrollList(this.buildParams())
        if (r.code === 0 && r.data) {
          this.calc = r.data.calc || null
          this.list = r.data.list || []
          this.total = r.data.total || 0
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () { this.query = { month: this.currentMonth(), department_id: [], user_name: '' }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    handleCalculate () {
      this.$confirm(`确认对 ${this.query.month} 进行工资计算吗？将重新计算所有员工的工资数据。`, '执行计算', { type: 'warning' }).then(async () => {
        this.calculating = true
        try {
          const r = await calculatePayroll({ month: this.query.month })
          if (r.code === 0) { this.$message.success(r.msg || '工资计算完成'); this.loadData() } else this.$message.error(r.msg || '计算失败')
        } catch (e) {} finally { this.calculating = false }
      }).catch(() => {})
    },
    handleConfirm () {
      this.$confirm(`确认 ${this.query.month} 的工资数据吗？确认后状态变为已确认。`, '确认工资', { type: 'warning' }).then(async () => {
        try {
          const r = await confirmPayroll(this.calc.id)
          if (r.code === 0) { this.$message.success('工资已确认'); this.loadData() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    async openDetail (row) {
      this.drawerVisible = true
      this.detail = {}
      this.allowanceRows = []; this.deductionRows = []
      try {
        const r = await getPayrollDetail(row.id)
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
        const r = await exportPayroll({ month: this.query.month })
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `工资报表_${this.query.month}.xlsx`
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
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.stat-row { margin-top: 16px; }
.stat-card { display: flex; align-items: center; padding: 16px 20px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); }
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
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.drawer-body { padding: 0 20px; }
.sub-title { font-size: 14px; font-weight: 600; margin-bottom: 8px; }
</style>
