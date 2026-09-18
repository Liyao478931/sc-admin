<template>
  <div class="task-page">
    <!-- 统计卡片 -->
    <el-row :gutter="16" style="margin-bottom:16px;">
      <el-col :span="6" v-for="card in statCards" :key="card.key">
        <el-card shadow="hover" class="stat-card" @click.native="quickFilter(card)">
          <div class="stat-icon" :style="{ background: card.color + '1a', color: card.color }"><i :class="card.icon"></i></div>
          <div class="stat-info">
            <div class="stat-val" :style="{ color: card.color }">{{ card.value }}</div>
            <div class="stat-label">{{ card.label }}</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 筛选区域 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <el-form :inline="true" size="small">
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入任务编号、计划名称或检查区域" clearable style="width:220px" @keyup.enter.native="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.inspection_type_id" clearable filterable placeholder="全部类型" style="width:130px" @change="onSearch">
            <el-option v-for="t in typeOptions" :key="t.id" :label="t.type_name" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.executor_id" clearable filterable placeholder="全部执行人" style="width:130px" @change="onSearch">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" clearable placeholder="全部" style="width:100px" @change="onSearch">
            <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" placeholder="计划执行日期" style="width:240px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilters">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 工具栏 + 表格 -->
    <el-card shadow="never">
      <div slot="header" class="card-header">
        <span style="color:#909399">共 <b style="color:#409EFF">{{ total }}</b> 条任务记录</span>
        <div>
          <el-button v-if="hasPerm('safety:inspection:task:add')" size="small" type="primary" icon="el-icon-plus" @click="genVisible = true">手动生成任务</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="refreshAll">刷新</el-button>
        </div>
      </div>

      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" />
        <el-table-column label="任务编号" width="180" show-overflow-tooltip>
          <template slot-scope="{ row }">
            <el-link type="primary" @click="openDetail(row)">{{ row && row.task_code }}</el-link>
          </template>
        </el-table-column>
        <el-table-column prop="plan_name" label="计划名称" min-width="140" show-overflow-tooltip />
        <el-table-column prop="inspection_type_name" label="检查类型" width="100" align="center" />
        <el-table-column prop="area" label="检查区域" width="120" show-overflow-tooltip />
        <el-table-column prop="executor_name" label="执行人" width="80" align="center" />
        <el-table-column label="计划执行日期" width="120" align="center">
          <template slot-scope="{ row }">
            <span :style="{ color: row.status === 'overdue' ? '#F56C6C' : '', fontWeight: row.status === 'overdue' ? 600 : '' }">{{ row.plan_execute_date }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="actual_execute_date" label="实际执行日期" width="160" align="center">
          <template slot-scope="{ row }">{{ row.actual_execute_date || '-' }}</template>
        </el-table-column>
        <el-table-column label="状态" width="100" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="statusTagType(row.status)">{{ row.status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="260" align="center" fixed="right">
          <template slot-scope="{ row }">
            <el-button v-if="['pending', 'overdue'].indexOf(row.status) > -1 && hasPerm('safety:inspection:task:assign')" size="mini" type="text" @click="openAssign(row)">分配执行人</el-button>
            <el-button v-if="['pending', 'overdue'].indexOf(row.status) > -1 && hasPerm('safety:inspection:task:execute')" size="mini" type="text" @click="handleStart(row)">开始执行</el-button>
            <el-button v-if="['pending', 'overdue'].indexOf(row.status) > -1 && hasPerm('safety:inspection:task:edit')" size="mini" type="text" style="color:#E6A23C" @click="openCancel(row)">取消任务</el-button>
            <el-button v-if="['pending', 'overdue'].indexOf(row.status) > -1 && hasPerm('safety:inspection:task:edit')" size="mini" type="text" style="color:#409EFF" @click="handleSendRemind(row)">发送提醒</el-button>
            <el-button v-if="hasPerm('safety:inspection:task:query')" size="mini" type="text" @click="openDetail(row)">查看详情</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination style="margin-top:12px;text-align:right" background layout="total, sizes, prev, pager, next"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10, 20, 50]" @current-change="loadList" @size-change="loadList" />
    </el-card>

    <!-- 弹窗 -->
    <task-detail-dialog :visible.sync="detailVisible" :task-id="detailId" />
    <assign-dialog :visible.sync="assignVisible" :row="currentRow" :user-options="userOptions" @saved="refreshAll" />
    <cancel-dialog :visible.sync="cancelVisible" :row="currentRow" @saved="refreshAll" />
    <generate-dialog :visible.sync="genVisible" @saved="refreshAll" />
  </div>
</template>

<script>
import { getTaskList, getTaskStatistics, startTask, sendTaskRemind, getTypeOptions } from '@/api/safetyInspectionTask'
import { getUserList } from '@/api/user'
import TaskDetailDialog from './components/TaskDetailDialog.vue'
import AssignDialog from './components/AssignDialog.vue'
import CancelDialog from './components/CancelDialog.vue'
import GenerateDialog from './components/GenerateDialog.vue'

export default {
  name: 'SafetyInspectionTask',
  components: { TaskDetailDialog, AssignDialog, CancelDialog, GenerateDialog },
  data() {
    return {
      loading: false,
      list: [],
      total: 0,
      page: 1,
      limit: 10,
      filters: { keyword: '', inspection_type_id: null, executor_id: null, status: '' },
      dateRange: null,
      stats: { pending: 0, in_progress: 0, completed: 0, overdue: 0, cancelled: 0 },
      typeOptions: [],
      userOptions: [],
      statusOptions: [
        { value: '', label: '全部' },
        { value: 'pending', label: '待执行' },
        { value: 'in_progress', label: '执行中' },
        { value: 'completed', label: '已完成' },
        { value: 'overdue', label: '逾期' },
        { value: 'cancelled', label: '已取消' },
      ],
      detailVisible: false,
      detailId: 0,
      assignVisible: false,
      cancelVisible: false,
      genVisible: false,
      currentRow: null,
    }
  },
  computed: {
    statCards() {
      return [
        { key: 'pending', label: '待执行任务', value: this.stats.pending, icon: 'el-icon-time', color: '#409EFF' },
        { key: 'in_progress', label: '执行中任务', value: this.stats.in_progress, icon: 'el-icon-loading', color: '#E6A23C' },
        { key: 'completed', label: '已完成任务', value: this.stats.completed, icon: 'el-icon-circle-check', color: '#67C23A' },
        { key: 'overdue', label: '逾期任务', value: this.stats.overdue, icon: 'el-icon-warning', color: '#F56C6C' },
      ]
    },
  },
  created() {
    this.loadList()
    this.loadStats()
    this.loadTypes()
    this.loadUsers()
  },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    statusTagType(v) {
      return { pending: 'primary', in_progress: 'warning', completed: 'success', overdue: 'danger', cancelled: 'info' }[v] || 'info'
    },
    async loadList() {
      this.loading = true
      try {
        const params = {
          page: this.page,
          limit: this.limit,
          keyword: this.filters.keyword || '',
          inspection_type_id: this.filters.inspection_type_id || '',
          executor_id: this.filters.executor_id || '',
          status: this.filters.status || '',
          start_date: this.dateRange ? this.dateRange[0] : '',
          end_date: this.dateRange ? this.dateRange[1] : '',
        }
        const r = await getTaskList(params)
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    async loadStats() {
      try { const r = await getTaskStatistics(); if (r.code === 0) this.stats = r.data || {} } catch (e) {}
    },
    async loadTypes() {
      try { const r = await getTypeOptions(); if (r.code === 0) this.typeOptions = r.data || [] } catch (e) {}
    },
    async loadUsers() {
      try { const r = await getUserList({ limit: 500 }); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) {}
    },
    onSearch() { this.page = 1; this.loadList() },
    resetFilters() {
      this.filters = { keyword: '', inspection_type_id: null, executor_id: null, status: '' }
      this.dateRange = null
      this.page = 1
      this.loadList()
    },
    quickFilter(card) {
      if (this.filters.status === card.key) { this.filters.status = '' }
      else { this.filters.status = card.key }
      this.page = 1
      this.loadList()
    },
    refreshAll() { this.loadList(); this.loadStats() },
    openDetail(row) { this.detailId = row.id; this.detailVisible = true },
    openAssign(row) { this.currentRow = row; this.assignVisible = true },
    openCancel(row) { this.currentRow = row; this.cancelVisible = true },
    handleStart(row) {
      this.$confirm(`确认开始执行任务 [${row.task_code}] ？`, '开始执行', { type: 'warning' }).then(async () => {
        try {
          const r = await startTask(row.id)
          if (r.code === 0) { this.$message.success(r.msg || '已开始执行'); this.refreshAll() }
        } catch (e) {}
      }).catch(() => {})
    },
    handleSendRemind(row) {
      this.$confirm(`确认向执行人 ${row.executor_name || '-'} 发送任务提醒？`, '发送提醒', { type: 'info' }).then(async () => {
        try {
          const r = await sendTaskRemind(row.id)
          if (r.code === 0) { this.$message.success(r.msg || '提醒已发送'); this.refreshAll() }
        } catch (e) {}
      }).catch(() => {})
    },
  },
}
</script>

<style scoped>
.stat-card { cursor: pointer; transition: all .2s; }
.stat-card:hover { transform: translateY(-3px); box-shadow: 0 6px 16px rgba(0,0,0,.1); }
.stat-card .stat-icon { width: 40px; height: 40px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 20px; float: left; margin-right: 10px; }
.stat-card .stat-info { overflow: hidden; }
.stat-card .stat-val { font-size: 20px; font-weight: 700; line-height: 1.2; }
.stat-card .stat-label { font-size: 12px; color: #909399; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
