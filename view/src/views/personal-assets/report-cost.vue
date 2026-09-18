<template>
  <div class="rc-page">
    <el-breadcrumb separator="/" class="rc-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>报表统计</el-breadcrumb-item>
      <el-breadcrumb-item>资产成本核算</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 提示横幅 -->
    <div v-if="showBanner" class="rc-banner">
      <i class="el-icon-info rc-banner-icon"></i>
      <span class="rc-banner-text">资产成本核算：整合资产持有成本与生产成本，实现完整成本闭环。</span>
      <i class="el-icon-close rc-banner-close" @click="showBanner = false; localStorage.setItem('rc_banner_closed', '1')"></i>
    </div>

    <!-- 筛选 -->
    <div class="rc-filter">
      <el-select v-model="year" size="small" style="width:110px">
        <el-option v-for="y in yearOptions" :key="y" :label="y + '年'" :value="y" />
      </el-select>
      <el-select v-model="month" size="small" clearable placeholder="全部月份" style="width:110px;margin-left:10px">
        <el-option v-for="m in 12" :key="m" :label="m + '月'" :value="m" />
      </el-select>
      <el-button size="small" type="primary" icon="el-icon-search" style="margin-left:10px" @click="loadAll">查询</el-button>
      <el-button size="small" icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
      <el-button size="small" type="primary" icon="el-icon-download" :loading="exporting" style="margin-left:10px" @click="handleExport">导出报表</el-button>
    </div>

    <!-- 统计卡片 -->
    <div class="rc-stats">
      <div class="rc-stat-card"><div class="rc-stat-info"><div class="rc-stat-num" style="color:#409EFF">¥{{ Number(overview.asset_cost).toLocaleString() }}</div><div class="rc-stat-label">资产成本</div></div><div class="rc-stat-icon" style="background:#ecf5ff"><i class="el-icon-money" style="color:#409EFF"></i></div></div>
      <div class="rc-stat-card"><div class="rc-stat-info"><div class="rc-stat-num" style="color:#E6A23C">¥{{ Number(overview.production_cost).toLocaleString() }}</div><div class="rc-stat-label">生产成本</div></div><div class="rc-stat-icon" style="background:#fdf6ec"><i class="el-icon-factory" style="color:#E6A23C"></i></div></div>
      <div class="rc-stat-card"><div class="rc-stat-info"><div class="rc-stat-num" style="color:#67C23A">¥{{ Number(overview.total_cost).toLocaleString() }}</div><div class="rc-stat-label">总成本</div></div><div class="rc-stat-icon" style="background:#f0f9eb"><i class="el-icon-data-line" style="color:#67C23A"></i></div></div>
      <div class="rc-stat-card"><div class="rc-stat-info"><div class="rc-stat-num" :style="{ color: overview.cost_trend >= 0 ? '#F56C6C' : '#67C23A' }">{{ overview.cost_trend }}%</div><div class="rc-stat-label">成本趋势（环比）</div></div><div class="rc-stat-icon" style="background:#f5f0fa"><i class="el-icon-trend-charts" style="color:#9B59B6"></i></div></div>
    </div>

    <!-- 成本构成图 -->
    <div class="rc-chart-box">
      <div class="rc-chart-title">成本构成分析</div>
      <div ref="costChart" class="rc-chart rc-cost-chart" />
    </div>

    <!-- Tab视图 -->
    <div class="rc-tabs-box">
      <el-tabs v-model="activeTab">
        <el-tab-pane label="按工单" name="orders">
          <div class="rc-tab-toolbar">
            <el-input v-model="keyword" placeholder="工单编号/产品名称" size="small" clearable style="width:200px" @keyup.enter.native="loadOrders(1)" />
            <el-button size="small" type="primary" @click="loadOrders(1)">搜索</el-button>
          </div>
          <el-table :data="orderList" v-loading="orderLoading" size="small" border>
            <el-table-column label="工单编号" width="140"><template slot-scope="s"><el-link type="primary" @click="openOrderDetail(s.row)">{{ s.row.order_no }}</el-link></template></el-table-column>
            <el-table-column prop="product_name" label="产品名称" min-width="110" show-overflow-tooltip />
            <el-table-column prop="plan_quantity" label="计划数量" width="80" align="right" />
            <el-table-column prop="actual_quantity" label="实际产量" width="80" align="right" />
            <el-table-column label="人工成本" width="100" align="right"><template slot-scope="s">¥{{ Number(s.row.labor_cost).toLocaleString() }}</template></el-table-column>
            <el-table-column label="物料成本" width="100" align="right"><template slot-scope="s">¥{{ Number(s.row.material_cost).toLocaleString() }}</template></el-table-column>
            <el-table-column label="设备成本" width="100" align="right"><template slot-scope="s">¥{{ Number(s.row.equipment_cost).toLocaleString() }}</template></el-table-column>
            <el-table-column label="总成本" width="110" align="right"><template slot-scope="s"><b>¥{{ Number(s.row.total_cost).toLocaleString() }}</b></template></el-table-column>
            <el-table-column label="单位成本" width="100" align="right"><template slot-scope="s">¥{{ Number(s.row.unit_cost).toLocaleString() }}</template></el-table-column>
          </el-table>
          <div class="rc-pagination">
            <el-pagination background layout="total, prev, pager, next" :total="orderTotal" :current-page="orderPage" :page-size="20" @current-change="loadOrders" />
          </div>
        </el-tab-pane>

        <el-tab-pane label="按产品" name="products">
          <el-table :data="productList" v-loading="productLoading" size="small" border>
            <el-table-column prop="product_name" label="产品名称" min-width="140" />
            <el-table-column prop="total_quantity" label="总产量" width="90" align="right" />
            <el-table-column label="总成本" width="120" align="right"><template slot-scope="s">¥{{ Number(s.row.total_cost).toLocaleString() }}</template></el-table-column>
            <el-table-column label="单位成本" width="110" align="right"><template slot-scope="s">¥{{ Number(s.row.unit_cost).toLocaleString() }}</template></el-table-column>
            <el-table-column prop="trend" label="成本趋势" width="90" align="center" />
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="按部门" name="departments">
          <el-table :data="deptList" v-loading="deptLoading" size="small" border>
            <el-table-column prop="department_name" label="部门名称" min-width="140" />
            <el-table-column prop="order_count" label="工单数量" width="90" align="right" />
            <el-table-column label="生产成本" width="120" align="right"><template slot-scope="s">¥{{ Number(s.row.production_cost).toLocaleString() }}</template></el-table-column>
            <el-table-column label="资产成本" width="120" align="right"><template slot-scope="s">¥{{ Number(s.row.asset_cost).toLocaleString() }}</template></el-table-column>
            <el-table-column label="部门总成本" width="130" align="right"><template slot-scope="s"><b>¥{{ Number(s.row.total_cost).toLocaleString() }}</b></template></el-table-column>
          </el-table>
        </el-tab-pane>

        <el-tab-pane label="按设备" name="equipment">
          <el-table :data="equipmentList" v-loading="equipmentLoading" size="small" border>
            <el-table-column prop="device_name" label="设备名称" min-width="130" />
            <el-table-column prop="device_no" label="设备编号" width="120" />
            <el-table-column prop="usage_hours" label="使用工时" width="90" align="right" />
            <el-table-column label="设备成本" width="110" align="right"><template slot-scope="s">¥{{ Number(s.row.equipment_cost).toLocaleString() }}</template></el-table-column>
            <el-table-column label="折旧成本" width="110" align="right"><template slot-scope="s">¥{{ Number(s.row.depreciation_cost).toLocaleString() }}</template></el-table-column>
            <el-table-column label="设备总成本" width="120" align="right"><template slot-scope="s"><b>¥{{ Number(s.row.total_cost).toLocaleString() }}</b></template></el-table-column>
            <el-table-column prop="utilization_rate" label="利用率" width="90" align="right"><template slot-scope="s">{{ s.row.utilization_rate }}%</template></el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </div>

    <!-- 工单成本详情弹窗 -->
    <el-dialog :title="'工单成本详情 - ' + (orderDetail.order_no || '')" :visible.sync="detailVisible" width="700px">
      <div v-loading="detailLoading" class="rc-detail-body">
        <template v-if="orderDetail.order_no">
          <div class="rc-detail-sec">
            <div class="rc-detail-title">基本信息</div>
            <div class="rc-detail-grid">
              <div class="rc-detail-item"><span class="rc-lb">工单编号</span>{{ orderDetail.order_no }}</div>
              <div class="rc-detail-item"><span class="rc-lb">产品名称</span>{{ orderDetail.product_name || '-' }}</div>
              <div class="rc-detail-item"><span class="rc-lb">计划数量</span>{{ orderDetail.plan_quantity }}</div>
              <div class="rc-detail-item"><span class="rc-lb">工时单价</span>¥{{ orderDetail.labor_hour_rate }}/小时</div>
              <div class="rc-detail-item"><span class="rc-lb">设备费率</span>¥{{ orderDetail.equipment_hour_rate }}/小时</div>
            </div>
          </div>
          <div class="rc-detail-sec">
            <div class="rc-detail-title">报工工时（人工+设备成本）</div>
            <el-table :data="orderDetail.reports" size="small" border>
              <el-table-column prop="report_no" label="报工单号" width="130" />
              <el-table-column prop="reporter_name" label="报工人" width="80" />
              <el-table-column prop="device_name" label="设备" min-width="100" />
              <el-table-column prop="duration" label="工时" width="70" align="right" />
              <el-table-column prop="quantity" label="数量" width="70" align="right" />
            </el-table>
          </div>
          <div class="rc-detail-sec">
            <div class="rc-detail-title">物料消耗（物料成本）</div>
            <el-table :data="orderDetail.materials" size="small" border empty-text="无物料消耗">
              <el-table-column prop="material_name" label="配件名称" min-width="110" />
              <el-table-column prop="specification" label="规格" width="90" />
              <el-table-column prop="quantity" label="数量" width="70" align="right" />
              <el-table-column label="单价" width="90" align="right"><template slot-scope="s">¥{{ Number(s.row.unit_price).toLocaleString() }}</template></el-table-column>
              <el-table-column label="金额" width="100" align="right"><template slot-scope="s">¥{{ Number(s.row.quantity * s.row.unit_price).toLocaleString() }}</template></el-table-column>
            </el-table>
          </div>
        </template>
      </div>
      <div slot="footer"><el-button size="small" @click="detailVisible = false">关闭</el-button></div>
    </el-dialog>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getCostOverview, getCostOrders, getCostProducts, getCostDepartments, getCostEquipment, getCostOrderDetail, exportCostReport } from '../../api/personalAssets'

