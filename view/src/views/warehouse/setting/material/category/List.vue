<!--
  文件：admin/src/views/warehouse/setting/material/category/List.vue
  功能：物料分类管理（树形列表/新增/编辑/删除/新增子分类）
  权限：warehouse:setting:material:category:view/add/edit/delete
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>基础设置</el-breadcrumb-item>
      <el-breadcrumb-item>物料分类管理</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="分类名称"><el-input v-model="q.category_name" placeholder="请输入分类名称" clearable style="width:200px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="状态">
          <el-select v-model="q.status" clearable placeholder="全部" style="width:120px">
            <el-option label="启用" :value="1" /><el-option label="停用" :value="0" />
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
        <el-button v-permission="'warehouse:setting:material:category:add'" type="primary" size="small" icon="el-icon-plus" @click="openDialog()">新增分类</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 个</span>
    </div>

    <el-table :data="tree" v-loading="loading" size="small" border stripe row-key="id" :tree-props="{ children: 'children' }" empty-text="暂无数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column prop="category_code" label="分类编码" width="130" />
      <el-table-column prop="category_name" label="分类名称" min-width="180" />
      <el-table-column label="父级分类" width="160" show-overflow-tooltip><template slot-scope="s">{{ s.row.parent_name || '-' }}</template></el-table-column>
      <el-table-column prop="sort" label="排序" width="80" align="center" />
      <el-table-column label="状态" width="90" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status === 1 ? 'success' : 'info'" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="create_time" label="创建时间" width="170" />
      <el-table-column label="操作" width="200" align="center" fixed="right">
        <template slot-scope="s">
          <el-button v-permission="'warehouse:setting:material:category:add'" type="text" size="mini" @click="openDialog(null, s.row)">新增子分类</el-button>
          <el-button v-permission="'warehouse:setting:material:category:edit'" type="text" size="mini" @click="openDialog(s.row)">编辑</el-button>
          <el-button v-permission="'warehouse:setting:material:category:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog :title="form.id ? '编辑分类' : '新增分类'" :visible="dialogVisible"
      @update:visible="v => dialogVisible = v" width="560px" top="6vh"
      :close-on-click-modal="false" :close-on-press-escape="false">
      <el-form ref="form" :model="form" :rules="rules" label-width="100px" size="small">
        <el-form-item label="分类名称" prop="category_name"><el-input v-model="form.category_name" placeholder="请输入分类名称" /></el-form-item>
        <el-form-item label="分类编码" prop="category_code"><el-input v-model="form.category_code" placeholder="如 MF" /></el-form-item>
        <el-form-item label="父级分类">
          <el-cascader v-model="form.parent_path" :options="parentOptions" :props="{ value: 'id', label: 'category_name', children: 'children', checkStrictly: true }" clearable placeholder="不选则为顶级分类" style="width:100%" @change="v => form.parent_id = v && v.length ? v[v.length - 1] : 0" />
        </el-form-item>
        <el-form-item label="排序"><el-input-number v-model="form.sort" :min="0" style="width:200px" /></el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="dialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getMaterialCategoryList, saveMaterialCategory, deleteMaterialCategory } from '../../../../../api/warehouse'

export default {
  name: 'WarehouseSettingMaterialCategory',
  data () {
    return {
      list: [], tree: [], total: 0, loading: false,
      q: { category_name: '', status: '' },
      dialogVisible: false, saving: false,
      form: { id: 0, parent_id: 0, parent_path: [], category_name: '', category_code: '', sort: 0, status: 1 },
      rules: {
        category_name: [{ required: true, message: '请输入分类名称', trigger: 'blur' }],
        category_code: [{ required: true, message: '请输入分类编码', trigger: 'blur' }]
      }
    }
  },
  computed: {
    // 父级选项：排除自身及其子孙（避免循环）
    parentOptions () {
      const exclude = new Set()
      if (this.form.id) {
        const collect = nodes => nodes.forEach(n => { exclude.add(n.id); if (n.children) collect(n.children) })
        const self = this.tree.find(n => n.id === this.form.id)
        if (self) collect([self])
      }
      const filter = nodes => nodes.filter(n => !exclude.has(n.id)).map(n => ({ ...n, children: n.children ? filter(n.children) : [] }))
      return filter(this.tree)
    }
  },
  created () { this.getList() },
  methods: {
    buildParams () {
      const p = {}
      if (this.q.category_name) p.category_name = this.q.category_name
      if (this.q.status !== '') p.status = this.q.status
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getMaterialCategoryList(this.buildParams())
        if (r.code === 0 && r.data) {
          this.list = r.data.list || []
          this.tree = r.data.tree || []
          this.total = this.list.length
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.getList() },
    handleReset () { this.q = { category_name: '', status: '' }; this.handleSearch() },
    openDialog (row, parentRow) {
      if (row) {
        this.form = { id: row.id, parent_id: row.parent_id || 0, parent_path: row.parent_id ? [row.parent_id] : [], category_name: row.category_name, category_code: row.category_code, sort: row.sort || 0, status: row.status }
      } else {
        this.form = { id: 0, parent_id: parentRow ? parentRow.id : 0, parent_path: parentRow ? [parentRow.id] : [], category_name: '', category_code: '', sort: 0, status: 1 }
      }
      this.dialogVisible = true
      this.$nextTick(() => { if (this.$refs.form) this.$refs.form.clearValidate() })
    },
    handleSave () {
      this.$refs.form.validate(async valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        this.saving = true
        try {
          const r = await saveMaterialCategory(this.form)
          if (r.code === 0) { this.$message.success('保存成功'); this.dialogVisible = false; this.getList() } else this.$message.error(r.msg || '保存失败')
        } catch (e) {} finally { this.saving = false }
      })
    },
    handleDelete (row) {
      this.$confirm('确认删除该分类吗？', '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteMaterialCategory(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.getList() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 0; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.danger { color: #F56C6C; }
</style>
