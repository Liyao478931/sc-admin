<!-- 文件：admin/src/views/ai/workflow/create.vue -->
<template>
  <div class="wf-create">
    <!-- 顶部工具栏 -->
    <div class="wf-toolbar">
      <div class="tb-left">
        <el-button size="small" icon="el-icon-back" @click="$router.push('/ai/workflow/list')">返回列表</el-button>
        <span class="tb-title">{{ isEdit ? '编辑工作流' : '创建工作流' }}</span>
      </div>
      <div class="tb-form">
        <el-input v-model="workflowName" placeholder="工作流名称（必填）" size="small" style="width:220px" maxlength="100" />
        <el-select v-model="triggerType" size="small" style="width:130px" placeholder="触发方式">
          <el-option label="手动触发" value="manual" />
          <el-option label="定时触发" value="schedule" />
          <el-option label="Webhook触发" value="webhook" />
          <el-option label="事件触发" value="event" />
        </el-select>
        <!-- 触发配置（动态） -->
        <el-input v-if="triggerType === 'schedule'" v-model="triggerCfg.cron" size="small" placeholder="Cron表达式，如 0 8 * * *" style="width:220px" />
        <div v-else-if="triggerType === 'webhook'" class="webhook-url" size="small">
          Webhook: <code>{{ webhookUrl }}</code>
        </div>
        <el-select v-else-if="triggerType === 'event'" v-model="triggerCfg.event_type" size="small" style="width:150px" placeholder="事件类型">
          <el-option label="隐患创建" value="hazard_create" />
          <el-option label="工单创建" value="repair_order_create" />
          <el-option label="事故上报" value="accident_report" />
        </el-select>
      </div>
      <div class="tb-right">
        <el-switch v-model="enabled" active-text="启用" inactive-text="停用" style="margin-right:12px" />
        <el-button size="small" icon="el-icon-s-operation" @click="autoLayout">自动布局</el-button>
        <el-button size="small" icon="el-icon-video-play" @click="doDebug">调试运行</el-button>
        <el-button size="small" icon="el-icon-view" @click="doValidate">验证</el-button>
        <el-button size="small" :loading="saving" @click="doSave(0)">保存草稿</el-button>
        <el-button size="small" type="primary" icon="el-icon-check" :loading="saving" @click="doSave(1)">发布</el-button>
      </div>
    </div>

    <!-- 主体：节点库 + 画布 + 配置面板 -->
    <div class="wf-body">
      <node-library :existing-types="existingTypes" @add="addNodeFromLibrary" />

      <workflow-canvas ref="canvas" :nodes="nodes" :edges="edges" :selected-node-id="selectedNodeId"
        @select="onSelect" @update-position="onUpdatePosition" @add-node="onAddNode"
        @add-edge="onAddEdge" @delete-node="onDeleteNode" @delete-nodes="onDeleteNodes" @edit-edge="editEdgeLabel" />

      <node-config-panel v-if="selectedNode" :node="selectedNode" :variables="variables"
        @close="selectedNodeId = ''" @update-config="onUpdateNodeConfig" />
    </div>

    <!-- 底部：变量面板 -->
    <div class="wf-vars">
      <span class="vars-title"><i class="el-icon-s-data"></i> 工作流变量（{{ Object.keys(variables).length }}）</span>
      <el-tag v-for="(info, v) in variables" :key="v" size="small" class="var-tag">{{ v }}<span class="var-src">{{ info.source }}</span></el-tag>
      <span class="vars-tip">提示：拖拽左侧节点到画布，点击输出端口再点击目标节点建立连线</span>
    </div>
  </div>
</template>

<script>
import { NODE_TYPES, genNodeId, getNodeType } from './nodeTypes'
import { addWorkflow, editWorkflow, getWorkflowDetail, validateWorkflow } from '@/api/aiWorkflow'
import NodeLibrary from './components/NodeLibrary.vue'
import WorkflowCanvas from './components/WorkflowCanvas.vue'
import NodeConfigPanel from './components/NodeConfigPanel.vue'

