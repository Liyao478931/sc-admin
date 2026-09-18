<!-- 文件：admin/src/views/ai/app/components/AppStatsDialog.vue -->
<!-- 应用调用统计：总调用/今日/本月/平均 + 趋势与最近调用（依赖调用明细表，待建设） -->
<template>
  <el-dialog title="调用统计" :visible="visible" @update:visible="$emit('update:visible', $event)" width="700px" top="6vh">
    <div v-if="app">
      <!-- 统计指标 -->
      <el-row :gutter="12" class="stat-row">
        <el-col :span="6"><div class="mini-stat"><div class="ms-v">{{ app.call_count || 0 }}</div><div class="ms-l">总调用次数</div></div></el-col>
        <el-col :span="6"><div class="mini-stat"><div class="ms-v">—</div><div class="ms-l">今日调用</div></div></el-col>
        <el-col :span="6"><div class="mini-stat"><div class="ms-v">—</div><div class="ms-l">本月调用</div></div></el-col>
        <el-col :span="6"><div class="mini-stat"><div class="ms-v">—</div><div class="ms-l">平均响应(ms)</div></div></el-col>
      </el-row>

      <!-- 调用趋势 -->
      <div class="sec-title">调用趋势</div>
      <div class="cfg-none">调用明细表（ai_app_call_logs）待建设，趋势数据暂不可用。</div>

      <!-- 最近调用记录 -->
      <div class="sec-title">最近调用记录</div>
      <div class="cfg-none">（调用明细表待建设，暂无调用记录）</div>

      <div class="cfg-none" style="margin-top:10px;">应用最后调用时间：{{ app.last_call_time || '从未调用' }}</div>
    </div>
  </el-dialog>
</template>

<script>
export default {
  name: 'AppStatsDialog',
  props: {
    visible: { type: Boolean, default: false },
    app: { type: Object, default: null }
  }
}
</script>

<style scoped>
.stat-row { margin-bottom: 10px; }
.mini-stat { background: #f5f7fa; border-radius: 8px; padding: 12px; text-align: center; }
.ms-v { font-size: 18px; font-weight: 700; color: #303133; }
.ms-l { font-size: 12px; color: #909399; margin-top: 4px; }
.sec-title { font-size: 13px; font-weight: 600; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; margin: 14px 0 8px; }
.cfg-none { font-size: 12px; color: #c0c4cc; padding: 6px 0; }
</style>
