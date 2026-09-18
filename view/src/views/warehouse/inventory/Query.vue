<!--
  文件：admin/src/views/warehouse/inventory/Query.vue
  功能：库存查询（搜索筛选 / 统计卡片 / 预警快捷入口 / 库存分析图表 / 表格+行内钻取 / 导出）
  权限：warehouse:inventory:query:view / export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>库存管理</el-breadcrumb-item>
      <el-breadcrumb-item>库存查询</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索与筛选 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="物料名称"><el-input v-model="query.material_name" placeholder="请输入物料名称" clearable style="width:170px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="物料编码"><el-input v-model="query.material_code" placeholder="请输入物料编码" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="物料分类">
          <el-cascader v-model="query.category" :options="categoryTree" :props="{ value: 'value', label: 'label', children: 'children' }" clearable placeholder="全部" style="width:180px" @change="handleCategoryChange" />
        </el-form-item>
        <el-form-item label="仓库">
          <el-select v-model="query.warehouse_id" clearable filterable placeholder="全部" style="width:150px" @change="handleWarehouseChange">
            <el-option v-for="w in warehouseOptions" :key="w.id" :label="w.warehouse_name" :value="w.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="货位">
          <el-select v-model="query.location_id" clearable filterable placeholder="全部" style="width:150px" :disabled="!query.warehouse_id">
            <el-option v-for="l in locationOptions" :key="l.id" :label="l.location_name" :value="l.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="库存状态">
          <el-select v-model="query.stock_status" clearable placeholder="全部" style="width:120px">
            <el-option v-for="(t, v) in STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 统计卡片 + 预警快捷入口 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="8">
        <div class="stat-card stat-blue" @click="handleCardClick('all')">
          <div class="stat-icon"><i class="el-icon-box" /></div>
          <div class="stat-info">
            <div class="stat-num">{{ stats.total_materials }}</div>
            <div class="stat-label">物料种类总数</div>
          </div>
        </div>
      </el-col>
      <el-col :span="8">
        <div class="stat-card stat-green" @click="handleCardClick('all')">
          <div class="stat-icon"><i class="el-icon-goods" /></div>
          <div class="stat-info">
            <div class="stat-num">{{ Number(stats.total_stock).toFixed(2) }}</div>
            <div class="stat-label">库存总数量</div>
          </div>
        </div>
      </el-col>
      <el-col :span="8">
        <div class="stat-card" :class="stats.low_stock_count > 0 ? 'stat-red' : 'stat-gray'" @click="handleCardClick('low')">
          <div class="stat-icon"><i class="el-icon-warning" /></div>
          <div class="stat-info">
            <div class="stat-num" :style="stats.low_stock_count > 0 ? 'color:#F56C6C' : ''">{{ stats.low_stock_count }}</div>
            <div class="stat-label">低于安全库存物料数</div>
          </div>
          <el-button v-if="stats.low_stock_count > 0" type="text" size="mini" class="alert-entry" icon="el-icon-warning" @click.stop="handleShowAllAlert">查看全部预警</el-button>
        </div>
      </el-col>
    </el-row>

    <!-- 库存分析图表 -->
    <el-card shadow="never" class="chart-card">
      <div slot="header" class="chart-header">
        <span>库存分析</span>
        <el-button type="text" size="mini" icon="el-icon-refresh" :loading="chartLoading" @click="loadCharts">刷新图表</el-button>
      </div>
      <el-row :gutter="16">
        <el-col :span="8"><div ref="whChart" class="chart-box" /></el-col>
        <el-col :span="8"><div ref="catChart" class="chart-box" /></el-col>
        <el-col :span="8"><div ref="statusChart" class="chart-box" /></el-col>
      </el-row>
    </el-card>

    <!-- 操作按钮栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'warehouse:inventory:query:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 种物料</span>
    </div>

    <!-- 数据表格（含行内展开钻取） -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无库存数据" @expand-change="handleExpand">
      <el-table-column type="expand" width="45">
        <template slot-scope="s">
          <div class="expand-wrap">
            <div v-if="s.row.distribution === undefined" class="expand-empty">该物料暂无库存分布数据</div>
            <el-table v-else :data="s.row.distribution" size="mini" class="sub-table" border empty-text="该物料暂无库存分布数据">
              <el-table-column prop="warehouse_name" label="仓库名称" width="160" />
              <el-table-column prop="location_name" label="货位名称" width="160" />
              <el-table-column label="库存数量" width="140" align="right"><template slot-scope="x">{{ Number(x.row.current_stock).toFixed(4) }}</template></el-table-column>
              <el-table-column label="库存状态" width="110" align="center">
                <template slot-scope="x"><el-tag :type="x.row.stock_status_tag" size="mini">{{ x.row.stock_status_label }}</el-tag></template>
              </el-table-column>
            </el-table>
          </div>
        </template>
      </el-table-column>
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column prop="material_code" label="物料编码" width="130" />
      <el-table-column prop="material_name" label="物料名称" min-width="150" show-overflow-tooltip />
      <el-table-column label="规格型号" width="140" show-overflow-tooltip><template slot-scope="s">{{ s.row.specification || '-' }}</template></el-table-column>
      <el-table-column prop="unit" label="单位" width="80" align="center" />
      <el-table-column prop="category_name" label="物料分类" width="120" show-overflow-tooltip />
      <el-table-column label="当前库存" width="130" align="right"><template slot-scope="s">{{ Number(s.row.current_stock).toFixed(4) }} {{ s.row.unit }}</template></el-table-column>
      <el-table-column label="安全库存量" width="120" align="right"><template slot-scope="s">{{ Number(s.row.safety_stock) > 0 ? Number(s.row.safety_stock).toFixed(4) : '-' }}</template></el-table-column>
      <el-table-column label="库存状态" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.stock_status_tag" size="mini">{{ s.row.stock_status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="存放位置" width="150" show-overflow-tooltip>
        <template slot-scope="s">{{ s.row.warehouse_name ? (s.row.warehouse_name + ' / ' + (s.row.location_name || '-')) : '-' }}</template>
      </el-table-column>
      <el-table-column label="操作" width="180" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="goFlow(s.row)">库存流水</el-button>
          <el-button v-if="s.row.stock_status === 3 || s.row.stock_status === 4 || s.row.stock_status === 5" type="text" size="mini" @click="goPurchase(s.row)">生成采购申请</el-button>
          <el-button type="text" size="mini" @click="goDetail(s.row)">详情</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getInventoryList, getStockDistribution, exportInventory, getMaterialCategoryTree, getWarehouseList, getLocationList } from '../../../api/warehouse'

