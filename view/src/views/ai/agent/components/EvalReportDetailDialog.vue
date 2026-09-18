<template>
  <el-dialog title="评测报告" :visible.sync="visible" width="760px" append-to-body>
    <div v-if="detail" class="report-detail">
      <!-- 导出按钮 -->
      <div class="export-bar">
        <el-button size="small" icon="el-icon-download" @click="doExport('html')">HTML</el-button>
        <el-button size="small" icon="el-icon-download" @click="doExport('markdown')">Markdown</el-button>
        <el-button size="small" icon="el-icon-download" @click="doExport('json')">JSON</el-button>
      </div>

      <div class="report-head">
        <h3>{{ detail.task_name }}</h3>
        <p>智能体：{{ detail.agent_name }}　评测时间：{{ detail.create_time }}　状态：{{ detail.status_text }}</p>
      </div>

      <el-descriptions :column="4" size="small" border class="summary-desc">
        <el-descriptions-item label="总用例">{{ detail.total_count }}</el-descriptions-item>
        <el-descriptions-item label="通过">{{ detail.passed_count }}</el-descriptions-item>
        <el-descriptions-item label="失败">{{ detail.failed_count }}</el-descriptions-item>
        <el-descriptions-item label="通过率">{{ detail.pass_rate }}%</el-descriptions-item>
        <el-descriptions-item label="平均评分">{{ detail.avg_score }}</el-descriptions-item>
        <el-descriptions-item label="工具准确率">{{ detail.tool_accuracy }}%</el-descriptions-item>
        <el-descriptions-item label="平均响应">{{ detail.avg_response_time }}ms</el-descriptions-item>
        <el-descriptions-item label="Token消耗">{{ detail.total_tokens }}</el-descriptions-item>
      </el-descriptions>

      <div class="sub-title">详细结果（{{ (detail.result || []).length }}）</div>
      <el-table :data="detail.result || []" size="mini" stripe max-height="380">
        <el-table-column prop="case_name" label="用例" min-width="110" show-overflow-tooltip />
        <el-table-column prop="input" label="输入" min-width="120" show-overflow-tooltip />
        <el-table-column prop="actual_output" label="实际输出" min-width="140" show-overflow-tooltip />
        <el-table-column prop="expected_output" label="期望输出" min-width="120" show-overflow-tooltip />
        <el-table-column prop="score" label="评分" width="60" />
        <el-table-column label="状态" width="70">
          <template slot-scope="s">
            <el-tag size="mini" :type="s.row.passed ? 'success' : 'danger'">{{ s.row.passed ? '通过' : '失败' }}</el-tag>
          </template>
        </el-table-column>
      </el-table>
    </div>
    <div slot="footer">
      <el-button size="small" type="primary" @click="visible = false">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getEvalTaskDetail, exportEvalTask } from '../../../../api/aiEval'

export default {
  name: 'EvalReportDetailDialog',
  data() {
    return { visible: false, detail: null }
  },
  methods: {
    async open(id) {
      this.visible = true
      this.detail = null
      try {
        const res = await getEvalTaskDetail(id)
        this.detail = res.data || {}
      } catch (e) {}
    },
    async doExport(format) {
      try {
        const res = await exportEvalTask(this.detail.id, format)
        const typeMap = { html: 'text/html', markdown: 'text/markdown', json: 'application/json' }
        const blob = new Blob([res.data], { type: (typeMap[format] || 'text/plain') + ';charset=utf-8' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url; a.download = `eval_report_${this.detail.task_id}.${format === 'markdown' ? 'md' : format}`; a.click()
        URL.revokeObjectURL(url)
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.export-bar { text-align: right; margin-bottom: 10px; }
.report-head h3 { margin: 0 0 4px; }
.report-head p { color: #909399; font-size: 12px; margin: 0 0 10px; }
.sub-title { font-weight: 600; margin: 14px 0 8px; font-size: 13px; }
</style>
