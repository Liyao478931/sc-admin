<!--
  文件：admin/src/views/approval/Statistics.vue
  功能：审批统计（统一审批管理 · 数据驾驶舱）— 顶部标题栏 / 筛选 / KPI / 3 图表 / 明细表 / 导出
  权限：approval:statistics:view（页面）/ approval:statistics:export（导出）
-->
<template>
  <div class="dashboard-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>统一审批</el-breadcrumb-item>
      <el-breadcrumb-item>审批统计</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 顶部标题栏 -->
    <div class="top-bar">
      <div class="top-left">
        <span class="top-title">📊 审批统计</span>
        <span class="status-dot" :class="{ offline: !dataOk }" />
        <span class="status-text">{{ dataOk ? '数据实时' : '数据更新中…' }}</span>
      </div>
      <div class="top-right">
        <span class="live-time">{{ now }}</span>
        <el-button size="small" :icon="refreshing ? 'el-icon-loading' : 'el-icon-refresh'" @click="loadData">刷新数据</el-button>
      </div>
    </div>

    <!-- 筛选条件 -->
    <div class="filter-bar">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="统计时间">
          <el-date-picker v-model="query.dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:230px" />
        </el-form-item>
        <el-form-item label="业务类型">
          <el-select v-model="query.biz_type" clearable placeholder="全部类型" style="width:140px">
            <el-option v-for="b in bizTypes" :key="b.code" :label="b.name" :value="b.code" />
          </el-select>
        </el-form-item>
        <el-form-item label="审批人">
          <el-select v-model="query.approver_id" clearable filterable placeholder="全部审批人" style="width:140px">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleQuery">查询</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- KPI 指标卡 -->
    <el-row :gutter="16" class="kpi-row">
      <el-col :span="6"><div class="kpi-card"><div class="kpi-icon" style="background:#ECF5FF;color:#409EFF"><i class="el-icon-document" /></div><div class="kpi-num">{{ kpi.total_count.value }}</div><div class="kpi-label">总审批数</div></div></el-col>
      <el-col :span="6"><div class="kpi-card"><div class="kpi-icon" style="background:#FDF6EC;color:#E6A23C"><i class="el-icon-time" /></div><div class="kpi-num">{{ formatDuration(kpi.avg_duration.value) }}</div><div class="kpi-label">平均审批时长（小时）</div></div></el-col>
      <el-col :span="6"><div class="kpi-card"><div class="kpi-icon" style="background:#FEF0F0;color:#F56C6C"><i class="el-icon-warning" /></div><div class="kpi-num" :style="overdueWarn ? 'color:#F56C6C' : ''">{{ kpi.overdue_rate.value }}%</div><div class="kpi-label">超时率</div></div></el-col>
      <el-col :span="6"><div class="kpi-card"><div class="kpi-icon" style="background:#F0F9EB;color:#67C23A"><i class="el-icon-date" /></div><div class="kpi-num" style="color:#67C23A">{{ kpi.monthly_count.value }}</div><div class="kpi-label">本月审批数</div></div></el-col>
    </el-row>

    <!-- 图表区域 -->
    <el-row :gutter="16" class="chart-row">
      <el-col :span="12">
        <div class="chart-card">
          <div class="chart-header"><span class="chart-title"><i class="el-icon-pie-chart" /> 各业务类型审批数量排行</span></div>
          <div ref="typeChart" class="chart-box" />
        </div>
      </el-col>
      <el-col :span="12">
        <div class="chart-card">
          <div class="chart-header"><span class="chart-title"><i class="el-icon-user" /> 各审批人处理数量排行</span></div>
          <div ref="approverChart" class="chart-box" />
        </div>
      </el-col>
    </el-row>
    <el-row :gutter="16" class="chart-row">
      <el-col :span="24">
        <div class="chart-card">
          <div class="chart-header"><span class="chart-title"><i class="el-icon-trend-charts" /> 审批趋势图</span></div>
          <div ref="trendChart" class="chart-box" />
        </div>
      </el-col>
    </el-row>

    <!-- 明细表格 -->
    <div class="detail-card">
      <div class="detail-header">
        <span class="chart-title" style="color:#fff"><i class="el-icon-tickets" /> 📋 审批明细</span>
        <el-button v-permission="'approval:statistics:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出报表</el-button>
      </div>
      <el-table :data="detail" v-loading="loading" size="small" border class="detail-table" empty-text="暂无审批明细">
        <el-table-column type="index" label="#" width="55" align="center" />
        <el-table-column label="业务类型" width="130">
          <template slot-scope="s"><el-tag :type="bizTag(s.row.business_type)" size="mini">{{ s.row.business_name }}</el-tag></template>
        </el-table-column>
        <el-table-column label="业务编号" width="150">
          <template slot-scope="s"><span class="link-blue" @click="jumpBiz(s.row)">{{ s.row.business_no }}</span></template>
        </el-table-column>
        <el-table-column prop="business_title" label="业务标题" min-width="160" show-overflow-tooltip />
        <el-table-column prop="applicant_name" label="申请人" width="90" />
        <el-table-column label="审批人" width="90">
          <template slot-scope="s"><span class="link-blue" @click="jumpApprover(s.row)">{{ s.row.approver_name }}</span></template>
        </el-table-column>
        <el-table-column label="审批结果" width="100" align="center">
          <template slot-scope="s"><el-tag :type="resultTag(s.row.result)" size="mini">{{ s.row.result_label }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="submit_time" label="申请时间" width="160" align="center" />
        <el-table-column prop="finish_time" label="完成时间" width="160" align="center" />
        <el-table-column label="处理时长" width="100" align="center">
          <template slot-scope="s">{{ s.row.duration !== null && s.row.duration !== undefined ? s.row.duration + ' 小时' : '-' }}</template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
        :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50]"
        @current-change="handlePageChange" @size-change="handleSizeChange" />
    </div>
  </div>
