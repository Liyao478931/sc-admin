<template>
  <div class="ai-search-test-page">
    <!-- 左右结构 -->
    <div class="layout">
      <!-- 左侧：检索配置 -->
      <div class="left-panel">
        <el-card shadow="never" class="config-card">
          <div class="sec-title">检索配置</div>

          <el-form label-width="80px" size="small">
            <el-form-item label="知识库">
              <el-select v-model="params.kb_id" filterable style="width: 100%;" placeholder="选择已完成向量化的知识库">
                <el-option v-for="kb in kbList" :key="kb.kb_id" :label="kb.kb_name" :value="kb.kb_id" />
              </el-select>
            </el-form-item>
            <el-form-item label="检索内容">
              <el-input v-model="params.query_text" type="textarea" :rows="4" placeholder="请输入检索内容..." @keydown.ctrl.enter.native="doSearch" />
            </el-form-item>
            <el-form-item label="检索模式">
              <el-radio-group v-model="params.search_mode" @change="onModeChange">
                <el-radio-button v-for="opt in modeOptions" :key="opt.value" :label="opt.value">{{ opt.label }}</el-radio-button>
              </el-radio-group>
            </el-form-item>
            <el-form-item label="返回数量">
              <el-input-number v-model="params.top_k" :min="1" :max="20" />
            </el-form-item>
            <el-form-item label="相似度阈值">
              <el-slider v-model="thresholdSlider" :min="0" :max="1" :step="0.05" show-input />
            </el-form-item>
            <template v-if="params.search_mode === 'hybrid'">
              <el-form-item label="语义权重">
                <el-slider v-model="params.semantic_weight" :min="0" :max="1" :step="0.1" show-input @change="onWeightChange('semantic')" />
              </el-form-item>
              <el-form-item label="关键词权重">
                <el-slider v-model="params.keyword_weight" :min="0" :max="1" :step="0.1" show-input @change="onWeightChange('keyword')" />
              </el-form-item>
            </template>
            <el-form-item label="启用重排序">
              <el-switch v-model="params.rerank_enabled" />
            </el-form-item>
          </el-form>

          <!-- 检索方案 -->
          <div class="sec-title">检索方案</div>
          <div class="schema-bar">
            <el-select v-model="selectedSchema" placeholder="加载方案" clearable size="small" style="flex:1;" @change="loadSchema">
              <el-option v-for="s in schemaList" :key="s.schema_id" :label="s.schema_name" :value="s.schema_id" />
            </el-select>
            <el-button size="small" type="primary" icon="el-icon-plus" @click="saveSchemaDialog = true">保存方案</el-button>
            <el-button v-if="selectedSchema" size="small" icon="el-icon-delete" @click="deleteSchema">删除</el-button>
          </div>

          <!-- 执行检索 -->
          <el-button type="primary" size="medium" style="width:100%; margin-top:14px;" :loading="searching" @click="doSearch">
            执行检索
          </el-button>
          <div v-if="duration !== null" class="duration">检索耗时：{{ duration }} ms</div>

          <!-- 历史链接 -->
          <el-button type="text" size="small" style="margin-top:6px;" @click="$refs.historyDialog.open()">查看检索历史</el-button>
        </el-card>
      </div>

      <!-- 右侧：检索结果 -->
      <div class="right-panel">
        <el-card shadow="never" class="result-card">
          <div class="result-head">
            <span class="result-count">找到 {{ resultCount }} 个相关结果</span>
            <span v-if="avgScore !== null" class="result-meta">平均得分 {{ avgScore }} · 最高 {{ maxScore }}</span>
          </div>

          <!-- 优化建议 -->
          <el-alert v-if="suggestions.length" :title="suggestions[0]" type="warning" :closable="false" show-icon class="suggest-alert" />

          <!-- 结果列表 -->
          <div v-if="results.length" class="result-list">
            <el-card v-for="(r, i) in results" :key="r.chunk_id" shadow="never" class="result-item">
              <div class="result-body">
                <div class="score-box" :style="{ color: scoreColor(r.score) }">{{ r.score }}</div>
                <div class="result-content">
                  <div class="result-doc">{{ r.doc_name }} <span class="chunk-idx">#{{ r.chunk_index }}</span></div>
                  <div class="result-text" v-html="r.highlighted || r.content"></div>
                  <div class="result-doc-id">文档ID：{{ r.doc_id }}</div>
                </div>
              </div>
              <div class="result-actions">
                <el-button size="mini" :type="feedbackMap[i] === true ? 'success' : 'default'" :disabled="feedbackMap[i] !== undefined" @click="doFeedback(i, r, true)">相关</el-button>
                <el-button size="mini" :type="feedbackMap[i] === false ? 'danger' : 'default'" :disabled="feedbackMap[i] !== undefined" @click="doFeedback(i, r, false)">不相关</el-button>
              </div>
            </el-card>
          </div>

          <!-- 空状态 -->
          <el-empty v-if="!results.length && !searching" description="未找到相关内容，请调整检索参数重试" :image-size="80" />
          <div v-if="searching" v-loading="true" class="searching-box"></div>
        </el-card>
      </div>
    </div>

    <!-- 保存方案弹窗 -->
    <el-dialog title="保存检索方案" :visible.sync="saveSchemaDialog" width="420px" append-to-body>
      <el-input v-model="schemaName" maxlength="50" placeholder="请输入方案名称" />
      <div slot="footer">
        <el-button size="small" @click="saveSchemaDialog = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="saveSchema">保存</el-button>
      </div>
    </el-dialog>

    <!-- 历史弹窗 -->
    <SearchHistoryDialog ref="historyDialog" @reload="onHistoryReload" />
  </div>
