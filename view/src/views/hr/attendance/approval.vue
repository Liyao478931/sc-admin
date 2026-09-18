<template>
  <div class="approval-page">
    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="4" v-for="card in statCards" :key="card.key">
        <div class="stat-card" :style="{ borderTopColor: card.color }">
          <div class="stat-icon" :style="{ background: card.color + '1a', color: card.color }"><i :class="card.icon"></i></div>
          <div class="stat-body"><div class="stat-value" :style="{ color: card.color }">{{ card.value }}</div><div class="stat-label">{{ card.label }}</div></div>
        </div>
      </el-col>
    </el-row>

    <!-- 筛选区域 -->
    <el-card shadow="never" class="filter-card">
      <el-form :inline="true" size="small" @submit.native.prevent>
        <el-form-item><el-input v-model="filters.keyword" placeholder="请输入员工姓名" clearable style="width:180px" @keyup.enter.native="onSearch" @clear="onSearch" /></el-form-item>
        <el-form-item>
          <el-select v-model="filters.department_id" clearable placeholder="全部部门" style="width:140px" @change="onSearch"><el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" /></el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.approval_type" clearable placeholder="全部类型" style="width:110px" @change="onSearch"><el-option v-for="(t, k) in TYPE_MAP" :key="k" :label="t" :value="k" /></el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.approval_status" clearable placeholder="全部状态" style="width:110px" @change="onSearch"><el-option v-for="(s, k) in STATUS_MAP" :key="k" :label="s" :value="k" /></el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.source" clearable placeholder="全部来源" style="width:110px" @change="onSearch"><el-option label="钉钉同步" value="dingtalk" /><el-option label="手动录入" value="manual" /></el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="filters.dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" style="width:230px" @change="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilter">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 工具栏 + 表格 -->
    <el-card shadow="never" class="list-card">
      <div class="toolbar">
        <span>共 <b>{{ total }}</b> 条记录</span>
        <div>
          <el-button v-if="hasPerm('hr:attendance:approval:add')" size="small" type="primary" icon="el-icon-plus" @click="formVisible = true">录入审批</el-button>
          <el-button v-if="hasPerm('hr:attendance:approval:import')" size="small" icon="el-icon-upload2" @click="importVisible = true">导入</el-button>
          <el-button v-if="hasPerm('hr:attendance:approval:export')" size="small" icon="el-icon-download" :loading="exporting" @click="doExport">导出</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadAll">刷新</el-button>
        </div>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe>
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column prop="approval_code" label="审批编号" width="180" />
        <el-table-column prop="employee_name" label="员工姓名" width="80" />
        <el-table-column prop="department_name" label="所属部门" width="120" show-overflow-tooltip />
        <el-table-column label="审批类型" width="100" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :style="typeStyle(row.approval_type)">{{ row.approval_type_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="apply_date" label="申请日期" width="120" align="center" />
        <el-table-column prop="start_time" label="开始时间" width="160" />
        <el-table-column prop="end_time" label="结束时间" width="160" />
        <el-table-column label="时长" width="100" align="center"><template slot-scope="{ row }">{{ row.duration }}小时</template></el-table-column>
        <el-table-column label="审批状态" width="100" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="statusType(row.approval_status)">{{ row.approval_status_text }}</el-tag></template>
        </el-table-column>
        <el-table-column label="数据来源" width="100" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="row.source === 'manual' ? 'success' : 'primary'">{{ row.source_text }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="180" align="center">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('hr:attendance:approval:query')" type="text" size="mini" @click="openDetail(row)">详情</el-button>
            <el-button v-if="hasPerm('hr:attendance:approval:edit') && row.source === 'manual'" type="text" size="mini" @click="openEdit(row)">编辑</el-button>
            <el-button v-if="hasPerm('hr:attendance:approval:delete') && row.source === 'manual'" type="text" size="mini" style="color:#F56C6C" @click="removeOne(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination class="pager" background layout="total, sizes, prev, pager, next" :total="total"
        :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50]"
        @size-change="s => { limit = s; page = 1; loadAll() }"
        @current-change="p => { page = p; loadAll() }" />
    </el-card>

    <!-- 详情弹窗 -->
    <approval-detail-dialog v-if="detailVisible" :visible.sync="detailVisible" :record-id="detailId" />

    <!-- 录入/编辑弹窗 -->
    <approval-form-dialog v-if="formVisible" :visible.sync="formVisible" :record-id="formId" @saved="loadAll" />

    <!-- 导入弹窗 -->
    <approval-import-dialog v-if="importVisible" :visible.sync="importVisible" @saved="loadAll" />
  </div>
</template>

<script>
import { getApprovalList, getApprovalStatistics, deleteApproval, exportApproval } from '@/api/attendanceApproval'
import { getDeptTree } from '@/api/organization'
import ApprovalDetailDialog from './components/ApprovalDetailDialog.vue'
import ApprovalFormDialog from './components/ApprovalFormDialog.vue'
import ApprovalImportDialog from './components/ApprovalImportDialog.vue'

const TYPE_MAP = { leave: '请假', outing: '外出', travel: '出差', car_apply: '用车申请' }
const TYPE_COLOR = { leave: '#409EFF', outing: '#E6A23C', travel: '#67C23A', car_apply: '#8E44AD' }
const STATUS_MAP = { pending: '待审批', approved: '已通过', rejected: '已驳回', canceled: '已撤销' }

function flattenDept (nodes) {
  let r = []
  for (const n of nodes || []) { r.push(n); if (n.children) r = r.concat(flattenDept(n.children)) }
  return r
}

export default {
  name: 'AttendanceApproval',
  components: { ApprovalDetailDialog, ApprovalFormDialog, ApprovalImportDialog },
  data () {
    return {
      TYPE_MAP, STATUS_MAP,
      list: [], total: 0, page: 1, limit: 10, loading: false, exporting: false,
      stats: { total: 0, pending: 0, approved: 0, rejected: 0, month_new: 0, types: [] },
      filters: { keyword: '', department_id: '', approval_type: '', approval_status: '', source: '', dateRange: null },
      deptOptions: [],
      detailVisible: false, detailId: 0, formVisible: false, formId: 0, importVisible: false
    }
  },
  computed: {
    statCards () {
      const s = this.stats
      const typeText = (s.types || []).map(t => t.label + ':' + t.count).join(' ')
      return [
        { key: 'total', label: '总记录数', icon: 'el-icon-document', color: '#409EFF', value: s.total },
        { key: 'pending', label: '待审批数', icon: 'el-icon-time', color: '#E6A23C', value: s.pending },
        { key: 'approved', label: '已通过数', icon: 'el-icon-check', color: '#67C23A', value: s.approved },
        { key: 'rejected', label: '已驳回数', icon: 'el-icon-close', color: '#F56C6C', value: s.rejected },
        { key: 'month_new', label: '本月新增数', icon: 'el-icon-date', color: '#8E44AD', value: s.month_new },
        { key: 'types', label: '各类型数量', icon: 'el-icon-s-operation', color: '#909399', value: typeText }
      ]
    }
  },
  created () { this.loadDepts(); this.loadAll() },
  methods: {
    hasPerm (code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    typeStyle (t) { const c = TYPE_COLOR[t] || '#909399'; return { color: c, borderColor: c, background: c + '1a' } },
    statusType (s) { return { pending: 'warning', approved: 'success', rejected: 'danger', canceled: 'info' }[s] || 'info' },
    async loadDepts () {
      try { const r = await getDeptTree(); if (r.code === 0) this.deptOptions = flattenDept(r.data || []).map(d => ({ id: d.id, name: d.name })) } catch (e) {}
    },
    async loadAll () {
      this.loading = true
      try { await Promise.all([this.loadStats(), this.loadList()]) } catch (e) {} finally { this.loading = false }
    },
    async loadStats () {
      const r = await getApprovalStatistics()
      if (r.code === 0) this.stats = r.data || { total: 0, pending: 0, approved: 0, rejected: 0, month_new: 0, types: [] }
    },
    async loadList () {
      const params = { page: this.page, limit: this.limit }
      if (this.filters.keyword) params.keyword = this.filters.keyword
      if (this.filters.department_id) params.department_id = this.filters.department_id
      if (this.filters.approval_type) params.approval_type = this.filters.approval_type
      if (this.filters.approval_status) params.approval_status = this.filters.approval_status
      if (this.filters.source) params.source = this.filters.source
      if (this.filters.dateRange && this.filters.dateRange.length === 2) { params.start_date = this.filters.dateRange[0]; params.end_date = this.filters.dateRange[1] }
      const r = await getApprovalList(params)
      if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
    },
    onSearch () { this.page = 1; this.loadAll() },
    resetFilter () { this.filters = { keyword: '', department_id: '', approval_type: '', approval_status: '', source: '', dateRange: null }; this.page = 1; this.loadAll() },
    openDetail (row) { this.detailId = row.id; this.detailVisible = true },
    openEdit (row) { this.formId = row.id; this.formVisible = true },
    removeOne (row) {
      this.$confirm(`确定删除审批「${row.approval_code}」？`, '删除确认', { type: 'warning' }).then(async () => {
        try { const r = await deleteApproval(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadAll() } } catch (e) {}
      }).catch(() => {})
    },
    async doExport () {
      this.exporting = true
      try {
        const params = {}
        if (this.filters.keyword) params.keyword = this.filters.keyword
        if (this.filters.department_id) params.department_id = this.filters.department_id
        if (this.filters.approval_type) params.approval_type = this.filters.approval_type
        if (this.filters.approval_status) params.approval_status = this.filters.approval_status
        if (this.filters.source) params.source = this.filters.source
        if (this.filters.dateRange && this.filters.dateRange.length === 2) { params.start_date = this.filters.dateRange[0]; params.end_date = this.filters.dateRange[1] }
        const r = await exportApproval(params)
        if (r.code === 0 && r.data && r.data.url) window.open(r.data.url, '_blank')
        else this.$message.error('导出失败')
      } catch (e) {} finally { this.exporting = false }
    }
  }
}
</script>

<style scoped>
.approval-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.stat-row { margin-bottom: 16px; }
.stat-card { background: #fff; border-radius: 8px; border-top: 3px solid #409EFF; padding: 14px; display: flex; align-items: center; box-shadow: 0 1px 4px rgba(0,0,0,.04); }
.stat-icon { width: 44px; height: 44px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 22px; margin-right: 12px; }
.stat-value { font-size: 24px; font-weight: 700; }
.stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.filter-card { margin-bottom: 16px; }
.list-card .toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; font-size: 13px; color: #606266; }
.pager { margin-top: 14px; text-align: right; }
</style>
