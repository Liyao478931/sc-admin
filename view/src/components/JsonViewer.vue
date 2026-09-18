<!-- 文件：admin/src/components/JsonViewer.vue -->
<template>
  <div class="json-viewer">
    <div class="jv-head">
      <span class="jv-title">{{ title }}</span>
      <div class="jv-actions">
        <el-button size="mini" type="text" @click="toggleExpand">{{ expanded ? '折叠' : '展开' }}</el-button>
        <el-button size="mini" type="text" icon="el-icon-document-copy" @click="copy">复制</el-button>
      </div>
    </div>
    <div v-if="expanded" class="jv-body">
      <pre class="jv-pre">{{ prettyJson }}</pre>
      <div v-if="truncated" class="jv-truncated">（内容过大已截断，共 {{ originalLength }} 字符）</div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'JsonViewer',
  props: {
    content: { type: [String, Object, Array], default: '' },
    title: { type: String, default: 'JSON' },
    maxLength: { type: Number, default: 1048576 } // 默认1MB
  },
  data () {
    return { expanded: true, truncatedFlag: false }
  },
  computed: {
    prettyJson () {
      let s = this.content
      if (typeof s === 'object') {
        try { s = JSON.stringify(s, null, 2) } catch (e) { s = String(s) }
      } else {
        try { s = JSON.stringify(JSON.parse(String(s)), null, 2) } catch (e) { /* 保持原文 */ }
      }
      if (s.length > this.maxLength) {
        this.truncatedFlag = true
        return s.slice(0, this.maxLength)
      }
      this.truncatedFlag = false
      return s
    },
    truncated () { return this.truncatedFlag },
    originalLength () { return this.prettyJson.length },
    displayText () { return this.prettyJson }
  },
  methods: {
    toggleExpand () { this.expanded = !this.expanded },
    copy () {
      const text = this.displayText
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(() => this.$message.success('已复制'))
      } else {
        const ta = document.createElement('textarea')
        ta.value = text
        document.body.appendChild(ta); ta.select(); document.execCommand('copy'); document.body.removeChild(ta)
        this.$message.success('已复制')
      }
    }
  }
}
</script>

<style scoped>
.json-viewer { width: 100%; }
.jv-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
.jv-title { font-size: 13px; font-weight: 600; color: #606266; }
.jv-pre { background: #282c34; color: #abb2bf; border-radius: 6px; padding: 10px; font-size: 12px; overflow-x: auto; max-height: 400px; white-space: pre-wrap; word-break: break-word; }
.jv-truncated { font-size: 12px; color: #E6A23C; margin-top: 4px; }
</style>
