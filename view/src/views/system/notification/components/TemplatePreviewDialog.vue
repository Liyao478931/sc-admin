<template>
  <el-dialog :title="'模板预览：' + templateName" :visible="visible" @update:visible="$emit('update:visible', $event)" width="700px" top="6vh">
    <div class="pv-wrap">
      <!-- 变量值输入区 -->
      <div class="section-title">变量值</div>
      <el-form v-if="varFields.length" label-width="110px" size="small">
        <el-row :gutter="12">
          <el-col :span="12" v-for="v in varFields" :key="v.name">
            <el-form-item :label="'{' + v.name + '}'">
              <el-input v-model="values[v.name]" :placeholder="v.desc || '请输入示例值'" clearable />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
      <div v-else class="no-var">该模板未使用变量</div>

      <!-- 预览结果区 -->
      <div class="section-title">预览结果</div>
      <div class="pv-result">
        <div class="pv-title-label">标题：</div>
        <div class="pv-title">{{ preview.title || '（空）' }}</div>
        <div class="pv-content-label">内容：</div>
        <div class="pv-content" v-html="preview.content || '（空）'"></div>
      </div>
    </div>

    <span slot="footer">
      <el-button size="small" icon="el-icon-document-copy" @click="copyContent">复制预览内容</el-button>
      <el-button size="small" type="primary" @click="$emit('update:visible', false)">关闭</el-button>
    </span>
  </el-dialog>
</template>

<script>
import { previewTemplate } from '@/api/notificationTemplate'

export default {
  name: 'TemplatePreviewDialog',
  props: {
    visible: { type: Boolean, default: false },
    templateId: { type: Number, default: 0 },
    templateName: { type: String, default: '' },
    variables: { type: Array, default: () => [] }
  },
  data () {
    return {
      values: {},
      preview: { title: '', content: '' },
      timer: null
    }
  },
  computed: {
    // 需要输入示例值的变量（模板实际使用的）
    varFields () {
      return this.variables || []
    }
  },
  watch: {
    // v-if 动态创建时 @open/visible 不触发变化，用 immediate 覆盖初始打开
    visible: {
      handler (v) {
        if (v) {
          // 自动填充示例值（用户可修改），预览立即可见替换效果
          this.values = {}
          ;(this.variables || []).forEach(x => {
            this.values[x.name] = this.exampleValue(x.name, x.desc)
          })
          this.preview = { title: '', content: '' }
          this.doPreview()
        }
      },
      immediate: true
    },
    values: {
      deep: true,
      handler () { this.schedulePreview() }
    }
  },
  beforeDestroy () { if (this.timer) clearTimeout(this.timer) },
  methods: {
    // 防抖实时预览（与后端渲染保持一致）
    schedulePreview () {
      if (this.timer) clearTimeout(this.timer)
      this.timer = setTimeout(() => this.doPreview(), 300)
    },
    async doPreview () {
      if (!this.templateId) return
      try {
        const r = await previewTemplate(this.templateId, { ...this.values })
        if (r.code === 0) {
          this.preview = r.data || { title: '', content: '' }
        }
      } catch (e) {}
    },
    // 按变量名生成贴近业务的真实示例值
    exampleValue (name, desc) {
      const n = String(name || '').toLowerCase()
      const d = String(desc || '').toLowerCase()
      // 人名类
      if (/(applicant|approver|operator|reporter|handler|owner|buyer|trainer|verifier|dispatcher|principal|agent|user|holder|candidate|creator|worker)/.test(n)) return '张三'
      // 日期/时间类
      if (/(time|date|deadline|period|期限|到期|时间|日期)/.test(n) || /(时间|日期)/.test(d)) return '2026-08-29 10:00'
      // 编号/单号类 → 按前缀生成
      if (/(^|_)(no|code)$|编号|单号/.test(n) || /(编号|单号)/.test(d)) {
        const prefix = n.split('_')[0].slice(0, 2).toUpperCase()
        return (prefix || 'NO') + '-20260829-001'
      }
      // 数量/金额类
      if (/(count|quantity|number|数量|比例|金额|费用|price|amount)/.test(n) || /(数量|金额|费用)/.test(d)) return '10'
      // 客户/供应商/公司类
      if (/(customer|supplier|company|party|warehouse|team)/.test(n)) return '示例' + (d || n.replace(/_/g, ''))
      // 名称/标题类
      if (/(name|title|subject|product|device|contract|order|report|plan|task|exam|training|position)/.test(n) || /(名称|标题|主题)/.test(d)) return '示例' + (d || n.replace(/_/g, ''))
      // 链接类
      if (/(url|link)/.test(n)) return 'https://example.com'
      // 描述/原因类
      if (/(desc|reason|comment|remark|content|description|changelog)/.test(n)) return '这是一段示例描述内容。'
      return '示例值'
    },
    async copyContent () {
      const text = '【' + this.preview.title + '】\n' + this.preview.content.replace(/<[^>]+>/g, '')
      try {
        await navigator.clipboard.writeText(text)
        this.$message.success('预览内容已复制')
      } catch (e) {
        this.$message.error('复制失败，请手动复制')
      }
    }
  }
}
</script>

<style scoped>
.section-title { font-size: 13px; font-weight: 600; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; margin: 6px 0 12px; }
.no-var { color: #909399; font-size: 13px; padding: 8px 0 16px; }
.pv-result { border: 1px solid #EBEEF5; border-radius: 6px; padding: 12px; background: #fafbfc; min-height: 120px; }
.pv-title-label, .pv-content-label { font-size: 12px; color: #909399; margin-bottom: 4px; }
.pv-title { font-size: 15px; font-weight: 600; color: #303133; margin-bottom: 12px; }
.pv-content { font-size: 14px; line-height: 1.8; color: #333; word-break: break-all; }
</style>
