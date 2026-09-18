<!--
  文件：admin/src/views/warehouse/inventory/Flow.vue
  功能：库存流水（列表/多维度筛选/来源单据追溯/详情抽屉/导出；支持库存查询按 material_id 联动）
  权限：warehouse:inventory:flow:view / export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>库存管理</el-breadcrumb-item>
      <el-breadcrumb-item>库存流水</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="物料名称"><el-input v-model="query.material_name" placeholder="请输入物料名称" clearable style="width:170px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="物料编码"><el-input v-model="query.material_code" placeholder="请输入物料编码" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="变动类型">
          <el-select v-model="query.change_type" clearable placeholder="全部" style="width:140px">
            <el-option v-for="(t, v) in CHANGE_TYPES" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="来源单据编号"><el-input v-model="query.source_no" placeholder="请输入来源单据编号" clearable style="width:170px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="仓库">
          <el-select v-model="query.warehouse_id" clearable filterable placeholder="全部" style="width:150px">
            <el-option v-for="w in warehouseOptions" :key="w.id" :label="w.warehouse_name" :value="w.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="变动日期">
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:230px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'warehouse:inventory:flow:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条记录</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无库存流水记录">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="变动时间" width="160" align="center"><template slot-scope="s">{{ s.row.created_at || '-' }}</template></el-table-column>
      <el-table-column prop="material_code" label="物料编码" width="130" />
      <el-table-column prop="material_name" label="物料名称" min-width="150" show-overflow-tooltip />
      <el-table-column label="变动类型" width="110" align="center">
        <template slot-scope="s"><el-tag :type="s.row.change_type_tag" size="mini">{{ s.row.change_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="变动数量" width="120" align="right">
        <template slot-scope="s">
          <span :style="{ color: Number(s.row.change_quantity) >= 0 ? '#67C23A' : '#F56C6C' }">{{ Number(s.row.change_quantity) >= 0 ? '+' : '' }}{{ Number(s.row.change_quantity).toFixed(4) }}</span>
        </template>
      </el-table-column>
      <el-table-column label="变动前库存" width="120" align="right"><template slot-scope="s">{{ Number(s.row.before_stock).toFixed(4) }}</template></el-table-column>
      <el-table-column label="变动后库存" width="120" align="right"><template slot-scope="s">{{ Number(s.row.after_stock).toFixed(4) }}</template></el-table-column>
      <el-table-column label="成本单价" width="120" align="right"><template slot-scope="s">¥ {{ Number(s.row.cost_price).toFixed(4) }}</template></el-table-column>
      <el-table-column label="成本总价" width="130" align="right"><template slot-scope="s">¥ {{ Number(s.row.cost_total).toFixed(4) }}</template></el-table-column>
      <el-table-column label="来源单据" width="160">
        <template slot-scope="s">
          <el-link v-if="s.row.source_no" type="primary" @click="goSource(s.row)">{{ s.row.source_no }}</el-link>
          <span v-else>-</span>
        </template>
      </el-table-column>
      <el-table-column prop="operator_name" label="操作人" width="90" align="center" />
      <el-table-column label="备注" width="150" show-overflow-tooltip><template slot-scope="s">{{ s.row.remark || '-' }}</template></el-table-column>
      <el-table-column label="操作" width="120" align="center" fixed="right">
        <template slot-scope="s"><el-button type="text" size="mini" @click="openDetail(s.row)">查看详情</el-button></template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 流水详情抽屉 -->
    <el-drawer title="库存流水详情" :visible.sync="drawerVisible" size="600px" :close-on-press-escape="true">
      <el-descriptions v-if="detail.id" :column="2" border size="small" class="drawer-desc">
        <el-descriptions-item label="流水 ID">{{ detail.id }}</el-descriptions-item>
        <el-descriptions-item label="变动时间">{{ detail.created_at || '-' }}</el-descriptions-item>
        <el-descriptions-item label="物料编码">{{ detail.material_code || '-' }}</el-descriptions-item>
        <el-descriptions-item label="物料名称">{{ detail.material_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="规格型号">{{ detail.specification || '-' }}</el-descriptions-item>
        <el-descriptions-item label="单位">{{ detail.unit || '-' }}</el-descriptions-item>
        <el-descriptions-item label="变动类型">{{ detail.change_type_label }}</el-descriptions-item>
        <el-descriptions-item label="变动数量">{{ Number(detail.change_quantity).toFixed(4) }}</el-descriptions-item>
        <el-descriptions-item label="变动前库存">{{ Number(detail.before_stock).toFixed(4) }}</el-descriptions-item>
        <el-descriptions-item label="变动后库存">{{ Number(detail.after_stock).toFixed(4) }}</el-descriptions-item>
        <el-descriptions-item label="成本单价">¥ {{ Number(detail.cost_price).toFixed(4) }}</el-descriptions-item>
        <el-descriptions-item label="成本总价">¥ {{ Number(detail.cost_total).toFixed(4) }}</el-descriptions-item>
        <el-descriptions-item label="变动前加权单价">{{ Number(detail.before_avg_price).toFixed(4) }}</el-descriptions-item>
        <el-descriptions-item label="变动后加权单价">{{ Number(detail.after_avg_price).toFixed(4) }}</el-descriptions-item>
        <el-descriptions-item label="来源单据类型">{{ detail.source_type || '-' }}</el-descriptions-item>
        <el-descriptions-item label="来源单据编号">
          <el-link v-if="detail.source_no" type="primary" @click="goSource(detail)">{{ detail.source_no }}</el-link><span v-else>-</span>
        </el-descriptions-item>
        <el-descriptions-item label="来源单据 ID">{{ detail.source_id || '-' }}</el-descriptions-item>
        <el-descriptions-item label="仓库名称">{{ detail.warehouse_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="货位名称">{{ detail.location_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="操作人">{{ detail.operator_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="变动时间">{{ detail.created_at || '-' }}</el-descriptions-item>
        <el-descriptions-item label="备注" :span="2">{{ detail.remark || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-drawer>
  </div>
</template>

<script>
import { getFlowList, exportFlow, getWarehouseList } from '../../../api/warehouse'

const CHANGE_TYPES = { 1: '采购入库', 2: '配件领用', 3: '成品入库', 4: '销售出库', 5: '配件退库', 6: '报废出库', 7: '产品入库', 8: '产品出库', 9: '报废出库' }
// 来源类型 -> 前端详情路由
const SOURCE_ROUTES = {
  '采购入库单': '/warehouse/parts/purchase-in/detail/',
  '领料单': '/warehouse/parts/pick/detail/',
  '退库单': '/warehouse/parts/return/detail/',
  '报废单': '/warehouse/parts/scrap/detail/',
  '入库单': '/warehouse/product/in/detail/',
  '出库单': '/warehouse/product/out/detail/'
}

export default {
  name: 'WarehouseInventoryFlow',
  data () {
    return {
      CHANGE_TYPES,
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false,
      query: { material_name: '', material_code: '', change_type: '', source_no: '', warehouse_id: '', material_id: 0 },
      dateRange: [], warehouseOptions: [],
      drawerVisible: false, detail: {}
    }
  },
  created () {
    this.loadWarehouses()
    // 库存查询联动：URL 带 material_id 自动筛选
    const mid = Number(this.$route.query.material_id || 0)
    if (mid > 0) this.query.material_id = mid
    this.getList()
  },
  methods: {
    async loadWarehouses () {
      try {
        const r = await getWarehouseList({ page: 1, pageSize: 100, status: 1 })
        this.warehouseOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
      } catch (e) { this.warehouseOptions = [] }
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.material_name) p.material_name = this.query.material_name
      if (this.query.material_code) p.material_code = this.query.material_code
      if (this.query.change_type !== '' && this.query.change_type !== null) p.change_type = this.query.change_type
      if (this.query.source_no) p.source_no = this.query.source_no
      if (this.query.warehouse_id) p.warehouse_id = this.query.warehouse_id
      if (this.query.material_id) p.material_id = this.query.material_id
      if (this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] }
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getFlowList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () {
      this.query = { material_name: '', material_code: '', change_type: '', source_no: '', warehouse_id: '', material_id: 0 }
      const mid = Number(this.$route.query.material_id || 0)
      if (mid > 0) this.query.material_id = mid
      this.dateRange = []
      this.handleSearch()
    },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.getList() },
    goSource (row) {
      const route = SOURCE_ROUTES[row.source_type]
      if (!route || !row.source_id) { this.$message.warning('该单据已不存在'); return }
      this.$router.push({ path: route + row.source_id })
    },
    openDetail (row) { this.detail = row; this.drawerVisible = true },
    async handleExport () {
      this.exporting = true
      try {
        const p = { ...this.buildParams() }
        delete p.page; delete p.pageSize
        const r = await exportFlow(p)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `库存流水_${new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14)}.xlsx`
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
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.drawer-desc { padding: 0 20px; }
</style>
