<!-- 文件：admin/src/views/ai/tools/list.vue -->
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
      <!-- 筛选 -->
      <el-form inline size="small" class="filter-form">
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入工具名称或描述" clearable style="width:200px"
            @keyup.enter.native="handleSearch" @clear="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.category" placeholder="全部分类" clearable style="width:130px" @change="handleSearch">
            <el-option label="全部分类" value="" />
            <el-option v-for="(t, v) in CATEGORY_OPTIONS" :key="v" :label="t" :value="v" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" placeholder="全部状态" clearable style="width:120px" @change="handleSearch">
            <el-option label="全部状态" value="" />
            <el-option label="启用" value="1" />
            <el-option label="停用" value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.method" placeholder="全部方法" clearable style="width:120px" @change="handleSearch">
            <el-option label="全部方法" value="" />
            <el-option label="GET" value="GET" />
            <el-option label="POST" value="POST" />
            <el-option label="PUT" value="PUT" />
            <el-option label="DELETE" value="DELETE" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>

      <!-- 工具栏 -->
      <div class="toolbar">
        <span class="toolbar-tip">共 {{ total }} 个工具</span>
        <div class="toolbar-right">
          <el-button size="small" type="primary" icon="el-icon-plus" @click="goCreate">新增工具</el-button>
          <el-dropdown trigger="click" @command="handleBatchCmd">
            <el-button size="small" :disabled="!selection.length">批量操作</el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item command="enable">批量启用</el-dropdown-item>
              <el-dropdown-item command="disable">批量停用</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
          <el-button size="small" icon="el-icon-refresh" @click="loadAll">刷新</el-button>
        </div>
      </div>

      <!-- 表格 -->
      <el-table :data="tools" size="small" stripe v-loading="loading" @selection-change="handleSelectionChange">
        <el-table-column type="selection" width="40" />
        <el-table-column type="index" label="序号" width="60" />
        <el-table-column label="工具名称" width="140">
          <template slot-scope="s">
            <el-link type="primary" :underline="false" @click="openDetail(s.row)">{{ s.row.tool_name }}</el-link>
          </template>
        </el-table-column>
        <el-table-column prop="tool_display_name" label="显示名称" width="140" />
        <el-table-column label="分类" width="100" align="center">
          <template slot-scope="s">
            <el-tag size="mini">{{ s.row.category_text || s.row.category }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="方法" width="80" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="methodTag(s.row.method)">{{ s.row.method }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="api_path" label="API路径" min-width="200" show-overflow-tooltip />
        <el-table-column prop="call_count" label="调用次数" width="90" align="center" />
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="s.row.status === 1 ? 'success' : 'info'">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="220" align="center">
          <template slot-scope="s">
            <el-button size="mini" @click="openDetail(s.row)">详情</el-button>
            <el-button size="mini" :type="s.row.status === 1 ? 'warning' : 'success'" @click="toggleStatus(s.row)">
              {{ s.row.status === 1 ? '停用' : '启用' }}
            </el-button>
            <el-button size="mini" type="info" @click="openTest(s.row)">测试</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <div class="pager">
        <el-pagination background layout="total, sizes, prev, pager, next" :total="total"
          :page-size="limit" :page-sizes="[10, 20, 50]" :current-page="page"
          @size-change="p => { limit = p; page = 1; loadList() }"
          @current-change="p => { page = p; loadList() }" />
      </div>
    </el-card>

    <!-- 工具详情弹窗 -->
    <el-dialog title="工具详情" :visible.sync="detailVisible" width="800px" top="5vh">
      <el-tabs v-model="detailTab" v-if="detail">
        <!-- 基本信息 -->
        <el-tab-pane label="基本信息" name="info">
          <el-descriptions :column="2" size="small" border>
            <el-descriptions-item label="工具名称">{{ detail.tool_name }}</el-descriptions-item>
            <el-descriptions-item label="显示名称">{{ detail.tool_display_name }}</el-descriptions-item>
            <el-descriptions-item label="分类">{{ detail.category_text }}</el-descriptions-item>
            <el-descriptions-item label="状态">
              <el-tag size="mini" :type="detail.status === 1 ? 'success' : 'info'">{{ detail.status === 1 ? '启用' : '停用' }}</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="描述" :span="2">{{ detail.description || '-' }}</el-descriptions-item>
            <el-descriptions-item label="请求方法">
              <el-tag size="mini" :type="methodTag(detail.method)">{{ detail.method }}</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="API路径">{{ detail.api_path }}</el-descriptions-item>
            <el-descriptions-item label="是否需要确认">{{ detail.requires_confirm === 1 ? '是' : '否' }}</el-descriptions-item>
            <el-descriptions-item label="超时时间">{{ detail.timeout }}秒</el-descriptions-item>
            <el-descriptions-item label="调用次数">{{ detail.call_count }}</el-descriptions-item>
            <el-descriptions-item label="最后调用时间">{{ detail.last_call_time || '-' }}</el-descriptions-item>
            <el-descriptions-item label="创建时间">{{ detail.create_time }}</el-descriptions-item>
            <el-descriptions-item label="更新时间">{{ detail.update_time }}</el-descriptions-item>
          </el-descriptions>
          <div class="detail-json">
            <div class="json-label">请求头配置 <el-button size="mini" type="text" @click="copyJson(detail.headers)">复制</el-button></div>
            <pre class="json-body">{{ formatJson(detail.headers) }}</pre>
          </div>
          <div class="detail-json">
            <div class="json-label">参数定义（JSON Schema） <el-button size="mini" type="text" @click="copyJson(detail.params_schema)">复制</el-button></div>
            <pre class="json-body">{{ formatJson(detail.params_schema) }}</pre>
          </div>
          <div class="detail-json">
            <div class="json-label">返回定义 <el-button size="mini" type="text" @click="copyJson(detail.response_schema)">复制</el-button></div>
            <pre class="json-body">{{ formatJson(detail.response_schema) }}</pre>
          </div>
        </el-tab-pane>
        <!-- 调用测试 -->
        <el-tab-pane label="调用测试" name="test">
          <div class="test-params">
            <el-form label-width="120px" size="small">
              <el-form-item v-for="(p, key) in schemaProps" :key="key" :label="p.title || key">
                <el-input v-model="testForm[key]" :placeholder="'参数 ' + key" />
              </el-form-item>
              <el-form-item v-if="!Object.keys(schemaProps).length">
                <span class="no-params">该工具无参数定义，直接测试</span>
              </el-form-item>
              <el-form-item>
                <el-button type="primary" size="small" :loading="testing" @click="runTest">发送测试请求</el-button>
              </el-form-item>
            </el-form>
          </div>
          <div v-if="testResult" class="test-result">
            <div class="result-row">状态码：<b :class="testResult.success ? 'ok' : 'err'">{{ testResult.status_code }}</b></div>
            <div class="result-row">响应时间：{{ testResult.elapsed_ms }}ms</div>
            <pre class="result-body">{{ formatResultBody(testResult.response_body) }}</pre>
          </div>
        </el-tab-pane>
        <!-- 调用记录 -->
        <el-tab-pane label="调用记录" name="logs">
          <el-table :data="detail.call_logs || []" size="small" stripe>
            <el-table-column prop="create_time" label="时间" width="160" />
            <el-table-column label="参数" min-width="150" show-overflow-tooltip>
              <template slot-scope="s">{{ s.row.params }}</template>
            </el-table-column>
            <el-table-column label="结果" min-width="150" show-overflow-tooltip>
              <template slot-scope="s">{{ (s.row.result || '').slice(0, 100) }}</template>
            </el-table-column>
            <el-table-column prop="elapsed_ms" label="耗时(ms)" width="90" align="center" />
            <el-table-column label="成功" width="70" align="center">
              <template slot-scope="s">
                <el-tag size="mini" :type="s.row.success === 1 ? 'success' : 'danger'">{{ s.row.success === 1 ? '是' : '否' }}</el-tag>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-dialog>
  </div>
</template>

<script>
import {
  getAiToolList, getAiToolDetail, getAiToolStatistics, toggleAiToolStatus,
  batchToggleAiToolStatus, testAiTool
} from '@/api/aiTool'

const CATEGORY_OPTIONS = { device: '设备工具', safety: '安全工具', hr: '人事工具', warehouse: '仓储工具', common: '通用工具' }

export default {
  name: 'AiToolList',
  data () {
    return {
      CATEGORY_OPTIONS,
      stats: { total_tools: 0, enabled_tools: 0, disabled_tools: 0, today_calls: 0, top_tools: [] },
      filters: { keyword: '', category: '', status: '', method: '' },
      tools: [], total: 0, page: 1, limit: 20, loading: false,
      selection: [],
      detailVisible: false, detailTab: 'info', detail: null,
      testForm: {}, testing: false, testResult: null
    }
  },
  computed: {
    statCards () {
      return [
        { key: 'total', label: '工具总数', value: this.stats.total_tools, icon: 'el-icon-s-tools', cls: 'stat-blue' },
        { key: 'enabled', label: '已启用数', value: this.stats.enabled_tools, icon: 'el-icon-check', cls: 'stat-green', onClick: () => this.quickFilter('1') },
        { key: 'disabled', label: '已停用数', value: this.stats.disabled_tools, icon: 'el-icon-close', cls: 'stat-grey', onClick: () => this.quickFilter('0') },
        { key: 'today', label: '今日调用数', value: this.stats.today_calls, icon: 'el-icon-date', cls: 'stat-orange' },
        { key: 'top', label: '热门工具TOP1', value: this.stats.top_tools && this.stats.top_tools.length ? this.stats.top_tools[0].tool_display_name : '-', icon: 'el-icon-star-on', cls: 'stat-gold' }
      ]
    },
    schemaProps () {
      // 从 params_schema 提取属性（JSON Schema properties）
      if (!this.detail || !this.detail.params_schema) return {}
      const ps = typeof this.detail.params_schema === 'string' ? JSON.parse(this.detail.params_schema) : this.detail.params_schema
      return (ps && ps.properties) || {}
    }
  },
  created () {
    this.loadStats()
    this.loadList()
    // 支持从调用日志等页面携带 tool_id 跳转时自动打开对应工具详情
    const qid = this.$route && this.$route.query && this.$route.query.tool_id
    if (qid) {
      this.$nextTick(() => this.openDetail({ id: Number(qid) }))
    }
  },
  methods: {
    methodTag (m) {
      return { GET: 'primary', POST: 'success', PUT: 'warning', DELETE: 'danger' }[m] || 'info'
    },
    formatJson (obj) {
      if (obj === null || obj === undefined || obj === '') return '(空)'
      if (typeof obj === 'string') { try { return JSON.stringify(JSON.parse(obj), null, 2) } catch (e) { return obj } }
      try { return JSON.stringify(obj, null, 2) } catch (e) { return String(obj) }
    },
    formatResultBody (body) {
      if (!body) return '(无响应体)'
      try { return JSON.stringify(JSON.parse(body), null, 2) } catch (e) { return body }
    },
    copyJson (obj) {
      const text = this.formatJson(obj)
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(() => this.$message.success('已复制'))
      } else {
        const ta = document.createElement('textarea')
        ta.value = text
        document.body.appendChild(ta); ta.select(); document.execCommand('copy'); document.body.removeChild(ta)
        this.$message.success('已复制')
      }
    },
    async loadStats () {
      try {
        const r = await getAiToolStatistics()
        if (r.code === 0) this.stats = Object.assign(this.stats, r.data || {})
      } catch (e) {}
    },
    async loadList () {
      this.loading = true
      try {
        const params = {
          page: this.page, limit: this.limit,
          keyword: this.filters.keyword || undefined,
          category: this.filters.category || undefined,
          status: this.filters.status || undefined,
          method: this.filters.method || undefined
        }
        const r = await getAiToolList(params)
        if (r.code === 0) {
          this.tools = r.data.list || []
          this.total = r.data.total || 0
        }
      } catch (e) {} finally { this.loading = false }
    },
    loadAll () { this.page = 1; this.loadList(); this.loadStats() },
    handleSearch () { this.page = 1; this.loadList() },
    handleReset () {
      this.filters = { keyword: '', category: '', status: '', method: '' }
      this.handleSearch()
    },
    quickFilter (status) { this.filters.status = status; this.handleSearch() },
    handleSelectionChange (rows) { this.selection = rows },
    goCreate () { this.$router.push('/ai/tools/create') },
    async openDetail (row) {
      try {
        const r = await getAiToolDetail(row.id)
        if (r.code === 0) {
          this.detail = r.data
          this.detailTab = 'info'
          this.testForm = {}
          this.testResult = null
          this.detailVisible = true
        }
      } catch (e) {}
    },
    async toggleStatus (row) {
      const action = row.status === 1 ? '停用' : '启用'
      const c = await this.$confirm(`确认${action}工具 [${row.tool_name}] 吗？`, '提示', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const r = await toggleAiToolStatus(row.id, row.status === 1 ? 0 : 1)
        if (r.code === 0) { this.$message.success('状态已更新'); this.loadAll() }
      } catch (e) {}
    },
    async handleBatchCmd (cmd) {
      if (!this.selection.length) return
      const status = cmd === 'enable' ? 1 : 0
      const action = status === 1 ? '启用' : '停用'
      const c = await this.$confirm(`确认${action}选中的 ${this.selection.length} 个工具吗？`, '提示', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const ids = this.selection.map(s => s.id)
        const r = await batchToggleAiToolStatus(ids, status)
        if (r.code === 0) { this.$message.success(r.msg || '批量更新完成'); this.loadAll() }
      } catch (e) {}
    },
    openTest (row) {
      // 跳转到独立测试页面
      this.$router.push({ path: '/ai/tools/test', query: { tool_id: row.id } })
    },
    async runTest () {
      if (!this.detail) return
      this.testing = true
      this.testResult = null
      try {
        const r = await testAiTool(this.detail.id, this.testForm)
        if (r.code === 0) {
          this.testResult = r.data
          this.$message.success(r.msg || '测试完成')
        }
      } catch (e) {
        this.$message.error('测试失败')
      } finally { this.testing = false }
    }
  }
}
</script>

<style scoped>
.page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.sec-card { margin-bottom: 16px; }
.stat-row { margin-bottom: 16px; }
.stat-card { background: #fff; border-radius: 8px; padding: 16px; display: flex; align-items: center; box-shadow: 0 1px 4px rgba(0,0,0,0.06); cursor: pointer; }
.stat-icon { font-size: 30px; margin-right: 12px; }
.stat-num { font-size: 20px; font-weight: 600; color: #303133; }
.stat-label { font-size: 12px; color: #909399; }
.stat-blue .stat-icon { color: #409EFF; }
.stat-green .stat-icon { color: #67C23A; }
.stat-grey .stat-icon { color: #909399; }
.stat-orange .stat-icon { color: #E6A23C; }
.stat-gold .stat-icon { color: #E6A23C; }
.filter-form { margin-bottom: 8px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.toolbar-tip { font-size: 13px; color: #909399; }
.pager { margin-top: 12px; text-align: right; }
.detail-json { margin-top: 12px; }
.json-label { font-size: 13px; font-weight: 600; color: #909399; margin-bottom: 4px; }
.json-body { background: #f8f9fb; border-radius: 6px; padding: 10px; font-size: 12px; overflow-x: auto; max-height: 200px; }
.test-params { padding: 4px; }
.no-params { color: #909399; font-size: 13px; }
.test-result { margin-top: 12px; background: #f8f9fb; border-radius: 6px; padding: 10px; }
.result-row { font-size: 13px; margin-bottom: 4px; }
.result-row .ok { color: #67C23A; }
.result-row .err { color: #F56C6C; }
.result-body { background: #282c34; color: #abb2bf; border-radius: 6px; padding: 10px; font-size: 12px; overflow-x: auto; max-height: 250px; }
</style>
