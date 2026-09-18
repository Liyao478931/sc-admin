<template>
  <div class="record-page">
    <!-- 统计卡片 -->
    <el-row :gutter="16" style="margin-bottom:16px;">
      <el-col :span="6" v-for="card in statCards" :key="card.key">
        <el-card shadow="hover" class="stat-card" @click.native="quickFilter(card)">
          <div class="stat-icon" :style="{ background: card.color + '1a', color: card.color }"><i :class="card.icon"></i></div>
          <div class="stat-info">
            <div class="stat-val" :style="{ color: card.color }">{{ card.value }}</div>
            <div class="stat-label">{{ card.label }}</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 筛选区域 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <el-form :inline="true" size="small">
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入记录编号、计划名称或检查区域" clearable style="width:220px" @keyup.enter.native="onSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.inspection_type_id" clearable filterable placeholder="全部类型" style="width:130px" @change="onSearch">
            <el-option v-for="t in typeOptions" :key="t.id" :label="t.type_name" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.executor_id" clearable filterable placeholder="全部执行人" style="width:130px" @change="onSearch">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" placeholder="执行日期范围" style="width:240px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilters">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 工具栏 + 表格 -->
    <el-card shadow="never">
      <div slot="header" class="card-header">
        <span style="color:#909399">共 <b style="color:#409EFF">{{ total }}</b> 条记录</span>
        <div>
          <el-button v-if="hasPerm('safety:inspection:record:export')" size="small" icon="el-icon-download" @click="doExport">导出</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="refreshAll">刷新</el-button>
        </div>
      </div>

      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" />
        <el-table-column label="记录编号" width="180" show-overflow-tooltip>
          <template slot-scope="{ row }">
            <el-link type="primary" @click="openDetail(row)">{{ row.task_code }}</el-link>
          </template>
        </el-table-column>
        <el-table-column prop="task_code" label="任务编号" width="180" show-overflow-tooltip />
        <el-table-column prop="plan_name" label="计划名称" min-width="140" show-overflow-tooltip />
        <el-table-column label="检查类型" width="100" align="center">
          <template slot-scope="{ row }">{{ row.inspection_type_name || '-' }}</template>
        </el-table-column>
        <el-table-column prop="area" label="检查区域" width="120" show-overflow-tooltip />
        <el-table-column prop="executor_name" label="执行人" width="80" align="center" />
        <el-table-column prop="actual_execute_date" label="执行日期" width="160" align="center" />
        <el-table-column label="项目总数" width="90" align="center">
          <template slot-scope="{ row }">{{ row.stats ? row.stats.total : 0 }}</template>
        </el-table-column>
        <el-table-column label="合格数" width="90" align="center">
          <template slot-scope="{ row }"><span style="color:#67C23A">{{ row.stats ? row.stats.qualified : 0 }}</span></template>
        </el-table-column>
        <el-table-column label="不合格数" width="90" align="center">
          <template slot-scope="{ row }">
            <span :style="{ color: row.stats && row.stats.unqualified ? '#F56C6C' : '' }">{{ row.stats ? row.stats.unqualified : 0 }}</span>
          </template>
        </el-table-column>
        <el-table-column label="不适用数" width="90" align="center">
          <template slot-scope="{ row }"><span style="color:#909399">{{ row.stats ? row.stats.na : 0 }}</span></template>
        </el-table-column>
        <el-table-column label="操作" width="120" align="center" fixed="right">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('safety:inspection:record:query')" size="mini" type="text" @click="openDetail(row)">查看详情</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-empty v-if="!loading && !list.length" description="暂无检查记录" />
      <el-pagination v-if="total > 0" style="margin-top:12px;text-align:right" background layout="total, sizes, prev, pager, next"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10, 20, 50]" @current-change="loadList" @size-change="loadList" />
    </el-card>

    <!-- 详情弹窗 -->
    <record-detail-dialog :visible.sync="detailVisible" :record-id="detailId" />
  </div>
</template>

<script>
import { getRecordList, getRecordStatistics, exportRecords, getTypeOptions } from '@/api/safetyInspectionRecord'
import { getUserList } from '@/api/user'
import RecordDetailDialog from './components/RecordDetailDialog.vue'

