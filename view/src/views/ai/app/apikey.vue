<!-- 文件：admin/src/views/ai/app/apikey.vue -->
<!-- API 密钥管理：统计卡片 / 筛选 / 表格 / 生成弹窗 / 查看详情 -->
<template>
  <div class="apikey-page">
    <!-- 统计卡片（4 个） -->
    <el-row :gutter="12" class="stat-row">
      <el-col :span="6">
        <div class="stat-card clickable" @click="quickFilter('total')">
          <div class="stat-icon" style="background:#409EFF1a;color:#409EFF;"><i class="el-icon-key"></i></div>
          <div class="stat-body"><div class="stat-value">{{ stats.total }}</div><div class="stat-label">密钥总数</div></div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card clickable" @click="quickFilter('enabled')">
          <div class="stat-icon" style="background:#67C23A1a;color:#67C23A;"><i class="el-icon-check"></i></div>
          <div class="stat-body"><div class="stat-value">{{ stats.enabled }}</div><div class="stat-label">已启用数</div></div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card">
          <div class="stat-icon" style="background:#E6A23C1a;color:#E6A23C;"><i class="el-icon-date"></i></div>
          <div class="stat-body"><div class="stat-value">{{ stats.today_calls }}</div><div class="stat-label">今日调用数</div></div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card">
          <div class="stat-icon" style="background:#8E44AD1a;color:#8E44AD;"><i class="el-icon-data-line"></i></div>
          <div class="stat-body"><div class="stat-value">{{ stats.total_calls }}</div><div class="stat-label">总调用数</div></div>
        </div>
      </el-col>
    </el-row>

    <!-- 筛选 -->
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入密钥名称" clearable style="width:200px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.app_id" placeholder="全部应用" clearable filterable style="width:180px" @change="onSearch">
            <el-option v-for="a in appOptions" :key="a.id" :label="a.app_name" :value="a.app_id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" placeholder="全部状态" clearable style="width:120px" @change="onSearch">
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
            <el-option label="已过期" value="expired" />
          </el-select>
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
        <span>共 <b>{{ total }}</b> 个密钥</span>
        <div>
          <el-button v-if="hasPerm('ai:app:apikey:add')" size="small" type="primary" icon="el-icon-plus" @click="generateVisible = true">生成密钥</el-button>
          <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadAll">刷新</el-button>
        </div>
      </div>

      <!-- 表格 -->
      <el-table :data="list" v-loading="loading" size="small" stripe>
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column prop="key_name" label="密钥名称" min-width="120" show-overflow-tooltip />
        <el-table-column prop="app_name" label="所属应用" min-width="140" show-overflow-tooltip />
        <el-table-column label="密钥前缀" width="150" show-overflow-tooltip>
          <template slot-scope="{ row }"><code class="key-prefix">{{ row.key_prefix }}</code></template>
        </el-table-column>
        <el-table-column label="状态" width="100" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="statusTag(row)">{{ statusText(row) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="call_count" label="调用次数" width="90" align="center" />
        <el-table-column prop="last_call_time" label="最后调用时间" width="160">
          <template slot-scope="{ row }">{{ row.last_call_time || '-' }}</template>
        </el-table-column>
        <el-table-column prop="create_time" label="创建时间" width="160" />
        <el-table-column label="操作" width="280" align="center" fixed="right">
          <template slot-scope="{ row }">
            <el-button type="text" size="mini" @click="openDetail(row)">查看</el-button>
            <el-button type="text" size="mini" @click="copyKey(row)">复制</el-button>
            <el-button v-if="hasPerm('ai:app:apikey:edit')" type="text" size="mini"
              :style="{ color: row.status === 1 && !row.is_expired ? '#E6A23C' : '#67C23A' }"
              @click="doToggleStatus(row)">{{ row.status === 1 && !row.is_expired ? '停用' : '启用' }}</el-button>
            <el-button v-if="hasPerm('ai:app:apikey:edit')" type="text" size="mini" @click="doRefresh(row)">刷新</el-button>
            <el-button v-if="hasPerm('ai:app:apikey:delete')" type="text" size="mini" style="color:#F56C6C;" @click="doDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination class="pager" background layout="total, sizes, prev, pager, next" :total="total"
        :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50]"
        @size-change="s => { limit = s; page = 1; loadAll() }"
        @current-change="p => { page = p; loadAll() }" />
    </el-card>

    <!-- 生成密钥弹窗 -->
    <api-key-generate-dialog v-if="generateVisible" :visible.sync="generateVisible" :app-options="appOptions"
      @success="onGenerated" />

    <!-- 查看密钥详情弹窗 -->
    <el-dialog title="密钥详情" :visible.sync="detailVisible" width="650px" top="5vh">
      <div v-if="detail.id" v-loading="detailLoading">
        <el-descriptions :column="2" size="small" border>
          <el-descriptions-item label="密钥名称">{{ detail.key_name }}</el-descriptions-item>
          <el-descriptions-item label="所属应用">{{ detail.app_name }}</el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag size="mini" :type="statusTag(detail)">{{ statusText(detail) }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="过期时间">{{ detail.key_expire || '永不过期' }}</el-descriptions-item>
          <el-descriptions-item label="调用次数">{{ detail.call_count || 0 }}</el-descriptions-item>
          <el-descriptions-item label="最后调用时间">{{ detail.last_call_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="最后调用IP">{{ detail.last_call_ip || '-' }}</el-descriptions-item>
        </el-descriptions>

        <!-- 密钥值（脱敏/显示明文） -->
        <div class="sec-title">密钥值</div>
        <div class="key-box">
          <code class="key-full">{{ showPlain ? plainKey : detail.key_prefix }}</code>
          <el-button v-if="hasPerm('ai:app:apikey:view')" size="mini" @click="toggleReveal">{{ showPlain ? '隐藏' : '显示完整密钥' }}</el-button>
          <el-button size="mini" icon="el-icon-document-copy" @click="copyPlain">复制</el-button>
        </div>
        <div class="key-warn" v-if="showPlain">密钥仅显示一次，请妥善保存。</div>

        <!-- IP白名单 -->
        <div v-if="detail.ip_whitelist && detail.ip_whitelist.length" class="sec-title">IP白名单</div>
        <div v-if="detail.ip_whitelist && detail.ip_whitelist.length" class="ip-list">
          <el-tag v-for="ip in detail.ip_whitelist" :key="ip" size="mini">{{ ip }}</el-tag>
        </div>

        <!-- 调用趋势（占位） -->
        <div class="sec-title">调用趋势（近30天）</div>
        <div class="cfg-none">调用日志表待建设，趋势数据暂不可用。</div>

        <!-- 最近调用记录（占位） -->
        <div class="sec-title">最近调用记录</div>
        <div class="cfg-none">（调用日志表待建设，暂无调用记录）</div>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getApiKeyList, getApiKeyDetail, getApiKeyStatistics, deleteApiKey, updateApiKeyStatus, refreshApiKey, revealApiKey } from '@/api/aiApiKey'
import { getAppOptions } from '@/api/aiApp'
import ApiKeyGenerateDialog from './components/ApiKeyGenerateDialog.vue'

export default {
  name: 'AiApiKeyList',
  components: { ApiKeyGenerateDialog },
  data () {
    return {
      list: [], total: 0, page: 1, limit: 20, loading: false,
      appOptions: [],
      stats: { total: 0, enabled: 0, today_calls: 0, total_calls: 0 },
      filters: { keyword: '', app_id: '', status: '' },
      generateVisible: false,
      detailVisible: false, detail: {}, detailLoading: false, showPlain: false, plainKey: ''
    }
  },
  created () { this.loadAppOptions(); this.loadAll(); this.loadStats() },
  methods: {
    hasPerm (code) {
      const u = this.$store.state.user.userInfo || {}
      const p = this.$store.state.user.permissions || []
      if (u.is_super_admin || p.indexOf('super_admin') > -1) return true
      return p.indexOf(code) > -1
    },
    async loadAppOptions () {
      try { const r = await getAppOptions(); if (r.code === 0) this.appOptions = r.data || [] } catch (e) {}
    },
    buildParams () {
      const p = { page: this.page, limit: this.limit }
      if (this.filters.keyword) p.keyword = this.filters.keyword
      if (this.filters.app_id) p.app_id = this.filters.app_id
      if (this.filters.status === 'expired') { /* 前端过滤过期 */ } else if (this.filters.status !== '') p.status = this.filters.status
      return p
    },
    async loadAll () {
      this.loading = true
      try {
        const r = await getApiKeyList(this.buildParams())
        if (r.code === 0) {
          let list = r.data.list || []
          if (this.filters.status === 'expired') list = list.filter(k => k.is_expired)
          this.list = list
          this.total = r.data.total || 0
        }
      } catch (e) {} finally { this.loading = false }
    },
    async loadStats () {
      try { const r = await getApiKeyStatistics(); if (r.code === 0) this.stats = r.data || this.stats } catch (e) {}
    },
    onSearch () { this.page = 1; this.loadAll() },
    resetFilter () { this.filters = { keyword: '', app_id: '', status: '' }; this.page = 1; this.loadAll() },
    quickFilter (key) {
      this.filters.status = key === 'total' ? '' : key
      this.page = 1; this.loadAll()
    },
    onGenerated () { this.generateVisible = false; this.loadAll(); this.loadStats() },
    // 查看详情
    async openDetail (row) {
      this.detailVisible = true
      this.detail = {}; this.showPlain = false; this.plainKey = ''
      this.detailLoading = true
      try { const r = await getApiKeyDetail(row.id); if (r.code === 0) this.detail = r.data || {} } catch (e) {} finally { this.detailLoading = false }
    },
    // 显示/隐藏明文
    async toggleReveal () {
      if (this.showPlain) { this.showPlain = false; this.plainKey = ''; return }
      try {
        const r = await revealApiKey(this.detail.key_id)
        if (r.code === 0) { this.plainKey = r.data.api_key || ''; this.showPlain = true }
      } catch (e) {}
    },
    copyPlain () {
      if (!this.plainKey) { this.$message.warning('请先显示完整密钥'); return }
      this.copyText(this.plainKey)
      this.$message.success('密钥已复制，请妥善保存')
    },
    copyKey (row) {
      this.copyText(row.key_prefix)
      this.$message.success('密钥前缀已复制')
    },
    copyText (text) {
      const ta = document.createElement('textarea')
      ta.value = text; document.body.appendChild(ta); ta.select()
      document.execCommand('copy'); document.body.removeChild(ta)
    },
    doToggleStatus (row) {
      const next = row.status === 1 && !row.is_expired ? 0 : 1
      const text = next === 1 ? '启用' : '停用'
      this.$confirm(`确认${text}密钥 [${row.key_name}] 吗？`, `${text}确认`, { type: 'warning' })
        .then(async () => {
          try { const r = await updateApiKeyStatus(row.id, next); if (r.code === 0) { this.$message.success('状态已更新'); this.loadAll(); this.loadStats() } } catch (e) {}
        }).catch(() => {})
    },
    doRefresh (row) {
      this.$confirm(`确认刷新密钥 [${row.key_name}] 吗？刷新后旧密钥将立即失效，新密钥将生成`, '刷新确认', { type: 'warning' })
        .then(async () => {
          try {
            const r = await refreshApiKey(row.id)
            if (r.code === 0) {
              this.$alert('新密钥：<br><code style="font-size:14px;">' + (r.data.api_key || '') + '</code><br>密钥仅显示一次，请妥善保存', '密钥已刷新', { dangerouslyUseHTMLString: true })
              this.loadAll(); this.loadStats()
            }
          } catch (e) {}
        }).catch(() => {})
    },
    doDelete (row) {
      this.$confirm(`确定要删除密钥 [${row.key_name}] 吗？删除后该密钥将立即失效，不可恢复`, '删除确认', { type: 'warning' })
        .then(async () => {
          try { const r = await deleteApiKey(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadAll(); this.loadStats() } } catch (e) {}
        }).catch(() => {})
    },
    statusTag (row) {
      if (row.is_expired) return 'danger'
      return row.status === 1 ? 'success' : 'info'
    },
    statusText (row) {
      if (row.is_expired) return '已过期'
      return row.status === 1 ? '启用' : '停用'
    }
  }
}
</script>

<style scoped>
.apikey-page { padding: 16px; }
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
.key-prefix { font-size: 12px; background: #f5f7fa; padding: 2px 6px; border-radius: 4px; }
.sec-title { font-size: 13px; font-weight: 600; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; margin: 14px 0 8px; }
.key-box { display: flex; align-items: center; gap: 10px; background: #f5f7fa; border-radius: 6px; padding: 10px 12px; }
.key-full { font-size: 13px; word-break: break-all; flex: 1; }
.key-warn { font-size: 12px; color: #E6A23C; margin-top: 6px; }
.ip-list { display: flex; flex-wrap: wrap; gap: 6px; }
.cfg-none { font-size: 12px; color: #c0c4cc; padding: 6px 0; }
</style>
