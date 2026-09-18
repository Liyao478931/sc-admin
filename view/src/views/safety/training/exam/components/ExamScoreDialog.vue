<template>
  <el-dialog title="考试成绩" :visible="visible" width="900px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <div v-loading="loading">
      <el-row :gutter="12" style="margin-bottom:14px;">
        <el-col :span="6" v-for="c in statCards" :key="c.label">
          <el-card shadow="never" :body-style="{ padding: '12px' }">
            <div style="font-size:20px;font-weight:600;color:#303133;">{{ c.value }}</div>
            <div style="font-size:12px;color:#909399;">{{ c.label }}</div>
          </el-card>
        </el-col>
      </el-row>
      <el-table :data="list" size="mini" border max-height="380">
        <el-table-column prop="user_name" label="姓名" width="120" />
        <el-table-column prop="department" label="部门" width="140" show-overflow-tooltip />
        <el-table-column label="得分" width="90" align="center">
          <template slot-scope="{ row }">{{ row.status === 2 ? row.score : '-' }}</template>
        </el-table-column>
        <el-table-column label="合格状态" width="90" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.pass_text === '合格' ? 'success' : (row.pass_text === '不合格' ? 'danger' : 'info')">{{ row.pass_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="实名验证" width="110" align="center">
          <template slot-scope="{ row }">
            <el-tooltip v-if="row.face_verified == 1 && row.id_card_verified == 1" :content="'身份证✓ 人脸' + (row.face_score ?? '-') + '分' + (row.face_verified_at ? ' ' + row.face_verified_at : '')" placement="top">
              <el-tag size="mini" type="success">已实名</el-tag>
            </el-tooltip>
            <el-tag v-else size="mini" type="info">未实名</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="submit_time" label="交卷时间" show-overflow-tooltip />
        <el-table-column label="操作" width="90" align="center">
          <template slot-scope="{ row }">
            <el-button v-if="row.status === 2" size="mini" type="text" @click="openAnswer(row)">答卷</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>
    <exam-answer-detail-dialog :visible.sync="answerVisible" :exam-id="examId" :user-id="answerUserId" />
    <div slot="footer">
      <el-button size="small" type="primary" icon="el-icon-download" :loading="exporting" @click="doExport">导出成绩</el-button>
      <el-button size="small" @click="handleVisibleChange(false)">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getExamScoreList, exportExamScore } from '@/api/trainingExam'
import ExamAnswerDetailDialog from './ExamAnswerDetailDialog.vue'

export default {
  name: 'ExamScoreDialog',
  components: { ExamAnswerDetailDialog },
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null },
  },
  data() {
    return {
      loading: false, exporting: false, list: [], stat: { max: 0, min: 0, avg: 0, pass_rate: 0 },
      answerVisible: false, answerUserId: 0, examId: 0,
    }
  },
  computed: {
    statCards() {
      return [
        { label: '最高分', value: this.stat.max },
        { label: '最低分', value: this.stat.min },
        { label: '平均分', value: this.stat.avg },
        { label: '通过率(%)', value: this.stat.pass_rate },
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
      this.loading = true; this.list = []
      try {
        const r = await getExamScoreList(this.row.id)
        if (r.code === 0) {
          this.examId = this.row.id
          this.list = r.data.list || []
          this.stat = r.data.stat || this.stat
        }
      } catch (e) {}
      this.loading = false
    },
    openAnswer(row) { this.answerUserId = row.user_id; this.answerVisible = true },
    async doExport() {
      this.exporting = true
      try {
        const r = await exportExamScore(this.row.id)
        if (r.code === 0 && r.data.url) { window.open(r.data.url, '_blank'); this.$message.success('导出成功') }
      } catch (e) {}
      this.exporting = false
    },
  },
}
</script>
