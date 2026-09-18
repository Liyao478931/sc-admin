<!--
  文件：admin/src/views/hr/salary/slip/List.vue
  功能：工资条查询（多维度筛选/预览打印/导出/补发通知）
  权限：hr:salary:slip:list:view / view / export / resend
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>薪酬管理</el-breadcrumb-item>
      <el-breadcrumb-item>工资条</el-breadcrumb-item>
      <el-breadcrumb-item>工资条查询</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索与筛选区域 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="工资月份">
          <el-date-picker v-model="query.month" type="month" value-format="yyyy-MM" placeholder="全部月份" clearable style="width:130px" @change="handleSearch" />
        </el-form-item>
        <el-form-item label="部门">
          <el-select v-model="query.department_id" multiple filterable clearable placeholder="全部" style="width:180px">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="员工姓名"><el-input v-model="query.user_name" placeholder="请输入员工姓名" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="工资条编号"><el-input v-model="query.slip_no" placeholder="请输入工资条编号" clearable style="width:170px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="工资条状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:130px">
            <el-option label="已生成" :value="1" />
            <el-option label="已发送" :value="2" />
            <el-option label="已签收" :value="3" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 操作按钮栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'hr:salary:slip:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button v-permission="'hr:salary:slip:resend'" size="small" icon="el-icon-message" @click="openResendDialog">批量发送通知</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
      </div>
      <div class="toolbar-right">
        <span class="total-text">共 {{ total }} 条</span>
        <span class="total-text" style="margin-left:12px">
          已生成 <b style="color:#409EFF">{{ stats[1] }}</b> 条 / 已发送 <b style="color:#67C23A">{{ stats[2] }}</b> 条 / 已签收 <b style="color:#9B59B6">{{ stats[3] }}</b> 条
        </span>
      </div>
    </div>

    <!-- 数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe
      @selection-change="handleSelectionChange" empty-text="暂无工资条数据，请先在「生成工资条」中生成">
      <el-table-column type="selection" width="55" align="center" />
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="工资条编号" width="150">
        <template slot-scope="s"><span class="slip-no" @click="openPreview(s.row.id)">{{ s.row.slip_no }}</span></template>
      </el-table-column>
      <el-table-column prop="user_name" label="员工姓名" width="90" />
      <el-table-column prop="department_name" label="部门" width="120" show-overflow-tooltip />
      <el-table-column prop="rank_name" label="职级" width="100" show-overflow-tooltip />
      <el-table-column prop="calc_month" label="工资月份" width="120" align="center" />
      <el-table-column label="实发工资" width="130" align="right"><template slot-scope="s"><b style="color:#67C23A">¥ {{ fmt(s.row.net_salary) }}</b></template></el-table-column>
      <el-table-column label="工资条状态" width="110" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="generated_at" label="生成时间" width="160" align="center" />
      <el-table-column label="操作" width="200" align="center" fixed="right">
        <template slot-scope="s">
          <el-button v-permission="'hr:salary:slip:view'" type="text" size="mini" @click="openPreview(s.row.id)">预览</el-button>
          <el-button v-if="s.row.status === 1" v-permission="'hr:salary:slip:resend'" type="text" size="mini" @click="handleResend(s.row)">发送通知</el-button>
          <el-button v-permission="'hr:salary:slip:view'" type="text" size="mini" @click="handlePrint(s.row)">打印</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页组件 -->
    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 工资条预览对话框 -->
    <el-dialog :title="`${preview.user_name || ''} ${preview.calc_month || ''} 工资条`" :visible.sync="previewVisible" width="700px" top="6vh" append-to-body>
      <div v-if="preview.user_name" class="slip-preview">
        <div class="slip-head">
          <div class="slip-company">{{ preview.company_name || '数智管控平台' }}</div>
          <div class="slip-title">{{ preview.calc_month }} 工资条</div>
          <div class="slip-info">
            姓名：{{ preview.user_name }} &nbsp;|&nbsp; 部门：{{ preview.department_name }} &nbsp;|&nbsp;
            职级：{{ preview.rank_name }} &nbsp;|&nbsp; 员工类型：{{ preview.employee_type_label }}
          </div>
        </div>
        <el-table :data="previewRows" size="mini" border class="slip-table">
          <el-table-column prop="name" label="项目名称" />
          <el-table-column prop="amount" label="金额" width="180" align="right" />
        </el-table>
        <div class="slip-foot">
          <div>生成日期：{{ preview.generated_at || '-' }}</div>
          <div class="slip-tip">温馨提示：本工资条仅供参考，如有疑问请联系人力资源部。</div>
        </div>
      </div>
      <div slot="footer">
        <el-button size="small" icon="el-icon-printer" @click="handlePrintPreview">打印</el-button>
        <el-button size="small" type="primary" @click="previewVisible = false">关闭</el-button>
      </div>
    </el-dialog>

    <!-- 补发通知对话框 -->
    <el-dialog title="补发工资条通知" :visible.sync="resendVisible" width="600px" top="8vh" append-to-body>
      <el-form label-width="90px" size="small">
        <el-form-item label="通知方式">
          <el-checkbox-group v-model="resendForm.channels">
            <el-checkbox label="inbox">站内信</el-checkbox>
            <el-checkbox label="email">邮件通知</el-checkbox>
            <el-checkbox label="wechat">小程序通知</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="通知模板">
          <el-input v-model="resendForm.template" type="textarea" :rows="4" placeholder="您的 {month} 工资条已生成，请点击查看：{link}" />
        </el-form-item>
        <el-form-item label="发送对象">
          <span class="total-text">将向 <b style="color:#409EFF">{{ resendTargetCount }}</b> 名员工补发工资条通知</span>
        </el-form-item>
        <el-form-item label="发送范围">
          <el-radio-group v-model="resendForm.scope">
            <el-radio label="selected">选中的 {{ selectedResendCount }} 名员工</el-radio>
            <el-radio label="filter">当前筛选条件下的所有员工</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="resendVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="resending" @click="handleResendBatch">确认发送</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getSlipList, previewSlip, exportSlip, resendSlip, batchResendSlip } from '@/api/salarySlip'
