<template>
  <div class="tpl-page">
    <!-- 筛选区域 -->
    <el-card shadow="never" class="filter-card">
      <el-form :inline="true" size="small" @submit.native.prevent>
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入模板名称" clearable style="width:200px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.template_type" clearable placeholder="全部类型" style="width:130px" @change="onSearch">
            <el-option v-for="(t, k) in TYPE_MAP" :key="k" :label="t.label" :value="Number(k)" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width:110px" @change="onSearch">
            <el-option label="启用" value="1" />
            <el-option label="停用" value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilter">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 工具栏 -->
    <el-card shadow="never" class="list-card">
      <div class="toolbar">
        <span class="toolbar-left">共 <b>{{ total }}</b> 条模板</span>
        <div class="toolbar-right">
          <el-button v-if="hasPerm('notification:template:add')" size="small" type="primary" icon="el-icon-plus" @click="openForm()">新增模板</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </div>
      </div>

      <!-- 表格 -->
      <el-table :data="list" v-loading="loading" size="small" stripe>
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column prop="template_code" label="模板编号" width="160" />
        <el-table-column prop="template_name" label="模板名称" min-width="140" show-overflow-tooltip>
          <template slot-scope="{ row }">
            <el-button type="text" size="mini" @click="openForm(row)">{{ row.template_name }}</el-button>
          </template>
        </el-table-column>
        <el-table-column label="模板类型" width="100" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :style="tagStyle(typeOf(row.template_type))">{{ typeOf(row.template_type).label }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="purpose" label="模板用途" min-width="140" show-overflow-tooltip>
          <template slot-scope="{ row }">{{ row.purpose || '-' }}</template>
        </el-table-column>
        <el-table-column prop="variable_count" label="变量数量" width="80" align="center" />
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.status === 1 ? 'success' : 'info'">{{ row.status === 1 ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" align="center">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('notification:template:edit')" type="text" size="mini" @click="openForm(row)">编辑</el-button>
            <el-button v-if="hasPerm('notification:template:query')" type="text" size="mini" @click="openPreview(row)">预览</el-button>
            <el-button v-if="hasPerm('notification:template:delete')" type="text" size="mini" style="color:#F56C6C" @click="removeOne(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination class="pager" background layout="total, sizes, prev, pager, next" :total="total"
        :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50]"
        @size-change="s => { limit = s; page = 1; loadList() }"
        @current-change="p => { page = p; loadList() }" />
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <template-form-dialog v-if="formVisible" :visible.sync="formVisible" :form-id="formId" @saved="onSaved" />

    <!-- 预览弹窗 -->
    <template-preview-dialog v-if="previewVisible" :visible.sync="previewVisible" :template-id="previewId" :template-name="previewName" :variables="previewVars" />
  </div>
</template>

<script>
import { getTemplateList, deleteTemplate } from '@/api/notificationTemplate'
import TemplateFormDialog from './components/TemplateFormDialog.vue'
import TemplatePreviewDialog from './components/TemplatePreviewDialog.vue'

// 模板类型：1系统公告 2任务指派 3审批通知 4预警提醒 5培训通知 6工单通知
const TYPE_MAP = {
  1: { label: '系统公告', color: '#909399' },
  2: { label: '任务指派', color: '#409EFF' },
  3: { label: '审批通知', color: '#E6A23C' },
  4: { label: '预警提醒', color: '#F56C6C' },
  5: { label: '培训通知', color: '#67C23A' },
  6: { label: '工单通知', color: '#8E44AD' }
}

export default {
  name: 'NotificationTemplates',
  components: { TemplateFormDialog, TemplatePreviewDialog },
  data () {
    return {
      TYPE_MAP,
      list: [],
      total: 0,
      page: 1,
      limit: 10,
      loading: false,
      filters: { keyword: '', template_type: '', status: '' },
      formVisible: false,
      formId: 0,
      previewVisible: false,
      previewId: 0,
      previewName: '',
      previewVars: []
    }
  },
  created () {
    this.loadList()
  },
  methods: {
    hasPerm (code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    typeOf (type) { return TYPE_MAP[type] || { label: '未知', color: '#909399' } },
    tagStyle (t) { return { color: t.color, borderColor: t.color, background: t.color + '1a' } },
    async loadList () {
      this.loading = true
      try {
        const params = { page: this.page, limit: this.limit }
        if (this.filters.keyword) params.keyword = this.filters.keyword
        if (this.filters.template_type) params.template_type = this.filters.template_type
        if (this.filters.status !== '' && this.filters.status !== null) params.status = this.filters.status
        const r = await getTemplateList(params)
        if (r.code === 0) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
        }
      } catch (e) {} finally { this.loading = false }
    },
    onSearch () { this.page = 1; this.loadList() },
    resetFilter () { this.filters = { keyword: '', template_type: '', status: '' }; this.page = 1; this.loadList() },
    openForm (row) { this.formId = row ? row.id : 0; this.formVisible = true },
    onSaved () { this.formVisible = false; this.loadList() },
    openPreview (row) {
      this.previewId = row.id
      this.previewName = row.template_name
      this.previewVars = row.variables || []
      this.previewVisible = true
    },
    removeOne (row) {
      this.$confirm(`确定删除模板「${row.template_name}」？`, '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteTemplate(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.loadList() }
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.tpl-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.filter-card { margin-bottom: 16px; }
.list-card .toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.toolbar-left { font-size: 13px; color: #606266; }
.pager { margin-top: 14px; text-align: right; }
</style>
