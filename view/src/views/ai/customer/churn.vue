<!-- 文件：admin/src/views/ai/customer/churn.vue（v1.66.0 客户流失预警） -->
<template>
  <div class="churn-page">
    <div class="crumb"><span>AI智能平台</span><i class="el-icon-arrow-right"></i><span>客户智能</span><i class="el-icon-arrow-right"></i><span class="cur">流失预警</span></div>

    <!-- 统计卡 -->
    <div class="cards">
      <div class="card r"><div class="card-label">高风险客户</div><div class="card-value">{{ stats.high || 0 }}</div></div>
      <div class="card o"><div class="card-label">中风险客户</div><div class="card-value">{{ stats.medium || 0 }}</div></div>
      <div class="card g"><div class="card-label">低风险客户</div><div class="card-value">{{ stats.low || 0 }}</div></div>
      <div class="card b"><div class="card-label">已挽回客户</div><div class="card-value">{{ stats.recovered || 0 }}</div></div>
    </div>

    <!-- 筛选 -->
    <div class="toolbar">
      <span class="lbl">风险等级：</span>
      <el-select v-model="level" size="small" placeholder="全部" clearable style="width:130px" @change="loadList">
        <el-option label="高风险" value="high" />
        <el-option label="中风险" value="medium" />
        <el-option label="低风险" value="low" />
      </el-select>
      <el-input v-model="keyword" size="small" placeholder="客户名称" clearable style="width:180px;margin-left:12px;" @keyup.enter.native="loadList" />
      <el-button size="small" icon="el-icon-search" @click="loadList">查询</el-button>
      <el-button size="small" @click="reset">重置</el-button>
      <el-button size="small" type="primary" icon="el-icon-download" @click="doExport">导出</el-button>
    </div>

    <!-- 列表 -->
    <div class="panel">
      <el-table :data="list" v-loading="loading" size="small" border stripe>
        <el-table-column type="index" label="#" width="50" align="center" />
        <el-table-column prop="customer_name" label="客户名称" min-width="130" />
        <el-table-column prop="risk_score" label="风险评分" width="90" align="center" sortable />
        <el-table-column label="风险等级" width="100" align="center">
          <template slot-scope="s"><el-tag :type="s.row.risk_level_tag" size="mini">{{ s.row.risk_level_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="days_since_last_order" label="距上次购买" width="100" align="center">
          <template slot-scope="s">{{ s.row.days_since_last_order != null ? s.row.days_since_last_order + '天' : '-' }}</template>
        </el-table-column>
        <el-table-column prop="churn_reason" label="流失原因" min-width="200" show-overflow-tooltip>
          <template slot-scope="s">{{ s.row.churn_reason ? s.row.churn_reason.slice(0, 80) : '未分析' }}</template>
        </el-table-column>
        <el-table-column label="操作" width="140" align="center" fixed="right">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="openRecover(s.row)">挽回</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <span>共 {{ total }} 条</span>
        <el-pagination background layout="prev, pager, next" :total="total" :page-size="10" :current-page.sync="page" @current-change="loadList" />
      </div>
    </div>

    <!-- 挽回策略弹窗 -->
    <el-dialog :title="'挽回策略 - ' + (current.customer_name || '')" :visible.sync="recoverVisible" width="640px" top="6vh">
      <div v-if="current.customer_name" class="rec-body">
        <div class="rec-head">风险评分：{{ current.risk_score }} 分｜<el-tag :type="current.risk_level_tag" size="mini">{{ current.risk_level_text }}</el-tag></div>
        <div class="p-block">
          <div class="p-title">🤖 AI流失原因分析</div>
          <div class="p-ai" v-loading="analyzing">{{ churnReason || '点击「生成分析」获取' }}</div>
          <el-button v-if="!churnReason" size="small" type="primary" style="margin-top:6px;" :loading="analyzing" @click="doAnalyze">生成分析</el-button>
        </div>
        <div class="p-block">
          <div class="p-title">📋 推荐挽回策略</div>
          <div v-if="strategies.length" class="strategy-list">
            <div v-for="s in strategies" :key="s.id" class="strategy-item">
              <div class="s-name">{{ s.strategy_name }}<el-tag v-if="s.is_default" size="mini" type="warning" style="margin-left:6px;">推荐</el-tag></div>
              <div class="s-desc">{{ s.description }}</div>
              <div class="s-meta">预计成功率 {{ s.expected_success_rate }}%｜预计成本 {{ s.estimated_cost }}</div>
              <el-button size="mini" type="primary" @click="doExecute(s)">执行此策略</el-button>
            </div>
          </div>
          <el-empty v-else description="暂无推荐策略" :image-size="50" />
        </div>
        <div class="p-block">
          <div class="p-title">🕘 挽回记录</div>
          <div v-if="actions.length" class="action-list">
            <div v-for="a in actions" :key="a.id" class="action-item">
              {{ a.create_time }}｜{{ a.strategy_name }}｜{{ a.executor || '-' }}｜{{ statusText(a) }}
            </div>
          </div>
          <span v-else class="none">暂无挽回记录</span>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getChurnOverview, getChurnList, analyzeChurn, getChurnStrategies, executeChurnStrategy, getChurnActions, exportChurnFile } from '@/api/aiCustomer'

export default {
  name: 'AiCustomerChurn',
  data () {
    return {
      stats: {}, list: [], total: 0, page: 1, loading: false,
      level: '', keyword: '',
      recoverVisible: false, current: {}, churnReason: '', analyzing: false, strategies: [], actions: []
    }
  },
  mounted () { this.loadStats(); this.loadList() },
  methods: {
    async loadStats () {
      try { const r = await getChurnOverview(); if (r.code === 0) this.stats = r.data || {} } catch (e) {}
    },
    async loadList () {
      this.loading = true
      try {
        const r = await getChurnList({ page: this.page, limit: 10, risk_level: this.level, keyword: this.keyword })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    reset () { this.level = ''; this.keyword = ''; this.page = 1; this.loadList() },
    statusText (a) {
      const es = ['待执行', '执行中', '已完成', '失败'][a.execute_status] || '待执行'
      const res = ['进行中', '成功', '失败'][a.result] || '进行中'
      return es + '｜' + res
    },
    async openRecover (row) {
      this.current = row
      this.churnReason = ''
      this.strategies = []
      this.actions = []
      this.recoverVisible = true
      try {
        const r = await getChurnStrategies(row.customer_id)
        if (r.code === 0) this.strategies = r.data.list || []
      } catch (e) {}
      this.loadActions()
    },
    async doAnalyze () {
      this.analyzing = true
      try {
        const r = await analyzeChurn(this.current.customer_id)
        if (r.code === 0) this.churnReason = r.data.reason || ''
      } catch (e) {} finally { this.analyzing = false }
    },
    async doExecute (s) {
      try {
        const r = await executeChurnStrategy({ customer_id: this.current.customer_id, strategy_id: s.id, risk_id: this.current.id || 0 })
        if (r.code === 0) { this.$message.success('策略已执行'); this.loadActions(); this.loadStats() } else this.$message.error(r.msg || '执行失败')
      } catch (e) { this.$message.error('执行失败') }
    },
    async loadActions () {
      try {
        const r = await getChurnActions(this.current.customer_id)
        if (r.code === 0) this.actions = r.data.list || []
      } catch (e) {}
    },
    async doExport () {
      try { await exportChurnFile({ risk_level: this.level }); this.$message.success('导出已开始') } catch (e) { this.$message.error('导出失败') }
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
.card.r .card-value { color: #f56c6c; }
.card.o .card-value { color: #e6a23c; }
.card.g .card-value { color: #67c23a; }
.card.b .card-value { color: #409eff; }
.card-label { font-size: 12px; color: #909399; }
.card-value { font-size: 20px; font-weight: 600; margin: 6px 0 2px; }
.toolbar { display: flex; align-items: center; padding: 0 16px 14px; }
.lbl { font-size: 13px; color: #606266; }
.panel { background: #fff; border: 1px solid #ebeef5; border-radius: 8px; margin: 0 16px 16px; padding: 12px 16px; }
.pager { display: flex; align-items: center; justify-content: space-between; padding-top: 10px; }
.p-block { background: #f5f7fa; border-radius: 6px; padding: 10px 12px; margin-bottom: 10px; }
.p-title { font-weight: 600; margin-bottom: 6px; }
.p-ai { font-size: 13px; line-height: 1.7; white-space: pre-wrap; }
.strategy-item { border: 1px solid #ebeef5; border-radius: 6px; padding: 8px 10px; margin-bottom: 8px; background: #fff; }
.s-name { font-weight: 600; }
.s-desc { font-size: 12px; color: #606266; margin: 4px 0; }
.s-meta { font-size: 12px; color: #909399; margin-bottom: 6px; }
.action-item { font-size: 12px; color: #606266; padding: 2px 0; }
.none { font-size: 12px; color: #909399; }
</style>
