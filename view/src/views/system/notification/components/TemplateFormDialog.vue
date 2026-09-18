<template>
  <el-dialog :title="formId ? '编辑消息模板' : '新增消息模板'" :visible="visible" @update:visible="$emit('update:visible', $event)" width="750px" top="6vh" :close-on-click-modal="false" @closed="reset">
    <el-form ref="form" :model="form" label-width="120px" size="small" :rules="rules">
      <!-- 基本信息 -->
      <div class="section-title">基本信息</div>
      <el-row :gutter="16">
        <el-col :span="12">
          <el-form-item label="模板名称" prop="template_name">
            <el-input v-model="form.template_name" placeholder="请输入模板名称" maxlength="100" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="模板类型" prop="template_type">
            <el-select v-model="form.template_type" placeholder="请选择模板类型" style="width:100%">
              <el-option v-for="(t, k) in TYPE_MAP" :key="k" :label="t.label" :value="Number(k)" />
            </el-select>
          </el-form-item>
        </el-col>
      </el-row>
      <el-form-item label="模板用途">
        <el-input v-model="form.purpose" placeholder="请输入模板用途说明（选填）" maxlength="255" />
      </el-form-item>

      <!-- 模板内容 -->
      <div class="section-title">模板内容</div>
      <el-form-item label="标题模板" prop="title_template">
        <el-input ref="title_template" v-model="form.title_template" placeholder="请输入消息标题模板（支持变量占位符，如 {username} 的培训通知）" maxlength="200" @focus="focusField('title_template')" />
      </el-form-item>
      <el-form-item label="内容模板" prop="content_template">
        <el-input ref="content_template" v-model="form.content_template" type="textarea" :rows="6" placeholder="请输入消息内容模板（支持变量占位符和HTML，如 您好 {username}，{training_name} 将于 {deadline} 开始…）" @focus="focusField('content_template')" />
      </el-form-item>

      <!-- 变量管理 -->
      <div class="section-title">变量管理</div>
      <el-form-item label="可用变量">
        <div class="var-list">
          <el-tag v-for="v in allVariables" :key="v.name" size="small" class="var-tag" :title="v.desc" @click="insertVar(v.name)">
            {{ '{' + v.name + '}' }} <span class="var-desc">{{ v.desc }}</span>
          </el-tag>
          <span class="var-tip">（点击变量插入到当前输入框光标位置）</span>
        </div>
      </el-form-item>
      <el-form-item label="已用变量">
        <div v-if="usedVariables.length" class="var-list">
          <el-tag v-for="v in usedVariables" :key="v.name" size="small" :type="v.known ? 'success' : 'danger'">
            {{ '{' + v.name + '}' }}<span v-if="!v.known" class="var-unknown">（未知变量）</span>
          </el-tag>
        </div>
        <span v-else class="var-tip">尚未在模板中使用变量</span>
      </el-form-item>

      <!-- 状态 -->
      <el-form-item label="状态">
        <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
      </el-form-item>
    </el-form>

    <span slot="footer">
      <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="submit">提交</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { getTemplateDetail, getTemplateVariables, addTemplate, editTemplate } from '@/api/notificationTemplate'

// 模板类型
const TYPE_MAP = {
  1: { label: '系统公告', color: '#909399' },
  2: { label: '任务指派', color: '#409EFF' },
  3: { label: '审批通知', color: '#E6A23C' },
  4: { label: '预警提醒', color: '#F56C6C' },
  5: { label: '培训通知', color: '#67C23A' },
  6: { label: '工单通知', color: '#8E44AD' }
}

