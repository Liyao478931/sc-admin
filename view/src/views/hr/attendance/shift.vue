<template>
  <div class="shift-page">
    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="5" v-for="card in statCards" :key="card.key">
        <div class="stat-card" :style="{ borderTopColor: card.color }">
          <div class="stat-icon" :style="{ background: card.color + '1a', color: card.color }"><i :class="card.icon"></i></div>
          <div class="stat-body"><div class="stat-value" :style="{ color: card.color }">{{ card.value }}</div><div class="stat-label">{{ card.label }}</div></div>
        </div>
      </el-col>
    </el-row>

    <!-- 筛选区域 -->
    <el-card shadow="never" class="filter-card">
      <el-form :inline="true" size="small" @submit.native.prevent>
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入班次名称或编码" clearable style="width:200px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.category" clearable placeholder="全部分类" style="width:120px" @change="onSearch">
            <el-option v-for="opt in categoryOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width:110px" @change="onSearch">
            <el-option label="启用" value="1" /><el-option label="停用" value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.department_id" clearable placeholder="全部部门" style="width:140px" @change="onSearch">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
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
        <span>共 <b>{{ total }}</b> 条班次</span>
        <div>
          <el-button size="small" type="primary" icon="el-icon-plus" @click="openForm()">新增班次</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadAll">刷新</el-button>
        </div>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe>
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column prop="shift_code" label="班次编码" width="120" />
        <el-table-column prop="shift_name" label="班次名称" min-width="120" show-overflow-tooltip />
        <el-table-column label="班次类别" width="100" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.shift_category === 'flexible' ? 'success' : 'primary'">{{ row.shift_category_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="上班时间" width="100" align="center">
          <template slot-scope="{ row }">{{ (row.start_time || '').substring(0, 5) }}</template>
        </el-table-column>
        <el-table-column label="下班时间" width="100" align="center">
          <template slot-scope="{ row }">{{ (row.end_time || '').substring(0, 5) }}</template>
        </el-table-column>
        <el-table-column label="打卡次数" width="90" align="center">
          <template slot-scope="{ row }">{{ row.clock_count }}次</template>
        </el-table-column>
        <el-table-column label="迟到规则" width="120" align="center">
          <template slot-scope="{ row }">允许{{ row.late_minutes }}分钟</template>
        </el-table-column>
        <el-table-column label="早退规则" width="120" align="center">
          <template slot-scope="{ row }">允许{{ row.early_minutes }}分钟</template>
        </el-table-column>
        <el-table-column prop="department_text" label="适用部门" min-width="140" show-overflow-tooltip />
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.status === 1 ? 'success' : 'info'">{{ row.status === 1 ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="220" align="center">
          <template slot-scope="{ row }">
            <el-button type="text" size="mini" @click="openForm(row)">编辑</el-button>
            <el-button type="text" size="mini" @click="copyOne(row)">复制</el-button>
            <el-button type="text" size="mini" style="color:#F56C6C" @click="removeOne(row)">删除</el-button>
            <el-button type="text" size="mini" @click="toggle(row)">{{ row.status === 1 ? '停用' : '启用' }}</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination class="pager" background layout="total, sizes, prev, pager, next" :total="total"
        :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50]"
        @size-change="s => { limit = s; page = 1; loadAll() }"
        @current-change="p => { page = p; loadAll() }" />
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <shift-form-dialog v-if="formVisible" :visible.sync="formVisible" :form-id="formId" @saved="onSaved" />
  </div>
</template>

<script>
import { getShiftList, getShiftStatistics, deleteShift, copyShift, toggleShiftStatus } from '@/api/attendanceShift'
import { getDeptTree } from '@/api/organization'
import ShiftFormDialog from './components/ShiftFormDialog.vue'

function flattenDept (nodes) {
  let r = []
  for (const n of nodes || []) { r.push(n); if (n.children) r = r.concat(flattenDept(n.children)) }
  return r
}

