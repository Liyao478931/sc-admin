<template>
  <div class="accident-register-page">
    <!-- 统计卡片 -->
    <el-row :gutter="12" style="margin-bottom:16px;">
      <el-col :span="4" v-for="card in statCards" :key="card.label">
        <el-card shadow="never" :body-style="{ padding: '14px 16px' }">
          <div class="stat-card">
            <div class="stat-icon" :style="{ background: card.bg, color: card.color }"><i :class="card.icon" /></div>
            <div class="stat-info"><div class="stat-num">{{ card.value }}</div><div class="stat-label">{{ card.label }}</div></div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 筛选 + 工具栏 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <el-form :inline="true" size="small" @submit.native.prevent>
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入事故名称或编号" clearable style="width:180px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.accident_type" clearable placeholder="全部类型" style="width:120px" @change="onSearch">
            <el-option v-for="t in typeOptions" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.accident_level" clearable placeholder="全部等级" style="width:120px" @change="onSearch">
            <el-option v-for="l in levelOptions" :key="l.value" :label="l.label" :value="l.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width:120px" @change="onSearch">
            <el-option label="待调查" value="pending" /><el-option label="调查中" value="investigating" />
            <el-option label="已结案" value="closed" /><el-option label="已归档" value="archived" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.department_id" clearable placeholder="全部部门" style="width:140px" @change="onSearch">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="~" start-placeholder="开始日期" end-placeholder="结束日期" style="width:240px" @change="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilters">重置</el-button>
        </el-form-item>
        <el-form-item style="float:right">
          <span style="margin-right:12px;font-size:13px;color:#909399;">共 {{ total }} 条事故</span>
          <el-button v-if="hasPerm('safety:accident:add')" type="primary" icon="el-icon-plus" @click="openAdd">新增事故</el-button>
          <el-button v-if="hasPerm('safety:accident:export')" icon="el-icon-upload2" :loading="exporting" @click="doExport">导出</el-button>
          <el-button icon="el-icon-refresh" @click="loadAll">刷新</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 表格 -->
    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column label="事故编号" width="160">
          <template slot-scope="{ row }">
            <el-link type="primary" :underline="false" @click="openDetail(row)">{{ row.accident_code }}</el-link>
          </template>
        </el-table-column>
        <el-table-column prop="accident_name" label="事故名称" min-width="160" show-overflow-tooltip />
        <el-table-column label="事故类型" width="100" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="typeTag(row.accident_type)">{{ row.type_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="事故等级" width="90" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="levelTag(row.accident_level)">{{ row.level_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="happen_time" label="发生时间" width="160" align="center" />
        <el-table-column prop="happen_location" label="发生地点" min-width="120" show-overflow-tooltip />
        <el-table-column prop="total_injuries" label="伤亡人数" width="80" align="center" />
        <el-table-column prop="economic_loss" label="损失(万元)" width="90" align="center" />
        <el-table-column prop="registrant_name" label="登记人" width="80" align="center" />
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="statusTag(row.status)">{{ row.status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" align="center" fixed="right">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('safety:accident:query')" size="mini" type="text" @click="openDetail(row)">详情</el-button>
            <el-button v-if="row.status === 'pending' && hasPerm('safety:accident:edit')" size="mini" type="text" @click="openEdit(row)">编辑</el-button>
            <el-button v-if="row.status === 'pending' && hasPerm('safety:accident:delete')" size="mini" type="text" style="color:#F56C6C" @click="doDelete(row)">删除</el-button>
            <el-button v-if="row.status !== 'archived' && hasPerm('safety:accident:edit')" size="mini" type="text" style="color:#67C23A" @click="openStatus(row)">状态</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination style="margin-top:12px;text-align:right" background layout="total, sizes, prev, pager, next"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10, 20, 50]" @current-change="loadList" @size-change="loadList" />
    </el-card>

    <accident-form-dialog :visible.sync="formVisible" :row="currentRow" :type-options="typeOptions"
      :level-options="levelOptions" :dept-options="deptOptions" @saved="onSaved" />
    <accident-detail-dialog :visible.sync="detailVisible" :row="detailRow" />
    <accident-status-dialog :visible.sync="statusVisible" :row="statusRow" @saved="onSaved" />
  </div>
</template>

<script>
import { getAccidentList, getAccidentStatistics, deleteAccident, exportAccident } from '@/api/safetyAccident'
import { getDictByCode } from '@/api/dictionary'
import { getDeptTree } from '@/api/organization'
import AccidentFormDialog from './components/AccidentFormDialog.vue'
import AccidentDetailDialog from './components/AccidentDetailDialog.vue'
import AccidentStatusDialog from './components/AccidentStatusDialog.vue'

export default {
  name: 'AccidentRegister',
  components: { AccidentFormDialog, AccidentDetailDialog, AccidentStatusDialog },
  data() {
    return {
      loading: false, exporting: false, list: [], total: 0, page: 1, limit: 10,
      filters: { keyword: '', accident_type: '', accident_level: '', status: '', department_id: null },
      dateRange: null,
      typeOptions: [], levelOptions: [], deptOptions: [],
      statCards: [
        { label: '事故总数', value: 0, icon: 'el-icon-document', color: '#409EFF', bg: 'rgba(64,158,255,.12)' },
        { label: '待调查数', value: 0, icon: 'el-icon-time', color: '#E6A23C', bg: 'rgba(230,162,60,.12)' },
        { label: '调查中数', value: 0, icon: 'el-icon-loading', color: '#8B5CF6', bg: 'rgba(139,92,246,.12)' },
        { label: '本月事故数', value: 0, icon: 'el-icon-date', color: '#F56C6C', bg: 'rgba(245,108,108,.12)' },
        { label: '总伤亡人数', value: 0, icon: 'el-icon-user', color: '#F56C6C', bg: 'rgba(245,108,108,.12)' },
        { label: '总损失(万元)', value: 0, icon: 'el-icon-money', color: '#E6A23C', bg: 'rgba(230,162,60,.12)' },
      ],
      formVisible: false, detailVisible: false, statusVisible: false,
      currentRow: null, detailRow: null, statusRow: null,
    }
  },
  created() {
    if (this.$store.state.user && this.$store.state.user.permissions && !this.$store.state.user.permissions.length) {
      this.$store.dispatch('user/loadPermissions')
    }
    this.loadOptions()
    this.loadAll()
  },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    async loadOptions() {
      try {
        const [t, l, d] = await Promise.all([getDictByCode('safety_accident_type'), getDictByCode('safety_accident_level'), getDeptTree()])
        this.typeOptions = (t.data || []).map(x => ({ label: x.label, value: x.value }))
        this.levelOptions = (l.data || []).map(x => ({ label: x.label, value: x.value }))
        this.deptOptions = d.data || []
      } catch (e) {}
    },
    buildParams(extra = {}) {
      const p = {
        page: this.page, limit: this.limit,
        keyword: this.filters.keyword || '',
        accident_type: this.filters.accident_type || '',
        accident_level: this.filters.accident_level || '',
        status: this.filters.status || '',
        department_id: this.filters.department_id || '',
        ...extra,
      }
      if (this.dateRange && this.dateRange.length === 2) {
        p.start_date = this.dateRange[0]
        p.end_date = this.dateRange[1]
      }
      return p
    },
    async loadList() {
      this.loading = true
      try {
        const r = await getAccidentList(this.buildParams())
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    async loadStatistics() {
      try {
        const r = await getAccidentStatistics()
        if (r.code === 0 && r.data) {
          const d = r.data
          this.statCards[0].value = d.total || 0
          this.statCards[1].value = d.pending || 0
          this.statCards[2].value = d.investigating || 0
          this.statCards[3].value = d.month || 0
          this.statCards[4].value = d.total_injuries || 0
          this.statCards[5].value = d.total_loss || 0
        }
      } catch (e) {}
    },
    loadAll() { this.loadList(); this.loadStatistics() },
    onSearch() { this.page = 1; this.loadAll() },
    resetFilters() {
      this.filters = { keyword: '', accident_type: '', accident_level: '', status: '', department_id: null }
      this.dateRange = null; this.page = 1; this.loadAll()
    },
    typeTag(t) { return { personal_injury: 'danger', equipment_damage: 'warning', fire: 'danger', explosion: 'danger', leakage: 'warning', other: 'info' }[t] || 'info' },
    levelTag(l) { return { general: '', major: 'warning', serious: 'danger', critical: 'danger' }[l] || 'info' },
    statusTag(s) { return { pending: 'warning', investigating: '', closed: 'success', archived: 'info' }[s] || 'info' },
    onSaved() { this.loadAll() },
    openAdd() { this.currentRow = null; this.formVisible = true },
    openEdit(row) { this.currentRow = row; this.formVisible = true },
    openDetail(row) { this.detailRow = row; this.detailVisible = true },
    openStatus(row) { this.statusRow = row; this.statusVisible = true },
    doDelete(row) {
      this.$confirm(`确认删除事故「${row.accident_name}」？`, '删除确认', { type: 'warning' }).then(async () => {
        try { const r = await deleteAccident(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadAll() } } catch (e) {}
      }).catch(() => {})
    },
    async doExport() {
      this.exporting = true
      try {
        const r = await exportAccident(this.buildParams())
        if (r.code === 0 && r.data.url) { window.open(r.data.url, '_blank'); this.$message.success('导出成功') }
      } catch (e) {}
      this.exporting = false
    },
  },
}
</script>

<style scoped>
.stat-card { display: flex; align-items: center; }
.stat-icon { width: 46px; height: 46px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 24px; margin-right: 12px; }
.stat-num { font-size: 22px; font-weight: 600; line-height: 1.2; }
.stat-label { font-size: 13px; color: #909399; }
</style>
