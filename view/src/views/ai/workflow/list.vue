<!-- 文件：admin/src/views/ai/workflow/list.vue -->
<template>
  <div class="workflow-page">
    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="6">
        <div class="stat-card clickable" @click="quickFilter('total')">
          <div class="stat-icon" style="background:#409EFF1a;color:#409EFF;"><i class="el-icon-s-operation"></i></div>
          <div class="stat-body">
            <div class="stat-value">{{ stats.total }}</div>
            <div class="stat-label">工作流总数</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card clickable" @click="quickFilter('enabled')">
          <div class="stat-icon" style="background:#67C23A1a;color:#67C23A;"><i class="el-icon-check"></i></div>
          <div class="stat-body">
            <div class="stat-value">{{ stats.enabled }}</div>
            <div class="stat-label">已启用数</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card clickable" @click="quickFilter('running')">
          <div class="stat-icon" style="background:#E6A23C1a;color:#E6A23C;"><i class="el-icon-loading"></i></div>
          <div class="stat-body">
            <div class="stat-value">{{ stats.running }}</div>
            <div class="stat-label">运行中数</div>
          </div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card">
          <div class="stat-icon" style="background:#8E44AD1a;color:#8E44AD;"><i class="el-icon-date"></i></div>
          <div class="stat-body">
            <div class="stat-value">{{ stats.today_runs }}</div>
            <div class="stat-label">今日运行数</div>
          </div>
        </div>
      </el-col>
    </el-row>

    <!-- 筛选区域 -->
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" @submit.native.prevent>
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入工作流名称" clearable style="width:200px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.trigger_type" placeholder="全部触发方式" clearable style="width:150px" @change="onSearch">
            <el-option v-for="(t, k) in TRIGGER_TEXT" :key="k" :label="t" :value="k" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.run_status" placeholder="全部运行状态" clearable style="width:140px" @change="onSearch">
            <el-option v-for="(s, k) in RUN_STATUS_TEXT" :key="k" :label="s" :value="k" />
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
        <span>共 <b>{{ total }}</b> 个工作流</span>
        <div>
          <el-button v-if="hasPerm('ai:workflow:add')" size="small" type="primary" icon="el-icon-plus" @click="goCreate">新建工作流</el-button>
          <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadAll">刷新</el-button>
        </div>
      </div>

      <!-- 表格 -->
      <el-table :data="list" v-loading="loading" size="small" stripe>
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column label="工作流名称" min-width="160" show-overflow-tooltip>
          <template slot-scope="{ row }">
            <el-button type="text" size="mini" @click="openDetail(row)">{{ row.workflow_name }}</el-button>
          </template>
        </el-table-column>
        <el-table-column prop="description" label="描述" min-width="140" show-overflow-tooltip>
          <template slot-scope="{ row }">{{ row.description || '-' }}</template>
        </el-table-column>
        <el-table-column label="触发方式" width="120" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="triggerTag(row.trigger_type)">{{ row.trigger_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="运行状态" width="100" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="statusTag(row.last_run_status)">{{ row.status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="触发配置" width="140" show-overflow-tooltip>
          <template slot-scope="{ row }">{{ row.trigger_summary || '-' }}</template>
        </el-table-column>
        <el-table-column prop="last_run_time" label="最近运行时间" width="160">
          <template slot-scope="{ row }">{{ row.last_run_time || '-' }}</template>
        </el-table-column>
        <el-table-column prop="run_count" label="运行次数" width="90" align="center" />
        <el-table-column prop="created_by_name" label="创建人" width="80" show-overflow-tooltip />
        <el-table-column label="操作" width="290" align="center" fixed="right">
          <template slot-scope="{ row }">
            <el-button v-if="row.status === 1 && row.last_run_status !== 'running' && hasPerm('ai:workflow:trigger')"
              type="text" size="mini" style="color:#409EFF;" @click="openRun(row)">运行</el-button>
            <el-button type="text" size="mini" @click="openDetail(row)">详情</el-button>
            <el-button v-if="hasPerm('ai:workflow:edit')" type="text" size="mini" @click="goEdit(row)">编辑</el-button>
            <el-button v-if="hasPerm('ai:workflow:add')" type="text" size="mini" @click="doCopy(row)">复制</el-button>
            <el-button v-if="hasPerm('ai:workflow:edit')" type="text" size="mini"
              :style="{ color: row.status === 1 ? '#E6A23C' : '#67C23A' }" @click="doToggleStatus(row)">
              {{ row.status === 1 ? '停用' : '启用' }}
            </el-button>
            <el-button v-if="hasPerm('ai:workflow:delete')" type="text" size="mini" style="color:#F56C6C;" @click="doDelete(row)">删除</el-button>
            <el-button type="text" size="mini" @click="goLogs(row)">日志</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 分页 -->
      <el-pagination class="pager" background layout="total, sizes, prev, pager, next" :total="total"
        :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50]"
        @size-change="s => { limit = s; page = 1; loadAll() }"
        @current-change="p => { page = p; loadAll() }" />
    </el-card>

    <!-- 工作流详情弹窗 -->
    <workflow-detail-dialog v-if="detailVisible" :visible.sync="detailVisible" :workflow-id="currentId" />

    <!-- 运行确认弹窗 -->
    <workflow-run-dialog v-if="runVisible" :visible.sync="runVisible" :workflow="currentRow" @success="loadAll" />
  </div>
</template>

<script>
import {
  getWorkflowList, getWorkflowStatistics, deleteWorkflow,
  updateWorkflowStatus, copyWorkflow
} from '@/api/aiWorkflow'
import WorkflowDetailDialog from './components/WorkflowDetailDialog.vue'
import WorkflowRunDialog from './components/WorkflowRunDialog.vue'

const TRIGGER_TEXT = {
  manual: '手动触发', schedule: '定时触发', webhook: 'Webhook触发', event: '事件触发'
}
const RUN_STATUS_TEXT = {
  idle: '空闲', running: '运行中', success: '成功', failed: '失败'
}

export default {
  name: 'AiWorkflowList',
  components: { WorkflowDetailDialog, WorkflowRunDialog },
  data () {
    return {
      TRIGGER_TEXT, RUN_STATUS_TEXT,
      list: [], total: 0, page: 1, limit: 20, loading: false,
      stats: { total: 0, enabled: 0, running: 0, today_runs: 0 },
      filters: { keyword: '', trigger_type: '', run_status: '', status: '', dateRange: null },
      detailVisible: false, runVisible: false, currentId: 0, currentRow: null
    }
  },
  created () { this.loadAll(); this.loadStats() },
  methods: {
    hasPerm (code) {
      const userInfo = this.$store.state.user.userInfo || {}
      const perms = this.$store.state.user.permissions || []
      if (userInfo.is_super_admin || perms.indexOf('super_admin') > -1) return true
      return perms.indexOf(code) > -1
    },
    buildParams () {
      const p = { page: this.page, limit: this.limit }
      if (this.filters.keyword) p.keyword = this.filters.keyword
      if (this.filters.trigger_type) p.trigger_type = this.filters.trigger_type
      if (this.filters.run_status) p.run_status = this.filters.run_status
      if (this.filters.status !== '') p.status = this.filters.status
      if (this.filters.dateRange && this.filters.dateRange.length === 2) {
        p.start_date = this.filters.dateRange[0]
        p.end_date = this.filters.dateRange[1]
      }
      return p
    },
    async loadAll () {
      this.loading = true
      try {
        const r = await getWorkflowList(this.buildParams())
        if (r.code === 0) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
        }
      } catch (e) {} finally { this.loading = false }
    },
    async loadStats () {
      try {
        const r = await getWorkflowStatistics()
        if (r.code === 0) this.stats = r.data || this.stats
      } catch (e) {}
    },
    onSearch () { this.page = 1; this.loadAll() },
    resetFilter () {
      this.filters = { keyword: '', trigger_type: '', run_status: '', status: '', dateRange: null }
      this.page = 1
      this.loadAll()
    },
    // 统计卡片快速筛选
    quickFilter (key) {
      if (key === 'total') {
        this.filters = { keyword: '', trigger_type: '', run_status: '', status: '', dateRange: null }
      } else if (key === 'enabled') {
        this.filters.status = 1
      } else if (key === 'running') {
        this.filters.run_status = 'running'
      } else {
        return
      }
      this.page = 1
      this.loadAll()
    },
    goCreate () { this.$router.push('/ai/workflow/create') },
    goEdit (row) { this.$router.push({ path: '/ai/workflow/create', query: { id: row.id } }) },
    goLogs (row) { this.$router.push({ path: '/ai/workflow/logs', query: { workflow_id: row.workflow_id } }) },
    openDetail (row) { this.currentId = row.id; this.detailVisible = true },
    openRun (row) { this.currentRow = row; this.runVisible = true },
    doDelete (row) {
      this.$confirm(`确定要删除工作流 [${row.workflow_name}] 吗？删除后不可恢复`, '删除确认', { type: 'warning' })
        .then(async () => {
          try {
            const r = await deleteWorkflow(row.id)
            if (r.code === 0) { this.$message.success('删除成功'); this.loadAll(); this.loadStats() }
          } catch (e) {
            // 接口错误信息已由 request 拦截器提示（如“工作流正在运行，不可删除”）
          }
        }).catch(() => {})
    },
    doToggleStatus (row) {
      const next = row.status === 1 ? 0 : 1
      const text = next === 1 ? '启用' : '停用'
      this.$confirm(`确认${text}工作流 [${row.workflow_name}] 吗？`, `${text}确认`, { type: 'warning' })
        .then(async () => {
          try {
            const r = await updateWorkflowStatus(row.id, next)
            if (r.code === 0) { this.$message.success('状态已更新'); this.loadAll(); this.loadStats() }
          } catch (e) {}
        }).catch(() => {})
    },
    doCopy (row) {
      this.$confirm(`确认复制工作流 [${row.workflow_name}] 吗？复制后将生成停用状态的副本`, '复制确认', { type: 'info' })
        .then(async () => {
          try {
            const r = await copyWorkflow(row.id)
            if (r.code === 0) { this.$message.success('工作流复制成功'); this.loadAll(); this.loadStats() }
          } catch (e) {}
        }).catch(() => {})
    },
    triggerTag (t) { return { manual: 'primary', schedule: 'success', webhook: 'warning', event: 'danger' }[t] || 'info' },
    statusTag (s) { return { idle: 'info', running: 'primary', success: 'success', failed: 'danger' }[s] || 'info' }
  }
}
</script>

<style scoped>
.workflow-page { padding: 16px; }
.stat-row { margin-bottom: 14px; }
.stat-card { display: flex; align-items: center; background: #fff; border-radius: 8px; padding: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
.stat-card.clickable { cursor: pointer; }
.stat-card.clickable:hover { box-shadow: 0 2px 8px rgba(0,0,0,0.08); }
.stat-icon { width: 48px; height: 48px; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 24px; margin-right: 14px; }
.stat-value { font-size: 22px; font-weight: 700; color: #303133; line-height: 1.2; }
.stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.filter-card { margin-bottom: 14px; }
.filter-card /deep/ .el-card__body { padding: 12px 16px 0; }
.list-card /deep/ .el-card__body { padding: 12px 16px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.toolbar span { font-size: 13px; color: #606266; }
.pager { margin-top: 14px; text-align: right; }
</style>
