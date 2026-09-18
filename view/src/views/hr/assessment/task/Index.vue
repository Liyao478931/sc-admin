<!--
  文件：admin/src/views/hr/assessment/task/Index.vue
  功能：考核任务管理（筛选栏 + 统计摘要 + 任务列表 + 行内明细展开 + 弹窗）
  视觉：对齐参考模板（主色 #1e6fff）
-->
<template>
  <div class="wh-page assessment-task-page">
    <div class="page-header">
      <div class="header-left">
        <el-breadcrumb separator="/" class="breadcrumb">
          <el-breadcrumb-item>人事管理</el-breadcrumb-item>
          <el-breadcrumb-item>绩效考核</el-breadcrumb-item>
          <el-breadcrumb-item>考核任务管理</el-breadcrumb-item>
        </el-breadcrumb>
        <span class="badge-module">📋 考核任务管理</span>
      </div>
    </div>

    <div class="task-layout">
      <!-- 筛选与操作栏 -->
      <div class="filter-bar">
        <div class="filter-left">
          <el-date-picker v-model="query.month" type="month" size="small" placeholder="考核月份" value-format="yyyy-MM" :clearable="false" style="width:130px" @change="loadList" />
          <el-select v-model="query.department_id" size="small" clearable placeholder="全部部门" style="width:140px" @change="loadList">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
          <el-input v-model="query.keyword" size="small" prefix-icon="el-icon-search" clearable placeholder="员工姓名" style="width:140px" @keyup.enter.native="loadList" @clear="loadList" />
          <el-select v-model="query.status" size="small" clearable placeholder="全部状态" style="width:120px" @change="loadList">
            <el-option v-for="(t, v) in TASK_STATUS" :key="v" :label="t" :value="v" />
          </el-select>
          <el-button size="small" icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </div>
        <div class="filter-right">
          <el-button v-permission="'assessment:task:generate'" size="small" type="primary" icon="el-icon-plus" @click="openGenerate">生成考核任务</el-button>
          <el-button v-permission="'assessment:task:auto_deduct'" size="small" type="success" icon="el-icon-video-play" @click="openAutoDeduct">执行自动扣分</el-button>
          <el-button v-permission="'assessment:task:confirm'" size="small" icon="el-icon-check" @click="doBatchConfirm">批量确认</el-button>
          <el-button v-permission="'assessment:appeal:view'" size="small" icon="el-icon-message" @click="openAppealCenter">申诉处理</el-button>
          <el-button v-permission="'assessment:export'" size="small" icon="el-icon-download" @click="doExport">导出</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </div>
      </div>

      <!-- 统计摘要栏 -->
      <div class="summary-bar" v-if="summary">
        <span class="sum-item">总人数 <b>{{ summary.total_employees }}</b></span>
        <span class="sum-item">平均分 <b>{{ summary.avg_score }}</b></span>
        <span class="sum-item">最高 <b>{{ summary.max_score }}</b></span>
        <span class="sum-item">最低 <b>{{ summary.min_score }}</b></span>
        <span class="sum-item">待确认 <b class="warn">{{ summary.pending_deductions }}</b> 条</span>
        <span class="sum-item">预警 <b class="warn">{{ summary.warning_count }}</b> 人</span>
      </div>

      <!-- 任务列表 -->
      <div class="task-table-wrap">
        <el-table :data="list" v-loading="loading" size="small" border stripe @sort-change="onSortChange">
          <el-table-column type="expand">
            <template slot-scope="s">
              <div class="deduct-detail">
                <div class="deduct-title">扣分明细 - {{ s.row.employee_name }}（{{ s.row.period }}）</div>
                <el-table :data="s.row.deductions" size="mini" border stripe empty-text="暂无扣分明细">
                  <el-table-column prop="indicator_name" label="指标" min-width="120" />
                  <el-table-column prop="indicator_score" label="分值" width="60" align="center" />
                  <el-table-column prop="deduct_score" label="扣分" width="60" align="center">
                    <template slot-scope="d"><span class="deduct-num">-{{ d.row.deduct_score }}</span></template>
                  </el-table-column>
                  <el-table-column prop="reason" label="扣分原因" min-width="160" show-overflow-tooltip />
                  <el-table-column label="数据来源" width="110">
                    <template slot-scope="d">{{ d.row.data_source_text }} {{ d.row.data_source_detail ? '·' + d.row.data_source_detail : '' }}</template>
                  </el-table-column>
                  <el-table-column prop="status_text" label="状态" width="80" align="center" />
                  <el-table-column label="操作" width="120" align="center">
                    <template slot-scope="d">
                      <el-button v-if="d.row.status === 0" type="text" size="mini" @click="doConfirmDeduction(d.row)">确认</el-button>
                      <el-button v-if="d.row.status === 0" type="text" size="mini" @click="openAppeal(d.row)">申诉</el-button>
                      <el-button v-if="d.row.attachments && d.row.attachments.length" type="text" size="mini" @click="showAttachments(d.row)">附件</el-button>
                    </template>
                  </el-table-column>
                </el-table>
                <div class="deduct-footer">小计：扣分 {{ s.row.total_deduct }} 分 | 当前得分 {{ s.row.total_score || '—' }} 分</div>
              </div>
            </template>
          </el-table-column>
          <el-table-column type="index" label="#" width="55" align="center" fixed="left" />
          <el-table-column prop="employee_name" label="姓名" width="90" fixed="left" />
          <el-table-column prop="department_name" label="部门" width="110" />
          <el-table-column prop="position" label="岗位" width="110" />
          <el-table-column prop="period" label="月份" width="90" align="center" />
          <el-table-column label="状态" width="90" align="center">
            <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_text }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="total_score" label="得分" width="80" align="center" sortable="custom">
            <template slot-scope="s">{{ s.row.total_score > 0 ? s.row.total_score : '—' }}</template>
          </el-table-column>
          <el-table-column prop="grade" label="等级" width="70" align="center">
            <template slot-scope="s"><span v-if="s.row.grade" class="grade-badge">{{ s.row.grade }}</span><span v-else>—</span></template>
          </el-table-column>
          <el-table-column prop="deduction_amount" label="考核扣款" width="95" align="right">
            <template slot-scope="s">{{ s.row.deduction_amount ? s.row.deduction_amount : '—' }}</template>
          </el-table-column>
          <el-table-column prop="reward_amount" label="考核奖励" width="95" align="right">
            <template slot-scope="s">{{ s.row.reward_amount ? s.row.reward_amount : '—' }}</template>
          </el-table-column>
          <el-table-column label="扣分项" width="80" align="center">
            <template slot-scope="s"><span :class="{ 'warn-text': s.row.pending_count > 0 }">{{ s.row.deduction_count }}<span v-if="s.row.pending_count" class="pending-tag">({{ s.row.pending_count }})</span></span></template>
          </el-table-column>
          <el-table-column label="操作" width="210" align="center" fixed="right">
            <template slot-scope="s">
              <el-button type="text" size="mini" @click="loadDetail(s.row)">明细</el-button>
              <el-button v-permission="'assessment:task:manual_deduct'" v-if="s.row.status < 3" type="text" size="mini" @click="openManualDeduct(s.row)">手动扣分</el-button>
              <el-button v-permission="'assessment:task:confirm'" v-if="s.row.status === 1" type="text" size="mini" @click="doConfirmTask(s.row)">确认</el-button>
              <el-button v-permission="'assessment:task:approve'" v-if="s.row.status === 2" type="text" size="mini" @click="openApprove(s.row)">审批</el-button>
            </template>
          </el-table-column>
        </el-table>
        <div class="pager">
          <el-pagination background layout="total, prev, pager, next" :total="total" :page-size="limit" :current-page="page" @current-change="onPageChange" />
        </div>
      </div>
    </div>

    <!-- 生成任务弹窗 -->
    <el-dialog title="生成考核任务" :visible.sync="generateVisible" width="520px" :close-on-click-modal="false">
      <el-form label-width="90px" size="small">
        <el-form-item label="考核月份"><el-date-picker v-model="generateForm.month" type="month" value-format="yyyy-MM" style="width:100%" :clearable="false" /></el-form-item>
        <el-form-item label="考核模板">
          <el-select v-model="generateForm.template_id" style="width:100%" placeholder="选择模板">
            <el-option v-for="t in templateOptions" :key="t.id" :label="t.name + '（' + t.category + '）' + (t.status === 0 ? '·停用' : '')" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="适用岗位">
          <el-select v-model="generateForm.category" style="width:100%" clearable placeholder="全部岗位">
            <el-option v-for="c in CATEGORIES" :key="c" :label="c" :value="c" />
          </el-select>
        </el-form-item>
        <el-form-item label="指定部门">
          <el-select v-model="generateForm.department_id" style="width:100%" clearable placeholder="全部部门">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-alert type="info" :closable="false" show-icon title="将按模板为员工生成考核任务；已存在任务（同员工同月份）的将被跳过。" />
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="generateVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="generating" @click="doGenerate">确认生成</el-button>
      </div>
    </el-dialog>

    <!-- 自动扣分弹窗 -->
    <el-dialog title="执行自动扣分" :visible.sync="autoVisible" width="520px" :close-on-click-modal="false">
      <el-form label-width="90px" size="small">
        <el-form-item label="考核月份"><el-date-picker v-model="autoForm.month" type="month" value-format="yyyy-MM" style="width:100%" :clearable="false" /></el-form-item>
        <el-form-item label="执行范围">
          <el-radio-group v-model="autoForm.scope">
            <el-radio label="all">全部待评分任务</el-radio>
            <el-radio label="dept">指定部门</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="autoForm.scope === 'dept'" label="部门">
          <el-select v-model="autoForm.department_id" style="width:100%">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="扣分策略">
          <el-radio-group v-model="autoForm.strategy">
            <el-radio :label="1">追加扣分（不覆盖已有）</el-radio>
            <el-radio :label="2">重新计算（覆盖已有）</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-alert type="warning" :closable="false" show-icon title="自动扣分从生产、保养、安全、培训等系统取数；考勤/质检/考试数据源暂未接入（跳过并记录日志）。" />
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="autoVisible = false">取消</el-button>
        <el-button size="small" type="success" :loading="autoRunning" @click="doAutoDeduct">开始执行</el-button>
      </div>
    </el-dialog>

    <!-- 手动扣分弹窗 -->
    <el-dialog title="手动录入扣分" :visible.sync="manualVisible" width="520px" :close-on-click-modal="false">
      <el-form label-width="90px" size="small">
        <el-form-item label="员工"><span>{{ manualForm.employee_name }}（{{ manualForm.department_name }}）</span></el-form-item>
        <el-form-item label="考核指标">
          <el-select v-model="manualForm.indicator_id" style="width:100%" placeholder="选择指标">
            <el-option v-for="i in manualForm.snapshot" :key="i.id" :label="i.name + '（' + i.score + '分）' + (i.status === 0 ? '·停用' : '')" :value="i.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="扣分分值"><el-input-number v-model="manualForm.deduct_score" :min="0.5" :step="0.5" :precision="1" style="width:100%" /></el-form-item>
        <el-form-item label="扣分原因"><el-input v-model="manualForm.reason" type="textarea" :rows="2" placeholder="扣分原因" /></el-form-item>
        <el-form-item label="通知员工"><el-switch v-model="manualForm.notify" :active-value="1" :inactive-value="0" active-text="是" inactive-text="否" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="manualVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="manualSaving" @click="doManualDeduct">提交扣分</el-button>
      </div>
    </el-dialog>

    <!-- 员工申诉弹窗 -->
    <el-dialog title="发起申诉" :visible.sync="appealVisible" width="480px" :close-on-click-modal="false">
      <el-form label-width="90px" size="small">
        <el-form-item label="申诉指标"><span>{{ appealForm.indicator_name }} | 扣分：{{ appealForm.deduct_score }} 分</span></el-form-item>
        <el-form-item label="申诉理由"><el-input v-model="appealForm.reason" type="textarea" :rows="4" placeholder="申诉理由" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="appealVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="appealSaving" @click="doAppeal">提交申诉</el-button>
      </div>
    </el-dialog>

    <!-- 审批弹窗 -->
    <el-dialog title="审批考核任务" :visible.sync="approveVisible" width="480px" :close-on-click-modal="false">
      <el-form label-width="90px" size="small">
        <el-form-item label="审批结果">
          <el-radio-group v-model="approveForm.status">
            <el-radio :label="1">通过（联动工资）</el-radio>
            <el-radio :label="2">驳回（退回待确认）</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="审批意见"><el-input v-model="approveForm.remark" type="textarea" :rows="3" placeholder="审批意见" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="approveVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="approving" @click="doApprove">确认处理</el-button>
      </div>
    </el-dialog>

    <!-- 申诉中心弹窗 -->
    <el-dialog title="申诉处理中心" :visible.sync="appealCenterVisible" width="760px" top="5vh" :close-on-click-modal="false">
      <el-select v-model="appealQuery.status" size="small" clearable placeholder="全部状态" style="width:120px; margin-bottom:10px;" @change="loadAppeals">
        <el-option label="待处理" :value="0" /><el-option label="已通过" :value="1" /><el-option label="已驳回" :value="2" />
      </el-select>
      <el-table :data="appeals" v-loading="appealLoading" size="small" border stripe max-height="420">
        <el-table-column prop="employee_name" label="申诉人" width="90" />
        <el-table-column prop="reason" label="扣分原因" min-width="140" show-overflow-tooltip />
        <el-table-column prop="deduct_score" label="扣分" width="60" align="center" />
        <el-table-column prop="appeal_reason" label="申诉理由" min-width="160" show-overflow-tooltip />
        <el-table-column prop="status_text" label="状态" width="80" align="center" />
        <el-table-column label="操作" width="90" align="center">
          <template slot-scope="s">
            <el-button v-permission="'assessment:appeal:handle'" v-if="s.row.status === 0" type="text" size="mini" @click="openHandleAppeal(s.row)">处理</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div slot="footer"><el-button size="small" @click="appealCenterVisible = false">关闭</el-button></div>
    </el-dialog>

    <!-- 申诉处理弹窗 -->
    <el-dialog title="处理申诉" :visible.sync="handleAppealVisible" width="520px" :close-on-click-modal="false">
      <el-form label-width="90px" size="small">
        <el-form-item label="申诉人"><span>{{ handleForm.employee_name }}</span></el-form-item>
        <el-form-item label="申诉理由"><div class="appeal-text">{{ handleForm.appeal_reason }}</div></el-form-item>
        <el-form-item label="处理结果">
          <el-radio-group v-model="handleForm.status">
            <el-radio :label="1">通过（撤销扣分）</el-radio>
            <el-radio :label="2">驳回（维持扣分）</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="处理意见"><el-input v-model="handleForm.handler_reply" type="textarea" :rows="3" placeholder="处理意见" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="handleAppealVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="handleSaving" @click="doHandleAppeal">确认处理</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import request from '@/api/request'