import { getDepartmentOptions } from '@/api/attendanceStatistics'

export default {
  name: 'HrSalarySlipList',
  data () {
    return {
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false, resending: false,
      query: { month: '', department_id: [], user_name: '', slip_no: '', status: '' },
      stats: { 1: 0, 2: 0, 3: 0 },
      deptOptions: [], multipleSelection: [],
      previewVisible: false, preview: {}, previewRows: [],
      resendVisible: false, resendForm: { channels: ['inbox'], template: '', scope: 'selected' }
    }
  },
  computed: {
    selectedResendCount () {
      return this.multipleSelection.filter(r => r.status === 1 || r.status === 2).length
    },
    resendTargetCount () {
      if (this.resendForm.scope === 'filter') return this.list.filter(r => r.status === 1 || r.status === 2).length
      return this.selectedResendCount
    }
  },
  created () {
    this.loadDepts()
    this.loadData()
  },
  methods: {
    fmt (v) { return Number(v || 0).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) },
    async loadDepts () {
      try {
        const r = await getDepartmentOptions()
        const out = []; const walk = (nodes) => { (nodes || []).forEach(n => { out.push({ id: n.id, name: n.name }); walk(n.children) }) }
        walk(r.data); this.deptOptions = out
      } catch (e) { this.deptOptions = [] }
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.month) p.month = this.query.month
      if (this.query.department_id && this.query.department_id.length) p.department_id = this.query.department_id
      if (this.query.user_name) p.user_name = this.query.user_name
      if (this.query.slip_no) p.slip_no = this.query.slip_no
      if (this.query.status !== '' && this.query.status !== null) p.status = this.query.status
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getSlipList(this.buildParams())
        if (r.code === 0 && r.data) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.stats = r.data.stats || { 1: 0, 2: 0, 3: 0 }
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () { this.query = { month: '', department_id: [], user_name: '', slip_no: '', status: '' }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    handleSelectionChange (rows) { this.multipleSelection = rows },
    async openPreview (id) {
      this.previewVisible = true
      this.preview = {}
      this.previewRows = []
      try {
        const r = await previewSlip(id)
        if (r.code === 0 && r.data) {
          this.preview = r.data
          const rows = []
          // 完整明细（收入项 + 扣除项）
          const sd = r.data.slip_data || {}
          const incomeItems = sd.income_items || []
          const deductionItems = sd.deduction_items || []
          if (incomeItems.length) {
            rows.push({ name: '—— 收入项 ——', amount: '', type: 'group' })
            incomeItems.forEach(it => {
              if (Number(it.amount) !== 0) rows.push({ name: it.name, amount: '¥ ' + this.fmt(it.amount) })
            })
            rows.push({ name: '收入合计', amount: '¥ ' + this.fmt(sd.total_income != null ? sd.total_income : incomeItems.reduce((a, b) => a + Number(b.amount), 0)) })
          }
          if (deductionItems.length) {
            rows.push({ name: '—— 扣除项 ——', amount: '', type: 'group' })
            deductionItems.forEach(it => {
              if (Number(it.amount) !== 0) rows.push({ name: it.name, amount: '-¥ ' + this.fmt(it.amount) })
            })
            rows.push({ name: '扣除合计', amount: '-¥ ' + this.fmt(deductionItems.reduce((a, b) => a + Number(b.amount), 0)) })
          }
          rows.push({ name: '应发工资', amount: '¥ ' + this.fmt(r.data.gross_salary) })
          rows.push({ name: '实发工资', amount: '¥ ' + this.fmt(r.data.net_salary) })
          this.previewRows = rows
        } else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
    },
    doPrint (content) {
      if (!content) return
      const win = window.open('', '_blank')
      if (!win) { this.$message.warning('请允许浏览器弹窗以打印'); return }
      win.document.write(`<html><head><title>工资条</title><style>body{font-family:SimSun,serif;padding:30px;color:#303133}table{border-collapse:collapse;width:100%;margin:16px 0}td,th{border:1px solid #dcdfe6;padding:8px 12px;font-size:14px}.company{font-size:20px;font-weight:bold;text-align:center}.title{font-size:16px;text-align:center;margin:8px 0}.info{font-size:13px;color:#606266;margin:12px 0}.tip{color:#909399;font-size:12px;margin-top:24px}</style></head><body>${content.outerHTML}</body></html>`)
      win.document.close()
      win.print()
    },
    handlePrintPreview () {
      this.doPrint(document.querySelector('.slip-preview'))
    },
    async handlePrint (row) {
      try {
        const r = await previewSlip(row.id)
        if (r.code === 0 && r.data) {
          this.preview = r.data
          await this.$nextTick()
          this.doPrint(document.querySelector('.slip-preview'))
        }
      } catch (e) {}
    },
    async handleExport () {
      this.exporting = true
      try {
        const params = { ...this.buildParams() }
        delete params.page
        delete params.pageSize
        const r = await exportSlip(params)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          const d = new Date()
          const pad = n => String(n).padStart(2, '0')
          a.download = `工资条列表_${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}_${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}.xlsx`
          a.click()
          window.URL.revokeObjectURL(url)
        }
      } catch (e) {} finally { this.exporting = false }
    },
    openResendDialog () {
      this.resendForm = { channels: ['inbox'], template: '您的 {month} 工资条已生成，请点击查看：{link}', scope: 'selected' }
      this.resendVisible = true
    },
    async handleResend (row) {
      try {
        const r = await resendSlip(row.id)
        if (r.code === 0) { this.$message.success(r.msg || '已补发'); this.loadData() } else this.$message.error(r.msg || '补发失败')
      } catch (e) {}
    },
    async handleResendBatch () {
      if (!this.resendForm.channels.length) { this.$message.warning('请至少选择一种通知方式'); return }
      this.resending = true
      try {
        const data = { scope: this.resendForm.scope, channels: this.resendForm.channels, template: this.resendForm.template }
        if (this.query.month) data.month = this.query.month
        if (this.query.department_id && this.query.department_id.length) data.department_id = this.query.department_id
        if (this.query.user_name) data.user_name = this.query.user_name
        if (this.query.slip_no) data.slip_no = this.query.slip_no
        if (this.resendForm.scope === 'selected') {
          const ids = this.multipleSelection.filter(r => r.status === 1 || r.status === 2).map(r => r.id)
          if (!ids.length) { this.$message.warning('请先选择待补发的工资条'); this.resending = false; return }
          data.ids = ids
        }
        const r = await batchResendSlip(data)
        if (r.code === 0) { this.$message.success(r.msg || '补发成功'); this.resendVisible = false; this.loadData() } else this.$message.error(r.msg || '补发失败')
      } catch (e) {} finally { this.resending = false }
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
.toolbar-right { display: flex; align-items: center; }
.total-text { color: #909399; font-size: 14px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.slip-no { color: #409EFF; cursor: pointer; }
.slip-preview { padding: 8px 4px; }
.slip-head { text-align: center; border-bottom: 2px solid #303133; padding-bottom: 12px; }
.slip-company { font-size: 20px; font-weight: bold; }
.slip-title { font-size: 16px; font-weight: 600; margin: 8px 0; }
.slip-info { font-size: 13px; color: #606266; }
.slip-table { margin: 16px 0; }
.slip-foot { font-size: 13px; color: #909399; }
.slip-tip { margin-top: 8px; }
</style>
