<template>
  <div class="record-page">
    <!-- 统计卡片（今日四卡片） -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="6" v-for="card in statCards" :key="card.key">
        <div class="stat-card" :style="{ borderTopColor: card.color }">
          <div class="stat-icon" :style="{ background: card.color + '1a', color: card.color }"><i :class="card.icon"></i></div>
          <div class="stat-body">
            <div class="stat-value" :style="{ color: card.color }">{{ card.value }}</div>
            <div class="stat-label">{{ card.label }}</div>
          </div>
        </div>
      </el-col>
    </el-row>

    <!-- 筛选区域 -->
    <el-card shadow="never" class="filter-card">
      <el-form :inline="true" size="small" @submit.native.prevent>
        <el-form-item>
          <el-date-picker v-model="filters.dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至"
            start-placeholder="开始日期" end-placeholder="结束日期" style="width:230px" @change="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.department_id" clearable filterable placeholder="全部部门" style="width:140px" @change="onSearch">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入员工姓名/工号" clearable style="width:180px" @keyup.enter.native="onSearch" @clear="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.check_result" clearable placeholder="全部状态" style="width:110px" @change="onSearch">
            <el-option label="正常" value="normal" /><el-option label="迟到" value="late" />
            <el-option label="早退" value="early" /><el-option label="缺卡" value="miss" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.check_method" clearable placeholder="全部方式" style="width:110px" @change="onSearch">
            <el-option label="人脸" :value="1" /><el-option label="指纹" :value="2" /><el-option label="密码" :value="3" />
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
        <span>共 <b>{{ total }}</b> 条记录<span v-if="stats.last_sync" style="margin-left:12px;color:#909399;">最近同步：{{ stats.last_sync }}</span></span>
        <div>
          <el-button v-if="hasPerm('hr:attendance:record:export')" size="small" type="primary" icon="el-icon-download" :loading="exporting" @click="doExport">导出</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadAll">刷新</el-button>
        </div>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe>
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column prop="check_date" label="日期" width="110" align="center" />
        <el-table-column prop="employee_name" label="姓名" width="80" />
        <el-table-column prop="department_name" label="部门" width="120" show-overflow-tooltip />
        <!-- 打卡记录（多段） -->
        <el-table-column label="打卡记录" min-width="360">
          <template slot-scope="{ row }">
            <div class="seg-wrap" v-if="row.segments && row.segments.length">
              <div class="seg-item" v-for="(seg, i) in row.segments" :key="i">
                <span class="seg-type">{{ seg.check_type_text || '打卡' }}</span>
                <span class="seg-time">{{ timeHm(seg.check_time) }}</span>
                <el-tag size="mini" :type="resultTagType(seg.check_result)">{{ seg.check_result_text }}</el-tag>
              </div>
            </div>
            <span v-else style="color:#c0c4cc;">-</span>
          </template>
        </el-table-column>
        <el-table-column label="打卡方式" width="90" align="center">
          <template slot-scope="{ row }">
            <span v-if="row.segments && row.segments.length">{{ row.segments[0].check_type_text }}</span>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column prop="point_name" label="打卡点" width="120" show-overflow-tooltip />
        <el-table-column label="操作" width="160" align="center">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('hr:attendance:record:query')" type="text" size="mini" @click="openDetail(row)">详情</el-button>
            <el-button v-if="hasPerm('hr:attendance:record:fix') && row.has_abnormal" type="text" size="mini" style="color:#E6A23C" @click="openFix(row)">修正</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination class="pager" background layout="total, sizes, prev, pager, next" :total="total"
        :current-page="page" :page-size="limit" :page-sizes="[10, 20, 50]"
        @size-change="s => { limit = s; page = 1; loadAll() }"
        @current-change="p => { page = p; loadAll() }" />
    </el-card>

    <!-- 详情弹窗 -->
    <record-detail-dialog v-if="detailVisible" :visible.sync="detailVisible" :record-id="detailId" />

    <!-- 补录弹窗 -->
    <record-add-dialog v-if="addVisible" :visible.sync="addVisible" @saved="loadAll" />

    <!-- 修正记录弹窗 -->
    <el-dialog title="修正打卡记录" :visible.sync="fixVisible" width="450px" :close-on-click-modal="false">
      <el-form :model="fixForm" label-width="90px" size="small">
        <el-form-item label="员工/日期">
          <span>{{ fixTarget ? fixTarget.employee_name : '' }} · {{ fixTarget ? fixTarget.check_date : '' }}</span>
        </el-form-item>
        <el-form-item label="打卡段" required>
          <el-select v-model="fixForm.record_id" placeholder="选择要修正的打卡段" style="width:100%">
            <el-option v-for="(seg, i) in (fixTarget ? fixTarget.segments : [])" :key="i"
              :label="`${seg.check_type_text || '打卡'} ${timeHm(seg.check_time)}（${seg.check_result_text}）`" :value="seg.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="修正状态" required>
          <el-select v-model="fixForm.check_result" placeholder="选择修正后状态" style="width:100%">
            <el-option label="正常" value="normal" /><el-option label="迟到" value="late" />
            <el-option label="早退" value="early" /><el-option label="缺卡" value="miss" />
          </el-select>
        </el-form-item>
        <el-form-item label="修正原因" required>
          <el-input v-model="fixForm.reason" placeholder="请填写修正原因（必填）" maxlength="100" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="fixForm.remark" placeholder="选填" maxlength="200" />
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="fixVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="fixing" @click="doFix">确认修正</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getRecordList, getRecordStatistics, deleteRecord, exportRecord, fixRecord } from '@/api/attendanceRecord'
import { getDeptTree } from '@/api/organization'
import RecordDetailDialog from './components/RecordDetailDialog.vue'
import RecordAddDialog from './components/RecordAddDialog.vue'

