<!-- 文件：admin/src/views/ai/agent/components/AgentFormDialog.vue -->
<!-- 创建/编辑智能体弹窗（支持双模式，父组件传入 visible / agentId） -->
<template>
  <el-dialog :title="agentId ? '编辑智能体' : '创建智能体'" :visible="visible" width="700px" top="5vh"
    @update:visible="v => $emit('update:visible', v)" @closed="resetForm">
    <el-form :model="form" :rules="formRules" ref="agentForm" label-width="120px" size="small">
      <el-form-item label="智能体名称" prop="agent_name">
        <el-input v-model="form.agent_name" placeholder="请输入智能体名称" maxlength="100" show-word-limit />
      </el-form-item>
      <el-form-item label="描述">
        <el-input v-model="form.description" type="textarea" :rows="2" placeholder="请输入智能体描述（选填）" maxlength="255" show-word-limit />
      </el-form-item>
      <el-form-item label="系统提示词" prop="system_prompt">
        <el-input v-model="form.system_prompt" type="textarea" :rows="6" maxlength="5000" show-word-limit
          placeholder="请设定智能体的角色和人设，例如：你是一个专业的设备管理助手..." />
      </el-form-item>
      <el-form-item label="关联模型" prop="model_id">
        <el-select v-model="form.model_id" placeholder="请选择模型" style="width:100%" filterable>
          <el-option v-for="m in modelOptions" :key="m.id" :label="m.model_name" :value="m.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="绑定知识库">
        <el-select v-model="form.knowledge_base_ids" multiple filterable collapse-tags clearable placeholder="请选择知识库（已完成向量化）" style="width:100%">
          <el-option v-for="kb in kbOptions" :key="kb.id" :label="kb.kb_name" :value="kb.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="绑定工具">
        <el-select v-model="form.tool_ids" multiple filterable collapse-tags clearable placeholder="请选择工具（已启用）" style="width:100%">
          <el-option v-for="t in toolOptions" :key="t.id" :label="t.tool_display_name || t.tool_name" :value="t.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="状态">
        <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
      </el-form-item>
    </el-form>
    <span slot="footer">
      <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
      <el-button size="small" type="primary" :loading="submitting" @click="submitForm">
        {{ agentId ? '确认修改' : '确认创建' }}
      </el-button>
    </span>
  </el-dialog>
</template>

<script>
import { getAiModelOptions } from '@/api/aiModel'
import { getAiKnowledgeOptions } from '@/api/aiKnowledge'
import { getAiToolOptions } from '@/api/aiTool'
import { addAiAgent, editAiAgent, getAiAgentDetail, checkAiAgentName } from '@/api/aiAgent'

export default {
  name: 'AgentFormDialog',
  props: {
    visible: { type: Boolean, default: false },
    agentId: { type: [Number, String], default: 0 }
  },
  data () {
    return {
      form: { agent_name: '', description: '', system_prompt: '', model_id: null, knowledge_base_ids: [], tool_ids: [], status: 1 },
      modelOptions: [], kbOptions: [], toolOptions: [],
      submitting: false
    }
  },
  computed: {
    formRules () {
      return {
        agent_name: [
          { required: true, message: '请输入智能体名称', trigger: 'blur' },
          { validator: this.validateName, trigger: 'blur' }
        ],
        system_prompt: [
          { required: true, message: '请设定系统提示词（人设）', trigger: 'blur' },
          { min: 10, max: 5000, message: '长度需为10-5000字符', trigger: 'blur' }
        ],
        model_id: [{ required: true, message: '请选择关联模型', trigger: 'change' }]
      }
    }
  },
  watch: {
    async visible (v) {
      if (v) {
        // 先加载下拉选项，再回填详情，避免选项未就绪导致回填不匹配
        await this.loadOptions()
        if (this.agentId) this.loadDetail()
        else this.resetForm()
      }
    }
  },
  methods: {
    /** 名称异步唯一性校验（编辑时排除自身） */
    async validateName (rule, value, callback) {
      const name = (value || '').trim()
      if (name === '') return callback(new Error('请输入智能体名称'))
      if (name.length < 2 || name.length > 100) return callback(new Error('长度需为2-100字符'))
      try {
        const r = await checkAiAgentName(name, this.agentId || undefined)
        if (r.code === 0 && r.data && r.data.exists) return callback(new Error('智能体名称已存在'))
        callback()
      } catch (e) { callback() }
    },
    resetForm () {
      this.form = { agent_name: '', description: '', system_prompt: '', model_id: null, knowledge_base_ids: [], tool_ids: [], status: 1 }
      this.submitting = false
      if (this.$refs.agentForm) this.$refs.agentForm.clearValidate()
    },
    async loadOptions () {
      try {
        const [mr, kr, tr] = await Promise.all([
          getAiModelOptions(),
          getAiKnowledgeOptions(),
          getAiToolOptions()
        ])
        if (mr.code === 0) this.modelOptions = Array.isArray(mr.data) ? mr.data : (mr.data.list || [])
        if (kr.code === 0) this.kbOptions = Array.isArray(kr.data) ? kr.data : (kr.data.list || [])
        if (tr.code === 0) this.toolOptions = Array.isArray(tr.data) ? tr.data : (tr.data.list || [])
      } catch (e) {}
    },
    async loadDetail () {
      try {
        const r = await getAiAgentDetail(this.agentId)
        if (r.code === 0) {
          const d = r.data
          this.form = {
            agent_name: d.agent_name, description: d.description || '',
            system_prompt: d.system_prompt, model_id: d.model_id,
            knowledge_base_ids: d.knowledge_base_ids || [], tool_ids: d.tool_ids || [], status: d.status
          }
          this.$nextTick(() => { if (this.$refs.agentForm) this.$refs.agentForm.clearValidate() })
        }
      } catch (e) {}
    },
    async submitForm () {
      const ok = await this.$refs.agentForm.validate().catch(() => false)
      if (!ok) return
      this.submitting = true
      try {
        const payload = {
          agent_name: this.form.agent_name,
          description: this.form.description,
          system_prompt: this.form.system_prompt,
          model_id: this.form.model_id,
          knowledge_base_ids: this.form.knowledge_base_ids,
          tool_ids: this.form.tool_ids,
          status: this.form.status
        }
        const r = this.agentId ? await editAiAgent(this.agentId, payload) : await addAiAgent(payload)
        if (r.code === 0) {
          this.$message.success(this.agentId ? '智能体已更新' : '智能体创建成功')
          this.$emit('saved')
          this.$emit('update:visible', false)
        }
      } catch (e) {} finally { this.submitting = false }
    }
  }
}
</script>
