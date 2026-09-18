<template>
  <div class="training-type-page">
    <!-- 工具栏 -->
    <el-card shadow="never">
      <div slot="header" class="card-header">
        <span>培训类型管理</span>
        <div>
          <el-button v-if="hasPerm('safety:training:plan:add')" size="small" type="primary" icon="el-icon-plus" @click="openAdd">新增类型</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </div>
      </div>

      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" />
        <el-table-column prop="type_code" label="类型编码" width="140" />
        <el-table-column prop="type_name" label="类型名称" min-width="120" />
        <el-table-column label="默认培训方式" width="110" align="center">
          <template slot-scope="{ row }">{{ row.mode_text || '-' }}</template>
        </el-table-column>
        <el-table-column prop="default_duration" label="默认培训时长(h)" width="130" align="center">
          <template slot-scope="{ row }">{{ row.default_duration || '-' }}</template>
        </el-table-column>
        <el-table-column prop="description" label="描述" min-width="160" show-overflow-tooltip />
        <el-table-column prop="sort" label="排序" width="70" align="center" />
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.status === 1 ? 'success' : 'info'">{{ row.status === 1 ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="140" align="center">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('safety:training:plan:edit')" size="mini" type="text" @click="openEdit(row)">编辑</el-button>
            <el-button v-if="hasPerm('safety:training:plan:delete')" size="mini" type="text" style="color:#F56C6C" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog :title="form.id ? '编辑类型' : '新增类型'" :visible.sync="dialogVisible" width="500px" append-to-body>
      <el-form :model="form" :rules="rules" ref="formRef" label-width="110px" size="small">
        <el-form-item label="类型编码" prop="type_code">
          <el-input v-model="form.type_code" :disabled="!!form.id" placeholder="如 INDUCTION" />
        </el-form-item>
        <el-form-item label="类型名称" prop="type_name"><el-input v-model="form.type_name" /></el-form-item>
        <el-form-item label="默认培训方式">
          <el-select v-model="form.default_mode" clearable style="width:100%">
            <el-option v-for="m in modeOptions" :key="m.value" :label="m.label" :value="m.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="默认培训时长(h)"><el-input-number v-model="form.default_duration" :min="0" style="width:100%" /></el-form-item>
        <el-form-item label="排序"><el-input-number v-model="form.sort" :min="0" style="width:100%" /></el-form-item>
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
import { getTypeList, addType, editType, deleteType } from '@/api/safetyTraining'

export default {
  name: 'SafetyTrainingType',
  data() {
    return {
      loading: false, list: [], dialogVisible: false, saving: false,
      modeOptions: [
        { value: 'online', label: '线上' }, { value: 'offline', label: '线下' }, { value: 'mixed', label: '混合' }
      ],
      form: { id: 0, type_code: '', type_name: '', default_mode: 'offline', default_duration: 2, sort: 0, status: 1 },
      rules: {
        type_code: [{ required: true, message: '请输入类型编码', trigger: 'blur' }],
        type_name: [{ required: true, message: '请输入类型名称', trigger: 'blur' }]
      }
    }
  },
  created() { this.loadList() },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    async loadList() {
      this.loading = true
      try { const r = await getTypeList(); if (r.code === 0) this.list = r.data || [] } catch (e) {}
      this.loading = false
    },
    openAdd() { this.form = { id: 0, type_code: '', type_name: '', default_mode: 'offline', default_duration: 2, sort: 0, status: 1 }; this.dialogVisible = true },
    openEdit(row) { this.form = { ...row }; this.dialogVisible = true },
    handleSave() {
      this.$refs.formRef.validate(async (valid) => {
        if (!valid) return
        this.saving = true
        try {
          const r = this.form.id ? await editType(this.form.id, this.form) : await addType(this.form)
          if (r.code === 0) { this.$message.success('保存成功'); this.dialogVisible = false; this.loadList() }
        } catch (e) {}
        this.saving = false
      })
    },
    handleDelete(row) {
      this.$confirm(`确认删除培训类型「${row.type_name}」？`, '删除确认', { type: 'warning' }).then(async () => {
        try { const r = await deleteType(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadList() } } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
