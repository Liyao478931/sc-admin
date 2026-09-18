<!-- 文件：admin/src/views/ai/agent/list.vue -->
<template>
  <div class="page">
    <!-- 统计卡片（4个） -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="6" v-for="card in statCards" :key="card.key">
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
          <el-input v-model="filters.keyword" placeholder="请输入智能体名称" clearable style="width:200px"
            @keyup.enter.native="handleSearch" @clear="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" placeholder="全部状态" clearable style="width:110px" @change="handleSearch">
            <el-option label="启用" value="1" />
            <el-option label="停用" value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.is_system" placeholder="全部类型" clearable style="width:110px" @change="handleSearch">
            <el-option label="系统" value="1" />
            <el-option label="自定义" value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始日期"
            end-placeholder="结束日期" value-format="yyyy-MM-dd" style="width:240px" @change="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>

      <!-- 工具栏 -->
      <div class="toolbar">
        <span class="toolbar-tip">共 {{ total }} 个智能体</span>
        <div class="toolbar-right">
          <el-button v-permission="'ai:agent:add'" size="small" type="primary" icon="el-icon-plus" @click="openCreate">新建智能体</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadAll">刷新</el-button>
        </div>
      </div>

      <!-- 智能体卡片 -->
      <el-row :gutter="16" v-loading="loading" class="card-row">
        <el-col :span="8" v-for="ag in list" :key="ag.id" class="ag-col">
          <el-card shadow="hover" class="ag-card">
            <div slot="header" class="ag-head">
              <div class="ag-name-wrap">
                <img v-if="agentIconIsImage(ag)" :src="ag.agent_icon" class="ag-icon ag-icon-img" alt="" />
                <i v-else :class="agentIcon(ag)" class="ag-icon"></i>
                <span class="ag-name" :title="ag.agent_name" @click="openDetail(ag)">{{ ag.agent_name }}</span>
              </div>
              <div class="ag-tags">
                <el-tag size="mini" :type="ag.status === 1 ? 'success' : 'info'">{{ ag.status === 1 ? '启用' : '停用' }}</el-tag>
                <el-tag size="mini" :type="ag.is_system === 1 ? 'primary' : 'info'">{{ ag.is_system === 1 ? '系统' : '自定义' }}</el-tag>
              </div>
            </div>
            <div class="ag-desc">{{ ag.description || '暂无描述' }}</div>
            <div class="ag-meta">
              <div><i class="el-icon-collection"></i> {{ ag.kb_count }} 个知识库</div>
              <div><i class="el-icon-s-tools"></i> {{ ag.tool_count }} 个工具</div>
            </div>
            <div class="ag-meta">
              <div><i class="el-icon-cpu"></i> {{ ag.model_name }}</div>
              <div><i class="el-icon-user"></i> {{ ag.created_by_name || '-' }}</div>
            </div>
            <div class="ag-meta"><div><i class="el-icon-time"></i> {{ ag.create_time }}</div></div>
            <!-- 人设预览（可折叠） -->
            <div class="ag-prompt">
              <el-collapse v-model="promptOpen">
                <el-collapse-item :name="'p' + ag.id" title="人设预览">
                  <div class="prompt-body">{{ truncate(ag.system_prompt, 100) }}</div>
                </el-collapse-item>
              </el-collapse>
            </div>
            <!-- 操作 -->
            <div class="ag-actions">
              <el-button size="mini" type="primary" icon="el-icon-chat-dot-round" @click="testChat(ag)">测试对话</el-button>
              <el-button size="mini" icon="el-icon-view" @click="openDetail(ag)">详情</el-button>
              <el-button v-permission="'ai:agent:edit'" size="mini" icon="el-icon-edit" @click="openEdit(ag)">编辑</el-button>
              <el-button size="mini" icon="el-icon-copy-document" @click="copyAgent(ag)">复制</el-button>
              <el-button size="mini" :type="ag.status === 1 ? 'warning' : 'success'" @click="toggleStatus(ag)">
                {{ ag.status === 1 ? '停用' : '启用' }}
              </el-button>
              <el-button v-if="ag.is_system !== 1" size="mini" type="danger" icon="el-icon-delete" @click="removeAgent(ag)">删除</el-button>
            </div>
          </el-card>
        </el-col>
      </el-row>

      <!-- 分页 -->
      <div class="pager">
        <el-pagination background layout="total, sizes, prev, pager, next" :total="total"
          :page-size="limit" :page-sizes="[6, 12, 24]" :current-page="page"
          @size-change="p => { limit = p; page = 1; loadList() }"
          @current-change="p => { page = p; loadList() }" />
      </div>
    </el-card>

    <!-- 智能体详情弹窗 -->
    <el-dialog title="智能体详情" :visible.sync="detailVisible" width="750px" top="5vh">
      <div v-if="detail">
        <el-descriptions :column="2" size="small" border>
          <el-descriptions-item label="名称">{{ detail.agent_name }}</el-descriptions-item>
          <el-descriptions-item label="类型">
            <el-tag size="mini" :type="detail.is_system === 1 ? 'primary' : 'info'">{{ detail.is_system === 1 ? '系统' : '自定义' }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag size="mini" :type="detail.status === 1 ? 'success' : 'info'">{{ detail.status === 1 ? '启用' : '停用' }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="关联模型">{{ detail.model_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建人">{{ detail.created_by_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ detail.create_time }}</el-descriptions-item>
          <el-descriptions-item label="描述" :span="2">{{ detail.description || '-' }}</el-descriptions-item>
        </el-descriptions>
        <div class="detail-block">
          <div class="detail-label">人设（系统提示词）</div>
          <pre class="prompt-pre">{{ detail.system_prompt }}</pre>
        </div>
        <div class="detail-block">
          <div class="detail-label">绑定知识库（{{ (detail.knowledge_bases || []).length }}）</div>
          <div v-if="detail.knowledge_bases && detail.knowledge_bases.length" class="tag-wrap">
            <el-tag v-for="kb in detail.knowledge_bases" :key="kb.id" size="small" class="kb-tag">{{ kb.kb_name }}</el-tag>
          </div>
          <span v-else class="no-data">未绑定知识库</span>
        </div>
        <div class="detail-block">
          <div class="detail-label">绑定工具（{{ (detail.tools || []).length }}）</div>
          <div v-if="detail.tools && detail.tools.length" class="tag-wrap">
            <el-tag v-for="t in detail.tools" :key="t.id" size="small" type="success" class="kb-tag">{{ t.tool_display_name || t.tool_name }}</el-tag>
          </div>
          <span v-else class="no-data">未绑定工具</span>
        </div>
      </div>
    </el-dialog>

    <!-- 创建/编辑智能体弹窗（组件：AgentFormDialog） -->
    <agent-form-dialog :visible="formVisible" :agent-id="editAgentId"
      @update:visible="v => formVisible = v" @saved="handleSaved" />
  </div>
</template>

<script>
import AgentFormDialog from './components/AgentFormDialog.vue'
import {
  getAiAgentList, getAiAgentDetail, deleteAiAgent,
  toggleAiAgentStatus, copyAiAgent, getAiAgentStats
} from '@/api/aiAgent'

export default {
  name: 'AiAgentList',
  components: { AgentFormDialog },
  data () {
    return {
      stats: { agent_total: 0, agent_enabled: 0, agent_system: 0, agent_custom: 0 },
      filters: { keyword: '', status: '', is_system: '' },
      dateRange: [],
      list: [], total: 0, page: 1, limit: 12, loading: false,
      promptOpen: [],
      // 详情
      detailVisible: false, detail: null,
      // 创建/编辑（AgentFormDialog 组件）
      formVisible: false,
      editAgentId: 0
    }
  },
  computed: {
    statCards () {
      const s = this.stats
      return [
        { key: 'total', label: '智能体总数', value: s.agent_total || 0, icon: 'el-icon-user', cls: 'stat-blue' },
        { key: 'enabled', label: '已启用数', value: s.agent_enabled || 0, icon: 'el-icon-check', cls: 'stat-green', onClick: () => this.quickFilter('1') },
        { key: 'system', label: '系统智能体', value: s.agent_system || 0, icon: 'el-icon-star-on', cls: 'stat-gold', onClick: () => this.quickFilterSystem('1') },
        { key: 'custom', label: '自定义智能体', value: s.agent_custom || 0, icon: 'el-icon-edit-outline', cls: 'stat-purple', onClick: () => this.quickFilterSystem('0') }
      ]
    }
  },
  created () {
    this.loadStats()
    this.loadList()
  },
  methods: {
    truncate (s, n) {
      if (!s) return ''
      return s.length > n ? s.slice(0, n) + '...' : s
    },
    /** 智能体头像：agent_icon 为图标类名时渲染图标，为 http 时渲染图片，否则默认图标 */
    agentIcon (ag) {
      const icon = ag.agent_icon || ''
      if (icon && icon.startsWith('el-icon-')) return icon
      return 'el-icon-user'
    },
    agentIconIsImage (ag) {
      const icon = ag.agent_icon || ''
      return icon.startsWith('http://') || icon.startsWith('https://')
    },
    // ---- 数据加载 ----
    async loadStats () {
      try {
        const r = await getAiAgentStats()
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
          is_system: this.filters.is_system || undefined
        }
        if (this.dateRange && this.dateRange.length === 2) {
          params.start_date = this.dateRange[0]
          params.end_date = this.dateRange[1]
        }
        const r = await getAiAgentList(params)
        if (r.code === 0) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
        }
      } catch (e) {} finally { this.loading = false }
    },
    loadAll () { this.page = 1; this.loadList(); this.loadStats() },
    handleSearch () { this.page = 1; this.loadList() },
    handleReset () {
      this.filters = { keyword: '', status: '', is_system: '' }
      this.dateRange = []
      this.handleSearch()
    },
    quickFilter (status) { this.filters.status = status; this.handleSearch() },
    quickFilterSystem (v) { this.filters.is_system = v; this.handleSearch() },
    // ---- 详情 ----
    async openDetail (ag) {
      try {
        const r = await getAiAgentDetail(ag.id)
        if (r.code === 0) { this.detail = r.data; this.detailVisible = true }
      } catch (e) {}
    },
    // ---- 创建/编辑（AgentFormDialog） ----
    openCreate () {
      this.editAgentId = 0
      this.formVisible = true
    },
    openEdit (ag) {
      this.editAgentId = ag.id
      this.formVisible = true
    },
    handleSaved () {
      this.loadAll()
    },
    // ---- 操作 ----
    async toggleStatus (ag) {
      const action = ag.status === 1 ? '停用' : '启用'
      const c = await this.$confirm(`确认${action}智能体 [${ag.agent_name}] 吗？`, '提示', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const r = await toggleAiAgentStatus(ag.id, ag.status === 1 ? 0 : 1)
        if (r.code === 0) { this.$message.success('已' + action); this.loadAll() }
      } catch (e) {}
    },
    async copyAgent (ag) {
      const c = await this.$confirm(`确认复制智能体 [${ag.agent_name}] 吗？`, '复制确认', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const r = await copyAiAgent(ag.id)
        if (r.code === 0) { this.$message.success('复制成功'); this.loadAll() }
      } catch (e) {}
    },
    async removeAgent (ag) {
      const c = await this.$confirm(`确定要删除智能体 [${ag.agent_name}] 吗？删除后不可恢复`, '删除确认', { type: 'warning' }).catch(() => false)
      if (!c) return
      try {
        const r = await deleteAiAgent(ag.id)
        if (r.code === 0) { this.$message.success('删除成功'); this.loadAll() }
      } catch (e) {}
    },
    testChat (ag) {
      this.$router.push({ path: '/ai/chat/create', query: { agent_id: ag.agent_id } })
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
.stat-gold .stat-icon { color: #E6A23C; }
.stat-purple .stat-icon { color: #9B59B6; }
.filter-form { margin-bottom: 8px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.toolbar-tip { font-size: 13px; color: #909399; }
.card-row { margin: 0 -8px; }
.ag-col { padding: 0 8px; margin-bottom: 16px; }
.ag-head { display: flex; justify-content: space-between; align-items: center; }
.ag-name-wrap { display: flex; align-items: center; gap: 6px; min-width: 0; }
.ag-icon { font-size: 20px; color: #409EFF; flex-shrink: 0; }
.ag-icon-img { width: 24px; height: 24px; border-radius: 50%; object-fit: cover; }
.ag-name { font-size: 14px; font-weight: 600; color: #303133; cursor: pointer; max-width: 160px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.ag-name:hover { color: #409EFF; }
.ag-tags { display: flex; gap: 4px; }
.ag-desc { font-size: 12px; color: #909399; min-height: 34px; line-height: 1.6; margin-bottom: 8px; overflow: hidden; text-overflow: ellipsis; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; }
.ag-meta { display: flex; justify-content: space-between; font-size: 12px; color: #606266; margin-bottom: 4px; }
.ag-prompt { margin-top: 6px; }
.prompt-body { font-size: 12px; color: #909399; line-height: 1.6; white-space: pre-wrap; word-break: break-word; }
.ag-actions { margin-top: 10px; text-align: right; }
.pager { margin-top: 12px; text-align: right; }
.detail-block { margin-top: 14px; }
.detail-label { font-size: 13px; font-weight: 600; color: #909399; margin-bottom: 6px; }
.prompt-pre { background: #f8f9fb; border-radius: 6px; padding: 10px; font-size: 12px; overflow-x: auto; white-space: pre-wrap; word-break: break-word; max-height: 220px; }
.tag-wrap { display: flex; flex-wrap: wrap; gap: 6px; }
.kb-tag { margin: 0; }
.no-data { font-size: 12px; color: #c0c4cc; }
</style>