const STATUS_TEXT = { 1: '充足', 2: '正常', 3: '偏低', 4: '短缺', 5: '零库存' }
const STATUS_COLOR = { 1: '#67C23A', 2: '#409EFF', 3: '#E6A23C', 4: '#F56C6C', 5: '#909399' }
const PALETTE = ['#409EFF', '#67C23A', '#E6A23C', '#F56C6C', '#909399', '#9B59B6', '#1ABC9C', '#F39C12']

export default {
  name: 'WarehouseInventoryQuery',
  data () {
    return {
      STATUS_TEXT,
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false, chartLoading: false,
      query: { material_name: '', material_code: '', category: [], category_id: 0, warehouse_id: '', location_id: '', stock_status: '', material_id: 0 },
      stats: { total_materials: 0, total_stock: 0, low_stock_count: 0 },
      charts: { warehouse: [], category: [], status: [] },
      categoryTree: [], warehouseOptions: [], locationOptions: [],
      chartInstances: {}
    }
  },
  created () {
    // 库存预警/流水联动：URL 带 material_id 自动筛选该物料
    const mid = Number(this.$route.query.material_id || 0)
    if (mid > 0) this.query.material_id = mid
    this.getList(); this.loadCategoryTree(); this.loadWarehouses()
    window.addEventListener('resize', this.resizeCharts)
  },
  beforeDestroy () {
    window.removeEventListener('resize', this.resizeCharts)
    Object.values(this.chartInstances).forEach(c => { if (c) c.dispose() })
    this.chartInstances = {}
  },
  methods: {
    async loadCategoryTree () {
      try {
        const r = await getMaterialCategoryTree()
        this.categoryTree = (r.code === 0 && r.data) ? r.data : []
      } catch (e) { this.categoryTree = [] }
    },
    async loadWarehouses () {
      try {
        const r = await getWarehouseList({ page: 1, pageSize: 100, status: 1 })
        this.warehouseOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
      } catch (e) { this.warehouseOptions = [] }
    },
    async loadLocations () {
      if (!this.query.warehouse_id) { this.locationOptions = []; return }
      try {
        const r = await getLocationList({ warehouse_id: this.query.warehouse_id, page: 1, pageSize: 100 })
        this.locationOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
      } catch (e) { this.locationOptions = [] }
    },
    handleCategoryChange (val) {
      this.query.category_id = Array.isArray(val) && val.length ? Number(val[val.length - 1]) : 0
    },
    handleWarehouseChange () {
      this.query.location_id = ''
      this.loadLocations()
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.material_name) p.material_name = this.query.material_name
      if (this.query.material_code) p.material_code = this.query.material_code
      if (this.query.category_id) p.category_id = this.query.category_id
      if (this.query.warehouse_id) p.warehouse_id = this.query.warehouse_id
      if (this.query.location_id) p.location_id = this.query.location_id
      if (this.query.stock_status !== '' && this.query.stock_status !== null) p.stock_status = this.query.stock_status
      if (this.query.material_id) p.material_id = this.query.material_id
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getInventoryList(this.buildParams())
        if (r.code === 0 && r.data) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.stats = {
            total_materials: r.data.total_materials || 0,
            total_stock: r.data.total_stock || 0,
            low_stock_count: r.data.low_stock_count || 0
          }
          this.charts = {
            warehouse: r.data.chart_warehouse || [],
            category: r.data.chart_category || [],
            status: r.data.chart_status || []
          }
          this.$nextTick(() => this.renderCharts())
        }
      } catch (e) {} finally { this.loading = false }
    },
    async loadCharts () {
      this.chartLoading = true
      try {
        const r = await getInventoryList({ page: 1, pageSize: 1 })
        if (r.code === 0 && r.data) {
          this.charts = {
            warehouse: r.data.chart_warehouse || [],
            category: r.data.chart_category || [],
            status: r.data.chart_status || []
          }
          this.$nextTick(() => this.renderCharts())
        }
      } catch (e) {} finally { this.chartLoading = false }
    },
    renderCharts () {
      this.renderWarehouseChart()
      this.renderCategoryChart()
      this.renderStatusChart()
    },
    getChart (ref) {
      if (!this.chartInstances[ref]) this.chartInstances[ref] = echarts.init(this.$refs[ref])
      return this.chartInstances[ref]
    },
    renderWarehouseChart () {
      const chart = this.getChart('whChart')
      const data = this.charts.warehouse || []
      chart.setOption({
        tooltip: { trigger: 'axis' },
        grid: { left: 40, right: 20, top: 30, bottom: 40 },
        xAxis: { type: 'category', data: data.map(x => x.name), axisLabel: { interval: 0, rotate: 20 } },
        yAxis: { type: 'value', name: '库存数量' },
        series: [{
          type: 'bar', data: data.map(x => x.value), barMaxWidth: 40,
          label: { show: true, position: 'top' },
          itemStyle: { color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color: '#409EFF' }, { offset: 1, color: '#a0cfff' }]) }
        }]
      }, true)
      chart.off('click')
      chart.on('click', params => {
        const item = data[params.dataIndex]
        if (item && item.id) { this.query.warehouse_id = item.id; this.loadLocations(); this.handleSearch() }
      })
    },
    renderCategoryChart () {
      const chart = this.getChart('catChart')
      const data = this.charts.category || []
      const totalVal = data.reduce((s, x) => s + (Number(x.value) || 0), 0)
      chart.setOption({
        tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
        legend: { type: 'scroll', orient: 'vertical', right: 0, top: 'middle', textStyle: { fontSize: 11 } },
        graphic: {
          type: 'text', left: 'center', top: '42%', style: {
            text: '总库存\n' + totalVal.toFixed(2), textAlign: 'center',
            fill: '#606266', fontSize: 14, lineHeight: 20, fontWeight: 'bold'
          }
        },
        series: [{
          type: 'pie', radius: ['38%', '62%'], center: ['38%', '50%'], avoidLabelOverlap: true,
          itemStyle: { borderRadius: 4, borderColor: '#fff', borderWidth: 1 },
          label: { formatter: '{b}\n{d}%', fontSize: 11 },
          data: data.map((x, i) => ({ ...x, itemStyle: { color: PALETTE[i % PALETTE.length] } }))
        }]
      }, true)
      chart.off('click')
      chart.on('click', params => {
        const item = data[params.dataIndex]
        if (item && item.id) { this.query.category_id = item.id; this.handleSearch() }
      })
    },
    renderStatusChart () {
      const chart = this.getChart('statusChart')
      const data = this.charts.status || []
      chart.setOption({
        tooltip: { trigger: 'axis' },
        grid: { left: 40, right: 20, top: 30, bottom: 40 },
        xAxis: { type: 'category', data: data.map(x => x.name) },
        yAxis: { type: 'value', name: '物料种类' },
        series: [{
          type: 'bar', data: data.map(x => x.value), barMaxWidth: 40,
          label: { show: true, position: 'top' },
          itemStyle: { color: params => STATUS_COLOR[(params.dataIndex + 1)] || '#909399' }
        }]
      }, true)
      chart.off('click')
      chart.on('click', params => {
        this.query.stock_status = params.dataIndex + 1
        this.handleSearch()
      })
    },
    resizeCharts () {
      Object.values(this.chartInstances).forEach(c => { if (c) c.resize() })
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () {
      this.query = { material_name: '', material_code: '', category: [], category_id: 0, warehouse_id: '', location_id: '', stock_status: '' }
      this.locationOptions = []
      this.handleSearch()
    },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.getList() },
    handleCardClick (type) {
      if (type === 'all') { this.handleReset(); return }
      this.handleShowAllAlert()
    },
    handleShowAllAlert () {
      // 预警组合：偏低(3) / 短缺(4) / 零库存(5)
      this.query.stock_status = '3,4,5'
      this.handleSearch()
    },
    async handleExport () {
      this.exporting = true
      try {
        const p = { ...this.buildParams() }
        delete p.page; delete p.pageSize
        const r = await exportInventory(p)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `库存查询_${new Date().toLocaleDateString()}.xlsx`
          a.click()
          window.URL.revokeObjectURL(url)
        }
      } catch (e) {} finally { this.exporting = false }
    },
    async handleExpand (row, expandedRows) {
      if (!expandedRows.length) return
      if (row.distribution === undefined) {
        try {
          const r = await getStockDistribution(row.id)
          row.distribution = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
        } catch (e) { row.distribution = [] }
      }
    },
    goFlow (row) { this.$router.push({ path: '/warehouse/inventory/flow', query: { material_id: row.id } }) },
    goDetail (row) { this.$router.push({ path: `/warehouse/setting/material/detail/${row.id}` }) },
    goPurchase (row) {
      // 建议采购量 = 安全库存 - 当前库存（至少 1）
      const suggest = Math.max(1, Number(row.safety_stock) - Number(row.current_stock))
      const copyFrom = JSON.stringify({
        request: { title: `库存预警采购申请-${row.material_name}` },
        items: [{
          product_id: row.id, product_code: row.material_code, product_name: row.material_name,
          product_spec: row.specification || '', product_unit: row.unit || '',
          quantity: suggest, unit_price: 0, need_date: ''
        }]
      })
      this.$router.push({ path: '/business/purchase/request/add', query: { copyFrom: encodeURIComponent(copyFrom) } })
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.stat-row { margin-top: 16px; }
.stat-card { position: relative; display: flex; align-items: center; padding: 16px 20px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); cursor: pointer; transition: transform .2s; overflow: hidden; }
.stat-card:hover { transform: translateY(-3px); }
.stat-blue { background: linear-gradient(135deg, #ecf5ff, #d9ecff); }
.stat-green { background: linear-gradient(135deg, #f0f9eb, #e1f3d8); }
.stat-red { background: linear-gradient(135deg, #fef0f0, #fde2e2); }
.stat-gray { background: linear-gradient(135deg, #f4f4f5, #e9e9eb); }
.stat-icon { font-size: 34px; margin-right: 14px; }
.stat-blue .stat-icon { color: #409EFF; }
.stat-green .stat-icon { color: #67C23A; }
.stat-red .stat-icon { color: #F56C6C; }
.stat-gray .stat-icon { color: #909399; }
.stat-num { font-size: 26px; font-weight: bold; color: #303133; line-height: 1.2; }
.stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.alert-entry { position: absolute; right: 12px; bottom: 10px; }
.chart-card { margin-top: 16px; }
.chart-header { display: flex; justify-content: space-between; align-items: center; }
.chart-box { height: 260px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; margin-top: 16px; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.expand-wrap { background: #F5F7FA; padding: 10px 16px; }
.expand-empty { color: #909399; font-size: 13px; padding: 8px 0; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
</style>
