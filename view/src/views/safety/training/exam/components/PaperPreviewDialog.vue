<template>
  <el-dialog title="试卷预览" :visible="visible" width="900px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <div v-loading="loading">
      <el-descriptions v-if="paper" :column="3" size="small" border style="margin-bottom:14px;">
        <el-descriptions-item label="试卷名称">{{ paper.paper_name }}</el-descriptions-item>
        <el-descriptions-item label="培训类型">{{ paper.type_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="题目数量">{{ paper.total_questions }}</el-descriptions-item>
        <el-descriptions-item label="总分">{{ paper.total_score }}</el-descriptions-item>
        <el-descriptions-item label="及格分数">{{ paper.pass_score }}</el-descriptions-item>
        <el-descriptions-item label="考试时长">{{ paper.duration_minutes }} 分钟</el-descriptions-item>
      </el-descriptions>
      <div v-for="(q, i) in questions" :key="q.id" style="margin-bottom:14px;padding:12px;background:#f7f8fa;border-radius:6px;">
        <div style="margin-bottom:6px;">
          <b>{{ i + 1 }}. {{ q.question_text }}</b>
          <el-tag size="mini" style="margin-left:8px;">{{ q.type_text }}</el-tag>
          <el-tag size="mini" type="warning" style="margin-left:6px;">{{ q.difficulty_text }}</el-tag>
        </div>
        <div v-for="o in q.options" :key="o.label" style="font-size:13px;color:#606266;margin-left:18px;">
          {{ o.label }}. {{ o.text }}
        </div>
        <div style="font-size:13px;color:#67C23A;margin-top:4px;margin-left:18px;">正确答案：{{ q.answer }}</div>
        <div v-if="q.analysis" style="font-size:12px;color:#909399;margin-top:4px;margin-left:18px;">解析：{{ q.analysis }}</div>
      </div>
      <el-empty v-if="!loading && !questions.length" description="该试卷暂未添加题目" />
    </div>
    <div slot="footer">
      <el-button size="small" @click="handleVisibleChange(false)">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getPaperDetail } from '@/api/trainingExam'

export default {
  name: 'PaperPreviewDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null },
  },
  data() {
    return { loading: false, paper: null, questions: [] }
  },
  watch: {
    visible(val) { if (val) this.load() },
  },
  methods: {
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    async load() {
      if (!this.row || !this.row.id) return
      this.loading = true; this.paper = null; this.questions = []
      try {
        const r = await getPaperDetail(this.row.id)
        if (r.code === 0) {
          this.paper = { ...r.data }
          this.questions = r.data.questions || []
        }
      } catch (e) {}
      this.loading = false
    },
  },
}
</script>
