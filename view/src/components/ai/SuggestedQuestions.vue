<!-- 推荐问题区：点击标签自动填入并发送 -->
<template>
  <div v-if="questions && questions.length" class="sug-wrap">
    <span class="sug-label">推荐问题：</span>
    <el-tag v-for="q in questions" :key="q.id" size="small" class="sug-tag" @click="$emit('ask', q)">
      {{ q.text }}
    </el-tag>
  </div>
</template>

<script>
export default {
  name: 'AiSuggestedQuestions',
  props: {
    questions: { type: Array, default: () => [] }
  }
}
</script>

<style scoped>
.sug-wrap { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; margin-bottom: 8px; }
.sug-label { font-size: 12px; color: #909399; flex-shrink: 0; }
.sug-tag { cursor: pointer; }
.sug-tag:hover { border-color: #409eff; color: #409eff; }
</style>
