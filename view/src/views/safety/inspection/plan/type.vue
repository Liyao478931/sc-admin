<template>
  <div class="type-page">
    <!-- 工具栏 -->
    <el-card shadow="never">
      <div slot="header" class="card-header">
        <div>
          <el-input v-model="keyword" placeholder="搜索类型名称/编码" size="small" style="width:200px" clearable @keyup.enter.native="loadList" />
          <el-button size="small" icon="el-icon-search" style="margin-left:8px" @click="loadList">搜索</el-button>
        </div>
        <div>
          <el-button v-if="hasPerm('safety:inspection:plan:add')" size="small" type="primary" icon="el-icon-plus" @click="openAdd">新增类型</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </div>
      </div>
      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" />
        <el-table-column prop="type_code" label="类型编码" width="100" />
        <el-table-column prop="type_name" label="类型名称" width="140" />
        <el-table-column label="默认周期" width="100" align="center">
          <template slot-scope="{row}">{{ row.cycle_type_text }} {{ row.default_cycle_value ? row.default_cycle_value + (row.default_cycle_type === 'day' || row.default_cycle_type === 'week' ? '天' : '期') : '' }}</template>
        </el-table-column>
        <el-table-column prop="default_leader_role" label="默认负责人角色" min-width="120" />
        <el-table-column prop="description" label="描述" min-width="160" show-overflow-tooltip />
        <el-table-column prop="sort" label="排序" width="70" align="center" />
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="{row}">
            <el-tag size="mini" :type="row.status === 1 ? 'success' : 'info'">{{ row.status === 1 ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="140" align="center">
          <template slot-scope="{row}">
            <el-button v-if="hasPerm('safety:inspection:plan:edit')" size="mini" type="text" @click="openEdit(row)">编辑</el-button>
            <el-button v-if="hasPerm('safety:inspection:plan:delete')" size="mini" type="text" style="color:#F56C6C" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 新增编辑弹窗 -->
    <el-dialog title="检查类型" :visible.sync="dialogVisible" width="500px" append-to-body>
      <el-form :model="form" :rules="rules" ref="formRef" label-width="120px" size="small">
        <el-form-item label="类型编码" prop="type_code">
          <el-input v-model="form.type_code" :disabled="!!form.id" placeholder="如 DAILY" />
        </el-form-item>
        <el-form-item label="类型名称" prop="type_name"><el-input v-model="form.type_name" /></el-form-item>
        <el-form-item label="默认周期类型">
          <el-select v-model="form.default_cycle_type" clearable placeholder="请选择" style="width:100%">
            <el-option v-for="c in cycleOptions" :key="c.value" :label="c.label" :value="c.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="默认周期值"><el-input-number v-model="form.default_cycle_value" :min="0" :max="999" /></el-form-item>
        <el-form-item label="默认负责人角色"><el-input v-model="form.default_leader_role" /></el-form-item>
        <el-form-item label="描述"><el-input v-model="form.description" /></el-form-item>
        <el-form-item label="排序"><el-input-number v-model="form.sort" :min="0" /></el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.status" :active-value="1" :inactive-value="0" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="dialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getTypeList, addType, editType, deleteType } from '@/api/safetyInspectionPlan'

export default {
  name: 'SafetyInspectionType',
  data() {
    return {
      loading: false, list: [], keyword: '', dialogVisible: false, saving: false,
      form: { id: 0, type_code: '', type_name: '', default_cycle_type: '', default_cycle_value: 1, default_leader_role: '', description: '', sort: 0, status: 1 },
      rules: { type_code: [{ required: true, message: '类型编码必填', trigger: 'blur' }], type_name: [{ required: true, message: '类型名称必填', trigger: 'blur' }] },
      cycleOptions: [
        { value: 'day', label: '每日' }, { value: 'week', label: '每周' }, { value: 'month', label: '每月' },
        { value: 'quarter', label: '每季' }, { value: 'year', label: '每年' },
      ],
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
      try {
        const r = await getTypeList({ keyword: this.keyword })
        if (r.code === 0) this.list = r.data || []
      } catch (e) {}
      this.loading = false
    },
    openAdd() { this.form = { id: 0, type_code: '', type_name: '', default_cycle_type: '', default_cycle_value: 1, default_leader_role: '', description: '', sort: 0, status: 1 }; this.dialogVisible = true },
    openEdit(row) { this.form = { ...row }; this.dialogVisible = true },
    handleSave() {
      this.$refs.formRef.validate(async (valid) => {
        if (!valid) return
        this.saving = true
        try {
          const d = { ...this.form }
          const r = this.form.id ? await editType(this.form.id, d) : await addType(d)
          if (r.code === 0) { this.$message.success('保存成功'); this.dialogVisible = false; this.loadList() }
        } catch (e) {}
        this.saving = false
      })
    },
    handleDelete(row) {
      this.$confirm(`确认删除类型「${row.type_name}」？`, '删除确认', { type: 'warning' }).then(async () => {
        const r = await deleteType(row.id)
        if (r.code === 0) { this.$message.success('删除成功'); this.loadList() }
      }).catch(() => {})
    },
  },
}
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
