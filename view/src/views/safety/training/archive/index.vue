<template>
  <div class="archive-page">
    <!-- 统计卡片 -->
    <div class="stat-row">
      <div v-for="card in statCards" :key="card.key" class="stat-card-flex">
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
        <el-form-item><el-input v-model="filters.keyword" placeholder="员工姓名/工号" clearable style="width:180px" @keyup.enter.native="onSearch" /></el-form-item>
        <el-form-item>
          <el-select v-model="filters.department_id" clearable filterable placeholder="全部部门" style="width:150px" @change="onSearch">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.position_id" clearable filterable placeholder="全部岗位" style="width:140px" @change="onSearch">
            <el-option v-for="p in positionOptions" :key="p.id" :label="p.name" :value="p.id" />
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
        <span style="color:#909399">共 <b style="color:#409EFF">{{ total }}</b> 名员工</span>
        <div><el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button></div>
      </div>

      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" />
        <el-table-column prop="user_name" label="员工姓名" min-width="100" />
        <el-table-column prop="department_name" label="所属部门" min-width="120">
          <template slot-scope="{ row }">{{ row.department_name || '-' }}</template>
        </el-table-column>
        <el-table-column prop="position_name" label="岗位" min-width="120">
          <template slot-scope="{ row }">{{ row.position_name || '-' }}</template>
        </el-table-column>
        <el-table-column prop="employee_id" label="工号" width="100" align="center">
          <template slot-scope="{ row }">{{ row.employee_id || '-' }}</template>
        </el-table-column>
        <el-table-column prop="total_count" label="总培训次数" width="110" align="center" sortable="custom" />
        <el-table-column prop="completed_count" label="已完成次数" width="110" align="center" />
        <el-table-column label="完成率" min-width="130">
          <template slot-scope="{ row }">
            <el-progress :percentage="row.rate" :stroke-width="8" />
          </template>
        </el-table-column>
        <el-table-column prop="last_date" label="最近培训" width="120" align="center">
          <template slot-scope="{ row }">{{ row.last_date || '-' }}</template>
        </el-table-column>
        <el-table-column label="操作" width="120" align="center">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('safety:training:archive:query')" size="mini" type="text" @click="openDetail(row)">查看档案</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-empty v-if="!loading && !list.length" description="暂无培训档案" />
      <el-pagination v-if="total > 0" style="margin-top:12px;text-align:right" background layout="total, sizes, prev, pager, next"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10, 20, 50]" @current-change="loadList" @size-change="loadList" />
    </el-card>

    <!-- 档案详情弹窗 -->
    <archive-detail-dialog :visible.sync="detailVisible" :user-id="detailUserId" />
  </div>
</template>

<script>
import { getArchiveList, getArchiveStatistics } from '@/api/safetyTrainingArchive'
import { getDepartmentTree } from '@/api/user'
import { getPositions } from '@/api/organization'
import ArchiveDetailDialog from './components/ArchiveDetailDialog.vue'

export default {
  name: 'SafetyTrainingArchive',
  components: { ArchiveDetailDialog },
  data() {
    return {
      loading: false, list: [], total: 0, page: 1, limit: 10,
      filters: { keyword: '', department_id: null, position_id: null },
      stats: { total_users: 0, total_attendee: 0, avg_rate: 0, cert_expire_soon: 0 },
      deptOptions: [], positionOptions: [],
      detailVisible: false, detailUserId: 0
    }
  },
  computed: {
    statCards() {
      return [
        { key: 'total_users', label: '总员工数', value: this.stats.total_users, icon: 'el-icon-user', color: '#409EFF' },
        { key: 'total_attendee', label: '总培训人次', value: this.stats.total_attendee, icon: 'el-icon-medal', color: '#67C23A' },
        { key: 'avg_rate', label: '平均完成率', value: this.stats.avg_rate + '%', icon: 'el-icon-pie-chart', color: '#E6A23C' },
        { key: 'cert_expire_soon', label: '证书即将过期', value: this.stats.cert_expire_soon, icon: 'el-icon-warning', color: '#F56C6C' }
      ]
    }
  },
  created() {
    if (this.$store.state.user && this.$store.state.user.permissions && !this.$store.state.user.permissions.length) {
      this.$store.dispatch('user/loadPermissions')
    }
    this.loadList(); this.loadStats(); this.loadDepts(); this.loadPositions()
  },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    async loadList() {
      this.loading = true
      try {
        const r = await getArchiveList({
          page: this.page, limit: this.limit,
          keyword: this.filters.keyword || '',
          department_id: this.filters.department_id || '',
          position_id: this.filters.position_id || ''
        })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    async loadStats() {
      try { const r = await getArchiveStatistics(); if (r.code === 0) this.stats = r.data || {} } catch (e) {}
    },
    async loadDepts() {
      try {
        const r = await getDepartmentTree()
        const flat = []
        const walk = (nodes) => (nodes || []).forEach(n => { flat.push({ id: n.id, name: n.name }); walk(n.children) })
        walk(r.data || [])
        this.deptOptions = flat
      } catch (e) {}
    },
    async loadPositions() {
      try { const r = await getPositions(); if (r.code === 0) this.positionOptions = r.data || [] } catch (e) {}
    },
    onSearch() { this.page = 1; this.loadList() },
    resetFilters() { this.filters = { keyword: '', department_id: null, position_id: null }; this.page = 1; this.loadList() },
    openDetail(row) { this.detailUserId = row.user_id; this.detailVisible = true }
  }
}
</script>

<style scoped>
.stat-row { display: flex; gap: 16px; margin-bottom: 16px; }
.stat-card-flex { flex: 1; background: #fff; border-radius: 8px; padding: 16px; box-shadow: 0 2px 8px rgba(0,0,0,.04); min-width: 0; }
.stat-card-flex .stat-icon { width: 40px; height: 40px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 20px; float: left; margin-right: 10px; }
.stat-card-flex .stat-info { overflow: hidden; }
.stat-card-flex .stat-val { font-size: 20px; font-weight: 700; line-height: 1.2; }
.stat-card-flex .stat-label { font-size: 12px; color: #909399; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
