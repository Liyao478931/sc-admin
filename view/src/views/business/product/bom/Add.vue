<!--
  文件：admin/src/views/business/product/bom/Add.vue
  功能：新增BOM（头信息 + 子项编辑）
  权限：business:product:bom:add
-->
<template>
  <div class="bom-form-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品管理</el-breadcrumb-item>
      <el-breadcrumb-item>BOM管理</el-breadcrumb-item>
      <el-breadcrumb-item>新增BOM</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">新增BOM</span>
      <div class="header-actions">
        <el-button type="primary" size="small" :loading="submitting" @click="handleSave(false)">保存</el-button>
        <el-button size="small" :loading="submitting" @click="handleSave(true)">保存并继续</el-button>
        <el-button size="small" @click="handleCancel">取消</el-button>
      </div>
    </div>

    <el-card shadow="never" class="header-card">
      <div class="section-title">BOM头信息</div>
      <BomHeaderForm ref="headerForm" :form="form" />
    </el-card>

    <el-card shadow="never" class="items-card">
      <div class="section-title">BOM子项列表</div>
      <BomEditableTable ref="editableTable" :items="items" />
    </el-card>
  </div>
</template>

<script>
import BomHeaderForm from './components/BomHeaderForm.vue'
import BomEditableTable from './components/BomEditableTable.vue'
import { saveBom } from '../../../../api/product'

export default {
  name: 'BusinessProductBomAdd',
  components: { BomHeaderForm, BomEditableTable },
  data() {
    return {
      submitting: false,
      form: {
        id: null,
        product_id: null,
        bom_code: '',
        bom_name: '',
        version: 'V1.0',
        quantity: 1,
        unit: '',
        is_default: 0,
        status: 1,
        effective_date: '',
        expiry_date: '',
        remark: ''
      },
      items: []
    }
  },
  created() {
    this.form.bom_code = this.genCode()
  },
  methods: {
    /** 本地生成默认BOM编号：BOM+YYYYMMDD+0001（可手动修改，保存时后端唯一性校验） */
    genCode() {
      const d = new Date()
      const pad = x => String(x).padStart(2, '0')
      return 'BOM' + d.getFullYear() + pad(d.getMonth() + 1) + pad(d.getDate()) + '0001'
    },
    async handleSave(continueEdit) {
      const headerOk = await this.$refs.headerForm.validate()
      if (!headerOk) return
      const submitItems = this.$refs.editableTable.getSubmitItems()
      this.submitting = true
      try {
        const payload = { ...this.form, items: submitItems }
        const r = await saveBom(payload)
        if (r.code === 0) {
          this.$message.success('保存成功')
          if (continueEdit) {
            this.form.id = r.data.id
            this.form.bom_code = r.data.bom_code || this.form.bom_code
          } else {
            this.$router.push('/business/product/bom')
          }
        }
      } catch (e) {}
      this.submitting = false
    },
    handleCancel() {
      if (this.form.product_id || this.form.bom_name || this.items.length) {
        this.$confirm('当前有未保存内容，确认离开吗？', '提示', { type: 'warning' }).then(() => this.$router.push('/business/product/bom')).catch(() => {})
      } else {
        this.$router.push('/business/product/bom')
      }
    }
  }
}
</script>

<style scoped>
.bom-form-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 700; color: #303133; }
.header-actions .el-button + .el-button { margin-left: 10px; }
.header-card { margin-bottom: 14px; }
.section-title { display: flex; align-items: center; font-size: 15px; font-weight: 600; margin-bottom: 12px; }
.section-title::before { content: ''; width: 4px; height: 14px; border-radius: 2px; background: #409eff; margin-right: 8px; }
</style>
