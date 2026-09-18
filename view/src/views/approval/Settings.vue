<!--
  文件：admin/src/views/approval/Settings.vue
  功能：审批流程配置（统一审批管理）— 搜索 / 列表 / 新增编辑（节点可编辑表格）/ 启用停用 / 流程图预览
  权限：approval:settings:manage
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>统一审批</el-breadcrumb-item>
      <el-breadcrumb-item>审批流程配置</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索筛选 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="业务类型"><el-input v-model="query.keyword" placeholder="请输入业务类型或名称" clearable style="width:200px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="审批模式">
          <el-select v-model="query.approval_mode" clearable placeholder="全部模式" style="width:130px">
            <el-option v-for="(t, v) in modeOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部状态" style="width:110px">
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
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
        <el-button v-permission="'approval:settings:manage'" type="primary" size="small" icon="el-icon-plus" @click="openAdd">新增配置</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条配置</span>
    </div>

    <!-- 数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无流程配置">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column prop="business_type" label="业务类型" width="150" />
      <el-table-column prop="business_name" label="业务名称" width="140" />
      <el-table-column prop="module_name" label="所属模块" width="120" />
      <el-table-column label="审批模式" width="110" align="center">
        <template slot-scope="s"><el-tag :type="modeTag(s.row.approval_mode)" size="mini">{{ s.row.approval_mode_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="node_count" label="节点数" width="90" align="center" />
      <el-table-column label="状态" width="90" align="center">
        <template slot-scope="s"><el-tag :type="s.row.is_active === 1 ? 'success' : 'info'" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="updated_at" label="更新时间" width="160" align="center" />
      <el-table-column label="操作" width="200" align="center" fixed="right">
        <template slot-scope="s">
          <el-button v-permission="'approval:settings:manage'" type="text" size="mini" @click="openEdit(s.row)">编辑</el-button>
          <el-button v-permission="'approval:settings:manage'" type="text" size="mini" @click="handleToggle(s.row)">{{ s.row.is_active === 1 ? '停用' : '启用' }}</el-button>
          <el-button type="text" size="mini" @click="openFlow(s.row)">查看流程图</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 新增/编辑对话框 -->
    <el-dialog :title="form.id ? '编辑审批流程配置' : '新增审批流程配置'" :visible.sync="dialogVisible" width="750px" :close-on-click-modal="false" append-to-body>
      <el-form ref="form" :model="form" :rules="formRules" label-width="130px" size="small">
        <el-form-item label="业务类型" prop="business_type">
          <el-select v-model="form.business_type" :disabled="!!form.id" placeholder="请选择业务类型" style="width:100%" @change="onBizTypeChange">
            <el-option v-for="b in bizTypeOptions" :key="b.business_type" :value="b.business_type" :label="b.business_name + '（' + b.business_type + '）'" :disabled="b.configured && !form.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="业务名称">
          <el-input v-model="form.business_name" disabled placeholder="选择业务类型自动带出" />
        </el-form-item>
        <el-form-item label="所属模块">
          <el-input v-model="form.module_name" disabled placeholder="选择业务类型自动带出" />
        </el-form-item>
        <el-form-item label="审批模式" prop="approval_mode">
          <el-select v-model="form.approval_mode" style="width:100%">
            <el-option v-for="(t, v) in modeOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="审批节点列表" required>
          <el-table :data="form.nodes" size="mini" border>
            <el-table-column label="序号" type="index" width="55" align="center" />
            <el-table-column label="节点名称" width="170">
              <template slot-scope="s">
                <el-input v-model="s.row.node_name" size="mini" placeholder="请输入节点名称" />
              </template>
            </el-table-column>
            <el-table-column label="审批人角色" width="150">
              <template slot-scope="s">
                <el-select v-model="s.row.approver_type" size="mini" style="width:100%" @change="v => onApproverTypeChange(s.row, v)">
                  <el-option v-for="o in approverOptions" :key="o.value" :label="o.label" :value="o.value" />
                </el-select>
              </template>
            </el-table-column>
            <el-table-column label="指定人员/角色" width="180">
              <template slot-scope="s">
                <el-select v-if="s.row.approver_type === 'specified_user'" v-model="s.row.approver_value" size="mini" filterable clearable placeholder="选择用户" style="width:100%" @change="v => onSpecifiedChange(s.row, v, 'user')">
                  <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="String(u.id)" />
                </el-select>
                <el-select v-else-if="s.row.approver_type === 'specified_role'" v-model="s.row.approver_value" size="mini" filterable clearable placeholder="选择角色" style="width:100%" @change="v => onSpecifiedChange(s.row, v, 'role')">
                  <el-option v-for="r in roleOptions" :key="r.value" :label="r.label" :value="String(r.value)" />
                </el-select>
                <span v-else style="color:#C0C4CC;font-size:12px">无需指定</span>
              </template>
            </el-table-column>
            <el-table-column label="超时时间(小时)" width="130">
              <template slot-scope="s">
                <el-input-number v-model="s.row.timeout_hours" :min="1" :max="999" size="mini" style="width:100%" />
              </template>
            </el-table-column>
            <el-table-column label="超时自动处理" width="150">
              <template slot-scope="s">
                <el-select v-model="s.row.timeout_action" size="mini" style="width:100%">
                  <el-option label="自动通过" value="auto_approve" />
                  <el-option label="自动驳回" value="auto_reject" />
                  <el-option label="仅提醒不自动处理" value="remind" />
                </el-select>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="70" align="center">
              <template slot-scope="s">
                <el-button type="text" size="mini" class="danger-text" @click="removeNode(s.$index)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
          <el-button size="mini" icon="el-icon-plus" style="margin-top:8px" :disabled="form.nodes.length >= 10" @click="addNode">添加节点</el-button>
          <div class="node-tip">最少 1 个节点，最多 10 个；节点按添加顺序执行</div>
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.is_active" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.remark" type="textarea" :rows="2" maxlength="200" placeholder="选填" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="dialogVisible = false">取 消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保 存</el-button>
      </div>
    </el-dialog>

    <!-- 流程图预览对话框 -->
    <el-dialog title="审批流程图" :visible.sync="flowVisible" width="700px" append-to-body>
      <div class="flow-wrap">
        <div class="flow-nodes">
          <template v-for="(n, i) in flowNodes">
            <div :key="'n' + i" class="flow-node">
              <div class="flow-node-name">{{ n.node_name }}</div>
              <div class="flow-node-role">{{ n.approver_name || '未指定' }}</div>
            </div>
            <i v-if="i < flowNodes.length - 1" :key="'a' + i" class="el-icon-right flow-arrow"></i>
          </template>
          <div v-if="!flowNodes.length" class="empty-tip">该流程未配置节点</div>
        </div>
        <div class="flow-mode">当前模式：{{ flowModeLabel }}（共 {{ flowNodes.length }} 个节点）</div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getApprovalDefinitions, saveApprovalDefinition, toggleApprovalDefinition, getBusinessTypes, getApprovalUserOptions, getRoleOptions } from '@/api/approval'

const MODE_TAG = { 1: 'info', 2: 'warning', 3: 'primary', 4: 'warning' }

export default {
  name: 'ApprovalSettings',
  data () {
    return {
      modeOptions: { 1: '单人审批', 2: '会签', 3: '或签', 4: '依次审批' },
      approverOptions: [
        { value: 'department_head', label: '部门负责人' },
        { value: 'manager', label: '经理' },
        { value: 'general_manager', label: '总经理' },
        { value: 'specified_user', label: '指定用户' },
        { value: 'specified_role', label: '指定角色' }
      ],
      query: { keyword: '', approval_mode: '', status: '' },
      list: [], total: 0, page: 1, pageSize: 10, loading: false,
      bizTypeOptions: [],
      userOptions: [], roleOptions: [],
      dialogVisible: false, saving: false,
      form: this.emptyForm(),
      formRules: {
        business_type: [{ required: true, message: '请选择业务类型', trigger: 'change' }],
        approval_mode: [{ required: true, message: '请选择审批模式', trigger: 'change' }]
      },
      flowVisible: false, flowNodes: [], flowModeLabel: ''
    }
  },
  created () { this.loadData(); this.loadBizTypes(); this.loadUserOptions(); this.loadRoleOptions() },
  methods: {
    emptyForm () {
      return {
        id: 0, business_type: '', business_name: '', module_name: '',
        approval_mode: 1, is_active: 1, remark: '',
        nodes: [{ node_name: '', approver_type: 'department_head', approver_value: '', approver_name: '部门负责人', timeout_hours: 48, timeout_action: 'remind' }]
      }
    },
    modeTag (m) { return MODE_TAG[m] || 'info' },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.keyword) p.keyword = this.query.keyword
      if (this.query.approval_mode !== '' && this.query.approval_mode !== null) p.approval_mode = this.query.approval_mode
      if (this.query.status !== '' && this.query.status !== null) p.status = this.query.status
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getApprovalDefinitions(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    async loadBizTypes () {
      try {
        const r = await getBusinessTypes()
        if (r.code === 0) this.bizTypeOptions = (r.data && r.data.list) || []
      } catch (e) {}
    },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () { this.query = { keyword: '', approval_mode: '', status: '' }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    onBizTypeChange (val) {
      const b = this.bizTypeOptions.find(x => x.business_type === val)
      if (b) { this.form.business_name = b.business_name; this.form.module_name = b.module_name }
    },
    onApproverTypeChange (row, val) {
      const o = this.approverOptions.find(x => x.value === val)
      row.approver_name = o ? o.label : ''
      row.approver_value = ''
      if (val === 'specified_user' || val === 'specified_role') row.approver_name = ''
    },
    // 指定用户/角色选择后回填名称
    onSpecifiedChange (row, val, type) {
      if (!val) { row.approver_name = ''; return }
      if (type === 'user') {
        const u = this.userOptions.find(x => String(x.id) === String(val))
        row.approver_name = u ? (u.real_name || u.username) : ''
      } else {
        const r = this.roleOptions.find(x => String(x.value) === String(val))
        row.approver_name = r ? r.label : ''
      }
    },
    async loadUserOptions () {
      try {
        const r = await getApprovalUserOptions()
        this.userOptions = (r.data && r.data.list) || []
      } catch (e) { this.userOptions = [] }
    },
    async loadRoleOptions () {
      try {
        const r = await getRoleOptions()
        this.roleOptions = (r.data && Array.isArray(r.data)) ? r.data : []
      } catch (e) { this.roleOptions = [] }
    },
    addNode () {
      if (this.form.nodes.length >= 10) return
      this.form.nodes.push({ node_name: '', approver_type: 'department_head', approver_value: '', approver_name: '部门负责人', timeout_hours: 48, timeout_action: 'remind' })
    },
    removeNode (idx) { this.form.nodes.splice(idx, 1) },
    openAdd () {
      this.form = this.emptyForm()
      this.dialogVisible = true
      this.$nextTick(() => this.$refs.form && this.$refs.form.clearValidate())
    },
    openEdit (row) {
      const nodes = (row.nodes || []).map(n => ({
        node_name: n.node_name || n.name || '',
        approver_type: n.approver_type || 'role',
        approver_value: n.approver_value || '',
        approver_name: n.approver_name || '',
        timeout_hours: n.timeout_hours || 48,
        timeout_action: n.timeout_action || 'remind'
      }))
      if (!nodes.length) nodes.push({ node_name: '', approver_type: 'department_head', approver_value: '', approver_name: '部门负责人', timeout_hours: 48, timeout_action: 'remind' })
      this.form = {
        id: row.id, business_type: row.business_type, business_name: row.business_name,
        module_name: row.module_name, approval_mode: row.approval_mode, is_active: row.is_active,
        remark: row.remark || '', nodes
      }
      this.dialogVisible = true
      this.$nextTick(() => this.$refs.form && this.$refs.form.clearValidate())
    },
    handleSave () {
      this.$refs.form.validate(valid => {
        if (!valid) return
        if (!this.form.nodes.length) { this.$message.error('至少配置 1 个审批节点'); return }
        const bad = this.form.nodes.some(n => !n.node_name || !n.approver_name)
        if (bad) { this.$message.error('节点名称与审批人角色必填'); return }
        this.saving = true
        saveApprovalDefinition({ ...this.form, nodes: this.form.nodes }).then(r => {
          if (r.code === 0) { this.$message.success('保存成功'); this.dialogVisible = false; this.loadData() } else this.$message.error(r.msg || '保存失败')
        }).catch(() => {}).finally(() => { this.saving = false })
      })
    },
    handleToggle (row) {
      this.$confirm(`确认${row.is_active === 1 ? '停用' : '启用'}该流程配置吗？`, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await toggleApprovalDefinition(row.id)
          if (r.code === 0) { this.$message.success(r.msg || '操作成功'); this.loadData() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    openFlow (row) {
      this.flowNodes = (row.nodes || []).map(n => ({ node_name: n.node_name || n.name || '', approver_name: n.approver_name || '' }))
      this.flowModeLabel = this.modeOptions[row.approval_mode] || '单人审批'
      this.flowVisible = true
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
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.danger-text { color: #F56C6C; }
.node-tip { color: #909399; font-size: 12px; margin-top: 6px; }
.flow-wrap { padding: 10px 0; }
.flow-nodes { display: flex; align-items: center; flex-wrap: wrap; gap: 6px; }
.flow-node {
  border: 1px solid #409EFF; border-radius: 8px; padding: 12px 18px; min-width: 110px;
  text-align: center; background: #f0f7ff;
}
.flow-node-name { font-weight: 600; color: #303133; font-size: 14px; }
.flow-node-role { color: #909399; font-size: 12px; margin-top: 4px; }
.flow-arrow { color: #409EFF; font-size: 18px; }
.flow-mode { margin-top: 18px; color: #E6A23C; font-size: 14px; font-weight: 600; }
.empty-tip { color: #909399; }
</style>
