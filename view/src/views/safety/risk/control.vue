<template>
  <div class="risk-control-page">
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
          <el-input v-model="filters.keyword" placeholder="请输入措施编号或风险名称" clearable style="width:200px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.measure_type" clearable placeholder="全部类型" style="width:120px" @change="onSearch">
            <el-option v-for="t in typeOptions" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.implement_status" clearable placeholder="实施状态" style="width:110px" @change="onSearch">
            <el-option v-for="opt in implementOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.verify_status" clearable placeholder="验证状态" style="width:110px" @change="onSearch">
            <el-option v-for="opt in verifyOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.responsible_person_id" clearable placeholder="责任人" style="width:130px" @change="onSearch">
            <el-option v-for="u in personOptions" :key="u.user_id || u.id" :label="u.name || '员工'" :value="u.user_id || u.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="~" start-placeholder="完成期限起" end-placeholder="完成期限止" style="width:240px" @change="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilters">重置</el-button>
        </el-form-item>
        <el-form-item style="float:right">
          <span style="margin-right:12px;font-size:13px;color:#909399;">共 {{ total }} 条措施</span>
          <el-button v-if="hasPerm('safety:risk:control:add')" type="primary" icon="el-icon-plus" @click="openAdd">新增措施</el-button>
          <el-button v-if="hasPerm('safety:risk:control:export')" icon="el-icon-upload2" :loading="exporting" @click="doExport">导出</el-button>
          <el-button icon="el-icon-refresh" @click="loadAll">刷新</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 表格 -->
    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column prop="measure_code" label="措施编号" width="170" />
        <el-table-column prop="risk_name" label="风险名称" min-width="130" show-overflow-tooltip />
        <el-table-column label="措施类型" width="95" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="typeTag(row.measure_type)">{{ row.measure_type_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="measure_content" label="措施内容摘要" min-width="180" show-overflow-tooltip />
        <el-table-column prop="responsible_person_name" label="责任人" width="80" align="center" />
        <el-table-column prop="deadline" label="完成期限" width="105" align="center" />
        <el-table-column label="实施状态" width="90" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="implTag(row.implement_status)">{{ row.implement_status_text }}</el-tag></template>
        </el-table-column>
        <el-table-column label="验证状态" width="90" align="center">
          <template slot-scope="{ row }"><el-tag size="mini" :type="verifyTag(row.verify_status)">{{ row.verify_status_text }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="250" align="center" fixed="right">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('safety:risk:control:query')" size="mini" type="text" @click="openDetail(row)">详情</el-button>
            <template v-if="row.implement_status === 'pending'">
              <el-button v-if="hasPerm('safety:risk:control:edit')" size="mini" type="text" @click="openEdit(row)">编辑</el-button>
              <el-button v-if="hasPerm('safety:risk:control:edit')" size="mini" type="text" style="color:#67C23A" @click="doStart(row)">开始实施</el-button>
              <el-button v-if="hasPerm('safety:risk:control:edit')" size="mini" type="text" style="color:#F56C6C" @click="doInvalidate(row)">失效</el-button>
              <el-button v-if="hasPerm('safety:risk:control:delete')" size="mini" type="text" style="color:#F56C6C" @click="doDelete(row)">删除</el-button>
            </template>
            <template v-else-if="row.implement_status === 'in_progress'">
              <el-button v-if="hasPerm('safety:risk:control:edit')" size="mini" type="text" @click="openEdit(row)">编辑</el-button>
              <el-button v-if="hasPerm('safety:risk:control:edit')" size="mini" type="text" style="color:#67C23A" @click="doComplete(row)">完成实施</el-button>
              <el-button v-if="hasPerm('safety:risk:control:edit')" size="mini" type="text" style="color:#F56C6C" @click="doInvalidate(row)">失效</el-button>
            </template>
            <el-button v-if="row.implement_status === 'completed' && row.verify_status === 'pending' && hasPerm('safety:risk:control:verify')" size="mini" type="text" style="color:#409EFF" @click="openVerify(row)">验证</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination style="margin-top:12px;text-align:right" background layout="total, sizes, prev, pager, next"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10, 20, 50]" @current-change="loadList" @size-change="loadList" />
    </el-card>

    <control-form-dialog :visible.sync="formVisible" :row="currentRow" :type-options="typeOptions"
      :risk-options="riskOptions" :person-options="personOptions" @saved="onSaved" />
    <control-detail-dialog :visible.sync="detailVisible" :row="detailRow" />
    <control-verify-dialog :visible.sync="verifyVisible" :row="verifyRow" @saved="onSaved" />
  </div>
</template>

<script>
import { getControlList, getControlStatistics, deleteControl, startControl, completeControl, invalidateControl, exportControl, getAvailableRisks, getResponsibleCandidates } from '@/api/safetyRisk'
import { getDictByCode } from '@/api/dictionary'
import ControlFormDialog from './components/ControlFormDialog.vue'
import ControlDetailDialog from './components/ControlDetailDialog.vue'
import ControlVerifyDialog from './components/ControlVerifyDialog.vue'

export default {
  name: 'RiskControl',
  components: { ControlFormDialog, ControlDetailDialog, ControlVerifyDialog },
  data() {
    return {
      loading: false, exporting: false, list: [], total: 0, page: 1, limit: 10,
      filters: { keyword: '', measure_type: '', implement_status: '', verify_status: '', responsible_person_id: null },
      implementOptions: [], verifyOptions: [],
      dateRange: null,
      typeOptions: [], riskOptions: [], personOptions: [],
      statCards: [
        { label: '措施总数', value: 0, icon: 'el-icon-document', color: '#409EFF', bg: 'rgba(64,158,255,.12)' },
        { label: '待实施数', value: 0, icon: 'el-icon-time', color: '#909399', bg: 'rgba(144,147,153,.12)' },
        { label: '实施中数', value: 0, icon: 'el-icon-loading', color: '#409EFF', bg: 'rgba(64,158,255,.12)' },
        { label: '已完成数', value: 0, icon: 'el-icon-check', color: '#67C23A', bg: 'rgba(103,194,58,.12)' },
        { label: '已失效数', value: 0, icon: 'el-icon-close', color: '#F56C6C', bg: 'rgba(245,108,108,.12)' },
        { label: '措施有效率(%)', value: 0, icon: 'el-icon-percent', color: '#67C23A', bg: 'rgba(103,194,58,.12)' },
      ],
      formVisible: false, detailVisible: false, verifyVisible: false,
      currentRow: null, detailRow: null, verifyRow: null,
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
    // 实施/验证状态从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../api/dictionary')
      try { const r = await getDictByCode('control_implement_status'); this.implementOptions = r.data || [] } catch (e) { this.implementOptions = [] }
      try { const r = await getDictByCode('control_verify_status'); this.verifyOptions = r.data || [] } catch (e) { this.verifyOptions = [] }
    },
    async loadOptions() {
      try {
        const [t, r, u] = await Promise.all([
          getDictByCode('control_measure_type'), getAvailableRisks(), getResponsibleCandidates(''),
        ])
        this.typeOptions = (t.data || []).map(x => ({ label: x.label, value: x.value }))
        this.riskOptions = r.data || []
        this.personOptions = (u.data && u.data.list) || []
      } catch (e) {}
    },
    buildParams(extra = {}) {
      const p = {
        page: this.page, limit: this.limit,
        keyword: this.filters.keyword || '',
        measure_type: this.filters.measure_type || '',
        implement_status: this.filters.implement_status || '',
        verify_status: this.filters.verify_status || '',
        responsible_person_id: this.filters.responsible_person_id || '',
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
        const r = await getControlList(this.buildParams())
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    async loadStatistics() {
      try {
        const r = await getControlStatistics()
        if (r.code === 0 && r.data) {
          this.statCards[0].value = r.data.total || 0
          this.statCards[1].value = r.data.pending || 0
          this.statCards[2].value = r.data.in_progress || 0
          this.statCards[3].value = r.data.completed || 0
          this.statCards[4].value = r.data.invalid || 0
          this.statCards[5].value = r.data.effective_rate || 0
        }
      } catch (e) {}
    },
    loadAll() { this.loadList(); this.loadStatistics() },
    onSearch() { this.page = 1; this.loadAll() },
    resetFilters() {
      this.filters = { keyword: '', measure_type: '', implement_status: '', verify_status: '', responsible_person_id: null }
      this.dateRange = null; this.page = 1; this.loadAll()
    },
    typeTag(t) { return { engineering: '', management_control: 'success', personal_protection: 'warning', emergency: 'danger' }[t] || 'info' },
    implTag(s) { return { pending: 'info', in_progress: '', completed: 'success', invalid: 'danger' }[s] || 'info' },
    verifyTag(s) { return { pending: 'warning', effective: 'success', ineffective: 'danger' }[s] || 'info' },
    onSaved() { this.loadAll() },
    openAdd() { this.currentRow = null; this.formVisible = true },
    openEdit(row) { this.currentRow = row; this.formVisible = true },
    openDetail(row) { this.detailRow = row; this.detailVisible = true },
    openVerify(row) { this.verifyRow = row; this.verifyVisible = true },
    doStart(row) {
      this.$confirm(`确认开始实施措施「${row.measure_code}」？`, '开始实施', { type: 'warning' }).then(async () => {
        try { const r = await startControl(row.id); if (r.code === 0) { this.$message.success('已开始实施'); this.loadAll() } } catch (e) {}
      }).catch(() => {})
    },
    doComplete(row) {
      this.$confirm(`确认完成实施措施「${row.measure_code}」？完成后进入待验证。`, '完成实施', { type: 'warning' }).then(async () => {
        try { const r = await completeControl(row.id); if (r.code === 0) { this.$message.success('已完成实施'); this.loadAll() } } catch (e) {}
      }).catch(() => {})
    },
    doInvalidate(row) {
      this.$prompt('请填写失效原因', '措施失效', { inputType: 'textarea', inputValidator: v => !!v && v.trim().length > 0, inputErrorMessage: '请填写失效原因' }).then(async ({ value }) => {
        try { const r = await invalidateControl(row.id, value); if (r.code === 0) { this.$message.success('措施已失效'); this.loadAll() } } catch (e) {}
      }).catch(() => {})
    },
    doDelete(row) {
      this.$confirm(`确认删除措施「${row.measure_code}」？`, '删除确认', { type: 'warning' }).then(async () => {
        try { const r = await deleteControl(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadAll() } } catch (e) {}
      }).catch(() => {})
    },
    async doExport() {
      this.exporting = true
      try {
        const r = await exportControl(this.buildParams())
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
