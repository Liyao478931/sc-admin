<template>
  <div class="ad-page">
    <el-breadcrumb separator="/" class="ad-breadcrumb">
      <el-breadcrumb-item>个人资产</el-breadcrumb-item>
      <el-breadcrumb-item>固定资产管理</el-breadcrumb-item>
      <el-breadcrumb-item>资产折旧</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 提示横幅 -->
    <div v-if="showBanner" class="ad-banner">
      <i class="el-icon-info ad-banner-icon"></i>
      <span class="ad-banner-text">资产折旧：固定资产每月折旧计提管理。系统根据资产档案中的折旧方法自动计算当月折旧额。</span>
      <i class="el-icon-close ad-banner-close" @click="showBanner = false; localStorage.setItem('ad_banner_closed', '1')"></i>
    </div>

    <!-- 操作栏 -->
    <div class="ad-toolbar">
      <el-button size="small" type="primary" icon="el-icon-coin" @click="openExecute">计提本月折旧</el-button>
      <el-button size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出折旧明细</el-button>
      <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadAll">刷新</el-button>
      <el-button size="small" icon="el-icon-time" @click="openHistory">折旧历史</el-button>
      <span class="ad-month">折旧月份：{{ currentMonthLabel }}</span>
    </div>

    <!-- 汇总统计 -->
    <div class="ad-stats">
      <div class="ad-stat-card"><div class="ad-stat-info"><div class="ad-stat-num" style="color:#409EFF">¥{{ Number(stats.total_depreciation).toLocaleString() }}</div><div class="ad-stat-label">本月折旧</div></div><div class="ad-stat-icon" style="background:#ecf5ff"><i class="el-icon-data-line" style="color:#409EFF"></i></div></div>
      <div class="ad-stat-card"><div class="ad-stat-info"><div class="ad-stat-num" style="color:#E6A23C">¥{{ Number(stats.total_accumulated).toLocaleString() }}</div><div class="ad-stat-label">累计折旧</div></div><div class="ad-stat-icon" style="background:#fdf6ec"><i class="el-icon-trend-charts" style="color:#E6A23C"></i></div></div>
      <div class="ad-stat-card"><div class="ad-stat-info"><div class="ad-stat-num" style="color:#67C23A">¥{{ Number(stats.total_net_value).toLocaleString() }}</div><div class="ad-stat-label">资产净值</div></div><div class="ad-stat-icon" style="background:#f0f9eb"><i class="el-icon-money" style="color:#67C23A"></i></div></div>
      <div class="ad-stat-card"><div class="ad-stat-info"><div class="ad-stat-num" style="color:#9B59B6">{{ stats.asset_count }}</div><div class="ad-stat-label">计提资产</div></div><div class="ad-stat-icon" style="background:#f5f0fa"><i class="el-icon-document" style="color:#9B59B6"></i></div></div>
    </div>

    <!-- 筛选 -->
    <div class="ad-filter">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item label="关键词">
          <el-input v-model="query.keyword" placeholder="资产名称/编号" clearable style="width:180px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 列表 -->
    <div class="ad-table">
      <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无资产数据">
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column label="资产编号" width="130"><template slot-scope="s"><el-link type="primary" @click="openAssetDetail(s.row)">{{ s.row.asset_no }}</el-link></template></el-table-column>
        <el-table-column prop="asset_name" label="资产名称" min-width="120" show-overflow-tooltip />
        <el-table-column prop="category_name" label="分类" width="90" />
        <el-table-column label="原值" width="100" align="right"><template slot-scope="s">¥{{ Number(s.row.total_value).toLocaleString() }}</template></el-table-column>
        <el-table-column label="残值" width="100" align="right"><template slot-scope="s">¥{{ Number(s.row.residual_value).toLocaleString() }}</template></el-table-column>
        <el-table-column prop="depreciation_method_label" label="折旧方法" width="85" align="center" />
        <el-table-column label="月折旧率" width="90" align="right"><template slot-scope="s">{{ s.row.month_rate }}%</template></el-table-column>
        <el-table-column label="本月折旧" width="100" align="right">
          <template slot-scope="s">
            <span :style="{ color: s.row.is_executed ? '#67C23A' : '#409EFF' }">¥{{ Number(s.row.current_depreciation).toLocaleString() }}</span>
            <el-tag v-if="s.row.is_executed" type="success" size="mini" style="margin-left:4px">已计提</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="累计折旧" width="105" align="right"><template slot-scope="s">¥{{ Number(s.row.accumulated_depreciation).toLocaleString() }}</template></el-table-column>
        <el-table-column label="当前净值" width="105" align="right"><template slot-scope="s">¥{{ Number(s.row.current_net_value).toLocaleString() }}</template></el-table-column>
        <el-table-column label="已折旧月数" width="100" align="center"><template slot-scope="s">{{ s.row.depreciated_months }}/{{ s.row.depreciation_months }}</template></el-table-column>
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="s"><el-tag :type="s.row.asset_status === 5 ? 'info' : 'success'" size="mini">{{ s.row.asset_status_label }}</el-tag></template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 分页 -->
    <div class="ad-pagination">
      <el-pagination background layout="total, sizes, prev, pager, next, jumper"
        :total="total" :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]"
        @current-change="handlePageChange" @size-change="handleSizeChange" />
    </div>

    <!-- 计提确认弹窗 -->
    <el-dialog title="计提本月折旧" :visible.sync="executeVisible" width="480px">
      <div class="ad-execute-box">
        <p class="ad-execute-title">确认计提 <b style="color:#409EFF">{{ currentMonthLabel }}</b> 折旧？</p>
        <p>本次将计提以下资产：</p>
        <ul class="ad-execute-list">
          <li>应计提资产数：{{ stats.asset_count || 0 }} 项</li>
          <li>预计折旧总额：¥{{ Number(stats.total_depreciation).toLocaleString() }}</li>
        </ul>
        <div class="ad-warn">⚠️ 提示：<br />• 已报废的资产不计提折旧<br />• 已提足折旧的资产将自动停止计提<br />• 此操作不可撤销</div>
      </div>
      <div slot="footer">
        <el-button size="small" @click="executeVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="executing" @click="submitExecute">确认计提</el-button>
      </div>
    </el-dialog>

    <!-- 折旧历史弹窗 -->
    <el-dialog title="折旧历史" :visible.sync="historyVisible" width="800px">
      <div class="ad-history-filter">
        <el-date-picker v-model="historyMonth" type="month" value-format="yyyy-MM" placeholder="选择月份" size="small" clearable style="width:140px" />
        <el-input v-model="historyKeyword" placeholder="资产名称/编号" size="small" clearable style="width:180px;margin-left:8px" />
        <el-button size="small" type="primary" @click="loadHistory(1)">查询</el-button>
      </div>
      <el-table :data="historyList" v-loading="historyLoading" size="small" border>
        <el-table-column prop="depreciation_month" label="月份" width="90" />
        <el-table-column prop="asset_no" label="资产编号" width="120" />
        <el-table-column prop="asset_name" label="资产名称" min-width="110" show-overflow-tooltip />
        <el-table-column label="原值" width="100" align="right"><template slot-scope="s">¥{{ Number(s.row.original_value).toLocaleString() }}</template></el-table-column>
        <el-table-column label="折旧额" width="100" align="right"><template slot-scope="s">¥{{ Number(s.row.depreciation_amount).toLocaleString() }}</template></el-table-column>
        <el-table-column label="累计折旧" width="105" align="right"><template slot-scope="s">¥{{ Number(s.row.accumulated_depreciation).toLocaleString() }}</template></el-table-column>
        <el-table-column label="净值" width="105" align="right"><template slot-scope="s">¥{{ Number(s.row.net_value).toLocaleString() }}</template></el-table-column>
      </el-table>
      <div class="ad-pagination" style="margin-top:12px">
        <el-pagination background layout="total, prev, pager, next" :total="historyTotal" :current-page="historyPage" :page-size="20" @current-change="loadHistory" />
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getDepreciationStats, getDepreciationList, executeDepreciation, getDepreciationHistory, exportDepreciation, getAssetArchiveDetail } from '../../api/assetArchive'

