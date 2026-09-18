<!-- 文件：admin/src/views/ai/app/components/ApiKeyGenerateDialog.vue -->
<!-- 生成 API 密钥弹窗：表单 → 生成后展示完整密钥（仅一次） -->
<template>
  <el-dialog :title="generated ? '密钥已生成' : '生成API密钥'" :visible="visible"
    @update:visible="$emit('update:visible', $event)" width="550px" :close-on-click-modal="false" @closed="reset">
    <!-- 表单模式 -->
    <template v-if="!generated">
      <el-form :model="form" :rules="rules" ref="form" label-width="90px" size="small">
        <el-form-item label="密钥名称" prop="key_name">
          <el-input v-model="form.key_name" placeholder="请输入密钥名称（如 生产环境密钥）" maxlength="50" />
        </el-form-item>
        <el-form-item label="所属应用" prop="app_id">
          <el-select v-model="form.app_id" filterable placeholder="请选择应用" style="width:100%">
            <el-option v-for="a in appOptions" :key="a.app_id" :label="a.app_name" :value="a.app_id" />
          </el-select>
        </el-form-item>
        <el-form-item label="过期时间">
          <el-date-picker v-model="form.key_expire" type="datetime" placeholder="永不过期" value-format="yyyy-MM-dd HH:mm:ss" style="width:100%" />
        </el-form-item>
        <el-form-item label="IP白名单">
          <el-input v-model="form.ip_whitelist" type="textarea" :rows="3" placeholder="每行一个IP，支持CIDR格式（如 192.168.1.0/24），留空不限制" />
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
        <el-button size="small" type="primary" :loading="generating" @click="doGenerate">确认生成</el-button>
      </span>
    </template>

    <!-- 展示模式 -->
    <template v-else>
      <el-alert type="warning" :closable="false" title="密钥仅显示一次，请妥善保存，关闭后将无法再次查看完整密钥。" style="margin-bottom:12px;" />
      <div class="key-result">
        <code class="key-full">{{ generatedKey }}</code>
        <el-button size="small" icon="el-icon-document-copy" type="primary" @click="copyKey">复制密钥</el-button>
      </div>
      <span slot="footer">
        <el-button size="small" type="primary" @click="$emit('update:visible', false)">我已保存，关闭</el-button>
      </span>
    </template>
  </el-dialog>
</template>

<script>
import { generateApiKey } from '@/api/aiApiKey'

export default {
  name: 'ApiKeyGenerateDialog',
  props: {
    visible: { type: Boolean, default: false },
    appOptions: { type: Array, default: () => [] }
  },
  data () {
    return {
      form: { key_name: '', app_id: '', key_expire: '', ip_whitelist: '' },
      rules: {
        key_name: [{ required: true, message: '请输入密钥名称', trigger: 'blur' }, { min: 2, max: 50, message: '长度2-50字符', trigger: 'blur' }],
        app_id: [{ required: true, message: '请选择应用', trigger: 'change' }]
      },
      generating: false, generated: false, generatedKey: ''
    }
  },
  methods: {
    reset () {
      this.form = { key_name: '', app_id: '', key_expire: '', ip_whitelist: '' }
      this.generated = false
      this.generatedKey = ''
      this.$refs.form && this.$refs.form.clearValidate()
    },
    doGenerate () {
      this.$refs.form.validate(async (ok) => {
        if (!ok) { this.$message.warning('请完善必填项'); return }
        this.generating = true
        try {
          const d = {
            key_name: this.form.key_name.trim(),
            app_id: this.form.app_id,
            key_expire: this.form.key_expire || '',
            ip_whitelist: this.form.ip_whitelist ? this.form.ip_whitelist.split(/\n/) : []
          }
          const r = await generateApiKey(d)
          if (r.code === 0) {
            this.generated = true
            this.generatedKey = r.data.api_key || ''
            this.$emit('success')
          }
        } catch (e) {} finally { this.generating = false }
      })
    },
    copyKey () {
      if (!this.generatedKey) return
      const ta = document.createElement('textarea')
      ta.value = this.generatedKey; document.body.appendChild(ta); ta.select()
      document.execCommand('copy'); document.body.removeChild(ta)
      this.$message.success('密钥已复制，请妥善保存')
    }
  }
}
</script>

<style scoped>
.key-result { display: flex; align-items: center; gap: 12px; background: #f5f7fa; border-radius: 8px; padding: 14px; }
.key-full { font-size: 15px; font-weight: 600; word-break: break-all; flex: 1; }
</style>
