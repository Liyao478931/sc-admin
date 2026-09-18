<template>
  <div class="tr-page">
    <el-breadcrumb separator="/" class="tr-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>资产调拨</el-breadcrumb-item>
      <el-breadcrumb-item>调拨记录</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 提示横幅 -->
    <div v-if="showBanner" class="tr-banner">
      <i class="el-icon-info tr-banner-icon"></i>
      <span class="tr-banner-text">调拨记录：资产调拨的完整历史记录。可查看本人/本部门/全部调拨记录。</span>
      <i class="el-icon-close tr-banner-close" @click="closeBanner"></i>
    </div>

    <!-- 统计卡片 -->
    <div class="tr-stats">
      <div class="tr-stat-card" @click="filterByStatus('')">
        <div class="tr-stat-info"><div class="tr-stat-num" style="color:#409EFF">{{ stats.total }}</div><div class="tr-stat-label">总调拨</div></div>
        <div class="tr-stat-icon" style="background:#ecf5ff"><i class="el-icon-document" style="color:#409EFF"></i></div>
      </div>
      <div class="tr-stat-card" @click="filterByStatus(0)">
        <div class="tr-stat-info"><div class="tr-stat-num" style="color:#E6A23C">{{ stats.pending }}</div><div class="tr-stat-label">待确认</div></div>
        <div class="tr-stat-icon" style="background:#fdf6ec"><i class="el-icon-time" style="color:#E6A23C"></i></div>
      </div>
      <div class="tr-stat-card" @click="filterByStatus(1)">
        <div class="tr-stat-info"><div class="tr-stat-num" style="color:#67C23A">{{ stats.confirmed }}</div><div class="tr-stat-label">已确认</div></div>
        <div class="tr-stat-icon" style="background:#f0f9eb"><i class="el-icon-success" style="color:#67C23A"></i></div>
      </div>
      <div class="tr-stat-card" @click="filterByStatus(2)">
        <div class="tr-stat-info"><div class="tr-stat-num" style="color:#F56C6C">{{ stats.rejected }}</div><div class="tr-stat-label">已拒绝</div></div>
        <div class="tr-stat-icon" style="background:#fef0f0"><i class="el-icon-error" style="color:#F56C6C"></i></div>
      </div>
    </div>

    <!-- 筛选区 -->
    <div class="tr-filter">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="调拨单号">
          <el-input v-model="query.transfer_no" placeholder="请输入调拨单号" clearable style="width:160px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="调拨类型">
          <el-select v-model="query.transfer_type" clearable placeholder="全部类型" style="width:120px" @change="handleSearch">
            <el-option label="主动调拨" :value="1" />
            <el-option label="申请调拨" :value="2" />
          </el-select>
        </el-form-item>
        <el-form-item label="调拨状态">
          <el-select v-model="query.status" clearable placeholder="全部状态" style="width:120px" @change="handleSearch">
            <el-option v-for="(t, v) in STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="姓名">
          <el-input v-model="query.keyword" placeholder="调出/调入人姓名" clearable style="width:140px" @keyup.enter.native="handleSearch" />
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
    <div class="tr-toolbar">
      <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      <el-button size="small" type="primary" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
      <span class="tr-total">共 {{ total }} 条记录</span>
    </div>

    <!-- 列表 -->
    <div class="tr-table">
      <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无调拨记录，当前筛选条件下没有调拨记录，请调整筛选条件。">
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column label="调拨单号" width="160">
          <template slot-scope="s"><el-link type="primary" @click="openDetail(s.row)">{{ s.row.transfer_no }}</el-link></template>
        </el-table-column>
        <el-table-column label="调拨类型" width="90" align="center">
          <template slot-scope="s"><el-tag :type="s.row.transfer_type === 1 ? 'primary' : 'success'" size="mini">{{ s.row.transfer_type_label }}</el-tag></template>
        </el-table-column>
        <el-table-column label="资产名称" min-width="130" show-overflow-tooltip>
          <template slot-scope="s">{{ s.row.asset_name }}{{ s.row.specification ? '（' + s.row.specification + '）' : '' }}</template>
        </el-table-column>
        <el-table-column prop="source_user_name" label="调出人" width="80" />
        <el-table-column prop="target_user_name" label="调入人" width="80" />
        <el-table-column label="数量" width="80" align="right">
          <template slot-scope="s">{{ s.row.transfer_quantity }} {{ s.row.unit }}</template>
        </el-table-column>
        <el-table-column label="调拨时间" width="150">
          <template slot-scope="s">{{ String(s.row.created_at).slice(0, 16) }}</template>
        </el-table-column>
        <el-table-column label="确认时间" width="150">
          <template slot-scope="s">{{ s.row.confirmed_at ? String(s.row.confirmed_at).slice(0, 16) : '-' }}</template>
        </el-table-column>
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="s"><el-tag :type="statusType(s.row.status)" size="mini">{{ s.row.status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="100" align="center" fixed="right">
          <template slot-scope="s"><el-button type="text" size="mini" @click="openDetail(s.row)">查看详情</el-button></template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 分页 -->
    <div class="tr-pagination">
      <el-pagination background layout="total, sizes, prev, pager, next, jumper"
        :total="total" :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]"
        @current-change="handlePageChange" @size-change="handleSizeChange" />
    </div>

    <!-- 调拨详情弹窗 -->
    <el-dialog :title="'调拨详情 - ' + (detail.transfer_no || '')" :visible.sync="detailVisible" width="650px">
      <div v-loading="detailLoading" class="tr-detail-body">
        <template v-if="detail.transfer_no">
          <div class="tr-detail-sec">
            <div class="tr-detail-title">基本信息</div>
            <div class="tr-detail-grid">
              <div class="tr-detail-item"><span class="tr-detail-lb">调拨单号</span>{{ detail.transfer_no }}</div>
              <div class="tr-detail-item"><span class="tr-detail-lb">调拨类型</span><el-tag :type="detail.transfer_type === 1 ? 'primary' : 'success'" size="mini">{{ detail.transfer_type_label }}</el-tag></div>
              <div class="tr-detail-item"><span class="tr-detail-lb">资产名称</span>{{ detail.asset_name }}</div>
              <div class="tr-detail-item"><span class="tr-detail-lb">规格型号</span>{{ detail.specification || '-' }}</div>
              <div class="tr-detail-item"><span class="tr-detail-lb">调拨数量</span>{{ detail.transfer_quantity }} {{ detail.unit }}</div>
              <div class="tr-detail-item"><span class="tr-detail-lb">资产编码</span>{{ detail.asset_code || '-' }}</div>
              <div class="tr-detail-item"><span class="tr-detail-lb">调出人</span>{{ detail.source_user_name }}{{ detail.source_department ? '（' + detail.source_department + '）' : '' }}</div>
              <div class="tr-detail-item"><span class="tr-detail-lb">调入人</span>{{ detail.target_user_name }}{{ detail.target_department ? '（' + detail.target_department + '）' : '' }}</div>
              <div class="tr-detail-item"><span class="tr-detail-lb">调拨时间</span>{{ detail.created_at }}</div>
              <div class="tr-detail-item"><span class="tr-detail-lb">确认时间</span>{{ detail.confirmed_at || '-' }}</div>
              <div class="tr-detail-item"><span class="tr-detail-lb">状态</span><el-tag :type="statusType(detail.status)" size="mini">{{ detail.status_label }}</el-tag></div>
            </div>
          </div>
          <div v-if="detail.purpose" class="tr-detail-sec">
            <div class="tr-detail-title">用途说明</div>
            <div class="tr-detail-remark">{{ detail.purpose }}</div>
          </div>
          <div v-if="detail.reject_reason" class="tr-detail-sec">
            <div class="tr-detail-title" style="color:#F56C6C">拒绝原因</div>
            <div class="tr-detail-remark" style="color:#F56C6C">{{ detail.reject_reason }}</div>
          </div>
          <div class="tr-detail-sec">
            <div class="tr-detail-title">流转记录</div>
            <div class="tr-flow">
              <div class="tr-flow-item"><span class="tr-flow-dot" style="background:#409EFF"></span><span>{{ detail.created_at }}　{{ detail.source_user_name }} 发起调拨申请</span></div>
              <div v-if="detail.status === 1 && detail.confirmed_at" class="tr-flow-item"><span class="tr-flow-dot" style="background:#67C23A"></span><span>{{ detail.confirmed_at }}　确认接收</span></div>
              <div v-if="detail.status === 1" class="tr-flow-item"><span class="tr-flow-dot" style="background:#67C23A"></span><span>资产已从 {{ detail.source_user_name }} 转移至 {{ detail.target_user_name }}</span></div>
              <div v-if="detail.status === 2 && detail.confirmed_at" class="tr-flow-item"><span class="tr-flow-dot" style="background:#F56C6C"></span><span>{{ detail.confirmed_at }}　拒绝了该调拨申请{{ detail.reject_reason ? '，原因：' + detail.reject_reason : '' }}</span></div>
            </div>
          </div>
        </template>
      </div>
      <div slot="footer"><el-button size="small" @click="detailVisible = false">关闭</el-button></div>
    </el-dialog>
  </div>
</template>

<script>
import { getTransferRecords, getTransferDetail, exportTransferRecords } from '../../api/personalAssets'

const STATUS_TEXT = { 0: '待确认', 1: '已确认', 2: '已拒绝', 3: '已取消' }

export default {
  name: 'TransferRecords',
  data () {
    return {
      STATUS_TEXT,
      showBanner: localStorage.getItem('tr_banner_closed') !== '1',
      stats: { total: 0, pending: 0, confirmed: 0, rejected: 0, cancelled: 0 },
      list: [], total: 0, page: 1, limit: 20, loading: false, exporting: false,
      query: { transfer_no: '', transfer_type: '', status: '', keyword: '' },
      dateRange: [],
      detailVisible: false, detailLoading: false, detail: {}
    }
  },
  created () { this.getList() },
  methods: {
    closeBanner () {
      this.showBanner = false
      localStorage.setItem('tr_banner_closed', '1')
    },
    statusType (s) { return { 0: 'warning', 1: 'success', 2: 'danger', 3: 'info' }[s] || 'info' },
    buildParams () {
      const p = { page: this.page, limit: this.limit }
      if (this.query.transfer_no) p.transfer_no = this.query.transfer_no
      if (this.query.transfer_type !== '' && this.query.transfer_type != null) p.transfer_type = this.query.transfer_type
      if (this.query.status !== '' && this.query.status != null) p.status = this.query.status
      if (this.query.keyword) p.keyword = this.query.keyword
      if (this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] }
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getTransferRecords(this.buildParams())
        if (r.code === 0) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.stats = r.data.statistics || { total: 0, pending: 0, confirmed: 0, rejected: 0, cancelled: 0 }
        }
      } catch (e) {}
      this.loading = false
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () {
      this.query = { transfer_no: '', transfer_type: '', status: '', keyword: '' }
      this.dateRange = []
      this.page = 1
      this.getList()
    },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.limit = s; this.page = 1; this.getList() },
    filterByStatus (s) {
      this.query.status = (s === '' || s == null) ? '' : Number(s)
      this.page = 1
      this.getList()
    },
    async openDetail (row) {
      this.detailVisible = true
      this.detail = {}
      this.detailLoading = true
      try {
        const r = await getTransferDetail({ transfer_id: row.id })
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
        const res = await exportTransferRecords(p)
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('导出失败'); return }
        const url = window.URL.createObjectURL(new Blob([blob]))
        const a = document.createElement('a')
        a.href = url
        a.download = '调拨记录_' + new Date().toISOString().slice(0, 10) + '.xlsx'
        a.click()
        window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') }
      this.exporting = false
    }
  }
}
</script>

