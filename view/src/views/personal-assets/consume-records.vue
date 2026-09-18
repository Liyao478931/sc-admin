<template>
  <div class="cr-page">
    <el-breadcrumb separator="/" class="cr-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>消耗记录</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 提示横幅 -->
    <div v-if="showBanner" class="cr-banner">
      <i class="el-icon-info cr-banner-icon"></i>
      <span class="cr-banner-text">消耗记录：报工消耗个人资产的记录汇总。消耗数据来源于报工单。</span>
      <i class="el-icon-close cr-banner-close" @click="closeBanner"></i>
    </div>

    <!-- 统计卡片 -->
    <div class="cr-stats">
      <div class="cr-stat-card">
        <div class="cr-stat-info"><div class="cr-stat-num" style="color:#409EFF">{{ stats.total_count }}</div><div class="cr-stat-label">总消耗次数</div></div>
        <div class="cr-stat-icon" style="background:#ecf5ff"><i class="el-icon-document" style="color:#409EFF"></i></div>
      </div>
      <div class="cr-stat-card">
        <div class="cr-stat-info"><div class="cr-stat-num" style="color:#67C23A">{{ stats.total_quantity }}</div><div class="cr-stat-label">总消耗数量</div></div>
        <div class="cr-stat-icon" style="background:#f0f9eb"><i class="el-icon-box" style="color:#67C23A"></i></div>
      </div>
      <div class="cr-stat-card">
        <div class="cr-stat-info"><div class="cr-stat-num" style="color:#E6A23C">{{ stats.total_types }}</div><div class="cr-stat-label">消耗种类</div></div>
        <div class="cr-stat-icon" style="background:#fdf6ec"><i class="el-icon-setting" style="color:#E6A23C"></i></div>
      </div>
    </div>

    <!-- 筛选区 -->
    <div class="cr-filter">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="报工单号">
          <el-input v-model="query.report_no" placeholder="请输入报工单号" clearable style="width:150px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="工单编号">
          <el-input v-model="query.order_no" placeholder="请输入工单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="配件名称">
          <el-input v-model="query.keyword" placeholder="请输入配件名称" clearable style="width:140px" @keyup.enter.native="handleSearch" />
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
    <div class="cr-toolbar">
      <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      <span class="cr-total">共 {{ total }} 条记录</span>
    </div>

    <!-- 列表 -->
    <div class="cr-table">
      <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无消耗记录，您尚未在报工时消耗个人配件，或暂无相关记录。">
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column label="报工单号" width="160">
          <template slot-scope="s"><el-link type="primary" @click="goReport(s.row)">{{ s.row.report_no }}</el-link></template>
        </el-table-column>
        <el-table-column prop="order_no" label="工单编号" width="140" show-overflow-tooltip />
        <el-table-column prop="product_name" label="产品名称" min-width="110" show-overflow-tooltip />
        <el-table-column prop="asset_name" label="配件名称" min-width="110" show-overflow-tooltip />
        <el-table-column prop="specification" label="规格型号" width="100" show-overflow-tooltip />
        <el-table-column label="消耗数量" width="90" align="right">
          <template slot-scope="s">{{ s.row.consume_quantity }} {{ s.row.unit }}</template>
        </el-table-column>
        <el-table-column label="消耗时间" width="150">
          <template slot-scope="s">{{ String(s.row.created_at).slice(0, 16) }}</template>
        </el-table-column>
        <el-table-column label="操作" width="100" align="center" fixed="right">
          <template slot-scope="s"><el-button type="text" size="mini" @click="openDetail(s.row)">查看详情</el-button></template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 分页 -->
    <div class="cr-pagination">
      <el-pagination background layout="total, sizes, prev, pager, next, jumper"
        :total="total" :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]"
        @current-change="handlePageChange" @size-change="handleSizeChange" />
    </div>

    <!-- 消耗详情弹窗 -->
    <el-dialog title="消耗详情" :visible.sync="detailVisible" width="500px">
      <div v-loading="detailLoading" class="cr-detail-body">
        <template v-if="detail.report_no">
          <div class="cr-detail-grid">
            <div class="cr-detail-item"><span class="cr-detail-lb">报工单号</span>{{ detail.report_no }}</div>
            <div class="cr-detail-item"><span class="cr-detail-lb">工单编号</span>{{ detail.order_no || '-' }}</div>
            <div class="cr-detail-item"><span class="cr-detail-lb">产品名称</span>{{ detail.product_name || '-' }}</div>
            <div class="cr-detail-item"><span class="cr-detail-lb">报工人</span>{{ detail.reporter_name || '-' }}</div>
            <div class="cr-detail-item"><span class="cr-detail-lb">消耗时间</span>{{ String(detail.created_at).slice(0, 16) }}</div>
          </div>
          <div class="cr-detail-sec">
            <div class="cr-detail-title">消耗明细</div>
            <el-table :data="detail.items" size="small" border>
              <el-table-column type="index" label="序号" width="55" align="center" />
              <el-table-column prop="asset_name" label="配件名称" min-width="110" />
              <el-table-column prop="specification" label="规格型号" width="100" show-overflow-tooltip />
              <el-table-column label="数量" width="90" align="right"><template slot-scope="s">{{ s.row.consume_quantity }} {{ s.row.unit }}</template></el-table-column>
            </el-table>
          </div>
        </template>
      </div>
      <div slot="footer">
        <el-button size="small" @click="detailVisible = false">关闭</el-button>
        <el-button size="small" type="primary" @click="goReport(detail)">查看完整报工</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getConsumeRecords, getConsumeDetail } from '../../api/personalAssets'

