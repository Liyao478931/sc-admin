<!--
  文件：admin/src/views/business/product/Category.vue
  功能：产品分类管理（树形：支持多级分类）
-->
<template>
  <div class="product-category-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品分类</el-breadcrumb-item>
    </el-breadcrumb>

    <el-card shadow="never">
      <div class="toolbar">
        <el-button v-permission="'business:product:category:add'" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增分类</el-button>
        <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe border>
        <el-table-column prop="category_code" label="分类编码" width="150" show-overflow-tooltip />
        <el-table-column prop="category_name" label="分类名称" min-width="180" show-overflow-tooltip />
        <el-table-column label="父级分类" width="180" show-overflow-tooltip>
          <template slot-scope="s">{{ s.row.parent_name || '-' }}</template>
        </el-table-column>
        <el-table-column prop="sort" label="排序" width="80" align="center" />
        <el-table-column prop="product_count" label="产品数" width="80" align="center" />
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="s.row.status === 1 ? 'success' : 'info'">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" align="center" fixed="right">
          <template slot-scope="s">
            <el-button v-permission="'business:product:category:edit'" type="text" size="mini" @click="openForm(s.row)">编辑</el-button>
            <el-button v-permission="'business:product:category:edit'" type="text" size="mini" @click="toggleStatus(s.row)">{{ s.row.status === 1 ? '停用' : '启用' }}</el-button>
            <el-button v-permission="'business:product:category:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog :title="form.id ? '编辑分类' : '新增分类'" :visible="visible" width="460px" :close-on-click-modal="false" @close="visible = false">
      <el-form ref="form" :model="form" :rules="rules" label-width="90px" size="small">
        <el-form-item label="分类编码" prop="category_code">
          <el-input v-model="form.category_code" :disabled="!!form.id" placeholder="如 PRODUCT-001" clearable />
        </el-form-item>
        <el-form-item label="分类名称" prop="category_name">
          <el-input v-model="form.category_name" placeholder="请输入分类名称" clearable />
        </el-form-item>
        <el-form-item label="父级分类" prop="parent_id">
          <el-select v-model="form.parent_id" placeholder="顶级分类" clearable style="width:100%">
            <el-option label="顶级分类" :value="0" />
            <el-option v-for="c in parentOptions" :key="c.id" :label="c.category_name" :value="c.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="排序" prop="sort">
          <el-input-number v-model="form.sort" :min="0" :max="9999" />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-radio-group v-model="form.status">
            <el-radio :label="1">启用</el-radio>
            <el-radio :label="0">停用</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input v-model="form.description" type="textarea" :rows="2" placeholder="描述说明（可选）" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="visible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="save">保存</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getProductCategoryList, addProductCategory, editProductCategory, deleteProductCategory, updateProductCategoryStatus } from '../../../api/product'

export default {
  name: 'BusinessProductCategory',
  data() {
    return {
      loading: false,
      saving: false,
      visible: false,
      list: [],
      parentOptions: [],
      form: { id: 0, category_code: '', category_name: '', parent_id: 0, sort: 0, status: 1, description: '' },
      rules: {
        category_code: [{ required: true, message: '请输入分类编码', trigger: 'blur' }],
        category_name: [{ required: true, message: '请输入分类名称', trigger: 'blur' }]
      }
    }
  },
  created() {
    this.loadList()
  },
  methods: {
    async loadList() {
      this.loading = true
      try {
        const r = await getProductCategoryList()
        if (r.code === 0) {
          this.list = r.data || []
          this.buildParentOptions()
        }
      } catch (e) {}
      this.loading = false
    },
    buildParentOptions() {
      // 父级可选：全部启用分类（排除自身，编辑时处理）
      this.parentOptions = this.list.filter(c => c.status === 1)
    },
    openForm(row) {
      if (row) {
        this.form = { id: row.id, category_code: row.category_code, category_name: row.category_name, parent_id: row.parent_id || 0, sort: row.sort || 0, status: row.status, description: row.description || '' }
        // 编辑时父级排除自身及其子孙（避免形成环）
        this.parentOptions = this.list.filter(c => c.status === 1 && c.id !== row.id && !this.isDescendant(row.id, c.id))
      } else {
        this.form = { id: 0, category_code: '', category_name: '', parent_id: 0, sort: 0, status: 1, description: '' }
        this.buildParentOptions()
      }
      this.visible = true
      this.$nextTick(() => this.$refs.form && this.$refs.form.clearValidate())
    },
    /** 判断 candidateId 是否为 nodeId 的后代 */
    isDescendant(nodeId, candidateId) {
      const findParent = id => {
        const node = this.list.find(c => c.id === id)
        return node ? node.parent_id || 0 : 0
      }
      let pid = findParent(candidateId)
      let guard = 0
      while (pid > 0 && guard < 50) {
        if (pid === nodeId) return true
        pid = findParent(pid)
        guard++
      }
      return false
    },
    save() {
      this.$refs.form.validate(async valid => {
        if (!valid) return
        this.saving = true
        try {
          const payload = { ...this.form }
          delete payload.id
          const r = this.form.id ? await editProductCategory(this.form.id, payload) : await addProductCategory(payload)
          if (r.code === 0) {
            this.$message.success(this.form.id ? '分类已更新' : '分类已创建')
            this.visible = false
            this.loadList()
          }
        } catch (e) {}
        this.saving = false
      })
    },
    async toggleStatus(row) {
      try {
        const r = await updateProductCategoryStatus(row.id, row.status === 1 ? 0 : 1)
        if (r.code === 0) {
          this.$message.success(r.msg)
          this.loadList()
        }
      } catch (e) {}
    },
    handleDelete(row) {
      this.$confirm(`确认删除分类「${row.category_name}」吗？`, '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteProductCategory(row.id)
          if (r.code === 0) {
            this.$message.success('分类已删除')
            this.loadList()
          }
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.product-category-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.danger { color: #f56c6c; }
</style>
