<template>
  <div class="record-page">
    <!-- 统计卡片 -->
    <div class="stat-row">
      <div v-for="card in statCards" :key="card.key" class="stat-card-flex" @click="quickFilter(card)">
        <div class="stat-icon" :style="{ background: card.color + '1a', color: card.color }"><i :class="card.icon"></i></div>
        <div class="stat-info">
          <div class="stat-val" :style="{ color: card.color }">{{ card.value }}</div>
          <div class="stat-label">{{ card.label }}</div>
        </div>
      </div>
    </div>

    <!-- 筛选区域 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <el-form :inline="true" size="small">
        <el-form-item><el-input v-model="filters.keyword" placeholder="请输入记录编号或计划名称" clearable style="width:200px" @keyup.enter.native="onSearch" /></el-form-item>
        <el-form-item>
          <el-select v-model="filters.training_type_id" clearable filterable placeholder="全部类型" style="width:130px" @change="onSearch">
            <el-option v-for="t in typeOptions" :key="t.id" :label="t.type_name" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.training_mode" clearable placeholder="全部方式" style="width:110px" @change="onSearch">
            <el-option v-for="m in modeOptions" :key="m.value" :label="m.label" :value="m.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.responsible_id" clearable filterable placeholder="全部负责人" style="width:120px" @change="onSearch">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" placeholder="培训日期范围" style="width:240px" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.evaluation_status" clearable placeholder="评估状态" style="width:120px" @change="onSearch">
            <el-option label="待评估" value="pending" /><el-option label="已评估" value="evaluated" />
          </el-select>
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
          <el-button v-if="hasPerm('safety:training:record:export')" size="small" icon="el-icon-download" @click="doExport">导出</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="refreshAll">刷新</el-button>
        </div>
      </div>

      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" />
        <el-table-column label="记录编号" width="180" show-overflow-tooltip>
          <template slot-scope="{ row }"><el-link type="primary" @click="openDetail(row)">{{ row.record_code }}</el-link></template>
        </el-table-column>
        <el-table-column prop="plan_name" label="计划名称" min-width="140" show-overflow-tooltip />
        <el-table-column prop="training_type_name" label="培训类型" width="100" align="center" />
        <el-table-column label="培训方式" width="90" align="center">
          <template slot-scope="{ row }">{{ row.mode_text }}</template>
        </el-table-column>
        <el-table-column prop="plan_count" label="计划人数" width="80" align="center" />
        <el-table-column prop="actual_count" label="实到人数" width="80" align="center" />
        <el-table-column label="培训时长" width="90" align="center">
          <template slot-scope="{ row }">{{ row.duration_hours }}{{ row.duration_hours ? 'h' : '-' }}</template>
        </el-table-column>
        <el-table-column prop="training_date" label="培训日期" width="120" align="center">
          <template slot-scope="{ row }">{{ row.training_date || '-' }}</template>
        </el-table-column>
        <el-table-column prop="responsible_name" label="负责人" width="80" align="center" />
        <el-table-column label="评估得分" width="90" align="center">
          <template slot-scope="{ row }">
            <span v-if="row.evaluation_score != null" :style="{ color: row.evaluation_score >= 90 ? '#67C23A' : row.evaluation_score >= 75 ? '#409EFF' : row.evaluation_score >= 60 ? '#E6A23C' : '#F56C6C' }">{{ row.evaluation_score }}</span>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" align="center" fixed="right">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('safety:training:record:query')" size="mini" type="text" @click="openDetail(row)">查看详情</el-button>
            <el-button v-if="row.status === 'pending' && hasPerm('safety:training:record:edit')" size="mini" type="text" style="color:#E6A23C" @click="openCheckin(row)">签到管理</el-button>
            <el-button v-if="row.status === 'pending' && hasPerm('safety:training:record:evaluate')" size="mini" type="text" style="color:#67C23A" @click="openEvaluate(row)">评估</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-empty v-if="!loading && !list.length" description="暂无培训记录" />
      <el-pagination v-if="total > 0" style="margin-top:12px;text-align:right" background layout="total, sizes, prev, pager, next"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10, 20, 50]" @current-change="loadList" @size-change="loadList" />
    </el-card>

    <!-- 弹窗 -->
    <record-detail-dialog :visible.sync="detailVisible" :record-id="detailId" />
    <checkin-dialog :visible.sync="checkinVisible" :record-id="currentId" @saved="refreshAll" />
    <evaluate-dialog :visible.sync="evaluateVisible" :record-id="currentId" @saved="refreshAll" />
  </div>
</template>

<script>
import { getRecordList, getRecordStatistics, exportRecords, getTypeOptions } from '@/api/safetyTrainingRecord'
import { getUserList } from '@/api/user'
import RecordDetailDialog from './components/RecordDetailDialog.vue'
import CheckinDialog from './components/CheckinDialog.vue'
import EvaluateDialog from './components/EvaluateDialog.vue'