export default {
  name: 'ReportCost',
  data () {
    const currentYear = new Date().getFullYear()
    return {
      showBanner: localStorage.getItem('rc_banner_closed') !== '1',
      year: currentYear,
      yearOptions: [currentYear, currentYear - 1, currentYear - 2, currentYear - 3],
      month: '',
      activeTab: 'orders',
      overview: { asset_cost: 0, production_cost: 0, total_cost: 0, cost_trend: 0, breakdown: {} },
      // 工单
      orderList: [], orderTotal: 0, orderPage: 1, orderLoading: false, keyword: '',
      // 产品/部门/设备
      productList: [], productLoading: false,
      deptList: [], deptLoading: false,
      equipmentList: [], equipmentLoading: false,
      exporting: false,
      detailVisible: false, detailLoading: false, orderDetail: {},
      charts: {}
    }
  },
  created () { this.loadAll() },
  methods: {
    buildParams () {
      const p = { year: this.year }
      if (this.month) p.month = this.month
      return p
    },
    async loadAll () {
      this.loadOverview()
      this.loadOrders(1)
      this.loadProducts()
      this.loadDepartments()
      this.loadEquipment()
    },
    handleReset () {
      this.year = new Date().getFullYear()
      this.month = ''
      this.keyword = ''
      this.loadAll()
    },
    async loadOverview () {
      try {
        const r = await getCostOverview(this.buildParams())
        if (r.code === 0) { this.overview = r.data; this.renderCost() }
      } catch (e) {}
    },
    async loadOrders (page) {
      this.orderPage = page || 1
      this.orderLoading = true
      try {
        const r = await getCostOrders({ ...this.buildParams(), keyword: this.keyword, page: this.orderPage, limit: 20 })
        if (r.code === 0) { this.orderList = r.data.list || []; this.orderTotal = r.data.total || 0 }
      } catch (e) {}
      this.orderLoading = false
    },
    async loadProducts () {
      this.productLoading = true
      try { const r = await getCostProducts(this.buildParams()); if (r.code === 0) this.productList = r.data || [] } catch (e) {}
      this.productLoading = false
    },
    async loadDepartments () {
      this.deptLoading = true
      try { const r = await getCostDepartments(this.buildParams()); if (r.code === 0) this.deptList = r.data || [] } catch (e) {}
      this.deptLoading = false
    },
    async loadEquipment () {
      this.equipmentLoading = true
      try { const r = await getCostEquipment(this.buildParams()); if (r.code === 0) this.equipmentList = r.data || [] } catch (e) {}
      this.equipmentLoading = false
    },
    renderCost () {
      const el = this.$refs.costChart
      if (!el) return
      if (!this.charts.cost) this.charts.cost = echarts.init(el)
      const b = this.overview.breakdown || {}
      const data = [
        { name: '资产成本', value: this.overview.asset_cost, itemStyle: { color: '#409EFF' } },
        { name: '生产成本', value: this.overview.production_cost, itemStyle: { color: '#E6A23C' } }
      ]
      this.charts.cost.setOption({
        tooltip: { trigger: 'item', formatter: '{b}: ¥{c} ({d}%)' },
        legend: { orient: 'vertical', right: 20, top: 'center' },
        series: [{
          type: 'pie',
          radius: ['40%', '68%'],
          center: ['42%', '50%'],
          itemStyle: { borderRadius: 6, borderColor: '#fff', borderWidth: 2 },
          label: { formatter: '{b}\n¥{c}' },
          emphasis: { scale: true },
          data
        }]
      }, true)
    },
    async openOrderDetail (row) {
      this.detailVisible = true
      this.orderDetail = {}
      this.detailLoading = true
      try {
        const r = await getCostOrderDetail({ order_id: row.order_id, ...this.buildParams() })
        if (r.code === 0) this.orderDetail = r.data
      } catch (e) {}
      this.detailLoading = false
    },
    async handleExport () {
      this.exporting = true
      try {
        const res = await exportCostReport(this.buildParams())
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('导出失败'); return }
        const url = window.URL.createObjectURL(new Blob([blob]))
        const a = document.createElement('a')
        a.href = url
        a.download = '资产成本核算_' + this.year + '.xlsx'
        a.click()
        window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') }
      this.exporting = false
    }
  },
  beforeDestroy () {
    Object.values(this.charts).forEach(c => { if (c) c.dispose() })
  }
}
</script>

