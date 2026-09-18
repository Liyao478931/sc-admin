<template>
  <div class="maintenance-plan-page">
    <!-- 三个子功能 Tab -->
    <el-tabs v-model="activeTab" class="mt-tabs">
      <el-tab-pane label="保养计划" name="plan">
        <!-- 统计卡片 -->
        <el-row :gutter="16" style="margin-bottom:16px;">
          <el-col :span="6" v-for="card in statCards" :key="card.key" @click.native="filterByStat(card.key)">
            <el-card shadow="hover" class="stat-card" :class="{active: quickKey === card.key}">
              <div class="stat-val" :style="{color: card.color}">{{ card.value }}</div>
              <div class="stat-label">{{ card.label }}</div>
            </el-card>
          </el-col>
        </el-row>

    <!-- 筛选区域 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <el-form :inline="true" size="small">
        <el-form-item label="计划名称">
          <el-input v-model="filters.keyword" placeholder="搜索计划名称/编号" clearable style="width:200px" @keyup.enter.native="loadList" />
        </el-form-item>
        <el-form-item label="保养等级">
          <el-select v-model="filters.level_id" clearable placeholder="全部等级" style="width:130px" @change="loadList">
            <el-option v-for="l in levelOptions" :key="l.id" :label="l.level_name" :value="l.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width:120px" @change="loadList">
            <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="设备">
          <el-select v-model="filters.device_id" filterable clearable placeholder="选择设备" style="width:180px" @change="loadList">
            <el-option v-for="d in deviceOptions" :key="d.id" :label="d.name + '（' + d.device_code + '）'" :value="d.id" />
          </el-select>
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
        <span>保养计划列表</span>
        <div style="float:right;">
          <el-button v-if="hasPerm('device:maintenance:plan:add')" size="small" type="primary" icon="el-icon-plus" @click="openForm()">新增计划</el-button>
          <el-button v-if="hasPerm('device:maintenance:plan:add')" size="small" icon="el-icon-copy-document" @click="handleCopySelected">复制计划</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </div>
      </div>

      <el-table :data="list" v-loading="loading" stripe border size="small" @selection-change="onSelectionChange">
        <el-table-column type="selection" width="40" />
        <el-table-column prop="plan_code" label="计划编号" width="150" />
        <el-table-column prop="plan_name" label="计划名称" min-width="140" show-overflow-tooltip />
        <el-table-column label="关联设备" min-width="130">
          <template slot-scope="{row}"><span>{{ row.device_name }}</span><span style="color:#909399;font-size:12px;margin-left:4px">{{ row.device_code }}</span></template>
        </el-table-column>
        <el-table-column prop="level_name" label="保养等级" width="110" />
        <el-table-column label="周期" width="120">
          <template slot-scope="{row}">{{ cycleTypeLabel(row.cycle_type) }} / {{ row.cycle_value }}</template>
        </el-table-column>
        <el-table-column prop="next_maintenance_date" label="下次保养日期" width="120" />
        <el-table-column label="状态" width="80">
          <template slot-scope="{row}">
            <el-tag :type="row.status === 'active' ? 'success' : (row.status === 'inactive' ? 'info' : 'danger')" size="mini">{{ row.status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="220" fixed="right">
          <template slot-scope="{row}">
            <el-button v-if="hasPerm('device:maintenance:plan:edit')" size="mini" type="text" icon="el-icon-edit" @click="openForm(row)">编辑</el-button>
            <el-button v-if="hasPerm('device:maintenance:plan:add')" size="mini" type="text" icon="el-icon-copy-document" @click="handleCopy(row)">复制</el-button>
            <el-button v-if="hasPerm('device:maintenance:plan:edit')" size="mini" type="text" :style="{color: row.status === 'active' ? '#E6A23C' : '#67C23A'}" @click="handleToggle(row)">
              {{ row.status === 'active' ? '停用' : '启用' }}
            </el-button>
            <el-button v-if="hasPerm('device:maintenance:plan:delete')" size="mini" type="text" icon="el-icon-delete" style="color:#F56C6C" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination background style="margin-top:16px;text-align:right;" :current-page="page" :page-size="limit" :total="total"
        layout="total, sizes, prev, pager, next" :page-sizes="[10,20,50]"
        @size-change="s => { limit = s; page = 1; loadList() }" @current-change="p => { page = p; loadList() }" />
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <plan-form-dialog :visible.sync="formVisible" :plan-id="currentId" :readonly-core="readonlyCore" @saved="onSaved" />
      </el-tab-pane>

      <!-- 保养等级子页面 -->
      <el-tab-pane label="保养等级" name="level">
        <maintenance-level />
      </el-tab-pane>

      <!-- 保养模板子页面 -->
      <el-tab-pane label="保养模板" name="template">
        <maintenance-template />
      </el-tab-pane>

    </el-tabs>
  </div>
</template>

<script>
import { getPlanList, getPlanStatistics, getLevelOptions, copyPlan, deletePlan, togglePlanStatus } from '@/api/maintenance'
import { getAssetList } from '@/api/deviceAsset'
import PlanFormDialog from './PlanFormDialog.vue'
import MaintenanceLevel from './level.vue'
import MaintenanceTemplate from './template.vue'

export default {
  name: 'MaintenancePlan',
  components: { PlanFormDialog, MaintenanceLevel, MaintenanceTemplate },
  data() {
    return {
      activeTab: 'plan',
      list: [], loading: false, total: 0, page: 1, limit: 20,
      quickKey: 'all', formVisible: false, currentId: 0, readonlyCore: false,
      levelOptions: [], deviceOptions: [], selectedRows: [],
      filters: { keyword: '', level_id: null, status: '', device_id: null },
      statCards: [
        { key: 'all', label: '全部计划', color: '#409EFF', value: 0 },
        { key: 'active', label: '启用中', color: '#67C23A', value: 0 },
        { key: 'inactive', label: '已停用', color: '#909399', value: 0 },
        { key: 'expired', label: '已过期', color: '#F56C6C', value: 0 }
      ],
      cycleTypeOptions: [],
      statusOptions: []
    }
  },
  created() { this.loadStatistics(); this.loadLevelOptions(); this.loadDevices(); this.loadDicts(); this.loadList() },
  methods: {
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    // 周期类型/计划状态从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../../api/dictionary')
      try { const r = await getDictByCode('maintenance_cycle_type'); this.cycleTypeOptions = r.data || [] } catch (e) { this.cycleTypeOptions = [] }
      try { const r = await getDictByCode('maintenance_plan_status'); this.statusOptions = r.data || [] } catch (e) { this.statusOptions = [] }
    },
    cycleTypeLabel(t) { const o = this.cycleTypeOptions.find(x => x.value === t); return o ? o.label : (t || '-') },
    async loadStatistics() {
      try { const r = await getPlanStatistics(); if (r.code === 0) { const d = r.data; this.statCards = [
        { key: 'all', label: '全部计划', color: '#409EFF', value: d.all }, { key: 'active', label: '启用中', color: '#67C23A', value: d.active },
        { key: 'inactive', label: '已停用', color: '#909399', value: d.inactive }, { key: 'expired', label: '已过期', color: '#F56C6C', value: d.expired }
      ] } } catch (e) {}
    },
    async loadLevelOptions() { try { const r = await getLevelOptions(); if (r.code === 0) this.levelOptions = r.data || [] } catch (e) {} },
    async loadDevices() { try { const r = await getAssetList({ limit: 500 }); if (r.code === 0) this.deviceOptions = r.data.list || [] } catch (e) {} },
    async loadList() {
      this.loading = true
      try {
        const p = { page: this.page, limit: this.limit, ...this.filters }
        if (this.quickKey && this.quickKey !== 'all') p.status = this.quickKey
        const r = await getPlanList(p)
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    filterByStat(key) { this.quickKey = this.quickKey === key ? 'all' : key; this.page = 1; this.loadList() },
    resetFilters() { this.filters = { keyword: '', level_id: null, status: '', device_id: null }; this.page = 1; this.loadList() },
    openForm(row) {
      this.currentId = row ? row.id : 0
      this.readonlyCore = row ? !!(row.next_maintenance_date) : false
      this.formVisible = true
    },
    onSaved() { this.formVisible = false; this.loadList(); this.loadStatistics() },
    onSelectionChange(rows) { this.selectedRows = rows },
    async handleCopy(row) {
      try { const r = await copyPlan(row.id); if (r.code === 0) { this.$message.success('复制成功'); this.loadList() } } catch (e) {}
    },
    async handleCopySelected() {
      if (!this.selectedRows.length) return this.$message.warning('请先选择计划')
      try { const r = await copyPlan(this.selectedRows[0].id); if (r.code === 0) { this.$message.success('已复制'); this.loadList() } } catch (e) {}
    },
    async handleToggle(row) {
      const newStatus = row.status === 'active' ? 'inactive' : 'active'
      try {
        await this.$confirm(`确认${newStatus === 'inactive' ? '停用' : '启用'}计划「${row.plan_name}」？`, '提示', { type: 'warning' })
        const r = await togglePlanStatus(row.id, newStatus)
        if (r.code === 0) { this.$message.success('已更新'); this.loadList(); this.loadStatistics() }
      } catch (e) {}
    },
    async handleDelete(row) {
      try {
        await this.$confirm(`确认删除计划「${row.plan_name}」？`, '提示', { type: 'warning' })
        const r = await deletePlan(row.id)
        if (r.code === 0) { this.$message.success('已删除'); this.loadList(); this.loadStatistics() }
      } catch (e) {}
    }
  }
}
</script>

<style scoped>
.maintenance-plan-page { padding: 0; }
.stat-card { cursor: pointer; text-align: center; transition: all .2s; }
.stat-card:hover { transform: translateY(-2px); }
.stat-card.active { border-color: #409EFF; }
.stat-val { font-size: 28px; font-weight: 700; }
.stat-label { color: #909399; font-size: 13px; margin-top: 4px; }
.card-header { display: flex; align-items: center; }
</style>