function flattenDept (nodes) {
  let r = []
  for (const n of nodes || []) { r.push(n); if (n.children) r = r.concat(flattenDept(n.children)) }
  return r
}

export default {
  name: 'AttendanceRecord',
  components: { RecordDetailDialog, RecordAddDialog },
  data () {
    return {
      list: [], total: 0, page: 1, limit: 10, loading: false, exporting: false,
      stats: { total: 0, normal: 0, abnormal: 0, today: 0, last_sync: '', today_stats: { should_checkin: 0, checked_in: 0, absent: 0, late: 0 } },
      filters: { keyword: '', department_id: '', check_result: '', check_method: '', source: '', dateRange: null },
      deptOptions: [],
      detailVisible: false, detailId: 0, addVisible: false,
      fixVisible: false, fixTarget: null, fixing: false,
      fixForm: { record_id: '', check_result: '', reason: '', remark: '' }
    }
  },
  computed: {
    statCards () {
      const t = this.stats.today_stats || {}
      return [
        { key: 'should', label: '今日应打卡', icon: 'el-icon-user', color: '#409EFF', value: t.should_checkin },
        { key: 'checked', label: '今日已打卡', icon: 'el-icon-check', color: '#67C23A', value: t.checked_in },
        { key: 'absent', label: '今日缺卡', icon: 'el-icon-warning', color: '#F56C6C', value: t.absent },
        { key: 'late', label: '今日迟到', icon: 'el-icon-time', color: '#E6A23C', value: t.late }
      ]
    }
  },
  created () {
    this.loadDepts()
    this.loadAll()
  },
  methods: {
    hasPerm (code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    resultType (r) { return { normal: 'success', late: 'warning', early: 'danger', miss: 'info' }[r] || 'info' },
    resultTagType (r) { return this.resultType(r) },
    timeHm (t) { return t ? String(t).slice(11, 16) : '--:--' },
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
      const r = await getRecordStatistics()
      if (r.code === 0) this.stats = r.data || { total: 0, normal: 0, abnormal: 0, today: 0, last_sync: '', today_stats: { should_checkin: 0, checked_in: 0, absent: 0, late: 0 } }
    },
    async loadList () {
      const params = { page: this.page, limit: this.limit }
      if (this.filters.keyword) params.keyword = this.filters.keyword
      if (this.filters.department_id) params.department_id = this.filters.department_id
      if (this.filters.check_result) params.check_result = this.filters.check_result
      if (this.filters.check_method) params.check_method = this.filters.check_method
      if (this.filters.dateRange && this.filters.dateRange.length === 2) {
        params.start_date = this.filters.dateRange[0]
        params.end_date = this.filters.dateRange[1]
      }
      const r = await getRecordList(params)
      if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
    },
    onSearch () { this.page = 1; this.loadAll() },
    resetFilter () { this.filters = { keyword: '', department_id: '', check_result: '', check_method: '', source: '', dateRange: null }; this.page = 1; this.loadAll() },
    openDetail (row) {
      // 详情取第一条段记录 id
      const rid = row.segments && row.segments.length ? row.segments[0].id : 0
      this.detailId = rid; this.detailVisible = true
    },
    openFix (row) { this.fixTarget = row; this.fixForm = { record_id: '', check_result: '', reason: '', remark: '' }; this.fixVisible = true },
    async doFix () {
      if (!this.fixForm.record_id) { this.$message.warning('请选择打卡段'); return }
      if (!this.fixForm.check_result) { this.$message.warning('请选择修正状态'); return }
      if (!this.fixForm.reason) { this.$message.warning('请填写修正原因'); return }
      this.fixing = true
      try {
        const r = await fixRecord(this.fixForm)
        if (r.code === 0) { this.$message.success(r.msg || '修正成功'); this.fixVisible = false; this.loadAll() }
        else this.$message.error(r.msg || '修正失败')
      } catch (e) { this.$message.error('请求失败') } finally { this.fixing = false }
    },
    removeOne (row) {
      this.$confirm(`确定删除员工「${row.employee_name}」${row.check_date} 的打卡记录？`, '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteRecord(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.loadAll() }
        } catch (e) {}
      }).catch(() => {})
    },
    async doExport () {
      this.exporting = true
      try {
        const params = {}
        if (this.filters.keyword) params.keyword = this.filters.keyword
        if (this.filters.department_id) params.department_id = this.filters.department_id
        if (this.filters.check_result) params.check_result = this.filters.check_result
        if (this.filters.check_method) params.check_method = this.filters.check_method
        if (this.filters.dateRange && this.filters.dateRange.length === 2) { params.start_date = this.filters.dateRange[0]; params.end_date = this.filters.dateRange[1] }
        const r = await exportRecord(params)
        if (r.code === 0 && r.data && r.data.url) window.open(r.data.url, '_blank')
        else this.$message.error('导出失败')
      } catch (e) {} finally { this.exporting = false }
    }
  }
}
</script>

<style scoped>
.record-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.stat-row { margin-bottom: 16px; }
.stat-card { background: #fff; border-radius: 8px; border-top: 3px solid #409EFF; padding: 14px; display: flex; align-items: center; box-shadow: 0 1px 4px rgba(0,0,0,.04); }
.stat-icon { width: 44px; height: 44px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 22px; margin-right: 12px; }
.stat-value { font-size: 24px; font-weight: 700; }
.stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.filter-card { margin-bottom: 16px; }
.list-card .toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; font-size: 13px; color: #606266; }
.pager { margin-top: 14px; text-align: right; }
.seg-wrap { display: flex; flex-wrap: wrap; gap: 6px; }
.seg-item { display: flex; align-items: center; gap: 4px; background: #f5f7fa; border-radius: 4px; padding: 2px 6px; font-size: 12px; }
.seg-type { color: #909399; }
.seg-time { font-weight: 600; color: #303133; }
</style>
