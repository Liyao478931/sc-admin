<!--
  文件：admin/src/views/hr/recruit/Offer.vue
  功能：录用管理（搜索/新增/编辑/删除/提交审批/撤销/发送录用通知/生成员工档案/导出/详情）
  权限：hr:recruit:view/add/edit/delete/approve/export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>招聘管理</el-breadcrumb-item>
      <el-breadcrumb-item>录用管理</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="录用编号"><el-input v-model="query.offer_no" placeholder="请输入录用编号" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="应聘者"><el-input v-model="query.candidate_name" placeholder="请输入姓名" clearable style="width:140px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="录用职位">
          <el-select v-model="query.position_id" clearable placeholder="全部" style="width:150px">
            <el-option v-for="p in positionOptions" :key="p.id" :label="p.position_name" :value="p.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="录用状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in OFFER_STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
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
        <el-button v-permission="'hr:recruit:add'" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增录用</el-button>
        <el-button v-permission="'hr:recruit:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无录用数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="录用编号" width="150">
        <template slot-scope="s"><el-link type="primary" @click="openDetail(s.row)">{{ s.row.offer_no }}</el-link></template>
      </el-table-column>
      <el-table-column prop="candidate_name" label="应聘者" width="90" align="center" />
      <el-table-column prop="position_name" label="录用职位" min-width="120" show-overflow-tooltip />
      <el-table-column prop="department_name" label="录用部门" width="150" show-overflow-tooltip />
      <el-table-column label="录用薪资" width="110" align="right"><template slot-scope="s">{{ money(s.row.offer_salary) }}</template></el-table-column>
      <el-table-column label="录用状态" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="创建时间" width="160" align="center"><template slot-scope="s">{{ s.row.created_at || '-' }}</template></el-table-column>
      <el-table-column label="操作" width="260" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="openDetail(s.row)">查看详情</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 3" v-permission="'hr:recruit:edit'" type="text" size="mini" @click="openForm(s.row)">编辑</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 3 || s.row.status === 5" v-permission="'hr:recruit:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
            <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right" /></el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-if="s.row.status === 0 || s.row.status === 3" command="submit" icon="el-icon-upload2">提交审批</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1" command="revoke" icon="el-icon-refresh-left">撤销审批</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 2 && !s.row.notice_time" command="notice" icon="el-icon-bell">发送录用通知</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 2 && !s.row.employee_profile_id" command="create" icon="el-icon-user">生成员工档案</el-dropdown-item>
              <el-dropdown-item v-if="!(s.row.status === 0 || s.row.status === 3 || s.row.status === 1 || (s.row.status === 2 && (!s.row.notice_time || !s.row.employee_profile_id)))" disabled>当前状态无可执行操作</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 新增/编辑录用弹窗 -->
    <el-dialog :title="formId ? '编辑录用' : '新增录用'" :visible.sync="formVisible" width="640px" top="6vh">
      <el-form ref="form" :model="form" :rules="rules" label-width="110px" size="small">
        <el-row :gutter="16">
          <el-col :span="24"><el-form-item label="关联简历" prop="resume_id">
            <el-select v-model="form.resume_id" filterable placeholder="选择已录用（终试通过）的简历" style="width:100%" @change="onResumeChange">
              <el-option v-for="r in hiredResumeOptions" :key="r.id" :label="`${r.candidate_name}（${r.candidate_phone}）- ${r.position_name}`" :value="r.id" />
            </el-select>
          </el-form-item></el-col>
          <el-col :span="12"><el-form-item label="录用职位" prop="position_id"><el-select v-model="form.position_id" style="width:100%"><el-option v-for="p in positionOptions" :key="p.id" :label="p.position_name" :value="p.id" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="录用部门" prop="department_id"><el-select v-model="form.department_id" style="width:100%"><el-option v-for="d in departmentOptions" :key="d.id" :label="d.name" :value="d.id" /></el-select></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="录用薪资" prop="offer_salary"><el-input-number v-model="form.offer_salary" :min="0" :precision="2" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="试用期薪资" prop="probation_salary"><el-input-number v-model="form.probation_salary" :min="0" :precision="2" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="录用日期" prop="offer_date"><el-date-picker v-model="form.offer_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="预计入职日期" prop="expected_join_date"><el-date-picker v-model="form.expected_join_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="试用期（月）"><el-input-number v-model="form.probation_period" :min="0" :max="12" style="width:100%" /></el-form-item></el-col>
          <el-col :span="24"><el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="2" placeholder="备注信息（选填）" /></el-form-item></el-col>
        </el-row>
      </el-form>
      <span slot="footer"><el-button size="small" @click="formVisible=false">取消</el-button><el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button></span>
    </el-dialog>

    <!-- 发送录用通知弹窗 -->
    <el-dialog title="发送录用通知" :visible.sync="noticeVisible" width="460px">
      <el-form label-width="90px" size="small">
        <el-form-item label="通知方式">
          <el-checkbox-group v-model="noticeChannels">
            <el-checkbox label="inbox">站内信</el-checkbox>
            <el-checkbox label="email">邮件</el-checkbox>
            <el-checkbox label="sms">短信</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="通知内容">
          <div class="notice-content">恭喜您通过面试！公司拟录用您担任「{{ currentOffer.position_name }}」，录用薪资 {{ money(currentOffer.offer_salary) }} 元/月，预计入职日期 {{ currentOffer.expected_join_date || '-' }}。请及时与我司人力资源部门联系确认。</div>
        </el-form-item>
        <el-alert type="info" :closable="false" show-icon title="若应聘者暂无系统账号，通知仅记录发送时间，不实际投递。" />
      </el-form>
      <span slot="footer"><el-button size="small" @click="noticeVisible=false">取消</el-button><el-button size="small" type="primary" :loading="saving" @click="handleSendNotice">发送</el-button></span>
    </el-dialog>

    <!-- 详情抽屉 -->
    <el-drawer :title="'录用详情 - ' + (detail.offer_no || '')" :visible.sync="detailVisible" size="560px">
      <div class="drawer-body" v-if="detail.id">
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="录用编号">{{ detail.offer_no }}</el-descriptions-item>
          <el-descriptions-item label="录用状态"><el-tag :type="detail.status_tag" size="mini">{{ detail.status_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="应聘者">{{ detail.candidate_name }}</el-descriptions-item>
          <el-descriptions-item label="简历编号">{{ detail.resume_no }}</el-descriptions-item>
          <el-descriptions-item label="录用职位">{{ detail.position_name }}</el-descriptions-item>
          <el-descriptions-item label="录用部门">{{ detail.department_name }}</el-descriptions-item>
          <el-descriptions-item label="录用薪资">{{ money(detail.offer_salary) }}</el-descriptions-item>
          <el-descriptions-item label="试用期薪资">{{ money(detail.probation_salary) }}</el-descriptions-item>
          <el-descriptions-item label="试用期">{{ detail.probation_period }} 个月</el-descriptions-item>
          <el-descriptions-item label="录用日期">{{ detail.offer_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="预计入职日期">{{ detail.expected_join_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建人">{{ detail.creator_name }}</el-descriptions-item>
          <el-descriptions-item label="审批时间" :span="2">{{ detail.approval_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="审批备注" :span="2">{{ detail.approval_remark || '-' }}</el-descriptions-item>
          <el-descriptions-item label="通知时间" :span="2">{{ detail.notice_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="接受时间" :span="2">{{ detail.accept_time || '-' }}</el-descriptions-item>
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
import { getOfferList, saveOffer, deleteOffer, submitOffer, revokeOffer, sendOfferNotice, createEmployeeFromOffer, exportOffer, getOfferDetail } from '@/api/recruit'
import { getRecruitOptions } from '@/api/recruit'

const OFFER_STATUS_TEXT = { 0: '草稿', 1: '待审批', 2: '已通过', 3: '已驳回', 4: '已接受', 5: '已拒绝' }

export default {
  name: 'RecruitOffer',
  data () {
    return {
      OFFER_STATUS_TEXT,
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false, saving: false,
      departmentOptions: [], positionOptions: [], hiredResumeOptions: [],
      query: { offer_no: '', candidate_name: '', position_id: '', status: '' },
      formVisible: false, formId: null, form: {},
      noticeVisible: false, noticeChannels: ['inbox'], currentOffer: {},
      detailVisible: false, detail: {},
      rules: {
        resume_id: [{ required: true, message: '请选择关联简历', trigger: 'change' }],
        position_id: [{ required: true, message: '请选择录用职位', trigger: 'change' }],
        department_id: [{ required: true, message: '请选择录用部门', trigger: 'change' }],
        offer_salary: [{ required: true, message: '请填写录用薪资', trigger: 'change' }],
        offer_date: [{ required: true, message: '请选择录用日期', trigger: 'change' }],
        expected_join_date: [{ required: true, message: '请选择预计入职日期', trigger: 'change' }],
        probation_salary: [{ required: true, message: '请填写试用期薪资', trigger: 'change' }]
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
        if (r.code === 0 && r.data) {
          this.departmentOptions = r.data.departments || []
          this.positionOptions = r.data.positions || []
          this.hiredResumeOptions = r.data.hired_resumes || []
        }
      } catch (e) {}
    },
    money (v) { const n = Number(v) || 0; return n ? '¥ ' + n.toLocaleString('zh-CN', { minimumFractionDigits: 2 }) : '-' },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      Object.keys(this.query).forEach(k => { if (this.query[k] !== '' && this.query[k] !== null) p[k] = this.query[k] })
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getOfferList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.query = { offer_no: '', candidate_name: '', position_id: '', status: '' }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.getList() },
    openForm (row) {
      this.formId = row ? row.id : null
      this.form = row ? {
        id: row.id, resume_id: row.resume_id, position_id: row.position_id, department_id: row.department_id,
        offer_salary: Number(row.offer_salary) || 0, offer_date: row.offer_date || '', expected_join_date: row.expected_join_date || '',
        probation_period: row.probation_period || 3, probation_salary: Number(row.probation_salary) || 0, remark: row.remark || ''
      } : {
        id: 0, resume_id: 0, position_id: 0, department_id: 0, offer_salary: 0, offer_date: '', expected_join_date: '',
        probation_period: 3, probation_salary: 0, remark: ''
      }
      this.formVisible = true
    },
    onResumeChange (id) {
      const r = this.hiredResumeOptions.find(x => x.id === id)
      if (!r) return
      const pos = this.positionOptions.find(p => p.position_name === r.position_name)
      if (pos) this.form.position_id = pos.id
    },
    handleSave () {
      this.$refs.form.validate(valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        this.saving = true
        saveOffer(this.form).then(r => {
          if (r.code === 0) { this.$message.success(r.msg || '保存成功'); this.formVisible = false; this.getList() } else this.$message.error(r.msg || '保存失败')
        }).catch(() => {}).finally(() => { this.saving = false })
      })
    },
    handleDelete (row) {
      this.$confirm('确认删除该录用记录吗？删除后不可恢复', '提示', { type: 'warning' }).then(() => {
        deleteOffer(row.id).then(r => { if (r.code === 0) { this.$message.success('删除成功'); this.getList() } else this.$message.error(r.msg || '删除失败') })
      }).catch(() => {})
    },
    handleMore (cmd, row) {
      if (cmd === 'submit') this.handleSubmit(row)
      else if (cmd === 'revoke') this.handleRevoke(row)
      else if (cmd === 'notice') this.handleNotice(row)
      else if (cmd === 'create') this.handleCreate(row)
    },
    handleSubmit (row) {
      this.$confirm(`确认提交录用 ${row.offer_no} 审批吗？`, '提交审批', { type: 'warning' }).then(() => {
        submitOffer(row.id).then(r => { if (r.code === 0) { this.$message.success('已提交审批'); this.getList() } else this.$message.error(r.msg || '提交失败') })
      }).catch(() => {})
    },
    handleRevoke (row) {
      this.$confirm(`确认撤销录用 ${row.offer_no} 的审批吗？`, '撤销审批', { type: 'warning' }).then(() => {
        revokeOffer(row.id).then(r => { if (r.code === 0) { this.$message.success('已撤销'); this.getList() } else this.$message.error(r.msg || '操作失败') })
      }).catch(() => {})
    },
    handleNotice (row) {
      this.currentOffer = row
      this.noticeChannels = ['inbox']
      this.noticeVisible = true
    },
    handleSendNotice () {
      if (!this.noticeChannels.length) { this.$message.warning('请至少选择一种通知方式'); return }
      this.saving = true
      sendOfferNotice(this.currentOffer.id, this.noticeChannels).then(r => {
        if (r.code === 0) { this.$message.success(r.msg || '通知已发送'); this.noticeVisible = false; this.getList() } else this.$message.error(r.msg || '操作失败')
      }).catch(() => {}).finally(() => { this.saving = false })
    },
    handleCreate (row) {
      this.$confirm(`确认生成员工档案吗？系统将创建员工档案（状态：待入职），录用状态变为已接受，且不可撤销。`, '生成员工档案', { type: 'warning' }).then(() => {
        createEmployeeFromOffer(row.id).then(r => {
          if (r.code === 0) {
            this.$message.success('员工档案已生成')
            this.getList()
            if (r.data && r.data.profile_id) this.$router.push({ path: '/profiles' })
          } else this.$message.error(r.msg || '操作失败')
        })
      }).catch(() => {})
    },
    async openDetail (row) {
      this.detail = {}
      try {
        const r = await getOfferDetail(row.id)
        if (r.code === 0 && r.data) this.detail = r.data
      } catch (e) {}
      this.detailVisible = true
    },
    async handleExport () {
      this.exporting = true
      try {
        const p = { ...this.buildParams() }
        delete p.page; delete p.pageSize
        const r = await exportOffer(p)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `录用管理_${new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14)}.xlsx`
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
.notice-content { color: #606266; background: #f5f7fa; border-radius: 4px; padding: 10px 12px; font-size: 13px; line-height: 1.8; }
</style>