export default {
  name: 'TemplateFormDialog',
  props: {
    visible: { type: Boolean, default: false },
    formId: { type: Number, default: 0 }
  },
  data () {
    return {
      TYPE_MAP,
      saving: false,
      allVariables: [],
      activeField: 'title_template',
      form: {
        template_name: '',
        template_type: '',
        purpose: '',
        title_template: '',
        content_template: '',
        status: 1
      },
      rules: {
        template_name: [{ required: true, message: '请输入模板名称', trigger: 'blur' }],
        template_type: [{ required: true, message: '请选择模板类型', trigger: 'change' }],
        title_template: [{ required: true, message: '请输入标题模板', trigger: 'blur' }],
        content_template: [{ required: true, message: '请输入内容模板', trigger: 'blur' }]
      }
    }
  },
  computed: {
    // 模板中已使用的变量（自动识别）
    usedVariables () {
      const text = (this.form.title_template || '') + '\n' + (this.form.content_template || '')
      const m = text.match(/\{([a-zA-Z_][a-zA-Z0-9_]*)\}/g) || []
      const names = [...new Set(m.map(x => x.slice(1, -1)))]
      const preset = {}
      this.allVariables.forEach(v => { preset[v.name] = true })
      return names.map(n => ({ name: n, known: !!preset[n] }))
    }
  },
  watch: {
    // v-if 动态创建时 @open 不触发，用 visible 监听（immediate 覆盖初始打开）加载数据
    visible: {
      handler (v) { if (v) this.onOpen() },
      immediate: true
    }
  },
  methods: {
    async onOpen () {
      // 加载可用变量
      try {
        const r = await getTemplateVariables()
        if (r.code === 0) this.allVariables = r.data.list || []
      } catch (e) {}
      // 编辑时回填
      if (this.formId) {
        try {
          const r = await getTemplateDetail(this.formId)
          if (r.code === 0) {
            const d = r.data || {}
            this.form = {
              template_name: d.template_name || '',
              template_type: d.template_type || '',
              purpose: d.purpose || '',
              title_template: d.title_template || '',
              content_template: d.content_template || '',
              status: d.status === 0 ? 0 : 1
            }
          } else {
            this.$message.error('模板详情加载失败：' + (r.msg || ''))
          }
        } catch (e) {
          console.error('getTemplateDetail 失败', e)
          this.$message.error('模板详情加载异常：' + (e.message || JSON.stringify(e)))
        }
      }
    },
    reset () {
      this.form = { template_name: '', template_type: '', purpose: '', title_template: '', content_template: '', status: 1 }
      this.$refs.form && this.$refs.form.clearValidate()
    },
    focusField (field) { this.activeField = field },
    // 插入变量到当前聚焦输入框的光标位置
    insertVar (name) {
      const field = this.activeField || 'title_template'
      const inputEl = this.$refs[field] ? this.$refs[field].$el.querySelector('input, textarea') : null
      const token = '{' + name + '}'
      if (inputEl && document.activeElement === inputEl && inputEl.selectionStart !== null && inputEl.selectionStart !== undefined) {
        const start = inputEl.selectionStart
        const end = inputEl.selectionEnd
        const cur = this.form[field] || ''
        this.form[field] = cur.slice(0, start) + token + cur.slice(end)
        this.$nextTick(() => {
          inputEl.focus()
          inputEl.setSelectionRange(start + token.length, start + token.length)
        })
      } else {
        this.form[field] = (this.form[field] || '') + token
      }
    },
    submit () {
      this.$refs.form.validate(async (ok) => {
        if (!ok) return
        this.saving = true
        try {
          const d = {
            template_name: this.form.template_name,
            template_type: this.form.template_type,
            purpose: this.form.purpose,
            title_template: this.form.title_template,
            content_template: this.form.content_template,
            status: this.form.status
          }
          const r = this.formId ? await editTemplate(this.formId, d) : await addTemplate(d)
          if (r.code === 0) {
            this.$message.success(this.formId ? '更新成功' : '新增成功')
            this.$emit('saved')
          }
        } catch (e) {} finally { this.saving = false }
      })
    }
  }
}
</script>

<style scoped>
.section-title { font-size: 13px; font-weight: 600; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; margin: 6px 0 12px; }
.var-list { display: flex; flex-wrap: wrap; gap: 6px; align-items: center; }
.var-tag { cursor: pointer; }
.var-desc { font-size: 11px; color: #909399; margin-left: 2px; }
.var-unknown { color: #F56C6C; margin-left: 2px; }
.var-tip { font-size: 12px; color: #909399; }
</style>
