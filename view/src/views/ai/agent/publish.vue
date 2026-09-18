<template>
  <div class="ai-publish-page">
    <el-tabs v-model="activeTab" type="border-card">
      <!-- ==================== Tab1 发布管理 ==================== -->
      <el-tab-pane label="发布管理" name="overview">
        <!-- 当前版本信息卡片 -->
        <el-card shadow="never" class="current-card">
          <div class="current-head">
            <span class="cur-title">当前版本</span>
            <el-tag v-if="currentVersion" size="small" :type="statusType(currentVersion.status)">{{ currentVersion.status_text }}</el-tag>
          </div>
          <div v-if="currentVersion" class="cur-info">
            <span>版本号：<b>{{ currentVersion.version_number }}</b></span>
            <span v-if="currentVersion.published_at">发布时间：{{ currentVersion.published_at }}</span>
            <span v-if="currentVersion.published_by_name">发布人：{{ currentVersion.published_by_name }}</span>
            <span v-if="currentVersion.publish_type">类型：{{ currentVersion.publish_type === 'gray' ? '灰度发布' : '全量发布' }}</span>
          </div>
          <el-empty v-if="!currentVersion" description="暂无发布版本，请先在「版本管理」创建版本" :image-size="60" />
        </el-card>

        <!-- 发布流程步骤条 -->
        <el-card shadow="never" class="flow-card">
          <el-steps :active="flowStep" align-center finish-status="success" process-status="finish">
            <el-step title="创建版本" description="草稿" />
            <el-step title="提交审核" description="审核中" />
            <el-step title="安全扫描" description="自动完成" />
            <el-step title="人工审核" description="待审批" />
            <el-step title="发布上线" description="已发布" />
          </el-steps>
        </el-card>

        <!-- 操作区域 -->
        <el-card shadow="never" class="action-card">
          <div class="sec-title">操作</div>
          <template v-if="!currentVersion || currentVersion.status === 'offline'">
            <el-button type="primary" size="small" icon="el-icon-plus" @click="$refs.createDialog.open()">创建版本</el-button>
          </template>
          <template v-else-if="currentVersion.status === 'draft'">
            <el-button type="primary" size="small" @click="$refs.editDialog.open(currentVersion)">编辑</el-button>
            <el-button type="warning" size="small" @click="submitCurrent">提交审核</el-button>
          </template>
          <template v-else-if="currentVersion.status === 'reviewing'">
            <el-alert title="版本正在审核中，审核通过后可执行发布" type="info" :closable="false" show-icon />
          </template>
          <template v-else-if="currentVersion.status === 'approved'">
            <el-button type="success" size="small" icon="el-icon-upload" @click="executeCurrent">执行发布</el-button>
          </template>
          <template v-else-if="currentVersion.status === 'published'">
            <el-button type="danger" size="small" @click="offlineCurrent">下线</el-button>
            <el-button type="warning" size="small" @click="rollbackPrompt">回滚</el-button>
            <el-button v-if="currentVersion.publish_type === 'gray'" type="success" size="small" @click="promoteCurrent">灰度推广</el-button>
          </template>
        </el-card>
      </el-tab-pane>

      <!-- ==================== Tab2 版本管理 ==================== -->
      <el-tab-pane label="版本管理" name="versions">
        <div class="filter-bar">
          <el-select v-model="versionFilter.status" placeholder="状态筛选" clearable size="small" style="width: 130px;" @change="p => { versionPage = 1; loadVersions() }">
            <el-option v-for="(v, k) in statusMap" :key="k" :label="v" :value="k" />
          </el-select>
          <el-input v-model="versionFilter.keyword" placeholder="版本号/名称搜索" size="small" clearable style="width: 180px; margin-left: 10px;" @keyup.enter.native="p => { versionPage = 1; loadVersions() }" @clear="p => { versionPage = 1; loadVersions() }" />
          <span class="flex-1"></span>
          <el-button size="small" type="primary" icon="el-icon-plus" @click="$refs.createDialog.open()">创建版本</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadVersions">刷新</el-button>
        </div>

        <el-table :data="versionList" size="small" stripe v-loading="versionLoading">
          <el-table-column prop="version_number" label="版本号" width="90" />
          <el-table-column prop="version_name" label="版本名称" min-width="120" show-overflow-tooltip>
            <template slot-scope="s">{{ s.row.version_name || '--' }}</template>
          </el-table-column>
          <el-table-column label="发布类型" width="90">
            <template slot-scope="s">{{ s.row.publish_type_text }}</template>
          </el-table-column>
          <el-table-column prop="create_time" label="创建时间" width="165" />
          <el-table-column label="状态" width="90">
            <template slot-scope="s">
              <el-tag size="mini" :type="statusType(s.row.status)">{{ s.row.status_text }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="200" align="center">
            <template slot-scope="s">
              <el-button type="text" size="mini" @click="$refs.detailDialog.open(s.row.id)">详情</el-button>
              <el-button type="text" size="mini" @click="openCompare(s.row)">对比</el-button>
              <el-button v-if="s.row.status !== 'draft'" type="text" size="mini" @click="rollbackVersion(s.row)">回滚</el-button>
              <el-button v-if="s.row.status === 'draft'" type="text" size="mini" class="danger" @click="deleteVersion(s.row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
        <el-pagination class="pager" small background layout="total, prev, pager, next" :total="versionTotal" :page-size="versionPageSize" :current-page="versionPage" @current-change="p => { versionPage = p; loadVersions() }" />
      </el-tab-pane>

      <!-- ==================== Tab3 渠道管理 ==================== -->
      <el-tab-pane label="渠道管理" name="channels">
        <el-row :gutter="14">
          <el-col v-for="ch in channelList" :key="ch.channel_type" :span="8" style="margin-bottom: 14px;">
            <el-card shadow="never" :class="['ch-card', 'ch-' + ch.status]">
              <div class="ch-head">
                <span class="ch-name">{{ ch.channel_name }}</span>
                <el-tag size="mini" :type="chStatusType(ch.status)">{{ ch.status_text }}</el-tag>
              </div>
              <div class="ch-desc">{{ ch.channel_type === 'webapi' ? '标准 API 接口调用' : (ch.channel_type === 'webembed' ? '嵌入企业网站/内部系统' : '接入' + ch.channel_name + ' 平台') }}</div>
              <div class="ch-actions">
                <el-button size="mini" type="primary" plain @click="$refs.channelDialog.open(ch)">配置</el-button>
                <el-button size="mini" @click="testChannel(ch)">测试</el-button>
                <el-button v-if="ch.status !== 'unconfigured'" size="mini" :type="ch.enabled ? 'warning' : 'success'" plain @click="toggleChannel(ch)">
                  {{ ch.enabled ? '停用' : '启用' }}
                </el-button>
              </div>
            </el-card>
          </el-col>
        </el-row>
      </el-tab-pane>

      <!-- ==================== Tab4 发布统计 ==================== -->
      <el-tab-pane label="发布统计" name="stats">
        <el-row :gutter="14" class="stat-row">
          <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num">{{ stats.total_publishes || 0 }}</div><div class="stat-label">总发布次数</div></el-card></el-col>
          <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num">{{ stats.current_version || '--' }}</div><div class="stat-label">当前版本</div></el-card></el-col>
          <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num success">{{ stats.publish_success_rate || 0 }}%</div><div class="stat-label">发布成功率</div></el-card></el-col>
          <el-col :span="6"><el-card shadow="never" class="stat-card"><div class="stat-num">{{ channelTotalCalls }}</div><div class="stat-label">渠道调用总数</div></el-card></el-col>
        </el-row>

        <el-card shadow="never" class="chart-card">
          <div class="sec-title">渠道调用统计</div>
          <el-table :data="stats.channel_stats || []" size="small" stripe>
            <el-table-column prop="channel_name" label="渠道" width="120" />
            <el-table-column prop="call_count" label="调用次数" width="100" />
            <el-table-column prop="success_rate" label="成功率" width="100">
              <template slot-scope="s">{{ s.row.success_rate }}%</template>
            </el-table-column>
            <el-table-column prop="avg_response_time" label="平均响应(ms)" width="120" />
          </el-table>
        </el-card>

        <el-card shadow="never" class="chart-card">
          <div class="sec-title">发布历史（近10次）</div>
          <el-table :data="stats.history || []" size="small" stripe>
            <el-table-column prop="version_number" label="版本号" width="90" />
            <el-table-column prop="version_name" label="版本名称" min-width="120" show-overflow-tooltip />
            <el-table-column label="状态" width="90">
              <template slot-scope="s">
                <el-tag size="mini" :type="statusType(s.row.status)">{{ statusMap[s.row.status] || s.row.status }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="published_by_name" label="发布人" width="100" />
            <el-table-column prop="published_at" label="发布时间" width="165" />
          </el-table>
        </el-card>
      </el-tab-pane>
    </el-tabs>

    <!-- 弹窗 -->
    <VersionCreateDialog ref="createDialog" :agent-id="agentId" @saved="reloadAll" />
    <VersionEditDialog ref="editDialog" @saved="reloadAll" />
    <VersionDetailDialog ref="detailDialog" />
    <VersionCompareDialog ref="compareDialog" />
    <ChannelConfigDialog ref="channelDialog" :agent-id="agentId" @saved="loadChannels" />
  </div>
</template>

<script>
import {
  getPublishVersions, getPublishStatistics, getPublishChannels, deletePublishVersion,
  submitPublish, executePublish, offlinePublish, promotePublish, rollbackPublishVersion,
  testPublishChannel, updateChannelStatus
} from '../../../api/aiPublish'
import { getAiAgentOptions } from '../../../api/aiAgent'
import VersionCreateDialog from './components/VersionCreateDialog.vue'
import VersionEditDialog from './components/VersionEditDialog.vue'
import VersionDetailDialog from './components/VersionDetailDialog.vue'
import VersionCompareDialog from './components/VersionCompareDialog.vue'
import ChannelConfigDialog from './components/ChannelConfigDialog.vue'

export default {
  name: 'AiAgentPublish',
  components: { VersionCreateDialog, VersionEditDialog, VersionDetailDialog, VersionCompareDialog, ChannelConfigDialog },
  data() {
    return {
      activeTab: 'overview',
      agentId: this.$route.query.agent_id || '',
      agent: null,
      // 版本
      versionLoading: false, versionList: [], versionTotal: 0, versionPage: 1, versionPageSize: 20,
      versionFilter: { status: '', keyword: '' },
      currentVersion: null,
      // 渠道
      channelList: [],
      // 统计
      stats: {},
      statusMap: { draft: '草稿', reviewing: '审核中', approved: '审核通过', published: '已发布', offline: '已下线' }
    }
  },
  computed: {
    channelTotalCalls() {
      return (this.stats.channel_stats || []).reduce((s, c) => s + (c.call_count || 0), 0)
    },
    flowStep() {
      if (!this.currentVersion) return 0
      const map = { draft: 0, reviewing: 2, approved: 3, published: 4, offline: 0 }
      return map[this.currentVersion.status] ?? 0
    }
  },
  created() {
    this.loadAgent()
    this.reloadAll()
  },
  methods: {
    async loadAgent() {
      if (!this.agentId) return
      try {
        const res = await getAiAgentOptions()
        this.agent = (res.data || []).find(a => a.agent_id === this.agentId) || null
      } catch (e) {}
    },
    reloadAll() {
      this.loadVersions()
      this.loadChannels()
      this.loadStats()
    },
    async loadVersions() {
      if (!this.agentId) return
      this.versionLoading = true
      try {
        const params = { agent_id: this.agentId, page: this.versionPage, limit: this.versionPageSize }
        if (this.versionFilter.status) params.status = this.versionFilter.status
        if (this.versionFilter.keyword) params.keyword = this.versionFilter.keyword
        const res = await getPublishVersions(params)
        this.versionList = res.data.list || []
        this.versionTotal = res.data.total || 0
        // 当前版本
        const cur = this.versionList.find(v => v.is_current === 1) || this.versionList.find(v => v.status === 'published') || null
        this.currentVersion = cur || this.versionList[0] || null
      } catch (e) {}
      this.versionLoading = false
    },
    async loadChannels() {
      if (!this.agentId) return
      try {
        const res = await getPublishChannels({ agent_id: this.agentId })
        this.channelList = res.data.list || []
      } catch (e) {}
    },
    async loadStats() {
      if (!this.agentId) return
      try {
        const res = await getPublishStatistics({ agent_id: this.agentId })
        this.stats = res.data || {}
      } catch (e) {}
    },
    // ===== 发布操作 =====
    async submitCurrent() {
      this.$confirm('提交当前版本进入审核流程？将自动进行安全扫描。', '提交审核', { type: 'warning' }).then(async () => {
        try {
          const res = await submitPublish({ version_id: this.currentVersion.version_id })
          this.$message.success(res.msg || '已提交审核')
          this.reloadAll()
        } catch (e) {}
      }).catch(() => {})
    },
    async executeCurrent() {
      this.$confirm('确认将当前版本发布到生产环境？', '执行发布', { type: 'warning' }).then(async () => {
        try {
          const res = await executePublish(this.currentVersion.id)
          this.$message.success(res.msg || '发布成功')
          this.reloadAll()
        } catch (e) {}
      }).catch(() => {})
    },
    async offlineCurrent() {
      this.$confirm('确认将当前版本下线？下线后用户将无法访问。', '下线', { type: 'warning' }).then(async () => {
        try {
          const res = await offlinePublish(this.currentVersion.id)
          this.$message.success(res.msg || '已下线')
          this.reloadAll()
        } catch (e) {}
      }).catch(() => {})
    },
    async promoteCurrent() {
      this.$confirm('灰度验证通过，确认全量发布？', '灰度推广', { type: 'warning' }).then(async () => {
        try {
          const res = await promotePublish(this.currentVersion.id)
          this.$message.success(res.msg || '已全量发布')
          this.reloadAll()
        } catch (e) {}
      }).catch(() => {})
    },
    rollbackPrompt() {
      this.$confirm('回滚将恢复智能体配置为指定版本，并生成新草稿版本，需重新审核发布。', '版本回滚', { type: 'warning' }).then(() => {
        this.$refs.compareDialog.open(null, true)
      }).catch(() => {})
    },
    async rollbackVersion(row) {
      this.$confirm(`确认回滚到版本 ${row.version_number}？将恢复配置并生成新版本。`, '版本回滚', { type: 'warning' }).then(async () => {
        try {
          const res = await rollbackPublishVersion(row.id)
          this.$message.success(res.msg || '回滚成功')
          this.reloadAll()
        } catch (e) {}
      }).catch(() => {})
    },
    deleteVersion(row) {
      this.$confirm(`确定删除版本 ${row.version_number}？`, '提示', { type: 'warning' }).then(async () => {
        try { await deletePublishVersion(row.id); this.$message.success('已删除'); this.reloadAll() } catch (e) {}
      }).catch(() => {})
    },
    // ===== 渠道 =====
    async testChannel(ch) {
      try {
        const res = await testPublishChannel({ agent_id: this.agentId, channel_type: ch.channel_type })
        this.$message[res.data && res.data.ok ? 'success' : 'warning'](res.data && res.data.message || res.msg)
      } catch (e) {}
    },
    async toggleChannel(ch) {
      try {
        const res = await updateChannelStatus(0, { agent_id: this.agentId, channel_type: ch.channel_type, status: ch.enabled ? 0 : 1 })
        this.$message.success(res.msg || '操作成功')
        this.loadChannels()
      } catch (e) {}
    },
    openCompare(row) {
      this.$refs.compareDialog.open(row)
    },
    // ===== 辅助 =====
    statusType(st) { return { draft: 'info', reviewing: 'warning', approved: 'success', published: 'primary', offline: 'danger' }[st] || 'info' },
    chStatusType(st) { return { unconfigured: 'info', configured: 'warning', enabled: 'success' }[st] || 'info' }
  }
}
</script>

<style scoped>
.ai-publish-page { padding: 4px 16px; }
.current-card, .flow-card, .action-card { margin-bottom: 14px; }
.current-head { display: flex; align-items: center; margin-bottom: 8px; }
.cur-title { font-weight: 600; margin-right: 10px; }
.cur-info { display: flex; gap: 20px; color: #606266; font-size: 13px; flex-wrap: wrap; }
.sec-title { font-weight: 600; margin-bottom: 10px; }
.filter-bar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.pager { margin-top: 10px; text-align: right; }
.ch-card { border-top: 3px solid #909399; }
.ch-card.ch-unconfigured { border-top-color: #909399; }
.ch-card.ch-configured { border-top-color: #e6a23c; }
.ch-card.ch-enabled { border-top-color: #67c23a; }
.ch-head { display: flex; align-items: center; justify-content: space-between; }
.ch-name { font-weight: 600; }
.ch-desc { color: #909399; font-size: 12px; margin: 8px 0; }
.ch-actions { text-align: right; }
.stat-row { margin-bottom: 14px; }
.stat-card { text-align: center; }
.stat-num { font-size: 26px; font-weight: 700; }
.stat-num.success { color: #67c23a; }
.stat-label { color: #909399; font-size: 12px; margin-top: 2px; }
.chart-card { margin-bottom: 14px; }
</style>
