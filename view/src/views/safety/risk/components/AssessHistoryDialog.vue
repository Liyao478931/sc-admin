<template>
  <el-dialog title="评估历史" :visible="visible" width="850px" append-to-body :close-on-click-modal="false" @update:visible="handleVisibleChange">
    <div v-loading="loading">
      <el-table :data="list" size="small" border max-height="420">
        <el-table-column prop="assessment_code" label="评估编号" width="170" />
        <el-table-column prop="assess_date" label="评估日期" width="110" align="center" />
        <el-table-column prop="l_score" label="L值" width="70" align="center" />
        <el-table-column prop="e_score" label="E值" width="70" align="center" />
        <el-table-column prop="c_score" label="C值" width="70" align="center" />
        <el-table-column prop="d_score" label="风险值" width="80" align="center" />
        <el-table-column label="风险等级" width="90" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="{ low: 'success', general: '', major: 'warning', critical: 'danger' }[row.risk_level] || 'info'">{{ row.level_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="assessor_name" label="评估人" width="90" align="center" />
        <el-table-column prop="remark" label="备注" min-width="120" show-overflow-tooltip />
      </el-table>
      <el-empty v-if="!loading && !list.length" description="暂无评估记录" />
    </div>
    <div slot="footer">
      <el-button size="small" @click="handleVisibleChange(false)">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getAssessHistory } from '@/api/safetyRisk'

export default {
  name: 'AssessHistoryDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null },
  },
  data() {
    return { loading: false, list: [] }
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
        const r = await getAssessHistory(this.row.id)
        if (r.code === 0) this.list = r.data.list || []
      } catch (e) {}
      this.loading = false
    },
  },
}
</script>
