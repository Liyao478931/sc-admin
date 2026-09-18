<template>
  <div class="analysis-page">
    <el-breadcrumb separator="/">
      <el-breadcrumb-item :to="{ path: '/' }">首页</el-breadcrumb-item>
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>库存分析</el-breadcrumb-item>
    </el-breadcrumb>

    <el-tabs v-model="activeTab" @tab-click="onTab">
      <!-- ============ 1. 库存总览 ============ -->
      <el-tab-pane label="库存总览" name="overview">
        <div class="stat-grid" v-loading="loadingOv">
          <div class="stat-card">
            <div class="stat-num">{{ ov.total_materials }}</div>
            <div class="stat-label">物料总数</div>
          </div>
          <div class="stat-card ok">
            <div class="stat-num">{{ ov.in_stock_materials }}</div>
            <div class="stat-label">有库存物料</div>
          </div>
          <div class="stat-card warn">
            <div class="stat-num">{{ ov.zero_stock_materials }}</div>
            <div class="stat-label">零库存物料</div>
          </div>
          <div class="stat-card">
            <div class="stat-num">{{ fmtQty(ov.total_stock) }}</div>
            <div class="stat-label">库存总量</div>
          </div>
          <div class="stat-card">
            <div class="stat-num">¥{{ fmtAmt(ov.total_cost) }}</div>
            <div class="stat-label">库存金额</div>
          </div>
          <div class="stat-card bad">
            <div class="stat-num">{{ ov.slow_materials }}</div>
            <div class="stat-label">呆滞料（>30天）</div>
          </div>
        </div>

        <div class="chart-row">
          <el-card class="box-card" shadow="never">
            <div slot="header" class="card-header"><span><i class="el-icon-pie-chart"></i> 分类库存分布</span></div>
            <div ref="catChart" style="height: 300px"></div>
          </el-card>
          <el-card class="box-card" shadow="never">
            <div slot="header" class="card-header"><span><i class="el-icon-office-building"></i> 仓库库存分布</span></div>
            <div ref="whChart" style="height: 300px"></div>
          </el-card>
        </div>
      </el-tab-pane>

      <!-- ============ 2. 周转分析 ============ -->
      <el-tab-pane label="周转分析" name="turnover">
        <el-card class="box-card" shadow="never">
          <div class="search-row">
            <el-select v-model="turnoverQuery.range" style="width: 140px" @change="loadTurnover(1)">
              <el-option v-for="(txt, key) in rangeOpts" :key="key" :label="txt" :value="key"></el-option>
            </el-select>
            <el-select v-model="turnoverQuery.category_id" style="width: 170px" clearable filterable placeholder="物料分类" @change="loadTurnover(1)">
              <el-option v-for="c in categoryOptions" :key="c.id" :label="c.label" :value="c.id"></el-option>
            </el-select>
            <el-input v-model="turnoverQuery.material_name" placeholder="物料名称" clearable style="width: 180px" @keyup.enter.native="loadTurnover(1)"></el-input>
            <el-input v-model="turnoverQuery.material_code" placeholder="物料编码" clearable style="width: 150px" @keyup.enter.native="loadTurnover(1)"></el-input>
            <el-input v-model="turnoverQuery.min_turnover" placeholder="最小周转次数" clearable style="width: 140px" @keyup.enter.native="loadTurnover(1)"></el-input>
            <el-button type="primary" icon="el-icon-search" @click="loadTurnover(1)">查询</el-button>
            <el-button type="success" icon="el-icon-download" @click="doExport('turnover')">导出</el-button>
          </div>
          <div class="range-hint">
            <el-tag size="small" type="info">{{ turnoverData.range_text || '' }}</el-tag>
            <span v-if="turnoverData.start_date">统计区间：{{ turnoverData.start_date }} ~ {{ turnoverData.end_date }}，共 {{ turnoverData.total }} 种物料</span>
          </div>
          <el-table :data="turnoverData.list" size="small" border v-loading="loadingTu" style="margin-top: 10px">
            <el-table-column type="index" label="#" width="50"></el-table-column>
            <el-table-column prop="material_code" label="物料编码" width="110"></el-table-column>
            <el-table-column prop="material_name" label="物料名称" min-width="130" show-overflow-tooltip></el-table-column>
            <el-table-column prop="specification" label="规格" width="110" show-overflow-tooltip></el-table-column>
            <el-table-column prop="unit" label="单位" width="70"></el-table-column>
            <el-table-column prop="category_name" label="分类" width="100"></el-table-column>
            <el-table-column prop="in_qty" label="期间入库" width="90" align="right">
              <template slot-scope="{ row }">{{ fmtQty(row.in_qty) }}</template>
            </el-table-column>
            <el-table-column prop="out_qty" label="期间出库" width="90" align="right">
              <template slot-scope="{ row }">{{ fmtQty(row.out_qty) }}</template>
            </el-table-column>
            <el-table-column prop="current_stock" label="期末库存" width="90" align="right">
              <template slot-scope="{ row }">{{ fmtQty(row.current_stock) }}</template>
            </el-table-column>
            <el-table-column prop="stock_amount" label="库存金额" width="100" align="right">
              <template slot-scope="{ row }">¥{{ fmtAmt(row.stock_amount) }}</template>
            </el-table-column>
            <el-table-column prop="turnover" label="周转次数" width="90" align="right">
              <template slot-scope="{ row }">{{ row.turnover > 0 ? row.turnover : '-' }}</template>
            </el-table-column>
            <el-table-column prop="turnover_days" label="周转天数" width="90" align="right">
              <template slot-scope="{ row }">{{ row.turnover_days > 0 ? row.turnover_days : '-' }}</template>
            </el-table-column>
            <el-table-column prop="level" label="周转水平" width="90">
              <template slot-scope="{ row }">
                <el-tag :type="levelTag(row.level)" size="small">{{ row.level }}</el-tag>
              </template>
            </el-table-column>
          </el-table>
          <el-pagination
            background
            layout="total, prev, pager, next"
            :total="turnoverData.total"
            :page-size="20"
            :current-page="turnoverQuery.page"
            @current-change="loadTurnover"
            style="margin-top: 12px; text-align: right"
          ></el-pagination>
        </el-card>
      </el-tab-pane>

      <!-- ============ 3. 呆滞料分析 ============ -->
      <el-tab-pane label="呆滞料分析" name="slow">
        <el-card class="box-card" shadow="never">
          <div class="search-row">
            <el-select v-model="slowQuery.threshold" style="width: 160px" @change="loadSlow(1)">
              <el-option :value="30" label="超过30天无出入库"></el-option>
              <el-option :value="60" label="超过60天无出入库"></el-option>
              <el-option :value="90" label="超过90天无出入库"></el-option>
              <el-option :value="180" label="超过180天无出入库"></el-option>
            </el-select>
            <el-select v-model="slowQuery.category_id" style="width: 170px" clearable filterable placeholder="物料分类" @change="loadSlow(1)">
              <el-option v-for="c in categoryOptions" :key="c.id" :label="c.label" :value="c.id"></el-option>
            </el-select>
            <el-input v-model="slowQuery.material_name" placeholder="物料名称" clearable style="width: 180px" @keyup.enter.native="loadSlow(1)"></el-input>
            <el-input v-model="slowQuery.material_code" placeholder="物料编码" clearable style="width: 150px" @keyup.enter.native="loadSlow(1)"></el-input>
            <el-button type="primary" icon="el-icon-search" @click="loadSlow(1)">查询</el-button>
            <el-button type="success" icon="el-icon-download" @click="doExport('slow')">导出</el-button>
          </div>
          <div class="stat-grid mini" v-loading="loadingSl">
            <div class="stat-card">
              <div class="stat-num">{{ slowData.total }}</div>
              <div class="stat-label">呆滞料种数</div>
            </div>
            <div class="stat-card">
              <div class="stat-num">¥{{ fmtAmt(slowData.total_amount) }}</div>
              <div class="stat-label">呆滞库存金额</div>
            </div>
            <div class="stat-card" v-for="b in slowData.chart_bucket" :key="b.name">
              <div class="stat-num">{{ b.count }}</div>
              <div class="stat-label">{{ b.name }}（¥{{ fmtAmt(b.amount) }}）</div>
            </div>
          </div>
          <el-table :data="slowData.list" size="small" border v-loading="loadingSl" style="margin-top: 10px">
            <el-table-column type="index" label="#" width="50"></el-table-column>
            <el-table-column prop="material_code" label="物料编码" width="110"></el-table-column>
            <el-table-column prop="material_name" label="物料名称" min-width="130" show-overflow-tooltip></el-table-column>
            <el-table-column prop="specification" label="规格" width="110" show-overflow-tooltip></el-table-column>
            <el-table-column prop="unit" label="单位" width="70"></el-table-column>
            <el-table-column prop="category_name" label="分类" width="100"></el-table-column>
            <el-table-column prop="current_stock" label="当前库存" width="90" align="right">
              <template slot-scope="{ row }">{{ fmtQty(row.current_stock) }}</template>
            </el-table-column>
            <el-table-column prop="stock_amount" label="库存金额" width="100" align="right">
              <template slot-scope="{ row }">¥{{ fmtAmt(row.stock_amount) }}</template>
            </el-table-column>
            <el-table-column prop="last_flow_time" label="最后出入库" width="160"></el-table-column>
            <el-table-column prop="idle_days" label="呆滞天数" width="90" align="right"></el-table-column>
            <el-table-column prop="bucket" label="呆滞分档" width="110">
              <template slot-scope="{ row }">
                <el-tag :type="bucketTag(row.bucket)" size="small">{{ row.bucket }}</el-tag>
              </template>
            </el-table-column>
          </el-table>
          <el-pagination
            background
            layout="total, prev, pager, next"
            :total="slowData.total"
            :page-size="20"
            :current-page="slowQuery.page"
            @current-change="loadSlow"
            style="margin-top: 12px; text-align: right"
          ></el-pagination>
        </el-card>
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script>
import request from '@/api/request'
import * as echarts from 'echarts'
import { getToken } from '@/utils/auth'

