<!--
  文件：admin/src/views/hr/recruit/Requirement.vue
  功能：招聘需求（搜索/新增/编辑/删除/提交审批/撤销/关闭/导出/详情）
  权限：hr:recruit:view/add/edit/delete/export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>招聘管理</el-breadcrumb-item>
      <el-breadcrumb-item>招聘需求</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="需求编号"><el-input v-model="query.requirement_no" placeholder="请输入需求编号" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="岗位名称"><el-input v-model="query.position_name" placeholder="请输入岗位名称" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="需求部门">
          <el-select v-model="query.department_id" clearable placeholder="全部" style="width:150px">
            <el-option v-for="d in departmentOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="紧急程度">
          <el-select v-model="query.urgency" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in URGENCY_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="需求状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in REQ_STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'hr:recruit:add'" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增需求</el-button>
        <el-button v-permission="'hr:recruit:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无招聘需求数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="需求编号" width="150">
        <template slot-scope="s"><el-link type="primary" @click="openDetail(s.row)">{{ s.row.requirement_no }}</el-link></template>
      </el-table-column>
      <el-table-column prop="position_name" label="岗位名称" min-width="120" show-overflow-tooltip />
      <el-table-column prop="department_name" label="需求部门" width="150" show-overflow-tooltip />
      <el-table-column prop="position_count" label="招聘人数" width="90" align="center"><template slot-scope="s">{{ s.row.position_count }} 人</template></el-table-column>
      <el-table-column label="紧急程度" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.urgency_tag" effect="plain" size="mini">{{ s.row.urgency_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="需求状态" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="创建时间" width="160" align="center"><template slot-scope="s">{{ s.row.created_at || '-' }}</template></el-table-column>
      <el-table-column label="操作" width="240" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="openDetail(s.row)">查看详情</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 3" v-permission="'hr:recruit:edit'" type="text" size="mini" @click="openForm(s.row)">编辑</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 3 || s.row.status === 4" v-permission="'hr:recruit:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
            <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right" /></el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-if="s.row.status === 0 || s.row.status === 3" command="submit" icon="el-icon-upload2">提交审批</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1" command="revoke" icon="el-icon-refresh-left">撤销审批</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1 || s.row.status === 2" command="close" icon="el-icon-circle-close">关闭需求</el-dropdown-item>
              <el-dropdown-item v-if="!(s.row.status === 0 || s.row.status === 3 || s.row.status === 1 || s.row.status === 2)" disabled>当前状态无可执行操作</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 新增/编辑弹窗 -->
    <el-dialog :title="formId ? '编辑招聘需求' : '新增招聘需求'" :visible.sync="formVisible" width="640px" top="6vh">
      <el-form ref="form" :model="form" :rules="rules" label-width="110px" size="small">
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="岗位名称" prop="position_name"><el-input v-model="form.position_name" placeholder="如：焊工、电工、维修工" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="需求部门" prop="department_id"><el-select v-model="form.department_id" placeholder="请选择部门" style="width:100%"><el-option v-for="d in departmentOptions" :key="d.id" :label="d.name" :value="d.id" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="岗位类别" prop="position_category"><el-select v-model="form.position_category" style="width:100%"><el-option v-for="(t, v) in CATEGORY_TEXT" :key="v" :label="t" :value="Number(v)" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="招聘人数" prop="position_count"><el-input-number v-model="form.position_count" :min="1" :max="999" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="紧急程度" prop="urgency"><el-select v-model="form.urgency" style="width:100%"><el-option v-for="(t, v) in URGENCY_TEXT" :key="v" :label="t" :value="Number(v)" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="期望到岗日期"><el-date-picker v-model="form.expected_join_date" type="date" value-format="yyyy-MM-dd" placeholder="选填" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="薪资范围-最低"><el-input-number v-model="form.salary_range_min" :min="0" :precision="2" :controls="false" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="薪资范围-最高"><el-input-number v-model="form.salary_range_max" :min="0" :precision="2" :controls="false" style="width:100%" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="招聘原因" prop="reason"><el-input v-model="form.reason" type="textarea" :rows="2" maxlength="500" placeholder="请填写招聘原因" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="岗位要求" prop="requirements"><el-input v-model="form.requirements" type="textarea" :rows="3" maxlength="2000" placeholder="技能、经验、学历等要求" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="2" placeholder="备注信息（选填）" /></el-form-item></el-col>
        </el-row>
      </el-form>
      <span slot="footer"><el-button size="small" @click="formVisible=false">取消</el-button><el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button></span>
    </el-dialog>

    <!-- 详情抽屉 -->
    <el-drawer :title="'招聘需求详情 - ' + (detail.requirement_no || '')" :visible.sync="detailVisible" size="560px">
      <div class="drawer-body" v-if="detail.id">
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="需求编号">{{ detail.requirement_no }}</el-descriptions-item>
          <el-descriptions-item label="状态"><el-tag :type="detail.status_tag" size="mini">{{ detail.status_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="岗位名称">{{ detail.position_name }}</el-descriptions-item>
          <el-descriptions-item label="需求部门">{{ detail.department_name }}</el-descriptions-item>
          <el-descriptions-item label="岗位类别">{{ detail.position_category_label }}</el-descriptions-item>
          <el-descriptions-item label="招聘人数">{{ detail.position_count }} 人</el-descriptions-item>
          <el-descriptions-item label="紧急程度"><el-tag :type="detail.urgency_tag" effect="plain" size="mini">{{ detail.urgency_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="期望到岗">{{ detail.expected_join_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="薪资范围">{{ money(detail.salary_range_min) }} ~ {{ money(detail.salary_range_max) }}</el-descriptions-item>
          <el-descriptions-item label="创建人">{{ detail.creator_name }}</el-descriptions-item>
          <el-descriptions-item label="创建时间" :span="2">{{ detail.created_at }}</el-descriptions-item>
          <el-descriptions-item label="招聘原因" :span="2">{{ detail.reason || '-' }}</el-descriptions-item>
          <el-descriptions-item label="岗位要求" :span="2">{{ detail.requirements || '-' }}</el-descriptions-item>
          <el-descriptions-item label="审批时间" :span="2">{{ detail.approval_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="审批备注" :span="2">{{ detail.approval_remark || '-' }}</el-descriptions-item>
          <el-descriptions-item label="备注" :span="2">{{ detail.remark || '-' }}</el-descriptions-item>
        </el-descriptions>
        <h4 class="section-title">审批记录</h4>
        <el-timeline v-if="detail.approval_histories && detail.approval_histories.length" style="padding-left:8px;">
          <el-timeline-item v-for="(h, i) in detail.approval_histories" :key="i" :timestamp="h.created_at" :type="h.result === 'reject' ? 'danger' : (h.action === 'submit' ? 'primary' : 'success')" placement="top">
            <div>{{ h.action_label }}：{{ h.result === 'pass' ? '通过' : (h.result === 'reject' ? '驳回' : '') }} <span style="color:#909399">({{ h.operator_name }})</span></div>
            <div v-if="h.comment" style="color:#606266;font-size:12px;">意见：{{ h.comment }}</div>
          </el-timeline-item>
        </el-timeline>
        <el-empty v-else description="暂无审批记录" :image-size="50" />
      </div>
    </el-drawer>
  </div>
</template>

<script>
import { getRequirementList, saveRequirement, deleteRequirement, submitRequirement, revokeRequirement, closeRequirement, exportRequirement } from '@/api/recruit'
import { getRecruitOptions } from '@/api/recruit'

const CATEGORY_TEXT = { 1: '工人', 2: '技术员', 3: '业务员', 4: '管理人员', 5: '其他' }
const URGENCY_TEXT = { 1: '普通', 2: '紧急', 3: '特急' }
const REQ_STATUS_TEXT = { 0: '草稿', 1: '待审批', 2: '已通过', 3: '已驳回', 4: '已关闭' }

export default {
  name: 'RecruitRequirement',
  data () {
    return {
      CATEGORY_TEXT, URGENCY_TEXT, REQ_STATUS_TEXT,
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false, saving: false,
      departmentOptions: [],
      query: { requirement_no: '', position_name: '', department_id: '', urgency: '', status: '' },
      formVisible: false, formId: null, form: {},
      detailVisible: false, detail: {},
      rules: {
        position_name: [{ required: true, message: '请填写岗位名称', trigger: 'blur' }],
        department_id: [{ required: true, message: '请选择需求部门', trigger: 'change' }],
        position_category: [{ required: true, message: '请选择岗位类别', trigger: 'change' }],
        position_count: [{ required: true, message: '请填写招聘人数', trigger: 'change' }],
        urgency: [{ required: true, message: '请选择紧急程度', trigger: 'change' }],
        reason: [{ required: true, message: '请填写招聘原因', trigger: 'blur' }],
        requirements: [{ required: true, message: '请填写岗位要求', trigger: 'blur' }]
      }
    }
  },
  created () {
    this.getList()
    this.loadOptions()
  },
  methods: {
    async loadOptions () {
      try {
        const r = await getRecruitOptions()
        if (r.code === 0 && r.data) this.departmentOptions = r.data.departments || []
      } catch (e) { this.departmentOptions = [] }
    },
    money (v) { const n = Number(v) || 0; return n ? '¥ ' + n.toLocaleString('zh-CN') : '-' },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      Object.keys(this.query).forEach(k => { if (this.query[k] !== '' && this.query[k] !== null) p[k] = this.query[k] })
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getRequirementList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.query = { requirement_no: '', position_name: '', department_id: '', urgency: '', status: '' }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.getList() },
    openForm (row) {
      this.formId = row ? row.id : null
      this.form = row ? {
        id: row.id, position_name: row.position_name, department_id: row.department_id,
        position_category: row.position_category, position_count: row.position_count, urgency: row.urgency,
        expected_join_date: row.expected_join_date || '', salary_range_min: Number(row.salary_range_min) || 0,
        salary_range_max: Number(row.salary_range_max) || 0, reason: row.reason || '', requirements: row.requirements || '', remark: row.remark || ''
      } : {
        id: 0, position_name: '', department_id: 0, position_category: 1, position_count: 1, urgency: 1,
        expected_join_date: '', salary_range_min: 0, salary_range_max: 0, reason: '', requirements: '', remark: ''
      }
      this.formVisible = true
    },
    handleSave () {
      this.$refs.form.validate(valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        if (Number(this.form.salary_range_max) > 0 && Number(this.form.salary_range_min) > Number(this.form.salary_range_max)) {
          this.$message.warning('薪资最低值不能大于最高值'); return
        }
        this.saving = true
        saveRequirement(this.form).then(r => {
          if (r.code === 0) { this.$message.success(r.msg || '保存成功'); this.formVisible = false; this.getList() } else this.$message.error(r.msg || '保存失败')
        }).catch(() => {}).finally(() => { this.saving = false })
      })
    },
    handleDelete (row) {
      this.$confirm('确认删除该招聘需求吗？删除后不可恢复', '提示', { type: 'warning' }).then(() => {
        deleteRequirement(row.id).then(r => {
          if (r.code === 0) { this.$message.success('删除成功'); this.getList() } else this.$message.error(r.msg || '删除失败')
        })
      }).catch(() => {})
    },
    handleMore (cmd, row) {
      if (cmd === 'submit') this.handleSubmit(row)
      else if (cmd === 'revoke') this.handleRevoke(row)
      else if (cmd === 'close') this.handleClose(row)
    },
    handleSubmit (row) {
      this.$confirm(`确认提交需求 ${row.requirement_no} 审批吗？`, '提交审批', { type: 'warning' }).then(() => {
        submitRequirement(row.id).then(r => { if (r.code === 0) { this.$message.success('已提交审批'); this.getList() } else this.$message.error(r.msg || '提交失败') })
      }).catch(() => {})
    },
    handleRevoke (row) {
      this.$confirm(`确认撤销需求 ${row.requirement_no} 的审批吗？`, '撤销审批', { type: 'warning' }).then(() => {
        revokeRequirement(row.id).then(r => { if (r.code === 0) { this.$message.success('已撤销'); this.getList() } else this.$message.error(r.msg || '操作失败') })
      }).catch(() => {})
    },
    handleClose (row) {
      this.$confirm(`确认关闭需求 ${row.requirement_no} 吗？`, '关闭需求', { type: 'warning' }).then(() => {
        closeRequirement(row.id).then(r => { if (r.code === 0) { this.$message.success('已关闭'); this.getList() } else this.$message.error(r.msg || '操作失败') })
      }).catch(() => {})
    },
    async openDetail (row) {
      this.detail = {}
      try {
        const r = await getRequirementDetail(row.id)
        if (r.code === 0 && r.data) this.detail = r.data
      } catch (e) {}
      this.detailVisible = true
    },
    async handleExport () {
      this.exporting = true
      try {
        const p = { ...this.buildParams() }
        delete p.page; delete p.pageSize
        const r = await exportRequirement(p)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `招聘需求_${new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14)}.xlsx`
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
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.danger { color: #F56C6C; }
.drawer-body { padding: 0 20px 20px; }
.section-title { margin: 20px 0 10px; color: #606266; border-bottom: 1px solid #f0f0f0; padding-bottom: 6px; }
</style>
