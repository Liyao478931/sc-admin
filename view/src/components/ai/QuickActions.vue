<!-- 快捷操作按钮：一键分析/报告/导出 -->
<template>
  <div v-if="actions && actions.length" class="qa-wrap">
    <el-button
      v-for="a in visibleActions" :key="a.id" size="small"
      :type="a.type || 'default'" :icon="a.icon || 'el-icon-magic-stick'"
      :loading="!!loadingMap[a.id]" @click="$emit('run', a)">
      {{ a.label }}
    </el-button>
  </div>
</template>

<script>
export default {
  name: 'AiQuickActions',
  props: {
    actions: { type: Array, default: () => [] },
    loadingMap: { type: Object, default: () => ({}) }
  },
  computed: {
    visibleActions () {
      const perms = this.$store.state.user.permissions || []
      return (this.actions || []).filter(a => !a.permission || perms.includes(a.permission))
    }
  }
}
</script>

<style scoped>
.qa-wrap { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; margin-bottom: 8px; }
</style>