</template>

<script>
import echarts from '@/utils/echarts'
import { getApprovalStatistics, exportApprovalStatistics, getUserOptions, getApprovalDefinitions } from '@/api/approval'

const BIZ_TAG = {
  purchase_request: 'primary',
  report: 'warning',
  leave: 'success',
  hazard: 'danger',
  purchase_order: '',
  contract: 'info'
}

export default {
  name: 'ApprovalStatistics',
  data () {
    const monthStart = this.today(1)
    return {
      now: '',
      dataOk: false, refreshing: false, loading: false, exporting: false,
      query: { dateRange: [monthStart, this.today()], biz_type: '', approver_id: null },
      bizTypes: [], userOptions: [],
      kpi: { total_count: { value: 0 }, avg_duration: { value: null }, overdue_rate: { value: 0 }, monthly_count: { value: 0 } },
      detail: [], total: 0, page: 1, pageSize: 10,
      charts: { type: null, approver: null, trend: null },
      timer: null
    }
  },
  computed: {
    overdueWarn () { return Number(this.kpi.overdue_rate.value) > 20 }
  },
  created () {
    this.now = this.fmtNow()
    this.timer = setInterval(() => { this.now = this.fmtNow() }, 1000)
    this.loadData()
    this.loadBizTypes()
    this.loadUsers()
  },
  beforeDestroy () { if (this.timer) clearInterval(this.timer) },
  methods: {
    today (day) {
      const d = new Date()
      if (day) d.setDate(1)
      const p = n => String(n).padStart(2, '0')
      return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`
    },
    fmtNow () {
      const d = new Date()
      const p = n => String(n).padStart(2, '0')
      return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`
    },
    bizTag (t) { return BIZ_TAG[t] || 'info' },
    resultTag (r) { return Number(r) === 2 ? 'success' : (Number(r) === 3 ? 'danger' : 'info') },
    formatDuration (v) { return (v === null || v === undefined || v === '') ? '-' : v },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.dateRange && this.query.dateRange.length === 2) {
        p.start_date = this.query.dateRange[0]
        p.end_date = this.query.dateRange[1]
      }
      if (this.query.biz_type) p.biz_type = this.query.biz_type
      if (this.query.approver_id) p.approver_id = this.query.approver_id
      return p
    },
    async loadData () {
      this.loading = true
      this.refreshing = true
      try {
        const r = await getApprovalStatistics(this.buildParams())
        if (r.code === 0 && r.data) {
          this.kpi = r.data.kpi || this.kpi
          this.detail = r.data.detail_table || []
          this.total = r.data.total || 0
          this.dataOk = true
          this.renderCharts(r.data.chart_data || {})
        }
      } catch (e) {} finally { this.loading = false; this.refreshing = false }
    },
    async loadBizTypes () {
      try {
        const dr = await getApprovalDefinitions({ page: 1, pageSize: 100 })
        if (dr.code === 0 && dr.data) {
          this.bizTypes = (dr.data.list || []).map(x => ({ code: x.business_type, name: x.business_name }))
        }
      } catch (e) {}
    },
    async loadUsers () {
      try {
        const r = await getUserOptions({ page: 1, pageSize: 100 })
        if (r.code === 0) this.userOptions = Array.isArray(r.data) ? r.data : (r.data.list || [])
      } catch (e) {}
    },
    handleQuery () { this.page = 1; this.loadData() },
    handleReset () {
      this.query = { dateRange: [this.today(1), this.today()], biz_type: '', approver_id: null }
      this.page = 1
      this.loadData()
    },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    renderCharts (cd) {
      this.$nextTick(() => {
        this.renderTypeChart(cd.type_ranking || [])
        this.renderApproverChart(cd.approver_ranking || [])
        this.renderTrendChart(cd.trend || [])
      })
    },
    renderTypeChart (data) {
      if (!this.charts.type && this.$refs.typeChart) this.charts.type = echarts.init(this.$refs.typeChart)
      if (!this.charts.type) return
      const items = data.slice().reverse()
      this.charts.type.setOption({
        tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
        grid: { left: 10, right: 40, top: 10, bottom: 10, containLabel: true },
        xAxis: { type: 'value', splitLine: { lineStyle: { color: '#f0f0f0' } } },
        yAxis: { type: 'category', data: items.map(x => x.name), axisLine: { lineStyle: { color: '#ddd' } } },
        series: [{
          type: 'bar', data: items.map(x => x.value), barWidth: 18,
          itemStyle: { color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [{ offset: 0, color: '#409EFF' }, { offset: 1, color: '#a0cfff' }]), borderRadius: [0, 4, 4, 0] },
          label: { show: true, position: 'right', color: '#606266' }
        }]
      }, true)
    },
    renderApproverChart (data) {
      if (!this.charts.approver && this.$refs.approverChart) this.charts.approver = echarts.init(this.$refs.approverChart)
      if (!this.charts.approver) return
      const items = data.slice().reverse()
      this.charts.approver.setOption({
        tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' } },
        grid: { left: 10, right: 40, top: 10, bottom: 10, containLabel: true },
        xAxis: { type: 'value', splitLine: { lineStyle: { color: '#f0f0f0' } } },
        yAxis: { type: 'category', data: items.map(x => x.name), axisLine: { lineStyle: { color: '#ddd' } } },
        series: [{
          type: 'bar', data: items.map(x => x.value), barWidth: 18,
          itemStyle: { color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [{ offset: 0, color: '#67C23A' }, { offset: 1, color: '#b3e19d' }]), borderRadius: [0, 4, 4, 0] },
          label: { show: true, position: 'right', color: '#606266' }
        }]
      }, true)
    },
    renderTrendChart (data) {
      if (!this.charts.trend && this.$refs.trendChart) this.charts.trend = echarts.init(this.$refs.trendChart)
      if (!this.charts.trend) return
      this.charts.trend.setOption({
        tooltip: { trigger: 'axis' },
        legend: { data: ['总审批数', '超时审批数'], top: 0, right: 0 },
        grid: { left: 10, right: 20, top: 34, bottom: 10, containLabel: true },
        xAxis: { type: 'category', data: data.map(x => x.date), axisLine: { lineStyle: { color: '#ddd' } } },
        yAxis: { type: 'value', splitLine: { lineStyle: { color: '#f0f0f0' } } },
        series: [
          { name: '总审批数', type: 'line', smooth: true, symbol: 'circle', data: data.map(x => x.total), lineStyle: { color: '#409EFF', width: 2 }, itemStyle: { color: '#409EFF' } },
          { name: '超时审批数', type: 'line', smooth: true, symbol: 'circle', data: data.map(x => x.overdue), lineStyle: { color: '#F56C6C', width: 2, type: 'dashed' }, itemStyle: { color: '#F56C6C' } }
        ]
      }, true)
    },
    jumpBiz (row) {
      if (Number(row.biz_id) > 0) {
        this.$message.info('业务单据详情跳转地址按实际模块路由配置')
      } else {
        this.$message.info('示例数据暂未关联业务单据')
      }
    },
    jumpApprover (row) {
      this.$router.push('/approval/history')
    },
    async handleExport () {
      this.exporting = true
      try {
        const response = await exportApprovalStatistics(this.buildParams())
        const url = URL.createObjectURL(new Blob([response.data]))
        const link = document.createElement('a')
        const now = new Date()
        const p = n => String(n).padStart(2, '0')
        const ts = `${now.getFullYear()}${p(now.getMonth() + 1)}${p(now.getDate())}_${p(now.getHours())}${p(now.getMinutes())}${p(now.getSeconds())}`
        link.href = url
        link.download = `审批统计_${ts}.xlsx`
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
        URL.revokeObjectURL(url)
        this.$message.success('导出成功')
      } catch (e) {} finally { this.exporting = false }
    }
  }
}
</script>

