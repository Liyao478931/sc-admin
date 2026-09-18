<!-- 文件：admin/src/components/AiMarkdown.vue -->
<template>
  <div class="ai-markdown" v-html="rendered"></div>
</template>

<script>
import MarkdownIt from 'markdown-it'
import hljs from 'highlight.js'

const md = new MarkdownIt({
  html: false,
  linkify: true,
  breaks: true,
  highlight (str, lang) {
    if (lang && hljs.getLanguage(lang)) {
      try {
        return '<pre class="hljs"><code>' + hljs.highlight(str, { language: lang, ignoreIllegals: true }).value + '</code></pre>'
      } catch (e) { /* fallthrough */ }
    }
    return '<pre class="hljs"><code>' + md.utils.escapeHtml(str) + '</code></pre>'
  }
})

export default {
  name: 'AiMarkdown',
  props: {
    content: { type: String, default: '' }
  },
  computed: {
    rendered () {
      return md.render(this.content || '')
    }
  }
}
</script>

<style scoped>
.ai-markdown { line-height: 1.7; font-size: 14px; word-break: break-word; }
.ai-markdown >>> h1, .ai-markdown >>> h2, .ai-markdown >>> h3 { margin: 12px 0 8px; font-weight: 600; }
.ai-markdown >>> p { margin: 6px 0; }
.ai-markdown >>> ul, .ai-markdown >>> ol { padding-left: 20px; margin: 6px 0; }
.ai-markdown >>> blockquote { border-left: 3px solid #409EFF; margin: 8px 0; padding: 4px 12px; color: #666; background: #f5f7fa; }
.ai-markdown >>> code { background: #f0f2f5; padding: 1px 5px; border-radius: 3px; font-size: 13px; }
.ai-markdown >>> pre { background: #282c34; color: #abb2bf; padding: 12px; border-radius: 6px; overflow-x: auto; }
.ai-markdown >>> pre code { background: transparent; color: inherit; padding: 0; }
.ai-markdown >>> table { border-collapse: collapse; margin: 8px 0; width: 100%; }
.ai-markdown >>> th, .ai-markdown >>> td { border: 1px solid #dcdfe6; padding: 6px 10px; font-size: 13px; }
.ai-markdown >>> th { background: #f5f7fa; font-weight: 600; }
.ai-markdown >>> a { color: #409EFF; }
</style>
