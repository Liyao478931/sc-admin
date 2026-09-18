<!--
  文件：admin/src/views/business/sales/ship/Track.vue
  功能：物流跟踪（统计卡 / 搜索 / 表格 / 轨迹弹窗时间线 / 批量刷新 / 单条刷新 / 导出）
  权限：sales:track:view / refresh / export
  说明：轨迹刷新复用后端物流服务（LogisticsService），未配置物流服务商时如实提示
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>销售管理</el-breadcrumb-item>
      <el-breadcrumb-item>发货管理</el-breadcrumb-item>
      <el-breadcrumb-item>物流跟踪</el-breadcrumb-item>
    </el-breadcrumb>

    <el-row :gutter="20" class="stat-row">
      <el-col :span="6" v-for="s in statCards" :key="s.key">
        <el-card shadow="hover" class="stat-card" @click.native="handleCardClick(s.status)">
          <div class="stat-inner">
            <i :class="s.icon" :style="{ color: s.color, fontSize: '26px' }"></i>
            <div>
              <div class="stat-val" :style="{ color: s.color }">{{ s.value }}</div>
              <div class="stat-lbl">{{ s.label }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="发货单编号"><el-input v-model="searchForm.ship_no" placeholder="请输入发货单编号" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="销售订单"><el-input v-model="searchForm.order_no" placeholder="请输入销售订单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="客户名称"><el-input v-model="searchForm.customer_name" placeholder="请输入客户名称" clearable style="width:130px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="物流公司"><el-input v-model="searchForm.logistics_company" placeholder="请输入物流公司" clearable style="width:120px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="物流单号"><el-input v-model="searchForm.tracking_no" placeholder="请输入物流单号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="物流状态">
          <el-select v-model="searchForm.track_status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in TRACK_STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="发货日期">
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
        <el-button v-permission="'sales:track:refresh'" type="primary" size="small" icon="el-icon-refresh" :loading="batchRefreshing" @click="handleBatchRefresh">批量刷新物流</el-button>
        <el-button v-permission="'sales:track:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <el-table :data="tableData" v-loading="loading" size="small" border stripe empty-text="暂无物流跟踪数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="发货单编号" width="150">
        <template slot-scope="s"><el-link type="primary" @click="$router.push({ path: `/business/sales/ship/detail/${s.row.id}` })">{{ s.row.ship_no }}</el-link></template>
      </el-table-column>
      <el-table-column label="销售订单" width="140">
        <template slot-scope="s"><el-link type="primary" @click="$router.push({ path: '/business/order' })">{{ s.row.order_no || '-' }}</el-link></template>
      </el-table-column>
      <el-table-column prop="customer_name" label="客户名称" width="120" show-overflow-tooltip />
      <el-table-column prop="receiver" label="收货人" width="80" align="center" />
      <el-table-column prop="logistics_company" label="物流公司" width="100" show-overflow-tooltip />
      <el-table-column label="物流单号" width="150">
        <template slot-scope="s">
          <el-link v-if="s.row.tracking_no" type="primary" @click="viewTrackDetail(s.row)">{{ s.row.tracking_no }}</el-link>
          <span v-else>-</span>
        </template>
      </el-table-column>
      <el-table-column label="物流状态" width="100" align="center">
        <template slot-scope="s">
          <el-tag v-if="s.row.track_status" :type="s.row.track_status_tag" size="mini">
            <span v-if="s.row.track_status === 3" class="dot-blink"></span>{{ s.row.track_status_label }}
          </el-tag>
          <el-tag v-else type="info" size="mini">暂无</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="最新轨迹" min-width="200" show-overflow-tooltip>
        <template slot-scope="s">
          <el-tooltip :content="s.row.latest_context || '-'" placement="top"><span>{{ s.row.latest_context || '-' }}</span></el-tooltip>
        </template>
      </el-table-column>
      <el-table-column label="最后更新" width="160" align="center"><template slot-scope="s">{{ s.row.track_updated_at || '-' }}</template></el-table-column>
      <el-table-column label="操作" width="180" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="viewTrackDetail(s.row)">轨迹详情</el-button>
          <el-button v-permission="'sales:track:refresh'" type="text" size="mini" :loading="refreshingId === s.row.id" @click="handleRefreshSingle(s.row)">刷新轨迹</el-button>
          <el-button type="text" size="mini" @click="$router.push({ path: `/business/sales/ship/detail/${s.row.id}` })">查看发货单</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 物流轨迹详情弹窗 -->
    <el-dialog :title="'物流轨迹 - ' + (currentTrack.tracking_no || '')" :visible.sync="dialogVisible" width="700px">
      <template v-if="currentTrack.tracking_no">
        <div class="track-head">
          <span>物流公司：{{ currentTrack.logistics_company || '-' }}</span>
          <span>物流单号：{{ currentTrack.tracking_no }}
            <el-button type="text" size="mini" @click="copyTrackingInfo">复制</el-button>
          </span>
          <el-tag :type="currentTrack.track_status_tag" size="mini">{{ currentTrack.track_status_label }}</el-tag>
          <span class="track-updated">最后更新：{{ currentTrack.updated_at || '-' }}</span>
        </div>
        <el-divider style="margin:10px 0;" />
        <div v-if="currentTrack.nodes && currentTrack.nodes.length" class="track-timeline">
          <el-timeline>
            <el-timeline-item v-for="(n, i) in currentTrack.nodes" :key="i" :timestamp="n.time" placement="top" :type="nodeType(n.type)">
              <span v-if="n.type === 'delivering'" class="dot-blink"></span>
              <i v-if="n.type === 'sign'" class="el-icon-check node-icon-sign"></i>
              <i v-if="n.type === 'exception'" class="el-icon-warning node-icon-exception"></i>
              <span>{{ n.context }}</span>
            </el-timeline-item>
          </el-timeline>
        </div>
        <el-empty v-else description="暂无物流信息，请稍后刷新" :image-size="80" />
        <div class="track-foot">
          <span class="track-source">数据来源：{{ currentTrack.data_source === '本地缓存' ? '本地缓存' : '第三方物流API' }}</span>
          <div>
            <el-button v-permission="'sales:track:refresh'" type="primary" size="small" :loading="dialogRefreshing" @click="handleDialogRefresh">刷新轨迹</el-button>
            <el-button size="small" @click="dialogVisible = false">关闭</el-button>
          </div>
        </div>
      </template>
      <el-empty v-else description="该发货单未填写物流单号" :image-size="80" />
    </el-dialog>
  </div>
</template>

<script>
import { getTrackList, getTrackDetail, refreshTrack, batchRefreshTrack, exportTrack } from '@/api/sales'

const TRACK_STATUS_TEXT = { 1: '已揽收', 2: '运输中', 3: '派送中', 4: '已签收', 5: '异常' }

export default {
  name: 'SalesShipTrack',
  data () {
    return {
      TRACK_STATUS_TEXT,
      searchForm: { ship_no: '', order_no: '', customer_name: '', logistics_company: '', tracking_no: '', track_status: '' },
      dateRange: [],
      tableData: [], total: 0, page: 1, limit: 20, loading: false, exporting: false,
      statistics: { total: 0, in_transit: 0, signed: 0, exception: 0 },
      dialogVisible: false, currentTrack: {}, dialogRefreshing: false,
      refreshingId: 0, batchRefreshing: false,
      statCards: [
        { key: 'total', label: '总发货单', value: 0, icon: 'el-icon-document', color: '#409EFF', status: '' },
        { key: 'in_transit', label: '运输中', value: 0, icon: 'el-icon-van', color: '#E6A23C', status: 2 },
        { key: 'signed', label: '已签收', value: 0, icon: 'el-icon-circle-check', color: '#67C23A', status: 4 },
        { key: 'exception', label: '异常', value: 0, icon: 'el-icon-warning', color: '#F56C6C', status: 5 }
      ]
    }
  },
  created () { this.loadList() },
  methods: {
    buildParams () {
      const p = { page: this.page, limit: this.limit }
      Object.keys(this.searchForm).forEach(k => { if (this.searchForm[k] !== '' && this.searchForm[k] !== null) p[k] = this.searchForm[k] })
      if (this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] }
      return p
    },
    async loadList () {
      this.loading = true
      try {
        const r = await getTrackList(this.buildParams())
        if (r.code === 0 && r.data) {
          this.tableData = r.data.list || []
          this.total = r.data.total || 0
          const s = r.data.statistics || {}
          this.statistics = { total: s.total || 0, in_transit: s.in_transit || 0, signed: s.signed || 0, exception: s.exception || 0 }
          this.statCards.forEach(c => { c.value = this.statistics[c.key] || 0 })
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.loadList() },
    handleReset () { this.searchForm = { ship_no: '', order_no: '', customer_name: '', logistics_company: '', tracking_no: '', track_status: '' }; this.dateRange = []; this.handleSearch() },
    handleCardClick (status) { this.searchForm.track_status = status; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.loadList() },
    handleSizeChange (s) { this.limit = s; this.page = 1; this.loadList() },
    async viewTrackDetail (row) {
      this.currentTrack = {}
      this.dialogVisible = true
      try {
        const r = await getTrackDetail(row.id)
        if (r.code === 0 && r.data) this.currentTrack = r.data
      } catch (e) {}
    },
    handleRefreshSingle (row) {
      this.refreshingId = row.id
      refreshTrack(row.id).then(r => {
        if (r.code === 0) { this.$message.success(r.msg || '刷新成功'); this.loadList() } else this.$message.error(r.msg || '刷新失败')
      }).catch(() => {}).finally(() => { this.refreshingId = 0 })
    },
    handleBatchRefresh () {
      if (!this.tableData.length) { this.$message.warning('当前无可刷新记录'); return }
      this.$confirm(`确认批量刷新当前页 ${this.tableData.length} 条发货单的物流轨迹吗？`, '批量刷新物流', { type: 'warning' }).then(() => {
        this.batchRefreshing = true
        batchRefreshTrack({ ids: this.tableData.map(x => x.id) }).then(r => {
          if (r.code === 0) {
            const d = r.data || {}
            this.$message.success(r.msg || `刷新完成，成功 ${d.success} 条，失败 ${d.failed} 条`)
            this.loadList()
          } else this.$message.error(r.msg || '批量刷新失败')
        }).catch(() => {}).finally(() => { this.batchRefreshing = false })
      }).catch(() => {})
    },
    handleDialogRefresh () {
      if (!this.currentTrack.tracking_no || !this.currentTrack.ship_order_id) { this.$message.warning('缺少发货单信息'); return }
      this.dialogRefreshing = true
      refreshTrack(this.currentTrack.ship_order_id).then(r => {
        if (r.code === 0) {
          this.$message.success('刷新成功')
          this.loadList()
          this.viewTrackDetail({ id: this.currentTrack.ship_order_id })
        } else this.$message.error(r.msg || '刷新失败')
      }).catch(() => {}).finally(() => { this.dialogRefreshing = false })
    },
    copyTrackingInfo () {
      const text = `${this.currentTrack.logistics_company || ''} ${this.currentTrack.tracking_no || ''}`.trim()
      if (!text) return
      const ta = document.createElement('textarea')
      ta.value = text
      document.body.appendChild(ta)
      ta.select()
      try { document.execCommand('copy') } catch (e) {}
      document.body.removeChild(ta)
      this.$message.success('已复制')
    },
    nodeType (type) {
      return { pickup: 'info', transport: 'warning', delivering: 'primary', sign: 'success', exception: 'danger' }[type] || 'primary'
    },
    async handleExport () {
      this.exporting = true
      try {
        const p = { ...this.buildParams() }
        delete p.page; delete p.limit
        const r = await exportTrack(p)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `物流跟踪列表_${new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14)}.xlsx`
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
.stat-row { margin-bottom: 16px; }
.stat-card { cursor: pointer; }
.stat-inner { display: flex; align-items: center; gap: 12px; }
.stat-val { font-size: 24px; font-weight: bold; }
.stat-lbl { font-size: 13px; color: #909399; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.track-head { display: flex; flex-wrap: wrap; align-items: center; gap: 14px; font-size: 13px; color: #606266; }
.track-updated { color: #909399; }
.track-timeline { max-height: 420px; overflow-y: auto; padding: 4px 6px; }
.track-foot { display: flex; justify-content: space-between; align-items: center; margin-top: 14px; }
.track-source { color: #909399; font-size: 12px; }
.node-icon-sign { color: #67C23A; margin-right: 4px; }
.node-icon-exception { color: #F56C6C; margin-right: 4px; }
@keyframes blink { 0% { opacity: 1; } 50% { opacity: 0.2; } 100% { opacity: 1; } }
.dot-blink { display: inline-block; width: 8px; height: 8px; border-radius: 50%; background-color: #409EFF; animation: blink 1.2s ease-in-out infinite; margin-right: 4px; }
</style>
