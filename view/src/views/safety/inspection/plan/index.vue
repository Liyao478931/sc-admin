<template>
  <div class="plan-page">
    <!-- 统计卡片 -->
    <el-row :gutter="16" style="margin-bottom:16px;">
      <el-col :span="6" v-for="card in statCards" :key="card.key">
        <el-card shadow="hover" class="stat-card" @click.native="quickFilter(card)">
          <div class="stat-icon" :style="{background: card.color + '1a', color: card.color}"><i :class="card.icon"></i></div>
          <div class="stat-info"><div class="stat-val" :style="{color: card.color}">{{ card.value }}</div><div class="stat-label">{{ card.label }}</div></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 筛选区域 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <el-form :inline="true" size="small">
        <el-form-item><el-input v-model="filters.keyword" placeholder="计划名称/编号" clearable style="width:180px" @keyup.enter.native="loadList" /></el-form-item>
        <el-form-item>
          <el-select v-model="filters.inspection_type_id" clearable placeholder="全部检查类型" style="width:140px" @change="loadList">
            <el-option v-for="t in typeOptions" :key="t.id" :label="t.type_name" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width:110px" @change="loadList">
            <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-input v-model="filters.area" placeholder="检查区域" clearable style="width:120px" @keyup.enter.native="loadList" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="loadList">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilters">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 工具栏 + 表格 -->
    <el-card shadow="never">
      <div slot="header" class="card-header">
        <span style="color:#909399">共 <b style="color:#409EFF">{{ total }}</b> 条计划</span>
        <div>
          <el-button v-if="hasPerm('safety:inspection:plan:add')" size="small" type="primary" icon="el-icon-plus" @click="openAdd">新增计划</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </div>
      </div>

      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" />
        <el-table-column prop="plan_code" label="计划编号" width="170" show-overflow-tooltip />
        <el-table-column label="计划名称" min-width="140" show-overflow-tooltip>
          <template slot-scope="{row}"><el-link type="primary" @click="openDetail(row)">{{ row.plan_name }}</el-link></template>
        </el-table-column>
        <el-table-column prop="type_name" label="检查类型" width="100" align="center" />
        <el-table-column prop="area" label="检查区域" min-width="100" show-overflow-tooltip />
        <el-table-column prop="cycle_type_text" label="周期类型" width="90" align="center" />
        <el-table-column prop="cycle_value" label="周期值" width="80" align="center" />
        <el-table-column prop="next_execute_date" label="下次执行" width="110" />
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="{row}">
            <el-tag size="mini" :type="row.status === 'active' ? 'success' : row.status === 'expired' ? 'danger' : 'info'">{{ row.status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" align="center">
          <template slot-scope="{row}">
            <el-button v-if="hasPerm('safety:inspection:plan:edit')" size="mini" type="text" @click="openEdit(row)">编辑</el-button>
            <el-button v-if="hasPerm('safety:inspection:plan:add')" size="mini" type="text" @click="handleCopy(row)">复制</el-button>
            <el-button v-if="hasPerm('safety:inspection:plan:edit')" size="mini" type="text" :style="{color: row.status === 'active' ? '#E6A23C' : '#67C23A'}" @click="handleStatus(row)">{{ row.status === 'active' ? '停用' : '启用' }}</el-button>
            <el-button v-if="hasPerm('safety:inspection:plan:delete')" size="mini" type="text" style="color:#F56C6C" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination style="margin-top:12px;text-align:right" background layout="total, sizes, prev, pager, next"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10,20,50]" @current-change="loadList" @size-change="loadList" />
    </el-card>

    <!-- 新增编辑计划弹窗 -->
    <el-dialog :title="form.id ? '编辑计划' : '新增计划'" :visible.sync="dialogVisible" width="750px" top="4vh" append-to-body>
      <el-form :model="form" :rules="rules" ref="formRef" label-width="110px" size="small">
        <div class="form-section">基本信息</div>
        <el-form-item label="计划名称" prop="plan_name"><el-input v-model="form.plan_name" /></el-form-item>
        <el-form-item label="检查类型" prop="inspection_type_id">
          <el-select v-model="form.inspection_type_id" style="width:100%" @change="onTypeChange">
            <el-option v-for="t in typeOptions" :key="t.id" :label="t.type_name" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="检查区域"><el-input v-model="form.area" /></el-form-item>

        <div class="form-section">模板选择</div>
        <el-form-item label="检查标准模板">
          <el-select v-model="form.template_id" style="width:100%" @change="onTemplateChange">
            <el-option v-for="t in templateOptions" :key="t.id" :label="t.template_name" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="templatePreview.length" label="模板预览">
          <div style="background:#f8f9fb;border-radius:6px;padding:8px;max-height:120px;overflow-y:auto;width:100%">
            <div v-for="(it,i) in templatePreview" :key="i" style="font-size:12px;color:#606266;line-height:1.8">
              {{ i+1 }}. {{ it.item_name }} <span v-if="it.is_required" style="color:#F56C6C">（必查）</span>
            </div>
          </div>
        </el-form-item>

        <div class="form-section">周期设置</div>
        <el-form-item label="周期类型" prop="cycle_type">
          <el-select v-model="form.cycle_type" style="width:100%">
            <el-option v-for="c in cycleOptions" :key="c.value" :label="c.label" :value="c.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="周期值"><el-input-number v-model="form.cycle_value" :min="1" :max="999" /></el-form-item>
        <el-form-item label="首次执行日期"><el-date-picker v-model="form.start_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>

        <div class="form-section">负责人设置</div>
        <el-form-item label="负责人">
          <el-select v-model="form.leader_id" filterable clearable style="width:100%">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="执行人">
          <el-select v-model="form.executor_ids_arr" multiple filterable clearable style="width:100%">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>

        <div class="form-section">有效期</div>
        <el-form-item label="开始日期"><el-date-picker v-model="form.start_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
        <el-form-item label="结束日期"><el-date-picker v-model="form.end_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="dialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getPlanList, getPlanDetail, addPlan, editPlan, deletePlan, changePlanStatus, copyPlan, getPlanStatistics, getTypeOptions, getTemplateOptions } from '@/api/safetyInspectionPlan'
