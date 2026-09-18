<!-- 文件：admin/src/views/ai/agents/churn.vue（v1.67.0 催办智能体） -->
<template>
  <div class="ch-page">
    <div class="crumb"><span>AI智能平台</span><i class="el-icon-arrow-right"></i><span>业务智能体</span><i class="el-icon-arrow-right"></i><span class="cur">催办智能体</span></div>

    <div class="toolbar">
      <el-select v-model="type" size="small" placeholder="任务类型" clearable style="width:130px" @change="load">
        <el-option v-for="(r, k) in rules" :key="k" :label="r.name" :value="k" />
      </el-select>
      <el-button size="small" icon="el-icon-refresh" style="margin-left:12px;" @click="load">刷新</el-button>
      <el-button size="small" type="primary" icon="el-icon-alarm-clock" @click="load">手动触发检测</el-button>
    </div>

    <div class="panel">
      <div class="panel-head">待催办任务（共 {{ total }} 条）</div>
      <el-table :data="list" v-loading="loading" size="small" border stripe>
        <el-table-column prop="task_type_text" label="任务类型" width="100" align="center" />
        <el-table-column prop="title" label="任务编号" min-width="140" />
        <el-table-column prop="overdue_text" label="超时时长" width="110" align="center" />
        <el-table-column label="紧急度" width="90" align="center">
          <template slot-scope="s"><el-tag :type="{ high: 'danger', medium: 'warning', low: 'success' }[s.row.urgency]" size="mini">{{ { high: '紧急', medium: '中等', low: '一般' }[s.row.urgency] }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="churn_count" label="催办次数" width="90" align="center" />
        <el-table-column label="操作" width="100" align="center">
          <template slot-scope="s"><el-button type="text" size="mini" @click="doChurn(s.row)">催办</el-button></template>
        </el-table-column>
      </el-table>
      <div class="pager"><span>共 {{ total }} 条</span></div>
    </div>

    <div class="panel">
      <div class="panel-head">催办规则配置</div>
      <el-table :data="ruleList" size="small" border>
        <el-table-column prop="name" label="任务类型" width="100" />
        <el-table-column label="超时阈值(小时)" width="130" align="center">
          <template slot-scope="s"><el-input v-model="s.row.timeout_h" size="mini" style="width:70px" /></template>
        </el-table-column>
        <el-table-column label="催办间隔(小时)" width="130" align="center">
          <template slot-scope="s"><el-input v-model="s.row.interval_h" size="mini" style="width:70px" /></template>
        </el-table-column>
        <el-table-column label="升级阈值(次)" width="120" align="center">
          <template slot-scope="s"><el-input v-model="s.row.escalate" size="mini" style="width:70px" /></template>
        </el-table-column>
        <el-table-column prop="channel" label="推送渠道" width="110" align="center" />
      </el-table>
      <el-button size="small" type="primary" style="margin-top:10px;" @click="saveRules">保存配置</el-button>
    </div>
  </div>
</template>

<script>
import { getChurnTasks, executeChurn, getChurnRules, saveChurnRules } from '@/api/aiAgentBiz'

export default {
  name: 'AiAgentChurn',
  data () {
    return { list: [], total: 0, loading: false, type: '', rules: {}, ruleList: [] }
  },
  mounted () { this.load(); this.loadRules() },
  methods: {
    async load () {
      this.loading = true
      try {
        const r = await getChurnTasks({ page: 1, limit: 20, task_type: this.type })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    async loadRules () {
      try { const r = await getChurnRules(); if (r.code === 0) { this.rules = Object.fromEntries((r.data.list || []).map(x => [x.task_type, x])); this.ruleList = r.data.list || [] } } catch (e) {}
    },
    async doChurn (row) {
      try {
        const r = await executeChurn({ task_type: row.task_type, task_id: row.task_id })
        if (r.code === 0) { this.$message.success(r.data.escalated ? '已催办并升级' : '已催办'); this.load() } else this.$message.error(r.msg || '催办失败')
      } catch (e) { this.$message.error('催办失败') }
    },
    async saveRules () {
      try { const r = await saveChurnRules(this.ruleList); if (r.code === 0) this.$message.success('规则已保存') } catch (e) { this.$message.error('保存失败') }
    }
  }
}
</script>

<style scoped>
.crumb { padding: 10px 16px; background: #fff; border-bottom: 1px solid #e8e8e8; font-size: 13px; color: #909399; }
.crumb i { margin: 0 6px; }
.crumb .cur { color: #303133; }
.toolbar { display: flex; align-items: center; padding: 12px 16px; }
.panel { background: #fff; border: 1px solid #ebeef5; border-radius: 8px; margin: 0 16px 16px; padding: 12px 16px; }
.panel-head { font-weight: 600; margin-bottom: 8px; }
.pager { display: flex; align-items: center; justify-content: space-between; padding-top: 10px; }
</style>
