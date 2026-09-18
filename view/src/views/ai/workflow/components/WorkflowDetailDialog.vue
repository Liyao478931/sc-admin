<!-- 文件：admin/src/views/ai/workflow/components/WorkflowDetailDialog.vue -->
<template>
  <el-dialog title="工作流详情" :visible="visible" @update:visible="$emit('update:visible', $event)" width="750px" top="6vh" @open="load">
    <div v-loading="loading">
      <template v-if="detail.id">
        <!-- 基本信息 -->
        <div class="sec-title">基本信息</div>
        <el-descriptions :column="2" size="small" border>
          <el-descriptions-item label="工作流名称">{{ detail.workflow_name }}</el-descriptions-item>
          <el-descriptions-item label="触发方式">
            <el-tag size="mini" :type="triggerTag(detail.trigger_type)">{{ detail.trigger_text }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="运行状态">
            <el-tag size="mini" :type="statusTag(detail.last_run_status)">{{ detail.status_text }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag size="mini" :type="detail.status === 1 ? 'success' : 'info'">{{ detail.status === 1 ? '启用' : '停用' }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="创建人">{{ detail.created_by_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ detail.create_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="运行次数">{{ detail.run_count || 0 }}</el-descriptions-item>
          <el-descriptions-item label="最近运行时间">{{ detail.last_run_time || '-' }}</el-descriptions-item>
        </el-descriptions>
        <div class="desc-box" v-if="detail.description">描述：{{ detail.description }}</div>

        <!-- 触发配置 -->
        <div class="sec-title">触发配置</div>
        <div class="cfg-box" v-if="detail.trigger_config && Object.keys(detail.trigger_config).length">
          <pre>{{ formatJson(detail.trigger_config) }}</pre>
        </div>
        <div class="cfg-none" v-else>（无额外触发配置）</div>

        <!-- 节点概览 -->
        <div class="sec-title">节点概览（{{ nodes.length }} 个）</div>
        <el-table v-if="nodes.length" :data="nodes" size="mini" border>
          <el-table-column prop="name" label="节点名称" min-width="140" />
          <el-table-column prop="type" label="节点类型" width="140" />
          <el-table-column label="状态" width="90" align="center">
            <template slot-scope="{ row }">
              <el-tag size="mini" :type="row.status === 'success' ? 'success' : 'info'">{{ row.status || '待执行' }}</el-tag>
            </template>
          </el-table-column>
        </el-table>
        <div class="cfg-none" v-else>（暂无节点）</div>

        <!-- 最近运行记录 -->
        <div class="sec-title">最近运行记录</div>
        <el-table v-if="detail.recent_logs && detail.recent_logs.length" :data="detail.recent_logs" size="mini" border>
          <el-table-column prop="create_time" label="开始时间" width="160" />
          <el-table-column label="状态" width="90" align="center">
            <template slot-scope="{ row }">
              <el-tag size="mini" :type="statusTag(row.status)">{{ statusText(row.status) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="duration" label="耗时(ms)" width="100" align="center">
            <template slot-scope="{ row }">{{ row.duration ?? '-' }}</template>
          </el-table-column>
          <el-table-column prop="error_message" label="错误信息" min-width="140" show-overflow-tooltip>
            <template slot-scope="{ row }">{{ row.error_message || '-' }}</template>
          </el-table-column>
        </el-table>
        <div class="cfg-none" v-else>（暂无运行记录）</div>
      </template>
    </div>
  </el-dialog>
</template>

<script>
import { getWorkflowDetail } from '@/api/aiWorkflow'

export default {
  name: 'WorkflowDetailDialog',
  props: {
    visible: { type: Boolean, default: false },
    workflowId: { type: Number, default: 0 }
  },
  data () {
    return { loading: false, detail: {} }
  },
  computed: {
    nodes () {
      const cfg = this.detail.config || {}
      return Array.isArray(cfg.nodes) ? cfg.nodes : []
    }
  },
  methods: {
    async load () {
      if (!this.workflowId) return
      this.loading = true
      try {
        const r = await getWorkflowDetail(this.workflowId)
        if (r.code === 0) this.detail = r.data || {}
      } catch (e) {} finally { this.loading = false }
    },
    formatJson (obj) {
      try { return JSON.stringify(obj, null, 2) } catch (e) { return String(obj) }
    },
    triggerTag (t) { return { manual: 'primary', schedule: 'success', webhook: 'warning', event: 'danger' }[t] || 'info' },
    statusTag (s) { return { idle: 'info', running: 'primary', success: 'success', failed: 'danger' }[s] || 'info' },
    statusText (s) { return { idle: '空闲', running: '运行中', success: '成功', failed: '失败' }[s] || s }
  }
}
</script>

<style scoped>
.sec-title { font-size: 13px; font-weight: 600; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; margin: 14px 0 8px; }
.desc-box { margin-top: 8px; font-size: 13px; color: #606266; }
.cfg-box { background: #f8f9fb; border-radius: 6px; padding: 10px; }
.cfg-box pre { font-size: 12px; margin: 0; white-space: pre-wrap; word-break: break-all; }
.cfg-none { font-size: 12px; color: #c0c4cc; padding: 6px 0; }
</style>
