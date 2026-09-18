<template>
  <div class="cert-template-page">
    <!-- 工具栏 -->
    <el-card shadow="never">
      <div slot="header" class="card-header">
        <span>证书模板管理</span>
        <div>
          <el-button v-if="hasPerm('safety:training:certificate:config')" size="small" type="primary" icon="el-icon-plus" @click="openAdd">新增模板</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </div>
      </div>

      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" />
        <el-table-column prop="template_code" label="模板编号" width="180" />
        <el-table-column prop="template_name" label="模板名称" min-width="130" />
        <el-table-column prop="type_name" label="适用培训类型" min-width="110">
          <template slot-scope="{ row }">{{ row.type_name || '通用' }}</template>
        </el-table-column>
        <el-table-column prop="certificate_name" label="证书名称" min-width="130" />
        <el-table-column prop="validity_years" label="有效年限" width="90" align="center">
          <template slot-scope="{ row }">{{ row.validity_years === 0 ? '长期' : row.validity_years + ' 年' }}</template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.status === 1 ? 'success' : 'info'">{{ row.status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="140" align="center">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('safety:training:certificate:config')" size="mini" type="text" @click="openEdit(row)">编辑</el-button>
            <el-button v-if="hasPerm('safety:training:certificate:config')" size="mini" type="text" style="color:#F56C6C" @click="doDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog :title="form.id ? '编辑模板' : '新增模板'" :visible.sync="dialogVisible" width="500px" append-to-body>
      <el-form :model="form" :rules="rules" ref="formRef" label-width="110px" size="small">
        <el-form-item label="模板名称" prop="template_name"><el-input v-model="form.template_name" /></el-form-item>
        <el-form-item label="适用培训类型">
          <el-select v-model="form.training_type_id" clearable style="width:100%">
            <el-option v-for="t in typeOptions" :key="t.id" :label="t.type_name" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="证书名称" prop="certificate_name"><el-input v-model="form.certificate_name" /></el-form-item>
        <el-form-item label="有效年限">
          <el-input-number v-model="form.validity_years" :min="0" :max="20" style="width:100%" />
          <div style="color:#909399;font-size:12px">0 表示长期有效</div>
        </el-form-item>
        <el-form-item label="状态"><el-switch v-model="form.status" :active-value="1" :inactive-value="0" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="dialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getCertificateTemplateList, saveCertificateTemplate, deleteCertificateTemplate, getTypeOptions } from '@/api/safetyTrainingArchive'

export default {
  name: 'SafetyCertificateTemplate',
  data() {
    return {
      loading: false, list: [], dialogVisible: false, saving: false, typeOptions: [],
      form: { id: 0, template_name: '', training_type_id: null, certificate_name: '', validity_years: 0, status: 1 },
      rules: {
        template_name: [{ required: true, message: '请输入模板名称', trigger: 'blur' }],
        certificate_name: [{ required: true, message: '请输入证书名称', trigger: 'blur' }]
      }
    }
  },
  created() {
    if (this.$store.state.user && this.$store.state.user.permissions && !this.$store.state.user.permissions.length) {
      this.$store.dispatch('user/loadPermissions')
    }
    this.loadList(); this.loadTypes()
  },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    async loadList() {
      this.loading = true
      try { const r = await getCertificateTemplateList(); if (r.code === 0) this.list = r.data || [] } catch (e) {}
      this.loading = false
    },
    async loadTypes() {
      try { const r = await getTypeOptions(); if (r.code === 0) this.typeOptions = r.data || [] } catch (e) {}
    },
    openAdd() { this.form = { id: 0, template_name: '', training_type_id: null, certificate_name: '', validity_years: 0, status: 1 }; this.dialogVisible = true },
    openEdit(row) { this.form = { ...row }; this.dialogVisible = true },
    handleSave() {
      this.$refs.formRef.validate(async (valid) => {
        if (!valid) return
        this.saving = true
        try {
          const r = await saveCertificateTemplate(this.form)
          if (r.code === 0) { this.$message.success('保存成功'); this.dialogVisible = false; this.loadList() }
        } catch (e) {}
        this.saving = false
      })
    },
    doDelete(row) {
      this.$confirm(`确认删除模板「${row.template_name}」？`, '删除确认', { type: 'warning' }).then(async () => {
        try { const r = await deleteCertificateTemplate(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadList() } } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
