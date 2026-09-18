<template>
  <el-dialog title="答卷详情" :visible="visible" width="800px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <div v-loading="loading">
      <el-descriptions v-if="answer" :column="3" size="small" border style="margin-bottom:14px;">
        <el-descriptions-item label="考生">{{ answer.user_name }}</el-descriptions-item>
        <el-descriptions-item label="得分">{{ answer.score }}</el-descriptions-item>
        <el-descriptions-item label="及格分">{{ answer.pass_score }}</el-descriptions-item>
        <el-descriptions-item label="合格">{{ answer.is_pass == 1 ? '是' : '否' }}</el-descriptions-item>
        <el-descriptions-item label="交卷时间">{{ answer.submit_time || '-' }}</el-descriptions-item>
        <el-descriptions-item label="用时">{{ answer.exam_duration }} 秒</el-descriptions-item>
      </el-descriptions>
      <div v-for="(a, i) in answer.answers" :key="i" style="margin-bottom:12px;padding:10px;background:#f7f8fa;border-radius:6px;">
        <div style="margin-bottom:4px;">
          <b>{{ i + 1 }}. {{ a.question_text }}</b>
          <el-tag size="mini" style="margin-left:6px;">{{ typeText(a.question_type) }}</el-tag>
          <el-tag size="mini" :type="a.is_correct ? 'success' : 'danger'" style="margin-left:6px;">{{ a.is_correct ? '答对' : '答错' }}</el-tag>
        </div>
        <div style="font-size:13px;color:#606266;margin-left:12px;">考生答案：{{ a.selected || '（未作答）' }}</div>
        <div style="font-size:13px;color:#67C23A;margin-left:12px;">正确答案：{{ a.answer }}</div>
      </div>
      <el-empty v-if="!loading && (!answer || !answer.answers || !answer.answers.length)" description="暂无答题记录" />
    </div>
    <div slot="footer"><el-button size="small" @click="handleVisibleChange(false)">关闭</el-button></div>
  </el-dialog>
</template>

<script>
import { getExamScoreDetail } from '@/api/trainingExam'

export default {
  name: 'ExamAnswerDetailDialog',
  props: {
    visible: { type: Boolean, default: false },
    examId: { type: Number, default: 0 },
    userId: { type: Number, default: 0 },
  },
  data() {
    return { loading: false, answer: null }
  },
  watch: {
    visible(val) { if (val) this.load() },
  },
  methods: {
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    typeText(t) { return { single: '单选题', multiple: '多选题', judge: '判断题' }[t] || t },
    async load() {
      if (!this.examId || !this.userId) return
      this.loading = true; this.answer = null
      try {
        const r = await getExamScoreDetail(this.examId, this.userId)
        if (r.code === 0) this.answer = r.data
      } catch (e) {}
      this.loading = false
    },
  },
}
</script>
