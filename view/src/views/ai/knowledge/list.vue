<!-- 文件：admin/src/views/ai/knowledge/list.vue -->
<template>
  <div class="page">
    <!-- 统计卡片（4个） -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="6" v-for="card in statCards" :key="card.key">
        <div class="stat-card" :class="card.cls" @click="card.onClick && card.onClick()">
          <i :class="card.icon" class="stat-icon"></i>
          <div class="stat-info">
            <div class="stat-num">{{ card.value }}</div>
            <div class="stat-label">{{ card.label }}</div>
          </div>
        </div>
      </el-col>
    </el-row>

    <el-card shadow="never" class="sec-card">
      <!-- 筛选区域 -->
      <el-form inline size="small" class="filter-form">
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入知识库名称" clearable style="width:200px"
            @keyup.enter.native="handleSearch" @clear="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" placeholder="全部状态" clearable style="width:130px" @change="handleSearch">
            <el-option label="未处理" value="pending" />
            <el-option label="处理中" value="processing" />
            <el-option label="已完成" value="completed" />
            <el-option label="失败" value="failed" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始日期"
            end-placeholder="结束日期" value-format="yyyy-MM-dd" style="width:240px" @change="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>

      <!-- 工具栏 -->
      <div class="toolbar">
        <span class="toolbar-tip">共 {{ total }} 个知识库</span>
        <div class="toolbar-right">
          <el-button size="small" type="primary" icon="el-icon-plus" @click="openCreate">新增知识库</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadAll">刷新</el-button>
        </div>
      </div>

      <!-- 知识库卡片 -->
      <el-row :gutter="16" v-loading="loading" class="card-row">
        <el-col :span="8" v-for="kb in list" :key="kb.id" class="kb-col">
          <el-card shadow="hover" class="kb-card">
            <div slot="header" class="kb-head">
              <span class="kb-name" :title="kb.kb_name" @click="openDetail(kb)">{{ kb.kb_name }}</span>
              <el-tag size="mini" :type="statusTagType(kb.status)">{{ statusText(kb.status) }}</el-tag>
            </div>
            <div class="kb-desc">{{ kb.description || '暂无描述' }}</div>
            <div class="kb-meta">
              <div><i class="el-icon-document"></i> {{ kb.doc_count }} 个文档</div>
              <div><i class="el-icon-data-line"></i> {{ formatSize(kb.total_size) }}</div>
            </div>
            <div class="kb-meta">
              <div><i class="el-icon-user"></i> {{ kb.created_by_name || '-' }}</div>
              <div><i class="el-icon-time"></i> {{ kb.create_time }}</div>
            </div>
            <!-- 向量化进度 -->
            <div class="kb-progress">
              <span class="kb-progress-label">{{ progressText(kb) }}</span>
              <el-progress :percentage="kb.progress || 0" :status="progressStatus(kb)" :stroke-width="6" />
              <div v-if="kb.status === 'failed' && kb.error_message" class="kb-error" @click="showError(kb)">
                <i class="el-icon-warning"></i> {{ truncate(kb.error_message, 30) }}
              </div>
            </div>
            <!-- 操作 -->
            <div class="kb-actions">
              <el-button size="mini" icon="el-icon-view" @click="openDetail(kb)">详情</el-button>
              <el-button size="mini" type="primary" icon="el-icon-upload2" @click="goUpload(kb)">上传</el-button>
              <el-button size="mini" type="success" icon="el-icon-search" @click="goRetrieve(kb)">检索</el-button>
              <el-button size="mini" icon="el-icon-edit" @click="openEdit(kb)">编辑</el-button>
              <el-button size="mini" type="danger" icon="el-icon-delete" @click="removeKb(kb)">删除</el-button>
            </div>
          </el-card>
        </el-col>
      </el-row>

      <!-- 分页 -->
      <div class="pager">
        <el-pagination background layout="total, sizes, prev, pager, next" :total="total"
          :page-size="limit" :page-sizes="[6, 12, 24]" :current-page="page"
          @size-change="p => { limit = p; page = 1; loadList() }"
          @current-change="p => { page = p; loadList() }" />
      </div>
    </el-card>

    <!-- 知识库详情弹窗 -->
    <el-dialog title="知识库详情" :visible.sync="detailVisible" width="850px" top="5vh">
      <div v-if="detail">
        <el-descriptions :column="2" size="small" border>
          <el-descriptions-item label="知识库名称">{{ detail.kb_name }}</el-descriptions-item>
          <el-descriptions-item label="向量化模型">{{ detail.embedding_model }}</el-descriptions-item>
          <el-descriptions-item label="描述" :span="2">{{ detail.description || '-' }}</el-descriptions-item>
          <el-descriptions-item label="切片大小">{{ detail.chunk_size }}</el-descriptions-item>
          <el-descriptions-item label="重叠大小">{{ detail.overlap }}</el-descriptions-item>
          <el-descriptions-item label="文档数量">{{ detail.doc_count }}</el-descriptions-item>
          <el-descriptions-item label="总大小">{{ formatSize(detail.total_size) }}</el-descriptions-item>
          <el-descriptions-item label="创建人">{{ detail.created_by_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ detail.create_time }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag size="mini" :type="statusTagType(detail.status)">{{ statusText(detail.status) }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="进度">{{ detail.progress || 0 }}%</el-descriptions-item>
          <el-descriptions-item label="知识库ID">{{ detail.kb_id }}
            <el-button size="mini" type="text" icon="el-icon-document-copy" @click="copyKbId(detail.kb_id)">复制</el-button>
          </el-descriptions-item>
          <el-descriptions-item v-if="detail.error_message" label="错误信息" :span="2">
            <span class="err-text">{{ detail.error_message }}</span>
          </el-descriptions-item>
        </el-descriptions>

        <!-- 文档列表 -->
        <div class="doc-title">文档列表（{{ docTotal }}）</div>
        <el-table :data="docList" size="small" stripe v-loading="docLoading">
          <el-table-column prop="doc_name" label="文档名称" min-width="200" show-overflow-tooltip />
          <el-table-column label="类型" width="80" align="center">
            <template slot-scope="s">
              <el-tag size="mini" type="info">{{ docTypeText(s.row.doc_type) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="大小" width="90" align="center">
            <template slot-scope="s">{{ formatSize(s.row.doc_size) }}</template>
          </el-table-column>
          <el-table-column prop="uploaded_by_name" label="上传人" width="90" align="center" />
          <el-table-column prop="upload_time" label="上传时间" width="160" />
          <el-table-column label="向量化状态" width="90" align="center">
            <template slot-scope="s">
              <el-tag size="mini" :type="statusTagType(s.row.status)">{{ statusText(s.row.status) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="90" align="center">
            <template slot-scope="s">
              <el-button size="mini" type="danger" @click="removeDoc(s.row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
        <div class="pager" style="margin-top:10px;">
          <el-pagination background layout="total, prev, pager, next" :total="docTotal"
            :page-size="docPageSize" :current-page="docPage" small
            @current-change="p => { docPage = p; loadDocs() }" />
        </div>
      </div>
    </el-dialog>

    <!-- 创建/编辑知识库弹窗 -->
    <el-dialog :title="form.id ? '编辑知识库' : '创建知识库'" :visible.sync="formVisible" width="550px" top="10vh">
      <el-form :model="form" :rules="formRules" ref="kbForm" label-width="90px" size="small">
        <el-form-item label="知识库名称" prop="kb_name">
          <el-input v-model="form.kb_name" placeholder="请输入知识库名称" maxlength="100" show-word-limit />
        </el-form-item>
        <el-form-item label="描述">
          <el-input v-model="form.description" type="textarea" :rows="2" placeholder="请输入知识库描述（选填）" maxlength="255" show-word-limit />
        </el-form-item>
        <el-form-item label="向量化模型">
          <el-select v-model="form.embedding_model" style="width:100%">
            <el-option label="text-embedding-v3" value="text-embedding-v3" />
            <el-option label="text-embedding-v2" value="text-embedding-v2" />
          </el-select>
        </el-form-item>
        <el-form-item label="切片大小">
          <el-input-number v-model="form.chunk_size" :min="100" :max="2000" :step="64" style="width:100%" />
        </el-form-item>
        <el-form-item label="重叠大小">
          <el-input-number v-model="form.overlap" :min="0" :max="500" :step="10" style="width:100%" />
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="formVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="submitting" @click="submitForm">确认</el-button>
      </span>
    </el-dialog>

    <!-- 错误详情弹窗 -->
    <el-dialog title="错误详情" :visible.sync="errorVisible" width="500px" top="15vh">
      <pre class="error-pre">{{ errorContent }}</pre>
    </el-dialog>
  </div>
</template>

<script>
import {
  getAiKnowledgeList, getAiKnowledgeDetail, addAiKnowledge, editAiKnowledge,
  deleteAiKnowledge, getAiKnowledgeStats, deleteAiKnowledgeDoc
} from '@/api/aiKnowledge'

export default {
  name: 'AiKnowledgeList',
  data () {
    return {
      stats: { kb_total: 0, kb_completed: 0, doc_total: 0, total_size_mb: 0 },
      filters: { keyword: '', status: '' },
      dateRange: [],
      list: [], total: 0, page: 1, limit: 12, loading: false,
      // 详情
      detailVisible: false, detail: null, docLoading: false,
      docList: [], docTotal: 0, docPage: 1, docPageSize: 10,
      // 创建/编辑
      formVisible: false, submitting: false,
      form: { id: null, kb_name: '', description: '', embedding_model: 'text-embedding-v3', chunk_size: 512, overlap: 50 },
      formRules: {
        kb_name: [
          { required: true, message: '请输入知识库名称', trigger: 'blur' },
          { min: 2, max: 100, message: '长度需为2-100字符', trigger: 'blur' }
        ]
      },
      // 错误
      errorVisible: false, errorContent: ''
    }
  },
  computed: {
    statCards () {
      const s = this.stats
      return [
        { key: 'total', label: '知识库总数', value: s.kb_total || 0, icon: 'el-icon-collection', cls: 'stat-blue' },
        { key: 'completed', label: '已完成数', value: s.kb_completed || 0, icon: 'el-icon-check', cls: 'stat-green', onClick: () => this.quickFilter('completed') },
        { key: 'docs', label: '文档总数', value: s.doc_total || 0, icon: 'el-icon-document', cls: 'stat-orange' },
        { key: 'size', label: '总大小(MB)', value: s.total_size_mb || 0, icon: 'el-icon-data-line', cls: 'stat-purple' }
      ]
    }
  },
  created () {
    this.loadStats()
    this.loadList()
  },
  methods: {
    statusText (s) {
      return { pending: '未处理', processing: '处理中', completed: '已完成', failed: '失败' }[s] || s || '-'
    },
    statusTagType (s) {
      return { pending: 'info', processing: 'primary', completed: 'success', failed: 'danger' }[s] || 'info'
    },
    progressText (kb) {
      if (kb.status === 'processing') return `处理中 ${kb.progress || 0}%`
      if (kb.status === 'completed') return '已完成 100%'
      return '未处理'
    },
    progressStatus (kb) {
      if (kb.status === 'failed') return 'exception'
      if (kb.status === 'completed') return 'success'
      return ''
    },
    docTypeText (t) {
      return { pdf: 'PDF', word: 'Word', excel: 'Excel', ppt: 'PPT', txt: 'TXT', md: 'MD', html: 'HTML' }[t] || t || '-'
    },
    formatSize (bytes) {
      const b = parseInt(bytes, 10)
      if (isNaN(b) || b <= 0) return '0 B'
      if (b < 1024) return b + ' B'
      if (b < 1048576) return (b / 1024).toFixed(1) + ' KB'
      return (b / 1048576).toFixed(2) + ' MB'
    },
    truncate (s, n) {
      if (!s) return ''
      return s.length > n ? s.slice(0, n) + '...' : s
    },
    // ---- 数据加载 ----
    async loadStats () {
      try {
        const r = await getAiKnowledgeStats()
        if (r.code === 0) this.stats = Object.assign(this.stats, r.data || {})
      } catch (e) {}
    },
    async loadList () {
      this.loading = true
      try {
        const params = {
          page: this.page, limit: this.limit,
          keyword: this.filters.keyword || undefined,
          status: this.filters.status || undefined
        }
        if (this.dateRange && this.dateRange.length === 2) {
          params.start_date = this.dateRange[0]
          params.end_date = this.dateRange[1]
        }
        const r = await getAiKnowledgeList(params)
        if (r.code === 0) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
        }
      } catch (e) {} finally { this.loading = false }
    },
    loadAll () { this.page = 1; this.loadList(); this.loadStats() },
    handleSearch () { this.page = 1; this.loadList() },
    handleReset () {
      this.filters = { keyword: '', status: '' }
      this.dateRange = []
      this.handleSearch()
    },
    quickFilter (status) { this.filters.status = status; this.handleSearch() },
    // ---- 详情 ----
    async openDetail (kb) {
      try {
        const r = await getAiKnowledgeDetail(kb.id, { page: this.docPage, limit: this.docPageSize })
        if (r.code === 0) {
          this.detail = r.data.knowledge
          this.docList = (r.data.documents && r.data.documents.list) || []
          this.docTotal = (r.data.documents && r.data.documents.total) || 0
          this.docPage = 1
          this.detailVisible = true
        }
      } catch (e) {}
    },
    async loadDocs () {
      if (!this.detail) return
      try {
        const r = await getAiKnowledgeDetail(this.detail.id, { page: this.docPage, limit: this.docPageSize })
        if (r.code === 0) {
          this.docList = (r.data.documents && r.data.documents.list) || []
          this.docTotal = (r.data.documents && r.data.documents.total) || 0
        }
      } catch (e) {}
    },
    // ---- 创建/编辑 ----
    openCreate () {
      this.form = { id: null, kb_name: '', description: '', embedding_model: 'text-embedding-v3', chunk_size: 512, overlap: 50 }
      this.formVisible = true
      this.$nextTick(() => { if (this.$refs.kbForm) this.$refs.kbForm.clearValidate() })
    },
    openEdit (kb) {
      this.form = {
        id: kb.id, kb_name: kb.kb_name, description: kb.description || '',
        embedding_model: kb.embedding_model, chunk_size: kb.chunk_size, overlap: kb.overlap
      }
      this.formVisible = true
      this.$nextTick(() => { if (this.$refs.kbForm) this.$refs.kbForm.clearValidate() })
    },
    async submitForm () {
      const ok = await this.$refs.kbForm.validate().catch(() => false)
      if (!ok) return
      this.submitting = true
      try {
        const payload = {
          kb_name: this.form.kb_name,
          description: this.form.description,
          embedding_model: this.form.embedding_model,
          chunk_size: this.form.chunk_size,
          overlap: this.form.overlap
        }
        const r = this.form.id
          ? await editAiKnowledge(this.form.id, payload)
          : await addAiKnowledge(payload)
        if (r.code === 0) {
          this.$message.success(this.form.id ? '知识库已更新' : '知识库创建成功')
          this.formVisible = false
          this.loadAll()
        }
      } catch (e) {} finally { this.submitting = false }
    },
    // ---- 删除 ----
    async removeKb (kb) {
      const c = await this.$confirm(
        `确定要删除知识库 [${kb.kb_name}] 吗？删除后将同时删除所有文档和向量数据，不可恢复`,
        '删除确认', { type: 'warning' }
      ).catch(() => false)
      if (!c) return
      try {
        const r = await deleteAiKnowledge(kb.id)
        if (r.code === 0) { this.$message.success('删除成功'); this.loadAll() }
      } catch (e) {}
    },
    async removeDoc (doc) {
      const c = await this.$confirm(`确定删除文档 [${doc.doc_name}] 吗？`, '删除确认', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const r = await deleteAiKnowledgeDoc(doc.id)
        if (r.code === 0) {
          this.$message.success('文档已删除')
          if (this.docPage > 1 && this.docList.length === 1) this.docPage--
          this.loadDocs()
          this.loadAll()
        }
      } catch (e) {}
    },
    // ---- 其他 ----
    showError (kb) {
      this.errorContent = kb.error_message || '未知错误'
      this.errorVisible = true
    },
    copyKbId (kbId) {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(kbId).then(() => this.$message.success('已复制知识库ID'))
      } else {
        this.$message.success('知识库ID：' + kbId)
      }
    },
    goUpload (kb) {
      this.$router.push({ path: '/ai/knowledge/upload', query: { kb_id: kb.kb_id } })
    },
    goRetrieve (kb) {
      this.$router.push({ path: '/ai/knowledge/search-test', query: { kb_id: kb.kb_id } })
    }
  }
}
</script>

<style scoped>
.page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.sec-card { margin-bottom: 16px; }
.stat-row { margin-bottom: 16px; }
.stat-card { background: #fff; border-radius: 8px; padding: 16px; display: flex; align-items: center; box-shadow: 0 1px 4px rgba(0,0,0,0.06); cursor: pointer; transition: transform 0.15s; }
.stat-card:hover { transform: translateY(-2px); }
.stat-icon { font-size: 30px; margin-right: 12px; }
.stat-num { font-size: 20px; font-weight: 600; color: #303133; }
.stat-label { font-size: 12px; color: #909399; }
.stat-blue .stat-icon { color: #409EFF; }
.stat-green .stat-icon { color: #67C23A; }
.stat-orange .stat-icon { color: #E6A23C; }
.stat-purple .stat-icon { color: #9B59B6; }
.filter-form { margin-bottom: 8px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.toolbar-tip { font-size: 13px; color: #909399; }
.card-row { margin: 0 -8px; }
.kb-col { padding: 0 8px; margin-bottom: 16px; }
.kb-head { display: flex; justify-content: space-between; align-items: center; }
.kb-name { font-size: 14px; font-weight: 600; color: #303133; cursor: pointer; max-width: 200px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.kb-name:hover { color: #409EFF; }
.kb-desc { font-size: 12px; color: #909399; min-height: 34px; line-height: 1.6; margin-bottom: 8px; overflow: hidden; text-overflow: ellipsis; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; }
.kb-meta { display: flex; justify-content: space-between; font-size: 12px; color: #606266; margin-bottom: 4px; }
.kb-progress { margin-top: 8px; }
.kb-progress-label { font-size: 12px; color: #909399; }
.kb-error { margin-top: 4px; font-size: 12px; color: #F56C6C; cursor: pointer; }
.kb-actions { margin-top: 10px; text-align: right; }
.pager { margin-top: 12px; text-align: right; }
.doc-title { margin: 14px 0 8px; font-size: 14px; font-weight: 600; color: #303133; }
.err-text { color: #F56C6C; }
.error-pre { background: #f8f9fb; border-radius: 6px; padding: 10px; font-size: 12px; overflow-x: auto; white-space: pre-wrap; word-break: break-all; max-height: 300px; }
</style>
