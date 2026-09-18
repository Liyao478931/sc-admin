<!-- 文件：admin/src/views/ai/knowledge/upload.vue -->
<template>
  <div class="page">
    <!-- 顶部：知识库信息卡片 -->
    <el-card shadow="never" class="sec-card">
      <div class="head-row">
        <div class="head-left">
          <el-button size="small" icon="el-icon-back" @click="goList">返回列表</el-button>
          <span class="head-title">文档上传</span>
          <el-select v-model="kbId" placeholder="请选择知识库" filterable size="small" style="width:240px" @change="onKbChange">
            <el-option v-for="kb in kbOptions" :key="kb.kb_id" :label="kb.kb_name" :value="kb.kb_id" />
          </el-select>
        </div>
        <div class="head-right">
          <el-button size="small" type="primary" icon="el-icon-refresh" @click="loadKbInfo">刷新</el-button>
        </div>
      </div>
      <div v-if="kb" class="kb-info">
        <el-tag size="mini" :type="statusTagType(kb.status)">{{ statusText(kb.status) }}</el-tag>
        <span class="kb-desc">{{ kb.description || '暂无描述' }}</span>
        <span class="kb-stat"><i class="el-icon-document"></i> {{ kb.doc_count }} 个文档</span>
        <span class="kb-stat"><i class="el-icon-data-line"></i> {{ formatSize(kb.total_size) }}</span>
      </div>
    </el-card>

    <!-- 中部：上传区域 -->
    <el-card v-if="kb" shadow="never" class="sec-card">
      <div slot="header" class="col-head">
        <span class="col-title">上传文档</span>
        <el-collapse v-model="advOpen" style="width:260px;">
          <el-collapse-item title="高级设置（切片/重叠）" name="adv">
            <div class="adv-row">
              <span>切片大小</span>
              <el-input-number v-model="chunkSize" :min="100" :max="2000" :step="64" size="mini" style="width:130px" />
            </div>
            <div class="adv-row">
              <span>重叠大小</span>
              <el-input-number v-model="overlap" :min="0" :max="500" :step="10" size="mini" style="width:130px" />
            </div>
          </el-collapse-item>
        </el-collapse>
      </div>
      <el-upload
        drag multiple
        :show-file-list="false"
        :accept="acceptExts"
        :auto-upload="false"
        :on-change="onFilesChange"
        :disabled="uploading"
        ref="uploader"
      >
        <i class="el-icon-upload"></i>
        <div class="el-upload__text">将文件拖到此处，或<em>点击选择（可多选）</em></div>
        <div class="el-upload__tip">支持 {{ extTip }}，单个不超过 {{ uploadCfg.max_size_mb }}MB，单次最多 {{ uploadCfg.max_count }} 个</div>
      </el-upload>
      <div class="upload-actions">
        <el-button type="primary" icon="el-icon-upload2" :disabled="!queue.length || uploading" @click="startUpload">
          {{ uploading ? '上传中...' : '开始上传（' + queue.length + '）' }}
        </el-button>
        <el-button icon="el-icon-refresh-left" :disabled="uploading" @click="clearQueue">清空队列</el-button>
      </div>
      <file-list v-if="queue.length" :files="queue" @remove="removeFromQueue" />
    </el-card>

    <!-- 底部：已上传文档列表 -->
    <el-card v-if="kb" shadow="never" class="sec-card">
      <div slot="header" class="col-head"><span class="col-title">已上传文档</span></div>
      <document-list
        :list="docs" :total="docTotal" :page="docPage" :limit="docPageSize" :loading="docLoading"
        @search="onDocSearch" @page-change="p => { docPage = p; loadDocs() }" @refresh="reloadDocs"
        @delete="removeDoc" @retry="retryDoc" @batch-delete="batchRemoveDocs" @batch-retry="batchRetryDocs"
        @toast="msg => $message.info(msg)"
      />
    </el-card>

    <el-empty v-if="!kb" description="请先选择知识库" />
  </div>
</template>

