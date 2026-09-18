<template>
  <div class="training-plan-page">
    <!-- 统计卡片 -->
    <div class="stat-row">
      <div v-for="card in statCards" :key="card.key" class="stat-card-flex" @click="quickFilter(card)">
        <div class="stat-icon" :style="{ background: card.color + '1a', color: card.color }"><i :class="card.icon"></i></div>
        <div class="stat-info">
          <div class="stat-val" :style="{ color: card.color }">{{ card.value }}</div>
          <div class="stat-label">{{ card.label }}</div>
        </div>
      </div>
    </div>

    <!-- 筛选区域 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <el-form :inline="true" size="small">
        <el-form-item><el-input v-model="filters.keyword" placeholder="计划名称/编号" clearable style="width:180px" @keyup.enter.native="onSearch" /></el-form-item>
        <el-form-item>
          <el-select v-model="filters.training_type_id" clearable filterable placeholder="全部类型" style="width:130px" @change="onSearch">
            <el-option v-for="t in typeOptions" :key="t.id" :label="t.type_name" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.training_mode" clearable placeholder="全部方式" style="width:110px" @change="onSearch">
            <el-option v-for="m in modeOptions" :key="m.value" :label="m.label" :value="m.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width:110px" @change="onSearch">
            <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.responsible_id" clearable filterable placeholder="全部负责人" style="width:120px" @change="onSearch">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" placeholder="计划日期范围" style="width:240px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilters">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 工具栏 + 表格 -->
    <el-card shadow="never">
      <div slot="header" class="card-header">
        <span style="color:#909399">共 <b style="color:#409EFF">{{ total }}</b> 条计划</span>
        <div>
          <el-button size="small" icon="el-icon-user" @click="$router.push('/safety/training/plan/teacher')">讲师管理</el-button>
          <el-button size="small" icon="el-icon-files" @click="$router.push('/safety/training/plan/courseware')">课件管理</el-button>
          <el-button v-if="hasPerm('safety:training:plan:add')" size="small" type="primary" icon="el-icon-plus" @click="openAdd">新增计划</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="refreshAll">刷新</el-button>
        </div>
      </div>

      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" />
        <el-table-column prop="plan_code" label="计划编号" width="170" show-overflow-tooltip />
        <el-table-column prop="plan_name" label="计划名称" min-width="140" show-overflow-tooltip />
        <el-table-column prop="type_name" label="培训类型" width="100" align="center" />
        <el-table-column prop="mode_text" label="培训方式" width="90" align="center" />
        <el-table-column prop="target_count" label="计划人数" width="90" align="center" />
        <el-table-column prop="completed_count" label="已完成人数" width="100" align="center" />
        <el-table-column prop="plan_start_date" label="开始日期" width="110" align="center" />
        <el-table-column prop="plan_end_date" label="结束日期" width="110" align="center" />
        <el-table-column prop="responsible_name" label="负责人" width="90" align="center" />
        <el-table-column label="状态" width="150" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="statusTagType(row.status)">{{ row.status_text }}</el-tag>
            <el-progress v-if="row.target_count > 0" :percentage="row.progress" :stroke-width="6" style="margin-top:6px" />
          </template>
        </el-table-column>
        <el-table-column label="操作" width="260" align="center" fixed="right">
          <template slot-scope="{ row }">
            <el-button v-if="row.status === 'pending' && hasPerm('safety:training:plan:edit')" size="mini" type="text" @click="openEdit(row)">编辑</el-button>
            <el-button v-if="row.status === 'pending' && hasPerm('safety:training:plan:delete')" size="mini" type="text" style="color:#F56C6C" @click="handleDelete(row)">删除</el-button>
            <el-button v-if="hasPerm('safety:training:plan:add')" size="mini" type="text" @click="handleCopy(row)">复制</el-button>
            <el-button v-if="['pending','in_progress'].indexOf(row.status) > -1 && hasPerm('safety:training:record:add')" size="mini" type="text" style="color:#67C23A" @click="handleGenerateRecord(row)">生成记录</el-button>
            <el-button v-if="row.status === 'pending' && hasPerm('safety:training:plan:edit')" size="mini" type="text" style="color:#409EFF" @click="handleExecute(row)">执行</el-button>
            <el-button v-if="row.status === 'in_progress' && hasPerm('safety:training:plan:edit')" size="mini" type="text" style="color:#67C23A" @click="handleComplete(row)">完成</el-button>
            <el-button v-if="['pending','in_progress'].indexOf(row.status) > -1 && hasPerm('safety:training:plan:edit')" size="mini" type="text" style="color:#E6A23C" @click="openCancel(row)">取消</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination style="margin-top:12px;text-align:right" background layout="total, sizes, prev, pager, next"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10, 20, 50]" @current-change="loadList" @size-change="loadList" />
    </el-card>

    <!-- 新增/编辑计划弹窗 -->
    <el-dialog :title="form.id ? '编辑计划' : '新增计划'" :visible.sync="dialogVisible" width="800px" top="4vh" append-to-body>
      <el-form :model="form" :rules="rules" ref="formRef" label-width="110px" size="small">
        <div class="form-section">基本信息</div>
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="计划名称" prop="plan_name"><el-input v-model="form.plan_name" /></el-form-item></el-col>
          <el-col :span="12">
            <el-form-item label="培训类型" prop="training_type_id">
              <el-select v-model="form.training_type_id" :disabled="lockedType" style="width:100%">
                <el-option v-for="t in typeOptions" :key="t.id" :label="t.type_name" :value="t.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="培训方式" prop="training_mode">
              <el-select v-model="form.training_mode" :disabled="lockedType" style="width:100%">
                <el-option v-for="m in modeOptions" :key="m.value" :label="m.label" :value="m.value" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="培训时长(h)"><el-input-number v-model="form.duration_hours" :min="0" style="width:100%" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="培训地点"><el-input v-model="form.location" placeholder="线下培训地点（选填）" /></el-form-item></el-col>
        </el-row>

        <div class="form-section">培训内容</div>
        <el-form-item label="培训内容"><el-input v-model="form.content" type="textarea" :rows="3" /></el-form-item>

        <div class="form-section">培训对象</div>
        <el-form-item label="对象类型" prop="target_type">
          <el-radio-group v-model="form.target_type" :disabled="lockedType" @change="onTargetTypeChange">
            <el-radio :label="'all'">全体人员</el-radio>
            <el-radio :label="'department'">指定部门</el-radio>
            <el-radio :label="'position'">指定岗位</el-radio>
            <el-radio :label="'user'">指定人员</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="form.target_type === 'department'" label="选择部门">
          <el-select v-model="form.target_ids_arr" multiple filterable :disabled="lockedType" style="width:100%" placeholder="选择部门（自动包含部门员工）">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="form.target_type === 'position'" label="选择岗位">
          <el-select v-model="form.target_ids_arr" multiple filterable :disabled="lockedType" style="width:100%" placeholder="选择岗位（自动包含岗位员工）">
            <el-option v-for="p in positionOptions" :key="p.id" :label="p.name" :value="p.id" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="form.target_type === 'user'" label="选择人员">
          <el-select v-model="form.target_ids_arr" multiple filterable :disabled="lockedType" style="width:100%" placeholder="选择具体人员">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="计划人数">
          <el-input :value="form.target_count" disabled style="width:120px" />
          <el-button v-if="form.target_count > 0" size="mini" type="text" style="margin-left:8px" @click="previewVisible = true">查看人员列表</el-button>
        </el-form-item>

        <div class="form-section">讲师和课件</div>
        <el-form-item label="培训讲师">
          <el-select v-model="form.teacher_ids_arr" multiple filterable clearable style="width:100%" placeholder="选择讲师">
            <el-option v-for="t in teacherOptions" :key="t.id" :label="t.teacher_name" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="培训课件">
          <el-select v-model="form.courseware_ids_arr" multiple filterable clearable style="width:100%" placeholder="选择课件">
            <el-option v-for="c in coursewareOptions" :key="c.id" :label="c.courseware_name" :value="c.id" />
          </el-select>
        </el-form-item>

        <div class="form-section">时间设置</div>
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="计划开始日期" prop="plan_start_date"><el-date-picker v-model="form.plan_start_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="计划结束日期" prop="plan_end_date"><el-date-picker v-model="form.plan_end_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item></el-col>
        </el-row>

        <div class="form-section">负责人</div>
        <el-form-item label="负责人">
          <el-select v-model="form.responsible_id" filterable clearable style="width:100%">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="dialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </el-dialog>

    <!-- 取消计划弹窗 -->
    <el-dialog title="取消计划" :visible.sync="cancelVisible" width="450px" append-to-body>
      <el-form :model="cancelForm" :rules="cancelRules" ref="cancelRef" label-width="90px" size="small">
        <el-form-item label="计划编号"><el-input :value="currentRow.plan_code" disabled /></el-form-item>
        <el-form-item label="取消原因" prop="cancel_reason">
          <el-input v-model="cancelForm.cancel_reason" type="textarea" :rows="3" maxlength="255" show-word-limit placeholder="请填写取消原因（必填）" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="cancelVisible = false">关闭</el-button>
        <el-button size="small" type="danger" :loading="cancelSaving" @click="handleCancelConfirm">确认取消</el-button>
      </div>
    </el-dialog>

    <!-- 人员名单预览 -->
    <target-preview-dialog :visible.sync="previewVisible" :target-type="form.target_type" :target-ids="form.target_ids_arr" />
  </div>
