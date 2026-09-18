<!--
  文件：admin/src/views/business/receive/Archive.vue
  功能：产品档案（产品维修履历）列表：搜索/统计卡片/表格/导出/跳详情
  权限：business:receive:archive:view / archive:export
-->
<template>
  <div class="rc-archive-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品接收管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品档案</el-breadcrumb-item>
    </el-breadcrumb>

    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="产品名称"><el-input v-model="q.name" placeholder="请输入产品名称" clearable style="width:140px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="编码/编号"><el-input v-model="q.code" placeholder="产品编码或设备编号" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="产品分类">
          <el-select v-model="q.category_id" clearable filterable style="width:150px">
            <el-option v-for="c in categoryOptions" :key="c.id" :label="c.category_name || c.name" :value="c.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="产品状态">
          <el-select v-model="q.product_status" placeholder="全部" clearable style="width:110px" @change="handleSearch">
            <el-option v-for="(t, v) in PRODUCT_STATUSES" :key="v" :label="t" :value="v" />
          </el-select>
        </el-form-item>
        <el-form-item label="来源矿井">
          <el-select v-model="q.source_mine" clearable filterable style="width:140px" @change="handleSearch">
            <el-option v-for="m in sourceMines" :key="m" :label="m" :value="m" />
          </el-select>
        </el-form-item>
        <el-form-item label="最近维修">
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始" end-placeholder="结束" value-format="yyyy-MM-dd" style="width:220px" @change="handleSearch" />
        </el-form-item>
        <div class="filter-btns">
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
          <el-button v-permission="'business:receive:archive:export'" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        </div>
      </el-form>
    </el-card>

    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stats-row">
      <el-col :span="6" v-for="(c, k) in statCards" :key="k">
        <el-card shadow="never" class="stat-card" :class="{ active: statKey === k }" @click.native="applyStat(k)">
          <div class="stat-num" :style="{ color: c.color }">{{ stats[c.field] }}</div>
          <div class="stat-label">{{ c.label }}</div>
        </el-card>
      </el-col>
    </el-row>

    <el-card shadow="never">
      <div class="toolbar">
        <el-button size="small" icon="el-icon-refresh" @click="getList">刷新</el-button>
        <span class="flex-1"></span>
        <span class="total-tip">共 {{ total }} 台/个</span>
      </div>
      <el-table :data="list" v-loading="loading" size="small" stripe border empty-text="暂无产品档案">
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column label="产品编码" width="130">
          <template slot-scope="s"><span class="link" @click="goDetail(s.row.id)">{{ s.row.product_code }}</span></template>
        </el-table-column>
        <el-table-column label="产品名称" min-width="150">
          <template slot-scope="s"><span class="link" @click="goDetail(s.row.id)">{{ s.row.product_name }}</span></template>
        </el-table-column>
        <el-table-column label="设备编号/序列号" width="140" show-overflow-tooltip>
          <template slot-scope="s"><span v-if="s.row.serial_number" class="link" @click="goDetail(s.row.id)">{{ s.row.serial_number }}</span><span v-else>-</span></template>
        </el-table-column>
        <el-table-column prop="specification" label="规格型号" width="130" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="70" align="center" />
        <el-table-column prop="manufacturer" label="生产厂家" width="130" show-overflow-tooltip />
        <el-table-column label="产品状态" width="100" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="pStatusTag(s.row.status)">{{ s.row.status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="current_location" label="当前所在位置" width="120" show-overflow-tooltip />
        <el-table-column prop="last_repair_date" label="最近维修日期" width="120" />
        <el-table-column prop="receive_count" label="接收次数" width="85" align="center" />
        <el-table-column label="操作" width="90" align="center" fixed="right">
          <template slot-scope="s"><el-button type="text" size="mini" @click="goDetail(s.row.id)">查看详情</el-button></template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper" :total="total" :page-sizes="[10, 20, 50, 100]" :page-size="q.pageSize" :current-page="q.page" @current-change="p => { q.page = p; getList() }" @size-change="s => { q.pageSize = s; q.page = 1; getList() }" />
    </el-card>
  </div>
</template>

<script>
import { getReceiveArchive, exportReceiveArchive } from '../../../api/purchase'
import { getProductCategoryOptions } from '../../../api/product'

const PRODUCT_STATUSES = { 1: '完好', 2: '待维修', 3: '待保养', 4: '报废', 5: '待检验' }

export default {
  name: 'ProductReceiveArchive',
  data () {
    return {
      PRODUCT_STATUSES,
      q: { page: 1, pageSize: 10, name: '', code: '', category_id: null, product_status: '', source_mine: '' },
      dateRange: null,
      list: [], total: 0, loading: false, exporting: false,
      stats: { total: 0, repair: 0, good: 0, scrap: 0 },
      statKey: '',
      sourceMines: [], categoryOptions: []
    }
  },
  computed: {
    statCards () {
      return [
        { key: 'total', field: 'total', label: '总产品数', color: '#409EFF' },
        { key: 'repair', field: 'repair', label: '待维修', color: '#E6A23C' },
        { key: 'good', field: 'good', label: '完好', color: '#67C23A' },
        { key: 'scrap', field: 'scrap', label: '报废', color: '#F56C6C' }
      ]
    }
  },
  created () {
    this.loadCategories()
    this.getList()
  },
  methods: {
    async loadCategories () {
      try { const r = await getProductCategoryOptions(); this.categoryOptions = (r.data && Array.isArray(r.data)) ? r.data : [] } catch (e) { this.categoryOptions = [] }
    },
    async getList () {
      this.loading = true
      try {
        const params = { page: this.q.page, pageSize: this.q.pageSize, name: this.q.name, code: this.q.code, product_status: this.q.product_status, source_mine: this.q.source_mine }
        if (this.q.category_id) params.category_id = this.q.category_id
        if (this.dateRange && this.dateRange.length === 2) { params.start_date = this.dateRange[0]; params.end_date = this.dateRange[1] }
        const r = await getReceiveArchive(params)
        if (r.code === 0) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.stats = r.data.stats || this.stats
          this.sourceMines = r.data.source_mines || []
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.q.page = 1; this.getList() },
    handleReset () {
      this.q = { page: 1, pageSize: this.q.pageSize, name: '', code: '', category_id: null, product_status: '', source_mine: '' }
      this.dateRange = null
      this.statKey = ''
      this.getList()
    },
    applyStat (key) {
      if (this.statKey === key) { this.statKey = ''; this.q.product_status = '' }
      else {
        this.statKey = key
        this.q.product_status = { repair: '2', good: '1', scrap: '4' }[key] || ''
      }
      this.q.page = 1
      this.getList()
    },
    pStatusTag (v) { return { 1: 'success', 2: 'warning', 3: 'primary', 4: 'danger', 5: 'info' }[v] || 'info' },
    goDetail (id) { this.$router.push('/business/receive/archive/detail/' + id) },
    async handleExport () {
      this.exporting = true
      try {
        const params = { name: this.q.name, code: this.q.code, product_status: this.q.product_status, source_mine: this.q.source_mine }
        if (this.q.category_id) params.category_id = this.q.category_id
        if (this.dateRange && this.dateRange.length === 2) { params.start_date = this.dateRange[0]; params.end_date = this.dateRange[1] }
        const blob = await exportReceiveArchive(params)
        const url = window.URL.createObjectURL(new Blob([blob]))
        const a = document.createElement('a'); a.href = url; a.download = `产品档案_${new Date().toISOString().slice(0, 10)}.xlsx`
        a.click(); window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') } finally { this.exporting = false }
    }
  }
}
</script>

<style scoped>
.rc-archive-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.breadcrumb { margin-bottom: 12px; }
.filter-card { margin-bottom: 12px; }
.filter-btns { display: inline-block; margin-left: 4px; }
.stats-row { margin-bottom: 12px; }
.stat-card { text-align: center; cursor: pointer; transition: all .2s; }
.stat-card.active { border-color: #409EFF; box-shadow: 0 0 0 1px #409EFF inset; }
.stat-num { font-size: 26px; font-weight: 700; color: #303133; }
.stat-label { font-size: 13px; color: #909399; margin-top: 4px; }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.total-tip { font-size: 14px; color: #909399; }
.link { color: #409EFF; cursor: pointer; }
.pager { margin-top: 12px; text-align: right; }
</style>