export default {
  name: 'AssetDepreciation',
  data () {
    return {
      showBanner: localStorage.getItem('ad_banner_closed') !== '1',
      currentMonth: new Date().toISOString().slice(0, 7),
      stats: { depreciation_month: '', total_depreciation: 0, total_accumulated: 0, total_net_value: 0, asset_count: 0 },
      list: [], total: 0, page: 1, limit: 20, loading: false, exporting: false,
      query: { keyword: '' },
      executeVisible: false, executing: false,
      historyVisible: false, historyLoading: false, historyList: [], historyTotal: 0, historyPage: 1, historyMonth: '', historyKeyword: ''
    }
  },
  computed: {
    currentMonthLabel () {
      const m = this.currentMonth
      return m ? m.split('-')[0] + '年' + Number(m.split('-')[1]) + '月' : ''
    }
  },
  created () { this.loadAll() },
  methods: {
    buildParams () {
      const p = { page: this.page, limit: this.limit, depreciation_month: this.currentMonth }
      if (this.query.keyword) p.keyword = this.query.keyword
      return p
    },
    async loadAll () {
      this.loadStats()
      this.getList()
    },
    async loadStats () {
      try {
        const r = await getDepreciationStats({ depreciation_month: this.currentMonth })
        if (r.code === 0) this.stats = r.data
      } catch (e) {}
    },
    async getList () {
      this.loading = true
      try {
        const r = await getDepreciationList(this.buildParams())
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.query = { keyword: '' }; this.page = 1; this.getList() },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.limit = s; this.page = 1; this.getList() },
    openExecute () {
      if (this.stats.asset_count > 0) { this.$message.warning('本月折旧已计提，请勿重复操作'); return }
      this.executeVisible = true
    },
    async submitExecute () {
      this.executing = true
      try {
        const r = await executeDepreciation()
        if (r.code === 0) {
          this.$message.success(r.msg || '折旧计提成功')
          this.executeVisible = false
          this.loadAll()
        }
      } catch (e) {}
      this.executing = false
    },
    openHistory () {
      this.historyVisible = true
      this.historyMonth = this.currentMonth
      this.historyKeyword = ''
      this.loadHistory(1)
    },
    async loadHistory (page) {
      this.historyPage = page || 1
      this.historyLoading = true
      try {
        const r = await getDepreciationHistory({ depreciation_month: this.historyMonth || '', keyword: this.historyKeyword, page: this.historyPage, limit: 20 })
        if (r.code === 0) { this.historyList = r.data.list || []; this.historyTotal = r.data.total || 0 }
      } catch (e) {}
      this.historyLoading = false
    },
    async handleExport () {
      this.exporting = true
      try {
        const res = await exportDepreciation({ depreciation_month: this.currentMonth })
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('导出失败'); return }
        const url = window.URL.createObjectURL(new Blob([blob]))
        const a = document.createElement('a')
        a.href = url
        a.download = '折旧明细_' + this.currentMonth + '.xlsx'
        a.click()
        window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') }
      this.exporting = false
    },
    async openAssetDetail (row) {
      try {
        const r = await getAssetArchiveDetail(row.id)
        if (r.code === 0) {
          const d = r.data
          this.$alert(
            `资产编号：${d.asset_no}\n资产名称：${d.asset_name}\n原值：¥${Number(d.total_value).toLocaleString()}\n残值：¥${Number(d.residual_value).toLocaleString()}\n累计折旧：¥${Number(d.accumulated_depreciation).toLocaleString()}\n当前净值：¥${Number(d.current_net_value).toLocaleString()}\n已折旧月数：${d.depreciated_months}/${d.depreciation_months}`,
            '资产折旧详情',
            { confirmButtonText: '关闭' }
          )
        }
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.ad-page { padding: 16px; background: #f0f2f5; min-height: 100vh; }
.ad-breadcrumb { margin-bottom: 12px; }
.ad-banner { display: flex; align-items: center; background: #ecf5ff; border: 1px solid #d9ecff; border-radius: 4px; padding: 12px 16px; margin-bottom: 16px; }
.ad-banner-icon { color: #409EFF; font-size: 16px; margin-right: 8px; }
.ad-banner-text { flex: 1; font-size: 14px; color: #5a6b7f; }
.ad-banner-close { color: #909399; cursor: pointer; font-size: 14px; }
.ad-toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.ad-month { margin-left: 12px; color: #409EFF; font-size: 13px; font-weight: 600; }
.ad-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 16px; }
.ad-stat-card { background: #fff; border-radius: 8px; padding: 18px 20px; border: 1px solid #ebeef5; box-shadow: 0 2px 8px rgba(31,45,61,.04); display: flex; align-items: center; justify-content: space-between; }
.ad-stat-num { font-size: 20px; font-weight: 700; }
.ad-stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.ad-stat-icon { width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px; }
.ad-filter { background: #fff; border-radius: 8px; padding: 14px 16px 0; margin-bottom: 12px; }
.ad-filter .el-form-item { margin-bottom: 14px; }
.ad-table { background: #fff; border-radius: 8px; padding: 12px; }
.ad-pagination { display: flex; justify-content: flex-end; margin-top: 20px; }
.ad-execute-box { font-size: 14px; color: #303133; }
.ad-execute-title { font-size: 15px; margin-bottom: 12px; }
.ad-execute-list { margin: 8px 0 12px; padding-left: 20px; line-height: 1.8; }
.ad-warn { background: #fef0f0; border: 1px solid #fde2e2; border-radius: 6px; padding: 10px 12px; font-size: 12px; color: #F56C6C; line-height: 1.8; margin-top: 12px; }
.ad-history-filter { display: flex; align-items: center; margin-bottom: 12px; }
</style>