<!--
  文件：admin/src/views/hr/assessment/template/components/IndicatorNode.vue
  功能：指标树递归节点（分组/叶子，拖拽排序，操作按钮）
  注意：组件 name 必须为 AssessmentIndicatorNode，实现递归渲染
  视觉：对齐参考模板（📁分组黄 / 📄叶子蓝 / 分值徽标）
-->
<template>
  <div class="tree-node" :class="{ 'is-group': isGroup, 'is-leaf': !isGroup }">
    <div class="node-content" :style="{ paddingLeft: (depth * 24) + 'px' }">
      <span class="toggle-icon" @click.stop="toggleExpand">
        <i v-if="isGroup" :class="node._expanded ? 'el-icon-arrow-down' : 'el-icon-arrow-right'"></i>
        <i v-else style="visibility:hidden;">▸</i>
      </span>
      <i class="drag-handle el-icon-rank"></i>
      <span class="node-icon" :class="{ document: !isGroup }">{{ isGroup ? '📁' : '📄' }}</span>
      <span class="node-name" :class="{ 'node-disabled': node.status !== 1 }">
        {{ node.name }}
        <span v-if="isGroup" class="sub">({{ node.score }}分)</span>
      </span>
      <span class="node-score">{{ node.score }} 分</span>
      <el-switch
        v-permission="'assessment:template:edit'"
        v-if="canEdit"
        :value="node.status === 1"
        size="mini"
        @change="val => $emit('toggle', node, val)"
      />
      <span class="node-actions" v-if="canEdit" @click.stop>
        <el-button v-if="isGroup" type="text" size="mini" title="添加子项" @click="$emit('add-child', node)">添加子项</el-button>
        <el-button type="text" size="mini" title="编辑" @click="$emit('edit', node)">编辑</el-button>
        <el-button type="text" size="mini" title="复制" @click="$emit('duplicate', node)">复制</el-button>
        <el-button type="text" size="mini" class="danger" title="删除" @click="$emit('delete', node)">删除</el-button>
      </span>
    </div>

    <div v-if="isGroup && node._expanded" class="children-wrap">
      <draggable v-model="node.children" handle=".drag-handle" @end="onSortChildren" :key="'c' + node.id">
        <indicator-node
          v-for="child in node.children" :key="child.id"
          :node="child" :template-id="templateId" :can-edit="canEdit" :depth="depth + 1"
          @add-child="$emit('add-child', $event)"
          @edit="$emit('edit', $event)"
          @duplicate="$emit('duplicate', $event)"
          @delete="$emit('delete', $event)"
          @toggle="$emit('toggle', $event)"
          @sort="$emit('sort', $event)"
        />
      </draggable>
    </div>
  </div>
</template>

<script>
import draggable from 'vuedraggable'

export default {
  name: 'AssessmentIndicatorNode',
  components: { draggable },
  props: {
    node: { type: Object, required: true },
    templateId: { type: Number, default: 0 },
    canEdit: { type: Boolean, default: true },
    depth: { type: Number, default: 0 }
  },
  computed: {
    isGroup () {
      return !!(this.node.children && this.node.children.length) || !!this.node._isGroup
    }
  },
  methods: {
    toggleExpand () {
      if (!this.isGroup) return
      this.$set(this.node, '_expanded', !this.node._expanded)
    },
    onSortChildren () {
      this.$emit('sort', (this.node.children || []).map(c => c.id))
    }
  }
}
</script>

<style scoped>
.tree-node { user-select: none; padding: 2px 0; }
.node-content { display: flex; align-items: center; gap: 8px; padding: 6px 10px 6px 6px; border-radius: 8px; transition: background .15s; flex-wrap: wrap; }
.node-content:hover { background: #eef2f7; }
.is-group > .node-content { font-weight: 500; }
.toggle-icon { width: 20px; text-align: center; cursor: pointer; color: #8c8f9c; font-size: 14px; flex-shrink: 0; }
.drag-handle { color: #c0c4cc; cursor: grab; flex-shrink: 0; }
.node-icon { color: #ffb020; font-size: 16px; flex-shrink: 0; }
.node-icon.document { color: #1e6fff; }
.node-name { font-size: 14px; color: #1d2129; font-weight: 500; flex: 1; min-width: 80px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.node-name .sub { font-weight: 400; color: #4e5a6b; }
.node-disabled { color: #c0c4cc; text-decoration: line-through; }
.node-score { font-size: 13px; color: #4e5a6b; background: #e8ecf1; padding: 0 10px; border-radius: 12px; line-height: 22px; white-space: nowrap; flex-shrink: 0; }
.node-actions { display: none; align-items: center; gap: 2px; flex-wrap: wrap; }
.node-actions >>> .el-button--text { padding: 2px 6px; font-size: 12px; color: #8c8f9c; }
.node-actions >>> .el-button--text:hover { color: #1e6fff; }
.node-content:hover .node-actions { display: inline-flex; }
.children-wrap { padding-left: 28px; }
.danger { color: #F56C6C !important; }
</style>
