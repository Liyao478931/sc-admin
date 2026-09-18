<template>
  <div class="inspection-page">
    <!-- 面包屑 -->
    <el-breadcrumb separator="/" class="crumb">
      <el-breadcrumb-item>设备管理</el-breadcrumb-item>
      <el-breadcrumb-item>设备巡检</el-breadcrumb-item>
    </el-breadcrumb>

    <el-tabs v-model="activeTab">
      <!-- ============ 一、巡检计划 ============ -->
      <el-tab-pane label="巡检计划" name="plan">
        <div class="toolbar">
          <el-input v-model="planFilter.keyword" placeholder="搜索计划名称/编号" clearable size="small" style="width:200px" @keyup.enter.native="loadPlans" />
          <el-select v-model="planFilter.plan_type" placeholder="计划类型" clearable size="small" style="width:120px">
            <el-option v-for="t in planTypeOptions" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
          <el-select v-model="planFilter.status" placeholder="状态" clearable size="small" style="width:110px">
            <el-option v-for="s in planStatusOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
          <el-button size="small" type="primary" icon="el-icon-search" @click="loadPlans">搜索</el-button>
          <el-button v-if="hasPerm('device:inspection:plan:add')" size="small" type="success" icon="el-icon-plus" @click="openPlan('add')">新增计划</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadPlans">刷新</el-button>
        </div>
        <div class="card-grid" v-if="plans.length">
          <div v-for="p in plans" :key="p.id" class="card">
            <div class="card-top">
              <span class="card-title">{{ p.plan_name }}</span>
              <el-tag :type="planStatusType(p.status)" size="mini">{{ planStatusLabel(p.status) }}</el-tag>
            </div>
            <div class="card-line">编号：{{ p.plan_code }}</div>
            <div class="card-line">类型：{{ planTypeLabel(p.plan_type) }} · 频率：{{ p.frequency_type || '-' }}</div>
            <div class="card-line">下次执行：{{ p.next_execute_date || '-' }}</div>
            <div class="card-actions">
              <el-button v-if="hasPerm('device:inspection:plan:edit')" size="mini" type="text" @click="openPlan('edit', p)">编辑</el-button>
              <el-button v-if="hasPerm('device:inspection:plan:add')" size="mini" type="text" @click="copyPlan(p)">复制</el-button>
              <el-button v-if="hasPerm('device:inspection:plan:edit')" size="mini" type="text" @click="togglePlan(p)">{{ p.status === 'active' ? '停用' : '启用' }}</el-button>
              <el-button v-if="hasPerm('device:inspection:plan:delete')" size="mini" type="text" style="color:#F56C6C" @click="delPlan(p)">删除</el-button>
            </div>
          </div>
        </div>
        <el-empty v-else description="暂无巡检计划" />
      </el-tab-pane>

      <!-- ============ 二、内容模板 ============ -->
      <el-tab-pane label="内容模板" name="template">
        <div class="toolbar">
          <el-input v-model="tplFilter.keyword" placeholder="搜索模板名称" clearable size="small" style="width:200px" @keyup.enter.native="loadTemplates" />
          <el-button size="small" type="primary" icon="el-icon-search" @click="loadTemplates">搜索</el-button>
          <el-button v-if="hasPerm('device:inspection:template:add')" size="small" type="success" icon="el-icon-plus" @click="openTpl('add')">新增模板</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadTemplates">刷新</el-button>
        </div>
        <div class="card-grid" v-if="templates.length">
          <div v-for="t in templates" :key="t.id" class="card">
            <div class="card-top">
              <span class="card-title">{{ t.template_name }}</span>
              <el-tag :type="t.status === 'active' ? 'success' : 'info'" size="mini">{{ t.status === 'active' ? '启用' : '停用' }}</el-tag>
            </div>
            <div class="card-line">编号：{{ t.template_code }} · 检查项 {{ t.items_count }} 项 · v{{ t.version }}</div>
            <div class="card-line">{{ t.description || '-' }}</div>
            <div class="card-actions">
              <el-button v-if="hasPerm('device:inspection:template:edit')" size="mini" type="text" @click="openTpl('edit', t)">编辑</el-button>
              <el-button v-if="hasPerm('device:inspection:template:add')" size="mini" type="text" @click="copyTpl(t)">复制</el-button>
              <el-button v-if="hasPerm('device:inspection:template:delete')" size="mini" type="text" style="color:#F56C6C" @click="delTpl(t)">删除</el-button>
            </div>
          </div>
        </div>
        <el-empty v-else description="暂无内容模板" />
      </el-tab-pane>

      <!-- ============ 三、巡检任务 ============ -->
      <el-tab-pane label="巡检任务" name="task">
        <el-row :gutter="12" class="stat-row">
          <el-col :span="6"><div class="stat-card" @click="quickTaskStatus('pending')"><div class="stat-num">{{ taskStats.pending || 0 }}</div><div class="stat-label">待执行</div></div></el-col>
          <el-col :span="6"><div class="stat-card" @click="quickTaskStatus('in_progress')"><div class="stat-num">{{ taskStats.in_progress || 0 }}</div><div class="stat-label">执行中</div></div></el-col>
          <el-col :span="6"><div class="stat-card" @click="quickTaskStatus('completed')"><div class="stat-num">{{ taskStats.completed || 0 }}</div><div class="stat-label">已完成</div></div></el-col>
          <el-col :span="6"><div class="stat-card" @click="quickTaskStatus('overdue')"><div class="stat-num" style="color:#F56C6C">{{ taskStats.overdue || 0 }}</div><div class="stat-label">逾期</div></div></el-col>
        </el-row>
        <div class="toolbar">
          <el-input v-model="taskFilter.keyword" placeholder="搜索设备/任务编号" clearable size="small" style="width:180px" @keyup.enter.native="loadTasks" />
          <el-select v-model="taskFilter.plan_id" placeholder="计划" clearable filterable size="small" style="width:140px">
            <el-option v-for="p in planOptions" :key="p.id" :label="p.plan_name" :value="p.id" />
          </el-select>
          <el-select v-model="taskFilter.status" placeholder="状态" clearable size="small" style="width:110px">
            <el-option v-for="s in taskStatusOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
          <el-button size="small" type="primary" icon="el-icon-search" @click="loadTasks">搜索</el-button>
          <el-button v-if="hasPerm('device:inspection:task:add')" size="small" type="success" icon="el-icon-plus" @click="openGenerate">手动生成任务</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadTasks; loadTaskStats">刷新</el-button>
        </div>
        <div class="card-grid" v-if="tasks.length">
          <div v-for="t in tasks" :key="t.id" class="card">
            <div class="card-top">
              <span class="card-title">{{ t.device_name }}</span>
              <el-tag :type="taskStatusType(t.status)" size="mini">{{ taskStatusLabel(t.status) }}</el-tag>
            </div>
            <div class="card-line">任务：{{ t.task_code }}</div>
            <div class="card-line">计划：{{ t.plan_name || '-' }} · 执行人：{{ t.executor_name || '未分配' }}</div>
            <div class="card-line">计划日期：{{ t.plan_execute_date }}</div>
            <div class="card-actions">
              <el-button v-if="hasPerm('device:inspection:task:assign')" size="mini" type="text" @click="assignTask(t)">分配</el-button>
              <el-button v-if="hasPerm('device:inspection:execute:start')" :disabled="!['pending','in_progress'].includes(t.status)" size="mini" type="text" style="color:#409EFF" @click="goExecute(t)">开始执行</el-button>
              <el-button v-if="hasPerm('device:inspection:task:edit')" :disabled="t.status !== 'pending'" size="mini" type="text" style="color:#E6A23C" @click="cancelTask(t)">取消</el-button>
            </div>
          </div>
        </div>
        <el-empty v-else description="暂无巡检任务" />
      </el-tab-pane>

      <!-- ============ 四、巡检记录 ============ -->
      <el-tab-pane label="巡检记录" name="record">
        <div class="toolbar">
          <el-input v-model="recFilter.keyword" placeholder="搜索设备/记录编号" clearable size="small" style="width:180px" @keyup.enter.native="loadRecords" />
          <el-select v-model="recFilter.audit_status" placeholder="审核状态" clearable size="small" style="width:120px">
            <el-option v-for="s in auditStatusOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
          <el-button size="small" type="primary" icon="el-icon-search" @click="loadRecords">搜索</el-button>
          <el-button v-if="hasPerm('device:inspection:record:export')" size="small" icon="el-icon-download" @click="exportRecords">导出</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadRecords">刷新</el-button>
        </div>
        <div class="card-grid" v-if="records.length">
          <div v-for="r in records" :key="r.id" class="card">
            <div class="card-top">
              <span class="card-title">{{ r.device_name }}</span>
              <el-tag :type="r.result === 'abnormal' ? 'danger' : 'success'" size="mini">{{ r.result === 'abnormal' ? '异常' : '正常' }}</el-tag>
            </div>
            <div class="card-line">记录：{{ r.record_code }} · 执行人：{{ r.executor_name }}</div>
            <div class="card-line">时间：{{ r.execute_time }} · 检查 {{ r.total_count }} 项 / 异常 {{ r.abnormal_count }} 项</div>
            <div class="card-line">审核：{{ auditLabel(r.audit_status) }}</div>
            <div class="card-actions">
              <el-button v-if="hasPerm('device:inspection:record:list')" size="mini" type="text" @click="openRecord(r.id)">详情</el-button>
              <el-button v-if="(r.audit_status === 'pending') && hasPerm('device:inspection:record:audit')"  size="mini" type="text" @click="auditRecord(r)">审核</el-button>
              <el-button v-if="hasPerm('device:inspection:record:delete')" size="mini" type="text" style="color:#F56C6C" @click="delRecord(r)">删除</el-button>
            </div>
          </div>
        </div>
        <el-empty v-else description="暂无巡检记录" />
      </el-tab-pane>

      <!-- ============ 六、统计看板 ============ -->
      <el-tab-pane label="统计看板" name="statistics">
        <el-row :gutter="12" class="stat-row">
          <el-col :span="6"><div class="stat-card"><div class="stat-num">{{ overview.plan_total || 0 }}</div><div class="stat-label">计划总数</div></div></el-col>
          <el-col :span="6"><div class="stat-card"><div class="stat-num">{{ overview.today_pending || 0 }}</div><div class="stat-label">今日待执行</div></div></el-col>
          <el-col :span="6"><div class="stat-card"><div class="stat-num" style="color:#67C23A">{{ overview.month_completed || 0 }}</div><div class="stat-label">本月完成</div></div></el-col>
          <el-col :span="6"><div class="stat-card"><div class="stat-num" style="color:#F56C6C">{{ overview.overdue || 0 }}</div><div class="stat-label">逾期未执行</div></div></el-col>
        </el-row>
        <div class="panel">
          <div class="section-title">近 6 个月完成率趋势</div>
          <div v-for="t in trend" :key="t.month" class="trend-row">
            <span class="trend-month">{{ t.month }}</span>
            <el-progress :percentage="t.rate" :stroke-width="12" />
            <span class="trend-text">{{ t.completed }}/{{ t.total }}</span>
          </div>
        </div>
        <el-row :gutter="12">
          <el-col :span="12">
            <div class="panel">
              <div class="section-title">异常项 TOP10</div>
              <div v-for="(a, i) in abnormalTop" :key="i" class="top-row"><span class="top-name">{{ i + 1 }}. {{ a.name }}</span><b>{{ a.count }} 次</b></div>
              <el-empty v-if="!abnormalTop.length" :image-size="50" />
            </div>
          </el-col>
          <el-col :span="12">
            <div class="panel">
              <div class="section-title">执行人排行</div>
              <div v-for="(e, i) in executorTop" :key="i" class="top-row"><span class="top-name">{{ i + 1 }}. {{ e.executor_name }}</span><b>{{ e.cnt }} 次</b></div>
              <el-empty v-if="!executorTop.length" :image-size="50" />
            </div>
          </el-col>
        </el-row>
      </el-tab-pane>
    </el-tabs>

    <!-- 弹窗 -->
    <plan-dialog :visible.sync="planVisible" :mode="planMode" :plan-id="editPlanId" @saved="loadPlans" />
    <template-dialog :visible.sync="tplVisible" :mode="tplMode" :template-id="editTplId" @saved="loadTemplates" />
    <record-detail-dialog :visible.sync="recordVisible" :record-id="recordId" />

    <!-- 手动生成任务 -->
    <el-dialog title="手动生成任务" :visible.sync="generateVisible" width="480px">
      <el-form label-width="100px" size="small">
        <el-form-item label="选择计划">
          <el-select v-model="generatePlanId" filterable style="width:100%">
            <el-option v-for="p in planOptions" :key="p.id" :label="p.plan_name" :value="p.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="执行日期">
          <el-date-picker v-model="generateDate" type="date" value-format="yyyy-MM-dd" style="width:100%" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="generateVisible = false">取消</el-button>
        <el-button size="small" type="primary" @click="doGenerate">生成</el-button>
      </div>
    </el-dialog>

    <!-- 审核 -->
    <el-dialog title="审核巡检记录" :visible.sync="auditVisible" width="480px">
      <el-form label-width="100px" size="small">
        <el-form-item label="审核结果">
          <el-radio-group v-model="auditStatus">
            <el-radio label="approved">通过</el-radio>
            <el-radio label="rejected">驳回</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="审核意见"><el-input v-model="auditRemark" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="auditVisible = false">取消</el-button>
        <el-button size="small" type="primary" @click="doAudit">确认</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getPlanList, togglePlanStatus, deletePlan, copyPlan, getPlanOptions, getTaskList, getTaskStatistics, generateTask, assignTask, cancelTask, getRecordList, auditRecord, exportRecords, deleteRecord, getOverview, getTrend, getAbnormalTop, getExecutorTop } from '@/api/deviceInspection'