export default {
  name: 'SafetyInspectionRecord',
  components: { RecordDetailDialog },
  data() {
    return {
      loading: false,
      list: [],
      total: 0,
      page: 1,
      limit: 10,
      filters: { keyword: '', inspection_type_id: null, executor_id: null, has_issue: 0 },
      dateRange: null,
      stats: { total: 0, month_new: 0, month_tasks: 0, issue_total: 0 },
      typeOptions: [],
      userOptions: [],
      detailVisible: false,
      detailId: 0,
    }
  },
  computed: {
    statCards() {
      return [
        { key: 'total', label: '总记录数', value: this.stats.total, icon: 'el-icon-document', color: '#409EFF' },
        { key: 'month_new', label: '本月新增', value: this.stats.month_new, icon: 'el-icon-date', color: '#67C23A' },
        { key: 'month_tasks', label: '本月检查次数', value: this.stats.month_tasks, icon: 'el-icon-s-order', color: '#E6A23C' },
        { key: 'issue_total', label: '问题总数', value: this.stats.issue_total, icon: 'el-icon-warning', color: '#F56C6C' },
      ]
    },
  },
  created() {
    this.loadList()
    this.loadStats()
    this.loadTypes()
    this.loadUsers()
  },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    async loadList() {
      this.loading = true
      try {
        const params = {
          page: this.page,
          limit: this.limit,
          keyword: this.filters.keyword || '',
          inspection_type_id: this.filters.inspection_type_id || '',
          executor_id: this.filters.executor_id || '',
          has_issue: this.filters.has_issue || 0,
          start_date: this.dateRange ? this.dateRange[0] : '',
          end_date: this.dateRange ? this.dateRange[1] : '',
        }
        const r = await getRecordList(params)
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    async loadStats() {
      try { const r = await getRecordStatistics(); if (r.code === 0) this.stats = r.data || {} } catch (e) {}
    },
    async loadTypes() {
      try { const r = await getTypeOptions(); if (r.code === 0) this.typeOptions = r.data || [] } catch (e) {}
    },
    async loadUsers() {
      try { const r = await getUserList({ limit: 500 }); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) {}
    },
    onSearch() { this.page = 1; this.loadList() },
    resetFilters() {
      this.filters = { keyword: '', inspection_type_id: null, executor_id: null, has_issue: 0 }
      this.dateRange = null
      this.page = 1
      this.loadList()
    },
    quickFilter(card) {
      const today = new Date()
      const fmt = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
      if (card.key === 'total') {
        this.resetFilters()
      } else if (card.key === 'month_new' || card.key === 'month_tasks') {
        const first = new Date(today.getFullYear(), today.getMonth(), 1)
        this.filters = { ...this.filters, has_issue: 0 }
        this.dateRange = [fmt(first), fmt(today)]
        this.page = 1
        this.loadList()
      } else if (card.key === 'issue_total') {
        this.filters.has_issue = this.filters.has_issue === 1 ? 0 : 1
        this.page = 1
        this.loadList()
      }
    },
    refreshAll() { this.loadList(); this.loadStats() },
    openDetail(row) { this.detailId = row.id; this.detailVisible = true },
    doExport() {
      this.$confirm(`当前筛选条件下共 ${this.total} 条记录，确定导出吗？`, '导出确认', { type: 'info' }).then(async () => {
        try {
          const params = {
            keyword: this.filters.keyword || '',
            inspection_type_id: this.filters.inspection_type_id || '',
            executor_id: this.filters.executor_id || '',
            has_issue: this.filters.has_issue || 0,
            start_date: this.dateRange ? this.dateRange[0] : '',
            end_date: this.dateRange ? this.dateRange[1] : '',
          }
          const r = await exportRecords(params)
          if (r.code === 0 && r.data && r.data.url) { window.open(r.data.url, '_blank'); this.$message.success('导出成功') }
        } catch (e) {}
      }).catch(() => {})
    },
  },
}
</script>

<style scoped>
.stat-card { cursor: pointer; transition: all .2s; }
.stat-card:hover { transform: translateY(-3px); box-shadow: 0 6px 16px rgba(0,0,0,.1); }
.stat-card .stat-icon { width: 40px; height: 40px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 20px; float: left; margin-right: 10px; }
.stat-card .stat-info { overflow: hidden; }
.stat-card .stat-val { font-size: 20px; font-weight: 700; line-height: 1.2; }
.stat-card .stat-label { font-size: 12px; color: #909399; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