<script>
import FileList from './components/FileList.vue'
import DocumentList from './components/DocumentList.vue'
import {
  getAiKnowledgeList, getUploadConfig, getUploadKbInfo,
  uploadDocBatch, getUploadDocs, deleteUploadDoc, batchDeleteUploadDocs,
  retryUploadDoc, batchRetryUploadDocs
} from '@/api/aiKnowledge'

export default {
  name: 'AiKnowledgeUpload',
  components: { FileList, DocumentList },
  data () {
    return {
      kbId: '',
      kb: null,
      kbOptions: [],
      uploadCfg: { allowed_exts: [], max_size_mb: 50, max_count: 20 },
      acceptExts: '',
      queue: [],
      uploading: false,
      advOpen: [],
      chunkSize: 512,
      overlap: 50,
      // 文档列表
      docs: [], docTotal: 0, docPage: 1, docPageSize: 10, docLoading: false,
      docFilters: { keyword: '', doc_type: '', status: '' }
    }
  },
  computed: {
    extTip () {
      return (this.uploadCfg.allowed_exts || []).map(e => '.' + e).join(' / ')
    }
  },
  created () {
    this.loadConfig()
    this.loadKbOptions()
    const qkb = this.$route.query && this.$route.query.kb_id
    if (qkb) this.kbId = qkb
  },
  methods: {
    statusText (s) {
      return { pending: '未处理', processing: '处理中', completed: '已完成', failed: '失败' }[s] || s || '-'
    },
    statusTagType (s) {
      return { pending: 'info', processing: 'primary', completed: 'success', failed: 'danger' }[s] || 'info'
    },
    formatSize (bytes) {
      const b = parseInt(bytes, 10)
      if (isNaN(b) || b <= 0) return '0 B'
      if (b < 1024) return b + ' B'
      if (b < 1048576) return (b / 1024).toFixed(1) + ' KB'
      return (b / 1048576).toFixed(2) + ' MB'
    },
    goList () { this.$router.push('/ai/knowledge/list') },
    async loadConfig () {
      try {
        const r = await getUploadConfig()
        if (r.code === 0) {
          this.uploadCfg = Object.assign(this.uploadCfg, r.data || {})
          this.acceptExts = (r.data.allowed_exts || []).map(e => '.' + e).join(',')
        }
      } catch (e) {}
    },
    async loadKbOptions () {
      try {
        const r = await getAiKnowledgeList({ page: 1, limit: 100 })
        if (r.code === 0) {
          this.kbOptions = r.data.list || []
          if (this.kbId && !this.kbOptions.some(k => k.kb_id === this.kbId)) this.kbId = ''
          if (this.kbId) this.loadKbInfo()
        }
      } catch (e) {}
    },
    async loadKbInfo () {
      if (!this.kbId) { this.kb = null; this.docs = []; return }
      try {
        const r = await getUploadKbInfo(this.kbId)
        if (r.code === 0) {
          this.kb = r.data
          this.chunkSize = r.data.chunk_size
          this.overlap = r.data.overlap
          this.docPage = 1
          this.loadDocs()
        }
      } catch (e) {}
    },
    onKbChange (val) { this.kbId = val; this.loadKbInfo() },
    // ---- 上传队列 ----
    onFilesChange (file, files) {
      // el-upload on-change 每次触发时收集全部选中文件
      const cfg = this.uploadCfg
      const allowed = cfg.allowed_exts || []
      files.forEach(f => {
        const ext = (f.name.split('.').pop() || '').toLowerCase()
        const size = f.size || 0
        if (!allowed.includes(ext)) { this.$message.warning(`已过滤不支持的文件：${f.name}（.${ext}）`); return }
        if (size > cfg.max_size_mb * 1024 * 1024) { this.$message.warning(`已过滤超大文件：${f.name}`); return }
        if (this.queue.some(q => q.name === f.name)) return // 防重复
        this.queue.push({ name: f.name, type: ext, size, raw: f, status: 'waiting', progress: 0 })
      })
      if (this.queue.length > cfg.max_count) {
        this.$message.warning(`单次最多上传 ${cfg.max_count} 个，已截断`)
        this.queue = this.queue.slice(0, cfg.max_count)
      }
      this.$refs.uploader.clearFiles()
    },
    removeFromQueue (row) {
      if (row.status === 'uploading') return
      this.queue = this.queue.filter(q => q !== row)
    },
    clearQueue () { this.queue = [] },
    async startUpload () {
      if (!this.kbId || !this.queue.length || this.uploading) return
      this.uploading = true
      const total = this.queue.length
      let done = 0
      for (const item of this.queue) {
        if (item.status === 'done') { done++; continue }
        item.status = 'uploading'
        item.progress = 0
        try {
          const fd = new FormData()
          fd.append('kb_id', this.kbId)
          fd.append('chunk_size', String(this.chunkSize))
          fd.append('overlap', String(this.overlap))
          fd.append('files[]', item.raw)
          const r = await uploadDocBatch(fd, p => { item.progress = p })
          item.status = 'done'
          item.progress = 100
          if (r && r.code === 0) {
            const failed = (r.data && r.data.failed_count) || 0
            if (failed) item.error = (r.data.failed || []).map(f => f.error).join('; ')
          }
        } catch (e) {
          item.status = 'error'
          item.error = e.message || '上传失败'
        }
        done++
      }
      this.uploading = false
      this.$message.success('上传完成')
      this.reloadDocs()
      this.loadKbInfo()
      this.queue = []
    },
    // ---- 文档列表 ----
    reloadDocs () { this.docPage = 1; this.loadDocs() },
    async loadDocs () {
      if (!this.kbId) return
      this.docLoading = true
      try {
        const params = {
          kb_id: this.kbId, page: this.docPage, limit: this.docPageSize,
          keyword: this.docFilters.keyword || undefined,
          doc_type: this.docFilters.doc_type || undefined,
          status: this.docFilters.status || undefined
        }
        const r = await getUploadDocs(params)
        if (r.code === 0) {
          this.docs = r.data.list || []
          this.docTotal = r.data.total || 0
        }
      } catch (e) {} finally { this.docLoading = false }
    },
    onDocSearch (filters) {
      this.docFilters = Object.assign({}, filters)
      this.reloadDocs()
    },
    async removeDoc (doc) {
      const c = await this.$confirm(`确定删除文档 [${doc.doc_name}] 吗？将同时删除向量数据`, '删除确认', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const r = await deleteUploadDoc(doc.doc_id)
        if (r.code === 0) { this.$message.success('文档已删除'); this.reloadDocs(); this.loadKbInfo() }
      } catch (e) {}
    },
    async batchRemoveDocs (docIds) {
      const c = await this.$confirm(`确定删除选中的 ${docIds.length} 个文档吗？将同时删除向量数据`, '批量删除', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const r = await batchDeleteUploadDocs(docIds)
        if (r.code === 0) { this.$message.success(r.msg || '删除完成'); this.reloadDocs(); this.loadKbInfo() }
      } catch (e) {}
    },
    async retryDoc (doc) {
      const c = await this.$confirm(`确认重新处理文档 [${doc.doc_name}] 吗？`, '重新处理', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const r = await retryUploadDoc(doc.doc_id)
        if (r.code === 0) { this.$message.success('已加入重新处理队列'); this.loadDocs() }
      } catch (e) {}
    },
    async batchRetryDocs (docIds) {
      const c = await this.$confirm(`确认重新处理选中的 ${docIds.length} 个文档吗？`, '批量重试', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const r = await batchRetryUploadDocs(docIds)
        if (r.code === 0) { this.$message.success('已提交重新处理'); this.loadDocs() }
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.sec-card { margin-bottom: 16px; }
.head-row { display: flex; justify-content: space-between; align-items: center; }
.head-left { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
.head-title { font-size: 15px; font-weight: 600; color: #303133; }
.kb-info { margin-top: 10px; display: flex; align-items: center; gap: 14px; flex-wrap: wrap; }
.kb-desc { font-size: 12px; color: #909399; }
.kb-stat { font-size: 12px; color: #606266; }
.col-head { display: flex; justify-content: space-between; align-items: center; }
.col-title { font-size: 15px; font-weight: 600; color: #303133; }
.adv-row { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; font-size: 12px; color: #606266; }
.upload-actions { margin-top: 12px; }
</style>
