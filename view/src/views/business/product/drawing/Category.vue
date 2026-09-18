<!--
  文件：admin/src/views/business/product/drawing/Category.vue
  功能：图纸分类管理（树形，无限层级）
  权限：business:product:drawing:category:list/add/edit/delete
-->
<template>
  <div class="drawing-category-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品管理</el-breadcrumb-item>
      <el-breadcrumb-item>图纸管理</el-breadcrumb-item>
      <el-breadcrumb-item>分类管理</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索 -->
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="分类名称">
          <el-input v-model="filter.keyword" placeholder="请输入分类名称" clearable style="width:180px" @keyup.enter.native="loadList" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="filter.status" placeholder="全部" clearable style="width:110px" @change="loadList">
            <el-option label="全部" value="" />
            <el-option label="启用" value="1" />
            <el-option label="停用" value="0" />
          </el-select>
        </el-form-item>
        <div class="filter-btns">
          <el-button type="primary" icon="el-icon-search" @click="loadList">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilter">重置</el-button>
        </div>
      </el-form>
    </el-card>

    <el-card shadow="never">
      <div class="toolbar">
        <el-button v-permission="'business:product:drawing:category:add'" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增分类</el-button>
        <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
      </div>

      <el-table :data="treeData" v-loading="loading" size="small" stripe border row-key="id" :tree-props="{ children: 'children' }" :default-expand-all="true">
        <el-table-column prop="category_code" label="分类编码" width="160" show-overflow-tooltip />
        <el-table-column prop="category_name" label="分类名称" min-width="180" show-overflow-tooltip />
        <el-table-column prop="parent_name" label="父级分类" width="180" show-overflow-tooltip>
          <template slot-scope="s">{{ s.row.parent_name || '-' }}</template>
        </el-table-column>
        <el-table-column prop="sort" label="排序" width="80" align="center" />
        <el-table-column prop="drawing_count" label="图纸数" width="80" align="center" />
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="s.row.status === 1 ? 'success' : 'info'">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="create_time" label="创建时间" width="160" align="center" />
        <el-table-column label="操作" width="200" align="center" fixed="right">
          <template slot-scope="s">
            <el-button v-permission="'business:product:drawing:category:add'" type="text" size="mini" @click="openForm(null, s.row)">新增子分类</el-button>
            <el-button v-permission="'business:product:drawing:category:edit'" type="text" size="mini" @click="openForm(s.row)">编辑</el-button>
            <el-button v-permission="'business:product:drawing:category:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog :title="form.id ? '编辑分类' : '新增分类'" :visible="visible" width="460px" :close-on-click-modal="false" @close="visible = false">
      <el-form ref="form" :model="form" :rules="rules" label-width="90px" size="small">
        <el-form-item label="分类名称" prop="category_name">
          <el-input v-model="form.category_name" placeholder="请输入分类名称" clearable />
        </el-form-item>
        <el-form-item label="分类编码" prop="category_code">
          <el-input v-model="form.category_code" placeholder="如 DRAWING-001" clearable />
        </el-form-item>
        <el-form-item label="父级分类" prop="parent_id">
          <el-cascader
            v-model="parentPath"
            :options="parentOptions"
            :props="{ value: 'value', label: 'label', children: 'children', checkStrictly: true, emitPath: false }"
            clearable
            filterable
            style="width:100%"
            placeholder="不选则为顶级分类"
            @change="v => (form.parent_id = v || 0)"
          />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="form.sort" :min="0" :max="9999" />
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.status" :active-value="1" :inactive-value="0" />
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
import { getDrawingCategoryList, saveDrawingCategory, deleteDrawingCategory, getDrawingCategoryTree } from '../../../../api/product'

export default {
  name: 'BusinessProductDrawingCategory',
  data() {
    return {
      loading: false,
      saving: false,
      visible: false,
      list: [],
      treeData: [],
      parentOptions: [],
      parentPath: [],
      filter: { keyword: '', status: '' },
      form: { id: 0, category_name: '', category_code: '', parent_id: 0, sort: 0, status: 1 },
      rules: {
        category_name: [{ required: true, message: '请输入分类名称', trigger: 'blur' }],
        category_code: [{ required: true, message: '请输入分类编码', trigger: 'blur' }]
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
        const r = await getDrawingCategoryList(this.filter)
        if (r.code === 0) {
          this.list = r.data || []
          this.treeData = this.buildTree(this.list, 0)
        }
      } catch (e) {}
      this.loading = false
    },
    buildTree(list, pid) {
      const tree = []
      list.forEach(item => {
        if (Number(item.parent_id) === pid) {
          item.children = this.buildTree(list, Number(item.id))
          tree.push(item)
        }
      })
      return tree
    },
    async resetFilter() {
      this.filter = { keyword: '', status: '' }
      this.loadList()
    },
    openForm(row, parentRow) {
      if (row) {
        this.form = { id: row.id, category_name: row.category_name, category_code: row.category_code, parent_id: row.parent_id || 0, sort: row.sort || 0, status: row.status }
      } else {
        this.form = { id: 0, category_name: '', category_code: '', parent_id: parentRow ? parentRow.id : 0, sort: 0, status: 1 }
      }
      this.loadParentOptions()
      this.visible = true
      this.$nextTick(() => this.$refs.form && this.$refs.form.clearValidate())
    },
    async loadParentOptions() {
      try {
        const r = await getDrawingCategoryTree()
        this.parentOptions = (r.code === 0 && r.data) ? r.data : []
      } catch (e) { this.parentOptions = [] }
    },
    save() {
      this.$refs.form.validate(async valid => {
        if (!valid) return
        this.saving = true
        try {
          const r = await saveDrawingCategory(this.form)
          if (r.code === 0) {
            this.$message.success(this.form.id ? '分类已更新' : '分类已创建')
            this.visible = false
            this.loadList()
          }
        } catch (e) {}
        this.saving = false
      })
    },
    handleDelete(row) {
      this.$confirm(`确认删除分类「${row.category_name}」吗？`, '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteDrawingCategory(row.id)
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
.drawing-category-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.filter-card { margin-bottom: 14px; }
.filter-btns { display: flex; align-items: center; margin-left: 8px; }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.danger { color: #f56c6c; }
</style>
