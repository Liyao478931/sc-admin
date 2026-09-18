<template>
  <el-dialog title="员工考试成绩" :visible="visible" width="800px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <div v-loading="loading">
      <el-row :gutter="12" style="margin-bottom:12px;">
        <el-col :span="6" v-for="c in statCards" :key="c.label">
          <el-card shadow="never" :body-style="{ padding: '10px' }">
            <div style="font-size:18px;font-weight:600;">{{ c.value }}</div>
            <div style="font-size:12px;color:#909399;">{{ c.label }}</div>
          </el-card>
        </el-col>
      </el-row>
      <el-table :data="list" size="mini" border max-height="360">
        <el-table-column prop="exam_name" label="考试名称" min-width="140" show-overflow-tooltip />
        <el-table-column prop="paper_name" label="试卷名称" min-width="120" show-overflow-tooltip />
        <el-table-column prop="score" label="得分" width="70" align="center" />
        <el-table-column label="合格状态" width="90" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.is_pass == 1 ? 'success' : 'danger'">{{ row.pass_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="start_time" label="考试时间" width="160" align="center" />
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
import { getScoreByUser } from '@/api/trainingExam'

export default {
  name: 'ExamScoreByUserDialog',
  props: { visible: { type: Boolean, default: false }, row: { type: Object, default: null } },
  data() {
    return { loading: false, list: [], stat: { times: 0, passed: 0, failed: 0, avg_score: 0 } }
  },
  computed: {
    statCards() {
      return [
        { label: '参加考试次数', value: this.stat.times },
        { label: '合格次数', value: this.stat.passed },
        { label: '不合格次数', value: this.stat.failed },
        { label: '平均分', value: this.stat.avg_score },
      ]
    },
  },
  watch: { visible(val) { if (val) this.load() } },
  methods: {
    handleVisibleChange(val) { this.$emit('update:visible', val) },
    async load() {
      if (!this.row || !this.row.user_id) return
      this.loading = true; this.list = []
      try {
        const r = await getScoreByUser(this.row.user_id, { page: 1, limit: 100 })
        if (r.code === 0) { this.list = r.data.list || []; this.stat = r.data.stat || this.stat }
      } catch (e) {}
      this.loading = false
    },
  },
}
</script>
