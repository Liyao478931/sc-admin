<template>
  <el-dialog title="考试成绩详情" :visible="visible" width="900px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <div v-loading="loading">
      <el-row :gutter="12" style="margin-bottom:12px;">
        <el-col :span="4" v-for="c in statCards" :key="c.label">
          <el-card shadow="never" :body-style="{ padding: '10px' }">
            <div style="font-size:18px;font-weight:600;">{{ c.value }}</div>
            <div style="font-size:12px;color:#909399;">{{ c.label }}</div>
          </el-card>
        </el-col>
      </el-row>
      <el-table :data="list" size="mini" border max-height="380">
        <el-table-column prop="user_name" label="姓名" width="100" />
        <el-table-column prop="department" label="部门" width="140" show-overflow-tooltip />
        <el-table-column prop="score" label="得分" width="80" align="center" />
        <el-table-column label="合格状态" width="90" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.is_pass == 1 ? 'success' : 'danger'">{{ row.pass_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="submit_time" label="交卷时间" show-overflow-tooltip />
        <el-table-column label="操作" width="90" align="center">
          <template slot-scope="{ row }">
            <el-button size="mini" type="text" @click="$emit('view-answer', { exam_id: row.exam_id, user_id: row.user_id })">答卷</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-empty v-if="!loading && !list.length" description="暂无成绩" />
    </div>
    <div slot="footer"><el-button size="small" @click="handleVisibleChange(false)">关闭</el-button></div>
  </el-dialog>
</template>

<script>
import { getScoreByExam } from '@/api/trainingExam'

export default {
  name: 'ExamScoreByExamDialog',
  props: { visible: { type: Boolean, default: false }, row: { type: Object, default: null } },
  data() {
    return { loading: false, list: [], stat: { total_participants: 0, actual_participants: 0, passed: 0, pass_rate: 0, avg_score: 0 } }
  },
  computed: {
    statCards() {
      return [
        { label: '应考人数', value: this.stat.total_participants },
        { label: '实考人数', value: this.stat.actual_participants },
        { label: '通过人数', value: this.stat.passed },
        { label: '通过率(%)', value: this.stat.pass_rate },
        { label: '平均分', value: this.stat.avg_score },
      ]
    },
  },
  watch: { visible(val) { if (val) this.load() } },
  methods: {
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    async load() {
      if (!this.row || !this.row.exam_id) return
      this.loading = true; this.list = []
      try {
        const r = await getScoreByExam(this.row.exam_id, { page: 1, limit: 100 })
        if (r.code === 0) { this.list = r.data.list || []; this.stat = r.data.stat || this.stat }
      } catch (e) {}
      this.loading = false
    },
  },
}
</script>
