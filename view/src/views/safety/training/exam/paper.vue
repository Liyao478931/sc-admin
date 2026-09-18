<template>
  <div class="exam-paper-page">
    <!-- 筛选 + 工具栏 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <el-form :inline="true" size="small" @submit.native.prevent>
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入试卷名称" clearable style="width:200px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.training_type_id" clearable placeholder="全部类型" style="width:140px" @change="onSearch">
            <el-option v-for="t in typeOptions" :key="t.id" :label="t.name" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width:120px" @change="onSearch">
            <el-option label="草稿" value="draft" />
            <el-option label="已发布" value="published" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilters">重置</el-button>
        </el-form-item>
        <el-form-item style="float:right">
          <span style="margin-right:12px;font-size:13px;color:#909399;">共 {{ total }} 条试卷</span>
          <el-button v-if="hasPerm('safety:training:exam:add')" type="primary" icon="el-icon-plus" @click="openAdd">新增试卷</el-button>
          <el-button icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 表格 -->
    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column prop="paper_code" label="试卷编号" width="160" show-overflow-tooltip />
        <el-table-column label="试卷名称" min-width="160">
          <template slot-scope="{ row }">
            <el-link type="primary" :underline="false" @click="openPreview(row)">{{ row.paper_name }}</el-link>
          </template>
        </el-table-column>
        <el-table-column prop="type_name" label="关联培训类型" width="120" align="center">
          <template slot-scope="{ row }">{{ row.type_name || '-' }}</template>
        </el-table-column>
        <el-table-column prop="total_questions" label="题目数量" width="100" align="center" />
        <el-table-column prop="total_score" label="总分" width="80" align="center" />
        <el-table-column prop="pass_score" label="及格分数" width="80" align="center" />
        <el-table-column label="考试时长" width="100" align="center">
          <template slot-scope="{ row }">{{ row.duration_minutes }} 分钟</template>
        </el-table-column>
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.status === 'published' ? 'success' : 'info'">{{ row.status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="220" align="center" fixed="right">
          <template slot-scope="{ row }">
            <template v-if="row.status === 'draft'">
              <el-button v-if="hasPerm('safety:training:exam:edit')" size="mini" type="text" @click="openEdit(row)">编辑</el-button>
              <el-button v-if="hasPerm('safety:training:exam:edit')" size="mini" type="text" style="color:#67C23A" @click="doPublish(row)">发布</el-button>
              <el-button v-if="hasPerm('safety:training:exam:delete')" size="mini" type="text" style="color:#F56C6C" @click="doDelete(row)">删除</el-button>
            </template>
            <el-button v-if="hasPerm('safety:training:exam:add')" size="mini" type="text" @click="doCopy(row)">复制</el-button>
            <el-button v-if="hasPerm('safety:training:exam:query')" size="mini" type="text" @click="openPreview(row)">预览</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination style="margin-top:12px;text-align:right" background layout="total, sizes, prev, pager, next"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10, 20, 50]" @current-change="loadList" @size-change="loadList" />
    </el-card>

    <paper-form-dialog :visible.sync="formVisible" :row="currentRow" :type-options="typeOptions" @saved="onSaved" />
    <paper-preview-dialog :visible.sync="previewVisible" :row="previewRow" />
  </div>
</template>

<script>
import { getPaperList, deletePaper, publishPaper, copyPaper, getCategoryOptions } from '@/api/trainingExam'
import PaperFormDialog from './components/PaperFormDialog.vue'
import PaperPreviewDialog from './components/PaperPreviewDialog.vue'

export default {
  name: 'ExamPaper',
  components: { PaperFormDialog, PaperPreviewDialog },
  data() {
    return {
      loading: false, list: [], total: 0, page: 1, limit: 10,
      filters: { keyword: '', training_type_id: null, status: '' },
      typeOptions: [], formVisible: false, previewVisible: false, currentRow: null, previewRow: null,
    }
  },
  created() {
    if (this.$store.state.user && this.$store.state.user.permissions && !this.$store.state.user.permissions.length) {
      this.$store.dispatch('user/loadPermissions')
    }
    this.loadTypes(); this.loadList()
  },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    async loadTypes() {
      try { const r = await getCategoryOptions(); this.typeOptions = r.data || [] } catch (e) {}
    },
    async loadList() {
      this.loading = true
      try {
        const r = await getPaperList({
          page: this.page, limit: this.limit,
          keyword: this.filters.keyword || '',
          training_type_id: this.filters.training_type_id || '',
          status: this.filters.status || '',
        })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    onSearch() { this.page = 1; this.loadList() },
    resetFilters() { this.filters = { keyword: '', training_type_id: null, status: '' }; this.page = 1; this.loadList() },
    onSaved() { this.loadList() },
    openAdd() { this.currentRow = null; this.formVisible = true },
    openEdit(row) { this.currentRow = row; this.formVisible = true },
    openPreview(row) { this.previewRow = row; this.previewVisible = true },
    doPublish(row) {
      this.$confirm(`确认发布试卷「${row.paper_name}」？发布后不可修改。`, '发布确认', { type: 'warning' }).then(async () => {
        try { const r = await publishPaper(row.id); if (r.code === 0) { this.$message.success('发布成功'); this.loadList() } } catch (e) {}
      }).catch(() => {})
    },
    doDelete(row) {
      this.$confirm(`确认删除试卷「${row.paper_name}」？`, '删除确认', { type: 'warning' }).then(async () => {
        try { const r = await deletePaper(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadList() } } catch (e) {}
      }).catch(() => {})
    },
    async doCopy(row) {
      try {
        const r = await copyPaper(row.id)
        if (r.code === 0) { this.$message.success('复制成功，已生成草稿副本'); this.loadList() }
      } catch (e) {}
    },
  },
}
</script>
