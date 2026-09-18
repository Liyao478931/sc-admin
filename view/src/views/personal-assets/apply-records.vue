<template>
  <div class="ar-page">
    <el-breadcrumb separator="/" class="ar-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>资产领用</el-breadcrumb-item>
      <el-breadcrumb-item>领用记录</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 提示横幅 -->
    <div v-if="showBanner" class="ar-banner">
      <i class="el-icon-info ar-banner-icon"></i>
      <span class="ar-banner-text">领用记录：所有领用申请的汇总清单。可查看本人/本部门/全部领用记录。</span>
      <i class="el-icon-close ar-banner-close" @click="closeBanner"></i>
    </div>

    <!-- 筛选区 -->
    <div class="ar-filter">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="领用单号">
          <el-input v-model="query.apply_no" placeholder="请输入领用单号" clearable style="width:160px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="领用类型">
          <el-select v-model="query.apply_type" clearable placeholder="全部类型" style="width:120px" @change="handleSearch">
            <el-option label="配件领用" :value="1" />
            <el-option label="资产领用" :value="2" />
          </el-select>
        </el-form-item>
        <el-form-item label="审批状态">
          <el-select v-model="query.status" clearable placeholder="全部状态" style="width:120px" @change="handleSearch">
            <el-option v-for="(t, v) in STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="领用人">
          <el-input v-model="query.picker_name" placeholder="请输入领用人姓名" clearable style="width:140px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="时间范围">
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="~" start-placeholder="开始" end-placeholder="结束" style="width:240px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 操作栏 -->
    <div class="ar-toolbar">
      <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      <el-button size="small" type="primary" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
      <span class="ar-total">共 {{ total }} 条记录</span>
    </div>

    <!-- 列表 -->
    <div class="ar-table">
      <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无领用记录，当前筛选条件下没有领用记录，请调整筛选条件。">
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column label="领用单号" width="160">
          <template slot-scope="s"><el-link type="primary" @click="openDetail(s.row)">{{ s.row.apply_no }}</el-link></template>
        </el-table-column>
        <el-table-column prop="picker_name" label="领用人" width="80" />
        <el-table-column prop="department_name" label="部门" width="120" show-overflow-tooltip />
        <el-table-column label="领用类型" width="90" align="center">
          <template slot-scope="s">
            <el-tag :type="s.row.apply_type === 1 ? 'primary' : 'success'" size="mini">{{ s.row.apply_type_label }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="item_summary" label="物品名称" min-width="140" show-overflow-tooltip />
        <el-table-column label="领用数量" width="90" align="right">
          <template slot-scope="s">{{ s.row.total_quantity }} {{ s.row.unit }}</template>
        </el-table-column>
        <el-table-column label="领用时间" width="160">
          <template slot-scope="s">{{ String(s.row.apply_date).slice(0, 16) }}</template>
        </el-table-column>
        <el-table-column label="审批状态" width="100" align="center">
          <template slot-scope="s"><el-tag :type="statusType(s.row.status)" size="mini">{{ s.row.status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="100" align="center" fixed="right">
          <template slot-scope="s"><el-button type="text" size="mini" @click="openDetail(s.row)">查看详情</el-button></template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 分页 -->
    <div class="ar-pagination">
      <el-pagination background layout="total, sizes, prev, pager, next, jumper"
        :total="total" :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]"
        @current-change="handlePageChange" @size-change="handleSizeChange" />
    </div>

    <!-- 领用单详情弹窗 -->
    <el-dialog :title="'领用单详情 - ' + (detail.apply_no || '')" :visible.sync="detailVisible" width="700px">
      <div v-loading="detailLoading" class="ar-detail-body">
        <template v-if="detail.apply_no">
          <div class="ar-detail-sec">
            <div class="ar-detail-title">基本信息</div>
            <div class="ar-detail-grid">
              <div class="ar-detail-item"><span class="ar-detail-lb">领用单号</span>{{ detail.apply_no }}</div>
              <div class="ar-detail-item"><span class="ar-detail-lb">领用类型</span><el-tag :type="detail.apply_type === 1 ? 'primary' : 'success'" size="mini">{{ detail.apply_type_label }}</el-tag></div>
              <div class="ar-detail-item"><span class="ar-detail-lb">领用人</span>{{ detail.picker_name }}</div>
              <div class="ar-detail-item"><span class="ar-detail-lb">部门</span>{{ detail.department_name || '-' }}</div>
              <div class="ar-detail-item"><span class="ar-detail-lb">领用时间</span>{{ String(detail.apply_date).slice(0, 16) }}</div>
              <div class="ar-detail-item"><span class="ar-detail-lb">审批状态</span><el-tag :type="statusType(detail.status)" size="mini">{{ detail.status_label }}</el-tag></div>
              <div class="ar-detail-item"><span class="ar-detail-lb">关联工单</span>{{ detail.work_order_no || '-' }}</div>
              <div class="ar-detail-item"><span class="ar-detail-lb">备注</span>{{ detail.remark || '-' }}</div>
            </div>
          </div>
          <div class="ar-detail-sec">
            <div class="ar-detail-title">领用明细</div>
            <el-table :data="detail.items" size="small" border>
              <el-table-column type="index" label="序号" width="55" align="center" />
              <el-table-column prop="item_name" label="物品名称" min-width="140" />
              <el-table-column prop="specification" label="规格型号" width="120" show-overflow-tooltip />
              <el-table-column prop="unit" label="单位" width="60" align="center" />
              <el-table-column prop="quantity" label="领用数量" width="90" align="right" />
              <el-table-column prop="remark" label="备注" min-width="100" show-overflow-tooltip />
            </el-table>
          </div>
        </template>
      </div>
      <div slot="footer">
        <el-button size="small" @click="detailVisible = false">关闭</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getApplyRecords, getApplyDetail, exportApplyRecords } from '../../api/personalAssets'

const STATUS_TEXT = { 0: '草稿', 1: '待审批', 2: '已审批', 3: '已驳回', 4: '已取消' }

export default {
  name: 'ApplyRecords',
  data () {
    return {
      STATUS_TEXT,
      showBanner: localStorage.getItem('ar_banner_closed') !== '1',
      list: [], total: 0, page: 1, limit: 20, loading: false, exporting: false,
      query: { apply_no: '', apply_type: '', status: '', picker_name: '' },
      dateRange: [],
      detailVisible: false, detailLoading: false, detail: {}
    }
  },
  created () { this.getList() },
  methods: {
    closeBanner () {
      this.showBanner = false
      localStorage.setItem('ar_banner_closed', '1')
    },
    statusType (s) { return { 0: 'info', 1: 'warning', 2: 'success', 3: 'danger', 4: 'info' }[s] || 'info' },
    buildParams () {
      const p = { page: this.page, limit: this.limit }
      if (this.query.apply_no) p.apply_no = this.query.apply_no
      if (this.query.apply_type !== '' && this.query.apply_type != null) p.apply_type = this.query.apply_type
      if (this.query.status !== '' && this.query.status != null) p.status = this.query.status
      if (this.query.picker_name) p.picker_name = this.query.picker_name
      if (this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] }
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getApplyRecords(this.buildParams())
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () {
      this.query = { apply_no: '', apply_type: '', status: '', picker_name: '' }
      this.dateRange = []
      this.page = 1
      this.getList()
    },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.limit = s; this.page = 1; this.getList() },
    async openDetail (row) {
      this.detailVisible = true
      this.detail = {}
      this.detailLoading = true
      try {
        const r = await getApplyDetail({ source_table: row.source_table, source_id: row.source_id })
        if (r.code === 0) this.detail = r.data
      } catch (e) {}
      this.detailLoading = false
    },
    async handleExport () {
      this.exporting = true
      try {
        const p = { ...this.buildParams() }
        delete p.page
        delete p.limit
        const res = await exportApplyRecords(p)
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('导出失败'); return }
        const url = window.URL.createObjectURL(new Blob([blob]))
        const a = document.createElement('a')
        a.href = url
        a.download = '领用记录_' + new Date().toISOString().slice(0, 10) + '.xlsx'
        a.click()
        window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') }
      this.exporting = false
    }
  }
}
</script>

