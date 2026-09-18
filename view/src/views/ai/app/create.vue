<!-- 文件：admin/src/views/ai/app/create.vue -->
<!-- 创建/编辑应用：三类型动态表单（智能体/工作流/对话）+ 资源预览 + 校验 -->
<template>
  <div class="app-create">
    <!-- 顶部 -->
    <div class="page-head">
      <el-breadcrumb separator="/">
        <el-breadcrumb-item>AI智能平台</el-breadcrumb-item>
        <el-breadcrumb-item>应用中心</el-breadcrumb-item>
        <el-breadcrumb-item>{{ isEdit ? '编辑应用' : '创建应用' }}</el-breadcrumb-item>
      </el-breadcrumb>
      <el-button size="small" icon="el-icon-back" @click="$router.push('/ai/app/list')">返回列表</el-button>
    </div>

    <!-- 表单 -->
    <el-form ref="form" :model="form" :rules="rules" label-width="140px" size="small">
      <!-- 一、基本信息 -->
      <el-card shadow="never" class="card">
        <div class="card-title">基本信息</div>
        <el-form-item label="应用名称" prop="appName">
          <el-input v-model="form.appName" placeholder="请输入应用名称（如 设备管理助手）" maxlength="100" style="max-width:480px" />
        </el-form-item>
        <el-form-item label="应用类型" prop="appType">
          <el-radio-group v-model="form.appType" :disabled="isEdit">
            <el-radio label="agent">智能体应用</el-radio>
            <el-radio label="workflow">工作流应用</el-radio>
            <el-radio label="chat">对话应用</el-radio>
          </el-radio-group>
          <div v-if="isEdit" class="type-tip">编辑模式下应用类型不可修改</div>
        </el-form-item>
        <el-form-item label="应用描述">
          <el-input v-model="form.description" type="textarea" :rows="3" placeholder="请描述应用的用途" maxlength="255" style="max-width:480px" />
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.enabled" active-text="启用" inactive-text="停用" />
        </el-form-item>
      </el-card>

      <!-- 二、应用配置（按类型动态显示） -->
      <el-card shadow="never" class="card">
        <div class="card-title">应用配置</div>

        <!-- 智能体应用 -->
        <template v-if="form.appType === 'agent'">
          <el-form-item label="选择智能体" prop="agentId">
            <el-select v-model="cfg.agent_id" filterable placeholder="请选择智能体" style="width:100%;max-width:480px;" @change="agentId = $event">
              <el-option v-for="a in agentOptions" :key="a.agent_id" :label="a.agent_name" :value="a.agent_id" />
            </el-select>
          </el-form-item>
          <div v-if="selectedAgent" class="preview-card">
            <div class="pv-name"><i class="el-icon-user"></i> {{ selectedAgent.agent_name }}</div>
            <div class="pv-desc">{{ selectedAgent.description || '暂无描述' }}</div>
            <div class="pv-meta">知识库 {{ selectedAgent.knowledge_count || 0 }} 个 · 工具 {{ selectedAgent.tool_count || 0 }} 个</div>
          </div>
        </template>

        <!-- 工作流应用 -->
        <template v-else-if="form.appType === 'workflow'">
          <el-form-item label="选择工作流" prop="workflowId">
            <el-select v-model="cfg.workflow_id" filterable placeholder="请选择工作流" style="width:100%;max-width:480px;" @change="workflowId = $event">
              <el-option v-for="w in workflowOptions" :key="w.workflow_id" :label="w.workflow_name" :value="w.workflow_id" />
            </el-select>
          </el-form-item>
          <div v-if="selectedWorkflow" class="preview-card">
            <div class="pv-name"><i class="el-icon-s-operation"></i> {{ selectedWorkflow.workflow_name }}</div>
            <div class="pv-desc">{{ selectedWorkflow.description || '暂无描述' }}</div>
            <div class="pv-meta">节点 {{ selectedWorkflow.node_count || 0 }} 个 · 触发方式 {{ selectedWorkflow.trigger_text || '-' }}</div>
          </div>
        </template>

        <!-- 对话应用 -->
        <template v-else>
          <el-form-item label="关联模型" prop="modelId">
            <el-select v-model="cfg.model_id" filterable placeholder="请选择模型" style="width:100%;max-width:480px;">
              <el-option v-for="m in modelOptions" :key="m.id" :label="m.model_name || m.name" :value="m.id" />
            </el-select>
          </el-form-item>
          <el-form-item label="系统提示词" prop="systemPrompt">
            <el-input v-model="cfg.system_prompt" type="textarea" :rows="6" maxlength="5000" show-word-limit
              placeholder="请设定AI的角色和行为，例如：你是一个专业的设备管理助手..." style="max-width:480px" />
          </el-form-item>
          <el-form-item label="绑定知识库">
            <el-select v-model="cfg.knowledge_base_ids" multiple filterable clearable placeholder="请选择知识库" style="width:100%;max-width:480px;">
              <el-option v-for="k in knowledgeOptions" :key="k.id" :label="k.kb_name || k.name" :value="k.id" />
            </el-select>
          </el-form-item>
          <el-form-item label="绑定工具">
            <el-select v-model="cfg.tool_ids" multiple filterable clearable placeholder="请选择工具" style="width:100%;max-width:480px;">
              <el-option v-for="t in toolOptions" :key="t.tool_name" :label="t.tool_display_name || t.tool_name" :value="t.id" />
            </el-select>
          </el-form-item>
          <el-form-item label="温度">
            <el-slider v-model="cfg.temperature" :min="0" :max="2" :step="0.1" show-input style="max-width:480px" />
          </el-form-item>
          <el-form-item label="最大输出Token">
            <el-input-number v-model="cfg.max_tokens" :min="1" :max="8192" />
          </el-form-item>
          <el-form-item label="流式输出">
            <el-switch v-model="cfg.stream" />
          </el-form-item>
        </template>
      </el-card>

      <!-- 三、配置摘要预览 -->
      <el-card shadow="never" class="card">
        <div class="card-title">配置摘要</div>
        <pre class="summary-pre">{{ configSummary }}</pre>
      </el-card>
    </el-form>

    <!-- 底部操作 -->
    <div class="footer-bar">
      <el-button size="small" @click="$router.push('/ai/app/list')">返回列表</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="doSave">保存</el-button>
    </div>
  </div>
