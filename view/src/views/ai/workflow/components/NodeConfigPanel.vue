<!-- 文件：admin/src/views/ai/workflow/components/NodeConfigPanel.vue -->
<!-- 节点配置面板：根据节点类型动态渲染配置项 -->
<template>
  <div class="node-config">
    <div class="cfg-header">
      <i :class="nodeIcon" :style="{ color: nodeColor }"></i>
      <span>{{ nodeTitle }}</span>
      <el-button type="text" size="mini" @click="$emit('close')">收起</el-button>
    </div>

    <div v-if="!node" class="cfg-empty">点击画布中的节点进行配置</div>

    <el-form v-else :model="cfg" label-position="top" size="small">
      <!-- 开始/结束：只读 -->
      <template v-if="node.type === 'start' || node.type === 'end'">
        <div class="cfg-readonly">{{ node.type === 'start' ? '开始节点是工作流入口，无需配置。' : '结束节点是工作流出口，无需配置。' }}</div>
      </template>

      <!-- LLM 节点 -->
      <template v-else-if="node.type === 'llm'">
        <el-form-item label="模型">
          <el-select v-model="cfg.model_id" filterable placeholder="选择模型" style="width:100%">
            <el-option v-for="m in modelOptions" :key="m.id" :label="m.model_name || m.name" :value="m.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="系统提示词">
          <el-input v-model="cfg.system_prompt" type="textarea" :rows="3" placeholder="设定AI的角色和行为" />
        </el-form-item>
        <el-form-item label="用户提示词模板">
          <el-input v-model="cfg.user_prompt" type="textarea" :rows="4" placeholder="支持 {{变量名}} 引用，如：请回答：{{question}}" />
        </el-form-item>
        <el-form-item label="温度">
          <el-slider v-model="cfg.temperature" :min="0" :max="2" :step="0.1" show-input />
        </el-form-item>
        <el-form-item label="输出变量名">
          <el-input v-model="cfg.output_var" placeholder="定义输出结果存储的变量名" />
        </el-form-item>
      </template>

      <!-- 工具节点 -->
      <template v-else-if="node.type === 'tool'">
        <el-form-item label="工具">
          <el-select v-model="cfg.tool_name" filterable placeholder="选择工具" style="width:100%">
            <el-option v-for="t in toolOptions" :key="t.tool_name" :label="t.tool_display_name || t.tool_name" :value="t.tool_name" />
          </el-select>
        </el-form-item>
        <el-form-item label="参数映射">
          <div v-for="(v, k) in cfg.param_map || {}" :key="k" class="kv-row">
            <el-input :value="k" disabled size="mini" style="width:40%" />
            <el-input v-model="cfg.param_map[k]" size="mini" placeholder="变量引用，如 {{var}}" style="width:55%" />
          </div>
          <el-button v-if="!Object.keys(cfg.param_map || {}).length" type="text" size="mini" @click="cfg.param_map = { param: '' }">+ 添加参数</el-button>
        </el-form-item>
        <el-form-item label="输出变量名">
          <el-input v-model="cfg.output_var" placeholder="定义存储工具输出的变量名" />
        </el-form-item>
      </template>

      <!-- 条件节点 -->
      <template v-else-if="node.type === 'condition'">
        <el-form-item label="分支列表（至少2个）">
          <div v-for="(b, i) in cfg.branches || []" :key="i" class="branch-row">
            <el-input v-model="b.name" size="mini" placeholder="分支名称（如 是/否）" style="width:32%" />
            <el-input v-model="b.condition" size="mini" placeholder="条件表达式，如 {{score}} > 60" style="width:58%" />
            <el-button type="text" size="mini" icon="el-icon-delete" @click="removeBranch(i)" />
          </div>
          <el-button type="text" size="mini" icon="el-icon-plus" @click="addBranch">添加分支</el-button>
        </el-form-item>
      </template>

      <!-- 循环节点 -->
      <template v-else-if="node.type === 'loop'">
        <el-form-item label="循环类型">
          <el-select v-model="cfg.loop_type" style="width:100%">
            <el-option label="次数循环" value="count" />
            <el-option label="条件循环" value="condition" />
            <el-option label="列表循环" value="list" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="cfg.loop_type === 'count'" label="循环次数">
          <el-input-number v-model="cfg.count" :min="1" :max="1000" />
        </el-form-item>
        <el-form-item v-else-if="cfg.loop_type === 'condition'" label="循环条件">
          <el-input v-model="cfg.condition" placeholder="支持 {{变量名}} 引用" />
        </el-form-item>
        <el-form-item v-else label="列表变量">
          <el-select v-model="cfg.list_var" filterable placeholder="选择工作流变量" style="width:100%">
            <el-option v-for="v in variableNames" :key="v" :label="v" :value="v" />
          </el-select>
        </el-form-item>
        <el-form-item label="最大迭代次数">
          <el-input-number v-model="cfg.max_iter" :min="1" :max="10000" />
        </el-form-item>
      </template>

      <!-- 代码节点 -->
      <template v-else-if="node.type === 'code'">
        <el-form-item label="代码语言">
          <el-select v-model="cfg.language" style="width:100%">
            <el-option label="Python" value="python" />
            <el-option label="JavaScript" value="javascript" />
          </el-select>
        </el-form-item>
        <el-form-item label="代码内容">
          <el-input v-model="cfg.code" type="textarea" :rows="8" placeholder="写自定义代码（真实执行引擎接入后生效）" />
        </el-form-item>
        <el-form-item label="输出变量名">
          <el-input v-model="cfg.output_var" placeholder="定义存储代码输出的变量名" />
        </el-form-item>
      </template>

      <!-- 人工确认节点 -->
      <template v-else-if="node.type === 'human'">
        <el-form-item label="确认标题">
          <el-input v-model="cfg.title" placeholder="显示给用户的确认标题" />
        </el-form-item>
        <el-form-item label="确认描述">
          <el-input v-model="cfg.description" type="textarea" :rows="3" placeholder="显示给用户的确认内容" />
        </el-form-item>
        <el-form-item label="超时时间（秒）">
          <el-input-number v-model="cfg.timeout" :min="5" :max="86400" />
        </el-form-item>
      </template>

      <!-- 知识库检索节点 -->
      <template v-else-if="node.type === 'knowledge'">
        <el-form-item label="知识库">
          <el-select v-model="cfg.kb_id" filterable placeholder="选择知识库" style="width:100%">
            <el-option v-for="k in knowledgeOptions" :key="k.id" :label="k.kb_name || k.name" :value="k.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="检索数量">
          <el-input-number v-model="cfg.top_k" :min="1" :max="10" />
        </el-form-item>
        <el-form-item label="相似度阈值">
          <el-slider v-model="cfg.threshold" :min="0" :max="1" :step="0.01" show-input />
        </el-form-item>
        <el-form-item label="输出变量名">
          <el-input v-model="cfg.output_var" placeholder="定义存储检索结果的变量名" />
        </el-form-item>
      </template>

      <!-- 通知节点 -->
      <template v-else-if="node.type === 'notification'">
        <el-form-item label="通知渠道">
          <el-checkbox-group v-model="cfg.channels">
            <el-checkbox label="inbox">站内信</el-checkbox>
            <el-checkbox label="email">邮件</el-checkbox>
            <el-checkbox label="dingtalk">钉钉</el-checkbox>
            <el-checkbox label="workwx">企微</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
        <el-form-item label="接收人">
          <el-select v-model="cfg.receivers" multiple filterable placeholder="选择用户" style="width:100%">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="通知标题">
          <el-input v-model="cfg.title" placeholder="支持 {{变量名}} 引用" />
        </el-form-item>
        <el-form-item label="通知内容">
          <el-input v-model="cfg.content" type="textarea" :rows="4" placeholder="支持 {{变量名}} 引用" />
        </el-form-item>
      </template>
    </el-form>
  </div>
