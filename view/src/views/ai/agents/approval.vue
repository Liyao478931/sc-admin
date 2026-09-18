<!-- 文件：admin/src/views/ai/agents/approval.vue（v1.67.0 审批助手） -->
<template>
  <div class="ap-page">
    <div class="crumb"><span>AI智能平台</span><i class="el-icon-arrow-right"></i><span>业务智能体</span><i class="el-icon-arrow-right"></i><span class="cur">审批助手</span></div>

    <div class="toolbar">
      <el-select v-model="urgency" size="small" placeholder="紧急度" clearable style="width:110px" @change="load">
        <el-option label="紧急" value="high" />
        <el-option label="中等" value="medium" />
        <el-option label="一般" value="low" />
      </el-select>
      <el-button size="small" icon="el-icon-refresh" style="margin-left:12px;" @click="load">刷新</el-button>
      <el-button size="small" type="primary" icon="el-icon-magic-stick" @click="loadSuggest">批量建议</el-button>
    </div>

    <!-- 批量建议 -->
    <div v-if="suggestions.length" class="panel">
      <div class="panel-head">批量处理建议</div>
      <div v-for="s in suggestions" :key="s.biz_type" class="sug-row">
        {{ s.suggestion }}
        <el-button size="mini" type="primary" @click="batchPass(s.ids)">批量通过</el-button>
      </div>
    </div>

    <!-- 待办列表 -->
    <div class="panel">
      <div class="panel-head">待办审批（共 {{ total }} 条）</div>
      <el-table :data="list" v-loading="loading" size="small" border stripe>
        <el-table-column label="紧急度" width="80" align="center">
          <template slot-scope="s"><el-tag :type="s.row.urgency_tag" size="mini">{{ s.row.urgency_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="biz_type" label="审批类型" width="100" align="center" />
        <el-table-column prop="instance_no" label="编号" width="140" />
        <el-table-column prop="business_title" label="申请信息" min-width="160" show-overflow-tooltip />
        <el-table-column prop="submit_time" label="申请时间" width="140" />
        <el-table-column label="AI建议" width="110" align="center">
          <template slot-scope="s"><span :class="s.row.ai_recommendation.recommendation === 'pass' ? 'rec-pass' : (s.row.ai_recommendation.recommendation === 'reject' ? 'rec-reject' : 'rec-none')">{{ s.row.ai_recommendation.label }}</span></template>
        </el-table-column>
        <el-table-column label="操作" width="100" align="center">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="openApprove(s.row)">审批</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <span>共 {{ total }} 条</span>
        <el-pagination background layout="prev, pager, next" :total="total" :page-size="10" :current-page.sync="page" @current-change="load" />
      </div>
    </div>

    <!-- 审批弹窗 -->
    <el-dialog :title="'审批 - ' + (current.instance_no || '')" :visible.sync="approveVisible" width="560px">
      <div v-if="current.id" class="ap-body">
        <div class="p-line">申请人：{{ current.applicant_name || '-' }}｜类型：{{ current.biz_type }}｜等待：{{ current.waiting_hours }} 小时</div>
        <div class="p-line">事由：{{ current.business_title }}</div>
        <div class="ai-box">
          <div class="ai-title">🤖 AI建议：<b>{{ current.ai_recommendation.label }}</b><span v-if="current.ai_recommendation.confidence">（置信度：{{ current.ai_recommendation.confidence }}）</span></div>
          <div class="ai-reason">{{ current.ai_recommendation.reason || '暂无依据' }}</div>
        </div>
        <div class="btn-row">
          <el-button type="success" @click="doApprove('pass')">通过</el-button>
          <el-button type="danger" @click="doApprove('reject')">驳回</el-button>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getApprovalTodos, executeApproval, getApprovalBatchSuggest, batchExecuteApproval } from '@/api/aiAgentBiz'

export default {
  name: 'AiAgentApproval',
  data () {
    return { list: [], total: 0, page: 1, loading: false, urgency: '', suggestions: [], approveVisible: false, current: {} }
  },
  mounted () { this.load() },
  methods: {
    async load () {
      this.loading = true
      try {
        const r = await getApprovalTodos({ page: this.page, limit: 10, urgency: this.urgency })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    async loadSuggest () {
      try { const r = await getApprovalBatchSuggest(); if (r.code === 0) this.suggestions = r.data.list || [] } catch (e) {}
    },
    openApprove (row) { this.current = row; this.approveVisible = true },
    async doApprove (decision) {
      try {
        const r = await executeApproval({ id: this.current.id, decision })
        if (r.code === 0) { this.$message.success('已' + (decision === 'pass' ? '通过' : '驳回')); this.approveVisible = false; this.load() } else this.$message.error(r.msg || '处理失败')
      } catch (e) { this.$message.error('处理失败') }
    },
    async batchPass (ids) {
      try {
        const r = await batchExecuteApproval({ ids, decision: 'pass' })
        if (r.code === 0) { this.$message.success('批量通过 ' + r.data.success + ' 笔'); this.load(); this.loadSuggest() } else this.$message.error(r.msg || '失败')
      } catch (e) { this.$message.error('批量处理失败') }
    }
  }
}
</script>

<style scoped>
.crumb { padding: 10px 16px; background: #fff; border-bottom: 1px solid #e8e8e8; font-size: 13px; color: #909399; }
.crumb i { margin: 0 6px; }
.crumb .cur { color: #303133; }
.toolbar { display: flex; align-items: center; padding: 12px 16px; }
.panel { background: #fff; border: 1px solid #ebeef5; border-radius: 8px; margin: 0 16px 16px; padding: 12px 16px; }
.panel-head { font-weight: 600; margin-bottom: 8px; }
.pager { display: flex; align-items: center; justify-content: space-between; padding-top: 10px; }
.rec-pass { color: #67c23a; }
.rec-reject { color: #f56c6c; }
.rec-none { color: #909399; }
.sug-row { display: flex; align-items: center; gap: 10px; padding: 6px 0; font-size: 13px; border-bottom: 1px dashed #ebeef5; }
.p-line { font-size: 13px; color: #606266; margin-bottom: 6px; }
.ai-box { background: #f0f7ff; border: 1px solid #d0e4ff; border-radius: 6px; padding: 10px; margin: 10px 0; }
.ai-title { font-size: 13px; margin-bottom: 6px; }
.ai-reason { font-size: 12px; color: #606266; white-space: pre-wrap; }
.btn-row { display: flex; gap: 10px; }
</style>