export default {
  name: 'AttendanceShift',
  components: { ShiftFormDialog },
  data () {
    return {
      list: [], total: 0, page: 1, limit: 10, loading: false,
      stats: { total: 0, fixed: 0, flexible: 0, enabled: 0, disabled: 0 },
      filters: { keyword: '', category: '', status: '', department_id: '' },
      deptOptions: [],
      categoryOptions: [],
      formVisible: false, formId: 0
    }
  },
  computed: {
    statCards () {
      const s = this.stats
      return [
        { key: 'total', label: '班次总数', icon: 'el-icon-time', color: '#409EFF', value: s.total },
        { key: 'fixed', label: '固定班次', icon: 'el-icon-s-flag', color: '#409EFF', value: s.fixed },
        { key: 'flexible', label: '弹性班次', icon: 'el-icon-s-operation', color: '#67C23A', value: s.flexible },
        { key: 'enabled', label: '启用数', icon: 'el-icon-check', color: '#67C23A', value: s.enabled },
        { key: 'disabled', label: '停用数', icon: 'el-icon-close', color: '#909399', value: s.disabled }
      ]
    }
  },
  created () {
    // 主动刷新权限（与其他页面惯例一致），确保新导入的班次权限即时生效
    this.$store.dispatch('user/loadPermissions')
    this.loadAll(); this.loadDepts(); this.loadDicts()
  },
  methods: {
    // 班次类别从字典动态加载
    async loadDicts () {
      const { getDictByCode } = await import('../../../api/dictionary')
      try { const r = await getDictByCode('attendance_shift_category'); this.categoryOptions = r.data || [] } catch (e) { this.categoryOptions = [] }
    },
    hasPerm (code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    async loadDepts () {
      try {
        const r = await getDeptTree()
        if (r.code === 0) this.deptOptions = flattenDept(r.data || []).map(d => ({ id: d.id, name: d.name }))
      } catch (e) {}
    },
    async loadAll () {
      this.loading = true
      try { await Promise.all([this.loadStats(), this.loadList()]) } catch (e) {} finally { this.loading = false }
    },
    async loadStats () {
      const r = await getShiftStatistics()
      if (r.code === 0) this.stats = r.data || { total: 0, fixed: 0, flexible: 0, enabled: 0, disabled: 0 }
    },
    async loadList () {
      const params = { page: this.page, limit: this.limit }
      if (this.filters.keyword) params.keyword = this.filters.keyword
      if (this.filters.category) params.category = this.filters.category
      if (this.filters.status !== '' && this.filters.status !== null) params.status = this.filters.status
      if (this.filters.department_id) params.department_id = this.filters.department_id
      const r = await getShiftList(params)
      if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
    },
    onSearch () { this.page = 1; this.loadAll() },
    resetFilter () { this.filters = { keyword: '', category: '', status: '', department_id: '' }; this.page = 1; this.loadAll() },
    openForm (row) { this.formId = row ? row.id : 0; this.formVisible = true },
    onSaved () { this.formVisible = false; this.loadAll() },
    copyOne (row) {
      this.$confirm(`确认复制班次「${row.shift_name}」？`, '复制确认', { type: 'warning' }).then(async () => {
        try {
          const r = await copyShift(row.id)
          if (r.code === 0) { this.$message.success('复制成功'); this.loadAll() }
        } catch (e) {}
      }).catch(() => {})
    },
    removeOne (row) {
      this.$confirm(`确定删除班次「${row.shift_name}」？`, '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteShift(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.loadAll() }
        } catch (e) {}
      }).catch(() => {})
    },
    toggle (row) {
      const target = row.status === 1 ? 0 : 1
      this.$confirm(`确认${target === 1 ? '启用' : '停用'}班次「${row.shift_name}」？`, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await toggleShiftStatus(row.id, target)
          if (r.code === 0) { this.$message.success(r.msg || '操作成功'); this.loadAll() }
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.shift-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.stat-row { margin-bottom: 16px; }
.stat-card { background: #fff; border-radius: 8px; border-top: 3px solid #409EFF; padding: 14px; display: flex; align-items: center; box-shadow: 0 1px 4px rgba(0,0,0,.04); }
.stat-icon { width: 44px; height: 44px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 22px; margin-right: 12px; }
.stat-value { font-size: 24px; font-weight: 700; }
.stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.filter-card { margin-bottom: 16px; }
.list-card .toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; font-size: 13px; color: #606266; }
.pager { margin-top: 14px; text-align: right; }
</style>