</template>

<script>
import {
  executeSearchTest, submitSearchFeedback, getSearchSchemas, saveSearchSchema, deleteSearchSchema
} from '../../../api/aiSearchTest'
import { getAiKnowledgeList } from '../../../api/aiKnowledge'
import SearchHistoryDialog from './components/SearchHistoryDialog.vue'

export default {
  name: 'AiSearchTest',
  components: { SearchHistoryDialog },
  data() {
    return {
      kbList: [],
      modeOptions: [],
      params: {
        kb_id: '', query_text: '', search_mode: 'semantic',
        top_k: 5, threshold: 0.6, semantic_weight: 0.5, keyword_weight: 0.5, rerank_enabled: false
      },
      thresholdSlider: 0.6,
      results: [], resultCount: 0, avgScore: null, maxScore: null, duration: null, suggestions: [],
      feedbackMap: {}, currentRecordId: '',
      searching: false,
      schemaList: [], selectedSchema: '', schemaName: '', saveSchemaDialog: false, saving: false
    }
  },
  created() {
    // 从知识库列表"检索"进入：URL 带 kb_id 预选
    const kbId = this.$route.query.kb_id || ''
    if (kbId) this.params.kb_id = kbId
    this.loadKbList()
    this.loadSchemas()
    this.loadDicts()
  },
  methods: {
    // 检索模式从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../api/dictionary')
      try { const r = await getDictByCode('search_mode'); this.modeOptions = r.data || [] } catch (e) { this.modeOptions = [] }
    },
    async loadKbList() {
      try {
        const res = await getAiKnowledgeList({ page: 1, limit: 100 })
        this.kbList = res.data.list || []
      } catch (e) {}
    },
    async loadSchemas() {
      try {
        const res = await getSearchSchemas({})
        this.schemaList = res.data || []
      } catch (e) {}
    },
    onModeChange() {
      // 切换模式时保持参数，混合模式显示权重
    },
    onWeightChange(which) {
      // 保持权重之和为1：调整任一权重时，另一个自动补足
      if (which === 'semantic') {
        this.params.keyword_weight = Math.round((1 - this.params.semantic_weight) * 10) / 10
      } else {
        this.params.semantic_weight = Math.round((1 - this.params.keyword_weight) * 10) / 10
      }
    },
    async doSearch() {
      if (!this.params.kb_id) return this.$message.warning('请选择知识库')
      if (!this.params.query_text.trim()) return this.$message.warning('请输入检索内容')
      this.searching = true
      this.results = []
      this.feedbackMap = {}
      this.suggestions = []
      try {
        const res = await executeSearchTest({
          kb_id: this.params.kb_id,
          query_text: this.params.query_text,
          search_mode: this.params.search_mode,
          top_k: this.params.top_k,
          threshold: this.thresholdSlider,
          semantic_weight: this.params.semantic_weight,
          keyword_weight: this.params.keyword_weight,
          rerank_enabled: this.params.rerank_enabled ? 1 : 0
        })
        const d = res.data || {}
        this.results = d.results || []
        this.resultCount = d.result_count || 0
        this.avgScore = d.avg_score ?? null
        this.maxScore = d.max_score ?? null
        this.duration = d.search_duration ?? null
        this.suggestions = d.suggestions || []
        this.currentRecordId = d.record_id || ''
      } catch (e) {}
      this.searching = false
    },
    async doFeedback(index, result, relevant) {
      if (!this.currentRecordId) return this.$message.warning('请先执行检索')
      try {
        await submitSearchFeedback({
          record_id: this.currentRecordId, result_index: index, relevant: relevant ? 1 : 0
        })
        this.$set(this.feedbackMap, index, relevant)
        this.$message.success('反馈已提交')
      } catch (e) {}
    },
    async saveSchema() {
      if (!this.schemaName.trim()) return this.$message.warning('请输入方案名称')
      if (!this.params.kb_id) return this.$message.warning('请选择知识库')
      this.saving = true
      try {
        const res = await saveSearchSchema({
          schema_name: this.schemaName,
          kb_id: this.params.kb_id,
          search_mode: this.params.search_mode,
          top_k: this.params.top_k,
          threshold: this.thresholdSlider,
          semantic_weight: this.params.semantic_weight,
          keyword_weight: this.params.keyword_weight,
          rerank_enabled: this.params.rerank_enabled ? 1 : 0
        })
        this.$message.success(res.msg || '方案已保存')
        this.saveSchemaDialog = false
        this.schemaName = ''
        this.loadSchemas()
      } catch (e) {}
      this.saving = false
    },
    loadSchema(schemaId) {
      const s = this.schemaList.find(x => x.schema_id === schemaId)
      if (!s) return
      this.params.search_mode = s.search_mode
      this.params.top_k = Number(s.top_k) || 5
      this.thresholdSlider = Number(s.threshold) || 0.6
      this.params.semantic_weight = Number(s.semantic_weight) || 0.5
      this.params.keyword_weight = Number(s.keyword_weight) || 0.5
      this.params.rerank_enabled = Number(s.rerank_enabled) === 1
      this.$message.success('方案已加载')
    },
    deleteSchema() {
      const s = this.schemaList.find(x => x.schema_id === this.selectedSchema)
      this.$confirm(`确定删除方案「${s ? s.schema_name : ''}」？`, '提示', { type: 'warning' }).then(async () => {
        try {
          await deleteSearchSchema(s.id)
          this.$message.success('已删除')
          this.selectedSchema = ''
          this.loadSchemas()
        } catch (e) {}
      }).catch(() => {})
    },
    onHistoryReload(data) {
      // 从历史重新加载：填充配置和结果
      if (!data) return
      this.params.kb_id = data.kb_id
      this.params.query_text = data.query_text
      this.params.search_mode = data.search_mode
      this.params.top_k = Number(data.top_k) || 5
      this.thresholdSlider = Number(data.threshold) || 0.6
      const results = (data.results && typeof data.results === 'string') ? JSON.parse(data.results) : (data.results || [])
      this.results = results
      this.resultCount = data.result_count || results.length
      this.avgScore = Number(data.avg_score) || null
      this.maxScore = Number(data.max_score) || null
      this.duration = data.search_duration || null
      this.currentRecordId = data.record_id || ''
      this.feedbackMap = {}
      const fb = (data.user_feedback && typeof data.user_feedback === 'string') ? JSON.parse(data.user_feedback) : (data.user_feedback || {})
      Object.keys(fb).forEach(k => { this.feedbackMap[Number(k)] = fb[k] })
    },
    scoreColor(score) {
      if (score >= 0.7) return '#67c23a'
      if (score >= 0.4) return '#e6a23c'
      return '#f56c6c'
    }
  }
}
</script>

