<!-- 文件：admin/src/views/ai/workflow/logs.vue -->
<!-- 工作流运行日志（完整版）：统计卡片 / 多维筛选 / 表格 / 导出 / 删除 / 详情 / 统计图表 -->
<template>
  <div class="wf-logs">
    <!-- 统计卡片（6 个） -->
    <el-row :gutter="12" class="stat-row">
      <el-col :span="4">
        <div class="stat-card clickable" @click="quickFilter('all')">
          <div class="stat-icon" style="background:#409EFF1a;color:#409EFF;"><i class="el-icon-s-data"></i></div>
          <div class="stat-body"><div class="stat-value">{{ stats.total }}</div><div class="stat-label">总运行次数</div></div>
        </div>
      </el-col>
      <el-col :span="4">
        <div class="stat-card clickable" @click="quickFilter('success')">
          <div class="stat-icon" style="background:#67C23A1a;color:#67C23A;"><i class="el-icon-circle-check"></i></div>
          <div class="stat-body"><div class="stat-value">{{ stats.success }}</div><div class="stat-label">成功次数</div></div>
        </div>
      </el-col>
      <el-col :span="4">
        <div class="stat-card clickable" @click="quickFilter('failed')">
          <div class="stat-icon" style="background:#F56C6C1a;color:#F56C6C;"><i class="el-icon-circle-close"></i></div>
          <div class="stat-body"><div class="stat-value">{{ stats.failed }}</div><div class="stat-label">失败次数</div></div>
        </div>
      </el-col>
      <el-col :span="4">
        <div class="stat-card">
          <div class="stat-icon" style="background:#8E44AD1a;color:#8E44AD;"><i class="el-icon-percent"></i></div>
          <div class="stat-body"><div class="stat-value">{{ stats.rate }}%</div><div class="stat-label">成功率</div></div>
        </div>
      </el-col>
      <el-col :span="4">
        <div class="stat-card">
          <div class="stat-icon" style="background:#E6A23C1a;color:#E6A23C;"><i class="el-icon-timer"></i></div>
          <div class="stat-body"><div class="stat-value">{{ stats.avg_duration }}</div><div class="stat-label">平均耗时(ms)</div></div>
        </div>
      </el-col>
      <el-col :span="4">
        <div class="stat-card">
          <div class="stat-icon" style="background:#409EFF1a;color:#409EFF;"><i class="el-icon-date"></i></div>
          <div class="stat-body"><div class="stat-value">{{ stats.today }}</div><div class="stat-label">今日运行</div></div>
        </div>
      </el-col>
    </el-row>

    <!-- 筛选 -->
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item>
          <el-select v-model="filters.workflow_id" placeholder="全部工作流" clearable filterable style="width:180px" @change="onSearch">
            <el-option v-for="w in workflowOptions" :key="w.id" :label="w.workflow_name" :value="w.workflow_id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.trigger_source" placeholder="全部来源" clearable style="width:110px" @change="onSearch">
            <el-option label="手动" value="manual" />
            <el-option label="定时" value="schedule" />
            <el-option label="Webhook" value="webhook" />
            <el-option label="事件" value="event" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" placeholder="全部状态" clearable style="width:110px" @change="onSearch">
            <el-option label="运行中" value="running" />
            <el-option label="成功" value="success" />
            <el-option label="失败" value="failed" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.timeRange" placeholder="时间范围" clearable style="width:130px" @change="onTimeRangeChange">
            <el-option label="最近1小时" value="1h" />
            <el-option label="最近24小时" value="24h" />
            <el-option label="最近7天" value="7d" />
            <el-option label="最近30天" value="30d" />
            <el-option label="自定义" value="custom" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="filters.timeRange === 'custom'">
          <el-date-picker v-model="filters.dateRange" type="daterange" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期"
            value-format="yyyy-MM-dd" style="width:230px" @change="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.duration" placeholder="耗时范围" clearable style="width:110px" @change="onSearch">
            <el-option label=">1s" :value="1000" />
            <el-option label=">3s" :value="3000" />
            <el-option label=">5s" :value="5000" />
            <el-option label=">10s" :value="10000" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="搜索工作流名称" clearable style="width:180px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilter">重置</el-button>
          <el-button icon="el-icon-data-line" @click="openStats">统计分析</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 工具栏 -->
    <el-card shadow="never" class="list-card">
      <div class="toolbar">
        <span>共 <b>{{ total }}</b> 条日志<span v-if="selection.length" style="margin-left:12px;">已选 <b style="color:#409EFF;">{{ selection.length }}</b> 条</span></span>
        <div>
          <el-dropdown v-if="hasPerm('ai:workflow:logs:export')" @command="doExport" style="margin-right:8px;">
            <el-button size="small" icon="el-icon-download">导出<i class="el-icon-arrow-down el-icon--right"></i></el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item command="xlsx">导出 Excel(CSV)</el-dropdown-item>
              <el-dropdown-item command="json">导出 JSON</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
          <el-dropdown v-if="hasPerm('ai:workflow:logs:delete')" @command="doDeleteCmd" style="margin-right:8px;">
            <el-button size="small" type="danger" icon="el-icon-delete" :disabled="!selection.length">删除<i class="el-icon-arrow-down el-icon--right"></i></el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item command="selected" :disabled="!selection.length">删除选中</el-dropdown-item>
              <el-dropdown-item command="bytime">按时间删除</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
          <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadAll">刷新</el-button>
        </div>
      </div>

      <!-- 表格 -->
      <el-table :data="list" v-loading="loading" size="small" stripe @selection-change="s => (selection = s)">
        <el-table-column type="selection" width="40" />
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column label="日志ID" width="180" show-overflow-tooltip>
          <template slot-scope="{ row }">
            <el-button type="text" size="mini" @click="openDetail(row)">{{ row.log_id }}</el-button>
          </template>
        </el-table-column>
        <el-table-column prop="workflow_name" label="工作流名称" min-width="140" show-overflow-tooltip />
        <el-table-column label="触发来源" width="100" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="sourceTag(row.trigger_source)">{{ sourceText(row.trigger_source) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="trigger_user" label="触发人" width="80" show-overflow-tooltip>
          <template slot-scope="{ row }">{{ row.trigger_user || '-' }}</template>
        </el-table-column>
        <el-table-column prop="start_time" label="开始时间" width="160" />
        <el-table-column prop="end_time" label="结束时间" width="160">
          <template slot-scope="{ row }">{{ row.end_time || '-' }}</template>
        </el-table-column>
        <el-table-column label="耗时" width="100" align="center">
          <template slot-scope="{ row }">
            <span :style="{ background: (row.duration || 0) > 3000 ? '#FEF0F0' : 'transparent', padding: '2px 6px', borderRadius: '4px' }">{{ row.duration ?? '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="statusTag(row.status)">{{ statusText(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" align="center">
          <template slot-scope="{ row }">
            <el-button type="text" size="mini" @click="openDetail(row)">详情</el-button>
            <el-button v-if="hasPerm('ai:workflow:logs:delete')" type="text" size="mini" style="color:#F56C6C;" @click="doDeleteOne(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination class="pager" background layout="total, sizes, prev, pager, next" :total="total"
        :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]"
        @size-change="s => { limit = s; page = 1; loadAll() }"
        @current-change="p => { page = p; loadAll() }" />
    </el-card>

    <!-- 详情弹窗 -->
    <workflow-log-detail-dialog v-if="detailVisible" :visible.sync="detailVisible" :log-id="currentId" />

    <!-- 统计图表弹窗 -->
    <workflow-log-stats-dialog v-if="statsVisible" :visible.sync="statsVisible" />
  </div>
</template>

<script>
import {
  getWorkflowLogList, getWorkflowLogStatistics, getWorkflowOptions,
  exportWorkflowLogs, deleteWorkflowLog, batchDeleteWorkflowLogs
} from '@/api/aiWorkflow'
import WorkflowLogDetailDialog from './components/WorkflowLogDetailDialog.vue'
import WorkflowLogStatsDialog from './components/WorkflowLogStatsDialog.vue'

export default {
  name: 'AiWorkflowLogs',
  components: { WorkflowLogDetailDialog, WorkflowLogStatsDialog },
  data () {
    return {
      list: [], total: 0, page: 1, limit: 20, loading: false,
      selection: [], workflowOptions: [],
      stats: { total: 0, success: 0, failed: 0, rate: 0, avg_duration: 0, today: 0 },
      filters: { keyword: '', workflow_id: '', trigger_source: '', status: '', timeRange: '', dateRange: null, duration: '' },
      detailVisible: false, currentId: 0, statsVisible: false
    }
  },
  created () {
    this.loadWorkflowOptions()
    const wfId = this.$route.query.workflow_id
    if (wfId) this.filters.workflow_id = wfId
    this.loadAll(); this.loadStats()
  },
  methods: {
    hasPerm (code) {
      const u = this.$store.state.user.userInfo || {}
      const p = this.$store.state.user.permissions || []
      if (u.is_super_admin || p.indexOf('super_admin') > -1) return true
      return p.indexOf(code) > -1
    },
    async loadWorkflowOptions () {
      try { const r = await getWorkflowOptions(); if (r.code === 0) this.workflowOptions = r.data || [] } catch (e) {}
    },
    buildParams () {
      const p = { page: this.page, limit: this.limit }
      if (this.filters.keyword) p.keyword = this.filters.keyword
      if (this.filters.workflow_id) p.workflow_id = this.filters.workflow_id
      if (this.filters.trigger_source) p.trigger_source = this.filters.trigger_source
      if (this.filters.status) p.status = this.filters.status
      if (this.filters.duration) p.duration_min = this.filters.duration
      if (this.filters.timeRange === 'custom' && this.filters.dateRange && this.filters.dateRange.length === 2) {
        p.start_date = this.filters.dateRange[0]; p.end_date = this.filters.dateRange[1]
      } else if (this.filters.timeRange && this.filters.timeRange !== 'custom') {
        const now = new Date()
        if (this.filters.timeRange === '1h') { p.start_date = this.fmt(new Date(now.getTime() - 3600000)); p.end_date = this.fmt(now) }
        else if (this.filters.timeRange === '24h') { p.start_date = this.fmt(new Date(now.getTime() - 86400000)); p.end_date = this.fmt(now) }
        else if (this.filters.timeRange === '7d') { p.start_date = this.fmt(new Date(now.getTime() - 7 * 86400000)); p.end_date = this.fmt(now) }
        else if (this.filters.timeRange === '30d') { p.start_date = this.fmt(new Date(now.getTime() - 30 * 86400000)); p.end_date = this.fmt(now) }
      }
      return p
    },
    fmt (d) { return d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0') },
    async loadAll () {
      this.loading = true
      try { const r = await getWorkflowLogList(this.buildParams()); if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 } } catch (e) {} finally { this.loading = false }
    },
    async loadStats () {
      try { const r = await getWorkflowLogStatistics(); if (r.code === 0) this.stats = r.data || this.stats } catch (e) {}
    },
    onSearch () { this.page = 1; this.loadAll() },
    onTimeRangeChange () { if (this.filters.timeRange !== 'custom') this.onSearch() },
    resetFilter () {
      this.filters = { keyword: '', workflow_id: '', trigger_source: '', status: '', timeRange: '', dateRange: null, duration: '' }
      this.page = 1; this.loadAll()
    },
    quickFilter (key) {
      this.filters.status = key === 'all' ? '' : key
      this.page = 1; this.loadAll()
    },
    openDetail (row) { this.currentId = row.id; this.detailVisible = true },
    openStats () { this.statsVisible = true },
    // 导出
    async doExport (format) {
      const p = this.buildParams()
      delete p.page; delete p.limit
      try {
        const resp = await exportWorkflowLogs({ ...p, format })
        const blob = resp.data instanceof Blob ? resp.data : new Blob([resp.data])
        const url = window.URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = 'workflow_logs_' + new Date().toISOString().slice(0, 10).replace(/-/g, '') + (format === 'json' ? '.json' : '.csv')
        document.body.appendChild(a); a.click(); document.body.removeChild(a)
        window.URL.revokeObjectURL(url)
      } catch (e) {}
    },
    // 删除
    doDeleteOne (row) {
      this.$confirm(`确定删除日志 [${row.log_id}] 吗？`, '删除确认', { type: 'warning' }).then(async () => {
        try { const r = await deleteWorkflowLog(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadAll(); this.loadStats() } } catch (e) {}
      }).catch(() => {})
    },
    doDeleteCmd (cmd) {
      if (cmd === 'selected') {
        if (!this.selection.length) return
        const ids = this.selection.map(s => s.id)
        this.$confirm(`确定删除选中的 ${ids.length} 条日志吗？`, '批量删除', { type: 'warning' }).then(async () => {
          try { const r = await batchDeleteWorkflowLogs({ ids }); if (r.code === 0) { this.$message.success('已删除 ' + (r.data.deleted || 0) + ' 条'); this.loadAll(); this.loadStats() } } catch (e) {}
        }).catch(() => {})
      } else if (cmd === 'bytime') {
        this.$prompt('输入开始日期（YYYY-MM-DD），删除该日期之前的日志', '按时间删除', { inputPlaceholder: '如 2026-06-01' }).then(async ({ value }) => {
          if (!value) return
          this.$confirm(`确定删除 ${value} 之前的全部日志吗？此操作不可恢复`, '确认', { type: 'warning' }).then(async () => {
            try {
              const r = await batchDeleteWorkflowLogs({ start_date: '2000-01-01', end_date: value })
              if (r.code === 0) { this.$message.success('已删除 ' + (r.data.deleted || 0) + ' 条'); this.loadAll(); this.loadStats() }
            } catch (e) {}
          }).catch(() => {})
        }).catch(() => {})
      }
    },
    sourceText (s) { return { manual: '手动', schedule: '定时', webhook: 'Webhook', event: '事件' }[s] || s || '-' },
    sourceTag (s) { return { manual: 'primary', schedule: 'success', webhook: 'warning', event: 'danger' }[s] || 'info' },
    statusText (s) { return { running: '运行中', success: '成功', failed: '失败' }[s] || s },
    statusTag (s) { return { running: 'primary', success: 'success', failed: 'danger' }[s] || 'info' }
  }
}
</script>

<style scoped>
.wf-logs { padding: 16px; }
.stat-row { margin-bottom: 14px; }
.stat-card { display: flex; align-items: center; background: #fff; border-radius: 8px; padding: 12px; box-shadow: 0 1px 3px rgba(0,0,0,.05); }
.stat-card.clickable { cursor: pointer; }
.stat-card.clickable:hover { box-shadow: 0 2px 8px rgba(0,0,0,.08); }
.stat-icon { width: 40px; height: 40px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 20px; margin-right: 10px; }
.stat-value { font-size: 18px; font-weight: 700; color: #303133; line-height: 1.2; }
.stat-label { font-size: 12px; color: #909399; margin-top: 2px; }
.filter-card { margin-bottom: 14px; }
.filter-card /deep/ .el-card__body { padding: 12px 16px 0; }
.list-card /deep/ .el-card__body { padding: 12px 16px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.toolbar span { font-size: 13px; color: #606266; }
.pager { margin-top: 14px; text-align: right; }
</style>
