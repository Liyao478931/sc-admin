<!-- 文件：admin/src/views/ai/tools/logs.vue -->
<template>
  <div class="page">
    <!-- 统计卡片（5个） -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="4" v-for="card in statCards" :key="card.key">
        <div class="stat-card" :class="card.cls" @click="card.onClick && card.onClick()">
          <i :class="card.icon" class="stat-icon"></i>
          <div class="stat-info">
            <div class="stat-num">{{ card.value }}</div>
            <div class="stat-label">{{ card.label }}</div>
          </div>
        </div>
      </el-col>
    </el-row>

    <el-card shadow="never" class="sec-card">
      <!-- 筛选区域 -->
      <el-form inline size="small" class="filter-form">
        <el-form-item>
          <el-select v-model="filters.tool_id" placeholder="全部工具" clearable filterable style="width:140px" @change="handleSearch">
            <el-option v-for="t in toolOptions" :key="t.id" :label="t.tool_display_name || t.tool_name" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.user_id" placeholder="全部用户" clearable filterable style="width:130px" @change="handleSearch">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" placeholder="全部状态" clearable style="width:110px" @change="handleSearch">
            <el-option label="成功" value="success" />
            <el-option label="失败" value="error" />
            <el-option label="超时" value="timeout" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.method" placeholder="全部方法" clearable style="width:110px" @change="handleSearch">
            <el-option v-for="m in ['GET', 'POST', 'PUT', 'DELETE']" :key="m" :label="m" :value="m" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.time_range" placeholder="时间范围" clearable style="width:130px" @change="handleTimeRange">
            <el-option label="最近1小时" value="1h" />
            <el-option label="最近24小时" value="24h" />
            <el-option label="最近7天" value="7d" />
            <el-option label="最近30天" value="30d" />
            <el-option label="自定义" value="custom" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="filters.time_range === 'custom'">
          <el-date-picker v-model="customDate" type="daterange" range-separator="至" start-placeholder="开始日期"
            end-placeholder="结束日期" value-format="yyyy-MM-dd" style="width:240px" @change="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.duration_min" placeholder="耗时范围" clearable style="width:110px" @change="handleSearch">
            <el-option label=">1s" value="1000" />
            <el-option label=">3s" value="3000" />
            <el-option label=">5s" value="5000" />
            <el-option label=">10s" value="10000" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-input v-model="filters.session_id" placeholder="会话ID" clearable style="width:150px"
            @keyup.enter.native="handleSearch" @clear="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="搜索工具名称或API路径" clearable style="width:180px"
            @keyup.enter.native="handleSearch" @clear="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
          <el-button icon="el-icon-data-analysis" @click="openCharts">统计图表</el-button>
        </el-form-item>
      </el-form>

      <!-- 工具栏 -->
      <div class="toolbar">
        <span class="toolbar-tip">共 {{ total }} 条日志</span>
        <div class="toolbar-right">
          <el-dropdown trigger="click" @command="handleExport">
            <el-button size="small" icon="el-icon-download">导出</el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item command="xlsx">导出Excel</el-dropdown-item>
              <el-dropdown-item command="json">导出JSON</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
          <el-button size="small" icon="el-icon-refresh" @click="loadAll">刷新</el-button>
          <el-dropdown trigger="click" @command="handleDeleteCmd">
            <el-button size="small" type="danger" icon="el-icon-delete" :disabled="!selection.length">删除</el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item command="selected" :disabled="!selection.length">删除选中（{{ selection.length }}）</el-dropdown-item>
              <el-dropdown-item command="range">按时间删除</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
        </div>
      </div>

      <!-- 表格 -->
      <el-table :data="logs" size="small" stripe v-loading="loading" @selection-change="s => selection = s">
        <el-table-column type="selection" width="40" />
        <el-table-column type="index" label="序号" width="60" />
        <el-table-column label="日志ID" width="180">
          <template slot-scope="s">
            <el-link type="primary" :underline="false" @click="openDetail(s.row)">{{ s.row.log_id }}</el-link>
          </template>
        </el-table-column>
        <el-table-column label="工具名称" width="120">
          <template slot-scope="s">
            <el-link type="primary" :underline="false" @click="goToolList(s.row)">{{ s.row.tool_name || '-' }}</el-link>
          </template>
        </el-table-column>
        <el-table-column prop="user_name" label="调用人" width="80" show-overflow-tooltip />
        <el-table-column prop="create_time" label="调用时间" width="160" />
        <el-table-column label="请求方法" width="90" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="methodTag(s.row.method)">{{ s.row.method }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="api_path" label="API路径" min-width="200" show-overflow-tooltip />
        <el-table-column label="状态码" width="80" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="statusCodeTagType(s.row.response_status)">{{ s.row.response_status || '-' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="耗时(ms)" width="100" align="center">
          <template slot-scope="s">
            <span :class="{ 'slow-request': s.row.duration > 3000 }">{{ s.row.duration || 0 }}</span>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="logStatusTagType(s.row.status)">{{ logStatusText(s.row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" align="center">
          <template slot-scope="s">
            <el-button size="mini" type="primary" @click="openDetail(s.row)">详情</el-button>
            <el-button size="mini" type="danger" @click="removeLog(s.row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pager">
        <el-pagination background layout="total, sizes, prev, pager, next" :total="total"
          :page-size="limit" :page-sizes="[10, 20, 50, 100]" :current-page="page"
          @size-change="p => { limit = p; page = 1; loadList() }"
          @current-change="p => { page = p; loadList() }" />
      </div>
    </el-card>

    <!-- 调用日志详情弹窗 -->
    <el-dialog title="调用日志详情" :visible.sync="detailVisible" width="900px" top="5vh">
      <el-tabs v-model="detailTab" v-if="detail">
        <!-- 基本信息 -->
        <el-tab-pane label="基本信息" name="info">
          <el-descriptions :column="2" size="small" border>
            <el-descriptions-item label="日志ID">{{ detail.log_id }}</el-descriptions-item>
            <el-descriptions-item label="工具名称">{{ detail.tool_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="调用人">{{ detail.user_name || '-' }}</el-descriptions-item>
            <el-descriptions-item label="调用时间">{{ detail.create_time || '-' }}</el-descriptions-item>
            <el-descriptions-item label="会话ID">{{ detail.session_id || '-' }}</el-descriptions-item>
            <el-descriptions-item label="来源">{{ sourceText(detail.source) }}</el-descriptions-item>
            <el-descriptions-item label="状态">
              <el-tag size="mini" :type="logStatusTagType(detail.status)">{{ logStatusText(detail.status) }}</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="状态码">{{ detail.response_status || '-' }}</el-descriptions-item>
            <el-descriptions-item label="耗时">{{ detail.duration || 0 }}ms</el-descriptions-item>
            <el-descriptions-item label="请求大小">{{ formatSize(detail.request_size) }}</el-descriptions-item>
            <el-descriptions-item label="响应大小">{{ formatSize(detail.response_size) }}</el-descriptions-item>
            <el-descriptions-item label="更新时间">{{ detail.update_time || '-' }}</el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>
        <!-- 请求信息 -->
        <el-tab-pane label="请求信息" name="request">
          <div class="detail-json">
            <div class="json-label">请求方法：
              <el-tag size="mini" :type="methodTag(detail.method)">{{ detail.method }}</el-tag>
            </div>
          </div>
          <div class="detail-json">
            <div class="json-label">API路径</div>
            <pre class="json-body">{{ detail.api_path }}</pre>
          </div>
          <div class="detail-json">
            <div class="json-label">请求头 <el-button size="mini" type="text" @click="copyJson(detail.request_headers)">复制</el-button></div>
            <pre class="json-body">{{ formatJson(detail.request_headers) }}</pre>
          </div>
          <div class="detail-json">
            <div class="json-label">请求参数 <el-button size="mini" type="text" @click="copyJson(detail.request_params)">复制</el-button></div>
            <pre class="json-body">{{ formatJson(detail.request_params) }}</pre>
          </div>
        </el-tab-pane>
        <!-- 响应信息 -->
        <el-tab-pane label="响应信息" name="response">
          <div class="detail-json">
            <div class="json-label">状态码：
              <el-tag size="mini" :type="statusCodeTagType(detail.response_status)">{{ detail.response_status || '-' }}</el-tag>
            </div>
          </div>
          <div class="detail-json">
            <div class="json-label">响应头 <el-button size="mini" type="text" @click="copyJson(detail.response_headers)">复制</el-button></div>
            <pre class="json-body">{{ formatJson(detail.response_headers) }}</pre>
          </div>
          <div class="detail-json">
            <div class="json-label">
              响应体 <el-button size="mini" type="text" @click="copyJson(detail.response_body)">复制</el-button>
              <el-input v-model="hlKeyword" placeholder="输入关键词高亮搜索" clearable size="mini"
                style="width:220px;margin-left:12px;" @clear="hlKeyword = ''" />
            </div>
            <pre class="json-body response-body" v-html="renderedResponseBody().html"></pre>
            <div v-if="renderedResponseBody().truncated" class="truncate-tip">响应体过大，已截断显示前 200000 字符</div>
          </div>
        </el-tab-pane>
        <!-- 错误信息 -->
        <el-tab-pane label="错误信息" name="error">
          <div v-if="detail.error_message" class="detail-json">
            <div class="json-label">错误信息 <el-button size="mini" type="text" @click="copyText(detail.error_message)">复制</el-button></div>
            <pre class="json-body error-body">{{ detail.error_message }}</pre>
          </div>
          <div v-else class="no-error">无错误信息</div>
        </el-tab-pane>
      </el-tabs>
    </el-dialog>

    <!-- 日志统计分析弹窗 -->
    <el-dialog title="日志统计分析" :visible.sync="chartsVisible" width="1000px" top="5vh" @closed="onChartsClosed">
      <div class="chart-toolbar">
        <el-radio-group v-model="chartRange" size="small" @change="reloadCharts">
          <el-radio-button label="today">今日</el-radio-button>
          <el-radio-button label="week">本周</el-radio-button>
          <el-radio-button label="month">本月</el-radio-button>
        </el-radio-group>
        <div class="chart-toolbar-right">
          <el-button size="small" icon="el-icon-picture-outline" :loading="chartLoading" @click="exportChart('trend', '调用趋势')">导出趋势图</el-button>
          <el-button size="small" icon="el-icon-picture-outline" :loading="chartLoading" @click="exportChart('dist', '状态分布')">导出分布图</el-button>
          <el-button size="small" icon="el-icon-picture-outline" :loading="chartLoading" @click="exportChart('rank', '工具排行')">导出排行图</el-button>
        </div>
      </div>
      <div v-loading="chartLoading">
        <div class="chart-title">调用趋势图（{{ chartRangeText }}）</div>
        <div ref="trendChart" class="chart-box"></div>
        <div class="chart-row">
          <div class="chart-col">
            <div class="chart-title">状态分布图</div>
            <div ref="distChart" class="chart-box"></div>
          </div>
          <div class="chart-col">
            <div class="chart-title">工具调用排行 TOP10</div>
            <div ref="rankChart" class="chart-box"></div>
          </div>
        </div>
      </div>
    </el-dialog>

    <!-- 按时间删除弹窗 -->
    <el-dialog title="按时间删除日志" :visible.sync="delRangeVisible" width="480px" top="20vh">
      <el-form size="small" label-width="90px">
        <el-form-item label="删除范围">
          <el-date-picker v-model="delDateRange" type="daterange" range-separator="至" start-placeholder="开始日期"
            end-placeholder="结束日期" value-format="yyyy-MM-dd" style="width:100%" />
        </el-form-item>
      </el-form>
      <div class="del-tip">将删除该时间范围内所有日志（软删除），删除后可在数据库中恢复。请谨慎操作。</div>
      <span slot="footer">
        <el-button size="small" @click="delRangeVisible = false">取消</el-button>
        <el-button size="small" type="danger" :loading="deleting" @click="doDeleteByTime">确认删除</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  getAiToolLogs, getAiToolLogDetail, getAiToolLogStats, getAiToolLogTrend,
  getAiToolLogStatusDist, deleteAiToolLog, batchDeleteAiToolLog, exportAiToolLogs
} from '@/api/aiToolLog'
import { getAiToolList } from '@/api/aiTool'
import { getUserList } from '@/api/user'
import * as echarts from 'echarts'

export default {
  name: 'AiToolLogs',
  data () {
    return {
      stats: { total_calls: 0, success_count: 0, error_count: 0, timeout_count: 0, success_rate: 0, avg_duration: 0, top_tools: [] },
      filters: { tool_id: '', user_id: '', status: '', method: '', time_range: '', duration_min: '', keyword: '', session_id: '' },
      customDate: [],
      toolOptions: [], userOptions: [],
      logs: [], total: 0, page: 1, limit: 20, loading: false,
      selection: [],
      detailVisible: false, detailTab: 'info', detail: null, hlKeyword: '',
      chartsVisible: false, chartRange: 'today', chartLoading: false, chartInstances: {},
      trendData: [], distData: [], topTools: [],
      delRangeVisible: false, delDateRange: [], deleting: false
    }
  },
  computed: {
    statCards () {
      const s = this.stats
      return [
        { key: 'total', label: '总调用次数', value: s.total_calls || 0, icon: 'el-icon-s-data', cls: 'stat-blue' },
        { key: 'success', label: '成功次数', value: s.success_count || 0, icon: 'el-icon-circle-check', cls: 'stat-green', onClick: () => this.quickFilter('success') },
        { key: 'error', label: '失败次数', value: s.error_count || 0, icon: 'el-icon-circle-close', cls: 'stat-red', onClick: () => this.quickFilter('error') },
        { key: 'rate', label: '成功率', value: (s.success_rate || 0) + '%', icon: 'el-icon-percent', cls: 'stat-purple' },
        { key: 'avg', label: '平均耗时(ms)', value: s.avg_duration || 0, icon: 'el-icon-timer', cls: 'stat-orange' }
      ]
    },
    chartRangeText () {
      return { today: '今日', week: '本周', month: '本月' }[this.chartRange] || '今日'
    }
  },
  created () {
    this.loadOptions()
    this.loadStats()
    this.loadList()
  },
  methods: {
    // ==================== 基础展示辅助 ====================
    methodTag (m) {
      return { GET: 'primary', POST: 'success', PUT: 'warning', DELETE: 'danger' }[m] || 'info'
    },
    logStatusText (s) {
      return { success: '成功', error: '失败', timeout: '超时' }[s] || s || '-'
    },
    logStatusTagType (s) {
      return { success: 'success', error: 'danger', timeout: 'warning' }[s] || 'info'
    },
    statusCodeTagType (code) {
      const c = parseInt(code, 10)
      if (isNaN(c)) return 'info'
      if (c >= 200 && c < 300) return 'success'
      if (c >= 300 && c < 400) return 'primary'
      if (c >= 400 && c < 500) return 'warning'
      if (c >= 500) return 'danger'
      return 'info'
    },
    sourceText (s) {
      return { chat: '对话调用', test: '工具测试', workflow: '工作流调用' }[s] || s || '-'
    },
    formatSize (bytes) {
      const b = parseInt(bytes, 10)
      if (isNaN(b) || b <= 0) return '0 B'
      if (b < 1024) return b + ' B'
      if (b < 1024 * 1024) return (b / 1024).toFixed(1) + ' KB'
      return (b / 1024 / 1024).toFixed(2) + ' MB'
    },
    formatJson (obj) {
      if (obj === null || obj === undefined || obj === '') return '(空)'
      if (typeof obj === 'string') { try { return JSON.stringify(JSON.parse(obj), null, 2) } catch (e) { return obj } }
      try { return JSON.stringify(obj, null, 2) } catch (e) { return String(obj) }
    },
    formatBody (body) {
      if (body === null || body === undefined || body === '') return '(无响应体)'
      if (typeof body === 'string') { try { return JSON.stringify(JSON.parse(body), null, 2) } catch (e) { return body } }
      try { return JSON.stringify(body, null, 2) } catch (e) { return String(body) }
    },
    escapeHtml (s) {
      return String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')
    },
    copyJson (obj) { this.copyText(this.formatJson(obj)) },
    copyText (text) {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(String(text)).then(() => this.$message.success('已复制'))
      } else {
        const ta = document.createElement('textarea')
        ta.value = String(text)
        document.body.appendChild(ta); ta.select(); document.execCommand('copy'); document.body.removeChild(ta)
        this.$message.success('已复制')
      }
    },
    // ==================== 数据加载 ====================
    async loadOptions () {
      try {
        const [tr, ur] = await Promise.all([
          getAiToolList({ page: 1, limit: 999 }),
          getUserList({ page: 1, limit: 999 })
        ])
        if (tr.code === 0) this.toolOptions = tr.data.list || []
        if (ur.code === 0) this.userOptions = ur.data.list || []
      } catch (e) {}
    },
    async loadStats () {
      try {
        const r = await getAiToolLogStats()
        if (r.code === 0) this.stats = Object.assign(this.stats, r.data || {})
      } catch (e) {}
    },
    buildParams () {
      const t = this.applyTimeRange()
      return {
        page: this.page, limit: this.limit,
        keyword: this.filters.keyword || undefined,
        tool_id: this.filters.tool_id || undefined,
        user_id: this.filters.user_id || undefined,
        status: this.filters.status || undefined,
        method: this.filters.method || undefined,
        session_id: this.filters.session_id || undefined,
        duration_min: this.filters.duration_min || undefined,
        ...(t || {})
      }
    },
    applyTimeRange () {
      const fmt = d => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
      const fmtTime = d => `${fmt(d)} ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}:${String(d.getSeconds()).padStart(2, '0')}`
      const now = new Date()
      const hoursAgo = n => { const d = new Date(now.getTime() - n * 3600 * 1000); return fmtTime(d) }
      const daysAgo = n => { const d = new Date(now.getTime() - n * 86400 * 1000); return fmtTime(d) }
      switch (this.filters.time_range) {
        case '1h': return { start_date: hoursAgo(1), end_date: fmtTime(now) } // 小时级精确
        case '24h': return { start_date: hoursAgo(24), end_date: fmtTime(now) }
        case '7d': return { start_date: fmt(daysAgo(6)), end_date: fmt(now) }
        case '30d': return { start_date: fmt(daysAgo(29)), end_date: fmt(now) }
        case 'custom': return (this.customDate && this.customDate.length === 2)
          ? { start_date: this.customDate[0], end_date: this.customDate[1] }
          : null
        default: return null
      }
    },
    async loadList () {
      this.loading = true
      try {
        const r = await getAiToolLogs(this.buildParams())
        if (r.code === 0) {
          this.logs = r.data.list || []
          this.total = r.data.total || 0
        }
      } catch (e) {} finally { this.loading = false }
    },
    loadAll () { this.page = 1; this.loadList(); this.loadStats() },
    handleSearch () { this.page = 1; this.loadList() },
    handleReset () {
      this.filters = { tool_id: '', user_id: '', status: '', method: '', time_range: '', duration_min: '', keyword: '', session_id: '' }
      this.customDate = []
      this.handleSearch()
    },
    handleTimeRange (val) {
      if (val !== 'custom') this.customDate = []
      this.handleSearch()
    },
    quickFilter (status) { this.filters.status = status; this.handleSearch() },
    // ==================== 详情 ====================
    async openDetail (row) {
      try {
        const r = await getAiToolLogDetail(row.id)
        if (r.code === 0) {
          this.detail = r.data
          this.detailTab = 'info'
          this.hlKeyword = ''
          this.detailVisible = true
        }
      } catch (e) {}
    },
    goToolList (row) {
      // 跳转到工具列表页（工具详情为列表页内弹窗）
      this.$router.push({ path: '/ai/tools/list', query: row.tool_id ? { tool_id: row.tool_id } : {} })
    },
    renderedResponseBody () {
      const body = this.detail ? this.detail.response_body : ''
      let text = this.formatBody(body)
      const max = 200000
      let truncated = false
      if (text.length > max) { text = text.slice(0, max); truncated = true }
      const kw = (this.hlKeyword || '').trim()
      let html = this.escapeHtml(text)
      if (kw) {
        const escKw = kw.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
        html = html.replace(new RegExp(escKw, 'gi'), m => `<span class="hl">${m}</span>`)
      }
      return { html, truncated }
    },
    // ==================== 导出 ====================
    async handleExport (cmd) {
      const format = cmd === 'xlsx' ? 'xlsx' : 'json'
      if (this.total > 10000) {
        const c = await this.$confirm(
          `当前筛选共 ${this.total} 条日志，超过10000条，建议缩小时间范围分批导出。仍要继续导出全部吗？`,
          '导出确认', { type: 'warning' }
        ).catch(() => false)
        if (!c) return
      }
      const d = new Date()
      const ymd = `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}`
      try {
        const blob = await exportAiToolLogs(this.buildParams(), format)
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = format === 'json' ? `调用日志_${ymd}.json` : `调用日志_${ymd}.xlsx`
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
      } catch (e) {
        this.$message.error('导出失败')
      }
    },
    // ==================== 删除 ====================
    async removeLog (row) {
      const c = await this.$confirm(`确定删除该条日志（${row.log_id}）吗？`, '删除确认', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const r = await deleteAiToolLog(row.id)
        if (r.code === 0) { this.$message.success(r.msg || '已删除'); this.loadAll() }
      } catch (e) {}
    },
    async handleDeleteCmd (cmd) {
      if (cmd === 'range') {
        this.delDateRange = []
        this.delRangeVisible = true
        return
      }
      if (!this.selection.length) return
      const c = await this.$confirm(`确定删除选中的 ${this.selection.length} 条日志吗？`, '批量删除', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const ids = this.selection.map(s => s.id)
        const r = await batchDeleteAiToolLog({ ids })
        if (r.code === 0) { this.$message.success(r.msg || '删除完成'); this.loadAll() }
      } catch (e) {}
    },
    async doDeleteByTime () {
      if (!this.delDateRange || this.delDateRange.length !== 2) { this.$message.warning('请选择日期范围'); return }
      const c = await this.$confirm(
        `确定删除 ${this.delDateRange[0]} 至 ${this.delDateRange[1]} 范围内所有日志吗？删除后不可恢复`,
        '按时间删除', { type: 'warning' }
      ).catch(() => false)
      if (!c) return
      this.deleting = true
      try {
        const r = await batchDeleteAiToolLog({ start_date: this.delDateRange[0], end_date: this.delDateRange[1] })
        if (r.code === 0) {
          this.$message.success(r.msg || '删除完成')
          this.delRangeVisible = false
          this.loadAll()
        }
      } catch (e) {} finally { this.deleting = false }
    },
    // ==================== 统计分析图表 ====================
    async openCharts () {
      this.chartsVisible = true
      this.chartLoading = true
      try {
        await this.reloadCharts()
      } catch (e) {} finally { this.chartLoading = false }
    },
    async reloadCharts () {
      this.chartLoading = true
      try {
        const t = this.chartRangeMap()
        const [tr, dr, st] = await Promise.all([
          getAiToolLogTrend({ range: this.chartRange, start_date: t.start_date, end_date: t.end_date }),
          getAiToolLogStatusDist({ start_date: t.start_date, end_date: t.end_date }),
          getAiToolLogStats({ start_date: t.start_date, end_date: t.end_date })
        ])
        if (tr.code === 0) this.trendData = tr.data.trend || []
        if (dr.code === 0) this.distData = dr.data || []
        if (st.code === 0) this.topTools = (st.data && st.data.top_tools) || []
        this.$nextTick(() => this.renderCharts())
      } finally { this.chartLoading = false }
    },
    chartRangeMap () {
      const fmt = d => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
      const today = new Date()
      const end = fmt(today)
      if (this.chartRange === 'today') return { start_date: end, end_date: end }
      if (this.chartRange === 'week') { const d = new Date(); d.setDate(d.getDate() - 6); return { start_date: fmt(d), end_date: end } }
      const d = new Date(today.getFullYear(), today.getMonth(), 1)
      return { start_date: fmt(d), end_date: end }
    },
    renderCharts () {
      this.renderTrend()
      this.renderDist()
      this.renderRank()
    },
    renderTrend () {
      const el = this.$refs.trendChart
      if (!el) return
      if (!this.chartInstances.trend) this.chartInstances.trend = echarts.init(el)
      const chart = this.chartInstances.trend
      chart.setOption({
        tooltip: { trigger: 'axis' },
        grid: { left: 44, right: 20, top: 30, bottom: 30 },
        xAxis: { type: 'category', data: this.trendData.map(x => x.date) },
        yAxis: { type: 'value', minInterval: 1 },
        series: [{
          name: '调用量', type: 'line', smooth: true,
          data: this.trendData.map(x => x.count),
          areaStyle: { opacity: 0.15 }, itemStyle: { color: '#409EFF' }
        }]
      })
    },
    renderDist () {
      const el = this.$refs.distChart
      if (!el) return
      if (!this.chartInstances.dist) this.chartInstances.dist = echarts.init(el)
      const chart = this.chartInstances.dist
      chart.setOption({
        tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
        legend: { bottom: 0 },
        series: [{
          type: 'pie', radius: ['40%', '68%'], center: ['50%', '45%'],
          data: this.distData.map(x => ({ name: x.name, value: x.value })),
          label: { formatter: '{b}: {c}' }
        }]
      })
    },
    renderRank () {
      const el = this.$refs.rankChart
      if (!el) return
      if (!this.chartInstances.rank) this.chartInstances.rank = echarts.init(el)
      const chart = this.chartInstances.rank
      chart.setOption({
        tooltip: { trigger: 'axis' },
        grid: { left: 44, right: 20, top: 30, bottom: 80 },
        xAxis: { type: 'category', data: this.topTools.map(x => x.tool_name), axisLabel: { rotate: 30, interval: 0 } },
        yAxis: { type: 'value', minInterval: 1 },
        series: [{
          type: 'bar', data: this.topTools.map(x => x.cnt),
          itemStyle: { color: '#67C23A' }, barMaxWidth: 28
        }]
      })
    },
    onChartsClosed () {
      Object.keys(this.chartInstances).forEach(k => { this.chartInstances[k].dispose(); delete this.chartInstances[k] })
    },
    exportChart (refKey, name) {
      const chart = this.chartInstances[refKey]
      if (!chart) { this.$message.warning('图表尚未生成'); return }
      const url = chart.getDataURL({ pixelRatio: 2, backgroundColor: '#fff' })
      const a = document.createElement('a')
      a.href = url
      a.download = `调用日志_${name}_${Date.now()}.png`
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
    }
  }
}
</script>

<style scoped>
.page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.sec-card { margin-bottom: 16px; }
.stat-row { margin-bottom: 16px; }
.stat-card { background: #fff; border-radius: 8px; padding: 16px; display: flex; align-items: center; box-shadow: 0 1px 4px rgba(0,0,0,0.06); cursor: pointer; transition: transform 0.15s; }
.stat-card:hover { transform: translateY(-2px); }
.stat-icon { font-size: 30px; margin-right: 12px; }
.stat-num { font-size: 20px; font-weight: 600; color: #303133; }
.stat-label { font-size: 12px; color: #909399; }
.stat-blue .stat-icon { color: #409EFF; }
.stat-green .stat-icon { color: #67C23A; }
.stat-red .stat-icon { color: #F56C6C; }
.stat-purple .stat-icon { color: #9B59B6; }
.stat-orange .stat-icon { color: #E6A23C; }
.filter-form { margin-bottom: 8px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.toolbar-tip { font-size: 13px; color: #909399; }
.pager { margin-top: 12px; text-align: right; }
/* 慢请求（>3s）黄色背景标识 */
.slow-request { display: inline-block; background: #fdf6ec; color: #E6A23C; font-weight: 600; padding: 0 6px; border-radius: 3px; }
.detail-json { margin-top: 12px; }
.json-label { font-size: 13px; font-weight: 600; color: #909399; margin-bottom: 4px; }
.json-body { background: #f8f9fb; border-radius: 6px; padding: 10px; font-size: 12px; overflow-x: auto; max-height: 320px; white-space: pre-wrap; word-break: break-all; }
.response-body { max-height: 360px; }
.error-body { color: #F56C6C; background: #fef0f0; white-space: pre-wrap; }
.no-error { color: #909399; font-size: 13px; padding: 12px 4px; }
.truncate-tip { color: #E6A23C; font-size: 12px; margin-top: 4px; }
.hl { background: #ffd04b; color: #303133; font-weight: 600; border-radius: 2px; padding: 0 1px; }
.chart-toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px; }
.chart-title { font-size: 14px; font-weight: 600; color: #303133; margin: 12px 0 6px; }
.chart-box { width: 100%; height: 300px; }
.chart-row { display: flex; gap: 16px; }
.chart-col { flex: 1; min-width: 0; }
.del-tip { color: #E6A23C; font-size: 12px; line-height: 1.6; }
</style>
