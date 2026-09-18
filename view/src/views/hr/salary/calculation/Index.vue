<!--
  文件：admin/src/views/hr/salary/calculation/Index.vue
  功能：工资计算（与 Excel 一月工资模板一致，43 列明细工资表）
  权限：salary:calculation:view/execute/confirm/export + salary:insurance:import
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>薪酬管理</el-breadcrumb-item>
      <el-breadcrumb-item>工资核算</el-breadcrumb-item>
      <el-breadcrumb-item>工资计算</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 筛选与操作栏 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="70px" @submit.native.prevent>
        <el-form-item label="计算月份">
          <el-date-picker v-model="query.month" type="month" value-format="yyyy-MM" style="width:140px" @change="handleSearch" />
        </el-form-item>
        <el-form-item label="部门">
          <el-select v-model="query.department_id" clearable placeholder="全部部门" style="width:140px" @change="handleSearch">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.label" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="姓名">
          <el-input v-model="query.keyword" placeholder="请输入员工姓名" clearable style="width:160px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
          <el-button type="primary" icon="el-icon-cpu" :loading="executing" @click="handleExecute">执行计算</el-button>
          <el-button icon="el-icon-upload2" :loading="importing" @click="importVisible = true">导入社保</el-button>
          <el-button v-if="saved" type="success" icon="el-icon-check" :disabled="status === 1" @click="handleConfirm">确认工资</el-button>
          <el-button icon="el-icon-download" :loading="exporting" @click="handleExport">导出报表</el-button>
          <el-button type="success" icon="el-icon-printer" :disabled="!total" @click="handlePrint">打印工资表</el-button>
          <el-button icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 统计摘要 -->
    <div v-if="summary" class="summary-bar">
      <span class="sum-item">总人数：<b>{{ summary.total }}</b></span>
      <span class="sum-item">应发工资合计：<b style="color:#409EFF">{{ fmtMoney(summary.total_income) }}</b></span>
      <span class="sum-item">实发工资合计：<b style="color:#67C23A">{{ fmtMoney(summary.total_net) }}</b></span>
      <span class="sum-item">平均工资：<b style="color:#e6a23c">{{ fmtMoney(summary.avg_net) }}</b></span>
      <el-tag v-if="saved" :type="status === 1 ? 'success' : 'warning'" size="mini" style="margin-left:10px">{{ status === 1 ? '已确认' : '已保存' }}</el-tag>
    </div>

    <!-- 明细工资表（43列多级表头） -->
    <el-table :data="list" v-loading="loading" size="small" border stripe :max-height="600" empty-text="请选择月份并执行计算" @expand-change="handleExpand">
      <el-table-column type="expand" width="40">
        <template slot-scope="props">
          <div class="detail-box">
            <el-table :data="detailRows" size="mini" border>
              <el-table-column prop="item" label="项目" width="140" />
              <el-table-column prop="standard" label="标准值" width="120" align="right" />
              <el-table-column prop="formula" label="计算公式" min-width="220" />
              <el-table-column prop="result" label="结果" width="120" align="right" />
            </el-table>
          </div>
        </template>
      </el-table-column>
      <el-table-column type="index" label="序号/工号" width="70" fixed="left" align="center" />
      <el-table-column prop="employee_name" label="姓名" width="80" fixed="left" />
      <el-table-column prop="department_name" label="部门" width="100" fixed="left" show-overflow-tooltip />
      <el-table-column prop="position_name" label="定级级别" width="130" fixed="left" show-overflow-tooltip />

      <el-table-column label="考勤数据" align="center">
        <el-table-column prop="work_days" label="正常工作日（天数）" width="110" align="right" />
        <el-table-column prop="overtime_sat" label="周六加班" width="80" align="right" />
        <el-table-column prop="overtime_sun" label="周日加班" width="80" align="right" />
        <el-table-column prop="overtime_holiday" label="节假日加班" width="90" align="right" />
        <el-table-column prop="overtime_other" label="其它加班" width="80" align="right" />
        <el-table-column prop="leave_days" label="调休" width="70" align="right" />
      </el-table-column>

      <el-table-column label="工资标准" align="center">
        <el-table-column prop="basic_wage_standard" label="基本工资标准" width="110" align="right"><template slot-scope="s">{{ fmtMoney(s.row.basic_wage_standard) }}</template></el-table-column>
        <el-table-column prop="position_wage_standard" label="职务/岗位工资" width="110" align="right"><template slot-scope="s">{{ fmtMoney(s.row.position_wage_standard) }}</template></el-table-column>
        <el-table-column prop="daily_assessment_standard" label="日常考核工资" width="110" align="right"><template slot-scope="s">{{ fmtMoney(s.row.daily_assessment_standard) }}</template></el-table-column>
      </el-table-column>

      <el-table-column label="实际出勤工资" align="center">
        <el-table-column prop="actual_basic_wage" label="当月基本工资" width="110" align="right"><template slot-scope="s">{{ fmtMoney(s.row.actual_basic_wage) }}</template></el-table-column>
        <el-table-column prop="overtime_pay" label="加班工资" width="170" align="right"><template slot-scope="s">{{ fmtMoney(s.row.overtime_pay) }}</template></el-table-column>
        <el-table-column prop="actual_position_wage" label="当月岗位工资" width="120" align="right"><template slot-scope="s">{{ fmtMoney(s.row.actual_position_wage) }}</template></el-table-column>
        <el-table-column prop="actual_daily_assessment" label="当月日常考核" width="110" align="right"><template slot-scope="s">{{ fmtMoney(s.row.actual_daily_assessment) }}</template></el-table-column>
      </el-table-column>

      <el-table-column label="工龄工资" align="center">
        <el-table-column prop="entry_date" label="参加工作时间" width="110" align="center" />
        <el-table-column prop="seniority_wage" label="工龄工资" width="90" align="right"><template slot-scope="s">{{ fmtMoney(s.row.seniority_wage) }}</template></el-table-column>
      </el-table-column>

      <el-table-column label="补助工资" align="center">
        <el-table-column prop="education_subsidy" label="学历补助" width="90" align="right"><template slot-scope="s">{{ fmtMoney(s.row.education_subsidy) }}</template></el-table-column>
        <el-table-column prop="title_subsidy" label="职称补助" width="90" align="right"><template slot-scope="s">{{ fmtMoney(s.row.title_subsidy) }}</template></el-table-column>
        <el-table-column prop="night_shift_subsidy" label="夜班补助" width="90" align="right"><template slot-scope="s">{{ fmtMoney(s.row.night_shift_subsidy) }}</template></el-table-column>
        <el-table-column prop="duty_subsidy" label="值班补助" width="90" align="right"><template slot-scope="s">{{ fmtMoney(s.row.duty_subsidy) }}</template></el-table-column>
        <el-table-column prop="driver_allowance" label="司机津贴" width="90" align="right"><template slot-scope="s">{{ fmtMoney(s.row.driver_allowance) }}</template></el-table-column>
        <el-table-column prop="washing_fee" label="洗理费" width="80" align="right"><template slot-scope="s">{{ fmtMoney(s.row.washing_fee) }}</template></el-table-column>
      </el-table-column>

      <el-table-column label="考核/计件" align="center">
        <el-table-column prop="assessment_score" label="扣分/加分" width="80" align="right" />
        <el-table-column prop="assessment_deduction" label="考核扣款" width="110" align="right"><template slot-scope="s">{{ fmtMoney(s.row.assessment_deduction) }}</template></el-table-column>
        <el-table-column prop="piece_points" label="本月工分" width="100" align="right" />
        <el-table-column prop="piece_unit_price" label="工分单价" width="110" align="right" />
        <el-table-column prop="piece_wage" label="计件金额" width="90" align="right"><template slot-scope="s">{{ fmtMoney(s.row.piece_wage) }}</template></el-table-column>
        <el-table-column prop="supplement" label="补差" width="80" align="right"><template slot-scope="s">{{ fmtMoney(s.row.supplement) }}</template></el-table-column>
      </el-table-column>

      <el-table-column prop="total_income" label="应税收入合计" width="140" align="right"><template slot-scope="s"><b style="color:#409EFF">{{ fmtMoney(s.row.total_income) }}</b></template></el-table-column>

      <el-table-column label="专项扣除" align="center">
        <el-table-column prop="insurance_pension" label="养老保险" width="120" align="right"><template slot-scope="s">{{ fmtMoney(s.row.insurance_pension) }}</template></el-table-column>
        <el-table-column prop="insurance_medical" label="医疗保险" width="120" align="right"><template slot-scope="s">{{ fmtMoney(s.row.insurance_medical) }}</template></el-table-column>
        <el-table-column prop="insurance_unemployment" label="失业保险" width="110" align="right"><template slot-scope="s">{{ fmtMoney(s.row.insurance_unemployment) }}</template></el-table-column>
        <el-table-column prop="insurance_housing_fund" label="住房公积金" width="110" align="right"><template slot-scope="s">{{ fmtMoney(s.row.insurance_housing_fund) }}</template></el-table-column>
        <el-table-column prop="insurance_annuity" label="年金" width="90" align="right"><template slot-scope="s">{{ fmtMoney(s.row.insurance_annuity) }}</template></el-table-column>
        <el-table-column prop="insurance_company" label="代扣社保集体" width="130" align="right"><template slot-scope="s">{{ fmtMoney(s.row.insurance_company) }}</template></el-table-column>
      </el-table-column>

      <el-table-column label="其它扣除项" align="center">
        <el-table-column prop="union_fee" label="会员费" width="80" align="right"><template slot-scope="s">{{ fmtMoney(s.row.union_fee) }}</template></el-table-column>
        <el-table-column prop="serious_illness" label="大病" width="70" align="right"><template slot-scope="s">{{ fmtMoney(s.row.serious_illness) }}</template></el-table-column>
        <el-table-column prop="income_tax" label="个税" width="80" align="right"><template slot-scope="s">{{ fmtMoney(s.row.income_tax) }}</template></el-table-column>
      </el-table-column>

  <el-table-column prop="net_pay" label="实发工资" width="130" align="right" fixed="right"><template slot-scope="s"><b style="color:#67C23A">{{ fmtMoney(s.row.net_pay) }}</b></template></el-table-column>
