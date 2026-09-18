<!-- 文件：admin/src/views/ai/workflow/components/WorkflowCanvas.vue -->
<!-- 自研轻量画布：节点绝对定位 + SVG 连线 + 原生拖拽/缩放/平移/多选（无第三方图库依赖） -->
<template>
  <div class="wf-canvas"
    @dragover.prevent @drop="onDrop"
    @wheel.prevent="onWheel"
    @mousedown="onBlankDown" @mousemove="onMove" @mouseup="onUp"
    @contextmenu.prevent="onContextMenu" @keydown="onKeydown" tabindex="0">
    <!-- 缩放/平移指示 -->
    <div class="canvas-tip">缩放 {{ Math.round(scale * 100) }}%<span v-if="connectFrom"> · 连线模式：点击目标节点</span><span v-if="selectedIds.length > 1"> · 已选 {{ selectedIds.length }} 个节点</span></div>

    <!-- 内容层 -->
    <div class="canvas-content" :style="contentStyle">
      <!-- 连线 SVG -->
      <svg class="edge-layer" width="10000" height="10000">
        <path v-for="(e, i) in edges" :key="e.id || i" :d="edgePath(e)" fill="none"
          :stroke="e.id === activeEdgeId ? '#F56C6C' : '#409EFF'" stroke-width="2" class="edge-path"
          @click.stop="selectEdge(e)" @dblclick.stop="editEdgeLabel(e)" />
        <text v-for="(e, i) in edges" :key="'t' + (e.id || i)" :x="edgeMid(e).x" :y="edgeMid(e).y - 6"
          font-size="12" fill="#409EFF" text-anchor="middle" style="pointer-events:none;">{{ e.label || '' }}</text>
      </svg>

      <!-- 节点 -->
      <div v-for="node in nodes" :key="node.id"
        class="wf-node" :class="{ selected: selectedIds.includes(node.id), multi: selectedIds.length > 1 && selectedIds.includes(node.id) }"
        :style="{ left: node.position.x + 'px', top: node.position.y + 'px', borderColor: nodeColor(node) }"
        @mousedown.stop="onNodeDown($event, node)" @click.stop="onNodeClick($event, node)" @contextmenu.stop="onNodeContextMenu($event, node)">
        <div class="node-head" :style="{ background: nodeColor(node) }">
          <i :class="nodeIcon(node)"></i>
          <span class="node-title">{{ node.name || nodeTypeName(node) }}</span>
          <span class="node-type">{{ nodeTypeName(node) }}</span>
        </div>
        <!-- 输入端口 -->
        <div class="port port-in" :class="{ connectable: connectFrom && connectFrom !== node.id }" title="输入端口"></div>
        <!-- 输出端口（end 无输出） -->
        <div v-if="node.type !== 'end'" class="port port-out" :class="{ active: connectFrom === node.id }"
          title="点击进入连线模式" @mousedown.stop="onPortDown($event, node)"></div>
      </div>
    </div>

    <!-- 右键菜单 -->
    <div v-if="menu.visible" class="ctx-menu" :style="{ left: menu.x + 'px', top: menu.y + 'px' }">
      <div class="ctx-item" @click="ctxDelete">删除节点</div>
      <div class="ctx-item" @click="ctxCancel">取消</div>
    </div>
  </div>
</template>

<script>
import { getNodeType } from '../nodeTypes'

const NODE_W = 150
const NODE_H = 64