export default {
  name: 'ConsumeRecords',
  data () {
    return {
      showBanner: localStorage.getItem('cr_banner_closed') !== '1',
      stats: { total_count: 0, total_quantity: 0, total_types: 0 },
      list: [], total: 0, page: 1, limit: 20, loading: false,
      query: { report_no: '', order_no: '', keyword: '' },
      dateRange: [],
      detailVisible: false, detailLoading: false, detail: {}
    }
  },
  created () { this.getList() },
  methods: {
    closeBanner () {
      this.showBanner = false
      localStorage.setItem('cr_banner_closed', '1')
    },
    buildParams () {
      const p = { page: this.page, limit: this.limit }
      if (this.query.report_no) p.report_no = this.query.report_no
      if (this.query.order_no) p.order_no = this.query.order_no
      if (this.query.keyword) p.keyword = this.query.keyword
      if (this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] }
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getConsumeRecords(this.buildParams())
        if (r.code === 0) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.stats = r.data.statistics || { total_count: 0, total_quantity: 0, total_types: 0 }
        }
      } catch (e) {}
      this.loading = false
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () {
      this.query = { report_no: '', order_no: '', keyword: '' }
      this.dateRange = []
      this.page = 1
      this.getList()
    },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.limit = s; this.page = 1; this.getList() },
    goReport (row) {
      this.$router.push('/production/report/detail/' + row.report_id)
    },
    async openDetail (row) {
      this.detailVisible = true
      this.detail = {}
      this.detailLoading = true
      try {
        const r = await getConsumeDetail({ report_id: row.report_id })
        if (r.code === 0) this.detail = r.data
      } catch (e) {}
      this.detailLoading = false
    }
  }
}
</script>

<style scoped>
.cr-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.cr-breadcrumb { margin-bottom: 12px; }
.cr-banner { display: flex; align-items: center; background: #ecf5ff; border: 1px solid #d9ecff; border-radius: 4px; padding: 12px 16px; margin-bottom: 16px; }
.cr-banner-icon { color: #409EFF; font-size: 16px; margin-right: 8px; }
.cr-banner-text { flex: 1; font-size: 14px; color: #5a6b7f; }
.cr-banner-close { color: #909399; cursor: pointer; font-size: 14px; }
.cr-stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-bottom: 16px; }
.cr-stat-card { background: #fff; border-radius: 8px; padding: 18px 20px; border: 1px solid #ebeef5; box-shadow: 0 2px 8px rgba(31,45,61,.04); display: flex; align-items: center; justify-content: space-between; }
.cr-stat-num { font-size: 22px; font-weight: 700; }
.cr-stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.cr-stat-icon { width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px; }
.cr-filter { background: #fff; border-radius: 8px; padding: 16px 16px 0; margin-bottom: 12px; }
.cr-filter .el-form-item { margin-bottom: 16px; margin-right: 16px; }
.cr-filter .el-form-item__label { color: #606266; font-size: 13px; width: 70px; }
.cr-toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.cr-total { margin-left: 12px; color: #909399; font-size: 13px; }
.cr-table { background: #fff; border-radius: 8px; padding: 12px; }
.cr-pagination { display: flex; justify-content: flex-end; margin-top: 20px; }
.cr-detail-body { min-height: 150px; }
.cr-detail-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px 16px; }
.cr-detail-item { font-size: 13px; color: #303133; display: flex; align-items: center; }
.cr-detail-lb { color: #909399; width: 70px; flex-shrink: 0; }
.cr-detail-sec { margin-top: 16px; }
.cr-detail-title { font-size: 14px; font-weight: 600; color: #1f2d3d; margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid #f0f2f5; }
</style>