export default {
  name: 'AiWorkflowCreate',
  components: { NodeLibrary, WorkflowCanvas, NodeConfigPanel },
  data () {
    return {
      isEdit: false, editId: 0,
      workflowName: '', description: '', triggerType: 'manual', enabled: true,
      triggerCfg: { cron: '', event_type: '' },
      nodes: [], edges: [], variables: {},
      selectedNodeId: '', saving: false
    }
  },
  computed: {
    existingTypes () { return this.nodes.map(n => n.type) },
    selectedNode () { return this.nodes.find(n => n.id === this.selectedNodeId) || null },
    webhookUrl () {
      // 生成一个稳定的 Webhook 路径（真实触发由执行引擎接入后生效）
      return '/api/ai/workflow/hook/' + (this.editId || 'new')
    }
  },
  async created () {
    const id = this.$route.query.id
    if (id) {
      this.isEdit = true
      this.editId = Number(id)
      await this.loadWorkflow(id)
    } else {
      // 新工作流：预置开始/结束节点
      this.nodes = [
        { id: genNodeId('start'), type: 'start', name: '开始', position: { x: 120, y: 220 }, config: {} },
        { id: genNodeId('end'), type: 'end', name: '结束', position: { x: 700, y: 220 }, config: {} }
      ]
    }
  },
  methods: {
    async loadWorkflow (id) {
      try {
        const r = await getWorkflowDetail(id)
        if (r.code === 0) {
          const d = r.data
          this.workflowName = d.workflow_name || ''
          this.description = d.description || ''
          this.triggerType = d.trigger_type || 'manual'
          this.enabled = Number(d.status) === 1
          this.triggerCfg = (d.trigger_config && typeof d.trigger_config === 'object') ? JSON.parse(JSON.stringify(d.trigger_config)) : {}
          const cfg = d.config || {}
          this.nodes = Array.isArray(cfg.nodes) ? cfg.nodes : []
          this.edges = Array.isArray(cfg.edges) ? cfg.edges : []
          this.variables = (cfg.variables && typeof cfg.variables === 'object') ? cfg.variables : {}
        }
      } catch (e) {}
    },
    // 节点库点击添加（画布中心附近）
    addNodeFromLibrary (type) {
      this.onAddNode(type, 400 + Math.random() * 60, 200 + Math.random() * 40)
    },
    onAddNode (type, x, y) {
      if ((type === 'start' || type === 'end') && this.existingTypes.includes(type)) {
        this.$message.warning(`${NODE_TYPES[type].name}节点已存在`)
        return
      }
      const node = {
        id: genNodeId(type),
        type,
        name: NODE_TYPES[type].name,
        position: { x, y },
        config: JSON.parse(JSON.stringify(NODE_TYPES[type].defaultConfig))
      }
      this.nodes.push(node)
      this.selectedNodeId = node.id
    },
    onUpdatePosition (id, pos) {
      const n = this.nodes.find(x => x.id === id)
      if (n) n.position = pos
    },
    onAddEdge (source, target) {
      // 防重复/自环
      if (source === target) return
      if (this.edges.some(e => e.source === source && e.target === target)) return
      this.edges.push({ source, target, label: '', id: 'edge_' + Date.now().toString(36) })
    },
    onDeleteNode (id) {
      this.nodes = this.nodes.filter(n => n.id !== id)
      this.edges = this.edges.filter(e => e.source !== id && e.target !== id)
      if (this.selectedNodeId === id) this.selectedNodeId = ''
    },
    onSelect (id) { this.selectedNodeId = id },
    onUpdateNodeConfig (cfg) {
      const n = this.selectedNode
      if (n) n.config = cfg
      this.collectVariables()
    },
    // 收集变量：节点输出变量 + 系统变量
    collectVariables () {
      const vars = {}
      for (const n of this.nodes) {
        const out = n.config && n.config.output_var
        if (out) vars[out] = { type: 'any', source: getNodeType(n.type).name + '#' + n.id.slice(-4) }
      }
      vars.current_time = { type: 'string', source: '系统' }
      vars.current_user = { type: 'string', source: '系统' }
      this.variables = vars
    },
    buildConfig () {
      return { nodes: this.nodes, edges: this.edges, variables: this.variables }
    },
    async doValidate () {
      if (!this.workflowName.trim()) { this.$message.warning('请填写工作流名称'); return }
      this.$message.info('正在验证工作流配置...')
      try {
        const r = await validateWorkflow(this.buildConfig())
        if (r.code === 0) {
          if (r.data.valid) {
            this.$message.success('工作流配置有效')
          } else {
            const errs = r.data.errors || []
            this.$alert(errs.map(e => '· ' + e).join('\n'), '配置校验未通过', { type: 'error', dangerouslyUseHTMLString: false })
          }
        }
      } catch (e) {}
    },
    async doSave (status) {
      if (!this.workflowName.trim()) { this.$message.warning('请填写工作流名称'); return }
      // 发布前完整校验；保存草稿允许未完成配置
      if (status === 1) {
        const startCount = this.nodes.filter(n => n.type === 'start').length
        const endCount = this.nodes.filter(n => n.type === 'end').length
        if (startCount !== 1 || endCount !== 1) {
          this.$message.warning('工作流必须包含且仅包含一个开始节点和一个结束节点')
          return
        }
      }
      this.saving = true
      try {
        const payload = {
          workflow_name: this.workflowName.trim(),
          description: this.description,
          trigger_type: this.triggerType,
          trigger_config: this.triggerType === 'manual' ? {} : this.triggerCfg,
          config: this.buildConfig(),
          status: status === 1 ? (this.enabled ? 1 : 0) : 0
        }
        let r
        if (this.isEdit) {
          r = await editWorkflow(this.editId, payload)
        } else {
          r = await addWorkflow(payload)
        }
        if (r.code === 0) {
          this.$message.success(status === 1 ? '工作流已发布' : '草稿已保存')
          this.$router.push('/ai/workflow/list')
        }
      } catch (e) {} finally { this.saving = false }
    },
    // 批量删除节点（多选）
    onDeleteNodes (ids) {
      this.nodes = this.nodes.filter(n => !ids.includes(n.id))
      this.edges = this.edges.filter(e => !ids.includes(e.source) && !ids.includes(e.target))
      if (ids.includes(this.selectedNodeId)) this.selectedNodeId = ''
    },
    // 双击连线编辑标签（如条件分支：是/否）
    editEdgeLabel (edge) {
      this.$prompt('设置连线标签（如条件分支：是/否）', '连线标签', {
        inputValue: edge.label || '',
        inputPlaceholder: '留空表示无标签'
      }).then(({ value }) => {
        edge.label = value || ''
        this.$forceUpdate()
      }).catch(() => {})
    },
    // 自动布局：按拓扑分层（BFS from start）垂直居中排列
    autoLayout () {
      if (!this.nodes.length) return
      const adj = {}
      for (const e of this.edges) { (adj[e.source] = adj[e.source] || []).push(e.target) }
      const layers = {}
      const visited = {}
      const queue = []
      const startNode = this.nodes.find(n => n.type === 'start')
      if (startNode) { layers[startNode.id] = 0; queue.push(startNode.id); visited[startNode.id] = true }
      while (queue.length) {
        const cur = queue.shift()
        for (const next of (adj[cur] || [])) {
          if (!visited[next]) {
            visited[next] = true
            layers[next] = (layers[cur] || 0) + 1
            queue.push(next)
          }
        }
      }
      let maxLayer = 0
      for (const n of this.nodes) {
        if (layers[n.id] === undefined) layers[n.id] = 999
        else maxLayer = Math.max(maxLayer, layers[n.id])
      }
      const layerNodes = {}
      for (const n of this.nodes) {
        const l = layers[n.id] === 999 ? maxLayer + 1 : layers[n.id]
        layers[n.id] = l
        ;(layerNodes[l] = layerNodes[l] || []).push(n)
      }
      const totalHeight = this.nodes.length * 120
      for (const l of Object.keys(layerNodes)) {
        const arr = layerNodes[l]
        arr.forEach((n, i) => {
          n.position = {
            x: 120 + Number(l) * 260,
            y: (totalHeight - arr.length * 120) / 2 + i * 120 + 40
          }
        })
      }
      this.$message.success('已自动布局')
    },
    doDebug () {
      this.$message.info('调试执行引擎待接入：真实节点执行引擎开发完成后，此处将支持断点/单步调试')
    }
  }
}
</script>

