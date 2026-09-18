<template>
  <div class="maintenance-record-page">
    <!-- 统计卡片 -->
    <el-row :gutter="16" style="margin-bottom:16px;">
      <el-col :span="6" v-for="card in statCards" :key="card.key">
        <el-card shadow="hover" class="stat-card">
          <div class="stat-icon" :style="{background: card.color + '1a', color: card.color}"><i :class="card.icon"></i></div>
          <div class="stat-info"><div class="stat-val" :style="{color: card.color}">{{ card.value }}</div><div class="stat-label">{{ card.label }}</div></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 筛选区域 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <el-form :inline="true" size="small">
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入设备名称或编码" clearable style="width:200px" @keyup.enter.native="loadList" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.level_id" clearable placeholder="全部等级" style="width:120px" @change="loadList">
            <el-option v-for="l in levelOptions" :key="l.id" :label="l.level_name" :value="l.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.executor_id" clearable filterable placeholder="全部执行人" style="width:130px" @change="loadList">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.accept_status" clearable placeholder="全部验收状态" style="width:130px" @change="loadList">
            <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="执行开始" end-placeholder="执行结束"
            value-format="yyyy-MM-dd" style="width:240px" @change="loadList" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="loadList">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilters">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 工具栏 + 表格 -->
    <el-card shadow="never">
      <div slot="header" class="card-header">
        <span>保养记录列表 · 共 {{ total }} 条记录</span>
        <div style="float:right;">
          <el-button v-if="hasPerm('device:maintenance:record:export')" size="small" icon="el-icon-download" @click="handleExport">导出</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </div>
      </div>

      <el-table :data="list" v-loading="loading" stripe border size="small">
        <el-table-column type="index" label="#" width="60" />
        <el-table-column label="记录编号" width="180">
          <template slot-scope="{row}"><el-link type="primary" @click="openDetail(row)">{{ row.record_code }}</el-link></template>
        </el-table-column>
        <el-table-column prop="device_name" label="设备名称" min-width="140" show-overflow-tooltip />
        <el-table-column label="保养等级" width="90"><template slot-scope="{row}"><el-tag size="mini">{{ row.level_name }}</el-tag></template></el-table-column>
        <el-table-column prop="executor_name" label="执行人" width="80" />
        <el-table-column prop="execute_time" label="执行日期" width="160" />
        <el-table-column prop="total_count" label="项目数" width="90" />
        <el-table-column label="异常项" width="90">
          <template slot-scope="{row}"><span :style="{color: row.abnormal_count > 0 ? '#F56C6C' : '#909399'}">{{ row.abnormal_count }}</span></template>
        </el-table-column>
        <el-table-column label="验收状态" width="100">
          <template slot-scope="{row}">
            <el-tag :type="statusType(row.accept_status)" size="mini">{{ row.accept_status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="180" fixed="right">
          <template slot-scope="{row}">
            <el-button v-if="row.accept_status === 'pending' && hasPerm('device:maintenance:record:accept')" size="mini" type="text" style="color:#67C23A" @click="openAccept(row)">验收</el-button>
            <el-button v-if="row.accept_status === 'pending' && hasPerm('device:maintenance:record:reject')" size="mini" type="text" style="color:#F56C6C" @click="openReject(row)">驳回</el-button>
            <el-button size="mini" type="text" @click="openDetail(row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination background style="margin-top:16px;text-align:right;" :current-page="page" :page-size="limit" :total="total"
        layout="total, sizes, prev, pager, next" :page-sizes="[10,20,50,100]"
        @size-change="s => { limit = s; page = 1; loadList() }" @current-change="p => { page = p; loadList() }" />
    </el-card>

    <!-- 弹窗 -->
    <record-detail-dialog :visible.sync="detailVisible" :record-id="currentId" />
    <record-accept-dialog :visible.sync="acceptVisible" :record-id="currentId" mode="accept" @saved="onSaved" />
    <record-accept-dialog :visible.sync="rejectVisible" :record-id="currentId" mode="reject" @saved="onSaved" />
  </div>
</template>

<script>
import { getRecordList, getRecordStatistics, exportRecords } from '@/api/maintenanceRecord'
import { getLevelOptions } from '@/api/maintenance'
import { getUserList } from '@/api/user'
import RecordDetailDialog from './components/RecordDetailDialog.vue'
import RecordAcceptDialog from './components/RecordAcceptDialog.vue'

export default {
  name: 'MaintenanceRecord',
  components: { RecordDetailDialog, RecordAcceptDialog },
  data() {
    return {
      list: [], loading: false, total: 0, page: 1, limit: 20,
      detailVisible: false, acceptVisible: false, rejectVisible: false, currentId: 0,
      levelOptions: [], userOptions: [], dateRange: [],
      filters: { keyword: '', level_id: null, executor_id: null, accept_status: '' },
      statusOptions: [],
      statCards: [
        { key: 'total', label: '总记录数', icon: 'el-icon-document', color: '#409EFF', value: 0 },
        { key: 'month_new', label: '本月新增', icon: 'el-icon-date', color: '#67C23A', value: 0 },
        { key: 'pending', label: '待验收', icon: 'el-icon-time', color: '#E6A23C', value: 0 },
        { key: 'abnormal_rate', label: '异常率(%)', icon: 'el-icon-warning', color: '#F56C6C', value: 0 }
      ]
    }
  },
  created() { this.loadStatistics(); this.loadLevels(); this.loadUsers(); this.loadDicts(); this.loadList() },
  methods: {
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    // 验收状态从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../api/dictionary')
      try { const r = await getDictByCode('maintenance_accept_status'); this.statusOptions = r.data || [] } catch (e) { this.statusOptions = [] }
    },
    statusType(s) { return { pending: 'warning', approved: 'success', rejected: 'danger' }[s] || '' },
    async loadStatistics() {
      try { const r = await getRecordStatistics(); if (r.code === 0) { const d = r.data; this.statCards = [
        { key: 'total', label: '总记录数', icon: 'el-icon-document', color: '#409EFF', value: d.total },
        { key: 'month_new', label: '本月新增', icon: 'el-icon-date', color: '#67C23A', value: d.month_new },
        { key: 'pending', label: '待验收', icon: 'el-icon-time', color: '#E6A23C', value: d.pending },
        { key: 'abnormal_rate', label: '异常率(%)', icon: 'el-icon-warning', color: '#F56C6C', value: d.abnormal_rate }
      ] } } catch (e) {}
    },
    async loadLevels() { try { const r = await getLevelOptions(); if (r.code === 0) this.levelOptions = r.data || [] } catch (e) {} },
    async loadUsers() { try { const r = await getUserList({ limit: 500 }); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) {} },
    async loadList() {
      this.loading = true
      try {
        const p = { page: this.page, limit: this.limit, ...this.filters }
        if (this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] }
        const r = await getRecordList(p)
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    resetFilters() { this.filters = { keyword: '', level_id: null, executor_id: null, accept_status: '' }; this.dateRange = []; this.page = 1; this.loadList() },
    openDetail(row) { this.currentId = row.id; this.detailVisible = true },
    openAccept(row) { this.currentId = row.id; this.acceptVisible = true },
    openReject(row) { this.currentId = row.id; this.rejectVisible = true },
    onSaved() { this.loadList(); this.loadStatistics() },
    async handleExport() {
      try {
        const p = { ...this.filters }
        if (this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] }
        const r = await exportRecords(p)
        if (r.code === 0 && r.data.url) window.open(r.data.url, '_blank')
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.maintenance-record-page { padding: 0; }
.stat-card { display: flex; align-items: center; }
.stat-icon { width: 48px; height: 48px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 22px; margin-right: 12px; }
.stat-val { font-size: 24px; font-weight: 700; line-height: 1.2; }
.stat-label { color: #909399; font-size: 13px; }
.card-header { display: flex; align-items: center; }
</style>
