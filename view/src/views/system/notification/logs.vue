<template>
  <div class="log-page">
    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="6"><div class="stat-card" style="borderTopColor:#409EFF;">
        <div class="stat-icon" style="background:#409EFF1a;color:#409EFF;"><i class="el-icon-document"></i></div>
        <div class="stat-body"><div class="stat-value" style="color:#409EFF;">{{ stats.total }}</div><div class="stat-label">总发送数</div></div>
      </div></el-col>
      <el-col :span="6"><div class="stat-card" style="borderTopColor:#67C23A;">
        <div class="stat-icon" style="background:#67C23A1a;color:#67C23A;"><i class="el-icon-circle-check"></i></div>
        <div class="stat-body"><div class="stat-value" style="color:#67C23A;">{{ stats.success }}</div><div class="stat-label">成功数</div></div>
      </div></el-col>
      <el-col :span="6"><div class="stat-card" style="borderTopColor:#F56C6C;">
        <div class="stat-icon" style="background:#F56C6C1a;color:#F56C6C;"><i class="el-icon-circle-close"></i></div>
        <div class="stat-body"><div class="stat-value" style="color:#F56C6C;">{{ stats.failed }}</div><div class="stat-label">失败数</div></div>
      </div></el-col>
      <el-col :span="6"><div class="stat-card" style="borderTopColor:#8E44AD;">
        <div class="stat-icon" style="background:#8E44AD1a;color:#8E44AD;"><i class="el-icon-percent"></i></div>
        <div class="stat-body"><div class="stat-value" style="color:#8E44AD;">{{ stats.rate }}%</div><div class="stat-label">成功率</div></div>
      </div></el-col>
    </el-row>

    <!-- 筛选区域 -->
    <el-card shadow="never" class="filter-card">
      <el-form :inline="true" size="small" @submit.native.prevent>
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入消息标题或接收人" clearable style="width:200px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.msg_type" clearable placeholder="全部类型" style="width:120px" @change="onSearch">
            <el-option v-for="(t, k) in TYPE_MAP" :key="k" :label="t.label" :value="Number(k)" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.channel" clearable placeholder="全部渠道" style="width:120px" @change="onSearch">
            <el-option v-for="(c, k) in CHANNELS" :key="k" :label="c.label" :value="k" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.send_status" clearable placeholder="全部状态" style="width:110px" @change="onSearch">
            <el-option label="待发送" value="0" /><el-option label="发送中" value="1" />
            <el-option label="成功" value="2" /><el-option label="失败" value="3" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="filters.dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至"
            start-placeholder="开始日期" end-placeholder="结束日期" style="width:230px" @change="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilter">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 工具栏 -->
    <el-card shadow="never" class="list-card">
      <div class="toolbar">
        <span>共 <b>{{ total }}</b> 条记录<span v-if="selection.length" style="margin-left:12px;">已选 <b style="color:#409EFF;">{{ selection.length }}</b> 条</span></span>
        <div>
          <el-button v-if="hasPerm('notification:log:retry')" size="small" type="warning" :disabled="!selection.length" icon="el-icon-refresh" @click="batchRetry">批量重发</el-button>
          <el-button v-if="hasPerm('notification:log:export')" size="small" icon="el-icon-download" :loading="exporting" @click="doExport">导出</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadAll">刷新</el-button>
        </div>
      </div>

      <!-- 表格 -->
      <el-table :data="list" v-loading="loading" size="small" stripe @selection-change="s => (selection = s)">
        <el-table-column type="selection" width="40" />
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column label="记录编号" width="180">
          <template slot-scope="{ row }">
            <el-button type="text" size="mini" @click="openDetail(row)">{{ row.log_id }}</el-button>
          </template>
        </el-table-column>
        <el-table-column prop="title" label="消息标题" min-width="140" show-overflow-tooltip />
        <el-table-column prop="to_user_name" label="接收人" width="80" show-overflow-tooltip />
        <el-table-column label="消息类型" width="100" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :style="tagStyle(typeOf(row.msg_type))">{{ row.msg_type_text }}</el-tag></template>
        </el-table-column>
        <el-table-column label="发送渠道" width="90" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :style="tagStyle(channelOf(row.channel))">{{ row.channel_text }}</el-tag></template>
        </el-table-column>
        <el-table-column label="发送状态" width="90" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="statusType(row.send_status)">{{ row.status_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="send_time" label="发送时间" width="160" />
        <el-table-column label="操作" width="160" align="center">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('notification:log:query')" type="text" size="mini" @click="openDetail(row)">详情</el-button>
            <el-button v-if="hasPerm('notification:log:retry') && Number(row.send_status) === 3" type="text" size="mini" style="color:#E6A23C" @click="retryOne(row)">重发</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination class="pager" background layout="total, sizes, prev, pager, next" :total="total"
        :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50]"
        @size-change="s => { limit = s; page = 1; loadAll() }"
        @current-change="p => { page = p; loadAll() }" />
    </el-card>

    <!-- 详情弹窗 -->
    <notification-log-detail-dialog v-if="detailVisible" :visible.sync="detailVisible" :log-id="detailId" />

    <!-- 批量重发结果弹窗 -->
    <el-dialog title="批量重发结果" :visible.sync="retryResultVisible" width="520px">
      <template v-if="retryResult">
        <div class="retry-summary">
          <el-tag type="success" size="medium">成功 {{ retryResult.success_count }} 条</el-tag>
          <el-tag type="danger" size="medium">失败 {{ retryResult.failed_count }} 条</el-tag>
        </div>
        <div v-if="retryResult.failed_list && retryResult.failed_list.length" class="retry-detail">
          <div v-for="(f, i) in retryResult.failed_list" :key="i" class="retry-fail">【{{ f.title || ('#' + f.id) }}】{{ f.msg }}</div>
        </div>
      </template>
    </el-dialog>
  </div>
</template>

<script>
import {
  getNotificationLogList, getNotificationLogStatistics, retryNotificationLog,
  batchRetryNotificationLog, exportNotificationLog
} from '@/api/notificationLog'
import NotificationLogDetailDialog from './components/NotificationLogDetailDialog.vue'

// 消息类型
const TYPE_MAP = {
  1: { label: '系统公告', color: '#909399' },
  2: { label: '任务指派', color: '#409EFF' },
  3: { label: '审批通知', color: '#E6A23C' },
  4: { label: '预警提醒', color: '#F56C6C' },
  5: { label: '培训通知', color: '#67C23A' },
  6: { label: '工单通知', color: '#8E44AD' }
}
// 发送渠道
const CHANNELS = {
  inbox: { label: '站内信', color: '#409EFF' },
  email: { label: '邮件', color: '#67C23A' },
  sms: { label: '短信', color: '#E6A23C' },
  wechat: { label: '微信', color: '#67C23A' },
  dingtalk: { label: '钉钉', color: '#409EFF' },
  workwx: { label: '企业微信', color: '#409EFF' }
}

export default {
  name: 'NotificationLogs',
  components: { NotificationLogDetailDialog },
  data () {
    return {
      TYPE_MAP, CHANNELS,
      list: [], total: 0, page: 1, limit: 10, loading: false,
      stats: { total: 0, success: 0, failed: 0, rate: 0 },
      filters: { keyword: '', msg_type: '', channel: '', send_status: '', dateRange: null },
      selection: [],
      detailVisible: false, detailId: 0,
      retryResultVisible: false, retryResult: null,
      exporting: false
    }
  },
  created () { this.loadAll() },
  methods: {
    hasPerm (code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    typeOf (t) { return TYPE_MAP[t] || { label: '未知', color: '#909399' } },
    channelOf (c) { return CHANNELS[c] || { label: c, color: '#909399' } },
    tagStyle (t) { return { color: t.color, borderColor: t.color, background: t.color + '1a' } },
    statusType (s) { return { 0: 'info', 1: 'warning', 2: 'success', 3: 'danger' }[s] || 'info' },
    async loadAll () {
      this.loading = true
      try {
        await Promise.all([this.loadStats(), this.loadList()])
      } catch (e) { this.$message.error('发送记录加载失败') } finally { this.loading = false }
    },
    async loadStats () {
      const r = await getNotificationLogStatistics()
      if (r.code === 0) this.stats = r.data || { total: 0, success: 0, failed: 0, rate: 0 }
    },
    async loadList () {
      const params = { page: this.page, limit: this.limit }
      if (this.filters.keyword) params.keyword = this.filters.keyword
      if (this.filters.msg_type) params.msg_type = this.filters.msg_type
      if (this.filters.channel) params.channel = this.filters.channel
      if (this.filters.send_status !== '' && this.filters.send_status !== null) params.send_status = this.filters.send_status
      if (this.filters.dateRange && this.filters.dateRange.length === 2) {
        params.start_date = this.filters.dateRange[0]
        params.end_date = this.filters.dateRange[1]
      }
      const r = await getNotificationLogList(params)
      if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
    },
    onSearch () { this.page = 1; this.loadAll() },
    resetFilter () { this.filters = { keyword: '', msg_type: '', channel: '', send_status: '', dateRange: null }; this.page = 1; this.loadAll() },
    openDetail (row) { this.detailId = row.id; this.detailVisible = true },
    // 单条重发
    retryOne (row) {
      this.$confirm(`确认重新发送消息「${row.title}」？`, '重发确认', { type: 'warning' }).then(async () => {
        try {
          const r = await retryNotificationLog(row.id)
          if (r.code === 0) { this.$message.success('重发成功'); this.loadAll() }
        } catch (e) {} finally { this.loadAll() }
      }).catch(() => {})
    },
    // 批量重发（仅失败记录可选）
    batchRetry () {
      const ids = this.selection.filter(s => Number(s.send_status) === 3).map(s => s.id)
      if (!ids.length) { this.$message.warning('请选择失败的记录'); return }
      this.$confirm(`确认重新发送选中的 ${ids.length} 条消息？`, '批量重发', { type: 'warning' }).then(async () => {
        try {
          const r = await batchRetryNotificationLog(ids)
          if (r.code === 0) {
            this.retryResult = r.data || {}
            this.retryResultVisible = true
            this.loadAll()
          }
        } catch (e) {}
      }).catch(() => {})
    },
    // 导出
    async doExport () {
      this.exporting = true
      try {
        const params = {}
        if (this.filters.keyword) params.keyword = this.filters.keyword
        if (this.filters.msg_type) params.msg_type = this.filters.msg_type
        if (this.filters.channel) params.channel = this.filters.channel
        if (this.filters.send_status !== '' && this.filters.send_status !== null) params.send_status = this.filters.send_status
        if (this.filters.dateRange && this.filters.dateRange.length === 2) {
          params.start_date = this.filters.dateRange[0]
          params.end_date = this.filters.dateRange[1]
        }
        const r = await exportNotificationLog(params)
        if (r.code === 0 && r.data && r.data.url) window.open(r.data.url, '_blank')
        else this.$message.error('导出失败')
      } catch (e) {} finally { this.exporting = false }
    }
  }
}
</script>

<style scoped>
.log-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.stat-row { margin-bottom: 16px; }
.stat-card { background: #fff; border-radius: 8px; border-top: 3px solid #409EFF; padding: 14px; display: flex; align-items: center; box-shadow: 0 1px 4px rgba(0,0,0,.04); }
.stat-icon { width: 44px; height: 44px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 22px; margin-right: 12px; }
.stat-value { font-size: 24px; font-weight: 700; }
.stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.filter-card { margin-bottom: 16px; }
.list-card .toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; font-size: 13px; color: #606266; }
.pager { margin-top: 14px; text-align: right; }
.retry-summary { display: flex; gap: 12px; margin-bottom: 10px; }
.retry-detail { max-height: 260px; overflow-y: auto; }
.retry-fail { font-size: 13px; color: #F56C6C; padding: 3px 0; word-break: break-all; }
</style>