export default {
  name: 'SafetyTrainingRecord',
  components: { RecordDetailDialog, CheckinDialog, EvaluateDialog },
  data() {
    return {
      loading: false, list: [], total: 0, page: 1, limit: 10,
      filters: { keyword: '', training_type_id: null, training_mode: '', responsible_id: null, evaluation_status: '' },
      dateRange: null,
      stats: { total: 0, month_count: 0, month_attendee: 0, avg_score: 0 },
      typeOptions: [], userOptions: [],
      modeOptions: [
        { value: 'online', label: '线上' }, { value: 'offline', label: '线下' }, { value: 'mixed', label: '混合' }
      ],
      detailVisible: false, detailId: 0,
      checkinVisible: false, evaluateVisible: false, currentId: 0
    }
  },
  computed: {
    statCards() {
      return [
        { key: 'total', label: '总记录数', value: this.stats.total, icon: 'el-icon-document', color: '#409EFF' },
        { key: 'month_count', label: '本月培训次数', value: this.stats.month_count, icon: 'el-icon-date', color: '#67C23A' },
        { key: 'month_attendee', label: '本月参训人次', value: this.stats.month_attendee, icon: 'el-icon-user', color: '#E6A23C' },
        { key: 'avg_score', label: '平均评估得分', value: this.stats.avg_score, icon: 'el-icon-star-on', color: '#9B59B6' }
      ]
    }
  },
  created() {
    // 权限为空时刷新（避免新加权限未及时拉取导致按钮不显示）
    if (this.$store.state.user && this.$store.state.user.permissions && !this.$store.state.user.permissions.length) {
      this.$store.dispatch('user/loadPermissions')
    }
    this.loadList(); this.loadStats(); this.loadTypes(); this.loadUsers()
  },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    async loadList() {
      this.loading = true
      try {
        const r = await getRecordList({
          page: this.page, limit: this.limit,
          keyword: this.filters.keyword || '',
          training_type_id: this.filters.training_type_id || '',
          training_mode: this.filters.training_mode || '',
          responsible_id: this.filters.responsible_id || '',
          evaluation_status: this.filters.evaluation_status || '',
          start_date: this.dateRange ? this.dateRange[0] : '',
          end_date: this.dateRange ? this.dateRange[1] : ''
        })
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
      this.filters = { keyword: '', training_type_id: null, training_mode: '', responsible_id: null, evaluation_status: '' }
      this.dateRange = null
      this.page = 1
      this.loadList()
    },
    quickFilter(card) {
      if (card.key === 'total') this.resetFilters()
      else if (card.key === 'month_count' || card.key === 'month_attendee') {
        const now = new Date()
        const fmt = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
        this.dateRange = [fmt(new Date(now.getFullYear(), now.getMonth(), 1)), fmt(now)]
        this.page = 1
        this.loadList()
      } else if (card.key === 'avg_score') {
        this.$message.info('平均评估得分 ' + this.stats.avg_score)
      }
    },
    refreshAll() { this.loadList(); this.loadStats() },
    openDetail(row) { this.detailId = row.id; this.detailVisible = true },
    openCheckin(row) { this.currentId = row.id; this.checkinVisible = true },
    openEvaluate(row) { this.currentId = row.id; this.evaluateVisible = true },
    doExport() {
      this.$confirm(`当前筛选条件下共 ${this.total} 条记录，确定导出吗？`, '导出确认', { type: 'info' }).then(async () => {
        try {
          const r = await exportRecords({
            keyword: this.filters.keyword || '',
            training_type_id: this.filters.training_type_id || '',
            training_mode: this.filters.training_mode || '',
            responsible_id: this.filters.responsible_id || '',
            start_date: this.dateRange ? this.dateRange[0] : '',
            end_date: this.dateRange ? this.dateRange[1] : ''
          })
          if (r.code === 0 && r.data && r.data.url) { window.open(r.data.url, '_blank'); this.$message.success('导出成功') }
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.stat-row { display: flex; gap: 16px; margin-bottom: 16px; }
.stat-card-flex { flex: 1; background: #fff; border-radius: 8px; padding: 16px; box-shadow: 0 2px 8px rgba(0,0,0,.04); cursor: pointer; transition: all .2s; min-width: 0; }
.stat-card-flex:hover { transform: translateY(-3px); box-shadow: 0 6px 16px rgba(0,0,0,.1); }
.stat-card-flex .stat-icon { width: 40px; height: 40px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 20px; float: left; margin-right: 10px; }
.stat-card-flex .stat-info { overflow: hidden; }
.stat-card-flex .stat-val { font-size: 20px; font-weight: 700; line-height: 1.2; }
.stat-card-flex .stat-label { font-size: 12px; color: #909399; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