<style scoped>
.tr-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.tr-breadcrumb { margin-bottom: 12px; }
.tr-banner { display: flex; align-items: center; background: #ecf5ff; border: 1px solid #d9ecff; border-radius: 4px; padding: 12px 16px; margin-bottom: 16px; }
.tr-banner-icon { color: #409EFF; font-size: 16px; margin-right: 8px; }
.tr-banner-text { flex: 1; font-size: 14px; color: #5a6b7f; }
.tr-banner-close { color: #909399; cursor: pointer; font-size: 14px; }
.tr-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 16px; }
.tr-stat-card { background: #fff; border-radius: 8px; padding: 18px 20px; border: 1px solid #ebeef5; box-shadow: 0 2px 8px rgba(31,45,61,.04); display: flex; align-items: center; justify-content: space-between; cursor: pointer; transition: box-shadow .2s; }
.tr-stat-card:hover { box-shadow: 0 6px 20px rgba(31,45,61,.1); }
.tr-stat-num { font-size: 22px; font-weight: 700; }
.tr-stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.tr-stat-icon { width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px; }
.tr-filter { background: #fff; border-radius: 8px; padding: 16px 16px 0; margin-bottom: 12px; }
.tr-filter .el-form-item { margin-bottom: 16px; margin-right: 16px; }
.tr-filter .el-form-item__label { color: #606266; font-size: 13px; width: 70px; }
.tr-toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.tr-total { margin-left: 12px; color: #909399; font-size: 13px; }
.tr-table { background: #fff; border-radius: 8px; padding: 12px; }
.tr-pagination { display: flex; justify-content: flex-end; margin-top: 20px; }
.tr-detail-body { min-height: 150px; }
.tr-detail-sec { margin-bottom: 16px; }
.tr-detail-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid #f0f2f5; }
.tr-detail-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px 16px; }
.tr-detail-item { font-size: 13px; color: #303133; display: flex; align-items: center; }
.tr-detail-lb { color: #909399; width: 70px; flex-shrink: 0; }
.tr-detail-remark { font-size: 13px; color: #4b5a6c; line-height: 1.7; }
.tr-flow { display: flex; flex-direction: column; gap: 10px; }
.tr-flow-item { display: flex; align-items: center; gap: 8px; font-size: 13px; color: #303133; }
.tr-flow-dot { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; }
</style>