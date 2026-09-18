<!--
  文件：admin/src/views/business/purchase/request/Edit.vue
  功能：编辑采购申请（仅草稿/已驳回可编辑，其余只读）
  权限：business:purchase:request:edit
-->
<template>
  <div class="request-edit-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购申请</el-breadcrumb-item>
      <el-breadcrumb-item>编辑申请</el-breadcrumb-item>
    </el-breadcrumb>

    <el-alert v-if="readonly" type="info" :closable="false" show-icon title="当前状态不可编辑，仅可查看" style="margin-bottom:12px" />

    <div class="page-header">
      <span class="page-title">编辑采购申请 - {{ form.request_code || '' }}</span>
      <div class="header-actions">
        <el-button type="primary" size="small" :loading="submitting" :disabled="readonly" @click="handleSave">保存</el-button>
        <el-button size="small" @click="$router.push('/business/purchase/request/list')">取消</el-button>
      </div>
    </div>

    <el-card shadow="never" class="form-card" v-loading="loading">
      <div class="section-title">申请信息</div>
      <RequestForm ref="requestForm" :form="form" :dept-options="deptOptions" :disabled="readonly" @source-type-change="onSourceTypeChange" />
    </el-card>

    <el-card shadow="never" class="items-card" v-loading="loading">
      <div class="section-title">采购明细</div>
      <RequestItemTable ref="itemTable" :items="items" :disabled="readonly" :can-import="!readonly && (form.source_type === 2 || form.source_type === 3)" @import-source="importFromSource" />
    </el-card>
  </div>
</template>

<script>
import RequestForm from './components/RequestForm.vue'
import RequestItemTable from './components/RequestItemTable.vue'
import { getRequestDetail, saveRequest, getDepartmentList, getSourceOrderDetail } from '../../../../api/purchase'

export default {
  name: 'BusinessPurchaseRequestEdit',
  components: { RequestForm, RequestItemTable },
  data() {
    return {
      id: Number(this.$route.params.id) || 0,
      loading: false,
      submitting: false,
      readonly: true,
      deptOptions: [],
      form: {
        request_code: '', title: '', request_type: 1, department_id: null, urgency: 1,
        budget_subject: '', budget_amount: 0, expected_date: '', purpose: '', remark: '',
        source_type: 1, source_id: 0, source_no: ''
      },
      items: []
    }
  },
  async created() {
    await this.loadDepts()
    this.fetchDetail()
  },
  methods: {
    async loadDepts() {
      try {
        const r = await getDepartmentList()
        this.deptOptions = (r.code === 0 && Array.isArray(r.data)) ? r.data : []
      } catch (e) { this.deptOptions = [] }
    },
    async fetchDetail() {
      this.loading = true
      try {
        const r = await getRequestDetail(this.id)
        if (r.code === 0 && r.data) {
          const req = r.data.request || {}
          this.readonly = !(req.approval_status === 0 || req.approval_status === 3)
          this.form = {
            request_code: req.request_code, title: req.title, request_type: req.request_type,
            department_id: req.department_id, urgency: req.urgency, budget_subject: req.budget_subject || '',
            budget_amount: Number(req.budget_amount) || 0, expected_date: req.expected_date || '',
            purpose: req.purpose || '', remark: req.remark || '',
            source_type: req.source_type, source_id: req.source_id, source_no: req.source_no || ''
          }
          this.items = (r.data.items || []).map(it => ({
            product_id: it.product_id, product_code: it.product_code, product_name: it.product_name,
            product_spec: it.product_spec || '', product_unit: it.product_unit || '',
            quantity: Number(it.quantity) || 1, unit_price: Number(it.unit_price) || 0, need_date: it.need_date || ''
          }))
        } else {
          this.$message.error(r.msg || '采购申请不存在')
          this.$router.push('/business/purchase/request/list')
        }
      } catch (e) {}
      this.loading = false
    },
    onSourceTypeChange() {
      this.form.source_id = 0
      this.form.source_no = ''
    },
    async importFromSource() {
      if (!this.form.source_id) { this.$message.warning('请先选择来源单据'); return }
      if (this.items.length) {
        try { await this.$confirm('导入将覆盖当前明细列表，是否继续？', '提示', { type: 'warning' }) } catch (e) { return }
      }
      try {
        const r = await getSourceOrderDetail(this.form.source_type, this.form.source_id)
        if (r.code === 0 && r.data) {
          this.items = (r.data.items || []).filter(x => x.product_id > 0).map(x => ({
            product_id: x.product_id, product_code: x.product_code, product_name: x.product_name,
            product_spec: x.product_spec || '', product_unit: x.product_unit || '',
            quantity: Number(x.quantity) || 1, unit_price: Number(x.unit_price) || 0, need_date: x.need_date || ''
          }))
          this.$message.success('已从来源单据导入明细')
        }
      } catch (e) {}
    },
    async handleSave() {
      const ok = await this.$refs.requestForm.validate()
      if (!ok) return
      if (!this.items.length) { this.$message.warning('请添加采购明细'); return }
      const payload = {
        id: this.id,
        title: this.form.title, request_type: this.form.request_type, department_id: this.form.department_id,
        urgency: this.form.urgency, budget_subject: this.form.budget_subject, budget_amount: this.form.budget_amount,
        expected_date: this.form.expected_date, purpose: this.form.purpose, remark: this.form.remark,
        source_type: this.form.source_type, source_id: this.form.source_id, source_no: this.form.source_no,
        items: this.items.map(i => ({ product_id: i.product_id, quantity: i.quantity, unit_price: i.unit_price, need_date: i.need_date || '' }))
      }
      this.submitting = true
      try {
        const r = await saveRequest(payload)
        if (r.code === 0) { this.$message.success('保存成功'); this.$router.push('/business/purchase/request/list') }
      } catch (e) {}
      this.submitting = false
    }
  }
}
</script>

<style scoped>
.request-edit-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 700; color: #303133; }
.header-actions .el-button + .el-button { margin-left: 10px; }
.form-card { margin-bottom: 14px; }
.section-title { display: flex; align-items: center; font-size: 15px; font-weight: 600; margin-bottom: 12px; }
.section-title::before { content: ''; width: 4px; height: 14px; border-radius: 2px; background: #409eff; margin-right: 8px; }
</style>
