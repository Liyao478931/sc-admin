<template>
  <div class="rr-page">
    <el-breadcrumb separator="/" class="rr-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>资产退还</el-breadcrumb-item>
      <el-breadcrumb-item>退还记录</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 统计卡片 -->
    <div class="rr-stats">
      <div class="rr-stat-card" @click="filterByStatus('')">
        <div class="rr-stat-info"><div class="rr-stat-num" style="color:#409EFF">{{ stats.total }}</div><div class="rr-stat-label">总退还</div></div>
        <div class="rr-stat-icon" style="background:#ecf5ff"><i class="el-icon-document" style="color:#409EFF"></i></div>
      </div>
      <div class="rr-stat-card" @click="filterByStatus(0)">
        <div class="rr-stat-info"><div class="rr-stat-num" style="color:#E6A23C">{{ stats.pending }}</div><div class="rr-stat-label">待审批</div></div>
        <div class="rr-stat-icon" style="background:#fdf6ec"><i class="el-icon-time" style="color:#E6A23C"></i></div>
      </div>
      <div class="rr-stat-card" @click="filterByStatus(1)">
        <div class="rr-stat-info"><div class="rr-stat-num" style="color:#67C23A">{{ stats.returned }}</div><div class="rr-stat-label">已退还</div></div>
        <div class="rr-stat-icon" style="background:#f0f9eb"><i class="el-icon-success" style="color:#67C23A"></i></div>
      </div>
      <div class="rr-stat-card" @click="filterByStatus(2)">
        <div class="rr-stat-info"><div class="rr-stat-num" style="color:#F56C6C">{{ stats.rejected }}</div><div class="rr-stat-label">已驳回</div></div>
        <div class="rr-stat-icon" style="background:#fef0f0"><i class="el-icon-error" style="color:#F56C6C"></i></div>
      </div>
    </div>

    <!-- 筛选区 -->
    <div class="rr-filter">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="退还单号">
          <el-input v-model="query.return_no" placeholder="请输入退还单号" clearable style="width:160px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:120px" @change="handleSearch">
            <el-option v-for="(t, v) in STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
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
    <div class="rr-toolbar">
      <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      <el-button size="small" type="primary" icon="el-icon-plus" @click="$router.push('/personal-assets/return-apply')">退还申请</el-button>
      <span class="rr-total">共 {{ total }} 条记录</span>
    </div>

    <!-- 列表 -->
    <div class="rr-table">
      <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无退还记录">
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column label="退还单号" width="160">
          <template slot-scope="s"><el-link type="primary" @click="openDetail(s.row)">{{ s.row.return_no }}</el-link></template>
        </el-table-column>
        <el-table-column prop="asset_name" label="资产名称" min-width="110" show-overflow-tooltip />
        <el-table-column prop="specification" label="规格型号" width="100" show-overflow-tooltip />
        <el-table-column label="退还数量" width="90" align="right">
          <template slot-scope="s">{{ s.row.return_quantity }} {{ s.row.unit }}</template>
        </el-table-column>
        <el-table-column prop="user_name" label="申请人" width="80" />
        <el-table-column label="申请时间" width="150">
          <template slot-scope="s">{{ String(s.row.created_at).slice(0, 16) }}</template>
        </el-table-column>
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="s"><el-tag :type="statusType(s.row.status)" size="mini">{{ s.row.status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="120" align="center" fixed="right">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="openDetail(s.row)">详情</el-button>
            <el-button v-if="s.row.status === 1 && s.row.approval_instance_id" type="text" size="mini" @click="goApproval(s.row)">审批进度</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 分页 -->
    <div class="rr-pagination">
      <el-pagination background layout="total, sizes, prev, pager, next, jumper"
        :total="total" :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]"
        @current-change="handlePageChange" @size-change="handleSizeChange" />
    </div>

    <!-- 详情弹窗 -->
    <el-dialog :title="'退还详情 - ' + (detail.return_no || '')" :visible.sync="detailVisible" width="600px">
      <div v-loading="detailLoading" class="rr-detail-body">
        <template v-if="detail.return_no">
          <div class="rr-detail-sec">
            <div class="rr-detail-title">基本信息</div>
            <div class="rr-detail-grid">
              <div class="rr-detail-item"><span class="rr-detail-lb">退还单号</span>{{ detail.return_no }}</div>
              <div class="rr-detail-item"><span class="rr-detail-lb">申请人</span>{{ detail.user_name }}</div>
              <div class="rr-detail-item"><span class="rr-detail-lb">申请时间</span>{{ detail.created_at }}</div>
              <div class="rr-detail-item"><span class="rr-detail-lb">状态</span><el-tag :type="statusType(detail.status)" size="mini">{{ detail.status_label }}</el-tag></div>
            </div>
          </div>
          <div class="rr-detail-sec">
            <div class="rr-detail-title">资产信息</div>
            <div class="rr-detail-grid">
              <div class="rr-detail-item"><span class="rr-detail-lb">资产名称</span>{{ detail.asset_name }}</div>
              <div class="rr-detail-item"><span class="rr-detail-lb">规格型号</span>{{ detail.specification || '-' }}</div>
              <div class="rr-detail-item"><span class="rr-detail-lb">资产编码</span>{{ detail.asset_code || '-' }}</div>
              <div class="rr-detail-item"><span class="rr-detail-lb">类型</span>{{ detail.asset_type_label }}</div>
              <div class="rr-detail-item"><span class="rr-detail-lb">退还数量</span>{{ detail.return_quantity }} {{ detail.unit }}</div>
            </div>
          </div>
          <div class="rr-detail-sec">
            <div class="rr-detail-title">退还信息</div>
            <div class="rr-detail-remark">原因：{{ detail.reason }}</div>
            <el-image v-if="detail.photo" :src="detail.photo" fit="cover" class="rr-photo" :preview-src-list="[detail.photo]" />
          </div>
          <div class="rr-detail-sec">
            <div class="rr-detail-title">审批信息</div>
            <div class="rr-detail-grid">
              <div class="rr-detail-item"><span class="rr-detail-lb">退还时间</span>{{ detail.return_time || '-' }}</div>
              <div v-if="detail.reject_reason" class="rr-detail-item" style="color:#F56C6C"><span class="rr-detail-lb">驳回原因</span>{{ detail.reject_reason }}</div>
            </div>
          </div>
        </template>
      </div>
      <div slot="footer"><el-button size="small" @click="detailVisible = false">关闭</el-button></div>
    </el-dialog>
  </div>
</template>

<script>
import { getReturnRecords, getReturnDetail } from '../../api/personalAssets'

const STATUS_TEXT = { 0: '待审批', 1: '已退还', 2: '已驳回' }

export default {
  name: 'ReturnRecords',
  data () {
    return {
      STATUS_TEXT,
      stats: { total: 0, pending: 0, returned: 0, rejected: 0 },
      list: [], total: 0, page: 1, limit: 20, loading: false,
      query: { return_no: '', status: '' },
      dateRange: [],
      detailVisible: false, detailLoading: false, detail: {}
    }
  },
  created () { this.getList() },
  methods: {
    statusType (s) { return { 0: 'warning', 1: 'success', 2: 'danger' }[s] || 'info' },
    buildParams () {
      const p = { page: this.page, limit: this.limit }
      if (this.query.return_no) p.return_no = this.query.return_no
      if (this.query.status !== '' && this.query.status != null) p.status = this.query.status
      if (this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] }
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getReturnRecords(this.buildParams())
        if (r.code === 0) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.stats = r.data.statistics || { total: 0, pending: 0, returned: 0, rejected: 0 }
        }
      } catch (e) {}
      this.loading = false
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () {
      this.query = { return_no: '', status: '' }
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
    goApproval (row) {
      if (row.approval_instance_id) this.$router.push('/approval/my-initiated/detail/' + row.approval_instance_id)
    },
    async openDetail (row) {
      this.detailVisible = true
      this.detail = {}
      this.detailLoading = true
      try {
        const r = await getReturnDetail({ id: row.id })
        if (r.code === 0) this.detail = r.data
      } catch (e) {}
      this.detailLoading = false
    }
  }
}
</script>