import { getUserList } from '@/api/user'

export default {
  name: 'SafetyInspectionPlan',
  data() {
    return {
      loading: false, list: [], total: 0, page: 1, limit: 10,
      filters: { keyword: '', inspection_type_id: null, status: '', area: '' },
      stats: { total: 0, active: 0, inactive: 0, expired: 0 },
      typeOptions: [], templateOptions: [], templatePreview: [], userOptions: [],
      dialogVisible: false, saving: false,
      form: { id: 0, plan_name: '', inspection_type_id: null, area: '', template_id: null, cycle_type: 'month', cycle_value: 1, start_date: '', end_date: '', leader_id: null, executor_ids_arr: [], remark: '' },
      rules: { plan_name: [{ required: true, message: '计划名称必填', trigger: 'blur' }], inspection_type_id: [{ required: true, message: '请选择检查类型', trigger: 'change' }], cycle_type: [{ required: true, message: '请选择周期类型', trigger: 'change' }] },
      cycleOptions: [
        { value: 'day', label: '每日' }, { value: 'week', label: '每周' }, { value: 'month', label: '每月' },
        { value: 'quarter', label: '每季' }, { value: 'year', label: '每年' },
      ],
      statusOptions: [
        { value: 'active', label: '启用' }, { value: 'inactive', label: '停用' }, { value: 'expired', label: '已过期' },
      ],
    }
  },
  computed: {
    statCards() {
      return [
        { key: 'total', label: '全部计划', value: this.stats.total, icon: 'el-icon-document', color: '#409EFF' },
        { key: 'active', label: '启用中', value: this.stats.active, icon: 'el-icon-circle-check', color: '#67C23A' },
        { key: 'inactive', label: '已停用', value: this.stats.inactive, icon: 'el-icon-remove-outline', color: '#909399' },
        { key: 'expired', label: '已过期', value: this.stats.expired, icon: 'el-icon-warning', color: '#F56C6C' },
      ]
    },
  },
  created() { this.loadList(); this.loadStats(); this.loadTypes(); this.loadUsers() },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    async loadList() {
      this.loading = true
      try {
        const p = { page: this.page, limit: this.limit, ...this.filters }
        const r = await getPlanList(p)
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
    async loadUsers() {
      try { const r = await getUserList({ limit: 500 }); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) {}
    },
    quickFilter(card) {
      if (card.key === 'total') this.filters.status = ''
      else this.filters.status = card.key
      this.page = 1
      this.loadList()
    },
    resetFilters() { this.filters = { keyword: '', inspection_type_id: null, status: '', area: '' }; this.page = 1; this.loadList() },
    onTypeChange() { this.form.template_id = null; this.templatePreview = []; this.loadTemplates() },
    async loadTemplates() {
      try {
        const r = await getTemplateOptions(this.form.inspection_type_id)
        if (r.code === 0) this.templateOptions = r.data || []
      } catch (e) {}
    },
    async onTemplateChange(id) {
      if (!id) { this.templatePreview = []; return }
      // 通过模板列表找到项目预览
      try {
        const { getTemplateDetail } = await import('@/api/safetyInspectionPlan')
        const r = await getTemplateDetail(id)
        if (r.code === 0) this.templatePreview = r.data.items || []
      } catch (e) {}
    },
    openAdd() {
      this.form = { id: 0, plan_name: '', inspection_type_id: null, area: '', template_id: null, cycle_type: 'month', cycle_value: 1, start_date: '', end_date: '', leader_id: null, executor_ids_arr: [], remark: '' }
      this.templatePreview = []
      this.dialogVisible = true
    },
    openEdit(row) { this.form = { ...row, executor_ids_arr: row.executor_ids ? row.executor_ids.split(',').map(Number) : [] }; this.loadTemplates(); this.onTemplateChange(row.template_id); this.dialogVisible = true },
    openDetail(row) { this.openEdit(row) },
    handleSave() {
      this.$refs.formRef.validate(async (valid) => {
        if (!valid) return
        this.saving = true
        try {
          const d = { ...this.form, executor_ids: this.form.executor_ids_arr }
          const r = this.form.id ? await editPlan(this.form.id, d) : await addPlan(d)
          if (r.code === 0) { this.$message.success('保存成功'); this.dialogVisible = false; this.loadList() }
        } catch (e) {}
        this.saving = false
      })
    },
    handleCopy(row) {
      this.$confirm(`确认复制计划「${row.plan_name}」？`, '复制确认', { type: 'warning' }).then(async () => {
        const r = await copyPlan(row.id)
        if (r.code === 0) { this.$message.success('复制成功'); this.loadList() }
      }).catch(() => {})
    },
    handleStatus(row) {
      const target = row.status === 'active' ? 'inactive' : 'active'
      this.$confirm(`确认${target === 'active' ? '启用' : '停用'}计划「${row.plan_name}」？`, '状态确认', { type: 'warning' }).then(async () => {
        const r = await changePlanStatus(row.id, target)
        if (r.code === 0) { this.$message.success('操作成功'); this.loadList(); this.loadStats() }
      }).catch(() => {})
    },
    handleDelete(row) {
      this.$confirm(`确认删除计划「${row.plan_name}」？`, '删除确认', { type: 'warning' }).then(async () => {
        const r = await deletePlan(row.id)
        if (r.code === 0) { this.$message.success('删除成功'); this.loadList(); this.loadStats() }
      }).catch(() => {})
    },
  },
}
</script>

<style scoped>
.stat-card { cursor: pointer; transition: all .2s; }
.stat-card:hover { transform: translateY(-3px); box-shadow: 0 6px 16px rgba(0,0,0,.1); }
.stat-card .stat-icon { width: 40px; height: 40px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 20px; float: left; margin-right: 10px; }
.stat-card .stat-info { overflow: hidden; }
.stat-card .stat-val { font-size: 20px; font-weight: 700; line-height: 1.2; }
.stat-card .stat-label { font-size: 12px; color: #909399; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
.form-section { font-weight: 600; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; margin: 8px 0; }
</style>
