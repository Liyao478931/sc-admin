<!--
  文件：admin/src/views/hr/assessment/template/components/BasicInfoTab.vue
  功能：模板基本信息（名称/编码/岗位类别/周期/默认/状态/描述）
  视觉：对齐参考模板（两列 grid / 编码校验 append / border radio）
-->
<template>
  <div class="basic-tab">
    <div class="basic-info-form">
      <div>
        <span class="form-label"><span class="required">*</span>模板名称</span>
        <el-input v-model="form.name" placeholder="请输入模板名称" maxlength="100" />
      </div>
      <div>
        <span class="form-label"><span class="required">*</span>模板编码</span>
        <el-input v-model="form.code" placeholder="唯一编码" maxlength="50" @blur="checkCode">
          <el-button slot="append" icon="el-icon-refresh" title="自动生成" @click="genCode" :disabled="!form.category"></el-button>
        </el-input>
        <div v-if="codeChecked" class="code-status" :class="codeExists ? 'error' : 'ok'">
          {{ codeExists ? '该编码已被使用，请更换' : '校验通过 ✅' }}
        </div>
        <div v-else class="form-tip">格式：{前缀}-{年份}-{序号}，如 YGZ-2026-001</div>
      </div>
      <div>
        <span class="form-label"><span class="required">*</span>适用岗位类别</span>
        <el-select v-model="form.category" style="width:100%;" placeholder="请选择岗位类别">
          <el-option v-for="c in CATEGORIES" :key="c" :label="c" :value="c" />
        </el-select>
      </div>
      <div>
        <span class="form-label">周期类型</span>
        <el-radio-group v-model="form.period_type">
          <el-radio-button :label="1">月度</el-radio-button>
          <el-radio-button :label="2">季度</el-radio-button>
          <el-radio-button :label="3">半年度</el-radio-button>
          <el-radio-button :label="4">年度</el-radio-button>
        </el-radio-group>
      </div>
      <div>
        <span class="form-label">默认模板</span>
        <el-switch v-model="form.is_default" :active-value="1" :inactive-value="0" active-text="推荐" inactive-text="普通" />
        <div class="form-tip">打开后创建任务时自动推荐</div>
      </div>
      <div>
        <span class="form-label">模板状态</span>
        <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
        <div class="form-tip">停用后不可用于生成新任务</div>
      </div>
      <div class="full-width">
        <span class="form-label">模板描述</span>
        <el-input v-model="form.description" type="textarea" :rows="3" maxlength="500" placeholder="模板适用范围和考核目的" />
      </div>
    </div>

    <div class="form-actions">
      <el-button type="primary" icon="el-icon-check" :loading="saving" @click="doSave">保存基本信息</el-button>
      <el-button @click="$emit('cancel')">取消</el-button>
    </div>
  </div>
</template>

<script>
import { getNextTemplateCode, checkTemplateCode } from '@/api/assessment'

const CATEGORIES = ['操作工', '维修工', '质检员', '班组长', '管理人员']

export default {
  name: 'AssessmentBasicInfoTab',
  props: {
    form: { type: Object, required: true },
    saving: { type: Boolean, default: false }
  },
  data () {
    return {
      CATEGORIES,
      codeExists: false,
      codeChecked: false
    }
  },
  watch: {
    'form.code' () { this.codeChecked = false }
  },
  methods: {
    async genCode () {
      if (!this.form.category) { this.$message.warning('请先选择适用岗位类别'); return }
      try {
        const r = await getNextTemplateCode(this.form.category)
        if (r.code === 0 && r.data && r.data.code) {
          this.form.code = r.data.code
          this.codeExists = false
          this.codeChecked = false
        }
      } catch (e) {}
    },
    async checkCode () {
      const code = (this.form.code || '').trim()
      if (!code) { this.codeChecked = false; return }
      try {
        const r = await checkTemplateCode({ code, exclude_id: this.form.id || 0 })
        if (r.code === 0) {
          this.codeExists = !!r.data.exists
          this.codeChecked = true
        }
      } catch (e) {}
    },
    doSave () {
      if (!(this.form.name || '').trim()) { this.$message.warning('请填写模板名称'); return }
      if (!(this.form.code || '').trim()) { this.$message.warning('请填写模板编码'); return }
      if (!this.form.category) { this.$message.warning('请选择适用岗位类别'); return }
      if (this.codeExists) { this.$message.warning('模板编码已被使用，请更换'); return }
      this.$emit('save', { ...this.form })
    }
  }
}
</script>

<style scoped>
.basic-tab { padding: 20px 24px; }
.basic-info-form { display: grid; grid-template-columns: 1fr 1fr; gap: 18px 40px; }
.basic-info-form .full-width { grid-column: 1 / -1; }
.form-label { font-size: 13px; color: #4e5a6b; margin-bottom: 6px; display: block; font-weight: 500; }
.form-label .required { color: #f53f3f; margin-right: 2px; }
.code-status { font-size: 12px; margin-top: 4px; }
.code-status.ok { color: #00b42a; }
.code-status.error { color: #f53f3f; }
.form-tip { font-size: 12px; color: #8c8f9c; line-height: 1.6; margin-top: 4px; }
.form-actions { margin-top: 24px; padding-top: 16px; border-top: 1px solid #e8ecf1; display: flex; gap: 12px; }
@media (max-width: 992px) {
  .basic-info-form { grid-template-columns: 1fr; }
}
</style>
