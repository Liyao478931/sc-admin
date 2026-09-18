<template>
  <div class="repair-order-page">
    <!-- 统计卡片 -->
    <el-row :gutter="16" style="margin-bottom:16px;">
      <el-col :span="4" v-for="card in statCards" :key="card.key">
        <el-card shadow="hover" class="stat-card" :class="{active: quickStatus === card.value}" @click.native="quickFilter(card.value)">
          <div class="stat-icon" :style="{background: card.color + '1a', color: card.color}"><i :class="card.icon"></i></div>
          <div class="stat-info"><div class="stat-val" :style="{color: card.color}">{{ card.value === null ? card.num : card.num }}</div><div class="stat-label">{{ card.label }}</div></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 筛选区域 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <el-form :inline="true" size="small">
        <el-form-item><el-input v-model="filters.keyword" placeholder="工单编号/设备名称/编码" clearable style="width:200px" @keyup.enter.native="loadList" /></el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width:110px" @change="loadList">
            <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.fault_type" clearable placeholder="全部故障类型" style="width:120px" @change="loadList">
            <el-option v-for="f in faultOptions" :key="f.value" :label="f.label" :value="f.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.emergency_level" clearable placeholder="全部紧急程度" style="width:110px" @change="loadList">
            <el-option v-for="e in emergencyOptions" :key="e.value" :label="e.label" :value="e.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.source_type" clearable placeholder="全部来源" style="width:120px" @change="loadList">
            <el-option v-for="s in sourceOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.reporter_id" clearable filterable placeholder="全部报修人" style="width:120px" @change="loadList">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.handler_id" clearable filterable placeholder="全部处理人" style="width:120px" @change="loadList">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="报修开始" end-placeholder="报修结束"
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
        <span>维修工单列表 · 共 {{ total }} 条<el-tag v-if="selection.length" size="small" style="margin-left:12px">已选 {{ selection.length }} 条</el-tag></span>
        <div>
          <el-button v-if="hasPerm('device:repair:order:delete')" size="small" type="danger" plain :disabled="!selection.length" @click="handleBatchDelete">批量删除</el-button>
          <el-button v-if="hasPerm('device:repair:order:assign')" size="small" :disabled="!selection.length" @click="openBatchAssign">批量派单</el-button>
          <el-button v-if="hasPerm('device:repair:order:add')" size="small" type="primary" icon="el-icon-plus" @click="openAdd">新增工单</el-button>
          <el-button v-if="hasPerm('device:repair:order:export')" size="small" icon="el-icon-download" @click="handleExport">导出</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </div>
      </div>

      <el-table :data="list" v-loading="loading" stripe border size="small" @selection-change="s => this.selection = s">
        <el-table-column type="selection" width="45" />
        <el-table-column type="index" label="#" width="55" />
        <el-table-column label="工单编号" width="170">
          <template slot-scope="{row}"><el-link type="primary" @click="openDetail(row)">{{ row.order_code }}</el-link></template>
        </el-table-column>
        <el-table-column prop="device_name" label="设备名称" min-width="130" show-overflow-tooltip />
        <el-table-column prop="device_code" label="设备编码" width="130" />
        <el-table-column label="故障类型" width="95">
          <template slot-scope="{row}"><el-tag size="mini">{{ faultLabel(row.fault_type) }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="fault_desc_short" label="故障描述" min-width="150" show-overflow-tooltip />
        <el-table-column label="紧急程度" width="85">
          <template slot-scope="{row}"><el-tag :type="emergencyType(row.emergency_level)" size="mini">{{ row.emergency_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="reporter_name" label="报修人" width="80" />
        <el-table-column prop="report_time" label="报修时间" width="155" />
        <el-table-column prop="handler_name" label="处理人" width="80" />
        <el-table-column label="状态" width="90">
          <template slot-scope="{row}"><el-tag :type="statusType(row.status)" size="mini">{{ row.status_text }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template slot-scope="{row}">
            <el-button v-if="row.status === 'pending' && hasPerm('device:repair:order:edit')" size="mini" type="text" @click="openEdit(row)">编辑</el-button>
            <el-button v-if="row.status === 'pending' && hasPerm('device:repair:order:delete')" size="mini" type="text" style="color:#F56C6C" @click="handleDelete(row)">删除</el-button>
            <el-button v-if="row.status === 'pending' && hasPerm('device:repair:order:assign')" size="mini" type="text" style="color:#67C23A" @click="openAssign(row)">派单</el-button>
            <el-button v-if="['assigned','repairing'].includes(row.status) && hasPerm('device:repair:order:assign')" size="mini" type="text" style="color:#E6A23C" @click="openTransfer(row)">转派</el-button>
            <el-button v-if="row.status === 'accepted' && hasPerm('device:repair:order:accept')" size="mini" type="text" style="color:#67C23A" @click="openAccept(row, 'accept')">验收</el-button>
            <el-button v-if="row.status === 'accepted' && hasPerm('device:repair:order:reject')" size="mini" type="text" style="color:#F56C6C" @click="openAccept(row, 'reject')">驳回</el-button>
            <el-button size="mini" type="text" @click="openDetail(row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination background style="margin-top:16px;text-align:right;" :current-page="page" :page-size="limit" :total="total"
        layout="total, sizes, prev, pager, next" :page-sizes="[10,20,50,100]"
        @size-change="s => { limit = s; page = 1; loadList() }" @current-change="p => { page = p; loadList() }" />
    </el-card>

    <!-- 弹窗 -->
    <order-detail-dialog :visible.sync="detailVisible" :order-id="currentId" />
    <order-form-dialog :visible.sync="formVisible" :order-id="currentId" @saved="onSaved" />
    <order-assign-dialog :visible.sync="assignVisible" :order-id="currentId" :batch-ids="batchIds" @saved="onSaved" />
    <order-transfer-dialog :visible.sync="transferVisible" :order-id="currentId" @saved="onSaved" />
    <order-accept-dialog :visible.sync="acceptVisible" :order-id="currentId" :mode="acceptMode" @saved="onSaved" />
  </div>
</template>

<script>
import { getOrderList, getOrderStatistics, deleteOrder, batchDeleteOrders, exportOrders } from '@/api/repairOrder'
import { getUserList } from '@/api/user'
import OrderDetailDialog from './components/OrderDetailDialog.vue'
import OrderFormDialog from './components/OrderFormDialog.vue'
import OrderAssignDialog from './components/OrderAssignDialog.vue'
import OrderTransferDialog from './components/OrderTransferDialog.vue'
import OrderAcceptDialog from './components/OrderAcceptDialog.vue'

export default {
  name: 'RepairOrder',
  components: { OrderDetailDialog, OrderFormDialog, OrderAssignDialog, OrderTransferDialog, OrderAcceptDialog },
  data() {
    return {
      list: [], loading: false, total: 0, page: 1, limit: 20, selection: [],
      detailVisible: false, formVisible: false, assignVisible: false, transferVisible: false, acceptVisible: false,
      currentId: 0, batchIds: [], acceptMode: 'accept', quickStatus: null,
      dateRange: [], userOptions: [],
      filters: { keyword: '', status: '', fault_type: '', emergency_level: '', source_type: '', reporter_id: null, handler_id: null },
      statusOptions: [],
      faultOptions: [],
      emergencyOptions: [],
      sourceOptions: [],
      statCards: [
        { key: 'all', label: '全部工单', icon: 'el-icon-document', color: '#409EFF', value: null },
        { key: 'pending', label: '待派单', icon: 'el-icon-time', color: '#909399', value: 'pending' },
        { key: 'repairing', label: '维修中', icon: 'el-icon-s-tools', color: '#E6A23C', value: 'repairing' },
        { key: 'accepted', label: '待验收', icon: 'el-icon-view', color: '#8E44AD', value: 'accepted' },
        { key: 'approved', label: '已验收', icon: 'el-icon-circle-check', color: '#67C23A', value: 'approved' },
        { key: 'closed', label: '已关闭', icon: 'el-icon-circle-close', color: '#909399', value: 'closed' }
      ]
    }
  },
  created() { this.loadStatistics(); this.loadUsers(); this.loadDicts(); this.loadList() },
  methods: {
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    // 状态/故障/紧急/来源从字典动态加载（字典新增即自动显示）
    async loadDicts() {
      const { getDictByCode } = await import('../../../api/dictionary')
      try { const r = await getDictByCode('repair_order_status'); this.statusOptions = r.data || [] } catch (e) { this.statusOptions = [] }
      try { const r = await getDictByCode('repair_fault_type'); this.faultOptions = r.data || [] } catch (e) { this.faultOptions = [] }
      try { const r = await getDictByCode('repair_emergency_level'); this.emergencyOptions = r.data || [] } catch (e) { this.emergencyOptions = [] }
      try { const r = await getDictByCode('repair_source_type'); this.sourceOptions = r.data || [] } catch (e) { this.sourceOptions = [] }
    },
    statusType(s) { return { pending: 'info', assigned: 'primary', repairing: 'warning', accepted: 'warning', approved: 'success', closed: 'info', rejected: 'danger' }[s] || '' },
    emergencyType(e) { return { critical: 'danger', urgent: 'warning', normal: 'info' }[e] || '' },
    faultLabel(v) { const f = this.faultOptions.find(x => x.value === v); return f ? f.label : v },
    async loadUsers() { try { const r = await getUserList({ limit: 500 }); if (r.code === 0) this.userOptions = r.data.list || [] } catch (e) {} },
    async loadStatistics() {
      try {
        const r = await getOrderStatistics()
        if (r.code === 0) {
          const d = r.data
          this.statCards = [
            { key: 'all', label: '全部工单', icon: 'el-icon-document', color: '#409EFF', value: null, num: d.all },
            { key: 'pending', label: '待派单', icon: 'el-icon-time', color: '#909399', value: 'pending', num: d.pending },
            { key: 'repairing', label: '维修中', icon: 'el-icon-s-tools', color: '#E6A23C', value: 'repairing', num: d.repairing },
            { key: 'accepted', label: '待验收', icon: 'el-icon-view', color: '#8E44AD', value: 'accepted', num: d.accepted },
            { key: 'approved', label: '已验收', icon: 'el-icon-circle-check', color: '#67C23A', value: 'approved', num: d.approved },
            { key: 'closed', label: '已关闭', icon: 'el-icon-circle-close', color: '#909399', value: 'closed', num: d.closed }
          ]
        }
      } catch (e) {}
    },
    async loadList() {
      this.loading = true
      try {
        const p = { page: this.page, limit: this.limit, ...this.filters }
        if (this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] }
        const r = await getOrderList(p)
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    quickFilter(value) { this.filters.status = value === null ? '' : value; this.quickStatus = value; this.page = 1; this.loadList() },
    resetFilters() { this.filters = { keyword: '', status: '', fault_type: '', emergency_level: '', source_type: '', reporter_id: null, handler_id: null }; this.dateRange = []; this.quickStatus = null; this.page = 1; this.loadList() },
    onSaved() { this.loadList(); this.loadStatistics() },
    openDetail(row) { this.currentId = row.id; this.detailVisible = true },
    openAdd() { this.currentId = 0; this.formVisible = true },
    openEdit(row) { this.currentId = row.id; this.formVisible = true },
    openAssign(row) { this.currentId = row.id; this.batchIds = []; this.assignVisible = true },
    openBatchAssign() { this.batchIds = this.selection.map(x => x.id); this.currentId = 0; this.assignVisible = true },
    openTransfer(row) { this.currentId = row.id; this.transferVisible = true },
    openAccept(row, mode) { this.currentId = row.id; this.acceptMode = mode; this.acceptVisible = true },
    handleDelete(row) {
      this.$confirm(`确定删除工单 ${row.order_code} 吗？删除后不可恢复。`, '删除确认', { type: 'warning' })
        .then(async () => { const r = await deleteOrder(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.onSaved() } }).catch(() => {})
    },
    handleBatchDelete() {
      this.$confirm(`确定删除选中的 ${this.selection.length} 条工单吗？`, '批量删除确认', { type: 'warning' })
        .then(async () => {
          const r = await batchDeleteOrders(this.selection.map(x => x.id))
          if (r.code === 0) { this.$message.success(r.msg || '删除完成'); this.onSaved() }
        }).catch(() => {})
    },
    async handleExport() {
      try {
        const p = { ...this.filters }
        if (this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] }
        const r = await exportOrders(p)
        if (r.code === 0 && r.data.url) window.open(r.data.url, '_blank')
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.repair-order-page { padding: 0; }
.stat-card { display: flex; align-items: center; border-radius: 8px; cursor: pointer; }
.stat-card.active { border-color: #409EFF; }
.stat-icon { width: 44px; height: 44px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 20px; margin-right: 10px; }
.stat-val { font-size: 22px; font-weight: 700; line-height: 1.2; }
.stat-label { color: #909399; font-size: 13px; }
.card-header { display: flex; align-items: center; justify-content: space-between; }
</style>
