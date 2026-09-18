<template>
  <div class="status-change-page">
    <!-- 面包屑 -->
    <el-breadcrumb separator="/" class="crumb">
      <el-breadcrumb-item>设备管理</el-breadcrumb-item>
      <el-breadcrumb-item>状态变更</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="6">
        <div class="stat-card" @click="quickByDate('today')">
          <div class="stat-icon blue"><i class="el-icon-s-order"></i></div>
          <div class="stat-info"><div class="stat-num">{{ stats.today_count || 0 }}</div><div class="stat-label">今日变更</div></div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card" @click="quickByDate('month')">
          <div class="stat-icon green"><i class="el-icon-date"></i></div>
          <div class="stat-info"><div class="stat-num">{{ stats.month_count || 0 }}</div><div class="stat-label">本月变更</div></div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card" @click="loadList({ rollback_only: 1 })">
          <div class="stat-icon orange"><i class="el-icon-time"></i></div>
          <div class="stat-info"><div class="stat-num">{{ stats.pending_rollback || 0 }}</div><div class="stat-label">待处理变更(24h可撤销)</div></div>
        </div>
      </el-col>
      <el-col :span="6">
        <div class="stat-card" @click="quickMine()">
          <div class="stat-icon gray"><i class="el-icon-user"></i></div>
          <div class="stat-info"><div class="stat-num">{{ stats.my_count || 0 }}</div><div class="stat-label">我的变更(本月)</div></div>
        </div>
      </el-col>
    </el-row>

    <!-- 筛选区 -->
    <div class="panel">
      <el-form :inline="true" :model="filter" size="small" class="filter-form">
        <el-form-item label="设备关键字">
          <el-input v-model="filter.keyword" placeholder="请输入设备名称或编码" clearable style="width:180px" @keyup.enter.native="onSearch" />
        </el-form-item>
        <el-form-item label="变更前状态">
          <el-select v-model="filter.from_status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="变更后状态">
          <el-select v-model="filter.to_status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="变更人">
          <el-select v-model="filter.operator_id" clearable filterable placeholder="全部" style="width:130px">
            <el-option v-for="m in managerList" :key="m.id" :label="m.name" :value="m.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="变更类型">
          <el-select v-model="filter.change_type" clearable placeholder="全部" style="width:110px">
            <el-option v-for="t in changeTypeOptions" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="设备类型">
          <el-select v-model="filter.device_type" clearable placeholder="全部" style="width:120px">
            <el-option v-for="t in typeOptions" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="变更日期">
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:240px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="onReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 表格 -->
    <div class="panel" v-loading="loading">
      <div class="toolbar">
        <div class="toolbar-left">
          <el-button v-if="hasPerm('device:status:add')" size="small" type="primary" icon="el-icon-plus" @click="createVisible = true">发起变更</el-button>
          <el-button v-if="hasPerm('device:status:batch')" size="small" type="warning" icon="el-icon-finished" @click="batchVisible = true">批量变更</el-button>
          <el-button v-if="hasPerm('device:status:export')" size="small" icon="el-icon-download" @click="doExport">导出</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </div>
        <div class="toolbar-right">共 {{ total }} 条</div>
      </div>

      <el-table :data="list" size="small" border stripe style="width:100%" @sort-change="onSortChange" highlight-current-row>
        <el-table-column type="index" label="#" width="48" align="center" />
        <el-table-column prop="id" label="变更ID" width="70" align="center" />
        <el-table-column prop="device_code" label="设备编码" width="130" sortable="custom">
          <template slot-scope="{ row }"><el-link type="primary" @click="openDeviceDetail(row.asset_id)">{{ row.device_code }}</el-link></template>
        </el-table-column>
        <el-table-column prop="device_name" label="设备名称" min-width="140" show-overflow-tooltip />
        <el-table-column label="设备类型" width="90" align="center">
          <template slot-scope="{ row }"><el-tag :type="typeTagType(row.device_type)" size="mini" effect="plain">{{ typeLabel(row.device_type) }}</el-tag></template>
        </el-table-column>
        <el-table-column label="变更前" width="100" align="center">
          <template slot-scope="{ row }"><el-tag :type="statusTagType(row.from_status)" size="mini">{{ statusLabel(row.from_status) || '初始' }}</el-tag></template>
        </el-table-column>
        <el-table-column label="变更后" width="100" align="center">
          <template slot-scope="{ row }"><el-tag :type="statusTagType(row.to_status)" size="mini">{{ statusLabel(row.to_status) }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="reason" label="变更原因" min-width="150" show-overflow-tooltip />
        <el-table-column prop="operator_name" label="变更人" width="80" />
        <el-table-column prop="change_time" label="变更时间" width="160" sortable="custom" />
        <el-table-column label="关联单据" width="130">
          <template slot-scope="{ row }"><el-link v-if="row.related_order_no" type="primary">{{ row.related_order_no }}</el-link><span v-else>-</span></template>
        </el-table-column>
        <el-table-column label="变更类型" width="80" align="center">
          <template slot-scope="{ row }"><el-tag :type="row.change_type === 'rollback' ? 'danger' : 'primary'" size="mini">{{ row.change_type === 'rollback' ? '撤销' : '正常' }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="150" fixed="right" align="center">
          <template slot-scope="{ row }">
            <el-button v-if="hasPerm('device:status:query')" size="mini" type="text" icon="el-icon-view" @click="openDetail(row.id)">详情</el-button>
            <el-button :disabled="!canRollback(row)" size="mini" type="text" icon="el-icon-refresh-left" style="color:#F56C6C" @click="confirmRollback(row)">撤销</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
                     :total="total" :current-page="page" :page-size="limit"
                     :page-sizes="[10, 20, 50, 100]" @current-change="p => (page = p, loadList())"
                     @size-change="s => (limit = s, page = 1, loadList())" />
    </div>

    <!-- 弹窗 -->
    <create-dialog :visible.sync="createVisible" :status-options="statusOptions" @saved="onSaved" />
    <batch-dialog :visible.sync="batchVisible" :status-options="statusOptions" @saved="onSaved" />
    <detail-dialog :visible.sync="detailVisible" :record-id="detailId" :status-options="statusOptions" :change-type-options="changeTypeOptions" />
  </div>
</template>

<script>
import { getStatusChangeList, exportStatusChange, getStatusChangeStatistics, getStatusChangeDetail } from '@/api/deviceStatusChange'
import { getDictionaryBatch } from '@/utils/dict'
import { getManagers } from '@/api/deviceAsset'
import CreateDialog from './components/CreateDialog.vue'
import BatchDialog from './components/BatchDialog.vue'
import DetailDialog from './components/DetailDialog.vue'

export default {
  name: 'DeviceStatusChange',
  components: { CreateDialog, BatchDialog, DetailDialog },
  data() {
    return {
      loading: false,
      list: [],
      total: 0,
      page: 1,
      limit: 20,
      filter: { keyword: '', from_status: '', to_status: '', operator_id: '', device_type: '', change_type: '' },
      dateRange: null,
      rollbackOnly: 0,
      myOnly: 0,
      sortField: 'change_time',
      sortOrder: 'desc',
      stats: {},
      statusOptions: [],
      typeOptions: [],
      changeTypeOptions: [],
      managerList: [],
      createVisible: false,
      batchVisible: false,
      detailVisible: false,
      detailId: 0
    }
  },
  async created() {
    this.loadDicts()
    this.loadManagers()
    this.loadList()
    this.loadStats()
    if (!this.$store.state.user || !this.$store.state.user.permissions || !this.$store.state.user.permissions.length) {
      try { await this.$store.dispatch('user/loadPermissions') } catch (e) {}
    }
  },
  methods: {
    hasPerm(code) {
      const perms = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return perms.indexOf(code) > -1
    },
    async loadDicts() {
      try {
        const res = await getDictionaryBatch(['device_status', 'device_type', 'change_type'])
        this.statusOptions = res['device_status'] || []
        this.typeOptions = res['device_type'] || []
        this.changeTypeOptions = res['change_type'] || []
      } catch (e) {}
    },
    async loadManagers() {
      try {
        const res = await getManagers()
        this.managerList = res.data || []
      } catch (e) {}
    },
    async loadList(extra = {}) {
      this.loading = true
      try {
        const params = {
          page: this.page, limit: this.limit,
          keyword: this.filter.keyword || '',
          from_status: this.filter.from_status || '',
          to_status: this.filter.to_status || '',
          operator_id: this.filter.operator_id || '',
          device_type: this.filter.device_type || '',
          change_type: this.filter.change_type || '',
          start_date: this.dateRange ? this.dateRange[0] : '',
          end_date: this.dateRange ? this.dateRange[1] : '',
          sort_field: this.sortField,
          sort_order: this.sortOrder,
          ...extra
        }
        const res = await getStatusChangeList(params)
        if (res.code === 0) { this.list = res.data.list || []; this.total = res.data.total || 0 }
      } catch (e) { this.$message.error('网络异常，请稍后重试') }
      this.loading = false
    },
    async loadStats() {
      try {
        const res = await getStatusChangeStatistics()
        if (res.code === 0) this.stats = res.data
      } catch (e) {}
    },
    onSearch() { this.page = 1; this.rollbackOnly = 0; this.myOnly = 0; this.loadList() },
    onReset() {
      this.filter = { keyword: '', from_status: '', to_status: '', operator_id: '', device_type: '', change_type: '' }
      this.dateRange = null
      this.rollbackOnly = 0
      this.myOnly = 0
      this.page = 1
      this.loadList()
    },
    quickByDate(type) {
      this.rollbackOnly = 0
      this.myOnly = 0
      this.dateRange = type === 'today' ? [this.today(), this.today()] : [this.monthStart(), this.today()]
      this.page = 1
      this.loadList()
    },
    quickMine() {
      this.rollbackOnly = 0
      this.myOnly = 1
      this.page = 1
      this.loadList({ my_only: 1 })
    },
    today() { const d = new Date(); return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}` },
    monthStart() { return this.today().slice(0, 8) + '01' },
    onSortChange({ prop, order }) {
      if (order) { this.sortField = prop === 'device_code' ? 'device_code' : prop === 'change_time' ? 'change_time' : 'change_time'; this.sortOrder = order === 'ascending' ? 'asc' : 'desc' }
      this.loadList()
    },
    typeLabel(v) { const t = this.typeOptions.find(x => x.value === v); return t ? t.label : (v || '-') },
    typeTagType(v) { return { general: 'primary', special: 'danger', car: 'success', truck: 'warning' }[v] || 'info' },
    statusLabel(v) { const s = this.statusOptions.find(x => x.value === v); return s ? s.label : (v || '') },
    statusTagType(v) { const s = this.statusOptions.find(x => x.value === v); return (s && s.style) || 'info' },
    // 撤销可用性：前端仅作展示提示，真正校验在后端
    canRollback(row) {
      if (row.change_type !== 'normal') return false
      if (!this.hasPerm('device:status:rollback') && !this.hasPerm('device:status:rollback_all')) return false
      const t = new Date(row.change_time).getTime()
      if (Date.now() - t > 24 * 3600 * 1000) return false
      return true
    },
    openDeviceDetail(assetId) {
      this.detailVisible = true
      this.detailId = 0
      // 打开设备台账页面（同窗口跳转）
      this.$router.push({ path: '/device/asset', query: { focus_asset: assetId } })
    },
    openDetail(id) { this.detailId = id; this.detailVisible = true },
    confirmRollback(row) {
      this.$confirm(`确定撤销设备 [${row.device_name}] 的状态变更吗？\n变更前：${this.statusLabel(row.from_status) || '初始'} → 变更后：${this.statusLabel(row.to_status)}\n变更时间：${row.change_time}`, '撤销确认', {
        confirmButtonText: '确定撤销', cancelButtonText: '取消', type: 'warning'
      }).then(async () => {
        const { rollbackStatusChange } = await import('@/api/deviceStatusChange')
        try {
          const res = await rollbackStatusChange(row.id)
          this.$message.success(res.msg || '撤销成功')
          this.onSaved()
        } catch (e) { /* 拦截器已提示 */ }
      }).catch(() => {})
    },
    async doExport() {
      this.$confirm(`当前筛选条件下共 ${this.total} 条变更记录，确定导出吗？`, '导出确认', { type: 'info' })
        .then(async () => {
          try {
            const res = await exportStatusChange({
              keyword: this.filter.keyword || '', from_status: this.filter.from_status || '',
              to_status: this.filter.to_status || '', operator_id: this.filter.operator_id || '',
              start_date: this.dateRange ? this.dateRange[0] : '', end_date: this.dateRange ? this.dateRange[1] : ''
            })
            if (res.code === 0 && res.data && res.data.url) { window.open(res.data.url, '_blank'); this.$message.success('导出成功') }
          } catch (e) {}
        }).catch(() => {})
    },
    onSaved() { this.loadList(); this.loadStats() }
  }
}
</script>

<style scoped>
.status-change-page { padding: 16px; }
.crumb { margin-bottom: 14px; }
.stat-row { margin-bottom: 16px; }
.stat-card { display: flex; align-items: center; gap: 12px; background: #fff; border-radius: 8px; padding: 16px; box-shadow: 0 2px 8px rgba(0,0,0,.04); cursor: pointer; }
.stat-icon { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 24px; color: #fff; }
.stat-icon.blue { background: #409EFF; }
.stat-icon.green { background: #67C23A; }
.stat-icon.orange { background: #E6A23C; }
.stat-icon.gray { background: #909399; }
.stat-num { font-size: 22px; font-weight: 700; }
.stat-label { color: #909399; font-size: 12px; }
.panel { background: #fff; border-radius: 8px; padding: 14px; box-shadow: 0 2px 8px rgba(0,0,0,.04); margin-bottom: 16px; }
.filter-form { margin-bottom: 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.toolbar-left { display: flex; gap: 8px; flex-wrap: wrap; }
.toolbar-right { color: #909399; font-size: 13px; }
.pager { margin-top: 14px; text-align: right; }
</style>
