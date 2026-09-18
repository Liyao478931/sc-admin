<template>
  <div class="risk-assess-page">
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
          <el-input v-model="filters.keyword" placeholder="请输入风险名称或编号" clearable style="width:200px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.risk_type" clearable placeholder="全部类型" style="width:120px" @change="onSearch">
            <el-option v-for="t in typeOptions" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-input v-model="filters.area" placeholder="请输入所属区域" clearable style="width:150px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="~" start-placeholder="开始日期" end-placeholder="结束日期" style="width:240px" @change="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilters">重置</el-button>
        </el-form-item>
        <el-form-item style="float:right">
          <span style="margin-right:12px;font-size:13px;color:#909399;">共 {{ total }} 条待评估风险</span>
          <el-button v-if="hasPerm('safety:risk:assess:export')" icon="el-icon-upload2" :loading="exporting" @click="doExport">导出</el-button>
          <el-button icon="el-icon-refresh" @click="loadAll">刷新</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 表格 -->
    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column label="风险编号" width="150">
          <template slot-scope="{ row }">
            <el-link type="primary" :underline="false" @click="openAssess(row)">{{ row.risk_code }}</el-link>
          </template>
        </el-table-column>
        <el-table-column prop="risk_name" label="风险名称" min-width="160" show-overflow-tooltip />
        <el-table-column label="风险类型" width="100" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="typeTag(row.risk_type)">{{ row.type_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="area" label="所属区域" width="120" show-overflow-tooltip />
        <el-table-column prop="department_name" label="所属部门" width="120" show-overflow-tooltip />
        <el-table-column prop="responsible_person_name" label="责任人" width="80" align="center" />
        <el-table-column prop="identify_date" label="辨识日期" width="120" align="center" />
        <el-table-column label="操作" width="160" align="center" fixed="right">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('safety:risk:assess:add')" size="mini" type="text" style="color:#67C23A" @click="openAssess(row)">评估</el-button>
            <el-button v-if="hasPerm('safety:risk:assess:query')" size="mini" type="text" @click="openHistory(row)">历史</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination style="margin-top:12px;text-align:right" background layout="total, sizes, prev, pager, next"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10, 20, 50]" @current-change="loadList" @size-change="loadList" />
    </el-card>

    <assess-form-dialog :visible.sync="assessVisible" :row="assessRow" @saved="onSaved" />
    <assess-history-dialog :visible.sync="historyVisible" :row="historyRow" />
  </div>
</template>

<script>
import { getAssessList, getAssessStatistics, exportAssess } from '@/api/safetyRisk'
import { getDictByCode } from '@/api/dictionary'
import AssessFormDialog from './components/AssessFormDialog.vue'
import AssessHistoryDialog from './components/AssessHistoryDialog.vue'

export default {
  name: 'RiskAssess',
  components: { AssessFormDialog, AssessHistoryDialog },
  data() {
    return {
      loading: false, exporting: false, list: [], total: 0, page: 1, limit: 10,
      filters: { keyword: '', risk_type: '', area: '' },
      dateRange: null,
      typeOptions: [],
      statCards: [
        { label: '待评估数', value: 0, icon: 'el-icon-time', color: '#E6A23C', bg: 'rgba(230,162,60,.12)' },
        { label: '已评估数', value: 0, icon: 'el-icon-check', color: '#67C23A', bg: 'rgba(103,194,58,.12)' },
        { label: '低风险数', value: 0, icon: 'el-icon-success', color: '#67C23A', bg: 'rgba(103,194,58,.12)' },
        { label: '一般风险数', value: 0, icon: 'el-icon-info', color: '#409EFF', bg: 'rgba(64,158,255,.12)' },
        { label: '较大风险数', value: 0, icon: 'el-icon-warning', color: '#E6A23C', bg: 'rgba(230,162,60,.12)' },
        { label: '重大风险数', value: 0, icon: 'el-icon-danger', color: '#F56C6C', bg: 'rgba(245,108,108,.12)' },
      ],
      assessVisible: false, historyVisible: false, assessRow: null, historyRow: null,
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
        const t = await getDictByCode('safety_risk_type')
        this.typeOptions = (t.data || []).map(x => ({ label: x.label, value: x.value }))
      } catch (e) {}
    },
    buildParams(extra = {}) {
      const p = {
        page: this.page, limit: this.limit,
        keyword: this.filters.keyword || '',
        risk_type: this.filters.risk_type || '',
        area: this.filters.area || '',
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
        const r = await getAssessList(this.buildParams())
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    async loadStatistics() {
      try {
        const r = await getAssessStatistics()
        if (r.code === 0 && r.data) {
          this.statCards[0].value = r.data.pending || 0
          this.statCards[1].value = r.data.assessed || 0
          this.statCards[2].value = r.data.low || 0
          this.statCards[3].value = r.data.general || 0
          this.statCards[4].value = r.data.major || 0
          this.statCards[5].value = r.data.critical || 0
        }
      } catch (e) {}
    },
    loadAll() { this.loadList(); this.loadStatistics() },
    onSearch() { this.page = 1; this.loadAll() },
    resetFilters() { this.filters = { keyword: '', risk_type: '', area: '' }; this.dateRange = null; this.page = 1; this.loadAll() },
    typeTag(t) { return { physical: '', chemical: 'warning', biological: 'success', ergonomic: 'info', management: 'warning', other: 'info' }[t] || 'info' },
    onSaved() { this.loadAll() },
    openAssess(row) { this.assessRow = row; this.assessVisible = true },
    openHistory(row) { this.historyRow = row; this.historyVisible = true },
    async doExport() {
      this.exporting = true
      try {
        const r = await exportAssess(this.buildParams())
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
