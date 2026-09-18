<!--
  文件：admin/src/views/business/purchase/order/Track.vue
  功能：采购订单跟踪（搜索/统计卡片/物流状态/入库进度/逾期预警/物流轨迹/催货/导出）
  权限：business:purchase:order:track:view / export / remind
-->
<template>
  <div class="track-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购订单跟踪</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索区 -->
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="订单编号">
          <el-input v-model="q.order_no" placeholder="请输入订单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="供应商">
          <el-input v-model="q.supplier" placeholder="请输入供应商名称" clearable style="width:150px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="来源申请">
          <el-input v-model="q.request_no" placeholder="请输入来源申请编号" clearable style="width:140px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="物流状态">
          <el-select v-model="q.logistics_status" placeholder="全部" clearable style="width:110px" @change="handleSearch">
            <el-option label="全部" value="" />
            <el-option label="未发货" value="0" /><el-option label="已揽收" value="1" /><el-option label="运输中" value="2" />
            <el-option label="派送中" value="3" /><el-option label="已签收" value="4" /><el-option label="异常" value="5" />
          </el-select>
        </el-form-item>
        <el-form-item label="逾期状态">
          <el-select v-model="q.overdue_status" placeholder="全部" clearable style="width:150px" @change="handleSearch">
            <el-option label="全部" value="" /><el-option label="正常" value="0" /><el-option label="即将逾期（3天内）" value="1" /><el-option label="已逾期" value="2" />
          </el-select>
        </el-form-item>
        <el-form-item label="下单日期">
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始" end-placeholder="结束" value-format="yyyy-MM-dd" style="width:240px" @change="handleSearch" />
        </el-form-item>
        <div class="filter-btns">
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </div>
      </el-form>
    </el-card>

    <!-- 统计卡片 -->
    <el-row :gutter="12" class="stats-row">
      <el-col :span="6">
        <el-card shadow="never" class="stat-card" :class="{ active: cardKey === 'total' }" @click.native="applyStat('total')">
          <div class="stat-num">{{ stats.total }}</div>
          <div class="stat-label">全部订单</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="never" class="stat-card blue" :class="{ active: cardKey === 'pending' }" @click.native="applyStat('pending')">
          <div class="stat-num">{{ stats.pending }}</div>
          <div class="stat-label">待发货</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="never" class="stat-card orange" :class="{ active: cardKey === 'transporting' }" @click.native="applyStat('transporting')">
          <div class="stat-num">{{ stats.transporting }}</div>
          <div class="stat-label">运输中</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="never" class="stat-card red" :class="{ active: cardKey === 'overdue' }" @click.native="applyStat('overdue')">
          <div class="stat-num">{{ stats.overdue }}</div>
          <div class="stat-label">已逾期</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 工具栏 + 表格 -->
    <el-card shadow="never">
      <div class="toolbar">
        <el-button v-permission="'business:purchase:order:track:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出跟踪报表</el-button>
        <el-button size="small" icon="el-icon-refresh" @click="getList">刷新</el-button>
        <span class="flex-1"></span>
        <span class="total-tip">共 {{ total }} 条</span>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe border empty-text="暂无采购订单跟踪数据">
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column label="订单编号" width="150">
          <template slot-scope="{ row }"><span class="link" @click="goDetail(row.id)">{{ row.order_no }}</span></template>
        </el-table-column>
        <el-table-column prop="supplier_name" label="供应商" width="130" show-overflow-tooltip />
        <el-table-column label="来源申请" width="140">
          <template slot-scope="{ row }">
            <span v-if="row.request_id" class="link" @click="goRequest(row.request_id)">{{ row.request_no }}</span>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column label="订单金额" width="120" align="right">
          <template slot-scope="{ row }">￥{{ Number(row.total_amount || 0).toFixed(2) }}</template>
        </el-table-column>
        <el-table-column prop="order_date" label="下单日期" width="110" />
        <el-table-column label="期望交货日期" width="130">
          <template slot-scope="{ row }">
            <span v-if="row.overdue_status === 2" class="overdue-red">已逾期{{ row.overdue_days }}天</span>
            <span v-else-if="row.overdue_status === 1" class="overdue-orange">即将逾期</span>
            <span v-else>{{ row.expected_date || '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="物流信息" min-width="180">
          <template slot-scope="{ row }">
            <div v-if="row.has_logistics">
              <el-tag size="mini" :type="logisticsTagType(row.logistics_status)">{{ row.logistics_status_label }}</el-tag>
              <div class="lg-sub">{{ row.express_name || '' }} {{ row.track_no }}</div>
              <div v-if="row.logistics_status === 4" class="lg-signed">已签收{{ row.signed_date ? ' ' + row.signed_date : '' }}</div>
            </div>
            <span v-else class="lg-empty">暂无物流信息</span>
          </template>
        </el-table-column>
        <el-table-column label="入库进度" width="170">
          <template slot-scope="{ row }">
            <el-progress :percentage="row.receive_progress" :color="progressColor(row.receive_progress)" :stroke-width="10" style="width:100px;display:inline-block;vertical-align:middle;" />
            <span class="progress-text">{{ row.receive_text }}</span>
          </template>
        </el-table-column>
        <el-table-column label="付款状态" width="95" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="paymentTagType(row.payment_status)">{{ row.payment_status_label }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="230" align="center" fixed="right">
          <template slot-scope="{ row }">
            <el-button type="text" size="mini" @click="goDetail(row.id)">查看详情</el-button>
            <el-button v-if="row.can_remind" v-permission="'business:purchase:order:track:remind'" type="text" size="mini" @click="openRemind(row)">催货</el-button>
            <el-button v-if="row.has_logistics" type="text" size="mini" @click="openLogistics(row)">物流追踪</el-button>
            <el-dropdown trigger="click" style="margin-left:6px;" @command="cmd => handleMore(cmd, row)">
              <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right" /></el-button>
              <el-dropdown-menu slot="dropdown">
                <el-dropdown-item v-if="row.request_id" command="request">查看来源申请</el-dropdown-item>
                <el-dropdown-item v-if="row.contract_id" command="contract">查看关联合同</el-dropdown-item>
                <el-dropdown-item v-if="!row.request_id && !row.contract_id" disabled>暂无更多操作</el-dropdown-item>
              </el-dropdown-menu>
            </el-dropdown>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, prev, pager, next" :total="total" :current-page="page" :page-size="limit"
        @current-change="p => { page = p; getList() }" />
    </el-card>

    <!-- 物流轨迹弹窗 -->
    <el-dialog title="物流轨迹" :visible="lgVisible" @update:visible="v => lgVisible = v" width="620px" top="6vh" @open="loadLogistics">
      <div v-if="lgData" class="lg-head">
        <div>订单：{{ lgData.order_no }}　快递：{{ lgData.express_name || '-' }}　单号：{{ lgData.track_no || '-' }}</div>
        <el-tag size="small" :type="logisticsTagType(lgData.logistics_status)">{{ lgData.logistics_status_label }}</el-tag>
      </div>
      <div v-if="lgLoading" v-loading="true" class="lg-loading" />
      <template v-else>
        <el-timeline v-if="lgTraces.length" class="lg-timeline">
          <el-timeline-item v-for="(t, i) in lgTraces" :key="i" :timestamp="t.time" :color="traceColor(t.status)">
            <div class="trace-context">{{ t.context }}</div>
            <div v-if="t.location" class="trace-location">{{ t.location }}</div>
          </el-timeline-item>
        </el-timeline>
        <el-empty v-else description="暂无物流轨迹" :image-size="60" />
      </template>
      <div v-if="lgError" class="lg-error">
        {{ lgError }}
        <el-button size="mini" type="text" @click="openManual">手动输入物流信息</el-button>
      </div>
      <span slot="footer">
        <el-button size="small" icon="el-icon-refresh" :loading="lgRefreshing" @click="doRefresh">刷新物流</el-button>
        <el-button size="small" @click="lgVisible = false">关闭</el-button>
      </span>
    </el-dialog>

    <!-- 手动输入物流信息弹窗 -->
    <el-dialog title="手动输入物流信息" :visible="manualVisible" @update:visible="v => manualVisible = v" width="460px" top="8vh">
      <el-form label-width="90px" size="small">
        <el-form-item label="快递单号"><el-input v-model="manualForm.tracking_no" placeholder="必填" maxlength="60" /></el-form-item>
        <el-form-item label="快递公司">
          <el-select v-model="manualForm.express_code" placeholder="选择快递公司（可选）" clearable filterable style="width:100%">
            <el-option v-for="(v, k) in EXPRESS_OPTIONS" :key="k" :label="v" :value="k" />
          </el-select>
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="manualVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="lgRefreshing" @click="submitManual">保存并查询</el-button>
      </span>
    </el-dialog>

    <!-- 催货对话框 -->
    <el-dialog title="发送催货" :visible="remindVisible" @update:visible="v => remindVisible = v" width="520px" top="8vh">
      <el-form :model="remindForm" label-width="90px" size="small">
        <el-form-item label="催货方式">
          <el-select v-model="remindForm.remind_type" style="width:200px">
            <el-option label="电话催货" :value="1" /><el-option label="邮件催货" :value="2" /><el-option label="系统自动提醒" :value="3" />
          </el-select>
        </el-form-item>
        <el-form-item label="联系人"><el-input v-model="remindForm.contact" placeholder="供应商联系人（选填）" maxlength="50" /></el-form-item>
        <el-form-item label="联系方式"><el-input v-model="remindForm.contact_way" placeholder="电话/邮箱（选填）" maxlength="100" /></el-form-item>
        <el-form-item label="催货内容">
          <el-input v-model="remindForm.content" type="textarea" :rows="3" maxlength="500" placeholder="催货通知内容" @keydown.ctrl.enter.native="submitRemind" />
        </el-form-item>
      </el-form>
      <div class="shortcut-tip">提示：按 Ctrl+Enter 快速提交</div>
      <span slot="footer">
        <el-button size="small" @click="remindVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="remindSaving" @click="submitRemind">确认发送</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import {
  getOrderTrackList, getOrderLogistics, refreshLogistics, sendReminder, exportTrackReport
} from '@/api/purchase'

const EXPRESS_OPTIONS = {
  shunfeng: '顺丰速运', zhongtong: '中通快递', yuantong: '圆通速递', yunda: '韵达快递',
  jtexpress: '极兔速递', ems: 'EMS', jingdong: '京东物流'
}

export default {
  name: 'PurchaseOrderTrack',
  data () {
    return {
      EXPRESS_OPTIONS,
      q: { order_no: '', supplier: '', request_no: '', logistics_status: '', overdue_status: '' },
      dateRange: null,
      cardKey: 'total',
      stats: { total: 0, pending: 0, transporting: 0, overdue: 0 },
      list: [], total: 0, page: 1, limit: 10, loading: false,
      exporting: false,
      lgVisible: false, lgLoading: false, lgRefreshing: false, lgData: null, lgTraces: [], lgError: '',
      currentOrder: null,
      manualVisible: false, manualForm: { tracking_no: '', express_code: '' },
      remindVisible: false, remindSaving: false, remindForm: { remind_type: 1, contact: '', contact_way: '', content: '' }
    }
  },
  created () {
    this.getList()
    // 从列表页"跟踪"跳转时定位订单（?id=）
    const qid = this.$route.query && this.$route.query.id
    if (qid) {
      this.locateOrder = Number(qid)
    }
  },
  methods: {
    async getList () {
      this.loading = true
      try {
        const params = { page: this.page, pageSize: this.limit, ...this.q }
        if (this.dateRange && this.dateRange.length === 2) { params.start_date = this.dateRange[0]; params.end_date = this.dateRange[1] }
        const r = await getOrderTrackList(params)
        if (r.code === 0) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.stats = r.data.stats || this.stats
          if (this.locateOrder) {
            this.$nextTick(() => {
              const row = this.list.find(x => x.id === this.locateOrder)
              if (row) this.$message.info(`已定位订单：${row.order_no}`)
            })
          }
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () {
      this.q = { order_no: '', supplier: '', request_no: '', logistics_status: '', overdue_status: '' }
      this.dateRange = null
      this.cardKey = 'total'
      this.page = 1
      this.getList()
    },
    applyStat (key) {
      if (this.cardKey === key) { this.cardKey = 'total'; this.q.logistics_status = ''; this.q.overdue_status = '' }
      else {
        this.cardKey = key
        this.q.logistics_status = ''
        this.q.overdue_status = ''
        if (key === 'pending') this.q.logistics_status = '0'
        if (key === 'transporting') this.q.logistics_status = '1,2,3'
        if (key === 'overdue') this.q.overdue_status = '2'
      }
      this.page = 1
      this.getList()
    },
    goDetail (id) { this.$router.push(`/business/purchase/order/detail/${id}`) },
    goRequest (id) { this.$router.push(`/business/purchase/request/detail/${id}`) },
    handleMore (cmd, row) {
      if (cmd === 'request') this.goRequest(row.request_id)
      if (cmd === 'contract') this.$router.push({ path: '/business/contract', query: { detail: row.contract_id } })
    },
    logisticsTagType (s) {
      return { 0: 'info', 1: 'primary', 2: 'warning', 3: 'primary', 4: 'success', 5: 'danger' }[s] || 'info'
    },
    paymentTagType (s) {
      return { 0: 'info', 1: 'warning', 2: 'success' }[s] || 'info'
    },
    progressColor (p) {
      if (p >= 100) return '#67C23A'
      if (p >= 50) return '#409EFF'
      if (p >= 1) return '#E6A23C'
      return '#C0C4CC'
    },
    // ===== 物流追踪 =====
    async openLogistics (row) {
      this.currentOrder = row
      this.lgData = { order_no: row.order_no, express_name: row.express_name, track_no: row.track_no, logistics_status: row.logistics_status, logistics_status_label: row.logistics_status_label }
      this.lgTraces = []
      this.lgError = ''
      this.lgVisible = true
      this.lgLoading = true
      try {
        const r = await getOrderLogistics(row.id)
        if (r.code === 0) {
          const d = r.data
          this.lgData = { ...this.lgData, express_name: d.express_name, track_no: d.track_no, logistics_status: d.logistics_status, logistics_status_label: d.logistics_status_label }
          this.lgTraces = d.traces || []
        } else {
          this.lgError = r.msg || '物流信息获取失败，请稍后重试'
        }
      } catch (e) { this.lgError = '物流信息获取失败，请稍后重试' } finally { this.lgLoading = false }
    },
    async loadLogistics () {
      if (!this.currentOrder) return
      this.lgLoading = true
      try {
        const r = await getOrderLogistics(this.currentOrder.id)
        if (r.code === 0) {
          const d = r.data
          this.lgData = { ...this.lgData, express_name: d.express_name, track_no: d.track_no, logistics_status: d.logistics_status, logistics_status_label: d.logistics_status_label }
          this.lgTraces = d.traces || []
          this.lgError = ''
        }
      } catch (e) {} finally { this.lgLoading = false }
    },
    async doRefresh () {
      if (!this.currentOrder) return
      this.lgRefreshing = true
      try {
        const r = await refreshLogistics(this.currentOrder.id)
        if (r.code === 0) {
          this.$message.success(r.msg || '物流信息已更新')
          this.lgData = { ...this.lgData, express_name: r.data.express_name, track_no: r.data.tracking_no, logistics_status: r.data.logistics_status, logistics_status_label: r.data.logistics_status_label }
          this.lgTraces = r.data.traces || []
          this.lgError = ''
          this.getList()
        } else {
          this.lgError = r.msg || '物流信息获取失败，请稍后重试'
        }
      } catch (e) { this.lgError = '物流信息获取失败，请稍后重试' } finally { this.lgRefreshing = false }
    },
    openManual () { this.manualForm = { tracking_no: this.currentOrder.track_no || '', express_code: '' }; this.manualVisible = true },
    async submitManual () {
      if (!this.manualForm.tracking_no) { this.$message.warning('请填写快递单号'); return }
      if (!this.currentOrder) return
      this.lgRefreshing = true
      try {
        const r = await refreshLogistics(this.currentOrder.id, { tracking_no: this.manualForm.tracking_no, express_code: this.manualForm.express_code })
        if (r.code === 0) {
          this.$message.success(r.msg || '物流信息已更新')
          this.manualVisible = false
          this.lgData = { ...this.lgData, express_name: r.data.express_name, track_no: r.data.tracking_no, logistics_status: r.data.logistics_status, logistics_status_label: r.data.logistics_status_label }
          this.lgTraces = r.data.traces || []
          this.lgError = ''
          this.getList()
        } else {
          this.$message.error(r.msg || '获取失败')
        }
      } catch (e) {} finally { this.lgRefreshing = false }
    },
    traceColor (status) {
      if (status === 'delivered') return '#67C23A'
      if (status === 'exception') return '#F56C6C'
      return '#409EFF'
    },
    // ===== 催货 =====
    openRemind (row) {
      this.currentOrder = row
      this.remindForm = {
        remind_type: 1, contact: '', contact_way: '',
        content: `关于订单 ${row.order_no} 的催货通知，请尽快安排发货`
      }
      this.remindVisible = true
    },
    async submitRemind () {
      if (!this.currentOrder) return
      if (!this.remindForm.content) { this.$message.warning('催货内容必填'); return }
      this.remindSaving = true
      try {
        const r = await sendReminder(this.currentOrder.id, this.remindForm)
        if (r.code === 0) { this.$message.success(r.msg || '催货已发送'); this.remindVisible = false; this.getList() }
        else this.$message.error(r.msg || '发送失败')
      } catch (e) {} finally { this.remindSaving = false }
    },
    // ===== 导出 =====
    async handleExport () {
      this.exporting = true
      try {
        const params = { ...this.q }
        if (this.dateRange && this.dateRange.length === 2) { params.start_date = this.dateRange[0]; params.end_date = this.dateRange[1] }
        const blob = await exportTrackReport(params)
        const url = window.URL.createObjectURL(new Blob([blob]))
        const a = document.createElement('a')
        a.href = url
        a.download = `采购订单跟踪_${new Date().toISOString().slice(0, 10)}.xlsx`
        a.click()
        window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') } finally { this.exporting = false }
    }
  }
}
</script>

<style scoped>
.track-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.breadcrumb { margin-bottom: 12px; }
.filter-card { margin-bottom: 12px; }
.filter-btns { display: inline-block; margin-left: 4px; }
.stats-row { margin-bottom: 12px; }
.stat-card { text-align: center; cursor: pointer; transition: all .2s; }
.stat-card.active { border-color: #409EFF; box-shadow: 0 0 0 1px #409EFF inset; }
.stat-card.blue .stat-num { color: #409EFF; }
.stat-card.orange .stat-num { color: #E6A23C; }
.stat-card.red .stat-num { color: #F56C6C; }
.stat-num { font-size: 26px; font-weight: 700; color: #303133; }
.stat-label { font-size: 13px; color: #909399; margin-top: 4px; }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.total-tip { font-size: 14px; color: #909399; }
.link { color: #409EFF; cursor: pointer; }
.overdue-red { color: #F56C6C; font-weight: 600; }
.overdue-orange { color: #E6A23C; font-weight: 600; }
.lg-sub { font-size: 12px; color: #909399; margin-top: 2px; }
.lg-signed { font-size: 12px; color: #67C23A; }
.lg-empty { color: #C0C4CC; font-size: 12px; }
.progress-text { font-size: 12px; color: #606266; margin-left: 4px; }
.pager { margin-top: 12px; text-align: right; }
.lg-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 14px; font-size: 13px; color: #303133; }
.lg-timeline { max-height: 420px; overflow-y: auto; padding-left: 4px; }
.lg-loading { min-height: 120px; }
.trace-context { font-size: 13px; color: #303133; }
.trace-location { font-size: 12px; color: #909399; margin-top: 2px; }
.lg-error { color: #F56C6C; font-size: 13px; margin-top: 10px; }
.shortcut-tip { font-size: 12px; color: #909399; text-align: right; margin-top: 6px; }
</style>
