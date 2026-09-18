<!-- 文件：admin/src/views/ai/workflow/components/WorkflowLogDetailDialog.vue -->
<!-- 运行日志详情：基本信息 / 节点执行详情 / 工作流配置快照 三个 Tab -->
<template>
  <el-dialog title="运行日志详情" :visible="visible" @update:visible="$emit('update:visible', $event)" width="950px" top="5vh" @open="load">
    <div v-loading="loading">
      <template v-if="detail.id">
        <el-tabs v-model="activeTab">
          <!-- 基本信息 -->
          <el-tab-pane label="基本信息" name="base">
            <el-descriptions :column="2" size="small" border>
              <el-descriptions-item label="日志ID">{{ detail.log_id }}</el-descriptions-item>
              <el-descriptions-item label="工作流名称">{{ detail.workflow_name }}</el-descriptions-item>
              <el-descriptions-item label="触发来源">{{ sourceText(detail.trigger_source) }}</el-descriptions-item>
              <el-descriptions-item label="触发人">{{ detail.trigger_user || '-' }}</el-descriptions-item>
              <el-descriptions-item label="开始时间">{{ detail.start_time || '-' }}</el-descriptions-item>
              <el-descriptions-item label="结束时间">{{ detail.end_time || '-' }}</el-descriptions-item>
              <el-descriptions-item label="耗时(ms)">{{ detail.duration ?? '-' }}</el-descriptions-item>
              <el-descriptions-item label="状态">
                <el-tag size="mini" :type="statusTag(detail.status)">{{ statusText(detail.status) }}</el-tag>
              </el-descriptions-item>
            </el-descriptions>
            <div v-if="detail.error_message" class="err-box"><b>错误信息：</b>{{ detail.error_message }}</div>
          </el-tab-pane>

          <!-- 节点执行详情 -->
          <el-tab-pane label="节点执行详情" name="nodes">
            <el-table v-if="executions.length" :data="executions" size="mini" border>
              <el-table-column prop="node_name" label="节点名称" min-width="120" />
              <el-table-column prop="node_type" label="节点类型" width="110" />
              <el-table-column prop="start_time" label="开始时间" width="160">
                <template slot-scope="{ row }">{{ row.start_time || '-' }}</template>
              </el-table-column>
              <el-table-column prop="end_time" label="结束时间" width="160">
                <template slot-scope="{ row }">{{ row.end_time || '-' }}</template>
              </el-table-column>
              <el-table-column prop="duration" label="耗时(ms)" width="90" align="center">
                <template slot-scope="{ row }">{{ row.duration ?? '-' }}</template>
              </el-table-column>
              <el-table-column label="状态" width="90" align="center">
                <template slot-scope="{ row }">
                  <el-tag size="mini" :type="row.status === 'success' ? 'success' : 'danger'">{{ row.status }}</el-tag>
                </template>
              </el-table-column>
              <el-table-column label="操作" width="90" align="center">
                <template slot-scope="{ row }">
                  <el-button type="text" size="mini" @click="openNodeDetail(row)">查看详情</el-button>
                </template>
              </el-table-column>
            </el-table>
            <div v-else class="cfg-none">（无节点执行记录）</div>
          </el-tab-pane>

          <!-- 工作流快照 -->
          <el-tab-pane label="工作流快照" name="snapshot">
            <pre class="snapshot-pre">{{ formatJson(detail.workflow_snapshot) }}</pre>
          </el-tab-pane>
        </el-tabs>
      </template>
    </div>

    <!-- 节点输入输出详情弹窗 -->
    <el-dialog title="节点输入输出" :visible.sync="nodeDetailVisible" width="720px" append-to-body>
      <div v-if="currentNode">
        <div class="sec-title">输入数据</div>
        <pre class="json-pre">{{ formatJson(currentNode.input) }}</pre>
        <div class="sec-title">输出数据</div>
        <pre class="json-pre">{{ formatJson(currentNode.output) }}</pre>
        <div v-if="currentNode.message" class="sec-title">说明</div>
        <div v-if="currentNode.message" class="msg-box">{{ currentNode.message }}</div>
      </div>
      <span slot="footer">
        <el-button size="small" @click="nodeDetailVisible = false">关闭</el-button>
      </span>
    </el-dialog>
  </el-dialog>
</template>

<script>
import { getWorkflowLogDetail } from '@/api/aiWorkflow'

export default {
  name: 'WorkflowLogDetailDialog',
  props: {
    visible: { type: Boolean, default: false },
    logId: { type: Number, default: 0 }
  },
  data () {
    return { activeTab: 'base', loading: false, detail: {}, nodeDetailVisible: false, currentNode: null }
  },
  computed: {
    executions () {
      const ex = this.detail.node_executions
      return Array.isArray(ex) ? ex : []
    }
  },
  methods: {
    async load () {
      if (!this.logId) return
      this.loading = true
      try { const r = await getWorkflowLogDetail(this.logId); if (r.code === 0) this.detail = r.data || {} } catch (e) {} finally { this.loading = false }
    },
    openNodeDetail (row) { this.currentNode = row; this.nodeDetailVisible = true },
    formatJson (obj) {
      if (obj === null || obj === undefined) return '(空)'
      try { return JSON.stringify(typeof obj === 'string' ? JSON.parse(obj) : obj, null, 2) } catch (e) { return String(obj) }
    },
    sourceText (s) { return { manual: '手动', schedule: '定时', webhook: 'Webhook', event: '事件' }[s] || s || '-' },
    statusText (s) { return { running: '运行中', success: '成功', failed: '失败' }[s] || s },
    statusTag (s) { return { running: 'primary', success: 'success', failed: 'danger' }[s] || 'info' }
  }
}
</script>

<style scoped>
.sec-title { font-size: 13px; font-weight: 600; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; margin: 12px 0 6px; }
.err-box { margin-top: 10px; font-size: 13px; color: #F56C6C; background: #fef0f0; border-radius: 6px; padding: 8px 10px; white-space: pre-wrap; word-break: break-all; }
.cfg-none { font-size: 12px; color: #c0c4cc; padding: 8px 0; }
.snapshot-pre { background: #f8f9fb; border-radius: 6px; padding: 12px; font-size: 12px; max-height: 420px; overflow: auto; white-space: pre-wrap; word-break: break-all; }
.json-pre { background: #f8f9fb; border-radius: 6px; padding: 10px; font-size: 12px; max-height: 240px; overflow: auto; white-space: pre-wrap; word-break: break-all; }
.msg-box { font-size: 13px; color: #606266; background: #f5f7fa; border-radius: 6px; padding: 8px 10px; }
</style>
