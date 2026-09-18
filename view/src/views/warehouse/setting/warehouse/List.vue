<!--
  文件：admin/src/views/warehouse/setting/warehouse/List.vue
  功能：仓库管理（列表/新增/编辑/删除/编码唯一校验）
  权限：warehouse:setting:warehouse:view/add/edit/delete
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>基础设置</el-breadcrumb-item>
      <el-breadcrumb-item>仓库管理</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索筛选 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="仓库名称"><el-input v-model="query.warehouse_name" placeholder="请输入仓库名称" clearable style="width:200px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="仓库编码"><el-input v-model="query.warehouse_code" placeholder="请输入仓库编码" clearable style="width:200px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="仓库类型">
          <el-select v-model="query.warehouse_type" clearable placeholder="全部" style="width:140px" @keyup.enter.native="handleSearch">
            <el-option v-for="(t, v) in WAREHOUSE_TYPES" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:120px" @keyup.enter.native="handleSearch">
            <el-option label="启用" :value="1" /><el-option label="停用" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 操作栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'warehouse:setting:warehouse:add'" type="primary" size="small" icon="el-icon-plus" @click="handleAdd">新增仓库</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 个</span>
    </div>

    <!-- 数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column prop="warehouse_code" label="仓库编码" width="130" />
      <el-table-column prop="warehouse_name" label="仓库名称" min-width="150" show-overflow-tooltip />
      <el-table-column label="仓库类型" width="120" align="center">
        <template slot-scope="s"><el-tag :type="s.row.warehouse_type_tag" effect="plain" size="mini">{{ s.row.warehouse_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="负责人" width="100">
        <template slot-scope="s">{{ s.row.manager_name || '-' }}</template>
      </el-table-column>
      <el-table-column label="联系电话" width="120">
        <template slot-scope="s">{{ s.row.phone || '-' }}</template>
      </el-table-column>
      <el-table-column prop="address" label="仓库地址" min-width="160" show-overflow-tooltip />
      <el-table-column label="状态" width="90" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status === 1 ? 'success' : 'info'" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="200" align="center" fixed="right">
        <template slot-scope="s">
          <el-button v-permission="'warehouse:setting:warehouse:edit'" type="text" size="mini" @click="handleEdit(s.row)">编辑</el-button>
          <el-button v-permission="'warehouse:setting:warehouse:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          <el-button type="text" size="mini" @click="handleViewLocation(s.row)">查看货位</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 新增/编辑对话框 -->
    <el-dialog :title="formData.id ? '编辑仓库' : '新增仓库'" :visible="dialogVisible"
      @update:visible="v => dialogVisible = v" width="600px" top="6vh"
      :close-on-click-modal="false" :close-on-press-escape="false">
      <el-form ref="form" :model="formData" :rules="rules" label-width="100px" size="small">
        <el-form-item label="仓库编码" prop="warehouse_code">
          <el-input v-model="formData.warehouse_code" :disabled="!!formData.id" placeholder="请输入仓库编码，如 WH001" @blur="validateCode" />
        </el-form-item>
        <el-form-item label="仓库名称" prop="warehouse_name"><el-input v-model="formData.warehouse_name" placeholder="请输入仓库名称" /></el-form-item>
        <el-form-item label="仓库类型" prop="warehouse_type">
          <el-select v-model="formData.warehouse_type" placeholder="请选择仓库类型" style="width:100%">
            <el-option v-for="(t, v) in WAREHOUSE_TYPES" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="负责人">
          <el-select v-model="formData.manager_id" filterable clearable placeholder="请选择负责人" style="width:100%">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="联系电话"><el-input v-model="formData.phone" placeholder="请输入联系电话" /></el-form-item>
        <el-form-item label="仓库地址"><el-input v-model="formData.address" placeholder="请输入仓库地址" /></el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="formData.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
        </el-form-item>
        <el-form-item label="备注"><el-input v-model="formData.remark" type="textarea" :rows="3" placeholder="请输入备注信息" /></el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="dialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" :disabled="codeExists" @click="handleSave">保存</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getWarehouseList, saveWarehouse, deleteWarehouse, checkWarehouseCode } from '../../../../api/warehouse'
import { getUserList } from '../../../../api/user'

const WAREHOUSE_TYPES = { 1: '原材料仓', 2: '半成品仓', 3: '成品仓', 4: '备件仓', 5: '待检仓', 6: '报废仓' }

export default {
  name: 'WarehouseSettingWarehouseList',
  data () {
    return {
      WAREHOUSE_TYPES,
      list: [], total: 0, page: 1, pageSize: 10, loading: false,
      query: { warehouse_name: '', warehouse_code: '', warehouse_type: '', status: '' },
      dialogVisible: false, saving: false, codeExists: false, userOptions: [],
      formData: { id: 0, warehouse_code: '', warehouse_name: '', warehouse_type: 1, manager_id: 0, phone: '', address: '', status: 1, remark: '' },
      rules: {
        warehouse_code: [{ required: true, message: '请输入仓库编码', trigger: 'blur' }],
        warehouse_name: [{ required: true, message: '请输入仓库名称', trigger: 'blur' }],
        warehouse_type: [{ required: true, message: '请选择仓库类型', trigger: 'change' }]
      }
    }
  },
  created () {
    this.getList()
    this.loadUsers()
  },
  methods: {
    async loadUsers () {
      try { const u = await getUserList({ page: 1, limit: 200 }); this.userOptions = (u.data && u.data.list) || [] } catch (e) { this.userOptions = [] }
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      Object.keys(this.query).forEach(k => { if (this.query[k] !== '' && this.query[k] !== null) p[k] = this.query[k] })
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getWarehouseList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.query = { warehouse_name: '', warehouse_code: '', warehouse_type: '', status: '' }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.getList() },
    handleAdd () {
      this.formData = { id: 0, warehouse_code: '', warehouse_name: '', warehouse_type: 1, manager_id: 0, phone: '', address: '', status: 1, remark: '' }
      this.codeExists = false
      this.dialogVisible = true
      this.$nextTick(() => { if (this.$refs.form) this.$refs.form.clearValidate() })
    },
    handleEdit (row) {
      this.formData = { ...row, manager_id: row.manager_id || 0 }
      this.codeExists = false
      this.dialogVisible = true
      this.$nextTick(() => { if (this.$refs.form) this.$refs.form.clearValidate() })
    },
    async validateCode () {
      if (this.formData.id) return
      const code = (this.formData.warehouse_code || '').trim()
      if (!code) { this.codeExists = false; return }
      try {
        const r = await checkWarehouseCode(code, 0)
        this.codeExists = !!(r.code === 0 && r.data && r.data.exists)
        if (this.codeExists) {
          this.$message.error('该仓库编码已存在，请重新输入')
          if (this.$refs.form) this.$refs.form.validateField('warehouse_code')
        }
      } catch (e) { this.codeExists = false }
    },
    handleSave () {
      this.$refs.form.validate(async valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        this.saving = true
        try {
          const r = await saveWarehouse(this.formData)
          if (r.code === 0) { this.$message.success('保存成功'); this.dialogVisible = false; this.getList() } else this.$message.error(r.msg || '保存失败')
        } catch (e) {} finally { this.saving = false }
      })
    },
    handleDelete (row) {
      this.$confirm('确认删除该仓库吗？删除后不可恢复，且该仓库下的货位和库存数据将受影响', '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteWarehouse(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.getList() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleViewLocation (row) { this.$router.push({ path: '/warehouse/setting/location', query: { warehouse_id: row.id } }) }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 0; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; margin-bottom: 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.danger { color: #F56C6C; }
</style>
