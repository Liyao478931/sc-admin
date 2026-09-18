<template>
  <div class="repair-record-page">
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
          <el-input v-model="filters.keyword" placeholder="请输入记录编号、工单编号或设备名称" clearable style="width:220px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.fault_type" clearable placeholder="全部故障类型" style="width:130px" @change="loadList">
            <el-option v-for="f in faultOptions" :key="f.value" :label="f.label" :value="f.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.handler_id" clearable filterable placeholder="全部维修人员" style="width:130px" @change="loadList">
            <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-select v-model="filters.status" clearable placeholder="全部状态" style="width:110px" @change="loadList">
            <el-option v-for="s in statusOptions" :key="s.value" :label="s.label" :value="s.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="完成开始" end-placeholder="完成结束"
            value-format="yyyy-MM-dd" style="width:240px" @change="loadList" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilters">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 工具栏 + 表格 -->
    <el-card shadow="never">
      <div slot="header" class="card-header">
        <div class="header-left"><span style="color:#909399">共 <b style="color:#409EFF">{{ total }}</b> 条记录</span></div>
        <div class="header-right">
          <el-button v-if="hasPerm('device:repair:record:export')" size="small" icon="el-icon-download" @click="handleExport">导出</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
          <el-button size="small" icon="el-icon-time" @click="openHistoryDialog">设备履历</el-button>
        </div>
      </div>

      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" align="center" />
        <el-table-column label="记录编号" width="180" show-overflow-tooltip>
          <template slot-scope="{row}">
            <el-link type="primary" @click="openDetail(row.id)">{{ row.record_code }}</el-link>
          </template>
        </el-table-column>
        <el-table-column prop="order_code" label="工单编号" width="180" show-overflow-tooltip />
        <el-table-column prop="device_name" label="设备名称" min-width="140" show-overflow-tooltip />
        <el-table-column prop="device_code" label="设备编码" width="120" show-overflow-tooltip />
        <el-table-column label="故障类型" width="100" align="center">
          <template slot-scope="{row}"><el-tag size="mini">{{ row.fault_type_text || faultLabel(row.fault_type) }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="handler_name" label="维修人员" width="80" />
        <el-table-column prop="repair_end_time" label="维修完成时间" width="160" show-overflow-tooltip />
        <el-table-column label="维修时长" width="100" align="center">
          <template slot-scope="{row}">{{ row.duration_text || row.repair_duration + ' 分钟' }}</template>
        </el-table-column>
        <el-table-column label="验收状态" width="100" align="center">
          <template slot-scope="{row}">
            <el-tag size="mini" :type="row.status === 'approved' ? 'success' : 'info'">{{ row.status_text }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="120" align="center">
          <template slot-scope="{row}">
            <el-button size="mini" type="text" @click="openDetail(row.id)">查看详情</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination style="margin-top:12px;text-align:right"
        background layout="total, sizes, prev, pager, next, jumper"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10,20,50,100]" @current-change="loadList" @size-change="loadList" />
    </el-card>

    <!-- 记录详情弹窗 -->
    <el-dialog title="维修记录详情" :visible.sync="detailVisible" width="950px" top="4vh" append-to-body>
      <el-tabs v-model="detailTab">
        <!-- 基本信息 -->
        <el-tab-pane label="基本信息" name="basic">
          <el-row :gutter="16" v-if="detail">
            <el-col :span="12"><el-descriptions title="工单信息" :column="1" border size="small">
              <el-descriptions-item label="记录编号">{{ detail.record_code }}</el-descriptions-item>
              <el-descriptions-item label="工单编号">{{ detail.order_code }}</el-descriptions-item>
              <el-descriptions-item label="验收状态">{{ detail.status_text }}</el-descriptions-item>
            </el-descriptions></el-col>
            <el-col :span="12"><el-descriptions title="设备信息" :column="1" border size="small">
              <el-descriptions-item label="设备名称">{{ detail.device_name }}</el-descriptions-item>
              <el-descriptions-item label="设备编码">{{ detail.device_code }}</el-descriptions-item>
              <el-descriptions-item label="故障类型">{{ detail.fault_type_text }}</el-descriptions-item>
            </el-descriptions></el-col>
          </el-row>
          <el-row :gutter="16" style="margin-top:12px" v-if="detail">
            <el-col :span="12"><el-descriptions title="报修信息" :column="1" border size="small">
              <el-descriptions-item label="报修人">{{ detail.reporter_name }}</el-descriptions-item>
              <el-descriptions-item label="报修时间">{{ detail.report_time }}</el-descriptions-item>
              <el-descriptions-item label="故障描述">{{ detail.fault_description }}</el-descriptions-item>
            </el-descriptions></el-col>
            <el-col :span="12"><el-descriptions title="维修信息" :column="1" border size="small">
              <el-descriptions-item label="维修人员">{{ detail.handler_name }}</el-descriptions-item>
              <el-descriptions-item label="维修开始">{{ detail.repair_start_time }}</el-descriptions-item>
              <el-descriptions-item label="维修结束">{{ detail.repair_end_time }}</el-descriptions-item>
              <el-descriptions-item label="维修时长">{{ detail.duration_text }}</el-descriptions-item>
            </el-descriptions></el-col>
          </el-row>
          <el-descriptions title="验收信息" :column="1" border size="small" style="margin-top:12px" v-if="detail">
            <el-descriptions-item label="验收人">{{ detail.acceptor_name }}</el-descriptions-item>
            <el-descriptions-item label="验收时间">{{ detail.accept_time }}</el-descriptions-item>
            <el-descriptions-item label="验收意见">{{ detail.accept_remark }}</el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>

        <!-- 故障诊断 -->
        <el-tab-pane label="故障诊断" name="diagnosis">
          <el-descriptions :column="1" border size="small" v-if="detail">
            <el-descriptions-item label="故障原因分析">{{ detail.diagnosis_cause || '—' }}</el-descriptions-item>
            <el-descriptions-item label="诊断结论">{{ detail.diagnosis_conclusion || '—' }}</el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>

        <!-- 维修方案 -->
        <el-tab-pane label="维修方案" name="plan">
          <div v-if="detail">
            <el-descriptions :column="1" border size="small">
              <el-descriptions-item label="维修方案">{{ detail.repair_plan || '—' }}</el-descriptions-item>
            </el-descriptions>
            <div style="font-weight:600;margin:12px 0 8px">备件使用清单</div>
            <el-table :data="materialList" border stripe size="small" v-if="materialList.length">
              <el-table-column type="index" label="序号" width="60" />
              <el-table-column prop="name" label="备件名称" />
              <el-table-column prop="spec" label="规格型号" />
              <el-table-column prop="count" label="数量" width="80" align="center" />
            </el-table>
            <el-empty v-else description="无备件使用记录" :image-size="60" />
          </div>
        </el-tab-pane>

        <!-- 维修过程 -->
        <el-tab-pane label="维修过程" name="process">
          <el-descriptions :column="1" border size="small" v-if="detail">
            <el-descriptions-item label="维修记录">{{ detail.repair_process || '—' }}</el-descriptions-item>
            <el-descriptions-item label="维修结果">{{ detail.repair_result || '—' }}</el-descriptions-item>
            <el-descriptions-item label="维修开始时间">{{ detail.repair_start_time || '—' }}</el-descriptions-item>
            <el-descriptions-item label="维修结束时间">{{ detail.repair_end_time || '—' }}</el-descriptions-item>
            <el-descriptions-item label="维修时长">{{ detail.duration_text }}</el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>

        <!-- 验收信息 -->
        <el-tab-pane label="验收信息" name="accept">
          <el-descriptions :column="1" border size="small" v-if="detail">
            <el-descriptions-item label="验收人">{{ detail.acceptor_name || '—' }}</el-descriptions-item>
            <el-descriptions-item label="验收时间">{{ detail.accept_time || '—' }}</el-descriptions-item>
            <el-descriptions-item label="验收意见">{{ detail.accept_remark || '—' }}</el-descriptions-item>
          </el-descriptions>
        </el-tab-pane>
      </el-tabs>
    </el-dialog>

    <!-- 设备维修履历弹窗 -->
    <el-dialog title="设备维修履历" :visible.sync="historyVisible" width="800px" top="6vh" append-to-body>
      <el-form :inline="true" size="small" style="margin-bottom:12px">
        <el-form-item label="选择设备">
          <el-select v-model="historyDeviceId" filterable clearable placeholder="请选择设备" style="width:260px" @change="loadHistory">
            <el-option v-for="d in deviceOptions" :key="d.device_id" :label="d.device_name + '（' + d.device_code + '）'" :value="d.device_id" />
          </el-select>
        </el-form-item>
      </el-form>
      <template v-if="historyDeviceId">
        <div style="margin-bottom:12px;font-size:13px;color:#909399">
          总维修次数：<b style="color:#409EFF">{{ historyStats.total_count }}</b>
          &nbsp;&nbsp;最近维修：{{ historyStats.last_repair_time || '—' }}
        </div>
        <el-table :data="historyList" v-loading="historyLoading" border stripe size="small">
          <el-table-column type="index" label="序号" width="60" />
          <el-table-column label="记录编号" width="180">
            <template slot-scope="{row}">
              <el-link type="primary" @click="openHistoryDetail(row.id)">{{ row.record_code }}</el-link>
            </template>
          </el-table-column>
          <el-table-column prop="repair_time" label="维修时间" width="160" />
          <el-table-column label="故障类型" width="100">
            <template slot-scope="{row}"><el-tag size="mini">{{ row.fault_type_text }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="handler_name" label="维修人员" width="80" />
          <el-table-column label="维修时长" width="100">
            <template slot-scope="{row}">{{ row.duration_text }}</template>
          </el-table-column>
        </el-table>
      </template>
      <el-empty v-else description="请选择设备查看维修履历" :image-size="80" />
    </el-dialog>
  </div>
</template>

<script>
import { getRecordList, getRecordDetail, getRecordStatistics, exportRecords, getRecordHistory, getRecordDevices, getRecordHandlers } from '@/api/repairRecord'

export default {
  name: 'RepairRecord',
  data() {
    return {
      loading: false,
      list: [],
      total: 0,
      page: 1,
      limit: 10,
      filters: { keyword: '', fault_type: '', handler_id: null, status: '' },
      dateRange: [],
      stats: { total_count: 0, month_count: 0, month_duration: 0, avg_duration: 0 },
      userOptions: [],
      faultOptions: [],
      statusOptions: [],
      // 详情弹窗
      detailVisible: false,
      detailTab: 'basic',
      detail: null,
      // 履历弹窗
      historyVisible: false,
      historyDeviceId: null,
      historyLoading: false,
      historyList: [],
      historyStats: { total_count: 0, last_repair_time: '' },
      deviceOptions: [],
    }
  },
  computed: {
    statCards() {
      return [
        { key: 'total', label: '总记录数', value: this.stats.total_count, icon: 'el-icon-document', color: '#409EFF' },
        { key: 'month', label: '本月新增', value: this.stats.month_count, icon: 'el-icon-date', color: '#67C23A' },
        { key: 'monthDur', label: '本月维修时长(小时)', value: this.stats.month_duration, icon: 'el-icon-time', color: '#E6A23C' },
        { key: 'avg', label: '平均维修时长(小时)', value: this.stats.avg_duration, icon: 'el-icon-data-line', color: '#9B59B6' },
      ]
    },
    materialList() {
      const m = this.detail && this.detail.materials
      if (!m) return []
      if (Array.isArray(m)) return m
      try { return JSON.parse(m) || [] } catch (e) { return [] }
    },
  },
  created() {
    this.loadList()
    this.loadStats()
    this.loadUsers()
    this.loadDicts()
  },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    // 故障类型/状态从字典动态加载
    async loadDicts() {
      const { getDictByCode } = await import('../../../api/dictionary')
      try { const r = await getDictByCode('repair_fault_type'); this.faultOptions = r.data || [] } catch (e) { this.faultOptions = [] }
      try { const r = await getDictByCode('repair_order_status'); this.statusOptions = (r.data || []).filter(s => ['approved', 'closed'].includes(s.value)) } catch (e) { this.statusOptions = [] }
    },
    faultLabel(v) {
      const f = this.faultOptions.find(x => x.value === v)
      return f ? f.label : v
    },
    async loadUsers() {
      // 从维修工单提取有维修记录的维修人员（handler）
      try {
        const r = await getRecordHandlers()
        if (r.code === 0) {
          this.userOptions = (r.data || []).map(h => ({ id: h.handler_id, real_name: h.handler_name }))
        }
      } catch (e) {}
    },
    async loadList() {
      this.loading = true
      try {
        const p = {
          page: this.page, limit: this.limit,
          keyword: this.filters.keyword, fault_type: this.filters.fault_type,
          handler_id: this.filters.handler_id, status: this.filters.status,
          start_date: this.dateRange && this.dateRange[0] || '',
          end_date: this.dateRange && this.dateRange[1] || '',
        }
        const r = await getRecordList(p)
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    async loadStats() {
      try {
        const r = await getRecordStatistics()
        if (r.code === 0) this.stats = r.data || {}
      } catch (e) {}
    },
    handleSearch() { this.page = 1; this.loadList() },
    resetFilters() {
      this.filters = { keyword: '', fault_type: '', handler_id: null, status: '' }
      this.dateRange = []
      this.page = 1
      this.loadList()
    },
    async openDetail(id) {
      this.detail = null
      this.detailTab = 'basic'
      this.detailVisible = true
      try {
        const r = await getRecordDetail(id)
        if (r.code === 0) this.detail = r.data
      } catch (e) {}
    },
    async handleExport() {
      const p = {
        keyword: this.filters.keyword, fault_type: this.filters.fault_type,
        handler_id: this.filters.handler_id, status: this.filters.status,
        start_date: this.dateRange && this.dateRange[0] || '',
        end_date: this.dateRange && this.dateRange[1] || '',
      }
      const r = await exportRecords(p)
      if (r.code === 0 && r.data.url) window.open(r.data.url, '_blank')
    },
    async openHistoryDialog() {
      this.historyVisible = true
      this.historyDeviceId = null
      this.historyList = []
      this.historyStats = { total_count: 0, last_repair_time: '' }
      try {
        const r = await getRecordDevices()
        if (r.code === 0) this.deviceOptions = r.data || []
      } catch (e) {}
    },
    async loadHistory() {
      if (!this.historyDeviceId) return
      this.historyLoading = true
      try {
        const r = await getRecordHistory({ device_id: this.historyDeviceId })
        if (r.code === 0) {
          this.historyList = r.data.list || []
          this.historyStats = r.data.stats || { total_count: 0, last_repair_time: '' }
        }
      } catch (e) {}
      this.historyLoading = false
    },
    async openHistoryDetail(id) {
      await this.openDetail(id)
      this.detailVisible = true
    },
  },
}
</script>

<style scoped>
.stat-card { cursor: default; }
.stat-card .stat-icon { width: 48px; height: 48px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 24px; float: left; margin-right: 12px; }
.stat-card .stat-info { overflow: hidden; }
.stat-card .stat-val { font-size: 22px; font-weight: 700; line-height: 1.2; }
.stat-card .stat-label { font-size: 12px; color: #909399; }
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