export default {
  name: 'WorkflowCanvas',
  props: {
    nodes: { type: Array, default: () => [] },
    edges: { type: Array, default: () => [] },
    selectedNodeId: { type: String, default: '' }
  },
  data () {
    return {
      scale: 1, panX: 40, panY: 40,
      connectFrom: '', activeEdgeId: '',
      selectedIds: [],
      dragNode: null, dragOffset: { x: 0, y: 0 }, dragOrigins: {},
      panning: false, panStart: { x: 0, y: 0 },
      menu: { visible: false, x: 0, y: 0, node: null }
    }
  },
  watch: {
    selectedNodeId (id) {
      // 外部（配置面板/删除）变更时同步单选状态
      if (id) this.selectedIds = [id]
    }
  },
  computed: {
    contentStyle () {
      return { transform: `translate(${this.panX}px, ${this.panY}px) scale(${this.scale})` }
    }
  },
  methods: {
    nodeColor (node) { return getNodeType(node.type).color },
    nodeIcon (node) { return getNodeType(node.type).icon },
    nodeTypeName (node) { return getNodeType(node.type).name },
    nodeById (id) { return this.nodes.find(n => n.id === id) || null },
    edgePath (e) {
      const s = this.nodeById(e.source); const t = this.nodeById(e.target)
      if (!s || !t) return ''
      const sx = s.position.x + NODE_W; const sy = s.position.y + NODE_H / 2
      const tx = t.position.x; const ty = t.position.y + NODE_H / 2
      const mx = (sx + tx) / 2
      return `M ${sx} ${sy} C ${mx} ${sy}, ${mx} ${ty}, ${tx} ${ty}`
    },
    edgeMid (e) {
      const s = this.nodeById(e.source); const t = this.nodeById(e.target)
      if (!s || !t) return { x: 0, y: 0 }
      return { x: (s.position.x + t.position.x + NODE_W) / 2, y: (s.position.y + t.position.y + NODE_H) / 2 }
    },
    // 节点拖拽（支持多选批量移动）
    onNodeDown (e, node) {
      if (!this.selectedIds.includes(node.id)) {
        // 未选中则单选
        this.selectedIds = [node.id]
        this.$emit('select', node.id)
      }
      this.dragNode = node
      this.dragOffset = { x: e.clientX - node.position.x, y: e.clientY - node.position.y }
      this.dragOrigins = {}
      for (const id of this.selectedIds) {
        const n = this.nodes.find(x => x.id === id)
        if (n) this.dragOrigins[id] = { x: n.position.x, y: n.position.y }
      }
    },
    onMove (e) {
      if (this.dragNode) {
        const dx = e.clientX - this.dragOffset.x - this.dragOrigins[this.dragNode.id].x
        const dy = e.clientY - this.dragOffset.y - this.dragOrigins[this.dragNode.id].y
        for (const id of Object.keys(this.dragOrigins)) {
          const n = this.nodes.find(x => x.id === id)
          if (n) {
            n.position = { x: Math.max(0, this.dragOrigins[id].x + dx), y: Math.max(0, this.dragOrigins[id].y + dy) }
          }
        }
      } else if (this.panning) {
        this.panX += e.clientX - this.panStart.x
        this.panY += e.clientY - this.panStart.y
        this.panStart = { x: e.clientX, y: e.clientY }
      }
    },
    onUp () { this.dragNode = null; this.panning = false; this.dragOrigins = {} },
    onBlankDown (e) {
      this.panning = true
      this.panStart = { x: e.clientX, y: e.clientY }
      this.selectedIds = []
      this.$emit('select', '')
    },
    onWheel (e) {
      const delta = e.deltaY > 0 ? 0.9 : 1.1
      this.scale = Math.min(2, Math.max(0.5, this.scale * delta))
    },
    onNodeClick (e, node) {
      if (this.connectFrom) {
        if (this.connectFrom !== node.id) this.$emit('add-edge', this.connectFrom, node.id)
        this.connectFrom = ''
        return
      }
      // Shift+点击：多选切换
      if (e.shiftKey) {
        const idx = this.selectedIds.indexOf(node.id)
        if (idx > -1) { this.selectedIds.splice(idx, 1); this.$emit('select', '') }
        else { this.selectedIds.push(node.id); this.$emit('select', node.id) }
      } else {
        this.selectedIds = [node.id]
        this.$emit('select', node.id)
      }
    },
    onPortDown (e, node) {
      e.stopPropagation()
      if (node.type === 'end') return
      this.connectFrom = this.connectFrom === node.id ? '' : node.id
      this.activeEdgeId = ''
    },
    selectEdge (e) {
      this.activeEdgeId = e.id || ''
      this.$emit('select-edge', e)
    },
    // 双击连线：编辑标签
    editEdgeLabel (e) {
      this.$emit('edit-edge', e)
    },
    // 删除（选中节点）
    onKeydown (e) {
      if ((e.key === 'Delete' || e.key === 'Backspace') && this.selectedIds.length) {
        this.$emit('delete-nodes', this.selectedIds.slice())
        this.selectedIds = []
      }
    },
    onNodeContextMenu (e, node) {
      this.menu = { visible: true, x: e.clientX, y: e.clientY, node }
    },
    onContextMenu (e) { this.menu = { visible: false, x: 0, y: 0, node: null } },
    ctxDelete () {
      if (this.menu.node) this.$emit('delete-node', this.menu.node.id)
      this.menu = { visible: false, x: 0, y: 0, node: null }
    },
    ctxCancel () { this.menu = { visible: false, x: 0, y: 0, node: null } },
    // 从节点库拖入
    onDrop (e) {
      const type = e.dataTransfer.getData('application/node-type')
      if (!type) return
      const rect = this.$el.getBoundingClientRect()
      const x = (e.clientX - rect.left - this.panX) / this.scale
      const y = (e.clientY - rect.top - this.panY) / this.scale
      this.$emit('add-node', type, Math.max(0, x - NODE_W / 2), Math.max(0, y - NODE_H / 2))
    }
  }
}
</script>

