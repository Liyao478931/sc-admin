<template>
  <div class="exam-question-page">
    <!-- 统计卡片 -->
    <el-row :gutter="12" style="margin-bottom:16px;">
      <el-col :span="4" v-for="card in statCards" :key="card.label">
        <el-card shadow="never" :body-style="{ padding: '14px 16px' }">
          <div class="stat-card">
            <div class="stat-icon" :style="{ background: card.bg, color: card.color }">
              <i :class="card.icon" />
            </div>
            <div class="stat-info">
              <div class="stat-num">{{ card.value }}</div>
              <div class="stat-label">{{ card.label }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 筛选 + 工具栏 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <el-form :inline="true" size="small" @submit.native.prevent>
        <el-form-item>
          <el-select v-model="filters.question_type" clearable placeholder="全部题型" style="width:120px" @change="onSearch">
            <el-option v-for="t in typeOptions" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.difficulty" clearable placeholder="全部难度" style="width:120px" @change="onSearch">
            <el-option v-for="d in diffOptions" :key="d.value" :label="d.label" :value="d.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.category_id" clearable placeholder="全部分类" style="width:140px" @change="onSearch">
            <el-option v-for="c in categoryOptions" :key="c.id" :label="c.name" :value="c.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width:120px" @change="onSearch">
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入题目关键词" clearable style="width:200px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilters">重置</el-button>
        </el-form-item>
        <el-form-item style="float:right">
          <span style="margin-right:12px;font-size:13px;color:#909399;">共 {{ total }} 条题目</span>
          <el-button v-if="hasPerm('safety:training:exam:add')" type="primary" icon="el-icon-plus" @click="openAdd">新增题目</el-button>
          <el-button v-if="hasPerm('safety:training:exam:add')" icon="el-icon-upload2" @click="importVisible = true">导入题目</el-button>
          <el-button v-if="hasPerm('safety:training:exam:list')" icon="el-icon-download" @click="downloadTemplate">下载模板</el-button>
          <el-button v-if="hasPerm('safety:training:exam:export')" icon="el-icon-upload2" :loading="exporting" @click="doExport">导出题目</el-button>
          <el-button icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 表格 -->
    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" border stripe size="small" @selection-change="onSelectionChange">
        <el-table-column type="selection" width="40" align="center" />
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column prop="question_code" label="题目编号" width="150" show-overflow-tooltip />
        <el-table-column label="题型" width="90" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="typeTag(row.question_type)">{{ row.type_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="question_text" label="题目内容" min-width="200" show-overflow-tooltip />
        <el-table-column label="难度" width="80" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="diffTag(row.difficulty)">{{ row.difficulty_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="category_name" label="分类" width="100" align="center">
          <template slot-scope="{ row }">{{ row.category_name || '-' }}</template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.status === 1 ? 'success' : 'info'">{{ row.status === 1 ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="create_time" label="创建时间" width="160" align="center" />
        <el-table-column label="操作" width="200" align="center" fixed="right">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('safety:training:exam:edit')" size="mini" type="text" @click="openEdit(row)">编辑</el-button>
            <el-button v-if="hasPerm('safety:training:exam:delete')" size="mini" type="text" style="color:#F56C6C" @click="doDelete(row)">删除</el-button>
            <el-button v-if="hasPerm('safety:training:exam:edit')" size="mini" type="text" @click="toggleStatus(row)">
              {{ row.status === 1 ? '停用' : '启用' }}
            </el-button>
          </template>
        </el-table-column>
      </el-table>
      <div style="margin-top:12px;display:flex;justify-content:space-between;align-items:center;">
        <el-button v-if="hasPerm('safety:training:exam:delete')" size="small" type="danger" plain icon="el-icon-delete"
          :disabled="!selectedIds.length" @click="doBatchDelete">批量删除（{{ selectedIds.length }}）</el-button>
        <el-pagination style="text-align:right" background layout="total, sizes, prev, pager, next"
          :total="total" :current-page.sync="page" :page-size.sync="limit"
          :page-sizes="[10, 20, 50]" @current-change="loadList" @size-change="loadList" />
      </div>
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <question-form-dialog :visible.sync="formVisible" :row="currentRow" :type-options="typeOptions"
      :diff-options="diffOptions" :category-options="categoryOptions" @saved="onSaved" />

    <!-- 导入弹窗 -->
    <question-import-dialog :visible.sync="importVisible" @imported="onSaved" />
  </div>
</template>

<script>
import { getQuestionList, getQuestionStatistics, deleteQuestion, batchDeleteQuestions,
  changeQuestionStatus, exportQuestions, getQuestionTemplate, getCategoryOptions } from '@/api/trainingExam'
import { getDictByCode } from '@/api/dictionary'
import QuestionFormDialog from './components/QuestionFormDialog.vue'
import QuestionImportDialog from './components/QuestionImportDialog.vue'

export default {
  name: 'ExamQuestion',
  components: { QuestionFormDialog, QuestionImportDialog },
  data() {
    return {
      loading: false, exporting: false, list: [], total: 0, page: 1, limit: 10, selectedIds: [],
      filters: { keyword: '', question_type: '', difficulty: '', category_id: null, status: '' },
      typeOptions: [], diffOptions: [], categoryOptions: [],
      statCards: [
        { label: '总题目数', value: 0, icon: 'el-icon-document', color: '#409EFF', bg: 'rgba(64,158,255,.12)' },
        { label: '单选题数', value: 0, icon: 'el-icon-edit', color: '#409EFF', bg: 'rgba(64,158,255,.12)' },
        { label: '多选题数', value: 0, icon: 'el-icon-edit-outline', color: '#67C23A', bg: 'rgba(103,194,58,.12)' },
        { label: '判断题数', value: 0, icon: 'el-icon-question', color: '#E6A23C', bg: 'rgba(230,162,60,.12)' },
        { label: '启用题目数', value: 0, icon: 'el-icon-check', color: '#67C23A', bg: 'rgba(103,194,58,.12)' },
        { label: '停用题目数', value: 0, icon: 'el-icon-close', color: '#909399', bg: 'rgba(144,147,153,.12)' },
      ],
      formVisible: false, importVisible: false, currentRow: null,
    }
  },
  created() {
    if (this.$store.state.user && this.$store.state.user.permissions && !this.$store.state.user.permissions.length) {
      this.$store.dispatch('user/loadPermissions')
    }
    this.loadDict()
    this.loadCategories()
    this.loadList()
    this.loadStatistics()
  },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    async loadDict() {
      try {
        const [t, d] = await Promise.all([getDictByCode('exam_question_type'), getDictByCode('exam_difficulty')])
        this.typeOptions = (t.data || []).map(x => ({ label: x.label, value: x.value }))
        this.diffOptions = (d.data || []).map(x => ({ label: x.label, value: x.value }))
      } catch (e) {
        // 字典缺失时兜底
        this.typeOptions = [
          { label: '单选题', value: 'single' }, { label: '多选题', value: 'multiple' }, { label: '判断题', value: 'judge' }
        ]
        this.diffOptions = [
          { label: '简单', value: 'easy' }, { label: '中等', value: 'normal' }, { label: '困难', value: 'hard' }
        ]
      }
    },
    async loadCategories() {
      try { const r = await getCategoryOptions(); this.categoryOptions = r.data || [] } catch (e) {}
    },
    async loadList() {
      this.loading = true
      try {
        const r = await getQuestionList({
          page: this.page, limit: this.limit,
          keyword: this.filters.keyword || '',
          question_type: this.filters.question_type || '',
          difficulty: this.filters.difficulty || '',
          category_id: this.filters.category_id || '',
          status: this.filters.status === '' ? '' : this.filters.status,
        })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    async loadStatistics() {
      try {
        const r = await getQuestionStatistics()
        if (r.code === 0 && r.data) {
          const d = r.data
          this.statCards[0].value = d.total || 0
          this.statCards[1].value = (d.type_count || {}).single || 0
          this.statCards[2].value = (d.type_count || {}).multiple || 0
          this.statCards[3].value = (d.type_count || {}).judge || 0
          this.statCards[4].value = (d.status_count || {}).enabled || 0
          this.statCards[5].value = (d.status_count || {}).disabled || 0
        }
      } catch (e) {}
    },
    onSearch() { this.page = 1; this.loadList() },
    resetFilters() {
      this.filters = { keyword: '', question_type: '', difficulty: '', category_id: null, status: '' }
      this.page = 1; this.loadList()
    },
    typeTag(v) { return { single: '', multiple: 'success', judge: 'warning' }[v] || 'info' },
    diffTag(v) { return { easy: 'success', normal: 'warning', hard: 'danger' }[v] || 'info' },
    onSelectionChange(rows) { this.selectedIds = rows.map(r => r.id) },
    openAdd() { this.currentRow = null; this.formVisible = true },
    openEdit(row) { this.currentRow = row; this.formVisible = true },
    onSaved() { this.loadList(); this.loadStatistics() },
    doDelete(row) {
      this.$confirm('确认删除该题目？删除后不可恢复。', '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteQuestion(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.selectedIds = []; this.loadList(); this.loadStatistics() }
        } catch (e) {}
      }).catch(() => {})
    },
    doBatchDelete() {
      if (!this.selectedIds.length) return
      this.$confirm(`确认删除选中的 ${this.selectedIds.length} 条题目？`, '批量删除', { type: 'warning' }).then(async () => {
        try {
          const r = await batchDeleteQuestions(this.selectedIds)
          if (r.code === 0) {
            if (r.data.failed && r.data.failed.length) {
              this.$message.warning(`成功${r.data.success.length}条，失败${r.data.failed.length}条（含被试卷引用的题目）`)
            } else {
              this.$message.success('删除成功')
            }
            this.selectedIds = []
            this.loadList(); this.loadStatistics()
          }
        } catch (e) {}
      }).catch(() => {})
    },
    async toggleStatus(row) {
      try {
        const r = await changeQuestionStatus(row.id, row.status === 1 ? 0 : 1)
        if (r.code === 0) { this.$message.success('操作成功'); this.loadList() }
      } catch (e) {}
    },
    async downloadTemplate() {
      try {
        const r = await getQuestionTemplate()
        if (r.code === 0 && r.data.url) { window.open(r.data.url, '_blank') }
      } catch (e) {}
    },
    doExport() {
      this.$confirm('确认导出当前筛选条件下的全部题目？', '导出确认', { type: 'info' }).then(async () => {
        this.exporting = true
        try {
          const r = await exportQuestions({
            keyword: this.filters.keyword || '',
            question_type: this.filters.question_type || '',
            difficulty: this.filters.difficulty || '',
            category_id: this.filters.category_id || '',
            status: this.filters.status === '' ? '' : this.filters.status,
          })
          if (r.code === 0 && r.data.url) { window.open(r.data.url, '_blank'); this.$message.success('导出成功') }
        } catch (e) {}
        this.exporting = false
      }).catch(() => {})
    },
  },
}
</script>

<style scoped>
.stat-card { display: flex; align-items: center; }
.stat-icon { width: 46px; height: 46px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 24px; margin-right: 12px; }
.stat-num { font-size: 22px; font-weight: 600; line-height: 1.2; }
.stat-label { font-size: 13px; color: #909399; }
</style>
