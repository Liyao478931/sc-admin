<!-- 文件：admin/src/views/ai/operation/audit.vue -->
<!-- 操作审计：统计卡片 / 多维筛选 / 表格 / 导出删除 / 详情(4Tab) / 统计图表 -->
<template>
  <div class="audit-page">
    <!-- 统计卡片（4 个） -->
    <el-row :gutter="12" class="stat-row">
      <el-col :span="6"><div class="stat-card"><div class="stat-icon" style="background:#409EFF1a;color:#409EFF;"><i class="el-icon-document"></i></div><div class="stat-body"><div class="stat-value">{{ stats.total }}</div><div class="stat-label">总操作数</div></div></div></el-col>
      <el-col :span="6"><div class="stat-card"><div class="stat-icon" style="background:#67C23A1a;color:#67C23A;"><i class="el-icon-date"></i></div><div class="stat-body"><div class="stat-value">{{ stats.today }}</div><div class="stat-label">今日操作</div></div></div></el-col>
      <el-col :span="6"><div class="stat-card"><div class="stat-icon" style="background:#E6A23C1a;color:#E6A23C;"><i class="el-icon-calendar"></i></div><div class="stat-body"><div class="stat-value">{{ stats.week }}</div><div class="stat-label">本周操作</div></div></div></el-col>
      <el-col :span="6"><div class="stat-card"><div class="stat-icon" style="background:#8E44AD1a;color:#8E44AD;"><i class="el-icon-data-line"></i></div><div class="stat-body"><div class="stat-value">{{ stats.month }}</div><div class="stat-label">本月操作</div></div></div></el-col>
    </el-row>

    <!-- 筛选 -->
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item><el-input v-model="filters.keyword" placeholder="操作人或内容" clearable style="width:180px" @keyup.enter.native="onSearch" @clear="onSearch" /></el-form-item>
        <el-form-item><el-select v-model="filters.module" placeholder="全部模块" clearable style="width:120px" @change="onSearch"><el-option v-for="(t, k) in MODULE_TEXT" :key="k" :label="t" :value="k" /></el-select></el-form-item>
        <el-form-item><el-select v-model="filters.action" placeholder="全部类型" clearable style="width:110px" @change="onSearch"><el-option v-for="(t, k) in ACTION_TEXT" :key="k" :label="t" :value="k" /></el-select></el-form-item>
        <el-form-item><el-select v-model="filters.result" placeholder="全部结果" clearable style="width:100px" @change="onSearch"><el-option v-for="opt in resultOptions" :key="opt.value" :label="opt.label" :value="opt.value" /></el-select></el-form-item>
        <el-form-item><el-input v-model="filters.ip" placeholder="IP地址" clearable style="width:140px" @change="onSearch" /></el-form-item>
        <el-form-item><el-input v-model="filters.resource_id" placeholder="资源ID" clearable style="width:140px" @change="onSearch" /></el-form-item>
        <el-form-item>
          <el-select v-model="filters.timeRange" placeholder="时间范围" clearable style="width:130px" @change="onTimeRangeChange">
            <el-option label="最近1小时" value="1h" /><el-option label="最近24小时" value="24h" />
            <el-option label="最近7天" value="7d" /><el-option label="最近30天" value="30d" /><el-option label="自定义" value="custom" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="filters.timeRange === 'custom'">
          <el-date-picker v-model="filters.dateRange" type="daterange" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" value-format="yyyy-MM-dd" style="width:230px" @change="onSearch" />
        </el-form-item>
        <el-form-item><el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button><el-button icon="el-icon-refresh-left" @click="resetFilter">重置</el-button><el-button icon="el-icon-data-line" @click="openStats">统计分析</el-button></el-form-item>
      </el-form>
    </el-card>

    <!-- 工具栏 -->
    <el-card shadow="never" class="list-card">
      <div class="toolbar">
        <span>共 <b>{{ total }}</b> 条日志<span v-if="selection.length" style="margin-left:12px;">已选 {{ selection.length }} 条</span></span>
        <div>
          <el-dropdown v-if="hasPerm('ai:operation:audit:export')" @command="doExport" style="margin-right:8px;">
            <el-button size="small" icon="el-icon-download">导出<i class="el-icon-arrow-down el-icon--right"></i></el-button>
            <el-dropdown-menu slot="dropdown"><el-dropdown-item command="xlsx">导出 Excel(CSV)</el-dropdown-item><el-dropdown-item command="json">导出 JSON</el-dropdown-item></el-dropdown-menu>
          </el-dropdown>
          <el-dropdown v-if="hasPerm('ai:operation:audit:delete')" @command="doDeleteCmd" style="margin-right:8px;">
            <el-button size="small" type="danger" icon="el-icon-delete" :disabled="!selection.length">删除<i class="el-icon-arrow-down el-icon--right"></i></el-button>
            <el-dropdown-menu slot="dropdown"><el-dropdown-item command="selected" :disabled="!selection.length">删除选中</el-dropdown-item><el-dropdown-item command="bytime">按时间删除</el-dropdown-item></el-dropdown-menu>
          </el-dropdown>
          <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadAll">刷新</el-button>
        </div>
      </div>

      <!-- 表格 -->
      <el-table :data="list" v-loading="loading" size="small" stripe @selection-change="s => (selection = s)">
        <el-table-column type="selection" width="40" />
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column label="日志ID" width="180" show-overflow-tooltip>
          <template slot-scope="{ row }"><el-button type="text" size="mini" @click="openDetail(row)">{{ row.log_id }}</el-button></template>
        </el-table-column>
        <el-table-column prop="user_name" label="操作人" width="80" show-overflow-tooltip>
          <template slot-scope="{ row }">{{ row.user_name || '-' }}</template>
        </el-table-column>
        <el-table-column prop="create_time" label="操作时间" width="160" />
        <el-table-column label="模块" width="90" align="center"><template slot-scope="{ row }">{{ row.module_text }}</template></el-table-column>
        <el-table-column label="操作类型" width="80" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="actionTag(row.action)">{{ row.action_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="description" label="操作内容" min-width="200" show-overflow-tooltip />
        <el-table-column prop="resource_id" label="资源ID" width="120" show-overflow-tooltip>
          <template slot-scope="{ row }">{{ row.resource_id || '-' }}</template>
        </el-table-column>
        <el-table-column prop="user_ip" label="IP地址" width="130" show-overflow-tooltip />
        <el-table-column label="结果" width="80" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="row.result === 'success' ? 'success' : 'danger'">{{ row.result === 'success' ? '成功' : '失败' }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="120" align="center">
          <template slot-scope="{ row }">
            <el-button type="text" size="mini" @click="openDetail(row)">详情</el-button>
            <el-button v-if="hasPerm('ai:operation:audit:delete')" type="text" size="mini" style="color:#F56C6C;" @click="doDeleteOne(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination class="pager" background layout="total, sizes, prev, pager, next" :total="total"
        :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50, 100]"
        @size-change="s => { limit = s; page = 1; loadAll() }" @current-change="p => { page = p; loadAll() }" />
    </el-card>

    <!-- 详情弹窗（4 Tab） -->
    <el-dialog title="审计日志详情" :visible.sync="detailVisible" width="900px" top="5vh">
      <div v-if="detail.id" v-loading="detailLoading">
        <el-tabs v-model="activeTab">
          <el-tab-pane label="基本信息" name="base">
            <el-descriptions :column="2" size="small" border>
              <el-descriptions-item label="日志ID">{{ detail.log_id }}</el-descriptions-item>
              <el-descriptions-item label="操作人">{{ detail.user_name || '-' }}</el-descriptions-item>
              <el-descriptions-item label="操作时间">{{ detail.create_time }}</el-descriptions-item>
              <el-descriptions-item label="模块">{{ detail.module_text }}</el-descriptions-item>
              <el-descriptions-item label="操作类型"><el-tag size="mini" :type="actionTag(detail.action)">{{ detail.action_text }}</el-tag></el-descriptions-item>
              <el-descriptions-item label="结果"><el-tag size="mini" :type="detail.result === 'success' ? 'success' : 'danger'">{{ detail.result === 'success' ? '成功' : '失败' }}</el-tag></el-descriptions-item>
              <el-descriptions-item label="耗时(ms)">{{ detail.duration ?? '-' }}</el-descriptions-item>
              <el-descriptions-item label="IP地址">{{ detail.user_ip || '-' }}</el-descriptions-item>
            </el-descriptions>
            <div v-if="detail.user_agent" class="meta-line"><b>User-Agent：</b>{{ detail.user_agent }}</div>
          </el-tab-pane>
          <el-tab-pane label="请求信息" name="req">
            <el-descriptions :column="2" size="small" border>
              <el-descriptions-item label="请求方法">{{ detail.request_method || '-' }}</el-descriptions-item>
              <el-descriptions-item label="请求路径">{{ detail.request_path || '-' }}</el-descriptions-item>
            </el-descriptions>
            <div class="sec-title">请求参数（敏感字段已脱敏）</div>
            <pre class="json-pre">{{ formatJson(detail.request_params) }}</pre>
          </el-tab-pane>
          <el-tab-pane label="变更详情" name="change">
            <div v-if="detail.action === 'create'"><div class="sec-title">新增内容</div><pre class="json-pre">{{ formatJson(detail.new_data) }}</pre></div>
            <div v-else-if="detail.action === 'update'">
              <div class="sec-title">变更对比（差异高亮）</div>
              <el-table v-if="diffRows.length" :data="diffRows" size="mini" border>
                <el-table-column prop="key" label="字段" width="180" />
                <el-table-column label="变更前">
                  <template slot-scope="{ row }"><span :class="{ 'diff-old': row.changed }">{{ row.old }}</span></template>
                </el-table-column>
                <el-table-column label="变更后">
                  <template slot-scope="{ row }"><span :class="{ 'diff-new': row.changed }">{{ row.new }}</span></template>
                </el-table-column>
              </el-table>
              <div v-else class="cfg-none">（无变更数据）</div>
            </div>
            <div v-else-if="detail.action === 'delete'"><div class="sec-title">被删除内容</div><pre class="json-pre">{{ formatJson(detail.old_data) }}</pre></div>
            <div v-else class="cfg-none">该操作无变更数据</div>
          </el-tab-pane>
          <el-tab-pane label="错误信息" name="err">
            <div v-if="detail.error_message" class="err-box"><pre>{{ detail.error_message }}</pre></div>
            <div v-else class="cfg-none">（无错误信息）</div>
          </el-tab-pane>
        </el-tabs>
      </div>
    </el-dialog>

    <!-- 统计图表弹窗 -->
    <el-dialog title="审计统计分析" :visible.sync="statsVisible" width="1000px" top="5vh">
      <div style="text-align:right;margin-bottom:8px;"><el-button size="mini" icon="el-icon-picture-outline" @click="exportCharts">导出图片</el-button></div>
      <el-row :gutter="12">
        <el-col :span="14"><div class="chart-box"><div class="chart-title">操作趋势</div><div ref="trendChart" class="chart" style="height:260px;"></div></div></el-col>
        <el-col :span="10"><div class="chart-box"><div class="chart-title">操作类型分布</div><div ref="distChart" class="chart" style="height:260px;"></div></div></el-col>
      </el-row>
      <el-row :gutter="12">
        <el-col :span="12"><div class="chart-box"><div class="chart-title">操作模块排行TOP10</div><div ref="modChart" class="chart" style="height:240px;"></div></div></el-col>
        <el-col :span="12"><div class="chart-box"><div class="chart-title">活跃用户TOP10</div><div ref="userChart" class="chart" style="height:240px;"></div></div></el-col>
      </el-row>
    </el-dialog>
  </div>
</template>

<script>
import * as echarts from 'echarts'
import { getAuditList, getAuditDetail, getAuditStatistics, getAuditTrend, getAuditActionDist, exportAuditLogs, deleteAuditLog, batchDeleteAuditLogs } from '@/api/aiAudit'

const MODULE_TEXT = { system: '系统', chat: '对话', agent: '智能体', knowledge: '知识库', tool: '工具', workflow: '工作流', app: '应用', apikey: 'API密钥', user: '用户', role: '角色', permission: '权限', menu: '菜单', device: '设备', safety: '安全', hr: '人事', warehouse: '仓储', other: '其他' }
const ACTION_TEXT = { create: '新增', update: '修改', delete: '删除', query: '查询', login: '登录', logout: '登出', export: '导出', import: '导入', approve: '审批', other: '其他' }

export default {
  name: 'AiOperationAudit',
  data () {
    return {
      MODULE_TEXT, ACTION_TEXT,
      resultOptions: [],
      list: [], total: 0, page: 1, limit: 20, loading: false, selection: [],
      stats: { total: 0, today: 0, week: 0, month: 0 },
      filters: { keyword: '', module: '', action: '', result: '', ip: '', resource_id: '', timeRange: '', dateRange: null },
      detailVisible: false, detail: {}, detailLoading: false, activeTab: 'base',
      statsVisible: false, charts: {}
    }
  },
  computed: {
    // 变更字段差异对比（变更前/后值不同则高亮）
    diffRows () {
      const oldData = this.detail.old_data || {}
      const newData = this.detail.new_data || {}
      if (!Object.keys(oldData).length && !Object.keys(newData).length) return []
      const keys = new Set([...Object.keys(oldData), ...Object.keys(newData)])
      const rows = []
      for (const k of keys) {
        const ov = oldData[k]
        const nv = newData[k]
        const os = (ov !== null && typeof ov === 'object') ? JSON.stringify(ov) : String(ov ?? '')
        const ns = (nv !== null && typeof nv === 'object') ? JSON.stringify(nv) : String(nv ?? '')
        rows.push({ key: k, old: os, new: ns, changed: os !== ns })
      }
      return rows
    }
  },
  created () { this.loadAll(); this.loadStats(); this.loadDicts() },
  methods: {
    // 审计结果从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../api/dictionary')
      try { const r = await getDictByCode('audit_result'); this.resultOptions = r.data || [] } catch (e) { this.resultOptions = [] }
    },
    hasPerm (code) {
      const u = this.$store.state.user.userInfo || {}
      const p = this.$store.state.user.permissions || []
      if (u.is_super_admin || p.indexOf('super_admin') > -1) return true
      return p.indexOf(code) > -1
    },
    buildParams () {
      const p = { page: this.page, limit: this.limit }
      if (this.filters.keyword) p.keyword = this.filters.keyword
      if (this.filters.module) p.module = this.filters.module
      if (this.filters.action) p.action = this.filters.action
      if (this.filters.result) p.result = this.filters.result
      if (this.filters.ip) p.ip = this.filters.ip
      if (this.filters.resource_id) p.resource_id = this.filters.resource_id
      if (this.filters.timeRange === 'custom' && this.filters.dateRange && this.filters.dateRange.length === 2) {
        p.start_date = this.filters.dateRange[0]; p.end_date = this.filters.dateRange[1]
      } else if (this.filters.timeRange && this.filters.timeRange !== 'custom') {
        const now = new Date()
        const fmt = d => d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' + String(d.getDate()).padStart(2, '0')
        if (this.filters.timeRange === '1h') { p.start_date = fmt(new Date(now.getTime() - 3600000)); p.end_date = fmt(now) }
        else if (this.filters.timeRange === '24h') { p.start_date = fmt(new Date(now.getTime() - 86400000)); p.end_date = fmt(now) }
        else if (this.filters.timeRange === '7d') { p.start_date = fmt(new Date(now.getTime() - 7 * 86400000)); p.end_date = fmt(now) }
        else if (this.filters.timeRange === '30d') { p.start_date = fmt(new Date(now.getTime() - 30 * 86400000)); p.end_date = fmt(now) }
      }
      return p
    },
    async loadAll () {
      this.loading = true
      try { const r = await getAuditList(this.buildParams()); if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 } } catch (e) {} finally { this.loading = false }
    },
    async loadStats () {
      try { const r = await getAuditStatistics(); if (r.code === 0) this.stats = r.data || this.stats } catch (e) {}
    },
    onSearch () { this.page = 1; this.loadAll() },
    onTimeRangeChange () { if (this.filters.timeRange !== 'custom') this.onSearch() },
    resetFilter () { this.filters = { keyword: '', module: '', action: '', result: '', ip: '', resource_id: '', timeRange: '', dateRange: null }; this.page = 1; this.loadAll() },
    async openDetail (row) {
      this.detailVisible = true; this.detail = {}; this.detailLoading = true; this.activeTab = 'base'
      try { const r = await getAuditDetail(row.id); if (r.code === 0) this.detail = r.data || {} } catch (e) {} finally { this.detailLoading = false }
    },
    // 统计图表
    openStats () {
      this.statsVisible = true
      this.$nextTick(() => {
        if (!this.charts.trend) this.charts.trend = echarts.init(this.$refs.trendChart)
        if (!this.charts.dist) this.charts.dist = echarts.init(this.$refs.distChart)
        if (!this.charts.mod) this.charts.mod = echarts.init(this.$refs.modChart)
        if (!this.charts.user) this.charts.user = echarts.init(this.$refs.userChart)
        getAuditTrend({ range: 'day' }).then(r => {
          if (r.code !== 0 || !this.charts.trend) return
          const list = r.data.list || []
          this.charts.trend.setOption({ tooltip: { trigger: 'axis' }, grid: { left: 40, right: 20, top: 25, bottom: 30 }, xAxis: { type: 'category', data: list.map(i => i.date), axisLabel: { fontSize: 10 } }, yAxis: { type: 'value', minInterval: 1 }, series: [{ type: 'line', smooth: true, data: list.map(i => i.count), areaStyle: { opacity: 0.12 }, itemStyle: { color: '#409EFF' } }] })
        }).catch(() => {})
        getAuditActionDist().then(r => {
          if (r.code !== 0 || !this.charts.dist) return
          const list = r.data.list || []
          this.charts.dist.setOption({ tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' }, legend: { bottom: 0 }, series: [{ type: 'pie', radius: ['35%', '65%'], center: ['50%', '45%'], data: list.map(i => ({ name: i.name, value: i.cnt })) }] })
        }).catch(() => {})
        getAuditStatistics().then(r => {
          if (r.code !== 0) return
          if (this.charts.mod) {
            const list = r.data.module_rank || []
            this.charts.mod.setOption({ tooltip: { trigger: 'axis' }, grid: { left: 30, right: 90, top: 15, bottom: 20 }, xAxis: { type: 'value', minInterval: 1 }, yAxis: { type: 'category', data: list.map(i => i.name).reverse(), axisLabel: { fontSize: 10 } }, series: [{ type: 'bar', data: list.map(i => i.cnt).reverse(), itemStyle: { color: '#67C23A' }, barMaxWidth: 14 }] })
          }
          if (this.charts.user) {
            const list = r.data.user_rank || []
            this.charts.user.setOption({ tooltip: { trigger: 'axis' }, grid: { left: 30, right: 90, top: 15, bottom: 20 }, xAxis: { type: 'value', minInterval: 1 }, yAxis: { type: 'category', data: list.map(i => i.name).reverse(), axisLabel: { fontSize: 10 } }, series: [{ type: 'bar', data: list.map(i => i.cnt).reverse(), itemStyle: { color: '#E6A23C' }, barMaxWidth: 14 }] })
          }
        }).catch(() => {})
      })
    },
    // 导出
    async doExport (format) {
      const p = this.buildParams(); delete p.page; delete p.limit
      try {
        const resp = await exportAuditLogs({ ...p, format })
        const blob = resp.data instanceof Blob ? resp.data : new Blob([resp.data])
        const url = window.URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url; a.download = 'audit_logs_' + new Date().toISOString().slice(0, 10).replace(/-/g, '') + (format === 'json' ? '.json' : '.csv')
        document.body.appendChild(a); a.click(); document.body.removeChild(a); window.URL.revokeObjectURL(url)
      } catch (e) {}
    },
    // 删除
    doDeleteOne (row) {
      this.$confirm(`确定删除日志 [${row.log_id}] 吗？`, '删除确认', { type: 'warning' }).then(async () => {
        try { const r = await deleteAuditLog(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadAll(); this.loadStats() } } catch (e) {}
      }).catch(() => {})
    },
    doDeleteCmd (cmd) {
      if (cmd === 'selected') {
        if (!this.selection.length) return
        const ids = this.selection.map(s => s.id)
        this.$confirm(`确定删除选中的 ${ids.length} 条日志吗？`, '批量删除', { type: 'warning' }).then(async () => {
          try { const r = await batchDeleteAuditLogs({ ids }); if (r.code === 0) { this.$message.success('已删除 ' + (r.data.deleted || 0) + ' 条'); this.loadAll(); this.loadStats() } } catch (e) {}
        }).catch(() => {})
      } else if (cmd === 'bytime') {
        this.$prompt('输入开始日期（YYYY-MM-DD），删除该日期之前的日志', '按时间删除', { inputPlaceholder: '如 2026-06-01' }).then(async ({ value }) => {
          if (!value) return
          this.$confirm(`确定删除 ${value} 之前的全部日志吗？`, '确认', { type: 'warning' }).then(async () => {
            try { const r = await batchDeleteAuditLogs({ start_date: '2000-01-01', end_date: value }); if (r.code === 0) { this.$message.success('已删除 ' + (r.data.deleted || 0) + ' 条'); this.loadAll(); this.loadStats() } } catch (e) {}
          }).catch(() => {})
        }).catch(() => {})
      }
    },
    actionTag (a) { return { create: 'success', update: 'warning', delete: 'danger', query: 'primary', login: 'primary', logout: 'info', export: 'warning', import: 'warning', approve: 'primary', other: 'info' }[a] || 'info' },
    // 导出统计图表为图片
    exportCharts () {
      for (const k of Object.keys(this.charts)) {
        const c = this.charts[k]
        if (!c) continue
        const url = c.getDataURL({ pixelRatio: 2, backgroundColor: '#fff' })
        const a = document.createElement('a')
        a.href = url
        a.download = 'audit_chart_' + k + '.png'
        document.body.appendChild(a); a.click(); document.body.removeChild(a)
      }
    },
    formatJson (obj) {
      if (obj === null || obj === undefined) return '(空)'
      try { return JSON.stringify(typeof obj === 'string' ? JSON.parse(obj) : obj, null, 2) } catch (e) { return String(obj) }
    }
  },
  beforeDestroy () {
    for (const k of Object.keys(this.charts)) { if (this.charts[k]) { this.charts[k].dispose(); this.charts[k] = null } }
  }
}
</script>

<style scoped>
.audit-page { padding: 16px; }
.stat-row { margin-bottom: 14px; }
.stat-card { display: flex; align-items: center; background: #fff; border-radius: 8px; padding: 12px; box-shadow: 0 1px 3px rgba(0,0,0,.05); }
.stat-icon { width: 40px; height: 40px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 20px; margin-right: 10px; }
.stat-value { font-size: 18px; font-weight: 700; color: #303133; }
.stat-label { font-size: 12px; color: #909399; margin-top: 2px; }
.filter-card { margin-bottom: 14px; }
.filter-card /deep/ .el-card__body { padding: 12px 16px 0; }
.list-card /deep/ .el-card__body { padding: 12px 16px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.pager { margin-top: 14px; text-align: right; }
.sec-title { font-size: 13px; font-weight: 600; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; margin: 12px 0 6px; }
.meta-line { margin-top: 8px; font-size: 13px; color: #606266; word-break: break-all; }
.json-pre { background: #f8f9fb; border-radius: 6px; padding: 10px; font-size: 12px; max-height: 300px; overflow: auto; white-space: pre-wrap; word-break: break-all; }
.err-box { font-size: 12px; color: #F56C6C; background: #fef0f0; border-radius: 6px; padding: 10px; }
.cfg-none { font-size: 12px; color: #c0c4cc; padding: 8px 0; }
.diff-old { color: #F56C6C; }
.diff-new { color: #67C23A; }
.chart-box { background: #fff; border: 1px solid #ebeef5; border-radius: 8px; padding: 10px; margin-bottom: 12px; }
.chart-title { font-size: 13px; font-weight: 600; color: #303133; margin-bottom: 8px; }
</style>
