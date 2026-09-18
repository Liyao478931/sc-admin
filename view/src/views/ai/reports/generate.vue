<!-- 文件：admin/src/views/ai/reports/generate.vue（v1.65.0 智能报告生成） -->
<template>
  <div class="report-generate">
    <!-- 面包屑 -->
    <div class="crumb"><span>AI智能平台</span><i class="el-icon-arrow-right"></i><span>智能报告</span><i class="el-icon-arrow-right"></i><span class="cur">报告生成</span></div>

    <el-card shadow="never" class="sec">
      <div slot="header" class="sec-head"><span class="sec-title">① 选择报告模板</span></div>
      <div class="tpl-grid">
        <div v-for="t in templates" :key="t.id" class="tpl-card" :class="{ active: selectedTpl && selectedTpl.id === t.id }" @click="selectTpl(t)">
          <div class="tpl-icon">{{ tplIcon(t.template_code) }}</div>
          <div class="tpl-name">{{ t.template_name }}</div>
          <div class="tpl-desc">{{ t.description }}</div>
          <el-tag v-if="t.is_default" size="mini" type="warning">默认</el-tag>
        </div>
      </div>
    </el-card>

    <el-card shadow="never" class="sec">
      <div slot="header" class="sec-head"><span class="sec-title">② 报告配置</span></div>
      <el-form :inline="true" size="small">
        <el-form-item label="报告名称">
          <el-input v-model="reportName" style="width:260px" placeholder="默认：模板_时间范围" />
        </el-form-item>
        <el-form-item label="时间范围">
          <el-select v-model="timeRange" style="width:140px">
            <el-option label="本月" value="current_month" />
            <el-option label="上月" value="last_month" />
            <el-option label="本季" value="current_quarter" />
            <el-option label="本年" value="current_year" />
          </el-select>
        </el-form-item>
        <el-form-item label="报告格式">
          <el-select v-model="format" style="width:120px">
            <el-option label="PDF" value="pdf" />
            <el-option label="Word" value="word" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="generating" icon="el-icon-magic-stick" @click="startGenerate">立即生成</el-button>
          <el-button @click="resetForm">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 生成进度 -->
    <el-card v-if="generating || progress.percent > 0" shadow="never" class="sec">
      <div slot="header" class="sec-head"><span class="sec-title">生成进度</span></div>
      <el-progress :percentage="progress.percent" :status="progress.percent >= 100 ? 'success' : undefined" />
      <div class="step-text"><i class="el-icon-loading" v-if="generating"></i> {{ progress.step }}</div>
    </el-card>

    <!-- 报告预览 -->
    <el-card v-if="previewHtml" shadow="never" class="sec">
      <div slot="header" class="sec-head">
        <span class="sec-title">📊 {{ previewName }}（预览）</span>
        <div class="sec-actions">
          <el-button size="small" type="primary" icon="el-icon-download" @click="doDownload('pdf')">下载PDF</el-button>
          <el-button size="small" icon="el-icon-download" @click="doDownload('word')">下载Word</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="startGenerate">重新生成</el-button>
        </div>
      </div>
      <div class="report-body" v-html="previewHtml"></div>
    </el-card>
  </div>
</template>

<script>
import { getReportTemplates, streamReportGenerate, downloadReportFile } from '@/api/aiReport'

export default {
  name: 'AiReportGenerate',
  data () {
    return {
      templates: [],
      selectedTpl: null,
      reportName: '',
      timeRange: 'current_month',
      format: 'pdf',
      generating: false,
      progress: { percent: 0, step: '' },
      previewHtml: '',
      previewName: '',
      previewId: 0
    }
  },
  created () {
    this.loadTemplates()
  },
  methods: {
    tplIcon (code) {
      return { business_brief: '📊', sales_analysis: '📈', customer_insight: '👥' }[code] || '📄'
    },
    async loadTemplates () {
      try {
        const r = await getReportTemplates()
        if (r.code === 0) {
          this.templates = r.data.list || []
          const def = this.templates.find(t => t.is_default) || this.templates[0]
          if (def) this.selectedTpl = def
        }
      } catch (e) {}
    },
    selectTpl (t) { this.selectedTpl = t },
    resetForm () {
      this.reportName = ''
      this.timeRange = 'current_month'
      this.format = 'pdf'
      this.progress = { percent: 0, step: '' }
      this.previewHtml = ''
      this.previewName = ''
    },
    async startGenerate () {
      if (!this.selectedTpl) { this.$message.warning('请先选择报告模板'); return }
      if (this.generating) return
      this.generating = true
      this.progress = { percent: 0, step: '准备中...' }
      this.previewHtml = ''
      try {
        await streamReportGenerate({
          template_id: this.selectedTpl.id,
          time_range: this.timeRange,
          config: { report_name: this.reportName, format: this.format, time_range: this.timeRange }
        }, (evt) => {
          if (evt.type === 'progress') {
            this.progress = { percent: evt.percent || 0, step: evt.step || '' }
          } else if (evt.type === 'result') {
            this.previewHtml = evt.html || ''
            this.previewName = evt.report_name || ''
            this.previewId = evt.id || 0
            this.progress = { percent: 100, step: '生成完成' }
          } else if (evt.type === 'error') {
            this.$message.error(evt.message || '生成失败')
          }
        })
      } catch (e) {
        this.$message.error('生成失败：' + (e.message || ''))
      } finally {
        this.generating = false
      }
    },
    async doDownload (fmt) {
      if (!this.previewId) return
      try {
        await downloadReportFile(this.previewId, fmt)
        this.$message.success('下载已开始')
      } catch (e) {
        this.$message.error('下载失败')
      }
    }
  }
}
</script>

<style scoped>
.crumb { padding: 10px 16px; background: #fff; border-bottom: 1px solid #e8e8e8; font-size: 13px; color: #909399; }
.crumb i { margin: 0 6px; }
.crumb .cur { color: #303133; }
.sec { margin: 12px; }
.sec-head { display: flex; justify-content: space-between; align-items: center; }
.sec-title { font-weight: 600; }
.tpl-grid { display: flex; gap: 16px; flex-wrap: wrap; }
.tpl-card { width: 220px; border: 1px solid #dcdfe6; border-radius: 8px; padding: 16px; cursor: pointer; transition: all .2s; position: relative; }
.tpl-card:hover { border-color: #409eff; box-shadow: 0 2px 8px rgba(64,158,255,.15); }
.tpl-card.active { border-color: #409eff; background: #ecf5ff; }
.tpl-icon { font-size: 32px; }
.tpl-name { font-weight: 600; margin: 8px 0 4px; }
.tpl-desc { font-size: 12px; color: #909399; min-height: 36px; }
.step-text { margin-top: 8px; color: #606266; font-size: 13px; }
.report-body { background: #fff; border: 1px solid #ebeef5; border-radius: 6px; padding: 20px; min-height: 200px; }
</style>