<style scoped>
.rc-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.rc-breadcrumb { margin-bottom: 12px; }
.rc-banner { display: flex; align-items: center; background: #ecf5ff; border: 1px solid #d9ecff; border-radius: 4px; padding: 12px 16px; margin-bottom: 16px; }
.rc-banner-icon { color: #409EFF; font-size: 16px; margin-right: 8px; }
.rc-banner-text { flex: 1; font-size: 14px; color: #5a6b7f; }
.rc-banner-close { color: #909399; cursor: pointer; font-size: 14px; }
.rc-filter { background: #fff; border-radius: 8px; padding: 14px 16px; margin-bottom: 12px; display: flex; align-items: center; }
.rc-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 16px; }
.rc-stat-card { background: #fff; border-radius: 8px; padding: 18px 20px; border: 1px solid #ebeef5; box-shadow: 0 2px 8px rgba(31,45,61,.04); display: flex; align-items: center; justify-content: space-between; }
.rc-stat-num { font-size: 20px; font-weight: 700; }
.rc-stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.rc-stat-icon { width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px; }
.rc-chart-box { background: #fff; border-radius: 8px; padding: 16px; border: 1px solid #ebeef5; margin-bottom: 16px; }
.rc-chart-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 12px; }
.rc-cost-chart { height: 300px; }
.rc-tabs-box { background: #fff; border-radius: 8px; padding: 16px; border: 1px solid #ebeef5; }
.rc-tab-toolbar { display: flex; gap: 8px; margin-bottom: 12px; }
.rc-pagination { display: flex; justify-content: flex-end; margin-top: 16px; }
.rc-detail-body { min-height: 150px; }
.rc-detail-sec { margin-bottom: 16px; }
.rc-detail-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid #f0f2f5; }
.rc-detail-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px 16px; }
.rc-detail-item { font-size: 13px; color: #303133; display: flex; align-items: center; }
.rc-lb { color: #909399; width: 70px; flex-shrink: 0; }
</style>