<!-- 引用来源展示：默认折叠前 2 条，可展开全部 -->
<template>
  <div v-if="sources && sources.length" class="src-wrap">
    <span class="src-label">📚 引用来源：</span>
    <span v-for="(s, i) in visibleSources" :key="i" class="src-item" @click="$emit('open', s)">
      {{ s.title || s.source || s.type }}
    </span>
    <el-button v-if="sources.length > 2" type="text" size="mini" class="src-more" @click="showAll = !showAll">
      {{ showAll ? '收起' : '查看全部 (' + sources.length + ')' }}
    </el-button>
  </div>
</template>

<script>
export default {
  name: 'AiSourcesDisplay',
  props: {
    sources: { type: Array, default: () => [] }
  },
  data () {
    return { showAll: false }
  },
  computed: {
    visibleSources () {
      return this.showAll ? this.sources : this.sources.slice(0, 2)
    }
  }
}
</script>

<style scoped>
.src-wrap { margin-top: 6px; display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.src-label { font-size: 12px; color: #909399; }
.src-item { font-size: 12px; color: #409eff; background: #ecf5ff; border-radius: 3px; padding: 1px 6px; cursor: pointer; }
.src-item:hover { background: #d9ecff; }
.src-more { margin-left: 4px; }
</style>
