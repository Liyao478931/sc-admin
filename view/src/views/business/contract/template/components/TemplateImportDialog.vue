<!--
  文件：admin/src/views/business/contract/template/components/TemplateImportDialog.vue
  功能：导入模板弹窗（上传 HTML / Word 文件，解析后回调填充）
-->
<template>
  <el-dialog title="导入模板" :visible="visible" width="550px" :close-on-click-modal="false" @close="$emit('update:visible', false)">
    <el-upload
      drag :action="importUrl" :headers="uploadHeaders" :show-file-list="true" :limit="1"
      accept=".html,.htm,.docx" :on-success="handleSuccess" :on-error="handleError" :on-remove="() => (result = null)"
    >
      <i class="el-icon-upload"></i>
      <div class="el-upload__text">将文件拖到此处，或<em>点击上传</em></div>
      <div slot="tip" class="el-upload__tip">支持 .html / .htm / .docx 格式；解析后的内容将填充到模板编辑区</div>
    </el-upload>
    <el-alert v-if="result" :type="result.ok ? 'success' : 'error'" :closable="false" show-icon
      :title="result.ok ? '解析成功，点击「使用此内容」填充到模板' : result.msg" style="margin-top:10px" />
    <div slot="footer" class="dialog-footer">
      <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
      <el-button size="small" type="primary" :disabled="!result || !result.ok" @click="useIt">使用此内容</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getToken } from '../../../../../utils/auth'

export default {
  name: 'TemplateImportDialog',
  props: {
    visible: { type: Boolean, default: false }
  },
  data() {
    return { result: null }
  },
  computed: {
    importUrl() { return '/api/business/contract/template/import' },
    uploadHeaders() { return { Authorization: 'Bearer ' + getToken() } }
  },
  watch: {
    visible(val) { if (val) this.result = null }
  },
  methods: {
    handleSuccess(res) {
      if (res.code === 0 && res.data && res.data.content) {
        this.result = { ok: true, content: res.data.content, msg: res.msg || '解析成功' }
      } else {
        this.result = { ok: false, msg: res.msg || '解析失败' }
      }
    },
    handleError() { this.result = { ok: false, msg: '上传失败，请重试' } },
    useIt() { if (this.result && this.result.ok) this.$emit('imported', this.result.content) }
  }
}
</script>

<style scoped>
.dialog-footer { text-align: right; }
</style>