import { getTemplateList, deleteTemplate, copyTemplate } from '@/api/deviceInspection'
import { getDictionaryBatch } from '@/utils/dict'
import { getManagers } from '@/api/deviceAsset'
import PlanDialog from './components/PlanDialog.vue'
import TemplateDialog from './components/TemplateDialog.vue'
import RecordDetailDialog from './components/RecordDetailDialog.vue'

export default {
  name: 'DeviceInspection',
  components: { PlanDialog, TemplateDialog, RecordDetailDialog },
  data() {
    return {
      activeTab: 'plan',
      hasPermCache: {},
      planTypeOptions: [], taskStatusOptions: [],
      planStatusOptions: [], auditStatusOptions: [],
      managerList: [],
      plans: [], templates: [], tasks: [], records: [],
      planOptions: [], taskStats: {}, overview: {}, trend: [], abnormalTop: [], executorTop: [],
      planFilter: { keyword: '', plan_type: '', status: '' },
      tplFilter: { keyword: '' },
      taskFilter: { keyword: '', plan_id: '', status: '' },
      recFilter: { keyword: '', audit_status: '' },
      planVisible: false, planMode: 'add', editPlanId: 0,
      tplVisible: false, tplMode: 'add', editTplId: 0,
      recordVisible: false, recordId: 0,
      generateVisible: false, generatePlanId: null, generateDate: this.todayStr(),
      auditVisible: false, auditRecordId: 0, auditStatus: 'approved', auditRemark: ''
    }
  },
  created() {
    this.loadDicts()
    this.loadManagers()
    this.loadPlans()
    this.loadTemplates()
    this.loadPlanOptions()
    if (!this.$store.state.user || !this.$store.state.user.permissions || !this.$store.state.user.permissions.length) {
      this.$store.dispatch('user/loadPermissions').catch(() => {})
    }
  },
  methods: {
    hasPerm(code) {
      const perms = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return perms.indexOf(code) > -1
    },
    todayStr() { const d = new Date(); return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}` },
    async loadDicts() {
      try {
        const res = await getDictionaryBatch(['inspection_plan_type', 'task_status', 'plan_status', 'audit_status'])
        this.planTypeOptions = res['inspection_plan_type'] || []
        this.taskStatusOptions = res['task_status'] || []
        this.planStatusOptions = res['plan_status'] || []
        this.auditStatusOptions = res['audit_status'] || []
      } catch (e) {}
    },
    async loadManagers() {
      try { const r = await getManagers(); this.managerList = r.data || [] } catch (e) {}
    },
    // 计划
    async loadPlans() {
      try { const r = await getPlanList(this.planFilter); this.plans = r.data.list || [] } catch (e) {}
    },
    async loadPlanOptions() {
      try { const r = await getPlanOptions(); this.planOptions = r.data || [] } catch (e) {}
    },
    openPlan(mode, p) { this.planMode = mode; this.editPlanId = p ? p.id : 0; this.planVisible = true },
    togglePlan(p) { togglePlanStatus(p.id, p.status === 'active' ? 'inactive' : 'active').then(() => { this.$message.success('已更新'); this.loadPlans() }) },
    copyPlan(p) { copyPlan(p.id).then(() => { this.$message.success('已复制'); this.loadPlans() }) },
    delPlan(p) {
      this.$confirm(`确定删除计划 [${p.plan_name}] 吗？`, '提示', { type: 'warning' })
        .then(() => deletePlan(p.id).then(() => { this.$message.success('已删除'); this.loadPlans() })).catch(() => {})
    },
    planTypeLabel(v) { const t = this.planTypeOptions.find(x => x.value === v); return t ? t.label : v },
    planStatusLabel(v) { return { active: '启用', inactive: '停用', expired: '过期' }[v] || v },
    planStatusType(v) { return { active: 'success', inactive: 'info', expired: 'danger' }[v] || 'info' },
    // 模板
    async loadTemplates() {
      try { const r = await getTemplateList(this.tplFilter); this.templates = r.data.list || [] } catch (e) {}
    },
    openTpl(mode, t) { this.tplMode = mode; this.editTplId = t ? t.id : 0; this.tplVisible = true },
    copyTpl(t) { copyTemplate(t.id).then(() => { this.$message.success('已复制'); this.loadTemplates() }) },
    delTpl(t) {
      this.$confirm(`确定删除模板 [${t.template_name}] 吗？`, '提示', { type: 'warning' })
        .then(() => deleteTemplate(t.id).then(() => { this.$message.success('已删除'); this.loadTemplates() })).catch(() => {})
    },
    // 任务
    async loadTasks() {
      try { const r = await getTaskList(this.taskFilter); this.tasks = r.data.list || [] } catch (e) {}
    },
    async loadTaskStats() {
      try { const r = await getTaskStatistics(); this.taskStats = r.data || {} } catch (e) {}
    },
    quickTaskStatus(s) { this.taskFilter.status = this.taskFilter.status === s ? '' : s; this.loadTasks() },
    openGenerate() { this.generateVisible = true },
    doGenerate() {
      if (!this.generatePlanId || !this.generateDate) { this.$message.warning('请选择计划和日期'); return }
      generateTask(this.generatePlanId, this.generateDate).then(() => { this.$message.success('任务已生成'); this.generateVisible = false; this.loadTasks(); this.loadTaskStats() })
    },
    assignTask(t) {
      this.$prompt('选择执行人ID（可在用户管理查看）', '分配执行人', { inputValue: t.executor_id || '', inputPattern: /^\d+$/, inputErrorMessage: '请输入用户ID' })
        .then(({ value }) => assignTask(t.id, Number(value)).then(() => { this.$message.success('已分配'); this.loadTasks() })).catch(() => {})
    },
    cancelTask(t) { cancelTask(t.id).then(() => { this.$message.success('已取消'); this.loadTasks(); this.loadTaskStats() }) },
    goExecute(t) { this.$router.push({ path: '/device/inspection/execute', query: { task_id: t.id } }) },
    taskStatusLabel(v) { const s = this.taskStatusOptions.find(x => x.value === v); return s ? s.label : v },
    taskStatusType(v) { return { pending: 'info', in_progress: 'primary', completed: 'success', overdue: 'danger', cancelled: 'warning' }[v] || 'info' },
    // 记录
    async loadRecords() {
      try { const r = await getRecordList(this.recFilter); this.records = r.data.list || [] } catch (e) {}
    },
    openRecord(id) { this.recordId = id; this.recordVisible = true },
    auditLabel(v) { return { pending: '待审核', approved: '通过', rejected: '驳回' }[v] || v },
    auditRecord(r) { this.auditVisible = true; this.auditRecordId = r.id; this.auditStatus = 'approved'; this.auditRemark = '' },
    doAudit() {
      auditRecord(this.auditRecordId, { audit_status: this.auditStatus, audit_remark: this.auditRemark })
        .then(() => { this.$message.success('审核完成'); this.auditVisible = false; this.loadRecords() })
    },
    exportRecords() {
      exportRecords(this.recFilter).then(res => { if (res.code === 0 && res.data && res.data.url) window.open(res.data.url, '_blank') })
    },
    delRecord(r) {
      this.$confirm('确定删除该巡检记录吗？', '提示', { type: 'warning' })
        .then(() => deleteRecord(r.id).then(() => { this.$message.success('已删除'); this.loadRecords() })).catch(() => {})
    },
    // 统计
    async loadOverview() { try { const r = await getOverview(); this.overview = r.data || {} } catch (e) {} },
    async loadTrend() { try { const r = await getTrend(); this.trend = r.data || [] } catch (e) {} },
    async loadAbnormalTop() { try { const r = await getAbnormalTop(); this.abnormalTop = r.data || [] } catch (e) {} },
    async loadExecutorTop() { try { const r = await getExecutorTop(); this.executorTop = r.data || [] } catch (e) {} }
  },
  watch: {
    activeTab(v) {
      if (v === 'task') { this.loadTasks(); this.loadTaskStats() }
      if (v === 'record') this.loadRecords()
      if (v === 'statistics') { this.loadOverview(); this.loadTrend(); this.loadAbnormalTop(); this.loadExecutorTop() }
    }
  }
}
</script>

<style scoped>
.inspection-page { padding: 16px; }
.crumb { margin-bottom: 14px; }
.toolbar { display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 12px; align-items: center; }
.card-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 12px; }
.card { background: #fff; border: 1px solid #ebeef5; border-radius: 8px; padding: 12px; }
.card-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.card-title { font-size: 14px; font-weight: 600; }
.card-line { color: #606266; font-size: 12px; margin: 3px 0; }
.card-actions { display: flex; gap: 2px; margin-top: 8px; flex-wrap: wrap; }
.stat-row { margin-bottom: 12px; }
.stat-card { background: #fff; border-radius: 8px; padding: 12px; text-align: center; box-shadow: 0 2px 8px rgba(0,0,0,.04); cursor: pointer; }
.stat-num { font-size: 20px; font-weight: 700; }
.stat-label { color: #909399; font-size: 12px; }
.panel { background: #fff; border-radius: 8px; padding: 12px; margin-bottom: 12px; }
.section-title { font-size: 14px; font-weight: 600; margin-bottom: 10px; }
.trend-row { display: flex; align-items: center; gap: 10px; margin-bottom: 8px; }
.trend-month { width: 70px; color: #606266; font-size: 12px; }
.trend-text { color: #909399; font-size: 12px; }
.top-row { display: flex; justify-content: space-between; font-size: 13px; padding: 5px 0; }
.top-name { color: #606266; }
@media (max-width: 768px) {
  .card-grid { grid-template-columns: 1fr; }
}
</style>
