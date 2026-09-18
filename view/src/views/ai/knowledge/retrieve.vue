<!-- 文件：admin/src/views/ai/knowledge/retrieve.vue -->
<template>
  <div class="page">
    <el-card shadow="never" class="sec-card">
      <div class="head-row">
        <div class="head-left">
          <el-button size="small" icon="el-icon-back" @click="goList">返回列表</el-button>
          <span class="head-title">检索测试</span>
        </div>
      </div>
      <el-form inline size="small" class="filter-form">
        <el-form-item>
          <el-select v-model="kbId" placeholder="请选择知识库" filterable style="width:240px" @change="clearResult">
            <el-option v-for="kb in kbOptions" :key="kb.kb_id" :label="kb.kb_name" :value="kb.kb_id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-input v-model="query" placeholder="输入检索问题或关键词" clearable style="width:320px"
            @keyup.enter.native="doRetrieve" @clear="clearResult" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" :loading="searching" :disabled="!kbId || !query.trim()" @click="doRetrieve">检索</el-button>
          <el-button icon="el-icon-refresh-left" @click="clearResult">重置</el-button>
        </el-form-item>
      </el-form>
      <div v-if="resultInfo" class="result-info">
        <el-tag size="mini" type="info">关键词检索</el-tag>
        <span>命中 {{ resultTotal }} 条 · 耗时 {{ resultInfo.elapsed_ms }}ms</span>
      </div>
    </el-card>

    <el-card shadow="never" class="sec-card">
      <div slot="header" class="col-head"><span class="col-title">检索结果</span></div>
      <div v-loading="searching">
        <div v-for="(r, i) in results" :key="r.chunk_id" class="result-item">
          <div class="result-head">
            <span class="result-index">{{ i + 1 }}</span>
            <span class="result-doc">{{ r.doc_name }}</span>
            <span class="result-chunk">切片 #{{ r.chunk_index }}</span>
            <span class="result-score">相关度 {{ r.score }}</span>
          </div>
          <div class="result-content" v-html="highlight(r.content)"></div>
        </div>
        <el-empty v-if="!searching && !results.length && searched" description="未检索到相关内容" />
        <el-empty v-if="!searching && !results.length && !searched" description="选择知识库并输入问题开始检索" />
      </div>
    </el-card>
  </div>
</template>

<script>
import { getAiKnowledgeList, retrieveAiKnowledge } from '@/api/aiKnowledge'

export default {
  name: 'AiKnowledgeRetrieve',
  data () {
    return {
      kbId: '',
      kbOptions: [],
      query: '',
      searching: false,
      results: [],
      resultTotal: 0,
      resultInfo: null,
      searched: false
    }
  },
  created () {
    const qkb = this.$route.query && this.$route.query.kb_id
    if (qkb) this.kbId = qkb
    this.loadKbOptions()
  },
  methods: {
    goList () { this.$router.push('/ai/knowledge/list') },
    async loadKbOptions () {
      try {
        const r = await getAiKnowledgeList({ page: 1, limit: 100 })
        if (r.code === 0) this.kbOptions = r.data.list || []
      } catch (e) {}
    },
    clearResult () {
      this.results = []
      this.resultTotal = 0
      this.resultInfo = null
      this.searched = false
    },
    async doRetrieve () {
      if (!this.kbId || !this.query.trim()) return
      this.searching = true
      this.searched = true
      try {
        const r = await retrieveAiKnowledge({ kb_id: this.kbId, query: this.query, top_k: 10 })
        if (r.code === 0) {
          this.results = r.data.results || []
          this.resultTotal = r.data.total || 0
          this.resultInfo = r.data
        }
      } catch (e) {} finally { this.searching = false }
    },
    /** 关键词高亮（先转义再高亮，防 XSS） */
    highlight (content) {
      const esc = String(content || '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')
      const kws = (this.query || '').split(/[\s,，。;；、]+/).filter(Boolean)
      let html = esc
      kws.forEach(kw => {
        const safe = kw.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
        html = html.replace(new RegExp(safe, 'gi'), m => `<span class="hl">${m}</span>`)
      })
      return html
    }
  }
}
</script>

<style scoped>
.page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.sec-card { margin-bottom: 16px; }
.head-row { display: flex; align-items: center; margin-bottom: 10px; }
.head-left { display: flex; align-items: center; gap: 10px; }
.head-title { font-size: 15px; font-weight: 600; color: #303133; }
.filter-form { margin-bottom: 4px; }
.result-info { font-size: 13px; color: #909399; display: flex; align-items: center; gap: 8px; }
.col-head { }
.col-title { font-size: 15px; font-weight: 600; color: #303133; }
.result-item { border: 1px solid #ebeef5; border-radius: 6px; padding: 10px 12px; margin-bottom: 10px; }
.result-head { display: flex; align-items: center; gap: 10px; margin-bottom: 6px; }
.result-index { width: 20px; height: 20px; border-radius: 50%; background: #409EFF; color: #fff; font-size: 12px; display: inline-flex; align-items: center; justify-content: center; }
.result-doc { font-size: 13px; font-weight: 600; color: #303133; }
.result-chunk { font-size: 12px; color: #909399; }
.result-score { font-size: 12px; color: #E6A23C; margin-left: auto; }
.result-content { font-size: 13px; color: #606266; line-height: 1.7; background: #f8f9fb; border-radius: 4px; padding: 8px; white-space: pre-wrap; word-break: break-word; max-height: 160px; overflow-y: auto; }
.hl { background: #ffd04b; color: #303133; font-weight: 600; border-radius: 2px; padding: 0 1px; }
</style>
