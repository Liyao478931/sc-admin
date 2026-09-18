<!--
  文件：admin/src/views/production/quality/standard/Index.vue
  功能：质检标准管理（列表/新增编辑对话框含检验项目可编辑表格/启停/删除）
  权限：quality:standard:view 及各项操作权限
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>质量管理</el-breadcrumb-item>
      <el-breadcrumb-item>质检标准</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="标准名称"><el-input v-model="query.standard_name" placeholder="请输入标准名称" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="标准编码"><el-input v-model="query.standard_code" placeholder="请输入标准编码" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="产品类型">
          <el-select v-model="query.product_type" clearable placeholder="全部" style="width:120px">
            <el-option v-for="t in productTypes" :key="t" :label="t" :value="t" />
          </el-select>
        </el-form-item>
        <el-form-item label="检验类型">
          <el-select v-model="query.inspection_type" clearable placeholder="全部" style="width:120px">
            <el-option v-for="(t, v) in inspectionOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:100px">
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
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
        <el-button v-permission="'quality:standard:add'" type="primary" size="small" icon="el-icon-plus" @click="openDialog()">新增标准</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无质检标准">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column prop="standard_code" label="标准编码" width="110" />
      <el-table-column prop="standard_name" label="标准名称" min-width="160" show-overflow-tooltip />
      <el-table-column prop="product_type" label="适用产品类型" width="120" />
      <el-table-column label="检验类型" width="100" align="center"><template slot-scope="s">{{ s.row.inspection_type_label }}</template></el-table-column>
      <el-table-column label="检验项目数" width="90" align="center"><template slot-scope="s">{{ s.row.item_count }}</template></el-table-column>
      <el-table-column label="状态" width="80" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="200" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="openDialog(s.row)">编辑</el-button>
          <el-button v-permission="'quality:standard:delete'" type="text" size="mini" class="danger-text" @click="handleDelete(s.row)">删除</el-button>
          <el-button type="text" size="mini" @click="handleToggle(s.row)">{{ s.row.status === 1 ? '停用' : '启用' }}</el-button>
          <el-button type="text" size="mini" @click="openItems(s.row)">查看项目</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 新增/编辑标准对话框 -->
    <el-dialog :title="dialog.id ? '编辑质检标准' : '新增质检标准'" :visible.sync="dialogVisible" width="800px" append-to-body>
      <el-form ref="stdForm" :model="dialog" :rules="stdRules" label-width="100px" size="small">
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="标准编码" prop="standard_code"><el-input v-model="dialog.standard_code" placeholder="请输入标准编码，如 QS-001" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="标准名称" prop="standard_name"><el-input v-model="dialog.standard_name" placeholder="请输入标准名称" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="适用产品类型" prop="product_type">
            <el-select v-model="dialog.product_type" style="width:100%"><el-option v-for="t in productTypes" :key="t" :label="t" :value="t" /></el-select>
          </el-form-item></el-col>
          <el-col :span="12"><el-form-item label="检验类型" prop="inspection_type">
            <el-select v-model="dialog.inspection_type" style="width:100%"><el-option v-for="(t, v) in inspectionOptions" :key="v" :label="t" :value="Number(v)" /></el-select>
          </el-form-item></el-col>
        </el-row>
        <div class="sub-title">检验项目</div>
        <el-table :data="dialog.items" size="mini" border>
          <el-table-column type="index" label="#" width="40" align="center" />
          <el-table-column label="项目名称" min-width="120"><template slot-scope="s"><el-input v-model="s.row.item_name" size="mini" placeholder="项目名称" /></template></el-table-column>
          <el-table-column label="项目类型" width="90"><template slot-scope="s">
            <el-select v-model="s.row.item_type" size="mini" style="width:100%"><el-option v-for="(t, v) in itemTypeOptions" :key="v" :label="t" :value="Number(v)" /></el-select>
          </template></el-table-column>
          <el-table-column label="标准值" width="110"><template slot-scope="s"><el-input v-model="s.row.standard_value" size="mini" placeholder="如 Φ100±0.05" /></template></el-table-column>
          <el-table-column label="上限" width="90"><template slot-scope="s"><el-input-number v-model="s.row.upper_limit" :controls="false" size="mini" style="width:100%" /></template></el-table-column>
          <el-table-column label="下限" width="90"><template slot-scope="s"><el-input-number v-model="s.row.lower_limit" :controls="false" size="mini" style="width:100%" /></template></el-table-column>
          <el-table-column label="单位" width="70"><template slot-scope="s"><el-input v-model="s.row.unit" size="mini" placeholder="mm" /></template></el-table-column>
          <el-table-column label="必检" width="60" align="center"><template slot-scope="s"><el-switch v-model="s.row.is_required" :active-value="1" :inactive-value="0" size="mini" /></template></el-table-column>
          <el-table-column label="操作" width="60" align="center"><template slot-scope="s"><el-button type="text" size="mini" class="danger-text" @click="dialog.items.splice(s.$index, 1)">删除</el-button></template></el-table-column>
        </el-table>
        <el-button size="mini" icon="el-icon-plus" style="margin-top:8px" @click="dialog.items.push({ item_name: '', item_type: 1, standard_value: '', upper_limit: null, lower_limit: null, unit: '', is_required: 1, sort: dialog.items.length + 1 })">添加项目</el-button>
        <el-form-item label="状态" style="margin-top:12px">
          <el-switch v-model="dialog.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
        </el-form-item>
        <el-form-item label="备注"><el-input v-model="dialog.remark" type="textarea" :rows="2" placeholder="备注（可选）" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="dialogVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </el-dialog>

    <!-- 检验项目查看对话框 -->
    <el-dialog title="检验项目" :visible.sync="itemsVisible" width="700px" append-to-body>
      <el-table :data="itemsView" size="mini" border>
        <el-table-column type="index" label="#" width="45" align="center" />
        <el-table-column prop="item_name" label="项目名称" min-width="120" />
        <el-table-column prop="item_type_label" label="类型" width="70" align="center" />
        <el-table-column prop="standard_value" label="标准值" width="130" />
        <el-table-column label="上限/下限" width="130" align="center"><template slot-scope="s">{{ s.row.upper_limit ?? '-' }} / {{ s.row.lower_limit ?? '-' }} {{ s.row.unit || '' }}</template></el-table-column>
        <el-table-column label="必检" width="60" align="center"><template slot-scope="s">{{ s.row.is_required === 1 ? '是' : '否' }}</template></el-table-column>
      </el-table>
    </el-dialog>
  </div>
