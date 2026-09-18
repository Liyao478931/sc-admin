<!-- 文件：admin/src/views/ai/customer/value.vue（v1.66.0 客户价值分析） -->
<template>
  <div class="cv-page">
    <div class="crumb"><span>AI智能平台</span><i class="el-icon-arrow-right"></i><span>客户智能</span><i class="el-icon-arrow-right"></i><span class="cur">客户价值分析</span></div>

    <div class="toolbar">
      <span class="lbl">分析周期：</span>
      <el-select v-model="period" size="small" style="width:130px" @change="loadAll">
        <el-option :label="currentPeriod" :value="currentPeriod" />
      </el-select>
      <el-button size="small" icon="el-icon-refresh" style="margin-left:12px;" @click="loadAll">刷新</el-button>
    </div>

    <!-- 指标卡 -->
    <div class="cards">
      <div class="card"><div class="card-label">总客户数</div><div class="card-value">{{ overview.total_customers || 0 }}</div><div class="card-sub">统计周期内有交易</div></div>
      <div class="card g"><div class="card-label">高价值客户</div><div class="card-value">{{ overview.high_value || 0 }}</div><div class="card-sub">{{ pct(overview.high_value) }}%</div></div>
      <div class="card o"><div class="card-label">中等价值</div><div class="card-value">{{ overview.medium_value || 0 }}</div><div class="card-sub">{{ pct(overview.medium_value) }}%</div></div>
      <div class="card gr"><div class="card-label">低价值</div><div class="card-value">{{ overview.low_value || 0 }}</div><div class="card-sub">{{ pct(overview.low_value) }}%</div></div>
      <div class="card r"><div class="card-label">流失客户</div><div class="card-value">{{ overview.churn_customers || 0 }}</div><div class="card-sub">{{ pct(overview.churn_customers) }}%</div></div>
    </div>

    <!-- 图表 -->
    <div class="charts">
      <div class="panel"><div class="panel-head">客户价值分布</div><div ref="pieChart" class="chart-sm"></div></div>
      <div class="panel"><div class="panel-head">客户价值趋势（季度）</div><div ref="trendChart" class="chart-sm"></div></div>
      <div class="panel wide"><div class="panel-head">RFM 三维分布（气泡=购买频次）</div><div ref="rfmChart" class="chart-lg"></div></div>
    </div>

    <!-- 分层明细 -->
    <div class="panel">
      <div class="panel-head"><span>客户分层明细</span><span class="hint">共 {{ listTotal }} 家</span></div>
      <el-table :data="list" v-loading="loading" size="small" border stripe>
        <el-table-column type="index" label="#" width="50" align="center" />
        <el-table-column prop="customer_name" label="客户名称" min-width="140" />
        <el-table-column prop="customer_type" label="价值类型" min-width="110" align="center">
          <template slot-scope="s"><el-tag size="mini">{{ s.row.customer_type }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="r_value" label="R值(天)" width="80" align="center" sortable />
        <el-table-column prop="f_value" label="F值(次)" width="80" align="center" sortable />
        <el-table-column prop="m_value" label="M值(元)" width="110" align="right" sortable>
          <template slot-scope="s">{{ fmtMoney(s.row.m_value) }}</template>
        </el-table-column>
        <el-table-column prop="total_score" label="综合评分" width="90" align="center" sortable />
        <el-table-column prop="rank" label="排名" width="70" align="center" />
        <el-table-column label="操作" width="100" align="center">
          <template slot-scope="s"><el-button type="text" size="mini" @click="openProfile(s.row.customer_id)">查看画像</el-button></template>
        </el-table-column>
      </el-table>
      <div class="pager">
        <span>共 {{ listTotal }} 条</span>
        <el-pagination background layout="prev, pager, next" :total="listTotal" :page-size="10" :current-page.sync="page" @current-change="loadList" />
      </div>
    </div>

    <!-- 客户画像弹窗 -->
    <el-dialog :title="'客户画像 - ' + (profile.customer ? profile.customer.customer_name : '')" :visible.sync="profileVisible" width="680px" top="6vh">
      <div v-if="profile.customer" class="profile-body">
        <div class="two-col">
          <div class="p-block">
            <div class="p-title">基本信息</div>
            <div class="p-line">编码：{{ profile.customer.customer_code || '-' }}</div>
            <div class="p-line">等级：{{ profile.customer.customer_level || '-' }}</div>
            <div class="p-line">区域：{{ profile.customer.region || '-' }}</div>
            <div class="p-line">联系人：{{ profile.customer.contact_person || '-' }}</div>
          </div>
          <div class="p-block">
            <div class="p-title">价值评分</div>
            <div class="p-line">类型：{{ profile.rfm ? profile.rfm.customer_type : '未分层' }}</div>
            <div class="p-line">综合评分：{{ profile.rfm ? profile.rfm.total_score : '-' }} 分</div>
            <div class="p-line">排名：{{ profile.rfm ? '第' + profile.rfm.rank + '位' : '-' }}</div>
          </div>
        </div>
        <div class="p-block">
          <div class="p-title">交易概览</div>
          <div class="p-line">累计订单：{{ profile.trade.order_count }} 单｜累计金额：¥{{ fmtMoney(profile.trade.total_amount) }}｜最近购买：{{ profile.trade.last_order_date || '-' }}</div>
          <div class="p-line">客单价：¥{{ fmtMoney(profile.trade.avg_order_value) }}｜近3月消费变化：{{ profile.trade.recent3_trend_pct >= 0 ? '+' : '' }}{{ profile.trade.recent3_trend_pct }}%</div>
        </div>
        <div class="p-block">
          <div class="p-title">🤖 AI洞察</div>
          <div class="p-ai">{{ profile.ai_insight || '生成中...' }}</div>
        </div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import echarts from '@/utils/echarts'
import { getCustomerValueOverview, getCustomerValueList, getCustomerProfile, getCustomerValueTrend, getRfmDistribution } from '@/api/aiCustomer'

export default {
  name: 'AiCustomerValue',
  data () {
    return {
      period: '',
      overview: {},
      list: [], listTotal: 0, page: 1, loading: false,
      profile: {}, profileVisible: false,
      pieChart: null, trendChart: null, rfmChart: null
    }
  },
  computed: {
    currentPeriod () { return this.period || (new Date().getFullYear() + '-' + String(new Date().getMonth() + 1).padStart(2, '0')) }
  },
  mounted () { this.loadAll() },
  beforeDestroy () { [this.pieChart, this.trendChart, this.rfmChart].forEach(c => c && c.dispose()) },
  methods: {
    pct (v) { const t = this.overview.total_customers || 0; return t ? (v / t * 100).toFixed(1) : 0 },
    fmtMoney (v) { v = Number(v) || 0; return v >= 10000 ? (v / 10000).toFixed(1) + '万' : v.toFixed(0) },
    async loadAll () {
      this.loadOverview(); this.loadList(); this.loadTrend(); this.loadRfm()
    },
    async loadOverview () {
      try { const r = await getCustomerValueOverview({ period: this.period }); if (r.code === 0) { this.overview = r.data || {}; this.renderPie() } } catch (e) {}
    },
    async loadList () {
      this.loading = true
      try { const r = await getCustomerValueList({ period: this.period, page: this.page, limit: 10 }); if (r.code === 0) { this.list = r.data.list || []; this.listTotal = r.data.total || 0 } } catch (e) {} finally { this.loading = false }
    },
    async loadTrend () {
      try { const r = await getCustomerValueTrend(); if (r.code === 0) this.renderTrend(r.data.list || []) } catch (e) {}
    },
    async loadRfm () {
      try { const r = await getRfmDistribution({ period: this.period }); if (r.code === 0) this.renderRfm(r.data.list || []) } catch (e) {}
    },
    renderPie () {
      if (!this.$refs.pieChart) return
      if (!this.pieChart) this.pieChart = echarts.init(this.$refs.pieChart)
      const dist = this.overview.distribution || []
      this.pieChart.setOption({
        tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
        series: [{
          type: 'pie', radius: ['42%', '68%'],
          data: dist.map(d => ({ name: d.type, value: d.count })),
          label: { formatter: '{b}\n{d}%' }
        }]
      }, true)
    },
    renderTrend (list) {
      if (!this.$refs.trendChart) return
      if (!this.trendChart) this.trendChart = echarts.init(this.$refs.trendChart)
      this.trendChart.setOption({
        tooltip: { trigger: 'axis' },
        xAxis: { type: 'category', data: list.map(x => x.label) },
        yAxis: { type: 'value', name: '客户数' },
        series: [{ type: 'line', data: list.map(x => x.count), smooth: true, areaStyle: { opacity: 0.15 } }]
      }, true)
    },
    renderRfm (list) {
      if (!this.$refs.rfmChart) return
      if (!this.rfmChart) this.rfmChart = echarts.init(this.$refs.rfmChart)
      const maxF = Math.max(1, ...list.map(x => x.f))
      this.rfmChart.setOption({
        tooltip: { formatter: p => `${p.data[3]}<br/>R=${p.data[0]}天｜F=${p.data[4]}次｜M=${p.data[2]}万` },
        xAxis: { type: 'value', name: 'R（距上次购买天）' },
        yAxis: { type: 'value', name: 'M（万元）' },
        series: [{
          type: 'scatter', symbolSize: d => 6 + (d[4] / maxF) * 40,
          data: list.map(x => [x.r, x.m, x.type, x.name, x.f]),
          itemStyle: { color: '#409eff', opacity: 0.7 }
        }]
      }, true)
    },
    async openProfile (id) {
      try {
        const r = await getCustomerProfile(id)
        if (r.code === 0) { this.profile = r.data; this.profileVisible = true }
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.crumb { padding: 10px 16px; background: #fff; border-bottom: 1px solid #e8e8e8; font-size: 13px; color: #909399; }
.crumb i { margin: 0 6px; }
.crumb .cur { color: #303133; }
.toolbar { display: flex; align-items: center; padding: 12px 16px; background: #fff; }
.lbl { font-size: 13px; color: #606266; }
.cards { display: flex; gap: 14px; padding: 14px 16px; }
.card { flex: 1; background: #fff; border: 1px solid #ebeef5; border-radius: 8px; padding: 14px; }
.card.g .card-value { color: #67c23a; }
.card.o .card-value { color: #e6a23c; }
.card.gr .card-value { color: #909399; }
.card.r .card-value { color: #f56c6c; }
.card-label { font-size: 12px; color: #909399; }
.card-value { font-size: 20px; font-weight: 600; color: #409eff; margin: 6px 0 2px; }
.card-sub { font-size: 12px; color: #909399; }
.charts { display: flex; flex-wrap: wrap; gap: 14px; padding: 0 16px 14px; }
.panel { background: #fff; border: 1px solid #ebeef5; border-radius: 8px; padding: 12px 16px; flex: 1; min-width: 300px; margin-bottom: 14px; }
.panel.wide { flex-basis: 100%; }
.panel-head { font-weight: 600; margin-bottom: 8px; display: flex; justify-content: space-between; }
.hint { font-weight: 400; font-size: 12px; color: #909399; }
.chart-sm { height: 240px; }
.chart-lg { height: 300px; }
.pager { display: flex; align-items: center; justify-content: space-between; padding-top: 10px; }
.profile-body .two-col { display: flex; gap: 16px; }
.p-block { background: #f5f7fa; border-radius: 6px; padding: 10px 12px; margin-bottom: 10px; flex: 1; }
.p-title { font-weight: 600; margin-bottom: 6px; }
.p-line { font-size: 13px; color: #606266; margin-bottom: 4px; }
.p-ai { font-size: 13px; color: #303133; line-height: 1.7; white-space: pre-wrap; }
</style>
