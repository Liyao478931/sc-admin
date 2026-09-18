<template>
  <div class="accident-investigate-page">
    <!-- 统计卡片 -->
    <el-row :gutter="12" style="margin-bottom:16px;">
      <el-col :span="6" v-for="card in statCards" :key="card.label">
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
            <el-option label="待分配" value="pending" /><el-option label="调查中" value="investigating" /><el-option label="已结案" value="closed" />
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
          <span style="margin-right:12px;font-size:13px;color:#909399;">共 {{ total }} 条任务</span>
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
        <el-table-column prop="accident_name" label="事故名称" min-width="150" show-overflow-tooltip />
        <el-table-column label="事故类型" width="95" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="typeTag(row.accident_type)">{{ row.type_text }}</el-tag></template>
        </el-table-column>
        <el-table-column label="事故等级" width="85" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="levelTag(row.accident_level)">{{ row.level_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="happen_time" label="发生时间" width="155" align="center" />
        <el-table-column prop="happen_location" label="发生地点" min-width="110" show-overflow-tooltip />
        <el-table-column label="调查状态" width="90" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="invStatusTag(row.inv_status)">{{ row.inv_status_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="investigator_name" label="调查人" width="85" align="center">
          <template slot-scope="{ row }">{{ row.investigator_name || '-' }}</template>
        </el-table-column>
        <el-table-column label="调查期限" width="110" align="center">
          <template slot-scope="{ row }">
            <span v-if="row.investigation_deadline" :style="row.overdue ? 'color:#F56C6C;font-weight:600;' : ''">
              {{ row.investigation_deadline }}{{ row.overdue ? ' 已超期' : '' }}
            </span>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="210" align="center" fixed="right">
          <template slot-scope="{ row }">
            <template v-if="row.inv_status === 'pending'">
              <el-button v-if="hasPerm('safety:accident:investigate:assign')" size="mini" type="text" style="color:#E6A23C" @click="openAssign(row)">分配</el-button>
              <el-button v-if="hasPerm('safety:accident:investigate:query')" size="mini" type="text" @click="openDetail(row)">详情</el-button>
            </template>
            <template v-else-if="row.inv_status === 'investigating'">
              <el-button v-if="hasPerm('safety:accident:investigate:edit')" size="mini" type="text" @click="openReport(row)">填写报告</el-button>
              <el-button v-if="hasPerm('safety:accident:investigate:start')" size="mini" type="text" @click="doStart(row)">开始调查</el-button>
              <el-button v-if="hasPerm('safety:accident:investigate:approve') && row.submit_status === 'pending'" size="mini" type="text" style="color:#67C23A" @click="openApprove(row)">审批</el-button>
            </template>
            <template v-else>
              <el-button v-if="hasPerm('safety:accident:investigate:query')" size="mini" type="text" @click="openReport(row)">查看报告</el-button>
              <el-button v-if="hasPerm('safety:accident:investigate:export')" size="mini" type="text" @click="doExport(row)">导出</el-button>
            </template>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination style="margin-top:12px;text-align:right" background layout="total, sizes, prev, pager, next"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10, 20, 50]" @current-change="loadList" @size-change="loadList" />
    </el-card>

    <investigate-assign-dialog :visible.sync="assignVisible" :row="assignRow" @saved="onSaved" />
    <investigate-report-dialog :visible.sync="reportVisible" :row="reportRow" @saved="onSaved" />
    <investigate-approve-dialog :visible.sync="approveVisible" :row="approveRow" @saved="onSaved" />
  </div>
</template>

<script>
import { getInvestigateList, getInvestigateStatistics, startInvestigate, exportInvestigate } from '@/api/safetyAccident'
import { getDictByCode } from '@/api/dictionary'
import InvestigateAssignDialog from './components/InvestigateAssignDialog.vue'
import InvestigateReportDialog from './components/InvestigateReportDialog.vue'
import InvestigateApproveDialog from './components/InvestigateApproveDialog.vue'

export default {
  name: 'AccidentInvestigate',
  components: { InvestigateAssignDialog, InvestigateReportDialog, InvestigateApproveDialog },
  data() {
    return {
      loading: false, list: [], total: 0, page: 1, limit: 10,
      filters: { keyword: '', accident_type: '', accident_level: '', status: '' },
      dateRange: null,
      typeOptions: [], levelOptions: [],
      statCards: [
        { label: '待分配', value: 0, icon: 'el-icon-time', color: '#E6A23C', bg: 'rgba(230,162,60,.12)' },
        { label: '调查中', value: 0, icon: 'el-icon-loading', color: '#409EFF', bg: 'rgba(64,158,255,.12)' },
        { label: '已结案', value: 0, icon: 'el-icon-circle-check', color: '#67C23A', bg: 'rgba(103,194,58,.12)' },
        { label: '超时调查', value: 0, icon: 'el-icon-warning', color: '#F56C6C', bg: 'rgba(245,108,108,.12)' },
      ],
      assignVisible: false, reportVisible: false, approveVisible: false,
      assignRow: null, reportRow: null, approveRow: null,
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
        const [t, l] = await Promise.all([getDictByCode('safety_accident_type'), getDictByCode('safety_accident_level')])
        this.typeOptions = (t.data || []).map(x => ({ label: x.label, value: x.value }))
        this.levelOptions = (l.data || []).map(x => ({ label: x.label, value: x.value }))
      } catch (e) {}
    },
    buildParams(extra = {}) {
      const p = {
        page: this.page, limit: this.limit,
        keyword: this.filters.keyword || '',
        accident_type: this.filters.accident_type || '',
        accident_level: this.filters.accident_level || '',
        status: this.filters.status || '',
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
        const r = await getInvestigateList(this.buildParams())
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    async loadStatistics() {
      try {
        const r = await getInvestigateStatistics()
        if (r.code === 0 && r.data) {
          this.statCards[0].value = r.data.pending || 0
          this.statCards[1].value = r.data.investigating || 0
          this.statCards[2].value = r.data.closed || 0
          this.statCards[3].value = r.data.overdue || 0
        }
      } catch (e) {}
    },
    loadAll() { this.loadList(); this.loadStatistics() },
    onSearch() { this.page = 1; this.loadAll() },
    resetFilters() { this.filters = { keyword: '', accident_type: '', accident_level: '', status: '' }; this.dateRange = null; this.page = 1; this.loadAll() },
    typeTag(t) { return { personal_injury: 'danger', equipment_damage: 'warning', fire: 'danger', explosion: 'danger', leakage: 'warning', other: 'info' }[t] || 'info' },
    levelTag(l) { return { general: '', major: 'warning', serious: 'danger', critical: 'danger' }[l] || 'info' },
    invStatusTag(s) { return { pending: 'warning', investigating: '', closed: 'success' }[s] || 'info' },
    onSaved() { this.loadAll() },
    openAssign(row) { this.assignRow = row; this.assignVisible = true },
    openReport(row) { this.reportRow = row; this.reportVisible = true },
    openApprove(row) { this.approveRow = row; this.approveVisible = true },
    openDetail(row) { this.reportRow = row; this.reportVisible = true },
    doStart(row) {
      this.$confirm(`确认开始调查「${row.accident_name}」？`, '开始调查', { type: 'warning' }).then(async () => {
        try { const r = await startInvestigate(row.id); if (r.code === 0) { this.$message.success('已开始调查'); this.loadAll() } } catch (e) {}
      }).catch(() => {})
    },
    async doExport(row) {
      try {
        const r = await exportInvestigate(row.id)
        if (r.code === 0 && r.data.url) window.open(r.data.url, '_blank')
      } catch (e) {}
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