</el-table>

    <el-pagination class="pager" background layout="total,sizes,prev,pager,next" :total="total"
      :current-page="page" :page-size="limit" :page-sizes="[10,20,50,100]"
      @size-change="s => { limit = s; page = 1; loadData() }"
      @current-change="p => { page = p; loadData() }" />

    <!-- 社保导入弹窗 -->
    <el-dialog :title="`导入社保公积金数据（${query.month}）`" :visible.sync="importVisible" width="480px" :close-on-click-modal="false" @open="loadTempStatus">
      <div class="import-box">
        <div v-if="tempStatus !== null" class="temp-status" :class="tempStatus > 0 ? 'has' : 'empty'">
          {{ query.month }} 已暂存 <b>{{ tempStatus }}</b> 条社保数据{{ tempStatus > 0 ? '，重新导入将覆盖' : '' }}
        </div>
        <el-button size="small" icon="el-icon-download" @click="downloadTemplate">下载导入模板</el-button>
        <el-upload drag action="#" :auto-upload="false" :on-change="onImportFile" :limit="1" accept=".xlsx,.xls,.csv">
          <i class="el-icon-upload"></i>
          <div class="el-upload__text">将 Excel 文件拖到此处，或<em>点击上传</em></div>
        </el-upload>
        <el-radio-group v-model="importStrategy" style="margin-top:14px;">
          <el-radio label="overwrite">覆盖已有社保数据</el-radio>
          <el-radio label="skip">只更新空白数据</el-radio>
        </el-radio-group>
        <div class="import-tip">暂存到 {{ query.month }} 月份；切换月份可分别导入，执行工资计算时使用对应月份暂存数据<br>模板字段：序号、姓名、工号、部门、养老保险、医疗保险、失业保险、住房公积金、年金、代扣社保集体、个税</div>
      </div>
      <div slot="footer">
        <el-button size="small" @click="importVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="importing" @click="doImport">暂存到 {{ query.month }}</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getDeptTree } from '@/api/organization'