<style scoped>
.ar-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.ar-breadcrumb { margin-bottom: 12px; }
.ar-banner { display: flex; align-items: center; background: #ecf5ff; border: 1px solid #d9ecff; border-radius: 4px; padding: 12px 16px; margin-bottom: 16px; }
.ar-banner-icon { color: #409EFF; font-size: 16px; margin-right: 8px; }
.ar-banner-text { flex: 1; font-size: 14px; color: #5a6b7f; }
.ar-banner-close { color: #909399; cursor: pointer; font-size: 14px; }
.ar-filter { background: #fff; border-radius: 8px; padding: 16px 16px 0; margin-bottom: 12px; }
.ar-filter .el-form-item { margin-bottom: 16px; margin-right: 16px; }
.ar-filter .el-form-item__label { color: #606266; font-size: 13px; width: 70px; }
.ar-toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.ar-total { margin-left: 12px; color: #909399; font-size: 13px; }
.ar-table { background: #fff; border-radius: 8px; padding: 12px; }
.ar-pagination { display: flex; justify-content: flex-end; margin-top: 20px; }
.ar-detail-body { min-height: 200px; }
.ar-detail-sec { margin-bottom: 16px; }
.ar-detail-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid #f0f2f5; }
.ar-detail-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px 16px; }
.ar-detail-item { font-size: 13px; color: #303133; display: flex; align-items: center; }
.ar-detail-lb { color: #909399; width: 70px; flex-shrink: 0; }
</style>