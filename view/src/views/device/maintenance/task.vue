<template>
  <div class="maintenance-task-page">
    <!-- 统计卡片 -->
    <el-row :gutter="16" style="margin-bottom:16px;">
      <el-col :span="6" v-for="card in statCards" :key="card.key" @click.native="filterByStat(card.key)">
        <el-card shadow="hover" class="stat-card" :class="{active: quickKey === card.key}">
          <div class="stat-icon" :style="{background: card.color + '1a', color: card.color}"><i :class="card.icon"></i></div>
          <div class="stat-info"><div class="stat-val" :style="{color: card.color}">{{ card.value }}</div><div class="stat-label">{{ card.label }}</div></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 筛选区域 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <el-form :inline="true" size="small">
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入设备名称或编码" clearable style="width:200px" @keyup.enter.native="loadList" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.plan_id" clearable filterable placeholder="全部计划" style="width:160px" @change="loadList">
            <el-option v-for="p in planOptions" :key="p.id" :label="p.plan_name" :value="p.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.level_id" clearable placeholder="全部等级" style="width:120px" @change="loadList">
            <el-option v-for="l in levelOptions" :key="l.id" :label="l.level_name" :value="l.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.executor_id" clearable filterable placeholder="全部执行人" style="width:130px" @change="loadList">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width:110px" @change="loadList">
            <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="计划执行开始" end-placeholder="计划执行结束"
            value-format="yyyy-MM-dd" style="width:240px" @change="loadList" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="loadList">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilters">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 工具栏 + 表格 -->
    <el-card shadow="never">
      <div slot="header" class="card-header">
        <span>保养任务列表 · 共 {{ total }} 条任务记录</span>
        <div style="float:right;">
          <el-button v-if="hasPerm('device:maintenance:task:add')" size="small" type="primary" icon="el-icon-plus" @click="generateVisible = true">手动生成任务</el-button>
          <el-button size="small" icon="el-icon-download" @click="handleExport">导出</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </div>
      </div>

      <el-table :data="list" v-loading="loading" stripe border size="small">
        <el-table-column type="index" label="#" width="60" />
        <el-table-column prop="task_code" label="任务编号" width="180">
          <template slot-scope="{row}"><el-link type="primary" @click="openDetail(row)">{{ row.task_code }}</el-link></template>
        </el-table-column>
        <el-table-column prop="plan_name" label="计划名称" min-width="140" show-overflow-tooltip />
        <el-table-column prop="device_name" label="设备名称" min-width="140" show-overflow-tooltip />
        <el-table-column label="保养等级" width="90">
          <template slot-scope="{row}"><el-tag size="mini">{{ row.level_name }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="executor_name" label="执行人" width="80" />
        <el-table-column label="计划执行日期" width="120">
          <template slot-scope="{row}">
            <span v-if="row.status === 'overdue'" style="color:#F56C6C;font-weight:600">{{ row.plan_execute_date }}</span>
            <span v-else>{{ row.plan_execute_date }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="actual_execute_date" label="实际执行日期" width="160" />
        <el-table-column label="状态" width="100">
          <template slot-scope="{row}">
            <el-tag :type="statusType(row.status)" size="mini">{{ row.status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="220" fixed="right">
          <template slot-scope="{row}">
            <template v-if="['pending', 'overdue'].includes(row.status)">
              <el-button v-if="hasPerm('device:maintenance:task:assign')" size="mini" type="text" @click="openAssign(row)">分配</el-button>
              <el-button size="mini" type="text" style="color:#67C23A" @click="startExecute(row)">开始</el-button>
              <el-button v-if="hasPerm('device:maintenance:task:edit')" size="mini" type="text" style="color:#F56C6C" @click="openCancel(row)">取消</el-button>
              <el-button v-if="hasPerm('device:maintenance:task:edit')" size="mini" type="text" @click="sendRemind(row)">提醒</el-button>
              <el-button size="mini" type="text" @click="openDetail(row)">详情</el-button>
            </template>
            <template v-else-if="row.status === 'in_progress'">
              <el-button size="mini" type="text" disabled>执行中</el-button>
              <el-button size="mini" type="text" @click="openDetail(row)">详情</el-button>
            </template>
            <template v-else>
              <el-button size="mini" type="text" @click="openDetail(row)">详情</el-button>
            </template>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination background style="margin-top:16px;text-align:right;" :current-page="page" :page-size="limit" :total="total"
        layout="total, sizes, prev, pager, next" :page-sizes="[10,20,50,100]"
        @size-change="s => { limit = s; page = 1; loadList() }" @current-change="p => { page = p; loadList() }" />
    </el-card>

    <!-- 弹窗 -->
    <task-detail-dialog :visible.sync="detailVisible" :task-id="currentId" />
    <task-assign-dialog :visible.sync="assignVisible" :task-id="currentId" @saved="onSaved" />
    <task-cancel-dialog :visible.sync="cancelVisible" :task-id="currentId" @saved="onSaved" />
    <task-generate-dialog :visible.sync="generateVisible" @saved="onSaved" />
  </div>
</template>

<script>
import { getTaskList, getTaskStatistics, sendTaskRemind } from '@/api/maintenanceTask'
import { getPlanList } from '@/api/maintenance'
import { getLevelOptions } from '@/api/maintenance'
import { getUserList } from '@/api/user'
import TaskDetailDialog from './components/TaskDetailDialog.vue'
import TaskAssignDialog from './components/TaskAssignDialog.vue'
import TaskCancelDialog from './components/TaskCancelDialog.vue'
import TaskGenerateDialog from './components/TaskGenerateDialog.vue'

export default {
  name: 'MaintenanceTask',
  components: { TaskDetailDialog, TaskAssignDialog, TaskCancelDialog, TaskGenerateDialog },
  data() {
    return {
      list: [], loading: false, total: 0, page: 1, limit: 20,
      quickKey: 'all',
      detailVisible: false, assignVisible: false, cancelVisible: false, generateVisible: false, currentId: 0,
      planOptions: [], levelOptions: [], userOptions: [], dateRange: [],
      filters: { keyword: '', plan_id: null, level_id: null, executor_id: null, status: '' },
      statusOptions: [],
      statCards: [
        { key: 'pending', label: '待执行', icon: 'el-icon-time', color: '#409EFF', value: 0 },
        { key: 'in_progress', label: '执行中', icon: 'el-icon-loading', color: '#E6A23C', value: 0 },
        { key: 'completed', label: '已完成', icon: 'el-icon-circle-check', color: '#67C23A', value: 0 },
        { key: 'overdue', label: '已逾期', icon: 'el-icon-warning', color: '#F56C6C', value: 0 }
      ]
    }
  },
  created() { this.loadStatistics(); this.loadPlans(); this.loadLevels(); this.loadUsers(); this.loadDicts(); this.loadList() },
  methods: {
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    // 任务状态从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../api/dictionary')
      try { const r = await getDictByCode('maintenance_task_status'); this.statusOptions = r.data || [] } catch (e) { this.statusOptions = [] }
    },
    statusType(s) { return { pending: '', in_progress: 'warning', completed: 'success', overdue: 'danger', cancelled: 'info' }[s] || '' },
    async loadStatistics() {
      try { const r = await getTaskStatistics(); if (r.code === 0) { const d = r.data; this.statCards = [
        { key: 'pending', label: '待执行', icon: 'el-icon-time', color: '#409EFF', value: d.pending },
        { key: 'in_progress', label: '执行中', icon: 'el-icon-loading', color: '#E6A23C', value: d.in_progress },
        { key: 'completed', label: '已完成', icon: 'el-icon-circle-check', color: '#67C23A', value: d.completed },
        { key: 'overdue', label: '已逾期', icon: 'el-icon-warning', color: '#F56C6C', value: d.overdue }
      ] } } catch (e) {}
    },
    async loadPlans() { try { const r = await getPlanList({ limit: 500 }); if (r.code === 0) this.planOptions = r.data.list || [] } catch (e) {} },
    async loadLevels() { try { const r = await getLevelOptions(); if (r.code === 0) this.levelOptions = r.data || [] } catch (e) {} },
    async loadUsers() { try { const r = await getUserList({ limit: 500 }); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) {} },
    async loadList() {
      this.loading = true
      try {
        const p = { page: this.page, limit: this.limit, ...this.filters }
        if (this.quickKey && this.quickKey !== 'all') p.status = this.quickKey
        if (this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] }
        const r = await getTaskList(p)
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    filterByStat(key) { this.quickKey = this.quickKey === key ? 'all' : key; this.page = 1; this.loadList() },
    resetFilters() { this.filters = { keyword: '', plan_id: null, level_id: null, executor_id: null, status: '' }; this.quickKey = 'all'; this.dateRange = []; this.page = 1; this.loadList() },
    openDetail(row) { this.currentId = row.id; this.detailVisible = true },
    openAssign(row) { this.currentId = row.id; this.assignVisible = true },
    openCancel(row) { this.currentId = row.id; this.cancelVisible = true },
    startExecute(row) { this.$message.info('开始执行功能将在保养执行模块中实现') },
    async sendRemind(row) {
      try {
        await this.$confirm(`确认向执行人「${row.executor_name || '未分配'}」发送任务提醒？`, '提示', { type: 'warning' })
        const r = await sendTaskRemind(row.id)
        if (r.code === 0) { this.$message.success('提醒已发送'); this.loadList() }
      } catch (e) {}
    },
    onSaved() { this.loadList(); this.loadStatistics() },
    handleExport() {
      if (!this.list.length) return this.$message.warning('暂无数据可导出')
      const headers = ['任务编号', '计划名称', '设备名称', '保养等级', '执行人', '计划执行日期', '实际执行日期', '状态']
      const rows = this.list.map(t => [t.task_code, t.plan_name, t.device_name, t.level_name, t.executor_name, t.plan_execute_date, t.actual_execute_date || '', t.status_text])
      const csv = '\uFEFF' + [headers, ...rows].map(r => r.map(c => `"${String(c || '').replace(/"/g, '""')}"`).join(',')).join('\n')
      const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `保养任务_${Date.now()}.csv`
      a.click()
      URL.revokeObjectURL(url)
    }
  }
}
</script>

<style scoped>
.maintenance-task-page { padding: 0; }
.stat-card { cursor: pointer; display: flex; align-items: center; transition: all .2s; }
.stat-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,.1); }
.stat-card.active { border-color: #409EFF; }
.stat-icon { width: 48px; height: 48px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 22px; margin-right: 12px; }
.stat-val { font-size: 24px; font-weight: 700; line-height: 1.2; }
.stat-label { color: #909399; font-size: 13px; }
.card-header { display: flex; align-items: center; }
</style>