<style scoped>
.ai-search-test-page { padding: 4px 16px; }
.layout { display: flex; gap: 14px; align-items: flex-start; }
.left-panel { width: 360px; flex-shrink: 0; }
.right-panel { flex: 1; }
.sec-title { font-weight: 600; margin-bottom: 10px; }
.schema-bar { display: flex; gap: 6px; }
.duration { color: #909399; font-size: 12px; margin-top: 8px; text-align: center; }
.result-head { display: flex; align-items: center; margin-bottom: 12px; }
.result-count { font-weight: 600; }
.result-meta { color: #909399; font-size: 12px; margin-left: 12px; }
.suggest-alert { margin-bottom: 12px; }
.result-list { display: flex; flex-direction: column; gap: 10px; }
.result-item { }
.result-body { display: flex; gap: 12px; }
.score-box { font-size: 24px; font-weight: 700; width: 50px; text-align: center; flex-shrink: 0; }
.result-content { flex: 1; }
.result-doc { font-weight: 600; font-size: 13px; }
.chunk-idx { color: #c0c4cc; font-size: 12px; }
.result-text { color: #606266; font-size: 13px; margin-top: 4px; line-height: 1.6; }
.result-doc-id { color: #c0c4cc; font-size: 11px; margin-top: 4px; }
.result-actions { text-align: right; margin-top: 6px; }
.searching-box { height: 100px; }
</style>