<style scoped>
.wf-create { display: flex; flex-direction: column; height: calc(100vh - 84px); background: #fff; }
.wf-toolbar { display: flex; align-items: center; justify-content: space-between; gap: 10px; padding: 8px 14px; border-bottom: 1px solid #ebeef5; flex-wrap: wrap; }
.tb-left { display: flex; align-items: center; gap: 10px; }
.tb-title { font-size: 15px; font-weight: 600; color: #303133; }
.tb-form { display: flex; align-items: center; gap: 8px; flex: 1; flex-wrap: wrap; }
.tb-right { display: flex; align-items: center; }
.webhook-url { font-size: 12px; color: #606266; }
.webhook-url code { background: #f5f7fa; padding: 2px 6px; border-radius: 4px; color: #E6A23C; }
.wf-body { flex: 1; display: flex; min-height: 0; }
.wf-vars { display: flex; align-items: center; gap: 8px; padding: 8px 14px; border-top: 1px solid #ebeef5; background: #fafbfc; flex-wrap: wrap; }
.vars-title { font-size: 13px; font-weight: 600; color: #303133; }
.var-tag { margin-right: 4px; }
.var-src { color: #909399; font-size: 11px; margin-left: 4px; }
.vars-tip { margin-left: auto; font-size: 12px; color: #909399; }
</style>
