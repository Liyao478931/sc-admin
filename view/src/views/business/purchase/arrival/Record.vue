<!--
  文件：admin/src/views/business/purchase/arrival/Record.vue
  功能：到货记录（已入库历史，只读 + 导出）
  权限：business:purchase:arrival:record:view / record:export
-->
<template>
  <div class="ar-record-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购管理</el-breadcrumb-item>
      <el-breadcrumb-item>到货记录</el-breadcrumb-item>
    </el-breadcrumb>

    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="到货单号">
          <el-input v-model="q.arrival_no" placeholder="请输入到货单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="采购订单">
          <el-input v-model="q.order_no" placeholder="请输入采购订单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="供应商">
          <el-input v-model="q.supplier" placeholder="请输入供应商名称" clearable style="width:140px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="到货时间">
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始" end-placeholder="结束" value-format="yyyy-MM-dd" style="width:240px" @change="handleSearch" />
        </el-form-item>
        <div class="filter-btns">
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </div>
      </el-form>
    </el-card>

    <el-card shadow="never">
      <div class="toolbar">
        <el-button v-permission="'business:purchase:arrival:record:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" @click="getList">刷新</el-button>
        <span class="flex-1"></span>
        <span class="total-tip">共 {{ total }} 条</span>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe border empty-text="暂无到货记录">
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column label="到货单编号" width="150">
          <template slot-scope="s"><span class="link" @click="$router.push('/business/purchase/arrival/detail/' + s.row.id)">{{ s.row.arrival_no }}</span></template>
        </el-table-column>
        <el-table-column label="关联采购订单" width="140">
          <template slot-scope="s"><span class="link" @click="$router.push('/business/purchase/order/detail/' + s.row.order_id)">{{ s.row.order_no }}</span></template>
        </el-table-column>
        <el-table-column prop="supplier_name" label="供应商" width="130" show-overflow-tooltip />
        <el-table-column prop="arrival_date" label="到货日期" width="110" />
        <el-table-column prop="inbound_date" label="入库日期" width="160" />
        <el-table-column prop="receiver" label="收货人" width="90" align="center" />
        <el-table-column label="物流信息" width="140" show-overflow-tooltip>
          <template slot-scope="s"><span>{{ s.row.logistics_company || '' }} {{ s.row.track_no || '' }}</span></template>
        </el-table-column>
        <el-table-column label="操作" width="80" align="center">
          <template slot-scope="s"><el-button type="text" size="mini" @click="$router.push('/business/purchase/arrival/detail/' + s.row.id)">查看</el-button></template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper" :total="total" :page-sizes="[10, 20, 50, 100]" :page-size="q.pageSize" :current-page="q.page" @current-change="p => { q.page = p; getList() }" @size-change="s => { q.pageSize = s; q.page = 1; getList() }" />
    </el-card>
  </div>
</template>

<script>
import { getArrivalRecord, exportArrivalRecord } from '../../../../api/purchase'

export default {
  name: 'PurchaseArrivalRecord',
  data () {
    return {
      q: { page: 1, pageSize: 10, arrival_no: '', order_no: '', supplier: '' },
      dateRange: null,
      list: [], total: 0, loading: false, exporting: false
    }
  },
  created () { this.getList() },
  methods: {
    async getList () {
      this.loading = true
      try {
        const params = { page: this.q.page, pageSize: this.q.pageSize, ...this.q }
        if (this.dateRange && this.dateRange.length === 2) { params.start_date = this.dateRange[0]; params.end_date = this.dateRange[1] }
        const r = await getArrivalRecord(params)
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.q.page = 1; this.getList() },
    handleReset () {
      this.q = { page: 1, pageSize: this.q.pageSize, arrival_no: '', order_no: '', supplier: '' }
      this.dateRange = null
      this.getList()
    },
    async handleExport () {
      this.exporting = true
      try {
        const params = { ...this.q }
        if (this.dateRange && this.dateRange.length === 2) { params.start_date = this.dateRange[0]; params.end_date = this.dateRange[1] }
        const blob = await exportArrivalRecord(params)
        const url = window.URL.createObjectURL(new Blob([blob]))
        const a = document.createElement('a')
        a.href = url
        a.download = `到货记录_${new Date().toISOString().slice(0, 10)}.xlsx`
        a.click()
        window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') } finally { this.exporting = false }
    }
  }
}
</script>

<style scoped>
.ar-record-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.breadcrumb { margin-bottom: 12px; }
.filter-card { margin-bottom: 12px; }
.filter-btns { display: inline-block; margin-left: 4px; }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.total-tip { font-size: 14px; color: #909399; }
.link { color: #409EFF; cursor: pointer; }
.pager { margin-top: 12px; text-align: right; }
</style>