<style scoped>
.dashboard-page {
  padding: 16px;
  min-height: calc(100vh - 100px);
  background: linear-gradient(135deg, #0a1628 0%, #1a2a4a 100%);
  border-radius: 8px;
}
.breadcrumb { margin-bottom: 12px; }
.breadcrumb /deep/ .el-breadcrumb__inner { color: rgba(255, 255, 255, 0.75); }
.breadcrumb /deep/ .el-breadcrumb__separator { color: rgba(255, 255, 255, 0.4); }
.top-bar {
  display: flex; justify-content: space-between; align-items: center;
  background: linear-gradient(90deg, #1A1A2E 0%, #16213E 100%);
  padding: 16px 24px; border-radius: 8px;
  box-shadow: 0 2px 20px rgba(64, 158, 255, 0.15);
  margin-bottom: 14px;
}
.top-left { display: flex; align-items: center; gap: 10px; }
.top-title { font-size: 20px; font-weight: 600; color: #fff; }
.status-dot { width: 8px; height: 8px; border-radius: 50%; background: #67C23A; animation: pulse 1.5s infinite; }
.status-dot.offline { background: #F56C6C; animation: none; }
@keyframes pulse { 0% { box-shadow: 0 0 0 0 rgba(103, 194, 58, 0.6); } 70% { box-shadow: 0 0 0 8px rgba(103, 194, 58, 0); } 100% { box-shadow: 0 0 0 0 rgba(103, 194, 58, 0); } }
.status-text { font-size: 13px; color: rgba(255, 255, 255, 0.7); }
.top-right { display: flex; align-items: center; gap: 14px; }
.live-time { font-size: 14px; color: rgba(255, 255, 255, 0.8); }
.filter-bar {
  background: rgba(255, 255, 255, 0.05); padding: 12px 20px; border-radius: 8px;
  box-shadow: 0 2px 12px rgba(64, 158, 255, 0.08); margin-bottom: 14px;
}
.filter-bar /deep/ .el-form-item__label { color: rgba(255, 255, 255, 0.75); }
.kpi-row { margin-bottom: 14px; }
.kpi-card {
  background: linear-gradient(135deg, #ffffff 0%, #f5f9ff 100%);
  border-radius: 10px; padding: 20px 18px; text-align: center;
  box-shadow: 0 4px 20px rgba(64, 158, 255, 0.08);
  transition: transform 0.3s;
}
.kpi-card:hover { transform: translateY(-4px); }
.kpi-icon {
  width: 48px; height: 48px; border-radius: 50%; margin: 0 auto 10px;
  display: flex; align-items: center; justify-content: center; font-size: 24px;
}
.kpi-num { font-size: 32px; font-weight: 700; color: #303133; line-height: 1.1; }
.kpi-label { font-size: 14px; color: #909399; margin-top: 6px; }
.chart-row { margin-bottom: 14px; }
.chart-card {
  background: #fff; border-radius: 8px; overflow: hidden;
  box-shadow: 0 4px 20px rgba(64, 158, 255, 0.08);
}
.chart-header {
  background: #2C3E50; color: #fff; padding: 10px 16px;
  display: flex; justify-content: space-between; align-items: center;
}
.chart-title { color: #fff; font-size: 14px; font-weight: 600; }
.chart-box { height: 340px; }
.detail-card { background: #fff; border-radius: 8px; overflow: hidden; box-shadow: 0 4px 20px rgba(64, 158, 255, 0.08); }
.detail-header {
  background: #2C3E50; color: #fff; padding: 10px 16px;
  display: flex; justify-content: space-between; align-items: center;
}
.detail-table { width: 100%; }
.pager { margin: 16px; text-align: right; }
.link-blue { color: #409EFF; cursor: pointer; }
</style>
