<template>
  <div class="device-remind-page">
    <!-- 概览统计卡片 -->
    <el-row :gutter="16" style="margin-bottom:16px;">
      <el-col :span="6" v-for="card in statCards" :key="card.key">
        <el-card shadow="hover" class="stat-card" :body-style="{padding:'16px'}" @click.native="quickFilter(card)">
          <div class="stat-icon" :style="{background: card.color + '1a', color: card.color}"><i :class="card.icon"></i></div>
          <div class="stat-info"><div class="stat-val" :style="{color: card.color}">{{ card.value }}</div><div class="stat-label">{{ card.label }}</div></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 筛选区域 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <el-form :inline="true" size="small">
        <el-form-item>
          <el-select v-model="filters.remind_type" clearable placeholder="全部类型" style="width:130px" @change="loadList">
            <el-option v-for="t in typeOptions" :key="t.value" :label="t.label" :value="t.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width:120px" @change="loadList">
            <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-input v-model="filters.keyword" placeholder="请输入设备名称或编码" clearable style="width:200px" @keyup.enter.native="loadList" />
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="到期开始" end-placeholder="到期结束"
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
        <span style="color:#909399">共 <b style="color:#409EFF">{{ total }}</b> 条提醒记录</span>
        <div>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
          <el-button size="small" icon="el-icon-setting" @click="openConfig">提醒配置</el-button>
          <el-button size="small" icon="el-icon-time" @click="openHistory">提醒历史</el-button>
        </div>
      </div>

      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column label="提醒类型" width="110" align="center">
          <template slot-scope="{row}">
            <el-tag size="mini" :color="row.color" style="color:#fff;border:none">{{ row.remind_type_name }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="设备名称" min-width="140" show-overflow-tooltip>
          <template slot-scope="{row}">
            <el-link type="primary" @click="viewDevice(row)">{{ row.device_name }}</el-link>
          </template>
        </el-table-column>
        <el-table-column prop="device_code" label="设备编码" width="120" show-overflow-tooltip />
        <el-table-column prop="remind_item" label="提醒事项" min-width="160" show-overflow-tooltip />
        <el-table-column label="到期日期" width="120">
          <template slot-scope="{row}">
            <span :style="{color: row.status === 'overdue' ? '#F56C6C' : '', fontWeight: row.status === 'overdue' ? '700' : 'normal'}">{{ row.due_date || '—' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="逾期天数" width="100" align="center">
          <template slot-scope="{row}">
            <span :style="{color: row.diff_days < 0 ? '#F56C6C' : row.diff_days <= 3 ? '#E6A23C' : '#67C23A', fontWeight: '600'}">
              {{ row.diff_days < 0 ? Math.abs(row.diff_days) + '天' : row.diff_days === 0 ? '今天' : row.diff_days + '天' }}
            </span>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="100" align="center">
          <template slot-scope="{row}">
            <el-tag size="mini" :type="row.status === 'overdue' ? 'danger' : row.status === 'soon' ? 'warning' : 'primary'">{{ row.status_name }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="160" align="center">
          <template slot-scope="{row}">
            <el-button v-if="hasPerm('device:remind:handle')" size="mini" type="text" style="color:#67C23A" @click="handleMark(row)">去处理</el-button>
            <el-button size="mini" type="text" @click="goJump(row)">跳转</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination style="margin-top:12px;text-align:right"
        background layout="total, sizes, prev, pager, next"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10,20,50]" @current-change="loadList" @size-change="loadList" />
    </el-card>

    <!-- 提醒配置弹窗 -->
    <el-dialog title="提醒配置" :visible.sync="configVisible" width="550px" append-to-body>
      <el-form :model="configForm" label-width="160px" size="small">
        <el-form-item label="巡检提前提醒天数"><el-input-number v-model="configForm.inspection_advance_days" :min="0" :max="90" /></el-form-item>
        <el-form-item label="保养提前提醒天数"><el-input-number v-model="configForm.maintenance_advance_days" :min="0" :max="90" /></el-form-item>
        <el-form-item label="年检提前提醒天数"><el-input-number v-model="configForm.annual_inspection_advance_days" :min="0" :max="365" /></el-form-item>
        <el-form-item label="保险提前提醒天数"><el-input-number v-model="configForm.insurance_advance_days" :min="0" :max="365" /></el-form-item>
        <el-form-item label="特种检验提前提醒天数"><el-input-number v-model="configForm.special_inspection_advance_days" :min="0" :max="365" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="configVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="configSaving" @click="saveConfig">保存</el-button>
      </div>
    </el-dialog>

    <!-- 提醒历史弹窗 -->
    <el-dialog title="提醒历史" :visible.sync="historyVisible" width="900px" top="6vh" append-to-body>
      <el-form :inline="true" size="small" style="margin-bottom:12px">
        <el-form-item>
          <el-date-picker v-model="historyRange" type="daterange" range-separator="至" start-placeholder="处理开始" end-placeholder="处理结束"
            value-format="yyyy-MM-dd" style="width:240px" @change="loadHistory" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" size="mini" @click="loadHistory">查询</el-button>
        </el-form-item>
      </el-form>
      <el-table :data="historyList" v-loading="historyLoading" border stripe size="small">
        <el-table-column type="index" label="序号" width="55" />
        <el-table-column label="提醒类型" width="100">
          <template slot-scope="{row}">
            <el-tag size="mini" :color="row.color" style="color:#fff;border:none">{{ row.remind_type_name }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="device_name" label="设备名称" min-width="130" />
        <el-table-column prop="device_code" label="设备编码" width="120" />
        <el-table-column prop="remind_item" label="提醒事项" min-width="140" show-overflow-tooltip />
        <el-table-column prop="due_date" label="到期日期" width="110" />
        <el-table-column prop="handled_at" label="处理时间" width="160" />
        <el-table-column prop="handler_name" label="处理人" width="80" />
      </el-table>
      <el-pagination style="margin-top:10px;text-align:right" background layout="total, prev, pager, next"
        :total="historyTotal" :current-page.sync="historyPage" :page-size="10" @current-change="loadHistory" />
    </el-dialog>
  </div>
</template>

<script>
import { getRemindList, getRemindStatistics, getRemindConfig, saveRemindConfig, markRemindHandled, getRemindHistory } from '@/api/deviceRemind'

export default {
  name: 'DeviceRemind',
  data() {
    return {
      loading: false,
      list: [],
      total: 0,
      page: 1,
      limit: 10,
      filters: { remind_type: '', status: '', keyword: '' },
      dateRange: [],
      stats: { today_todo: 0, week_due: 0, overdue: 0, repair_pending: 0 },
      typeOptions: [],
      statusOptions: [],
      configVisible: false,
      configSaving: false,
      configForm: { inspection_advance_days: 3, maintenance_advance_days: 7, annual_inspection_advance_days: 30, insurance_advance_days: 30, special_inspection_advance_days: 30 },
      historyVisible: false,
      historyLoading: false,
      historyList: [],
      historyTotal: 0,
      historyPage: 1,
      historyRange: [],
    }
  },
  computed: {
    statCards() {
      return [
        { key: 'today_todo', label: '今日待办', value: this.stats.today_todo, icon: 'el-icon-timer', color: '#409EFF' },
        { key: 'week_due', label: '本周到期', value: this.stats.week_due, icon: 'el-icon-date', color: '#E6A23C' },
        { key: 'overdue', label: '已逾期', value: this.stats.overdue, icon: 'el-icon-warning', color: '#F56C6C' },
        { key: 'repair_pending', label: '待处理工单', value: this.stats.repair_pending, icon: 'el-icon-s-tools', color: '#9B59B6' },
      ]
    },
  },
  created() {
    this.loadList()
    this.loadStats()
    this.loadDicts()
  },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    // 提醒类型/状态从字典动态加载（字典新增即自动显示）
    async loadDicts() {
      const { getDictByCode } = await import('../../../api/dictionary')
      try { const r = await getDictByCode('remind_type'); this.typeOptions = r.data || [] } catch (e) { this.typeOptions = [] }
      try { const r = await getDictByCode('remind_status'); this.statusOptions = r.data || [] } catch (e) { this.statusOptions = [] }
    },
    async loadList() {
      this.loading = true
      try {
        const p = {
          page: this.page, limit: this.limit,
          remind_type: this.filters.remind_type, status: this.filters.status,
          keyword: this.filters.keyword,
          start_date: this.dateRange && this.dateRange[0] || '',
          end_date: this.dateRange && this.dateRange[1] || '',
        }
        const r = await getRemindList(p)
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    async loadStats() {
      try {
        const r = await getRemindStatistics()
        if (r.code === 0) this.stats = r.data || {}
      } catch (e) {}
    },
    quickFilter(card) {
      if (card.key === 'overdue') { this.filters.status = 'overdue' }
      else if (card.key === 'repair_pending') { this.filters.remind_type = 'repair'; this.filters.status = '' }
      this.page = 1
      this.loadList()
    },
    resetFilters() {
      this.filters = { remind_type: '', status: '', keyword: '' }
      this.dateRange = []
      this.page = 1
      this.loadList()
    },
    async handleMark(row) {
      this.$confirm('确认将该提醒标记为已处理？', '处理确认', { type: 'warning' }).then(async () => {
        try {
          const r = await markRemindHandled(row.source_id, row.remind_type)
          if (r.code === 0) { this.$message.success('已标记处理'); this.loadList() }
        } catch (e) {}
      }).catch(() => {})
    },
    goJump(row) {
      if (row.remind_type === 'annual_inspection' || row.remind_type === 'insurance' || row.remind_type === 'special_inspection') {
        this.$router.push({ path: '/device/asset', query: { device_id: row.source_id } })
      } else {
        const map = { inspection: '/device/inspection/task', maintenance: '/device/maintenance/task', repair: '/device/repair/order' }
        this.$router.push(map[row.remind_type] || '/device/remind')
      }
    },
    viewDevice(row) {
      this.$router.push({ path: '/device/asset', query: { device_id: row.source_id } })
    },
    async openConfig() {
      this.configVisible = true
      try {
        const r = await getRemindConfig()
        if (r.code === 0) this.configForm = { ...this.configForm, ...r.data }
      } catch (e) {}
    },
    async saveConfig() {
      this.configSaving = true
      try {
        const r = await saveRemindConfig(this.configForm)
        if (r.code === 0) { this.$message.success('配置保存成功'); this.configVisible = false }
      } catch (e) {}
      this.configSaving = false
    },
    async openHistory() {
      this.historyVisible = true
      this.historyPage = 1
      this.historyRange = []
      this.loadHistory()
    },
    async loadHistory() {
      this.historyLoading = true
      try {
        const p = {
          page: this.historyPage, limit: 10,
          start_date: this.historyRange && this.historyRange[0] || '',
          end_date: this.historyRange && this.historyRange[1] || '',
        }
        const r = await getRemindHistory(p)
        if (r.code === 0) { this.historyList = r.data.list || []; this.historyTotal = r.data.total || 0 }
      } catch (e) {}
      this.historyLoading = false
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
