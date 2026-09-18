<template>
  <el-dialog title="评测报告对比" :visible.sync="visible" width="720px" append-to-body>
    <el-form :model="form" label-width="110px" size="small">
      <el-form-item label="基准评测">
        <el-select v-model="form.task_id_1" filterable style="width: 100%;" placeholder="选择基准评测">
          <el-option v-for="t in completedTasks" :key="t.id" :label="t.task_name + '（' + t.create_time + '）'" :value="t.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="对比评测">
        <el-select v-model="form.task_id_2" filterable style="width: 100%;" placeholder="选择对比评测">
          <el-option v-for="t in completedTasks" :key="t.id" :label="t.task_name + '（' + t.create_time + '）'" :value="t.id" />
        </el-select>
      </el-form-item>
      <el-form-item>
        <el-button type="primary" size="small" :loading="loading" @click="doCompare">开始对比</el-button>
      </el-form-item>
    </el-form>

    <div v-if="result" class="compare-result">
      <div class="compare-head">
        <div class="cmp-side">
          <div class="cmp-name">{{ result.task_1.agent_name }}</div>
          <div class="cmp-time">{{ result.task_1.create_time }}</div>
        </div>
        <div class="cmp-vs">VS</div>
        <div class="cmp-side">
          <div class="cmp-name">{{ result.task_2.agent_name }}</div>
          <div class="cmp-time">{{ result.task_2.create_time }}</div>
        </div>
      </div>
      <el-table :data="result.compare" size="small" stripe>
        <el-table-column prop="label" label="指标" width="130" />
        <el-table-column prop="value_1" label="基准" width="100" />
        <el-table-column prop="value_2" label="对比" width="100" />
        <el-table-column label="变化" width="140">
          <template slot-scope="s">
            <el-tag size="mini" :type="s.row.improved ? 'success' : (s.row.delta === 0 ? 'info' : 'danger')">
              {{ s.row.delta > 0 ? '+' : '' }}{{ s.row.delta }}{{ s.row.improved ? ' ↑' : (s.row.delta === 0 ? '' : ' ↓') }}
            </el-tag>
          </template>
        </el-table-column>
      </el-table>
    </div>
    <div slot="footer">
      <el-button size="small" type="primary" @click="visible = false">关闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getEvalTasks, compareEvalTasks } from '../../../../api/aiEval'

export default {
  name: 'EvalReportCompareDialog',
  props: {
    agentList: { type: Array, default: () => [] }
  },
  data() {
    return {
      visible: false,
      loading: false,
      completedTasks: [],
      form: { task_id_1: '', task_id_2: '' },
      result: null
    }
  },
  methods: {
    async open(row) {
      this.visible = true
      this.result = null
      // 预选当前任务为基准
      this.form.task_id_1 = row.id || ''
      this.form.task_id_2 = ''
      try {
        const res = await getEvalTasks({ page: 1, limit: 100, status: 'completed' })
        this.completedTasks = res.data.list || []
      } catch (e) {}
    },
    async doCompare() {
      if (!this.form.task_id_1 || !this.form.task_id_2) return this.$message.warning('请选择两个评测任务')
      if (this.form.task_id_1 === this.form.task_id_2) return this.$message.warning('请选择两个不同的评测任务')
      this.loading = true
      try {
        const res = await compareEvalTasks({ task_id_1: this.form.task_id_1, task_id_2: this.form.task_id_2 })
        this.result = res.data || {}
      } catch (e) {}
      this.loading = false
    }
  }
}
</script>

<style scoped>
.compare-head { display: flex; align-items: center; justify-content: space-between; margin: 14px 0; padding: 12px; background: #f5f7fa; border-radius: 6px; }
.cmp-side { flex: 1; text-align: center; }
.cmp-name { font-weight: 600; }
.cmp-time { color: #909399; font-size: 12px; }
.cmp-vs { padding: 0 20px; color: #409eff; font-weight: 700; }
</style>
