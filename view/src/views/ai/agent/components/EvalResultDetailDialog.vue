<template>
  <el-dialog title="用例执行详情" :visible.sync="visible" width="640px" append-to-body>
    <div v-if="row" class="result-detail">
      <el-descriptions :column="2" size="small" border>
        <el-descriptions-item label="用例名称">{{ row.case_name }}</el-descriptions-item>
        <el-descriptions-item label="评分">
          <el-tag size="mini" :type="row.passed ? 'success' : 'danger'">{{ row.score }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="结果" :span="2">
          <el-tag size="mini" :type="row.passed ? 'success' : 'danger'">{{ row.passed ? '通过' : '失败' }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="输入" :span="2">{{ row.input }}</el-descriptions-item>
        <el-descriptions-item label="实际输出" :span="2">{{ row.actual_output }}</el-descriptions-item>
        <el-descriptions-item label="期望输出" :span="2">{{ row.expected_output || '（未设置）' }}</el-descriptions-item>
        <el-descriptions-item label="Token消耗">{{ row.tokens || 0 }}</el-descriptions-item>
        <el-descriptions-item label="响应时间">{{ row.response_time || 0 }} ms</el-descriptions-item>
      </el-descriptions>

      <div class="sub-title">工具调用验证</div>
      <div v-if="row.tool_verify">
        <el-tag v-for="m in row.tool_verify.matched || []" :key="m" size="mini" type="success" class="tag-item">✓ {{ m }}</el-tag>
        <el-tag v-for="m in row.tool_verify.missing || []" :key="m" size="mini" type="danger" class="tag-item">✗ 缺 {{ m }}</el-tag>
        <el-empty v-if="!(row.tool_verify.matched || []).length && !(row.tool_verify.missing || []).length" description="无工具调用验证" :image-size="40" />
      </div>

      <div class="sub-title">知识库检索（{{ (row.knowledge || []).length }}）</div>
      <el-tag v-for="(k, i) in row.knowledge || []" :key="i" size="mini" type="info" class="tag-item">{{ k.title || k.document || '片段' }}</el-tag>
      <el-empty v-if="!(row.knowledge || []).length" description="无知识库检索" :image-size="40" />
    </div>
    <div slot="footer">
      <el-button size="small" type="primary" @click="visible = false">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
export default {
  name: 'EvalResultDetailDialog',
  data() {
    return { visible: false, row: null }
  },
  methods: {
    open(row) {
      this.row = row
      this.visible = true
    }
  }
}
</script>

<style scoped>
.sub-title { font-weight: 600; margin: 14px 0 8px; font-size: 13px; }
.tag-item { margin: 2px 4px 2px 0; }
</style>