import {
  getTaskList, getTaskDetail, generateTasks, runAutoDeduct, manualDeduct,
  confirmDeduction, confirmTask, approveTask, batchConfirmTasks,
  getAppealList, handleAppeal, createAppeal, exportAssessmentReport
} from '@/api/assessment'

const TASK_STATUS = { 0: '待评分', 1: '待确认', 2: '已确认', 3: '已审批', 4: '已结束' }
const CATEGORIES = ['操作工', '维修工', '质检员', '班组长', '管理人员']

export default {
  name: 'AssessmentTaskIndex',
  data () {
    const now = new Date()
    const ym = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`
    return {
      TASK_STATUS, CATEGORIES,
      query: { month: ym, department_id: '', keyword: '', status: '' },
      deptOptions: [], templateOptions: [],
      list: [], total: 0, page: 1, limit: 20, loading: false, summary: null,
      // 弹窗
      generateVisible: false, generating: false,
      generateForm: { month: ym, template_id: '', category: '', department_id: '' },
      autoVisible: false, autoRunning: false,
      autoForm: { month: ym, scope: 'all', department_id: '', strategy: 1 },
      manualVisible: false, manualSaving: false,
      manualForm: { task_id: 0, employee_name: '', department_name: '', indicator_id: '', deduct_score: 1, reason: '', notify: 1, snapshot: [] },
      appealVisible: false, appealSaving: false,
      appealForm: { deduction_id: 0, indicator_name: '', deduct_score: 0, reason: '' },
      approveVisible: false, approving: false,
      approveForm: { task_id: 0, status: 1, remark: '' },
      appealCenterVisible: false, appealLoading: false, appealQuery: { status: '' },
      appeals: [],
      handleAppealVisible: false, handleSaving: false,
      handleForm: { id: 0, employee_name: '', appeal_reason: '', status: 1, handler_reply: '' }
    }
  },
  created () {
    this.initFromQuery()
    this.loadDepts()
    this.loadTemplates()
    this.loadList()
  },
  methods: {
    // 从 URL query 初始化筛选（支持考核看板下钻）
    initFromQuery () {
      const q = this.$route.query || {}
      if (q.year) {
        const m = q.month ? parseInt(q.month) : (new Date().getMonth() + 1)
        this.query.month = `${q.year}-${String(m).padStart(2, '0')}`
      } else if (q.month && /^\d{4}-\d{2}$/.test(String(q.month))) {
        this.query.month = String(q.month)
      }
      if (q.department_id) this.query.department_id = Number(q.department_id)
      if (q.keyword) this.query.keyword = String(q.keyword)
      if (q.status !== undefined && q.status !== '') this.query.status = Number(q.status)
      if (q.grade) this._gradeFilter = String(q.grade)
      if (q.sort) this._sortFilter = String(q.sort)
    },
    // ===== 基础数据 =====
    async loadDepts () {
      try {
        const r = await request({ url: '/departments/tree', method: 'get' })
        if (r.code === 0) {
          const flat = []
          const walk = (nodes) => { (nodes || []).forEach(n => { flat.push({ id: n.id, name: n.name }); if (n.children) walk(n.children) }) }
          walk(r.data)
          this.deptOptions = flat
        }
      } catch (e) {}
    },
    async loadTemplates () {
      try {
        const r = await request({ url: '/assessment/templates', method: 'get', params: { page: 1, limit: 100 } })
        if (r.code === 0 && r.data) this.templateOptions = r.data.list || []
      } catch (e) {}
    },
    // ===== 列表 =====
    async loadList () {
      if (!this.query.month) return
      this.loading = true
      try {
        const ym = this.query.month.split('-')
        const params = { year: parseInt(ym[0]), month: parseInt(ym[1]), page: this.page, limit: this.limit }
        if (this.query.department_id) params.department_id = this.query.department_id
        if (this.query.keyword) params.keyword = this.query.keyword
        if (this.query.status !== '') params.status = this.query.status
        if (this._gradeFilter) params.grade = this._gradeFilter
        if (this._sortFilter) params.sort = this._sortFilter
        const r = await getTaskList(params)
        if (r.code === 0 && r.data) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.summary = r.data.summary || null
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleReset () {
      const now = new Date()
      this.query = { month: `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`, department_id: '', keyword: '', status: '' }
      this.page = 1
      this.loadList()
    },
    onPageChange (p) { this.page = p; this.loadList() },
    onSortChange ({ prop, order }) {
      // 前端简单排序
      if (order) {
        const dir = order === 'ascending' ? 1 : -1
        this.list = [...this.list].sort((a, b) => (a[prop] - b[prop]) * dir)
      }
    },
    // ===== 明细 =====
    async loadDetail (row) {
      const expanded = this.$refs.table ? null : null
      try {
        const r = await getTaskDetail(row.id)
        if (r.code === 0 && r.data) {
          const target = this.list.find(x => x.id === row.id)
          if (target) {
            target.deductions = r.data.deductions || []
            target.total_deduct = (target.deductions || []).reduce((s, d) => s + Number(d.deduct_score || 0), 0)
          }
        }
      } catch (e) {}
      void expanded
    },
    // ===== 生成任务 =====
    openGenerate () { this.generateVisible = true },
    async doGenerate () {
      if (!this.generateForm.template_id) { this.$message.warning('请选择考核模板'); return }
      this.generating = true
      try {
        const ym = this.generateForm.month.split('-')
        const data = { year: parseInt(ym[0]), month: parseInt(ym[1]), template_id: this.generateForm.template_id }
        if (this.generateForm.category) data.category = this.generateForm.category
        if (this.generateForm.department_id) data.department_id = this.generateForm.department_id
        const r = await generateTasks(data)
        if (r.code === 0) {
          this.$message.success(`${r.msg}：生成 ${r.data.created} 个，跳过 ${r.data.skipped} 个`)
          this.generateVisible = false
          this.page = 1
          this.loadList()
        } else this.$message.error(r.msg || '生成失败')
      } catch (e) {} finally { this.generating = false }
    },
    // ===== 自动扣分 =====
    openAutoDeduct () { this.autoVisible = true },
    async doAutoDeduct () {
      this.autoRunning = true
      try {
        const ym = this.autoForm.month.split('-')
        const data = { year: parseInt(ym[0]), month: parseInt(ym[1]), strategy: this.autoForm.strategy }
        if (this.autoForm.scope === 'dept' && this.autoForm.department_id) data.department_id = this.autoForm.department_id
        const r = await runAutoDeduct(data)
        if (r.code === 0) {
          this.$message.success(`${r.msg}：成功 ${r.data.ok}，跳过 ${r.data.skip}，失败 ${r.data.error}`)
          this.autoVisible = false
          this.loadList()
        } else this.$message.error(r.msg || '执行失败')
      } catch (e) {} finally { this.autoRunning = false }
    },
    // ===== 手动扣分 =====
    openManualDeduct (row) {
      this.manualForm = { task_id: row.id, employee_name: row.employee_name, department_name: row.department_name, indicator_id: '', deduct_score: 1, reason: '', notify: 1, snapshot: [] }
      this.manualVisible = true
      // 加载快照指标
      getTaskDetail(row.id).then(r => {
        if (r.code === 0 && r.data) this.manualForm.snapshot = (r.data.task.snapshot || []).filter(i => i.status === 1)
      }).catch(() => {})
    },
    async doManualDeduct () {
      if (!this.manualForm.indicator_id) { this.$message.warning('请选择考核指标'); return }
      if (!this.manualForm.reason.trim()) { this.$message.warning('请填写扣分原因'); return }
      this.manualSaving = true
      try {
        const r = await manualDeduct({
          task_id: this.manualForm.task_id, indicator_id: this.manualForm.indicator_id,
          deduct_score: this.manualForm.deduct_score, reason: this.manualForm.reason, notify: this.manualForm.notify
        })
        if (r.code === 0) { this.$message.success('扣分已提交'); this.manualVisible = false; this.loadList() } else this.$message.error(r.msg || '提交失败')
      } catch (e) {} finally { this.manualSaving = false }
    },
    // ===== 确认 / 审批 =====
    doConfirmDeduction (ded) {
      this.$confirm(`确认该条扣分（${ded.reason}）吗？`, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await confirmDeduction([ded.id])
          if (r.code === 0) { this.$message.success('已确认'); this.loadList() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    doConfirmTask (row) {
      this.$confirm(`确认任务「${row.employee_name} ${row.period}」吗？将自动计算得分与等级。`, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await confirmTask(row.id)
          if (r.code === 0) { this.$message.success(`已确认，得分 ${r.data.total_score}，等级 ${r.data.grade}`); this.loadList() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    doBatchConfirm () {
      const ids = this.list.filter(x => x.status === 1).map(x => x.id)
      if (!ids.length) { this.$message.warning('当前没有待确认的任务'); return }
      this.$confirm(`批量确认 ${ids.length} 个「待确认」任务？`, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await batchConfirmTasks(ids)
          if (r.code === 0) { this.$message.success(`已确认 ${r.data.ok} 个`); this.loadList() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    openApprove (row) {
      this.approveForm = { task_id: row.id, status: 1, remark: '' }
      this.approveVisible = true
    },
    async doApprove () {
      this.approving = true
      try {
        const r = await approveTask(this.approveForm.task_id, { status: this.approveForm.status, remark: this.approveForm.remark })
        if (r.code === 0) {
          this.$message.success(r.msg || '处理完成')
          this.approveVisible = false
          this.loadList()
        } else this.$message.error(r.msg || '操作失败')
      } catch (e) {} finally { this.approving = false }
    },
    // ===== 申诉 =====
    openAppeal (ded) {
      this.appealForm = { deduction_id: ded.id, indicator_name: ded.indicator_name, deduct_score: ded.deduct_score, reason: '' }
      this.appealVisible = true
    },
    async doAppeal () {
      if (!this.appealForm.reason.trim()) { this.$message.warning('请填写申诉理由'); return }
      this.appealSaving = true
      try {
        const r = await createAppeal({ deduction_id: this.appealForm.deduction_id, appeal_reason: this.appealForm.reason })
        if (r.code === 0) { this.$message.success('申诉已提交'); this.appealVisible = false; this.loadList() } else this.$message.error(r.msg || '提交失败')
      } catch (e) {} finally { this.appealSaving = false }
    },
    openAppealCenter () {
      this.appealCenterVisible = true
      this.loadAppeals()
    },
    async loadAppeals () {
      this.appealLoading = true
      try {
        const params = { page: 1, limit: 50 }
        if (this.appealQuery.status !== '') params.status = this.appealQuery.status
        const r = await getAppealList(params)
        if (r.code === 0 && r.data) this.appeals = r.data.list || []
      } catch (e) {} finally { this.appealLoading = false }
    },
    openHandleAppeal (row) {
      this.handleForm = { id: row.id, employee_name: row.employee_name, appeal_reason: row.appeal_reason, status: 1, handler_reply: '' }
      this.handleAppealVisible = true
    },
    async doHandleAppeal () {
      if (!this.handleForm.handler_reply.trim()) { this.$message.warning('请填写处理意见'); return }
      this.handleSaving = true
      try {
        const r = await handleAppeal(this.handleForm.id, { status: this.handleForm.status, handler_reply: this.handleForm.handler_reply })
        if (r.code === 0) { this.$message.success('处理完成'); this.handleAppealVisible = false; this.loadAppeals(); this.loadList() } else this.$message.error(r.msg || '处理失败')
      } catch (e) {} finally { this.handleSaving = false }
    },
    // ===== 附件 / 导出 =====
    showAttachments (ded) {
      if (!ded.attachments || !ded.attachments.length) return
      this.$alert(ded.attachments.map((a, i) => `${i + 1}. ${a}`).join('<br/>'), '附件', { dangerouslyUseHTMLString: true })
    },
    async doExport () {
      if (!this.query.month) { this.$message.warning('请选择月份'); return }
      const ym = this.query.month.split('-')
      try {
        const params = { year: parseInt(ym[0]), month: parseInt(ym[1]) }
        if (this.query.department_id) params.department_id = this.query.department_id
        const r = await exportAssessmentReport(params)
        const blob = new Blob([r.data], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `考核报表_${this.query.month}.xlsx`
        a.click()
        URL.revokeObjectURL(url)
        this.$message.success('导出成功')
      } catch (e) { this.$message.error('导出失败') }
    }
  }
}
</script>

<style scoped>
.assessment-task-page { padding: 16px; }
.page-header { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; padding: 12px 18px; background: #fafbfc; border: 1px solid #e8ecf1; border-bottom: none; border-radius: 12px 12px 0 0; }
.header-left { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.header-left .breadcrumb { font-size: 14px; color: #8c8f9c; }
.header-left .breadcrumb >>> .el-breadcrumb__inner { color: #8c8f9c; }
.header-left .breadcrumb >>> .el-breadcrumb__item:last-child .el-breadcrumb__inner { color: #1d2129; font-weight: 500; }
.badge-module { background: #e8f3ff; color: #1e6fff; font-size: 12px; padding: 2px 12px; border-radius: 12px; font-weight: 500; }
.task-layout { border: 1px solid #e8ecf1; border-radius: 0 0 12px 12px; background: #fff; overflow: hidden; }
.filter-bar { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 10px; padding: 14px 18px; border-bottom: 1px solid #e8ecf1; background: #fafbfc; }
.filter-left { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.filter-right { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.summary-bar { display: flex; align-items: center; gap: 28px; flex-wrap: wrap; padding: 12px 18px; border-bottom: 1px solid #e8ecf1; background: #fff; }
.sum-item { font-size: 13px; color: #4e5a6b; }
.sum-item b { color: #1e6fff; font-size: 15px; margin-left: 4px; }
.sum-item b.warn { color: #f77234; }
.task-table-wrap { padding: 14px 18px; }
.pager { display: flex; justify-content: flex-end; margin-top: 12px; }
.deduct-detail { padding: 10px 20px; background: #fafbfc; }
.deduct-title { font-size: 13px; font-weight: 600; color: #1d2129; margin-bottom: 8px; }
.deduct-footer { margin-top: 8px; font-size: 12px; color: #4e5a6b; }
.deduct-num { color: #f53f3f; font-weight: 600; }
.warn-text { color: #f77234; font-weight: 600; }
.pending-tag { font-size: 11px; color: #f77234; }
.grade-badge { display: inline-block; background: #e8f3ff; color: #1e6fff; width: 24px; height: 24px; line-height: 24px; border-radius: 50%; font-weight: 600; }
.appeal-text { background: #f7f9fc; border-radius: 8px; padding: 10px; font-size: 13px; color: #4e5a6b; line-height: 1.6; width: 100%; }
</style>

<!-- 模块级主题覆盖 -->
<style>
.assessment-task-page .el-button--primary { background-color: #1e6fff; border-color: #1e6fff; }
.assessment-task-page .el-button--primary:hover, .assessment-task-page .el-button--primary:focus { background-color: #4d8bff; border-color: #4d8bff; }
.assessment-task-page .el-button--success { background-color: #00b42a; border-color: #00b42a; }
.assessment-task-page .el-button--success:hover, .assessment-task-page .el-button--success:focus { background-color: #27c346; border-color: #27c346; }
.assessment-task-page .el-switch.is-checked .el-switch__core { border-color: #1e6fff; background-color: #1e6fff; }
.assessment-task-page .el-radio__input.is-checked .el-radio__inner { border-color: #1e6fff; background: #1e6fff; }
.assessment-task-page .el-radio__input.is-checked + .el-radio__label { color: #1e6fff; }
.assessment-task-page .el-input__inner:focus, .assessment-task-page .el-textarea__inner:focus { border-color: #1e6fff; }
.assessment-task-page .el-pagination.is-background .el-pager li:not(.disabled).active { background-color: #1e6fff; }
</style>
