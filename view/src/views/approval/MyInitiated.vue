<!--
  文件：admin/src/views/approval/MyInitiated.vue
  功能：我发起的（统一审批管理）— 统计卡片 / 搜索筛选 / 列表 / 撤销 / 审批详情
  权限：approval:task:view（页面）/ approval:task:revoke（撤销）
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>统一审批</el-breadcrumb-item>
      <el-breadcrumb-item>我发起的</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="6" v-for="card in statCards" :key="card.key">
        <div class="stat-card" :class="'stat-' + card.key" @click="handleCardFilter(card.key)">
          <div class="stat-icon"><i :class="card.icon"></i></div>
          <div class="stat-body">
            <div class="stat-num" :class="'num-' + card.key">{{ stats[card.key] || 0 }}</div>
            <div class="stat-label">{{ card.label }}</div>
          </div>
        </div>
      </el-col>
    </el-row>

    <!-- 搜索筛选 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="业务类型">
          <el-select v-model="query.biz_type" clearable placeholder="全部类型" style="width:140px">
            <el-option v-for="b in bizTypes" :key="b.code" :label="b.name" :value="b.code" />
          </el-select>
        </el-form-item>
        <el-form-item label="业务编号"><el-input v-model="query.business_no" placeholder="请输入业务编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="业务标题"><el-input v-model="query.business_title" placeholder="请输入业务标题" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="审批状态">
          <el-select v-model="query.status" clearable placeholder="全部状态" style="width:120px">
            <el-option v-for="(t, v) in statusOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="申请日期">
          <el-date-picker v-model="query.dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:230px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 操作按钮栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条申请</span>
    </div>

    <!-- 数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无发起的申请">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="业务类型" width="130" align="center">
        <template slot-scope="s"><el-tag :type="bizTag(s.row.biz_type)" size="mini">{{ s.row.business_name }}</el-tag></template>
      </el-table-column>
      <el-table-column label="业务编号" width="150">
        <template slot-scope="s"><span class="link-blue" @click="jumpBiz(s.row)">{{ s.row.business_no }}</span></template>
      </el-table-column>
      <el-table-column prop="business_title" label="业务标题" min-width="160" show-overflow-tooltip />
      <el-table-column label="当前节点" width="130">
        <template slot-scope="s">{{ s.row.status === 1 ? s.row.current_node_name : '已完成' }}</template>
      </el-table-column>
      <el-table-column label="审批状态" width="110" align="center">
        <template slot-scope="s"><el-tag :type="statusTag(s.row.status)" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="current_approver_name" label="当前审批人" width="100" />
      <el-table-column prop="submit_time" label="申请时间" width="160" align="center" />
      <el-table-column prop="finish_time" label="完成时间" width="160" align="center" />
      <el-table-column label="操作" width="160" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="openDetail(s.row.id)">查看详情</el-button>
          <el-button v-if="s.row.status === 1" v-permission="'approval:task:revoke'" type="text" size="mini" class="danger-text" @click="handleRevoke(s.row)">撤销申请</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 审批详情抽屉 -->
    <el-drawer title="审批详情" :visible.sync="detailVisible" size="750px" append-to-body>
      <div v-loading="detailLoading" class="drawer-body">
        <template v-if="detailData">
          <div class="section-title">审批信息</div>
          <el-descriptions :column="2" border size="small">
            <el-descriptions-item label="实例编号">{{ detailData.instance.instance_no }}</el-descriptions-item>
            <el-descriptions-item label="业务类型">{{ detailData.instance.business_name }}</el-descriptions-item>
            <el-descriptions-item label="业务编号">
              <span class="link-blue" @click="jumpBiz(detailData.instance)">{{ detailData.instance.business_no }}</span>
            </el-descriptions-item>
            <el-descriptions-item label="业务标题">{{ detailData.instance.business_title }}</el-descriptions-item>
            <el-descriptions-item label="申请人">{{ detailData.instance.applicant_name }}</el-descriptions-item>
            <el-descriptions-item label="申请时间">{{ detailData.instance.submit_time }}</el-descriptions-item>
            <el-descriptions-item label="审批状态">{{ detailData.instance.status_label }}</el-descriptions-item>
            <el-descriptions-item label="当前节点">{{ detailData.instance.current_node_name }}</el-descriptions-item>
            <el-descriptions-item label="审批模式">{{ detailData.instance.approval_mode_label }}</el-descriptions-item>
            <el-descriptions-item label="紧急程度">{{ detailData.instance.urgent_label }}</el-descriptions-item>
          </el-descriptions>

          <div class="section-title">业务摘要</div>
          <el-descriptions :column="2" border size="small">
            <el-descriptions-item v-for="(it, i) in detailData.bizSummary" :key="i" :label="it.label">{{ it.value }}</el-descriptions-item>
          </el-descriptions>

          <div class="section-title">审批时间轴</div>
          <el-timeline>
            <el-timeline-item v-for="h in detailData.histories" :key="h.id" :timestamp="h.created_at" placement="top">
              <div class="tl-card">
                <div class="tl-head">
                  <el-tag :type="historyTag(h)" size="mini">{{ h.action_label }}</el-tag>
                  <span class="tl-operator">{{ h.operator_name }}</span>
                  <span class="tl-result">{{ historyResult(h) }}</span>
                </div>
                <div v-if="h.comment" class="tl-comment">{{ h.comment }}</div>
              </div>
            </el-timeline-item>
          </el-timeline>
        </template>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import { getMyInitiated, getApprovalDetail, revokeApproval } from '@/api/approval'

const BIZ_TAG = {
  purchase_request: 'primary',
  report: 'warning',
  leave: 'success',
  hazard: 'danger',
  purchase_order: '',
  contract: 'info'
}
const STATUS_TAG = { 1: 'warning', 2: 'success', 3: 'danger', 4: 'info' }

