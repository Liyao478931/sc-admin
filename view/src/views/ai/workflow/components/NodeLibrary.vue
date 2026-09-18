<!-- 文件：admin/src/views/ai/workflow/components/NodeLibrary.vue -->
<template>
  <div class="node-library">
    <div class="lib-header"><i class="el-icon-s-grid"></i> 节点库</div>
    <el-collapse v-model="openGroups" accordion>
      <el-collapse-item v-for="group in NODE_GROUPS" :key="group" :name="group" :title="group">
        <div v-for="(type, key) in NODE_TYPES" :key="key"
          v-if="NODE_TYPES[key].group === group"
          class="lib-node"
          draggable="true"
          @dragstart="onDragStart($event, key)"
          @click="onAdd(key)">
          <i class="lib-node-icon" :style="{ background: NODE_TYPES[key].color + '1a', color: NODE_TYPES[key].color }">
            <i :class="NODE_TYPES[key].icon"></i>
          </i>
          <div class="lib-node-info">
            <div class="lib-node-name">{{ NODE_TYPES[key].name }}</div>
            <div class="lib-node-desc">{{ NODE_TYPES[key].desc }}</div>
          </div>
        </div>
      </el-collapse-item>
    </el-collapse>
  </div>
</template>

<script>
import { NODE_TYPES, NODE_GROUPS } from '../nodeTypes'

export default {
  name: 'NodeLibrary',
  props: {
    // 可选：限制可添加的节点类型（如已存在 start/end 时禁用重复添加）
    existingTypes: { type: Array, default: () => [] }
  },
  data () {
    return { NODE_TYPES, NODE_GROUPS, openGroups: ['基础节点'] }
  },
  methods: {
    onDragStart (e, type) {
      // 开始/结束节点已有则禁止重复拖入
      if ((type === 'start' || type === 'end') && this.existingTypes.includes(type)) {
        e.preventDefault()
        this.$message.warning(`${NODE_TYPES[type].name}节点已存在`)
        return
      }
      e.dataTransfer.setData('application/node-type', type)
      e.dataTransfer.effectAllowed = 'copy'
    },
    onAdd (type) {
      if ((type === 'start' || type === 'end') && this.existingTypes.includes(type)) {
        this.$message.warning(`${NODE_TYPES[type].name}节点已存在`)
        return
      }
      this.$emit('add', type)
    }
  }
}
</script>

<style scoped>
.node-library { display: flex; flex-direction: column; height: 100%; background: #fff; border-right: 1px solid #ebeef5; }
.lib-header { padding: 10px 12px; font-size: 13px; font-weight: 600; color: #303133; border-bottom: 1px solid #ebeef5; }
.node-library /deep/ .el-collapse { border: none; }
.node-library /deep/ .el-collapse-item__header { font-size: 13px; height: 36px; line-height: 36px; padding-left: 12px; }
.node-library /deep/ .el-collapse-item__content { padding: 4px 10px 10px; }
.lib-node { display: flex; align-items: center; gap: 8px; padding: 8px 10px; border: 1px solid #ebeef5; border-radius: 6px; margin-bottom: 8px; cursor: grab; transition: all .15s; }
.lib-node:hover { border-color: #409EFF; box-shadow: 0 1px 4px rgba(64,158,255,.2); }
.lib-node:active { cursor: grabbing; }
.lib-node-icon { width: 30px; height: 30px; border-radius: 6px; display: flex; align-items: center; justify-content: center; font-size: 16px; flex-shrink: 0; }
.lib-node-name { font-size: 13px; color: #303133; font-weight: 500; }
.lib-node-desc { font-size: 11px; color: #909399; margin-top: 2px; }
</style>
