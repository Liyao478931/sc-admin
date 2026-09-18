<template>
  <div class="risk-identify-page">
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
          <el-select v-model="filters.risk_level" clearable placeholder="全部等级" style="width:120px" @change="onSearch">
            <el-option v-for="l in levelOptions" :key="l.value" :label="l.label" :value="l.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width:110px" @change="onSearch">
            <el-option v-for="opt in riskStatusOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-input v-model="filters.area" placeholder="请输入所属区域" clearable style="width:150px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.department_id" clearable placeholder="全部部门" style="width:130px" @change="onSearch">
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
          <span style="margin-right:12px;font-size:13px;color:#909399;">共 {{ total }} 条风险</span>
          <el-button v-if="hasPerm('safety:risk:identify:add')" type="primary" icon="el-icon-plus" @click="openAdd">新增风险</el-button>
          <el-button v-if="hasPerm('safety:risk:identify:export')" icon="el-icon-upload2" :loading="exporting" @click="doExport">导出</el-button>
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
            <el-link type="primary" :underline="false" @click="openDetail(row)">{{ row.risk_code }}</el-link>
          </template>
        </el-table-column>
        <el-table-column prop="risk_name" label="风险名称" min-width="160" show-overflow-tooltip />
        <el-table-column label="风险类型" width="100" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="typeTag(row.risk_type)">{{ row.type_text }}</el-tag></template>
        </el-table-column>
        <el-table-column label="风险等级" width="90" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="levelTag(row.risk_level)">{{ row.level_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="area" label="所属区域" width="120" show-overflow-tooltip />
        <el-table-column prop="department_name" label="所属部门" width="120" show-overflow-tooltip />
        <el-table-column prop="responsible_person_name" label="责任人" width="80" align="center" />
        <el-table-column prop="identify_date" label="辨识日期" width="120" align="center" />
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="statusTag(row.status)">{{ row.status_text }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="220" align="center" fixed="right">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('safety:risk:identify:query')" size="mini" type="text" @click="openDetail(row)">详情</el-button>
            <el-button v-if="row.status === 'pending' && hasPerm('safety:risk:identify:edit')" size="mini" type="text" @click="openEdit(row)">编辑</el-button>
            <el-button v-if="row.status === 'pending' && hasPerm('safety:risk:identify:delete')" size="mini" type="text" style="color:#F56C6C" @click="doDelete(row)">删除</el-button>
            <el-button v-if="row.status !== 'controlled' && hasPerm('safety:risk:identify:edit')" size="mini" type="text" style="color:#67C23A" @click="openStatus(row)">状态</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination style="margin-top:12px;text-align:right" background layout="total, sizes, prev, pager, next"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10, 20, 50]" @current-change="loadList" @size-change="loadList" />
    </el-card>

    <risk-form-dialog :visible.sync="formVisible" :row="currentRow" :type-options="typeOptions"
      :level-options="levelOptions" :dept-options="deptOptions" @saved="onSaved" />
    <risk-detail-dialog :visible.sync="detailVisible" :row="detailRow" />
    <risk-status-dialog :visible.sync="statusVisible" :row="statusRow" @saved="onSaved" />
  </div>
</template>

<script>
import { getRiskList, getRiskStatistics, deleteRisk, exportRisk } from '@/api/safetyRisk'
import { getDictByCode } from '@/api/dictionary'
import { getDeptTree } from '@/api/organization'
import RiskFormDialog from './components/RiskFormDialog.vue'
import RiskDetailDialog from './components/RiskDetailDialog.vue'
import RiskStatusDialog from './components/RiskStatusDialog.vue'

export default {
  name: 'RiskIdentify',
  components: { RiskFormDialog, RiskDetailDialog, RiskStatusDialog },
  data() {
    return {
      loading: false, exporting: false, list: [], total: 0, page: 1, limit: 10,
      filters: { keyword: '', risk_type: '', risk_level: '', status: '', area: '', department_id: null },
      riskStatusOptions: [],
      dateRange: null,
      typeOptions: [], levelOptions: [], deptOptions: [],
      statCards: [
        { label: '风险总数', value: 0, icon: 'el-icon-document', color: '#409EFF', bg: 'rgba(64,158,255,.12)' },
        { label: '待评估数', value: 0, icon: 'el-icon-time', color: '#E6A23C', bg: 'rgba(230,162,60,.12)' },
        { label: '已评估数', value: 0, icon: 'el-icon-check', color: '#67C23A', bg: 'rgba(103,194,58,.12)' },
        { label: '已管控数', value: 0, icon: 'el-icon-circle-check', color: '#409EFF', bg: 'rgba(64,158,255,.12)' },
        { label: '重大风险数', value: 0, icon: 'el-icon-warning', color: '#F56C6C', bg: 'rgba(245,108,108,.12)' },
        { label: '较大风险数', value: 0, icon: 'el-icon-warning-outline', color: '#E6A23C', bg: 'rgba(230,162,60,.12)' },
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
    this.loadDicts()
  },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    // 风险状态从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../api/dictionary')
      try { const r = await getDictByCode('safety_risk_status'); this.riskStatusOptions = r.data || [] } catch (e) { this.riskStatusOptions = [] }
    },
    async loadOptions() {
      try {
        const [t, l, d] = await Promise.all([getDictByCode('safety_risk_type'), getDictByCode('safety_risk_level'), getDeptTree()])
        this.typeOptions = (t.data || []).map(x => ({ label: x.label, value: x.value }))
        this.levelOptions = (l.data || []).map(x => ({ label: x.label, value: x.value }))
        this.deptOptions = d.data || []
      } catch (e) {}
    },
    buildParams(extra = {}) {
      const p = {
        page: this.page, limit: this.limit,
        keyword: this.filters.keyword || '',
        risk_type: this.filters.risk_type || '',
        risk_level: this.filters.risk_level || '',
        status: this.filters.status || '',
        area: this.filters.area || '',
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
        const r = await getRiskList(this.buildParams())
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    async loadStatistics() {
      try {
        const r = await getRiskStatistics()
        if (r.code === 0 && r.data) {
          this.statCards[0].value = r.data.total || 0
          this.statCards[1].value = r.data.pending || 0
          this.statCards[2].value = r.data.assessed || 0
          this.statCards[3].value = r.data.controlled || 0
          this.statCards[4].value = r.data.critical || 0
          this.statCards[5].value = r.data.major || 0
        }
      } catch (e) {}
    },
    loadAll() { this.loadList(); this.loadStatistics() },
    onSearch() { this.page = 1; this.loadAll() },
    resetFilters() {
      this.filters = { keyword: '', risk_type: '', risk_level: '', status: '', area: '', department_id: null }
      this.dateRange = null; this.page = 1; this.loadAll()
    },
    typeTag(t) { return { physical: '', chemical: 'warning', biological: 'success', ergonomic: 'info', management: 'warning', other: 'info' }[t] || 'info' },
    levelTag(l) { return { low: 'success', general: '', major: 'warning', critical: 'danger' }[l] || 'info' },
    statusTag(s) { return { pending: 'warning', assessed: 'success', controlled: '' }[s] || 'info' },
    onSaved() { this.loadAll() },
    openAdd() { this.currentRow = null; this.formVisible = true },
    openEdit(row) { this.currentRow = row; this.formVisible = true },
    openDetail(row) { this.detailRow = row; this.detailVisible = true },
    openStatus(row) { this.statusRow = row; this.statusVisible = true },
    doDelete(row) {
      this.$confirm(`确认删除风险「${row.risk_name}」？`, '删除确认', { type: 'warning' }).then(async () => {
        try { const r = await deleteRisk(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadAll() } } catch (e) {}
      }).catch(() => {})
    },
    async doExport() {
      this.exporting = true
      try {
        const r = await exportRisk(this.buildParams())
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
