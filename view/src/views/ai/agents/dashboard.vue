<!-- 文件：admin/src/views/ai/agents/dashboard.vue（v1.67.0 智能体总览） -->
<template>
  <div class="ad-page">
    <div class="crumb"><span>AI智能平台</span><i class="el-icon-arrow-right"></i><span>业务智能体</span><i class="el-icon-arrow-right"></i><span class="cur">智能体总览</span></div>

    <div class="cards">
      <div class="card"><div class="card-label">今日执行任务</div><div class="card-value">{{ d.today_count || 0 }}</div></div>
      <div class="card o"><div class="card-label">待处理事项</div><div class="card-value">{{ d.pending || 0 }}</div></div>
      <div class="card g"><div class="card-label">处理成功率</div><div class="card-value">{{ d.success_rate || 0 }}%</div></div>
    </div>

    <div class="agent-cards">
      <div v-for="a in d.agents" :key="a.code" class="agent-card">
        <div class="a-head"><span class="a-icon">{{ a.icon }}</span><span class="a-name">{{ a.name }}</span><el-tag size="mini" type="success">● 运行中</el-tag></div>
        <div class="a-row">今日处理：{{ a.today_count }} 件</div>
        <div class="a-row">待处理：{{ a.pending }} 件</div>
        <div class="a-row">成功率：{{ a.success_rate }}%</div>
        <el-button size="small" type="text" @click="goAgent(a.code)">查看详情</el-button>
      </div>
    </div>

    <div class="panel">
      <div class="panel-head">执行日志（最近 20 条）</div>
      <el-table :data="d.logs || []" size="small" border stripe>
        <el-table-column prop="executed_at" label="时间" width="150" />
        <el-table-column prop="agent_name" label="智能体" width="110" />
        <el-table-column prop="decision_result" label="动作" width="90">
          <template slot-scope="s">{{ decisionText(s.row.decision_result) }}</template>
        </el-table-column>
        <el-table-column label="结果" width="90" align="center">
          <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="summary" label="详情" min-width="220" show-overflow-tooltip />
      </el-table>
    </div>
  </div>
</template>

<script>
import { getAgentDashboard } from '@/api/aiAgentBiz'

export default {
  name: 'AiAgentDashboard',
  data () { return { d: {} } },
  mounted () { this.load() },
  methods: {
    async load () { try { const r = await getAgentDashboard(); if (r.code === 0) this.d = r.data || {} } catch (e) {} },
    decisionText (v) { return { approved: '通过', rejected: '驳回', pending: '待定' }[v] || v || '-' },
    goAgent (code) {
      const map = { approval_assistant: '/ai/agents/approval', churn_agent: '/ai/agents/churn', order_processor: '/ai/agents/order' }
      if (map[code]) this.$router.push(map[code])
    }
  }
}
</script>

<style scoped>
.crumb { padding: 10px 16px; background: #fff; border-bottom: 1px solid #e8e8e8; font-size: 13px; color: #909399; }
.crumb i { margin: 0 6px; }
.crumb .cur { color: #303133; }
.cards { display: flex; gap: 14px; padding: 14px 16px; }
.card { flex: 1; background: #fff; border: 1px solid #ebeef5; border-radius: 8px; padding: 14px; }
.card.o .card-value { color: #e6a23c; }
.card.g .card-value { color: #67c23a; }
.card-label { font-size: 12px; color: #909399; }
.card-value { font-size: 20px; font-weight: 600; color: #409eff; margin: 6px 0 2px; }
.agent-cards { display: flex; gap: 14px; padding: 0 16px 14px; }
.agent-card { flex: 1; background: #fff; border: 1px solid #ebeef5; border-radius: 8px; padding: 14px; }
.a-head { display: flex; align-items: center; gap: 8px; margin-bottom: 10px; }
.a-icon { font-size: 22px; }
.a-name { font-weight: 600; flex: 1; }
.a-row { font-size: 13px; color: #606266; margin-bottom: 6px; }
.panel { background: #fff; border: 1px solid #ebeef5; border-radius: 8px; margin: 0 16px 16px; padding: 12px 16px; }
.panel-head { font-weight: 600; margin-bottom: 8px; }
</style>