</template>

<script>
import { getQualityStandardList, saveQualityStandard, deleteQualityStandard, toggleQualityStandard } from '@/api/production'

export default {
  name: 'QualityStandard',
  data () {
    return {
      productTypes: ['油缸', '立柱', '减速器', '液压支架', '通用'],
      inspectionOptions: { 1: '外观检验', 2: '尺寸检验', 3: '性能测试', 4: '材质检验' },
      itemTypeOptions: { 1: '文本', 2: '数值', 3: '布尔' },
      query: { standard_name: '', standard_code: '', product_type: '', inspection_type: '', status: '' },
      list: [], total: 0, page: 1, pageSize: 10, loading: false, saving: false,
      dialogVisible: false, dialog: this.emptyDialog(), stdRules: {
        standard_code: [{ required: true, message: '请填写标准编码' }],
        standard_name: [{ required: true, message: '请填写标准名称' }],
        product_type: [{ required: true, message: '请选择适用产品类型' }],
        inspection_type: [{ required: true, message: '请选择检验类型' }]
      },
      itemsVisible: false, itemsView: []
    }
  },
  created () { this.loadData() },
  methods: {
    emptyDialog () {
      return { id: 0, standard_code: '', standard_name: '', product_type: '', inspection_type: 1, status: 1, remark: '', items: [] }
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.standard_name) p.standard_name = this.query.standard_name
      if (this.query.standard_code) p.standard_code = this.query.standard_code
      if (this.query.product_type !== '' && this.query.product_type !== null) p.product_type = this.query.product_type
      if (this.query.inspection_type !== '' && this.query.inspection_type !== null) p.inspection_type = this.query.inspection_type
      if (this.query.status !== '' && this.query.status !== null) p.status = this.query.status
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getQualityStandardList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () { this.query = { standard_name: '', standard_code: '', product_type: '', inspection_type: '', status: '' }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    openDialog (row) {
      if (row) {
        this.dialog = {
          id: row.id, standard_code: row.standard_code, standard_name: row.standard_name, product_type: row.product_type,
          inspection_type: row.inspection_type, status: row.status, remark: row.remark || '',
          items: (row.items || []).map(it => ({ ...it }))
        }
      } else this.dialog = this.emptyDialog()
      this.dialogVisible = true
    },
    async handleSave () {
      if (!this.dialog.standard_code) { this.$message.warning('请填写标准编码'); return }
      if (!this.dialog.standard_name) { this.$message.warning('请填写标准名称'); return }
      if (!this.dialog.product_type) { this.$message.warning('请选择适用产品类型'); return }
      if (!this.dialog.items.length || this.dialog.items.every(i => !i.item_name)) { this.$message.warning('请至少添加一个检验项目'); return }
      this.saving = true
      try {
        const data = { ...this.dialog }
        if (data.id) delete data.item_count
        const r = await saveQualityStandard(data)
        if (r.code === 0) { this.$message.success('保存成功'); this.dialogVisible = false; this.loadData() } else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.saving = false }
    },
    handleDelete (row) {
      this.$confirm('确认删除该质检标准吗？', '删除质检标准', { type: 'warning' }).then(async () => {
        try { const r = await deleteQualityStandard(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadData() } else this.$message.error(r.msg) } catch (e) {}
      }).catch(() => {})
    },
    async handleToggle (row) {
      try { const r = await toggleQualityStandard(row.id); if (r.code === 0) { this.$message.success(r.msg); this.loadData() } else this.$message.error(r.msg) } catch (e) {}
    },
    openItems (row) {
      this.itemsView = (row.items || []).map(it => ({ ...it, item_type_label: this.itemTypeOptions[it.item_type] || '' }))
      this.itemsVisible = true
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.sub-title { font-size: 14px; font-weight: 600; margin: 4px 0 10px; color: #303133; }
.danger-text { color: #F56C6C; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
</style>
