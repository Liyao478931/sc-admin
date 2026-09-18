<!-- 文件：admin/src/views/ai/voice/history.vue（v1.68.0 执行历史） -->
<template>
  <div class="vh-page">
    <div class="crumb"><span>AI智能平台</span><i class="el-icon-arrow-right"></i><span>自然语言交互</span><i class="el-icon-arrow-right"></i><span class="cur">执行历史</span></div>

    <div class="panel">
      <el-table :data="list" v-loading="loading" size="small" border stripe>
        <el-table-column prop="create_time" label="时间" width="150" />
        <el-table-column prop="raw_input" label="指令内容" min-width="200" show-overflow-tooltip />
        <el-table-column prop="intent_text" label="意图" width="80" align="center" />
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="response_time" label="耗时(ms)" width="90" align="center" />
        <el-table-column label="操作" width="120" align="center">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="openDetail(s.row)">详情</el-button>
            <el-button type="text" size="mini" @click="reRun(s.row)">重新执行</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <span>共 {{ total }} 条</span>
        <el-pagination background layout="prev, pager, next" :total="total" :page-size="10" :current-page.sync="page" @current-change="load" />
      </div>
    </div>

    <!-- 详情弹窗 -->
    <el-dialog title="执行详情" :visible.sync="detailVisible" width="620px">
      <div v-if="detail.log" class="d-body">
        <div class="p-line">指令：「{{ detail.log.raw_input }}」｜意图：{{ detail.log.intent }}｜耗时：{{ detail.log.response_time }}ms</div>
        <div class="p-line">实体：{{ fmtEntities(detail.log.entities) }}</div>
        <div class="d-title">执行过程</div>
        <div v-for="h in detail.histories" :key="h.id" class="d-log">
          <div class="d-tool">调用工具：{{ h.tool_name }}｜参数：{{ fmtJson(h.tool_params) }}</div>
          <div class="d-result">结果：{{ fmtResult(h.tool_result) }}</div>
        </div>
        <div v-if="!detail.histories || !detail.histories.length" class="none">无工具调用（导航/分析/帮助类）</div>
        <div class="fb-row">
          <el-button size="mini" type="success" @click="feedback(1)">👍 有用</el-button>
          <el-button size="mini" type="danger" @click="feedback(2)">👎 无用</el-button>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getVoiceHistory, getVoiceHistoryDetail, executeVoice, submitVoiceFeedback } from '@/api/aiVoice'

export default {
  name: 'AiVoiceHistory',
  data () {
    return { list: [], total: 0, page: 1, loading: false, detail: {}, detailVisible: false }
  },
  mounted () { this.load() },
  methods: {
    async load () {
      this.loading = true
      try { const r = await getVoiceHistory({ page: this.page, limit: 10 }); if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 } } catch (e) {} finally { this.loading = false }
    },
    async openDetail (row) {
      try { const r = await getVoiceHistoryDetail(row.id); if (r.code === 0) { this.detail = r.data; this.detailVisible = true } } catch (e) {}
    },
    async reRun (row) {
      try {
        const r = await executeVoice(row.raw_input)
        if (r.code === 0) {
          if (r.data.action === 'navigate' && r.data.page) this.$router.push(r.data.page)
          else this.$message.success(r.data.reply || '已重新执行')
          this.load()
        }
      } catch (e) {}
    },
    async feedback (type) {
      try { const r = await submitVoiceFeedback({ command_log_id: this.detail.log.id, feedback_type: type }); if (r.code === 0) this.$message.success('反馈已提交') } catch (e) {}
    },
    fmtEntities (e) { return e && Object.keys(e).length ? JSON.stringify(e) : '-' },
    fmtJson (j) { return j ? JSON.stringify(j) : '-' },
    fmtResult (r) {
      if (!r) return '-'
      const body = r.body
      if (body && body.data && body.data.list) return '共 ' + (body.data.total ?? body.data.list.length) + ' 条'
      return JSON.stringify(r).slice(0, 150)
    }
  }
}
</script>

<style scoped>
.crumb { padding: 10px 16px; background: #fff; border-bottom: 1px solid #e8e8e8; font-size: 13px; color: #909399; }
.crumb i { margin: 0 6px; }
.crumb .cur { color: #303133; }
.panel { background: #fff; border: 1px solid #ebeef5; border-radius: 8px; margin: 12px 16px; padding: 12px 16px; }
.pager { display: flex; align-items: center; justify-content: space-between; padding-top: 10px; }
.p-line { font-size: 13px; color: #606266; margin-bottom: 6px; }
.d-title { font-weight: 600; margin: 10px 0 6px; }
.d-log { background: #f5f7fa; border-radius: 4px; padding: 6px 8px; margin-bottom: 6px; font-size: 12px; }
.d-tool { color: #303133; }
.d-result { color: #909399; margin-top: 4px; word-break: break-all; }
.none { color: #909399; font-size: 12px; }
.fb-row { margin-top: 12px; display: flex; gap: 8px; }
</style>
