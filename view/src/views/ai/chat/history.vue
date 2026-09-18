<!-- 文件：admin/src/views/ai/chat/history.vue -->
<template>
  <div class="page">
    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="6">
        <div class="stat-card stat-blue" @click="quickFilter('')">
          <i class="el-icon-document stat-icon"></i>
          <div class="stat-info">
            <div class="stat-num">{{ stats.total_sessions }}</div>
            <div class="stat-label">总会话数</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-green" @click="quickFilter('today')">
          <i class="el-icon-date stat-icon"></i>
          <div class="stat-info">
            <div class="stat-num">{{ stats.today_sessions }}</div>
            <div class="stat-label">今日会话</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-green2" @click="quickFilter('active')">
          <i class="el-icon-check stat-icon"></i>
          <div class="stat-info">
            <div class="stat-num">{{ stats.active_sessions }}</div>
            <div class="stat-label">活跃会话</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card stat-grey" @click="quickFilter('archived')">
          <i class="el-icon-folder stat-icon"></i>
          <div class="stat-info">
            <div class="stat-num">{{ stats.archived_sessions }}</div>
            <div class="stat-label">已归档会话</div>
          </div>
        </div>
      </el-col>
    </el-row>

    <el-card shadow="never" class="sec-card">
      <!-- 筛选区域 -->
      <el-form inline size="small" class="filter-form">
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入会话标题搜索" clearable style="width:200px"
            @keyup.enter.native="handleSearch" @clear="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" placeholder="全部状态" clearable style="width:130px" @change="handleSearch">
            <el-option label="全部状态" value="" />
            <el-option label="活跃" value="active" />
            <el-option label="已归档" value="archived" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.date_range" placeholder="时间范围" clearable style="width:140px" @change="handleDateRange">
            <el-option label="全部时间" value="" />
            <el-option label="最近7天" value="7days" />
            <el-option label="最近30天" value="30days" />
            <el-option label="最近90天" value="90days" />
            <el-option label="自定义" value="custom" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="filters.date_range === 'custom'">
          <el-date-picker v-model="customDate" type="daterange" range-separator="至" start-placeholder="开始日期"
            end-placeholder="结束日期" value-format="yyyy-MM-dd" style="width:240px" @change="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.sort_by" style="width:130px" @change="handleSearch">
            <el-option label="按更新时间" value="update_time" />
            <el-option label="按创建时间" value="create_time" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.sort_order" style="width:110px" @change="handleSearch">
            <el-option label="倒序" value="desc" />
            <el-option label="正序" value="asc" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>

      <!-- 工具栏 -->
      <div class="toolbar">
        <span class="toolbar-tip">共 {{ total }} 条会话</span>
        <div class="toolbar-right">
          <el-button size="small" icon="el-icon-refresh" @click="loadAll">刷新</el-button>
          <el-dropdown trigger="click" @command="handleExportCmd">
            <el-button size="small" icon="el-icon-download" :disabled="!selection.length">导出</el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item command="current">导出当前</el-dropdown-item>
              <el-dropdown-item command="selected" :disabled="!selection.length">导出选中（{{ selection.length }}）</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
          <el-button size="small" type="danger" icon="el-icon-delete" :disabled="!selection.length" @click="batchDelete">批量删除</el-button>
        </div>
      </div>

      <!-- 表格 -->
      <el-table :data="sessions" size="small" stripe v-loading="loading" @selection-change="handleSelectionChange">
        <el-table-column type="selection" width="40" />
        <el-table-column type="index" label="序号" width="60" />
        <el-table-column prop="title" label="会话标题" min-width="160" show-overflow-tooltip>
          <template slot-scope="s">
            <el-link type="primary" :underline="false" @click="openChat(s.row)">{{ s.row.title }}</el-link>
          </template>
        </el-table-column>
        <el-table-column label="智能体" width="110" align="center">
          <template slot-scope="s">
            <el-tag v-if="s.row.agent_name" size="mini" type="warning">{{ s.row.agent_name }}</el-tag>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column prop="update_time" label="最后更新时间" width="160" />
        <el-table-column prop="message_count" label="消息数量" width="100" align="center" />
        <el-table-column prop="tool_call_count" label="工具调用" width="100" align="center" />
        <el-table-column prop="total_tokens" label="Token消耗" width="100" align="center" />
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="s.row.status === 'active' ? 'success' : 'info'">
              {{ s.row.status === 'active' ? '活跃' : '已归档' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="240" align="center">
          <template slot-scope="s">
            <el-button size="mini" type="primary" @click="openChat(s.row)">继续对话</el-button>
            <el-button size="mini" @click="openDetail(s.row)">详情</el-button>
            <el-button size="mini" @click="openRename(s.row)">重命名</el-button>
            <el-button size="mini" :type="s.row.status === 'active' ? 'warning' : 'success'" @click="toggleArchive(s.row)">
              {{ s.row.status === 'active' ? '归档' : '恢复' }}
            </el-button>
            <el-button size="mini" type="danger" @click="removeSession(s.row)">删除</el-button>
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

    <!-- 会话详情弹窗 -->
    <el-dialog title="会话详情" :visible.sync="detailVisible" width="700px" top="8vh">
      <div v-if="detail" class="detail-info">
        <el-descriptions :column="2" size="small" border>
          <el-descriptions-item label="会话标题">{{ detail.title }}</el-descriptions-item>
          <el-descriptions-item label="会话ID">{{ detail.session_id }}</el-descriptions-item>
          <el-descriptions-item label="智能体">{{ detail.agent_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ detail.create_time }}</el-descriptions-item>
          <el-descriptions-item label="最后更新时间">{{ detail.update_time }}</el-descriptions-item>
          <el-descriptions-item label="消息总数">{{ detail.message_count }}</el-descriptions-item>
          <el-descriptions-item label="工具调用次数">{{ detail.tool_call_count }}</el-descriptions-item>
          <el-descriptions-item label="Token消耗">{{ detail.total_tokens }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag size="mini" :type="detail.status === 'active' ? 'success' : 'info'">
              {{ detail.status === 'active' ? '活跃' : '已归档' }}
            </el-tag>
          </el-descriptions-item>
        </el-descriptions>
        <div class="preview-title">最近消息预览（{{ (detail.preview_messages || []).length }} 条）</div>
        <div v-for="(m, i) in detail.preview_messages" :key="i" class="preview-msg">
          <span class="preview-role">{{ roleText(m.role) }}</span>
          <span class="preview-content">{{ msgSummary(m) }}</span>
        </div>
        <div style="margin-top:12px;text-align:right;">
          <el-button size="small" type="primary" @click="openChat(detail)">查看全部</el-button>
        </div>
      </div>
    </el-dialog>

    <!-- 重命名弹窗 -->
    <el-dialog title="重命名会话" :visible.sync="renameVisible" width="450px" top="20vh">
      <el-input v-model="renameTitle" maxlength="50" placeholder="请输入新标题（2-50字符）" show-word-limit
        @keyup.enter.native="doRename" />
      <span slot="footer">
        <el-button size="small" @click="renameVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="renaming" @click="doRename">确认</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  getAiHistoryList, getAiHistoryDetail, renameAiHistory, deleteAiHistory, batchDeleteAiHistory,
  archiveAiHistory, restoreAiHistory, getAiHistoryStatistics, exportAiHistory, batchExportAiHistory
} from '@/api/aiChat'

export default {
  name: 'AiChatHistory',
  data () {
    return {
      stats: { total_sessions: 0, today_sessions: 0, active_sessions: 0, archived_sessions: 0 },
      filters: { keyword: '', status: '', date_range: '', sort_by: 'update_time', sort_order: 'desc' },
      customDate: [],
      sessions: [], total: 0, page: 1, limit: 20, loading: false,
      selection: [],
      detailVisible: false, detail: null,
      renameVisible: false, renameTitle: '', renameSessionId: '', renaming: false
    }
  },
  created () {
    this.loadStats()
    this.loadList()
  },
  methods: {
    roleText (role) {
      return { user: '用户', assistant: 'AI', system: '系统', tool: '工具' }[role] || role
    },
    msgSummary (m) {
      const c = (m.content || '').trim()
      if (c) return c.length > 80 ? c.slice(0, 80) + '...' : c
      if (m.role === 'assistant' && m.tool_calls) return '[工具调用]'
      return '(空)'
    },
    // ---- 数据加载 ----
    async loadStats () {
      try {
        const r = await getAiHistoryStatistics()
        if (r.code === 0) this.stats = Object.assign(this.stats, r.data || {})
      } catch (e) {}
    },
    async loadList () {
      this.loading = true
      try {
        const params = {
          page: this.page, limit: this.limit,
          keyword: this.filters.keyword || undefined,
          status: this.filters.status || undefined,
          date_range: this.filters.date_range || undefined,
          sort_by: this.filters.sort_by, sort_order: this.filters.sort_order
        }
        if (this.filters.date_range === 'custom' && this.customDate && this.customDate.length === 2) {
          params.start_date = this.customDate[0]
          params.end_date = this.customDate[1]
        }
        const r = await getAiHistoryList(params)
        if (r.code === 0) {
          this.sessions = r.data.list || []
          this.total = r.data.total || 0
        }
      } catch (e) {} finally { this.loading = false }
    },
    loadAll () { this.page = 1; this.loadList(); this.loadStats() },
    handleSearch () { this.page = 1; this.loadList() },
    handleReset () {
      this.filters = { keyword: '', status: '', date_range: '', sort_by: 'update_time', sort_order: 'desc' }
      this.customDate = []
      this.handleSearch()
    },
    handleDateRange (val) {
      if (val !== 'custom') this.customDate = []
      this.handleSearch()
    },
    quickFilter (type) {
      if (type === 'today') {
        this.filters.status = ''
        this.filters.date_range = 'today'
        this.customDate = []
        // today 走自定义日期=今天
        const today = new Date()
        const fmt = d => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
        this.customDate = [fmt(today), fmt(today)]
        this.filters.date_range = 'custom'
      } else if (type === 'active') {
        this.filters.status = 'active'; this.filters.date_range = ''; this.customDate = []
      } else if (type === 'archived') {
        this.filters.status = 'archived'; this.filters.date_range = ''; this.customDate = []
      } else {
        this.filters.status = ''; this.filters.date_range = ''; this.customDate = []
      }
      this.handleSearch()
    },
    handleSelectionChange (rows) { this.selection = rows },
    // ---- 会话操作 ----
    openChat (row) {
      this.$router.push({ path: '/ai/chat/create', query: { session_id: row.session_id } })
    },
    async openDetail (row) {
      try {
        const r = await getAiHistoryDetail(row.session_id)
        if (r.code === 0) { this.detail = r.data; this.detailVisible = true }
      } catch (e) {}
    },
    openRename (row) {
      this.renameVisible = true
      this.renameTitle = row.title
      this.renameSessionId = row.session_id
    },
    async doRename () {
      const t = (this.renameTitle || '').trim()
      if (t.length < 2 || t.length > 50) { this.$message.warning('标题长度需为2-50字符'); return }
      this.renaming = true
      try {
        const r = await renameAiHistory(this.renameSessionId, t)
        if (r.code === 0) {
          this.$message.success('重命名成功')
          this.renameVisible = false
          this.loadList()
        }
      } catch (e) {} finally { this.renaming = false }
    },
    async removeSession (row) {
      const c = await this.$confirm('确定要删除该会话吗？删除后不可恢复', '提示', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const r = await deleteAiHistory(row.session_id)
        if (r.code === 0) { this.$message.success('删除成功'); this.loadAll() }
      } catch (e) {}
    },
    async batchDelete () {
      if (!this.selection.length) return
      const c = await this.$confirm(`确定要删除选中的 ${this.selection.length} 个会话吗？删除后不可恢复`, '提示', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const ids = this.selection.map(s => s.session_id)
        const r = await batchDeleteAiHistory(ids)
        if (r.code === 0) { this.$message.success(r.msg || '批量删除完成'); this.loadAll() }
      } catch (e) {}
    },
    async toggleArchive (row) {
      try {
        const fn = row.status === 'active' ? archiveAiHistory : restoreAiHistory
        const r = await fn(row.session_id)
        if (r.code === 0) { this.$message.success(row.status === 'active' ? '已归档' : '已恢复'); this.loadAll() }
      } catch (e) {}
    },
    // ---- 导出 ----
    handleExportCmd (cmd) {
      if (cmd === 'current') {
        if (this.sessions.length) this.downloadSingle(this.sessions[0])
      } else if (cmd === 'selected') {
        this.batchExport()
      }
    },
    async downloadSingle (row) {
      try {
        const blob = await exportAiHistory(row.session_id, 'md')
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = (row.title || 'conversation') + '.md'
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
      } catch (e) {
        this.$message.error('导出失败')
      }
    },
    async batchExport () {
      if (!this.selection.length) return
      try {
        const blob = await batchExportAiHistory(this.selection.map(s => s.session_id))
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = 'ai_conversations.zip'
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
      } catch (e) {
        this.$message.error('导出失败')
      }
    }
  }
}
</script>

<style scoped>
.page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.sec-card { margin-bottom: 16px; }
.stat-row { margin-bottom: 16px; }
.stat-card { background: #fff; border-radius: 8px; padding: 18px; display: flex; align-items: center; box-shadow: 0 1px 4px rgba(0,0,0,0.06); cursor: pointer; transition: transform 0.15s; }
.stat-card:hover { transform: translateY(-2px); }
.stat-icon { font-size: 34px; margin-right: 14px; }
.stat-num { font-size: 22px; font-weight: 600; color: #303133; }
.stat-label { font-size: 12px; color: #909399; }
.stat-blue .stat-icon { color: #409EFF; }
.stat-green .stat-icon, .stat-green2 .stat-icon { color: #67C23A; }
.stat-grey .stat-icon { color: #909399; }
.filter-form { margin-bottom: 8px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.toolbar-tip { font-size: 13px; color: #909399; }
.pager { margin-top: 12px; text-align: right; }
.detail-info { padding: 4px; }
.preview-title { margin: 14px 0 8px; font-size: 14px; font-weight: 600; color: #303133; }
.preview-msg { padding: 6px 8px; border-bottom: 1px dashed #ebeef5; font-size: 13px; }
.preview-role { font-weight: 600; color: #409EFF; margin-right: 8px; }
.preview-content { color: #606266; }
</style>