</template>

<script>
import { addApp, editApp, getAppDetail } from '@/api/aiApp'
import request from '@/api/request'

export default {
  name: 'AiAppCreate',
  data () {
    return {
      isEdit: false, editId: 0, saving: false,
      form: { appName: '', appType: 'agent', description: '', enabled: true },
      cfg: { agent_id: '', workflow_id: '', model_id: '', system_prompt: '', knowledge_base_ids: [], tool_ids: [], temperature: 0.7, max_tokens: 4096, stream: true },
      agentId: '', workflowId: '',
      agentOptions: [], workflowOptions: [], modelOptions: [], knowledgeOptions: [], toolOptions: [],
      rules: {
        appName: [
          { required: true, message: '请输入应用名称', trigger: 'blur' },
          { min: 2, max: 100, message: '名称长度需为2-100字符', trigger: 'blur' },
          { validator: this.checkNameUnique, trigger: 'blur' }
        ],
        appType: [{ required: true, message: '请选择应用类型', trigger: 'change' }],
        agentId: [{ required: true, message: '请选择智能体', trigger: 'change' }],
        workflowId: [{ required: true, message: '请选择工作流', trigger: 'change' }],
        modelId: [{ required: true, message: '请选择模型', trigger: 'change' }],
        systemPrompt: [
          { required: true, message: '请输入系统提示词', trigger: 'blur' },
          { min: 10, max: 5000, message: '系统提示词长度需为10-5000字符', trigger: 'blur' }
        ]
      }
    }
  },
  computed: {
    selectedAgent () { return this.agentOptions.find(a => a.agent_id === this.cfg.agent_id) || null },
    selectedWorkflow () { return this.workflowOptions.find(w => w.workflow_id === this.cfg.workflow_id) || null },
    configSummary () {
      const c = this.cfg
      if (this.form.appType === 'agent') return JSON.stringify({ agent_id: c.agent_id }, null, 2)
      if (this.form.appType === 'workflow') return JSON.stringify({ workflow_id: c.workflow_id }, null, 2)
      return JSON.stringify({
        model_id: c.model_id, system_prompt: c.system_prompt,
        knowledge_base_ids: c.knowledge_base_ids, tool_ids: c.tool_ids,
        temperature: c.temperature, max_tokens: c.max_tokens, stream: c.stream
      }, null, 2)
    }
  },
  watch: {
    // 切换应用类型时清空配置
    'form.appType' () {
      this.cfg = { agent_id: '', workflow_id: '', model_id: '', system_prompt: '', knowledge_base_ids: [], tool_ids: [], temperature: 0.7, max_tokens: 4096, stream: true }
    }
  },
  async created () {
    await this.loadOptions()
    const id = this.$route.query.id
    if (id) {
      this.isEdit = true
      this.editId = Number(id)
      await this.loadApp(id)
    }
  },
  methods: {
    async loadOptions () {
      const jobs = [
        request({ url: '/ai/agent/options', method: 'get' }).then(r => { if (r.code === 0) this.agentOptions = r.data || [] }).catch(() => {}),
        request({ url: '/ai/workflow/options', method: 'get' }).then(r => { if (r.code === 0) this.workflowOptions = r.data || [] }).catch(() => {}),
        request({ url: '/ai/model/options', method: 'get' }).then(r => { if (r.code === 0) this.modelOptions = r.data || [] }).catch(() => {}),
        request({ url: '/ai/knowledge/options', method: 'get' }).then(r => { if (r.code === 0) this.knowledgeOptions = r.data || [] }).catch(() => {}),
        request({ url: '/ai/tools/options', method: 'get' }).then(r => { if (r.code === 0) this.toolOptions = r.data || [] }).catch(() => {})
      ]
      await Promise.all(jobs)
    },
    async loadApp (id) {
      try {
        const r = await getAppDetail(id)
        if (r.code === 0) {
          const d = r.data
          this.form.appName = d.app_name || ''
          this.form.appType = d.app_type || 'agent'
          this.form.description = d.description || ''
          this.form.enabled = Number(d.status) === 1
          const c = d.config || {}
          this.cfg = {
            agent_id: c.agent_id || '', workflow_id: c.workflow_id || '',
            model_id: c.model_id || '', system_prompt: c.system_prompt || '',
            knowledge_base_ids: c.knowledge_base_ids || [], tool_ids: c.tool_ids || [],
            temperature: c.temperature ?? 0.7, max_tokens: c.max_tokens || 4096, stream: c.stream !== false
          }
        }
      } catch (e) {}
    },
    // 应用名称异步唯一校验
    async checkNameUnique (rule, value, callback) {
      if (!value || value.trim().length < 2) { callback(); return }
      try {
        const r = await request({ url: '/ai/app/check-name', method: 'get', params: { name: value.trim(), exclude_id: this.isEdit ? this.editId : 0 } })
        if (r.code === 0 && r.data.exists) callback(new Error('应用名称已存在'))
        else callback()
      } catch (e) { callback() }
    },
    doSave () {
      this.$refs.form.validate(async (ok) => {
        if (!ok) { this.$message.warning('请完善表单必填项'); return }
        this.saving = true
        try {
          const payload = {
            app_name: this.form.appName.trim(),
            description: this.form.description,
            config: this.buildConfig(),
            status: this.form.enabled ? 1 : 0
          }
          let r
          if (this.isEdit) r = await editApp(this.editId, payload)
          else r = await addApp({ ...payload, app_type: this.form.appType })
          if (r.code === 0) {
            this.$message.success(this.isEdit ? '应用已更新' : '应用创建成功')
            this.$router.push('/ai/app/list')
          }
        } catch (e) {} finally { this.saving = false }
      })
    },
    buildConfig () {
      if (this.form.appType === 'agent') return { agent_id: this.cfg.agent_id }
      if (this.form.appType === 'workflow') return { workflow_id: this.cfg.workflow_id }
      return {
        model_id: this.cfg.model_id,
        system_prompt: this.cfg.system_prompt,
        knowledge_base_ids: this.cfg.knowledge_base_ids || [],
        tool_ids: this.cfg.tool_ids || [],
        temperature: this.cfg.temperature ?? 0.7,
        max_tokens: this.cfg.max_tokens || 4096,
        stream: this.cfg.stream !== false
      }
    }
  }
}
</script>

<style scoped>
.app-create { padding: 16px; max-width: 860px; }
.page-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; }
.card { margin-bottom: 14px; }
.card /deep/ .el-card__body { padding: 16px 20px 0; }
.card-title { font-size: 14px; font-weight: 600; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; margin-bottom: 16px; }
.type-tip { font-size: 12px; color: #909399; margin-top: 4px; }
.preview-card { background: #f0f7ff; border: 1px solid #d3e6ff; border-radius: 8px; padding: 12px 14px; margin: 0 0 18px 140px; max-width: 480px; }
.pv-name { font-size: 14px; font-weight: 600; color: #409EFF; }
.pv-desc { font-size: 13px; color: #606266; margin-top: 4px; }
.pv-meta { font-size: 12px; color: #909399; margin-top: 4px; }
.summary-pre { background: #f8f9fb; border-radius: 6px; padding: 12px; font-size: 12px; max-height: 260px; overflow: auto; white-space: pre-wrap; word-break: break-all; }
.footer-bar { display: flex; justify-content: flex-end; gap: 10px; padding: 12px 0; position: sticky; bottom: 0; background: #fff; border-top: 1px solid #ebeef5; }
</style>