</template>

<script>
import { getPlanList, getPlanDetail, addPlan, editPlan, deletePlan, copyPlan, executePlan, completePlan, cancelPlan, getPlanStatistics, getTypeOptions, getTeacherOptions, getCoursewareOptions } from '@/api/safetyTraining'
import { getUserList, getDepartmentTree } from '@/api/user'
import { getPositions } from '@/api/organization'
import TargetPreviewDialog from './components/TargetPreviewDialog.vue'

export default {
  name: 'SafetyTrainingPlan',
  components: { TargetPreviewDialog },
  data() {
    return {
      loading: false, list: [], total: 0, page: 1, limit: 10,
      filters: { keyword: '', training_type_id: null, training_mode: '', status: '', responsible_id: null },
      dateRange: null,
      stats: { total: 0, pending: 0, in_progress: 0, completed: 0, cancelled: 0, completion_rate: 0 },
      typeOptions: [], teacherOptions: [], coursewareOptions: [], userOptions: [], deptOptions: [], positionOptions: [],
      modeOptions: [
        { value: 'online', label: '线上' }, { value: 'offline', label: '线下' }, { value: 'mixed', label: '混合' }
      ],
      statusOptions: [
        { value: '', label: '全部' }, { value: 'pending', label: '待执行' }, { value: 'in_progress', label: '执行中' },
        { value: 'completed', label: '已完成' }, { value: 'cancelled', label: '已取消' }
      ],
      dialogVisible: false, saving: false,
      form: this.emptyForm(),
      rules: {
        plan_name: [{ required: true, message: '计划名称必填', trigger: 'blur' }],
        training_type_id: [{ required: true, message: '请选择培训类型', trigger: 'change' }],
        training_mode: [{ required: true, message: '请选择培训方式', trigger: 'change' }],
        target_type: [{ required: true, message: '请选择对象类型', trigger: 'change' }],
        plan_start_date: [{ required: true, message: '请选择开始日期', trigger: 'change' }],
        plan_end_date: [{ required: true, message: '请选择结束日期', trigger: 'change' }]
      },
      lockedType: false,
      cancelVisible: false, cancelSaving: false, currentRow: {},
      cancelForm: { cancel_reason: '' },
      cancelRules: { cancel_reason: [{ required: true, message: '请填写取消原因', trigger: 'blur' }] },
      previewVisible: false
    }
  },
  computed: {
    statCards() {
      return [
        { key: 'total', label: '总计划数', value: this.stats.total, icon: 'el-icon-document', color: '#409EFF' },
        { key: 'pending', label: '待执行', value: this.stats.pending, icon: 'el-icon-time', color: '#409EFF' },
        { key: 'in_progress', label: '执行中', value: this.stats.in_progress, icon: 'el-icon-loading', color: '#E6A23C' },
        { key: 'completed', label: '已完成', value: this.stats.completed, icon: 'el-icon-circle-check', color: '#67C23A' },
        { key: 'completion_rate', label: '计划完成率', value: this.stats.completion_rate + '%', icon: 'el-icon-pie-chart', color: '#909399' }
      ]
    }
  },
  watch: {
    // 培训对象变化时实时计算计划人数
    'form.target_ids_arr': function () { this.calcTargetCount() }
  },
  created() {
    // 权限为空时刷新（避免新加权限未及时拉取导致按钮不显示）
    if (this.$store.state.user && this.$store.state.user.permissions && !this.$store.state.user.permissions.length) {
      this.$store.dispatch('user/loadPermissions')
    }
    this.loadList(); this.loadStats(); this.loadTypes(); this.loadTeachers(); this.loadCoursewares(); this.loadUsers(); this.loadDepts(); this.loadPositions()
  },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    emptyForm() {
      return { id: 0, plan_name: '', training_type_id: null, training_mode: 'offline', duration_hours: 2, location: '', content: '', target_type: 'all', target_ids_arr: [], target_count: 0, teacher_ids_arr: [], courseware_ids_arr: [], plan_start_date: '', plan_end_date: '', responsible_id: null, remark: '' }
    },
    statusTagType(v) {
      return { pending: 'primary', in_progress: 'warning', completed: 'success', cancelled: 'info' }[v] || 'info'
    },
    async loadList() {
      this.loading = true
      try {
        const params = {
          page: this.page, limit: this.limit,
          keyword: this.filters.keyword || '',
          training_type_id: this.filters.training_type_id || '',
          training_mode: this.filters.training_mode || '',
          status: this.filters.status || '',
          responsible_id: this.filters.responsible_id || '',
          start_date: this.dateRange ? this.dateRange[0] : '',
          end_date: this.dateRange ? this.dateRange[1] : ''
        }
        const r = await getPlanList(params)
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    async loadStats() {
      try { const r = await getPlanStatistics(); if (r.code === 0) this.stats = r.data || {} } catch (e) {}
    },
    async loadTypes() {
      try { const r = await getTypeOptions(); if (r.code === 0) this.typeOptions = r.data || [] } catch (e) {}
    },
    async loadTeachers() {
      try { const r = await getTeacherOptions(); if (r.code === 0) this.teacherOptions = r.data || [] } catch (e) {}
    },
    async loadCoursewares() {
      try { const r = await getCoursewareOptions(); if (r.code === 0) this.coursewareOptions = r.data || [] } catch (e) {}
    },
    async loadUsers() {
      try { const r = await getUserList({ limit: 500 }); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) {}
    },
    async loadDepts() {
      try {
        const r = await getDepartmentTree()
        const flat = []
        const walk = (nodes) => (nodes || []).forEach(n => { flat.push({ id: n.id, name: n.name }); walk(n.children) })
        walk(r.data || [])
        this.deptOptions = flat
      } catch (e) {}
    },
    async loadPositions() {
      try { const r = await getPositions(); if (r.code === 0) this.positionOptions = r.data || [] } catch (e) {}
    },
    onSearch() { this.page = 1; this.loadList() },
    resetFilters() {
      this.filters = { keyword: '', training_type_id: null, training_mode: '', status: '', responsible_id: null }
      this.dateRange = null
      this.page = 1
      this.loadList()
    },
    quickFilter(card) {
      if (card.key === 'total') { this.resetFilters() }
      else if (card.key === 'completion_rate') { this.$message.info('计划完成率 ' + this.stats.completion_rate + '%') }
      else { if (this.filters.status === card.key) this.filters.status = ''; else this.filters.status = card.key; this.page = 1; this.loadList() }
    },
    refreshAll() { this.loadList(); this.loadStats() },
    onTargetTypeChange() { this.form.target_ids_arr = []; this.calcTargetCount() },
    async calcTargetCount() {
      const ids = this.form.target_ids_arr || []
      try {
        const r = await getTargetUsers({ target_type: this.form.target_type, target_ids: ids.join(',') })
        if (r.code === 0) this.form.target_count = r.data.total || 0
      } catch (e) {}
    },
    openAdd() { this.form = this.emptyForm(); this.lockedType = false; this.dialogVisible = true },
    async openEdit(row) {
      this.lockedType = (row.completed_count || 0) > 0
      try {
        const r = await getPlanDetail(row.id)
        if (r.code === 0) {
          const d = r.data
          this.form = {
            id: d.id, plan_name: d.plan_name, training_type_id: d.training_type_id, training_mode: d.training_mode,
            duration_hours: d.duration_hours, location: d.location || '', content: d.content || '',
            target_type: d.target_type, target_ids_arr: d.target_ids_arr || [], target_count: d.target_count || 0,
            teacher_ids_arr: d.teacher_ids_arr || [], courseware_ids_arr: d.courseware_ids_arr || [],
            plan_start_date: d.plan_start_date, plan_end_date: d.plan_end_date, responsible_id: d.responsible_id, remark: d.remark || ''
          }
          this.dialogVisible = true
        }
      } catch (e) {}
    },
    handleSave() {
      this.$refs.formRef.validate(async (valid) => {
        if (!valid) return
        this.saving = true
        try {
          const d = {
            ...this.form,
            target_ids: this.form.target_ids_arr,
            teacher_ids: this.form.teacher_ids_arr,
            courseware_ids: this.form.courseware_ids_arr
          }
          const r = this.form.id ? await editPlan(this.form.id, d) : await addPlan(d)
          if (r.code === 0) { this.$message.success('保存成功'); this.dialogVisible = false; this.refreshAll() }
        } catch (e) {}
        this.saving = false
      })
    },
    handleCopy(row) {
      this.$confirm(`确认复制计划「${row.plan_name}」？`, '复制确认', { type: 'warning' }).then(async () => {
        try { const r = await copyPlan(row.id); if (r.code === 0) { this.$message.success('复制成功'); this.refreshAll() } } catch (e) {}
      }).catch(() => {})
    },
    handleDelete(row) {
      this.$confirm(`确认删除计划「${row.plan_name}」？`, '删除确认', { type: 'warning' }).then(async () => {
        try { const r = await deletePlan(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.refreshAll() } } catch (e) {}
      }).catch(() => {})
    },
    handleExecute(row) {
      this.$confirm(`确认执行计划「${row.plan_name}」？执行后计划状态变为执行中。`, '执行确认', { type: 'warning' }).then(async () => {
        try { const r = await executePlan(row.id); if (r.code === 0) { this.$message.success('已开始执行'); this.refreshAll() } } catch (e) {}
      }).catch(() => {})
    },
    handleGenerateRecord(row) {
      this.$confirm(`确认从计划「${row.plan_name}」生成培训记录？将自动复制计划信息并生成参训人员名单。`, '生成培训记录', { type: 'warning' }).then(async () => {
        try {
          const { generateRecord } = await import('@/api/safetyTrainingRecord')
          const r = await generateRecord(row.id)
          if (r.code === 0) { this.$message.success('培训记录生成成功'); this.$message.info('请在「培训记录」菜单查看和签到'); this.refreshAll() }
        } catch (e) {}
      }).catch(() => {})
    },
    handleComplete(row) {
      this.$confirm(`确认完成计划「${row.plan_name}」？`, '完成确认', { type: 'warning' }).then(async () => {
        try { const r = await completePlan(row.id); if (r.code === 0) { this.$message.success('已完成'); this.refreshAll() } } catch (e) {}
      }).catch(() => {})
    },
    openCancel(row) { this.currentRow = row; this.cancelForm = { cancel_reason: '' }; this.cancelVisible = true },
    handleCancelConfirm() {
      this.$refs.cancelRef.validate(async (valid) => {
        if (!valid) return
        this.cancelSaving = true
        try {
          const r = await cancelPlan(this.currentRow.id, this.cancelForm.cancel_reason)
          if (r.code === 0) { this.$message.success('已取消'); this.cancelVisible = false; this.refreshAll() }
        } catch (e) {}
        this.cancelSaving = false
      })
    }
  }
}
</script>

<style scoped>
.stat-row { display: flex; gap: 16px; margin-bottom: 16px; }
.stat-card-flex { flex: 1; background: #fff; border-radius: 8px; padding: 16px; box-shadow: 0 2px 8px rgba(0,0,0,.04); cursor: pointer; transition: all .2s; min-width: 0; }
.stat-card-flex:hover { transform: translateY(-3px); box-shadow: 0 6px 16px rgba(0,0,0,.1); }
.stat-card-flex .stat-icon { width: 40px; height: 40px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 20px; float: left; margin-right: 10px; }
.stat-card-flex .stat-info { overflow: hidden; }
.stat-card-flex .stat-val { font-size: 20px; font-weight: 700; line-height: 1.2; }
.stat-card-flex .stat-label { font-size: 12px; color: #909399; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
.form-section { font-weight: 600; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; margin: 8px 0; }
</style>
