<!-- 文件：admin/src/views/ai/app/list.vue -->
<template>
  <div class="app-page">
    <!-- 统计卡片（6 个） -->
    <el-row :gutter="12" class="stat-row">
      <el-col :span="4">
        <div class="stat-card clickable" @click="quickFilter('total')">
          <div class="stat-icon" style="background:#409EFF1a;color:#409EFF;"><i class="el-icon-apps"></i></div>
          <div class="stat-body"><div class="stat-value">{{ stats.total }}</div><div class="stat-label">应用总数</div></div>
        </div>
      </el-col>
      <el-col :span="4">
        <div class="stat-card clickable" @click="quickFilter('enabled')">
          <div class="stat-icon" style="background:#67C23A1a;color:#67C23A;"><i class="el-icon-check"></i></div>
          <div class="stat-body"><div class="stat-value">{{ stats.enabled }}</div><div class="stat-label">已启用数</div></div>
        </div>
      </el-col>
      <el-col :span="4">
        <div class="stat-card clickable" @click="quickFilter('agent')">
          <div class="stat-icon" style="background:#409EFF1a;color:#409EFF;"><i class="el-icon-user"></i></div>
          <div class="stat-body"><div class="stat-value">{{ stats.agent }}</div><div class="stat-label">智能体数</div></div>
        </div>
      </el-col>
      <el-col :span="4">
        <div class="stat-card clickable" @click="quickFilter('workflow')">
          <div class="stat-icon" style="background:#67C23A1a;color:#67C23A;"><i class="el-icon-s-operation"></i></div>
          <div class="stat-body"><div class="stat-value">{{ stats.workflow }}</div><div class="stat-label">工作流数</div></div>
        </div>
      </el-col>
      <el-col :span="4">
        <div class="stat-card clickable" @click="quickFilter('chat')">
          <div class="stat-icon" style="background:#E6A23C1a;color:#E6A23C;"><i class="el-icon-chat-dot-round"></i></div>
          <div class="stat-body"><div class="stat-value">{{ stats.chat }}</div><div class="stat-label">对话数</div></div>
        </div>
      </el-col>
      <el-col :span="4">
        <div class="stat-card">
          <div class="stat-icon" style="background:#8E44AD1a;color:#8E44AD;"><i class="el-icon-data-line"></i></div>
          <div class="stat-body"><div class="stat-value">{{ stats.total_calls }}</div><div class="stat-label">总调用次数</div></div>
        </div>
      </el-col>
    </el-row>

    <!-- 筛选 -->
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入应用名称" clearable style="width:200px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.app_type" placeholder="全部类型" clearable style="width:130px" @change="onSearch">
            <el-option label="智能体" value="agent" />
            <el-option label="工作流" value="workflow" />
            <el-option label="对话" value="chat" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" placeholder="全部状态" clearable style="width:120px" @change="onSearch">
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="filters.dateRange" type="daterange" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期"
            value-format="yyyy-MM-dd" style="width:240px" @change="onSearch" />
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
        <span>共 <b>{{ total }}</b> 个应用</span>
        <div>
          <el-button v-if="hasPerm('ai:app:add')" size="small" type="primary" icon="el-icon-plus" @click="goCreate">新建应用</el-button>
          <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadAll">刷新</el-button>
        </div>
      </div>

      <!-- 表格 -->
      <el-table :data="list" v-loading="loading" size="small" stripe>
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column label="应用名称" min-width="140" show-overflow-tooltip>
          <template slot-scope="{ row }">
            <el-button type="text" size="mini" @click="openDetail(row)">{{ row.app_name }}</el-button>
          </template>
        </el-table-column>
        <el-table-column label="应用类型" width="100" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="typeTag(row.app_type)">{{ row.type_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="描述" min-width="160" show-overflow-tooltip>
          <template slot-scope="{ row }">{{ row.description || '-' }}</template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.status === 1 ? 'success' : 'info'">{{ row.status === 1 ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="调用次数" width="100" align="center">
          <template slot-scope="{ row }">
            <el-button type="text" size="mini" @click="openStats(row)">{{ row.call_count }}</el-button>
          </template>
        </el-table-column>
        <el-table-column prop="created_by_name" label="创建人" width="80" show-overflow-tooltip />
        <el-table-column prop="create_time" label="创建时间" width="160" />
        <el-table-column label="操作" width="250" align="center" fixed="right">
          <template slot-scope="{ row }">
            <el-button type="text" size="mini" @click="openDetail(row)">详情</el-button>
            <el-button v-if="hasPerm('ai:app:edit')" type="text" size="mini" @click="goEdit(row)">编辑</el-button>
            <el-button v-if="hasPerm('ai:app:add')" type="text" size="mini" @click="doCopy(row)">复制</el-button>
            <el-button v-if="hasPerm('ai:app:edit')" type="text" size="mini" :style="{ color: row.status === 1 ? '#E6A23C' : '#67C23A' }" @click="doToggleStatus(row)">
              {{ row.status === 1 ? '停用' : '启用' }}
            </el-button>
            <el-button v-if="hasPerm('ai:app:delete')" type="text" size="mini" style="color:#F56C6C;" @click="doDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination class="pager" background layout="total, sizes, prev, pager, next" :total="total"
        :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50]"
        @size-change="s => { limit = s; page = 1; loadAll() }"
        @current-change="p => { page = p; loadAll() }" />
    </el-card>

    <!-- 详情弹窗 -->
    <app-detail-dialog v-if="detailVisible" :visible.sync="detailVisible" :app-id="currentId" />

    <!-- 调用统计弹窗 -->
    <app-stats-dialog v-if="statsVisible" :visible.sync="statsVisible" :app="currentRow" />
  </div>
</template>

<script>
import { getAppList, getAppStatistics, deleteApp, updateAppStatus, copyApp } from '@/api/aiApp'
import AppDetailDialog from './components/AppDetailDialog.vue'
import AppStatsDialog from './components/AppStatsDialog.vue'

export default {
  name: 'AiAppList',
  components: { AppDetailDialog, AppStatsDialog },
  data () {
    return {
      list: [], total: 0, page: 1, limit: 20, loading: false,
      stats: { total: 0, enabled: 0, agent: 0, workflow: 0, chat: 0, total_calls: 0 },
      filters: { keyword: '', app_type: '', status: '', dateRange: null },
      detailVisible: false, statsVisible: false, currentId: 0, currentRow: null
    }
  },
  created () { this.loadAll(); this.loadStats() },
  methods: {
    hasPerm (code) {
      const u = this.$store.state.user.userInfo || {}
      const p = this.$store.state.user.permissions || []
      if (u.is_super_admin || p.indexOf('super_admin') > -1) return true
      return p.indexOf(code) > -1
    },
    buildParams () {
      const p = { page: this.page, limit: this.limit }
      if (this.filters.keyword) p.keyword = this.filters.keyword
      if (this.filters.app_type) p.app_type = this.filters.app_type
      if (this.filters.status !== '') p.status = this.filters.status
      if (this.filters.dateRange && this.filters.dateRange.length === 2) {
        p.start_date = this.filters.dateRange[0]; p.end_date = this.filters.dateRange[1]
      }
      return p
    },
    async loadAll () {
      this.loading = true
      try { const r = await getAppList(this.buildParams()); if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 } } catch (e) {} finally { this.loading = false }
    },
    async loadStats () {
      try { const r = await getAppStatistics(); if (r.code === 0) this.stats = r.data || this.stats } catch (e) {}
    },
    onSearch () { this.page = 1; this.loadAll() },
    resetFilter () { this.filters = { keyword: '', app_type: '', status: '', dateRange: null }; this.page = 1; this.loadAll() },
    quickFilter (key) {
      if (key === 'total') { this.filters = { keyword: '', app_type: '', status: '', dateRange: null } }
      else if (key === 'enabled') { this.filters.status = 1 }
      else if (key === 'agent' || key === 'workflow' || key === 'chat') { this.filters.app_type = key }
      else return
      this.page = 1; this.loadAll()
    },
    goCreate () { this.$router.push('/ai/app/create') },
    goEdit (row) { this.$router.push({ path: '/ai/app/create', query: { id: row.id } }) },
    openDetail (row) { this.currentId = row.id; this.detailVisible = true },
    openStats (row) { this.currentRow = row; this.statsVisible = true },
    doDelete (row) {
      this.$confirm(`确定要删除应用 [${row.app_name}] 吗？删除后不可恢复`, '删除确认', { type: 'warning' })
        .then(async () => {
          try { const r = await deleteApp(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadAll(); this.loadStats() } } catch (e) {}
        }).catch(() => {})
    },
    doToggleStatus (row) {
      const next = row.status === 1 ? 0 : 1
      const text = next === 1 ? '启用' : '停用'
      this.$confirm(`确认${text}应用 [${row.app_name}] 吗？`, `${text}确认`, { type: 'warning' })
        .then(async () => {
          try { const r = await updateAppStatus(row.id, next); if (r.code === 0) { this.$message.success('状态已更新'); this.loadAll(); this.loadStats() } } catch (e) {}
        }).catch(() => {})
    },
    doCopy (row) {
      this.$confirm(`确认复制应用 [${row.app_name}] 吗？复制后将生成停用状态的副本`, '复制确认', { type: 'info' })
        .then(async () => {
          try { const r = await copyApp(row.id); if (r.code === 0) { this.$message.success('应用复制成功'); this.loadAll(); this.loadStats() } } catch (e) {}
        }).catch(() => {})
    },
    typeTag (t) { return { agent: 'primary', workflow: 'success', chat: 'warning' }[t] || 'info' }
  }
}
</script>

<style scoped>
.app-page { padding: 16px; }
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
