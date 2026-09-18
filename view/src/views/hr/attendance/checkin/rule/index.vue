<template>
  <div class="rule-page">
    <!-- 操作按钮栏 -->
    <el-card shadow="never" class="toolbar-card">
      <div class="toolbar">
        <div>
          <el-button v-if="hasPerm('attendance:rule:manage')" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增规则</el-button>
          <el-button v-if="hasPerm('attendance:rule:manage')" size="small" icon="el-icon-star-off" :disabled="!selectedRow" @click="setDefault">设为默认</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadAll">刷新</el-button>
        </div>
        <span class="stat-text">共 <b>{{ total }}</b> 条规则</span>
      </div>
    </el-card>

    <!-- 筛选 -->
    <el-card shadow="never" class="filter-card">
      <el-form :inline="true" size="small" @submit.native.prevent>
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="搜索规则名称" clearable style="width:200px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width:120px" @change="onSearch">
            <el-option label="启用" value="enabled" />
            <el-option label="停用" value="disabled" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilter">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 列表 -->
    <el-card shadow="never" class="list-card">
      <el-table :data="list" v-loading="loading" size="small" stripe highlight-current-row @current-change="row => { selectedRow = row }">
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column prop="rule_name" label="规则名称" width="140" show-overflow-tooltip />
        <el-table-column label="规则类型" width="100" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.rule_type === 1 ? 'info' : 'primary'">{{ row.rule_type_label }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="department_names" label="关联部门" width="160" show-overflow-tooltip />
        <el-table-column label="打卡次数" width="90" align="center">
          <template slot-scope="{ row }">{{ row.checkin_count_label }}</template>
        </el-table-column>
        <el-table-column prop="time_display" label="打卡时间" width="200" show-overflow-tooltip />
        <el-table-column prop="advance_delay" label="提前/延迟" width="150" />
        <el-table-column prop="grace_time" label="宽限时间" width="140" />
        <el-table-column prop="weekdays_label" label="适用工作日" width="160" show-overflow-tooltip />
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="row.status === 1 ? 'success' : 'info'">{{ row.status_label }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" align="center">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('attendance:rule:manage')" type="text" size="mini" icon="el-icon-edit" @click="openForm(row.id)">编辑</el-button>
            <el-button v-if="hasPerm('attendance:rule:manage')" type="text" size="mini" icon="el-icon-switch-button" @click="toggle(row)">{{ row.status === 1 ? '停用' : '启用' }}</el-button>
            <el-button v-if="hasPerm('attendance:rule:manage') && row.rule_type === 1" type="text" size="mini" icon="el-icon-delete" style="color:#F56C6C" @click="removeOne(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination class="pager" background layout="total, sizes, prev, pager, next" :total="total"
        :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50]"
        @size-change="s => { limit = s; page = 1; loadAll() }"
        @current-change="p => { page = p; loadAll() }" />
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <rule-form v-if="formVisible" :visible.sync="formVisible" :rule-id="currentId" @saved="loadAll" />
  </div>
</template>

<script>
import { getRuleList, deleteRule, toggleRule, setDefaultRule } from '@/api/attendanceRule'
import RuleForm from './components/RuleForm.vue'

export default {
  name: 'AttendanceRule',
  components: { RuleForm },
  data () {
    return {
      list: [], total: 0, page: 1, limit: 10, loading: false,
      filters: { keyword: '', status: '' },
      formVisible: false, currentId: 0, selectedRow: null
    }
  },
  created () { this.loadAll() },
  methods: {
    hasPerm (code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    async loadAll () {
      this.loading = true
      try {
        const params = { page: this.page, limit: this.limit }
        if (this.filters.keyword) params.keyword = this.filters.keyword
        if (this.filters.status) params.status = this.filters.status
        const r = await getRuleList(params)
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    onSearch () { this.page = 1; this.loadAll() },
    resetFilter () { this.filters = { keyword: '', status: '' }; this.page = 1; this.loadAll() },
    openForm (id) { this.currentId = id || 0; this.formVisible = true },
    async toggle (row) {
      try {
        const r = await toggleRule(row.id, row.status === 1 ? 0 : 1)
        if (r.code === 0) { this.$message.success(r.msg || '操作成功'); this.loadAll() }
      } catch (e) {}
    },
    setDefault () {
      if (!this.selectedRow) { this.$message.warning('请先选择一条规则'); return }
      this.$confirm(`确认将规则「${this.selectedRow.rule_name}」设为默认规则？`, '设为默认', { type: 'warning' }).then(async () => {
        try {
          const r = await setDefaultRule(this.selectedRow.id)
          if (r.code === 0) { this.$message.success(r.msg || '已设为默认'); this.loadAll() }
        } catch (e) {}
      }).catch(() => {})
    },
    removeOne (row) {
      this.$confirm(`确认删除规则「${row.rule_name}」吗？`, '提示', {
        type: 'warning', confirmButtonText: '确认删除', cancelButtonText: '取消'
      }).then(async () => {
        try {
          const r = await deleteRule(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.loadAll() }
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.rule-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.toolbar-card { margin-bottom: 16px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; }
.stat-text { font-size: 13px; color: #606266; }
.filter-card { margin-bottom: 16px; }
.pager { margin-top: 14px; text-align: right; }
</style>