import request from '@/api/request'

function flattenDept(nodes) {
  let r = []
  for (const n of nodes) { r.push(n); if (n.children) r = r.concat(flattenDept(n.children)) }
  return r
}

export default {
  name: 'SalaryCalculation',
  data () {
    const now = new Date()
    return {
      query: { month: `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`, department_id: '', keyword: '' },
      deptOptions: [], list: [], total: 0, page: 1, limit: 20, loading: false,
      summary: null, saved: false, status: 0, sheetId: 0,
      executing: false, importing: false, exporting: false,
      importVisible: false, importFile: null, importStrategy: 'overwrite', tempStatus: null,
      detailRows: []
    }
  },
  created () { this.loadDepts(); this.loadData() },
  methods: {
    fmtMoney (v) { return Number(v || 0).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) },
    monthParts () { const [y, m] = this.query.month.split('-'); return { year: parseInt(y), month: parseInt(m) } },
    async loadDepts () {
      try {
        const r = await getDeptTree()
        if (r.code === 0) this.deptOptions = flattenDept(r.data || []).map(d => ({ id: d.id, label: d.name }))
      } catch (e) {}
    },
    buildParams () {
      const { year, month } = this.monthParts()
      const p = { year, month, page: this.page, limit: this.limit }
      if (this.query.department_id) p.department_id = this.query.department_id
      if (this.query.keyword) p.keyword = this.query.keyword
      return p
    },
    async loadData () {
      if (!this.query.month) { this.$message.warning('请选择计算月份'); return }
      this.loading = true
      try {
        const r = await request({ url: '/salary/calculation/data', method: 'get', params: this.buildParams() })
        if (r.code === 0 && r.data) {
          this.list = (r.data.list || []).map(x => ({ ...x, _show: false }))
          this.total = r.data.total || 0
          this.summary = r.data.summary
          this.saved = r.data.saved
          this.sheetId = r.data.sheet_id || 0
          this.status = r.data.status || 0
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () { this.query = { month: this.query.month, department_id: '', keyword: '' }; this.handleSearch() },
    async handleExecute () {
      this.$confirm(`确认对 ${this.query.month} 执行工资计算？将按 Excel 模板公式重新计算所有员工工资。`, '执行计算', { type: 'warning' }).then(async () => {
        this.executing = true
        try {
          const { year, month } = this.monthParts()
          const r = await request({ url: '/salary/calculation/execute', method: 'post', data: { year, month } })
          if (r.code === 0) { this.$message.success(r.msg || '计算完成'); this.page = 1; this.loadData() } else this.$message.error(r.msg || '计算失败')
        } catch (e) { this.$message.error('计算失败') } finally { this.executing = false }
      }).catch(() => {})
    },
    async handleConfirm () {
      this.$confirm('确认工资后将锁定数据，不可再修改。确认继续？', '确认工资', { type: 'warning' }).then(async () => {
        try {
          const { year, month } = this.monthParts()
          const r = await request({ url: '/salary/calculation/confirm', method: 'post', data: { year, month } })
          if (r.code === 0) { this.$message.success('工资已确认'); this.loadData() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    async handleExport () {
      this.exporting = true
      try {
        const { year, month } = this.monthParts()
        const r = await request({ url: '/salary/calculation/export', method: 'get', params: { year, month }, responseType: 'blob' })
        const blob = new Blob([r.data], { type: 'text/csv;charset=utf-8' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `工资表_${year}-${month}.csv`
        a.click()
        URL.revokeObjectURL(url)
        this.$message.success('导出成功')
      } catch (e) { this.$message.error('导出失败') } finally { this.exporting = false }
    },
    handleExpand (row, expandedRows) {
      // 展开时构建当前行明细；收起时清空
      if (expandedRows && expandedRows.includes(row)) {
        this.detailRows = this.buildDetailRows(row)
      }
    },
    buildDetailRows (row) {
      return [
        { item: '基本工资', standard: this.fmtMoney(row.basic_wage_standard), formula: '出勤≥标准全额，否则按差额扣减', result: this.fmtMoney(row.actual_basic_wage) },
        { item: '岗位工资', standard: this.fmtMoney(row.position_wage_standard), formula: '按出勤+周末加班折算', result: this.fmtMoney(row.actual_position_wage) },
        { item: '日常考核', standard: this.fmtMoney(row.daily_assessment_standard), formula: '出勤<16天为0，否则按比例', result: this.fmtMoney(row.actual_daily_assessment) },
        { item: '加班工资', standard: '-', formula: `(基本/22)×(周六${row.overtime_sat}×2+周日${row.overtime_sun}×2+节假日${row.overtime_holiday}×3)`, result: this.fmtMoney(row.overtime_pay) },
        { item: '工龄工资', standard: `${row.seniority_years}年`, formula: '工龄×每1年金额，按出勤比例', result: this.fmtMoney(row.seniority_wage) },
        { item: '学历补助', standard: '-', formula: '按员工学历匹配', result: this.fmtMoney(row.education_subsidy) },
        { item: '职称补助', standard: '-', formula: '按员工职称匹配', result: this.fmtMoney(row.title_subsidy) },
        { item: '洗理费', standard: '-', formula: '出勤≥16天发放35元', result: this.fmtMoney(row.washing_fee) },
        { item: '计件工资', standard: `${row.piece_points}分×${row.piece_unit_price}元`, formula: '工分×单价', result: this.fmtMoney(row.piece_wage) },
        { item: '应税收入合计', standard: '-', formula: '各项收入之和', result: this.fmtMoney(row.total_income) },
        { item: '社保公积金', standard: '-', formula: '按导入数据', result: this.fmtMoney(row.insurance_pension + row.insurance_medical + row.insurance_unemployment + row.insurance_housing_fund + row.insurance_annuity) },
        { item: '个税', standard: '-', formula: '按导入数据', result: this.fmtMoney(row.income_tax) },
        { item: '实发工资', standard: '-', formula: '应税-各项扣除', result: this.fmtMoney(row.net_pay) }
      ]
    },
    onImportFile (file) { this.importFile = file.raw },
    async loadTempStatus () {
      this.tempStatus = null
      try {
        const { year, month } = this.monthParts()
        const r = await request({ url: '/salary/calculation/insurance-temp-status', method: 'get', params: { year, month } })
        if (r.code === 0 && r.data) this.tempStatus = r.data.count || 0
      } catch (e) { this.tempStatus = 0 }
    },
    async downloadTemplate () {
      try {
        const { year, month } = this.monthParts()
        const r = await request({ url: '/salary/calculation/insurance-template', method: 'get', params: { year, month }, responseType: 'blob' })
        const blob = new Blob([r.data], { type: 'text/csv;charset=utf-8' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `社保导入模板_${year}-${month}.csv`
        a.click()
        URL.revokeObjectURL(url)
        this.$message.success('模板已下载')
      } catch (e) { this.$message.error('模板下载失败') }
    },
    async doImport () {
      if (!this.importFile) { this.$message.warning('请选择 Excel 文件'); return }
      this.importing = true
      try {
        const { year, month } = this.monthParts()
        const fd = new FormData()
        fd.append('file', this.importFile)
        fd.append('year', year)
        fd.append('month', month)
        fd.append('conflict_strategy', this.importStrategy)
        const r = await request({ url: '/salary/calculation/insurance-import', method: 'post', data: fd })
        if (r.code === 0) { this.$message.success(r.msg || '导入成功'); this.importVisible = false; this.importFile = null; this.loadData() } else this.$message.error(r.msg || '导入失败')
      } catch (e) { this.$message.error('导入失败') } finally { this.importing = false }
    },
    // ===== 打印功能（独立窗口打印） =====
    async handlePrint () {
      // 获取全部数据（不受分页限制）
      const { year, month } = this.monthParts()
      let rows = this.list
      try {
        const r = await request({ url: '/salary/calculation/data', method: 'get', params: { year, month, limit: 1000 } })
        if (r.code === 0 && r.data && r.data.list) rows = r.data.list
      } catch (e) {}
      if (!rows.length) { this.$message.warning('暂无数据可打印'); return }
      const html = this.buildPrintHtml(rows, year, month)
      const win = window.open('', '_blank', 'width=1400,height=900')
      if (!win) { this.$message.error('请允许浏览器弹出窗口后重试'); return }
      win.document.write(html)
      win.document.close()
      win.focus()
      setTimeout(() => { win.print() }, 500)
    },
    buildPrintHtml (rows, year, month) {
      const title = `山西大运华能装备制造有限公司${year}年${month}月工资表`
      const fmt = v => Number(v || 0).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
      let totalIncome = 0; let totalNet = 0; let totalBasic = 0; let totalPos = 0; let totalDaily = 0; let totalOT = 0; let totalSeniority = 0
      rows.forEach(r => {
        totalIncome += Number(r.total_income || 0); totalNet += Number(r.net_pay || 0)
        totalBasic += Number(r.actual_basic_wage || 0); totalPos += Number(r.actual_position_wage || 0)
        totalDaily += Number(r.actual_daily_assessment || 0); totalOT += Number(r.overtime_pay || 0)
        totalSeniority += Number(r.seniority_wage || 0)
      })
      const buildRow = (r, i) => {
        return `<tr>
          <td class="num">${i + 1}</td><td class="txt">${r.employee_name || ''}</td><td class="txt">${r.department_name || ''}</td><td class="txt">${r.position_name || ''}</td>
          <td class="num">${r.work_days || 0}</td><td class="num">${r.overtime_sat || 0}</td><td class="num">${r.overtime_sun || 0}</td><td class="num">${r.overtime_holiday || 0}</td><td class="num">${r.overtime_other || 0}</td><td class="num">${r.leave_days || 0}</td>
          <td class="num">${fmt(r.basic_wage_standard)}</td><td class="num">${fmt(r.position_wage_standard)}</td><td class="num">${fmt(r.daily_assessment_standard)}</td>
          <td class="num">${fmt(r.actual_basic_wage)}</td><td class="num">${fmt(r.overtime_pay)}</td><td class="num">${fmt(r.actual_position_wage)}</td><td class="num">${fmt(r.actual_daily_assessment)}</td>
          <td class="num">${fmt(r.seniority_wage)}</td><td class="txt">${r.entry_date || ''}</td>
          <td class="num">${fmt(r.education_subsidy)}</td><td class="num">${fmt(r.title_subsidy)}</td><td class="num">${fmt(r.night_shift_subsidy)}</td><td class="num">${fmt(r.duty_subsidy)}</td><td class="num">${fmt(r.driver_allowance)}</td><td class="num">${fmt(r.washing_fee)}</td>
          <td class="num">${r.assessment_score || 0}</td><td class="num">${fmt(r.assessment_deduction)}</td><td class="num">${r.piece_points || 0}</td><td class="num">${r.piece_unit_price || 0}</td><td class="num">${fmt(r.piece_wage)}</td><td class="num">${fmt(r.supplement)}</td>
          <td class="num total">${fmt(r.total_income)}</td>
          <td class="num">${fmt(r.insurance_pension)}</td><td class="num">${fmt(r.insurance_medical)}</td><td class="num">${fmt(r.insurance_unemployment)}</td><td class="num">${fmt(r.insurance_housing_fund)}</td><td class="num">${fmt(r.insurance_annuity)}</td><td class="num">${fmt(r.insurance_company)}</td>
          <td class="num">${fmt(r.union_fee)}</td><td class="num">${fmt(r.serious_illness)}</td><td class="num">${fmt(r.income_tax)}</td>
          <td class="num total">${fmt(r.net_pay)}</td>
        </tr>`
      }
      // 动态计算统一字号：A3 横向可用宽度约 1156pt，42 列，数字列不换行
      const calcFont = () => {
        const usable = 1156
        const cols = 42
        const size = Math.floor(usable / (cols * 5.2))
        return Math.max(7, Math.min(12, size))
      }
      const fontSize = calcFont()
      return `<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<title>${title}</title>
<style>
  @page { size: A3 landscape; margin: 8mm 6mm; }
  body { font-family: '宋体', SimSun, serif; font-size: ${fontSize}pt; color: #000; margin: 0; padding: 0; }
  .print-title { text-align: center; font-size: 48pt; font-weight: bold; padding: 12px 0; letter-spacing: 2px; }
  .print-sub { text-align: center; font-size: 12pt; color: #333; margin-bottom: 6px; }
  table { width: 100%; max-width: 100%; border-collapse: separate; border-spacing: 0; font-size: ${fontSize}pt; table-layout: auto; }
  th, td { border: 1px solid #000; padding: 2px 3px; text-align: center; font-size: ${fontSize}pt; line-height: 1.2; }
  th { background: #d9e1f2; font-weight: bold; white-space: normal; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  td.num { white-space: nowrap; }
  td.txt { max-height: 2.4em; overflow: hidden; }
  thead { display: table-header-group; }
  .total { font-weight: bold; }
  .total-row td { background: #f0f0f0; font-weight: bold; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  .print-footer { text-align: right; font-size: 10pt; margin-top: 6px; }
</style>
</head>
<body>
<div class="print-title">${title}</div>
<div class="print-sub">打印日期：${new Date().toLocaleDateString('zh-CN')}</div>
<table>
  <thead>
    <tr>
      <th rowspan="2">序号</th><th rowspan="2">姓名</th><th rowspan="2">部门</th><th rowspan="2">定级级别</th>
      <th colspan="6">考勤数据</th>
      <th colspan="3">工资标准</th>
      <th colspan="4">实际出勤工资</th>
      <th colspan="2">工龄工资</th>
      <th colspan="6">补助工资</th>
      <th colspan="6">考核/计件</th>
      <th rowspan="2">应税收入合计</th>
      <th colspan="6">专项扣除</th>
      <th colspan="3">其它扣除项</th>
      <th rowspan="2">实发工资</th>
    </tr>
    <tr>
      <th>正常工作日（天数）</th><th>周六加班</th><th>周日加班</th><th>节假日加班</th><th>其它加班</th><th>调休</th>
      <th>基本工资标准</th><th>职务/岗位工资</th><th>日常考核工资</th>
      <th>当月基本工资</th><th>加班工资</th><th>当月岗位工资</th><th>当月日常考核</th>
      <th>工龄工资</th><th>参加工作时间</th>
      <th>学历补助</th><th>职称补助</th><th>夜班补助</th><th>值班补助</th><th>司机津贴</th><th>洗理费</th>
      <th>扣分/加分</th><th>考核扣款</th><th>本月工分</th><th>工分单价</th><th>计件金额</th><th>补差</th>
      <th>养老保险</th><th>医疗保险</th><th>失业保险</th><th>住房公积金</th><th>年金</th><th>代扣社保集体</th>
      <th>会员费</th><th>大病</th><th>个税</th>
    </tr>
  </thead>
  <tbody>
    ${rows.map((r, i) => buildRow(r, i)).join('')}
    <tr class="total-row">
      <td colspan="4">合计（${rows.length}人）</td>
      <td colspan="6"></td>
      <td colspan="3"></td>
      <td>${fmt(totalBasic)}</td><td>${fmt(totalOT)}</td><td>${fmt(totalPos)}</td><td>${fmt(totalDaily)}</td>
      <td>${fmt(totalSeniority)}</td><td></td>
      <td colspan="6"></td>
      <td colspan="6"></td>
      <td class="total">${fmt(totalIncome)}</td>
      <td colspan="6"></td>
      <td colspan="3"></td>
      <td class="total">${fmt(totalNet)}</td>
    </tr>
  </tbody>
</table>
<div class="print-footer">第 1 页 / 共 ${Math.ceil(rows.length / 25) || 1} 页</div>
</body>
</html>`
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.summary-bar { background: #fff; padding: 10px 20px; border-bottom: 1px solid #ebeef5; display: flex; align-items: center; gap: 24px; flex-wrap: wrap; font-size: 13px; }
.sum-item b { font-size: 16px; }
.pager { margin-top: 16px; text-align: right; }
.detail-box { padding: 8px 0; }
.import-box { text-align: center; }
.import-tip { font-size: 12px; color: #909399; margin-top: 12px; line-height: 1.7; text-align: left; }
.temp-status { font-size: 13px; padding: 8px 12px; border-radius: 8px; margin-bottom: 10px; text-align: left; }
.temp-status.has { background: #fdf6ec; color: #e6a23c; }
.temp-status.empty { background: #f0f9eb; color: #67c23a; }
</style>
