<template>
  <el-dialog title="考试监控" :visible="visible" width="950px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <div v-loading="loading">
      <el-row :gutter="12" style="margin-bottom:14px;">
        <el-col :span="4" v-for="c in statCards" :key="c.label">
          <el-card shadow="never" :body-style="{ padding: '12px' }">
            <div style="font-size:20px;font-weight:600;color:#303133;">{{ c.value }}</div>
            <div style="font-size:12px;color:#909399;">{{ c.label }}</div>
          </el-card>
        </el-col>
      </el-row>
      <el-table :data="attendees" size="mini" border max-height="400">
        <el-table-column prop="user_name" label="姓名" width="120" />
        <el-table-column label="部门" width="140">
          <template slot-scope="{ row }">{{ row.department || '-' }}</template>
        </el-table-column>
        <el-table-column prop="status_text" label="状态" width="90" align="center" />
        <el-table-column label="实名验证" width="110" align="center">
          <template slot-scope="{ row }">
            <el-tooltip v-if="row.face_verified == 1 && row.id_card_verified == 1" :content="'身份证✓ 人脸' + (row.face_score ?? '-') + '分' + (row.face_verified_at ? ' ' + row.face_verified_at : '')" placement="top">
              <el-tag size="mini" type="success">已实名</el-tag>
            </el-tooltip>
            <el-tag v-else size="mini" type="info">未实名</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="submit_time" label="交卷时间" show-overflow-tooltip />
        <el-table-column label="操作" width="220" align="center">
          <template slot-scope="{ row }">
            <el-button v-if="row.status === 2" size="mini" type="text" @click="openAnswer(row)">答卷</el-button>
            <el-button v-if="row.status === 1" size="mini" type="text" style="color:#F56C6C" @click="doForceSubmit(row)">强制交卷</el-button>
            <el-button v-if="row.status === 1" size="mini" type="text" @click="promptExtend(row)">延长</el-button>
          </template>
        </el-table-column>
      </el-table>
      <exam-answer-detail-dialog :visible.sync="answerVisible" :exam-id="row && row.id" :user-id="answerUserId" />
    </div>
    <div slot="footer">
      <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="load">刷新</el-button>
      <el-button size="small" @click="handleVisibleChange(false)">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getExamMonitor, forceSubmitExam, extendExamTime } from '@/api/trainingExam'
import ExamAnswerDetailDialog from './ExamAnswerDetailDialog.vue'

export default {
  name: 'ExamMonitorDialog',
  components: { ExamAnswerDetailDialog },
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null },
  },
  data() {
    return { loading: false, exam: null, attendees: [], counts: { total: 0, unstarted: 0, doing: 0, submitted: 0 }, answerVisible: false, answerUserId: 0 }
  },
  computed: {
    statCards() {
      return [
        { label: '应考人数', value: this.counts.total },
        { label: '实考人数', value: this.counts.doing + this.counts.submitted },
        { label: '未考人数', value: this.counts.unstarted },
        { label: '已交卷人数', value: this.counts.submitted },
        { label: '未交卷人数', value: this.counts.total - this.counts.submitted },
      ]
    },
  },
  watch: {
    visible(val) { if (val) this.load() },
  },
  methods: {
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    async load() {
      if (!this.row || !this.row.id) return
      this.loading = true
      try {
        const r = await getExamMonitor(this.row.id)
        if (r.code === 0) {
          this.exam = r.data.exam
          this.counts = r.data.counts || this.counts
          this.attendees = r.data.attendees || []
          this.$emit('saved')
        }
      } catch (e) {}
      this.loading = false
    },
    doForceSubmit(row) {
      this.$confirm(`确认强制交卷「${row.user_name}」？交卷后将自动判卷。`, '强制交卷', { type: 'warning' }).then(async () => {
        try {
          const r = await forceSubmitExam(this.row.id, row.user_id)
          if (r.code === 0) { this.$message.success(`已交卷，得分 ${r.data.score}`); this.load() }
        } catch (e) {}
      }).catch(() => {})
    },
    openAnswer(row) {
      this.answerUserId = row.user_id
      this.answerVisible = true
    },
    promptExtend(row) {
      this.$prompt('请输入延长分钟数（不超过30分钟）', '延长考试时间', { inputPattern: /^[1-9]\d*$/, inputErrorMessage: '请输入正整数' }).then(async ({ value }) => {
        try {
          const r = await extendExamTime(this.row.id, row.user_id, parseInt(value))
          if (r.code === 0) { this.$message.success(`已延长 ${value} 分钟`); this.load() }
        } catch (e) {}
      }).catch(() => {})
    },
  },
}
</script>