<style scoped>
.wf-canvas { position: relative; flex: 1; overflow: hidden; background: #f5f7fa; outline: none; }
.canvas-tip { position: absolute; top: 8px; left: 50%; transform: translateX(-50%); z-index: 20; background: rgba(0,0,0,.6); color: #fff; font-size: 12px; padding: 4px 10px; border-radius: 4px; pointer-events: none; white-space: nowrap; }
.canvas-content { position: absolute; left: 0; top: 0; transform-origin: 0 0; }
.edge-layer { position: absolute; left: 0; top: 0; pointer-events: none; }
.edge-layer .edge-path { pointer-events: stroke; cursor: pointer; }
.wf-node { position: absolute; width: 150px; min-height: 64px; background: #fff; border: 2px solid #dcdfe6; border-radius: 8px; box-shadow: 0 1px 4px rgba(0,0,0,.08); cursor: move; user-select: none; z-index: 5; }
.wf-node.selected { box-shadow: 0 0 0 2px #409EFF66, 0 2px 8px rgba(64,158,255,.3); z-index: 10; }
.wf-node.multi { box-shadow: 0 0 0 2px #67C23A66, 0 2px 8px rgba(103,194,58,.3); }
.node-head { display: flex; align-items: center; gap: 6px; padding: 6px 8px; color: #fff; border-radius: 6px 6px 0 0; font-size: 12px; }
.node-title { font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 90px; }
.node-type { font-size: 10px; opacity: .85; margin-left: auto; }
.port { position: absolute; width: 14px; height: 14px; border-radius: 50%; background: #fff; border: 2px solid #909399; top: 28px; z-index: 15; }
.port-in { left: -8px; }
.port-out { right: -8px; }
.port-out.active { background: #409EFF; border-color: #409EFF; }
.port.connectable { border-color: #67C23A; background: #67C23A; cursor: pointer; }
.ctx-menu { position: fixed; z-index: 9999; background: #fff; border: 1px solid #ebeef5; border-radius: 6px; box-shadow: 0 2px 8px rgba(0,0,0,.12); padding: 4px 0; }
.ctx-item { padding: 8px 16px; font-size: 13px; color: #303133; cursor: pointer; }
.ctx-item:hover { background: #f5f7fa; color: #F56C6C; }
</style>
