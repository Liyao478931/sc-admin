<!--
  文件：admin/src/views/business/supplier/category.vue
  功能：经营管理 → 供应商管理 → 供应商分类
    - 分类列表（名称/编码/排序/状态/供应商数/操作）
    - 新增/编辑/删除/切换状态
-->
<template>
  <div class="category-page">
    <el-card shadow="never">
      <div class="toolbar">
        <el-button v-if="hasPerm('business:supplier:category:add')" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增分类</el-button>
        <el-input v-model="keyword" size="small" placeholder="名称/编码搜索" clearable style="width:200px;margin-left:10px" @keyup.enter.native="loadList" @clear="loadList" />
        <span class="flex-1"></span>
        <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe border>
        <el-table-column prop="category_name" label="分类名称" min-width="160" />
        <el-table-column prop="category_code" label="分类编码" width="150" />
        <el-table-column prop="sort" label="排序" width="80" align="center" />
        <el-table-column prop="supplier_count" label="供应商数" width="90" align="center" />
        <el-table-column prop="description" label="描述" min-width="180" show-overflow-tooltip />
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="s.row.status === 1 ? 'success' : 'info'">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" align="center">
          <template slot-scope="s">
            <el-button v-if="hasPerm('business:supplier:category:edit')" type="text" size="mini" @click="openForm(s.row)">编辑</el-button>
            <el-button v-if="hasPerm('business:supplier:category:edit')" type="text" size="mini" @click="toggleStatus(s.row)">{{ s.row.status === 1 ? '停用' : '启用' }}</el-button>
            <el-button v-if="hasPerm('business:supplier:category:delete')" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog :title="isEdit ? '编辑分类' : '新增分类'" :visible="formVisible" width="460px" :close-on-click-modal="false" @close="formVisible = false">
      <el-form ref="form" :model="form" :rules="rules" label-width="100px" size="small">
        <el-form-item label="分类名称" prop="category_name">
          <el-input v-model="form.category_name" maxlength="50" />
        </el-form-item>
        <el-form-item label="分类编码" prop="category_code">
          <el-input v-model="form.category_code" maxlength="30" :disabled="isEdit" placeholder="唯一，如 PARTS" />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="form.sort" :min="0" style="width:100%" />
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="form.description" type="textarea" :rows="2" maxlength="255" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="formVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSubmit">保存</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getSupplierCategoryList, addSupplierCategory, editSupplierCategory, deleteSupplierCategory, updateSupplierCategoryStatus } from '../../../api/businessSupplier'

export default {
  name: 'BusinessSupplierCategory',
  data() {
    return {
      loading: false, saving: false,
      list: [], keyword: '',
      formVisible: false, isEdit: false, currentRow: null,
      form: { category_name: '', category_code: '', sort: 0, status: 1, description: '' },
      rules: {
        category_name: [{ required: true, message: '请输入分类名称', trigger: 'blur' }],
        category_code: [{ required: true, message: '请输入分类编码', trigger: 'blur' }]
      }
    }
  },
  created() { this.loadList() },
  methods: {
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    async loadList() {
      this.loading = true
      try {
        const r = await getSupplierCategoryList({ keyword: this.keyword })
        if (r.code === 0) this.list = r.data || []
      } catch (e) {}
      this.loading = false
    },
    openForm(row) {
      this.isEdit = !!row
      this.currentRow = row || null
      this.form = row
        ? { category_name: row.category_name, category_code: row.category_code, sort: row.sort, status: row.status, description: row.description || '' }
        : { category_name: '', category_code: '', sort: 0, status: 1, description: '' }
      this.formVisible = true
    },
    async handleSubmit() {
      const valid = await this.$refs.form.validate().catch(() => false)
      if (!valid) return
      this.saving = true
      try {
        if (this.isEdit) {
          const r = await editSupplierCategory(this.currentRow.id, this.form)
          if (r.code === 0) { this.$message.success('分类已更新'); this.formVisible = false; this.loadList() }
        } else {
          const r = await addSupplierCategory(this.form)
          if (r.code === 0) { this.$message.success('分类已创建'); this.formVisible = false; this.loadList() }
        }
      } catch (e) {}
      this.saving = false
    },
    async toggleStatus(row) {
      try {
        const r = await updateSupplierCategoryStatus(row.id, row.status === 1 ? 0 : 1)
        if (r.code === 0) { this.$message.success(r.msg); this.loadList() }
      } catch (e) {}
    },
    handleDelete(row) {
      this.$confirm(`确定删除分类「${row.category_name}」？有供应商关联的分类不可删除。`, '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteSupplierCategory(row.id)
          if (r.code === 0) { this.$message.success('分类已删除'); this.loadList() }
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.category-page { padding: 4px 16px; }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.danger { color: #f56c6c; }
</style>