export default {
  name: 'InventoryAnalysis',
  data() {
    return {
      activeTab: 'overview',
      rangeOpts: { '30d': '近30天', '60d': '近60天', '90d': '近90天', '180d': '近半年', '365d': '近一年', all: '全部' },
      categoryOptions: [],
      loadingOv: false,
      loadingTu: false,
      loadingSl: false,
      ov: {},
      turnoverQuery: { range: '90d', category_id: 0, material_name: '', material_code: '', min_turnover: '', page: 1 },
      turnoverData: { list: [], total: 0 },
      slowQuery: { threshold: 30, category_id: 0, material_name: '', material_code: '', page: 1 },
      slowData: { list: [], total: 0, chart_bucket: [] },
      catChart: null,
      whChart: null
    }
  },
  mounted() {
    this.loadCategory()
    this.loadOverview()
  },
  methods: {
    fmtQty(v) {
      const n = Number(v || 0)
      return n % 1 === 0 ? n : n.toFixed(2)
    },
    fmtAmt(v) {
      const n = Number(v || 0)
      return n.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
    },
    levelTag(l) {
      return l === '高周转' ? 'success' : l === '正常' ? 'primary' : l === '低周转' ? 'warning' : 'info'
    },
    bucketTag(b) {
      return b === '180天以上' ? 'danger' : b === '91-180天' ? 'warning' : 'primary'
    },
    loadCategory() {
      request.get('/warehouse/setting/material/category/tree').then((res) => {
        const walk = (list, depth) => {
          ;(list || []).forEach((c) => {
            this.categoryOptions.push({ id: c.id, label: (depth ? '　'.repeat(depth) : '') + c.category_name })
            if (c.children && c.children.length) walk(c.children, depth + 1)
          })
        }
        walk(res.data, 0)
      }).catch(() => {})
    },
    onTab() {
      if (this.activeTab === 'overview' && !this.ov.total_materials) this.loadOverview()
      if (this.activeTab === 'turnover' && !this.turnoverData.total) this.loadTurnover(1)
      if (this.activeTab === 'slow' && !this.slowData.total) this.loadSlow(1)
    },
    loadOverview() {
      this.loadingOv = true
      request.get('/warehouse/inventory/analysis/overview').then((res) => {
        this.ov = res.data || {}
        this.$nextTick(() => this.renderCharts())
      }).finally(() => { this.loadingOv = false })
    },
    renderCharts() {
      if (this.catChart) this.catChart.dispose()
      if (this.whChart) this.whChart.dispose()
      this.catChart = echarts.init(this.$refs.catChart)
      this.whChart = echarts.init(this.$refs.whChart)
      const cat = this.ov.chart_category || []
      this.catChart.setOption({
        backgroundColor: 'transparent',
        tooltip: { trigger: 'axis', confine: true },
        grid: { left: 45, right: 20, top: 30, bottom: 60, containLabel: true },
        xAxis: {
          type: 'category',
          data: cat.map((c) => c.name),
          axisLabel: { rotate: 35, fontSize: 11, interval: 0 },
          axisLine: { lineStyle: { color: '#ddd' } }
        },
        yAxis: { type: 'value', name: '库存量', axisLabel: { fontSize: 11 } },
        series: [{
          type: 'bar',
          data: cat.map((c) => c.value),
          itemStyle: { color: '#8BC8EA', borderRadius: [4, 4, 0, 0] },
          barMaxWidth: 32,
          label: { show: true, position: 'top', fontSize: 10, formatter: (p) => (Number(p.value) % 1 === 0 ? p.value : Number(p.value).toFixed(2)) }
        }]
      })
      const wh = this.ov.chart_warehouse || []
      this.whChart.setOption({
        backgroundColor: 'transparent',
        tooltip: { trigger: 'item', confine: true },
        legend: { bottom: 0, type: 'scroll', textStyle: { fontSize: 11 } },
        series: [{
          type: 'pie',
          radius: ['38%', '68%'],
          center: ['50%', '45%'],
          data: wh.map((w) => ({ name: w.name, value: w.value })),
          label: { fontSize: 11, formatter: '{b}\n{c}' },
          itemStyle: { borderRadius: 4, borderColor: '#fff', borderWidth: 1 }
        }]
      })
      window.addEventListener('resize', () => {
        if (this.catChart) this.catChart.resize()
        if (this.whChart) this.whChart.resize()
      })
    },
    loadTurnover(page) {
      this.turnoverQuery.page = page
      this.loadingTu = true
      const params = { ...this.turnoverQuery }
      if (!params.min_turnover) delete params.min_turnover
      request.get('/warehouse/inventory/analysis/turnover', { params }).then((res) => {
        this.turnoverData = res.data || { list: [], total: 0 }
      }).finally(() => { this.loadingTu = false })
    },
    loadSlow(page) {
      this.slowQuery.page = page
      this.loadingSl = true
      request.get('/warehouse/inventory/analysis/slow', { params: this.slowQuery }).then((res) => {
        this.slowData = res.data || { list: [], total: 0, chart_bucket: [] }
      }).finally(() => { this.loadingSl = false })
    },
    doExport(type) {
      const q = type === 'turnover' ? this.turnoverQuery : this.slowQuery
      const params = new URLSearchParams()
      params.set('type', type)
      Object.keys(q).forEach((k) => {
        if (q[k] !== '' && q[k] !== 0 && q[k] !== undefined) params.set(k, q[k])
      })
      const token = getToken() || ''
      window.open('/api/warehouse/inventory/analysis/export?' + params.toString() + '&token=' + encodeURIComponent(token), '_blank')
    }
  }
}
</script>

