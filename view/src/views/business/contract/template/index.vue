<!--
  文件：admin/src/views/business/contract/template/index.vue
  功能：经营管理 → 订单中心 → 合同管理 → 合同模板管理
    - 筛选（关键词/合同类型/状态）+ 工具栏（新增/导入/刷新）
    - 表格（模板编号/名称/类型/适用类型/默认/状态/创建时间/操作）
    - 弹窗：新增编辑/预览/导入
-->
<template>
  <div class="template-page">
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="关键词">
          <el-input v-model="filter.keyword" placeholder="模板名称/编号" clearable style="width:180px" @keyup.enter.native="search" />
        </el-form-item>
        <el-form-item label="合同类型">
          <el-select v-model="filter.contract_type" placeholder="全部" clearable style="width:130px">
            <el-option v-for="opt in typeOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="filter.status" placeholder="全部" clearable style="width:100px">
            <el-option label="启用" value="1" />
            <el-option label="停用" value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="search">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="reset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <div class="toolbar">
      <el-button v-if="hasPerm('business:contract:template:add')" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增模板</el-button>
      <el-button v-if="hasPerm('business:contract:template:add')" size="small" icon="el-icon-upload2" @click="importVisible = true">导入模板</el-button>
      <span class="flex-1"></span>
      <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
    </div>

    <el-table :data="list" v-loading="loading" size="small" stripe border>
      <el-table-column prop="template_code" label="模板编号" width="165" />
      <el-table-column prop="template_name" label="模板名称" min-width="170" show-overflow-tooltip />
      <el-table-column label="模板类型" width="100" align="center">
        <template slot-scope="s"><el-tag size="mini" :type="s.row.template_type === 'standard' ? 'primary' : 'success'">{{ s.row.template_type_text }}</el-tag></template>
      </el-table-column>
      <el-table-column label="适用合同类型" width="110" align="center">
        <template slot-scope="s"><el-tag size="mini" :type="typeTag(s.row.contract_type)">{{ s.row.contract_type_text }}</el-tag></template>
      </el-table-column>
      <el-table-column label="默认" width="80" align="center">
        <template slot-scope="s">
          <el-tag v-if="s.row.is_default" size="mini" type="danger">默认</el-tag>
          <span v-else style="color:#c0c4cc">-</span>
        </template>
      </el-table-column>
      <el-table-column label="状态" width="80" align="center">
        <template slot-scope="s">
          <el-tag size="mini" :type="s.row.status ? 'success' : 'info'">{{ s.row.status ? '启用' : '停用' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="create_time" label="创建时间" width="165" />
      <el-table-column label="操作" width="280" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="openPreview(s.row.id)">查看</el-button>
          <el-button v-if="hasPerm('business:contract:template:edit')" type="text" size="mini" @click="openForm(s.row)">编辑</el-button>
          <el-button v-if="hasPerm('business:contract:template:add')" type="text" size="mini" @click="handleCopy(s.row)">复制</el-button>
          <el-button v-if="hasPerm('business:contract:template:edit') && !s.row.is_default" type="text" size="mini" @click="handleSetDefault(s.row)">设默认</el-button>
          <el-button v-if="hasPerm('business:contract:template:edit')" type="text" size="mini" @click="handleToggleStatus(s.row)">{{ s.row.status ? '停用' : '启用' }}</el-button>
          <el-button v-if="hasPerm('business:contract:template:delete')" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>
    <el-pagination class="pager" small background layout="total, prev, pager, next" :total="total" :page-size="pageSize" :current-page="page" @current-change="p => { page = p; loadList() }" />

    <!-- 弹窗 -->
    <TemplateFormDialog :visible="formVisible" :row="currentRow" @update:visible="v => (formVisible = v)" @success="onFormSuccess" />
    <TemplatePreviewDialog :visible="previewVisible" :template-id="previewId" @update:visible="v => (previewVisible = v)" />
    <TemplateImportDialog :visible="importVisible" @update:visible="v => (importVisible = v)" @imported="onImported" />
  </div>
</template>

<script>
import TemplateFormDialog from './components/TemplateFormDialog.vue'
import TemplatePreviewDialog from './components/TemplatePreviewDialog.vue'
import TemplateImportDialog from './components/TemplateImportDialog.vue'
import { getTemplateList, deleteTemplate, setDefaultTemplate, toggleTemplateStatus, copyTemplate } from '../../../../api/contractTemplate'
import { getDictByCode } from '../../../../api/dictionary'

export default {
  name: 'BusinessContractTemplate',
  components: { TemplateFormDialog, TemplatePreviewDialog, TemplateImportDialog },
  data() {
    return {
      loading: false, list: [], total: 0, page: 1, pageSize: 20,
      filter: { keyword: '', contract_type: '', status: '' },
      typeOptions: [],
      formVisible: false, currentRow: null,
      previewVisible: false, previewId: 0,
      importVisible: false
    }
  },
  created() { this.loadList(); this.loadTypes() },
  methods: {
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    typeTag(t) { return { sales: 'primary', purchase: 'success', repair_service: 'warning' }[t] || 'info' },
    async loadTypes() {
      try { const r = await getDictByCode('contract_type'); this.typeOptions = r.data || [] } catch (e) { this.typeOptions = [] }
    },
    search() { this.page = 1; this.loadList() },
    reset() { this.filter = { keyword: '', contract_type: '', status: '' }; this.page = 1; this.loadList() },
    async loadList() {
      this.loading = true
      try {
        const r = await getTemplateList({ ...this.filter, page: this.page, limit: this.pageSize })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    openForm(row) { this.currentRow = row || null; this.formVisible = true },
    onFormSuccess() { this.formVisible = false; this.loadList() },
    openPreview(id) { this.previewId = id; this.previewVisible = true },
    handleCopy(row) {
      this.$confirm(`复制模板「${row.template_name}」生成新模板？`, '复制模板', { type: 'warning' }).then(async () => {
        try { const r = await copyTemplate(row.id); if (r.code === 0) { this.$message.success(r.msg); this.loadList() } } catch (e) {}
      }).catch(() => {})
    },
    handleSetDefault(row) {
      this.$confirm(`将「${row.template_name}」设为该合同类型的默认模板？`, '设置默认', { type: 'warning' }).then(async () => {
        try { const r = await setDefaultTemplate(row.id); if (r.code === 0) { this.$message.success(r.msg); this.loadList() } } catch (e) {}
      }).catch(() => {})
    },
    handleToggleStatus(row) {
      const action = row.status ? '停用' : '启用'
      this.$confirm(`确认${action}模板「${row.template_name}」？`, action + '模板', { type: 'warning' }).then(async () => {
        try { const r = await toggleTemplateStatus(row.id); if (r.code === 0) { this.$message.success(r.msg); this.loadList() } } catch (e) {}
      }).catch(() => {})
    },
    handleDelete(row) {
      this.$confirm(`确定删除模板「${row.template_name}」？已被合同引用的模板不可删除。`, '删除确认', { type: 'warning' }).then(async () => {
        try { const r = await deleteTemplate(row.id); if (r.code === 0) { this.$message.success('模板已删除'); this.loadList() } } catch (e) {}
      }).catch(() => {})
    },
    onImported(content) {
      this.importVisible = false
      this.currentRow = null
      this.formVisible = true
      this.$nextTick(() => {
        const dlg = this.$children.find(c => c.$options.name === 'TemplateFormDialog')
        if (dlg) dlg.fillImported(content)
      })
    }
  }
}
</script>

<style scoped>
.template-page { padding: 4px 16px; }
.filter-card { margin-bottom: 12px; }
.toolbar { display: flex; align-items: center; margin: 12px 0; }
.flex-1 { flex: 1; }
.pager { margin-top: 12px; text-align: right; }
.danger { color: #f56c6c; }
</style>