</template>

<script>
import { getNodeType } from '../nodeTypes'
import request from '@/api/request'

export default {
  name: 'NodeConfigPanel',
  props: {
    node: { type: Object, default: null },
    variables: { type: Object, default: () => ({}) }
  },
  data () {
    return {
      cfg: {},
      modelOptions: [], toolOptions: [], knowledgeOptions: [], userOptions: []
    }
  },
  computed: {
    nodeTitle () { return this.node ? (this.node.name || getNodeType(this.node.type).name) : '节点配置' },
    nodeIcon () { return this.node ? getNodeType(this.node.type).icon : 'el-icon-set-up' },
    nodeColor () { return this.node ? getNodeType(this.node.type).color : '#909399' },
    variableNames () { return Object.keys(this.variables || {}) }
  },
  watch: {
    node: {
      immediate: true,
      handler (n) {
        if (n) {
          this.cfg = (n.config && typeof n.config === 'object') ? JSON.parse(JSON.stringify(n.config)) : {}
        } else {
          this.cfg = {}
        }
      }
    },
    cfg: {
      deep: true,
      handler (val) {
        if (this.node) this.$emit('update-config', JSON.parse(JSON.stringify(val)))
      }
    }
  },
  created () { this.loadOptions() },
  methods: {
    async loadOptions () {
      try {
        const r = await request({ url: '/ai/model/options', method: 'get' })
        if (r.code === 0) this.modelOptions = r.data || []
      } catch (e) {}
      try {
        const r = await request({ url: '/ai/tools/options', method: 'get' })
        if (r.code === 0) this.toolOptions = r.data || []
      } catch (e) {}
      try {
        const r = await request({ url: '/ai/knowledge/options', method: 'get' })
        if (r.code === 0) this.knowledgeOptions = r.data || []
      } catch (e) {}
      try {
        const r = await request({ url: '/users', method: 'get', params: { page: 1, limit: 500 } })
        if (r.code === 0) this.userOptions = (r.data && r.data.list) || []
      } catch (e) {}
    },
    addBranch () {
      if (!this.cfg.branches) this.cfg.branches = []
      this.cfg.branches.push({ name: '', condition: '' })
    },
    removeBranch (i) { (this.cfg.branches || []).splice(i, 1) }
  }
}
</script>

<style scoped>
.node-config { width: 380px; height: 100%; background: #fff; border-left: 1px solid #ebeef5; display: flex; flex-direction: column; overflow: hidden; }
.cfg-header { display: flex; align-items: center; gap: 8px; padding: 10px 12px; border-bottom: 1px solid #ebeef5; font-size: 13px; font-weight: 600; color: #303133; }
.cfg-header .el-button { margin-left: auto; }
.cfg-empty { padding: 40px 20px; text-align: center; color: #909399; font-size: 13px; }
.cfg-readonly { padding: 20px; color: #909399; font-size: 13px; line-height: 1.8; }
.node-config /deep/ .el-form { padding: 12px; overflow-y: auto; flex: 1; }
.kv-row { display: flex; gap: 6px; margin-bottom: 6px; }
.branch-row { display: flex; gap: 6px; margin-bottom: 6px; align-items: center; }
</style>
