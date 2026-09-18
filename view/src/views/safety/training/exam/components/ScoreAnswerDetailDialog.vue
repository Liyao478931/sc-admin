<template>
  <el-dialog title="答卷详情" :visible="visible" width="800px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <div v-loading="loading">
      <el-descriptions v-if="detail" :column="3" size="small" border style="margin-bottom:12px;">
        <el-descriptions-item label="考试名称">{{ detail.exam_name }}</el-descriptions-item>
        <el-descriptions-item label="试卷名称">{{ detail.paper_name }}</el-descriptions-item>
        <el-descriptions-item label="考生">{{ detail.user_name }}</el-descriptions-item>
        <el-descriptions-item label="得分">{{ detail.score }}</el-descriptions-item>
        <el-descriptions-item label="合格状态">
          <el-tag size="mini" :type="detail.is_pass == 1 ? 'success' : 'danger'">{{ detail.is_pass == 1 ? '合格' : '不合格' }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="交卷时间">{{ detail.submit_time }}</el-descriptions-item>
      </el-descriptions>
      <el-row v-if="detail && detail.stat" :gutter="12" style="margin-bottom:12px;">
        <el-col :span="6" v-for="c in statCards" :key="c.label">
          <el-card shadow="never" :body-style="{ padding: '10px' }">
            <div style="font-size:18px;font-weight:600;">{{ c.value }}</div>
            <div style="font-size:12px;color:#909399;">{{ c.label }}</div>
          </el-card>
        </el-col>
      </el-row>
      <div v-for="(a, i) in (detail ? detail.answers : [])" :key="i" style="margin-bottom:10px;padding:10px;background:#f7f8fa;border-radius:6px;">
        <div style="margin-bottom:4px;">
          <b>{{ i + 1 }}. {{ a.question_text }}</b>
          <el-tag size="mini" style="margin-left:6px;">{{ typeText(a.question_type) }}</el-tag>
          <el-tag size="mini" :type="a.is_correct ? 'success' : 'danger'" style="margin-left:6px;">
            {{ a.is_correct ? '✓ 正确' : '✗ 错误' }}
          </el-tag>
        </div>
        <div style="font-size:13px;color:#606266;margin-left:12px;">考生答案：{{ a.selected || '（未作答）' }}</div>
        <div style="font-size:13px;color:#67C23A;margin-left:12px;">正确答案：{{ a.answer }}</div>
        <div v-if="a.analysis" style="font-size:12px;color:#909399;margin-top:4px;margin-left:12px;">解析：{{ a.analysis }}</div>
      </div>
      <el-empty v-if="!loading && (!detail || !detail.answers || !detail.answers.length)" description="暂无答题记录" />
    </div>
    <div slot="footer"><el-button size="small" @click="handleVisibleChange(false)">关闭</el-button></div>
  </el-dialog>
</template>

<script>
import { getScoreDetail } from '@/api/trainingExam'

export default {
  name: 'ScoreAnswerDetailDialog',
  props: {
    visible: { type: Boolean, default: false },
    examId: { type: Number, default: 0 },
    userId: { type: Number, default: 0 },
  },
  data() {
    return { loading: false, detail: null }
  },
  computed: {
    statCards() {
      const s = (this.detail && this.detail.stat) || {}
      return [
        { label: '总题数', value: s.total || 0 },
        { label: '正确数', value: s.correct || 0 },
        { label: '错误数', value: s.wrong || 0 },
        { label: '正确率(%)', value: s.rate || 0 },
      ]
    },
  },
  watch: {
    visible(val) { if (val) this.load() },
  },
  methods: {
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    typeText(t) { return { single: '单选题', multiple: '多选题', judge: '判断题' }[t] || t },
    async load() {
      if (!this.examId || !this.userId) return
      this.loading = true; this.detail = null
      try {
        const r = await getScoreDetail(this.examId, this.userId)
        if (r.code === 0) this.detail = r.data
      } catch (e) {}
      this.loading = false
    },
  },
}
</script>
