<!--
  文件：admin/src/views/settings/AgreementConfig.vue
  功能：系统设置 → 协议管理（移动端用户协议 / 隐私政策）
    富文本编辑（wangeditor v4），支持字体/字号/颜色/加粗/列表/链接/图片等，所见即所得
-->
<template>
  <div class="agreement-page">
    <!-- 顶部 -->
    <div class="page-head">
      <div>
        <h2>协议管理</h2>
        <div class="update-tip">配置移动端登录页展示的《用户协议》与《隐私政策》，支持富文本编辑（字体、字号、颜色等）</div>
      </div>
      <div class="head-actions">
        <el-button size="small" :loading="saving" type="primary" @click="doSave">保存</el-button>
      </div>
    </div>

    <div class="main-body" v-loading="loading">
      <el-card shadow="never" class="sec-card">
        <div slot="header" class="sec-header">
          <span>《用户协议》</span>
          <el-tag size="mini" type="info">移动端登录页勾选链接</el-tag>
        </div>
        <div ref="uaEditor" class="rich-editor"></div>
        <div class="char-count">{{ pureText(form.user_agreement).length }} 字符</div>
      </el-card>

      <el-card shadow="never" class="sec-card">
        <div slot="header" class="sec-header">
          <span>《隐私政策》</span>
          <el-tag size="mini" type="info">移动端登录页勾选链接</el-tag>
        </div>
        <div ref="ppEditor" class="rich-editor"></div>
        <div class="char-count">{{ pureText(form.privacy_policy).length }} 字符</div>
      </el-card>

      <el-card shadow="never" class="sec-card">
        <div slot="header" class="sec-header">
          <span>移动端效果预览</span>
          <el-tag size="mini" type="success">保存后即时生效</el-tag>
        </div>
        <div class="preview-tip">
          保存后，移动端登录页点击《用户协议》或《隐私政策》链接，将以独立页面展示配置内容。
          支持字体、字号、颜色、加粗、列表、链接、图片等富文本排版。
        </div>
      </el-card>
    </div>
  </div>
</template>

<script>
import E from 'wangeditor'
import { getAgreements, saveAgreements } from '../../api/agreement'

export default {
  name: 'AgreementConfig',
  data() {
    return {
      loading: false,
      saving: false,
      form: {
        user_agreement: '',
        privacy_policy: ''
      },
      uaEditor: null,
      ppEditor: null
    }
  },
  mounted() {
    this.uaEditor = this.createEditor(this.$refs.uaEditor)
    this.ppEditor = this.createEditor(this.$refs.ppEditor)
    this.loadData()
  },
  methods: {
    pureText(html) {
      const div = document.createElement('div')
      div.innerHTML = html || ''
      return div.textContent || ''
    },
    createEditor(el) {
      const editor = new E(el)
      editor.config.menus = [
        'head',
        'bold',
        'italic',
        'underline',
        'strikeThrough',
        'fontName',
        'fontSize',
        'foreColor',
        'backColor',
        'justify',
        'list',
        'link',
        'image',
        'undo',
        'redo'
      ]
      editor.config.placeholder = '请输入内容...'
      editor.config.height = 320
      editor.config.zIndex = 100
      editor.config.uploadImgShowBase64 = true
      editor.config.uploadImgMaxSize = 5 * 1024 * 1024
      editor.config.uploadImgMaxLength = 1
      editor.create()
      return editor
    },
    async loadData() {
      this.loading = true
      try {
        // 注意：request 封装成功时已返回解包后的 { code, msg, data }，此处直接用 res.code / res.data
        const res = await getAgreements()
        if (res && res.code === 0) {
          this.form.user_agreement = (res.data && res.data.user_agreement) || ''
          this.form.privacy_policy = (res.data && res.data.privacy_policy) || ''
          this.uaEditor.txt.html(this.form.user_agreement)
          this.ppEditor.txt.html(this.form.privacy_policy)
        }
      } catch (e) {
        this.$message.error('获取协议内容失败')
      }
      this.loading = false
    },
    async doSave() {
      this.saving = true
      try {
        this.form.user_agreement = this.uaEditor.txt.html()
        this.form.privacy_policy = this.ppEditor.txt.html()
        const res = await saveAgreements({
          user_agreement: this.form.user_agreement,
          privacy_policy: this.form.privacy_policy
        })
        if (res && res.code === 0) {
          this.$message.success('保存成功，移动端即时生效')
        } else {
          this.$message.error((res && res.msg) || '保存失败')
        }
      } catch (e) {
        this.$message.error('保存失败，请检查网络')
      }
      this.saving = false
    }
  }
}
</script>

<style scoped>
.agreement-page { padding: 16px; }
.page-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #fff;
  padding: 16px 20px;
  border-radius: 8px;
  margin-bottom: 16px;
  box-shadow: 0 1px 4px rgba(0, 21, 41, 0.08);
}
.page-head h2 { margin: 0 0 4px; font-size: 18px; color: #1f2d3d; }
.update-tip { font-size: 12px; color: #909399; }
.main-body { max-width: 960px; }
.sec-card { margin-bottom: 16px; }
.sec-header { display: flex; align-items: center; justify-content: space-between; font-weight: 600; }
.rich-editor {
  border: 1px solid #dcdfe6;
  border-radius: 4px;
  background: #fff;
}
.rich-editor >>> .w-e-toolbar {
  border: none;
  border-bottom: 1px solid #ebeef5;
  border-radius: 4px 4px 0 0;
}
.rich-editor >>> .w-e-text-container {
  border: none;
}
.char-count { margin-top: 6px; font-size: 12px; color: #c0c4cc; text-align: right; }
.preview-tip { font-size: 13px; color: #606266; line-height: 1.8; }
</style>