<style scoped>
.rr-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.rr-breadcrumb { margin-bottom: 12px; }
.rr-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 16px; }
.rr-stat-card { background: #fff; border-radius: 8px; padding: 18px 20px; border: 1px solid #ebeef5; box-shadow: 0 2px 8px rgba(31,45,61,.04); display: flex; align-items: center; justify-content: space-between; cursor: pointer; }
.rr-stat-card:hover { box-shadow: 0 6px 20px rgba(31,45,61,.1); }
.rr-stat-num { font-size: 22px; font-weight: 700; }
.rr-stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.rr-stat-icon { width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px; }
.rr-filter { background: #fff; border-radius: 8px; padding: 16px 16px 0; margin-bottom: 12px; }
.rr-filter .el-form-item { margin-bottom: 16px; margin-right: 16px; }
.rr-filter .el-form-item__label { color: #606266; font-size: 13px; width: 70px; }
.rr-toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.rr-total { margin-left: 12px; color: #909399; font-size: 13px; }
.rr-table { background: #fff; border-radius: 8px; padding: 12px; }
.rr-pagination { display: flex; justify-content: flex-end; margin-top: 20px; }
.rr-detail-body { min-height: 150px; }
.rr-detail-sec { margin-bottom: 16px; }
.rr-detail-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid #f0f2f5; }
.rr-detail-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px 16px; }
.rr-detail-item { font-size: 13px; color: #303133; display: flex; align-items: center; }
.rr-detail-lb { color: #909399; width: 70px; flex-shrink: 0; }
.rr-detail-remark { font-size: 13px; color: #4b5a6c; line-height: 1.7; }
.rr-photo { width: 120px; height: 120px; border-radius: 8px; margin-top: 8px; }
</style>