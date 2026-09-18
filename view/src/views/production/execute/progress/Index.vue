<!--
  文件：admin/src/views/production/execute/progress/Index.vue
  功能：生产进度（统计卡片 + 状态分布/进度趋势图表 + 工单进度表格 + 进度详情抽屉 + 导出）
  权限：production:progress:view / export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>生产执行</el-breadcrumb-item>
      <el-breadcrumb-item>生产进度</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 筛选条件区域 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="工单编号"><el-input v-model="query.order_no" placeholder="请输入工单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="产品名称"><el-input v-model="query.product_name" placeholder="请输入产品名称" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="工单类型">
          <el-select v-model="query.order_type" clearable placeholder="全部" style="width:110px">
            <el-option label="生产工单" :value="1" />
            <el-option label="维修工单" :value="2" />
          </el-select>
        </el-form-item>
        <el-form-item label="工单状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in statusOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="延期状态">
          <el-select v-model="query.overdue_status" clearable placeholder="全部" style="width:110px">
            <el-option label="正常" :value="0" />
            <el-option label="即将延期（3天内）" :value="1" />
            <el-option label="已延期" :value="2" />
          </el-select>
        </el-form-item>
        <el-form-item label="计划日期">
          <el-date-picker v-model="query.dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:230px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">查询</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="6">
        <div class="stat-card stat-blue" @click="quickFilter('total')">
          <div class="stat-icon"><i class="el-icon-document" /></div>
          <div class="stat-info"><div class="stat-num" style="color:#409EFF">{{ cards.total }}</div><div class="stat-label">总工单数（点击查看）</div></div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-orange" @click="quickFilter('status2')">
          <div class="stat-icon"><i class="el-icon-loading" /></div>
          <div class="stat-info"><div class="stat-num" style="color:#E6A23C">{{ cards.in_progress }}</div><div class="stat-label">进行中（点击查看）</div></div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-green" @click="quickFilter('status4')">
          <div class="stat-icon"><i class="el-icon-check" /></div>
          <div class="stat-info"><div class="stat-num" style="color:#67C23A">{{ cards.completed }}</div><div class="stat-label">已完成（点击查看）</div></div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-red" @click="quickFilter('overdue2')">
          <div class="stat-icon"><i class="el-icon-warning" /></div>
          <div class="stat-info"><div class="stat-num" style="color:#F56C6C">{{ cards.overdue }}</div><div class="stat-label">已延期（点击查看）</div></div>
        </div>
      </el-col>
    </el-row>
    <el-row :gutter="16" class="stat-row stat-row2">
      <el-col :span="6" :offset="6">
        <div class="stat-card stat-blue">
          <div class="stat-icon"><i class="el-icon-data-line" /></div>
          <div class="stat-info"><div class="stat-num" style="color:#409EFF">{{ cards.avg_progress }}%</div><div class="stat-label">平均进度</div></div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-purple">
          <div class="stat-icon"><i class="el-icon-time" /></div>
          <div class="stat-info"><div class="stat-num" style="color:#9B59B6">{{ Number(cards.avg_duration || 0).toFixed(1) }} 小时</div><div class="stat-label">平均工时</div></div>
        </div>
      </el-col>
    </el-row>

    <!-- 图表区域 -->
    <el-card class="chart-card" shadow="never">
      <div slot="header" class="chart-header">
        <span class="chart-title">生产进度分析</span>
        <el-button type="text" icon="el-icon-refresh" @click="loadData">刷新图表</el-button>
      </div>
      <el-row :gutter="16">
        <el-col :span="12"><div ref="statusChart" class="chart-box" /></el-col>
        <el-col :span="12"><div ref="trendChart" class="chart-box" /></el-col>
      </el-row>
    </el-card>

    <!-- 操作按钮栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'production:progress:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出进度报表</el-button>
      </div>
      <span class="total-text">共 {{ total }} 个工单</span>
    </div>

    <!-- 工单进度表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe>
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="工单编号" width="150">
        <template slot-scope="s"><span class="link-blue" @click="$router.push(`/production/plan/order/detail/${s.row.id}`)">{{ s.row.order_no }}</span></template>
      </el-table-column>
      <el-table-column prop="product_name" label="产品名称" min-width="150" show-overflow-tooltip />
      <el-table-column label="工单类型" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.order_type_tag" size="mini">{{ s.row.order_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="计划数量" width="100" align="right"><template slot-scope="s">{{ Number(s.row.plan_quantity) }}</template></el-table-column>
      <el-table-column label="完成数量" width="110" align="right"><template slot-scope="s">{{ Number(s.row.completed_quantity) }} / {{ Number(s.row.plan_quantity) }}</template></el-table-column>
      <el-table-column label="进度" width="140">
        <template slot-scope="s">
          <div class="progress-cell">
            <el-progress :percentage="Number(s.row.progress)" :color="progressColor(s.row.progress)" :show-text="false" style="width:90px" />
            <span class="progress-text">{{ Number(s.row.progress) }}%</span>
          </div>
        </template>
      </el-table-column>
      <el-table-column label="已完成工序" width="130" align="center"><template slot-scope="s">已完成 {{ s.row.completed_processes || 0 }} / 总 {{ s.row.total_processes || 0 }} 道工序</template></el-table-column>
      <el-table-column label="设备工时" width="120" align="right"><template slot-scope="s">{{ Number(s.row.total_duration || 0).toFixed(1) }} 小时</template></el-table-column>
      <el-table-column label="计划完成日期" width="120" align="center">
        <template slot-scope="s"><span :class="{ 'overdue': s.row.overdue_status === 2 }">{{ s.row.planned_end_date || '-' }}</span></template>
      </el-table-column>
      <el-table-column label="工单状态" width="110" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="120" align="center" fixed="right">
        <template slot-scope="s"><el-button type="text" size="mini" @click="openDetail(s.row)">查看进度详情</el-button></template>
      </el-table-column>
    </el-table>

    <!-- 分页组件 -->
    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 工单进度详情抽屉 -->
    <el-drawer :title="`${detail.order?.order_no || ''} 生产进度详情`" :visible.sync="drawerVisible" size="800px">
      <div v-if="detail.order" class="drawer-body">
        <div class="sub-title">工单概要</div>
        <el-descriptions :column="3" border size="small">
          <el-descriptions-item label="工单编号">{{ detail.order.order_no }}</el-descriptions-item>
          <el-descriptions-item label="产品名称">{{ detail.order.product_name }}</el-descriptions-item>
          <el-descriptions-item label="工单状态">{{ detail.order.status_label }}</el-descriptions-item>
          <el-descriptions-item label="计划数量">{{ Number(detail.order.plan_quantity) }}</el-descriptions-item>
          <el-descriptions-item label="完成数量">{{ Number(detail.order.completed_quantity) }}</el-descriptions-item>
          <el-descriptions-item label="进度">{{ Number(detail.order.progress) }}%</el-descriptions-item>
          <el-descriptions-item label="计划完成日期">{{ detail.order.planned_end_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="负责人">{{ detail.order.responsible_person_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="设备总工时">{{ Number(detail.order.total_duration || 0).toFixed(1) }} 小时</el-descriptions-item>
        </el-descriptions>

        <div class="sub-title">工序进度</div>
        <el-table :data="detail.processes || []" size="small" border>
          <el-table-column prop="process_name" label="工序名称" min-width="110" />
          <el-table-column prop="workstation_name" label="关联工位" width="100" show-overflow-tooltip />
          <el-table-column prop="sort_order" label="顺序" width="60" align="center" />
          <el-table-column label="标准工时" width="90" align="right"><template slot-scope="s">{{ Number(s.row.standard_hours) }}h</template></el-table-column>
          <el-table-column label="实际工时" width="90" align="right"><template slot-scope="s">{{ Number(s.row.actual_hours) }}h</template></el-table-column>
          <el-table-column label="完成数量" width="90" align="right"><template slot-scope="s">{{ s.row.done_quantity }} / {{ Number(s.row.plan_quantity) }}</template></el-table-column>
          <el-table-column label="工序状态" width="90" align="center">
            <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
          </el-table-column>
        </el-table>

        <div class="sub-title">报工记录</div>
        <el-table :data="detail.reports || []" size="small" border>
          <el-table-column label="报工单编号" width="150">
            <template slot-scope="s"><span class="link-blue" @click="$router.push(`/production/report/detail/${s.row.id}`)">{{ s.row.report_no }}</span></template>
          </el-table-column>
          <el-table-column prop="process_name" label="工序" width="90" show-overflow-tooltip />
          <el-table-column prop="workstation_name" label="工位" width="90" show-overflow-tooltip />
          <el-table-column prop="device_name" label="设备" width="110" show-overflow-tooltip />
          <el-table-column prop="reporter_name" label="报工人" width="80" />
          <el-table-column label="完成数量" width="80" align="center"><template slot-scope="s">{{ s.row.quantity || 1 }}</template></el-table-column>
          <el-table-column label="工时" width="70" align="right"><template slot-scope="s">{{ Number(s.row.duration || 0) }}</template></el-table-column>
          <el-table-column prop="report_date" label="报工日期" width="100" align="center" />
          <el-table-column label="审核状态" width="80" align="center">
            <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
          </el-table-column>
        </el-table>
        <el-pagination class="mini-pager" background layout="prev, pager, next" :total="detail.report_total || 0" :page-size="5" :current-page="repPage" @current-change="repPageChange" />

        <div class="sub-title">材料消耗汇总</div>
        <el-table :data="detail.materials || []" size="small" border>
          <el-table-column prop="material_code" label="物料编码" width="120" />
          <el-table-column prop="material_name" label="物料名称" min-width="130" />
          <el-table-column prop="specification" label="规格型号" width="120" show-overflow-tooltip />
          <el-table-column prop="unit" label="单位" width="60" align="center" />
          <el-table-column label="使用数量合计" width="100" align="right"><template slot-scope="s">{{ s.row.total_qty }}</template></el-table-column>
        </el-table>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getProgressList, getProgressDetail, exportProgress } from '@/api/production'

export default {
  name: 'ProductionProgress',
  data () {
    return {
      statusOptions: { 0: '待派工', 1: '已派工', 2: '进行中', 3: '待质检', 4: '已完成', 5: '已关闭' },
      query: { order_no: '', product_name: '', order_type: '', status: '', overdue_status: '', dateRange: [] },
      cards: { total: 0, in_progress: 0, completed: 0, overdue: 0, avg_progress: 0, avg_duration: 0 },
      statusDist: { 0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0 },
      trend: { dates: [], avg: [], done: [] },
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false,
      drawerVisible: false, detail: {}, repPage: 1,
      charts: {}
    }
  },
  created () { this.loadData() },
  mounted () {
    this.$nextTick(() => this.initCharts())
    window.addEventListener('resize', this.handleResize)
  },
  beforeDestroy () {
    window.removeEventListener('resize', this.handleResize)
    Object.values(this.charts).forEach(c => { if (c) c.dispose() })
    this.charts = {}
  },
  methods: {
    progressColor (p) { const v = Number(p); if (v < 30) return '#F56C6C'; if (v < 70) return '#E6A23C'; return '#67C23A' },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.order_no) p.order_no = this.query.order_no
      if (this.query.product_name) p.product_name = this.query.product_name
      if (this.query.order_type !== '' && this.query.order_type !== null) p.order_type = this.query.order_type
      if (this.query.status !== '' && this.query.status !== null) p.status = this.query.status
      if (this.query.overdue_status !== '' && this.query.overdue_status !== null) p.overdue_status = this.query.overdue_status
      if (this.query.dateRange && this.query.dateRange.length === 2) {
        p.start_date = this.query.dateRange[0]
        p.end_date = this.query.dateRange[1]
      }
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getProgressList(this.buildParams())
        if (r.code === 0 && r.data) {
          this.cards = r.data.cards || this.cards
          this.statusDist = r.data.status_dist || this.statusDist
          this.trend = r.data.trend || { dates: [], avg: [], done: [] }
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.$nextTick(() => this.renderCharts())
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () { this.query = { order_no: '', product_name: '', order_type: '', status: '', overdue_status: '', dateRange: [] }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    quickFilter (type) {
      if (type === 'status2') { this.query.status = 2; this.query.overdue_status = '' }
      if (type === 'status4') { this.query.status = 4; this.query.overdue_status = '' }
      if (type === 'overdue2') { this.query.status = ''; this.query.overdue_status = 2 }
      if (type === 'total') { this.query.status = ''; this.query.overdue_status = '' }
      this.handleSearch()
    },
    handleResize () { Object.values(this.charts).forEach(c => { if (c) c.resize() }) },
    initCharts () {
      this.charts.status = echarts.init(this.$refs.statusChart)
      this.charts.trend = echarts.init(this.$refs.trendChart)
    },
    renderCharts () {
      if (!this.charts.status) this.initCharts()
      const statusText = this.statusOptions
      const colorMap = { 0: '#909399', 1: '#409EFF', 2: '#E6A23C', 3: '#9B59B6', 4: '#67C23A', 5: '#909399' }
      this.charts.status.setOption({
        title: { text: '工单状态分布', textStyle: { fontSize: 14 }, left: 'center' },
        tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
        legend: { bottom: 0 },
        series: [{
          name: '工单状态', type: 'pie', radius: ['40%', '65%'], center: ['50%', '48%'],
          label: { formatter: '{b} {d}%' },
          data: Object.entries(this.statusDist).filter(([k, v]) => v > 0).map(([k, v]) => ({ name: statusText[k] || k, value: v, itemStyle: { color: colorMap[k] } }))
        }]
      })
      this.charts.trend.setOption({
        title: { text: '工单进度趋势', textStyle: { fontSize: 14 } },
        tooltip: { trigger: 'axis' },
        legend: { data: ['平均进度', '已完成工单数'], top: 0, right: 10 },
        grid: { left: 60, right: 40, top: 40, bottom: 60 },
        xAxis: { type: 'category', data: this.trend.dates, axisLabel: { interval: 0, rotate: 30 } },
        yAxis: [{ type: 'value', name: '进度%', max: 100 }, { type: 'value', name: '数量' }],
        series: [
          { name: '平均进度', type: 'line', smooth: true, data: this.trend.avg, itemStyle: { color: '#409EFF' } },
          { name: '已完成工单数', type: 'line', smooth: true, yAxisIndex: 1, data: this.trend.done, itemStyle: { color: '#67C23A' }, lineStyle: { type: 'dashed' } }
        ]
      })
    },
    async openDetail (row) {
      this.drawerVisible = true
      this.detail = {}
      this.repPage = 1
      await this.loadDetail(row.id, 1)
    },
    async loadDetail (id, page) {
      try {
        const r = await getProgressDetail(id, { page: page || 1 })
        if (r.code === 0 && r.data) this.detail = r.data
      } catch (e) {}
    },
    async repPageChange (p) {
      this.repPage = p
      await this.loadDetail(this.detail.order ? this.detail.order.id : 0, p)
    },
    async handleExport () {
      this.exporting = true
      try {
        const params = { ...this.buildParams() }
        delete params.page
        delete params.pageSize
        const r = await exportProgress(params)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          const d = new Date()
          const pad = n => String(n).padStart(2, '0')
          a.href = url
          a.download = `生产进度报表_${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}_${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}.xlsx`
          a.click()
          window.URL.revokeObjectURL(url)
        }
      } catch (e) {} finally { this.exporting = false }
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.stat-row { margin-top: 16px; }
.stat-row2 { margin-top: 12px; }
.stat-card { display: flex; align-items: center; padding: 16px 20px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); cursor: pointer; transition: transform .2s; }
.stat-card:hover { transform: translateY(-3px); }
.stat-blue { background: linear-gradient(135deg, #ecf5ff, #d9ecff); }
.stat-orange { background: linear-gradient(135deg, #fdf6ec, #fae8cd); }
.stat-green { background: linear-gradient(135deg, #f0f9eb, #e1f3d8); }
.stat-red { background: linear-gradient(135deg, #fef0f0, #fde2e2); }
.stat-purple { background: linear-gradient(135deg, #f5ecfb, #ecd9f7); }
.stat-icon { font-size: 30px; margin-right: 14px; }
.stat-blue .stat-icon { color: #409EFF; }
.stat-orange .stat-icon { color: #E6A23C; }
.stat-green .stat-icon { color: #67C23A; }
.stat-red .stat-icon { color: #F56C6C; }
.stat-purple .stat-icon { color: #9B59B6; }
.stat-num { font-size: 20px; font-weight: bold; color: #303133; line-height: 1.2; }
.stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.chart-card { margin-top: 16px; border-radius: 8px; }
.chart-header { display: flex; justify-content: space-between; align-items: center; }
.chart-title { font-weight: 600; }
.chart-box { width: 100%; height: 320px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; margin-top: 16px; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.link-blue { color: #409EFF; cursor: pointer; }
.progress-cell { display: flex; align-items: center; gap: 6px; }
.progress-text { font-size: 12px; color: #606266; }
.overdue { color: #F56C6C; font-weight: 600; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.mini-pager { margin-top: 8px; text-align: right; }
.drawer-body { padding: 0 20px; }
.sub-title { font-size: 14px; font-weight: 600; margin: 16px 0 10px; color: #303133; }
</style>
