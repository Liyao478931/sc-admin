<!-- 文件：admin/src/views/ai/workflow/components/WorkflowRunDialog.vue -->
<template>
  <el-dialog title="确认运行" :visible="visible" @update:visible="$emit('update:visible', $event)" width="450px" :close-on-click-modal="false">
    <div class="run-body">
      <div class="run-name"><i class="el-icon-s-promotion"></i> {{ workflow ? workflow.workflow_name : '' }}</div>
      <div class="run-tip">确认立即执行该工作流吗？执行过程将记录到运行日志中。</div>
    </div>
    <span slot="footer">
      <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
      <el-button size="small" type="primary" :loading="running" @click="doRun">确认运行</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { triggerWorkflow } from '@/api/aiWorkflow'

export default {
  name: 'WorkflowRunDialog',
  props: {
    visible: { type: Boolean, default: false },
    workflow: { type: Object, default: null }
  },
  data () {
    return { running: false }
  },
  methods: {
    async doRun () {
      if (!this.workflow || !this.workflow.id) return
      this.running = true
      try {
        const r = await triggerWorkflow(this.workflow.id)
        if (r.code === 0) {
          this.$message.success('工作流已开始执行')
          this.$emit('success')
          this.$emit('update:visible', false)
        }
      } catch (e) {} finally { this.running = false }
    }
  }
}
</script>

<style scoped>
.run-body { padding: 4px 2px; }
.run-name { font-size: 15px; font-weight: 600; color: #303133; margin-bottom: 10px; }
.run-name i { color: #409EFF; margin-right: 6px; }
.run-tip { font-size: 13px; color: #606266; }
</style>
