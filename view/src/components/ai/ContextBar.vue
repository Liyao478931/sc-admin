<!-- 上下文信息栏：显示当前页面 / 数据量 / 时间范围 / 筛选条件，可清除 -->
<template>
  <div v-if="context" class="ctx-bar">
    <div class="ctx-main">
      <i class="el-icon-location-outline ctx-icon"></i>
      <span class="ctx-title">{{ context.pageTitle || context.route }}</span>
      <template v-if="expanded">
        <el-tag v-if="display.total" size="mini" class="ctx-tag">共 {{ display.total }} 条</el-tag>
        <el-tag v-if="display.timeRange" size="mini" type="success" class="ctx-tag">{{ display.timeRange }}</el-tag>
        <el-tag v-if="display.filters" size="mini" type="warning" class="ctx-tag">筛选：{{ display.filters }}</el-tag>
        <el-tag v-if="entityLabel" size="mini" type="info" class="ctx-tag">{{ entityLabel }}</el-tag>
      </template>
    </div>
    <div class="ctx-actions">
      <el-button type="text" size="mini" class="ctx-toggle" @click="expanded = !expanded">
        {{ expanded ? '收起' : '展开' }}
      </el-button>
      <i class="el-icon-close ctx-close" @click="$emit('clear')" title="清除上下文"></i>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AiContextBar',
  props: {
    context: { type: Object, default: null },
    dataSummary: { type: Object, default: null },
    filters: { type: Object, default: () => ({}) },
    entity: { type: Object, default: null }
  },
  data () {
    return { expanded: false }
  },
  computed: {
    display () {
      const ds = this.dataSummary || {}
      const f = this.filters || {}
      const fText = Object.keys(f).length ? Object.entries(f).map(([k, v]) => `${k}=${v}`).join(' ') : ''
      return {
        total: ds.total || '',
        timeRange: ds.time_range || '',
        filters: fText
      }
    },
    entityLabel () {
      const e = this.entity
      return e && e.id ? `${e.type || ''} #${e.id} ${e.name || ''}`.trim() : ''
    }
  },
  watch: {
    context () { this.expanded = false }
  }
}
</script>

<style scoped>
.ctx-bar { display: flex; align-items: center; justify-content: space-between; padding: 6px 12px;
  background: #f0f7ff; border: 1px solid #d0e4ff; border-radius: 6px; margin-bottom: 8px; flex-wrap: wrap; }
.ctx-main { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.ctx-icon { color: #409eff; }
.ctx-title { font-weight: 600; font-size: 13px; color: #303133; }
.ctx-tag { margin-right: 4px; }
.ctx-toggle { color: #409eff; }
.ctx-close { cursor: pointer; color: #909399; font-size: 14px; margin-left: 6px; }
.ctx-close:hover { color: #f56c6c; }
</style>