<style scoped>
.search-row {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  align-items: center;
}
.range-hint {
  margin-top: 10px;
  display: flex;
  align-items: center;
  gap: 10px;
  color: #6B7280;
  font-size: 13px;
}
.stat-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 12px;
  margin-top: 14px;
}
.stat-grid.mini {
  margin-top: 12px;
}
.stat-card {
  background: linear-gradient(135deg, rgba(139, 200, 234, 0.12), rgba(139, 200, 234, 0.26));
  border-radius: 12px;
  padding: 16px 14px;
  text-align: center;
}
.stat-card.ok { background: linear-gradient(135deg, rgba(82, 196, 26, 0.10), rgba(82, 196, 26, 0.20)); }
.stat-card.warn { background: linear-gradient(135deg, rgba(250, 173, 20, 0.10), rgba(250, 173, 20, 0.20)); }
.stat-card.bad { background: linear-gradient(135deg, rgba(234, 102, 104, 0.10), rgba(234, 102, 104, 0.20)); }
.stat-num {
  font-size: 22px;
  font-weight: 600;
  color: #1A1B1C;
}
.stat-label {
  font-size: 12px;
  color: #6B7280;
  margin-top: 6px;
}
.chart-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(360px, 1fr));
  gap: 14px;
  margin-top: 14px;
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