export default {
  name: 'ApprovalMyInitiated',
  data () {
    return {
      statCards: [
        { key: 'pending', label: '审批中', icon: 'el-icon-loading' },
        { key: 'approved', label: '已通过', icon: 'el-icon-check' },
        { key: 'rejected', label: '已驳回', icon: 'el-icon-close' },
        { key: 'revoked', label: '已撤销', icon: 'el-icon-remove' }
      ],
      stats: { pending: 0, approved: 0, rejected: 0, revoked: 0 },
      statusOptions: { 1: '审批中', 2: '已通过', 3: '已驳回', 4: '已撤销' },
      query: { biz_type: '', business_no: '', business_title: '', status: '', dateRange: [] },
      cardStatus: '',
      bizTypes: [],
      list: [], total: 0, page: 1, pageSize: 10, loading: false,
      detailVisible: false, detailLoading: false, detailData: null
    }
  },
  created () { this.loadData() },
  methods: {
    bizTag (t) { return BIZ_TAG[t] || 'info' },
    statusTag (s) { return STATUS_TAG[Number(s)] || 'info' },
    historyTag (h) {
      if (h.result === 'pass') return 'success'
      if (h.result === 'reject') return 'danger'
      return 'info'
    },
    historyResult (h) {
      const map = { pass: '通过', reject: '驳回', transfer: '转办', urge: '催办', revoke: '撤销' }
      return map[h.result] || h.result || ''
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.biz_type) p.biz_type = this.query.biz_type
      if (this.query.business_no) p.business_no = this.query.business_no
      if (this.query.business_title) p.business_title = this.query.business_title
      if (this.query.status !== '' && this.query.status !== null) p.status = this.query.status
      if (this.query.dateRange && this.query.dateRange.length === 2) {
        p.start_date = this.query.dateRange[0]
        p.end_date = this.query.dateRange[1]
      }
      if (this.cardStatus) p.status = this.cardStatus
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getMyInitiated(this.buildParams())
        if (r.code === 0 && r.data) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.stats = r.data.stats || { pending: 0, approved: 0, rejected: 0, revoked: 0 }
          if (r.data.bizTypes) this.bizTypes = r.data.bizTypes
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.cardStatus = ''; this.page = 1; this.loadData() },
    handleReset () {
      this.query = { biz_type: '', business_no: '', business_title: '', status: '', dateRange: [] }
      this.cardStatus = ''
      this.page = 1
      this.loadData()
    },
    handleCardFilter (key) {
      const map = { pending: '1', approved: '2', rejected: '3', revoked: '4' }
      this.cardStatus = this.cardStatus === map[key] ? '' : map[key]
      this.page = 1
      this.loadData()
    },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    jumpBiz (row) {
      if (Number(row.biz_id) > 0) {
        this.$message.info('业务单据详情跳转地址按实际模块路由配置')
      } else {
        this.$message.info('示例数据暂未关联业务单据')
      }
    },
    openDetail (id) {
      this.detailVisible = true
      this.detailLoading = true
      this.detailData = null
      getApprovalDetail(id).then(r => {
        if (r.code === 0) this.detailData = r.data
      }).catch(() => {}).finally(() => { this.detailLoading = false })
    },
    handleRevoke (row) {
      this.$confirm('确认撤销该审批申请吗？撤销后将不可恢复，请谨慎操作', '撤销申请', { type: 'warning' }).then(async () => {
        try {
          const r = await revokeApproval(row.id, { reason: '' })
          if (r.code === 0) { this.$message.success('撤销成功'); this.loadData() } else this.$message.error(r.msg || '撤销失败')
        } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.stat-row { margin-bottom: 14px; }
.stat-card {
  display: flex; align-items: center; border-radius: 10px; padding: 18px 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06); cursor: pointer; transition: all 0.25s ease;
}
.stat-card:hover { transform: translateY(-3px); box-shadow: 0 6px 16px rgba(0, 0, 0, 0.12); }
.stat-pending { background: linear-gradient(135deg, #fff7e6, #ffe7ba); }
.stat-approved { background: linear-gradient(135deg, #f0f9eb, #e1f3d8); }
.stat-rejected { background: linear-gradient(135deg, #fef0f0, #fde2e2); }
.stat-revoked { background: linear-gradient(135deg, #f4f4f5, #e9e9eb); }
.stat-icon { font-size: 34px; color: #909399; margin-right: 14px; }
.stat-pending .stat-icon { color: #E6A23C; }
.stat-approved .stat-icon { color: #67C23A; }
.stat-rejected .stat-icon { color: #F56C6C; }
.stat-revoked .stat-icon { color: #909399; }
.stat-num { font-size: 26px; font-weight: 700; line-height: 1.1; }
.num-pending { color: #E6A23C; }
.num-approved { color: #67C23A; }
.num-rejected { color: #F56C6C; }
.num-revoked { color: #909399; }
.stat-label { font-size: 13px; color: #909399; margin-top: 4px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.link-blue { color: #409EFF; cursor: pointer; }
.danger-text { color: #F56C6C; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.drawer-body { padding: 8px 20px 30px; }
.section-title { font-size: 15px; font-weight: 600; margin: 20px 0 12px; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; }
.tl-card { border: 1px solid #ebeef5; border-radius: 6px; padding: 8px 12px; background: #fff; }
.tl-head { display: flex; align-items: center; gap: 10px; }
.tl-operator { font-weight: 600; color: #303133; }
.tl-result { color: #606266; }
.tl-comment { margin-top: 6px; color: #606266; font-size: 13px; }
</style>
