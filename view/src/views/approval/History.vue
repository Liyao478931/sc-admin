<!--
  文件：admin/src/views/approval/History.vue
  功能：审批历史（统一审批管理）— 统计卡片 / 搜索筛选 / 列表 / 导出 / 审批详情
  权限：approval:task:view（页面）/ approval:task:export（导出）
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>统一审批</el-breadcrumb-item>
      <el-breadcrumb-item>审批历史</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="6" v-for="card in statCards" :key="card.key">
        <div class="stat-card" :class="'stat-' + card.key">
          <div class="stat-icon"><i :class="card.icon"></i></div>
          <div class="stat-body">
            <div class="stat-num" :class="'num-' + card.key">{{ card.key === 'avg' ? formatAvg(stats.avg_duration) : (stats[card.key] || 0) }}</div>
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
        <el-form-item label="审批结果">
          <el-select v-model="query.result" clearable placeholder="全部结果" style="width:120px">
            <el-option v-for="(t, v) in resultOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="角色">
          <el-select v-model="query.role" clearable placeholder="全部角色" style="width:120px">
            <el-option v-for="(t, v) in roleOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="处理时间">
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
        <el-button v-permission="'approval:task:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条记录</span>
    </div>

    <!-- 数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无审批历史记录">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="业务类型" width="130" align="center">
        <template slot-scope="s"><el-tag :type="bizTag(s.row.biz_type)" size="mini">{{ s.row.business_name }}</el-tag></template>
      </el-table-column>
      <el-table-column label="业务编号" width="150">
        <template slot-scope="s"><span class="link-blue" @click="jumpBiz(s.row)">{{ s.row.business_no }}</span></template>
      </el-table-column>
      <el-table-column prop="business_title" label="业务标题" min-width="160" show-overflow-tooltip />
      <el-table-column prop="applicant_name" label="申请人" width="90" />
      <el-table-column label="我的角色" width="110" align="center">
        <template slot-scope="s"><el-tag :type="s.row.my_role === 1 ? 'primary' : 'success'" size="mini">{{ s.row.my_role_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="审批结果" width="110" align="center">
        <template slot-scope="s"><el-tag :type="s.row.result_tag" size="mini">{{ s.row.result_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="my_opinion" label="审批意见" width="150" show-overflow-tooltip />
      <el-table-column prop="handle_time" label="处理时间" width="160" align="center" />
      <el-table-column label="操作" width="120" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="openDetail(s.row.id)">查看详情</el-button>
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
            <el-descriptions-item label="审批模式">{{ detailData.instance.approval_mode_label }}</el-descriptions-item>
            <el-descriptions-item label="当前节点">{{ detailData.instance.current_node_name }}</el-descriptions-item>
            <el-descriptions-item label="完成时间">{{ detailData.instance.finish_time || '-' }}</el-descriptions-item>
          </el-descriptions>

          <div class="section-title">业务摘要</div>
          <el-descriptions :column="2" border size="small">
            <el-descriptions-item v-for="(it, i) in detailData.bizSummary" :key="i" :label="it.label">{{ it.value }}</el-descriptions-item>
          </el-descriptions>

          <div class="section-title">审批时间轴</div>
          <el-timeline>
            <el-timeline-item v-for="h in detailData.histories" :key="h.id" :timestamp="h.created_at" placement="top">
              <div class="tl-card" :class="{ 'tl-mine': h.operator_id === myUid }">
                <div class="tl-head">
                  <el-tag :type="historyTag(h)" size="mini">{{ h.action_label }}</el-tag>
                  <span class="tl-operator">{{ h.operator_name }}</span>
                  <span class="tl-result">{{ historyResult(h) }}</span>
                  <span v-if="h.operator_id === myUid" class="tl-mine-tag">我的操作</span>
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
import { getApprovalHistory, getApprovalDetail, exportApprovalHistory } from '@/api/approval'
import { getToken } from '@/utils/auth'

const BIZ_TAG = {
  purchase_request: 'primary',
  report: 'warning',
  leave: 'success',
  hazard: 'danger',
  purchase_order: '',
  contract: 'info'
}

export default {
  name: 'ApprovalHistory',
  data () {
    return {
      statCards: [
        { key: 'total_count', label: '本月审批数', icon: 'el-icon-document' },
        { key: 'approved_count', label: '本月通过数', icon: 'el-icon-check' },
        { key: 'rejected_count', label: '本月驳回数', icon: 'el-icon-close' },
        { key: 'avg', label: '平均处理时长', icon: 'el-icon-time' }
      ],
      stats: { total_count: 0, approved_count: 0, rejected_count: 0, avg_duration: null },
      resultOptions: { 2: '已通过', 3: '已驳回', 4: '已撤销' },
      roleOptions: { 1: '我审批的', 2: '我申请的' },
      query: { biz_type: '', business_no: '', business_title: '', result: '', role: '', dateRange: [] },
      bizTypes: [],
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false,
      detailVisible: false, detailLoading: false, detailData: null,
      myUid: null
    }
  },
  created () {
    this.myUid = this.resolveUid()
    this.loadData()
  },
  methods: {
    resolveUid () {
      try {
        const u = JSON.parse(localStorage.getItem('userInfo') || 'null')
        return u ? u.id : null
      } catch (e) { return null }
    },
    bizTag (t) { return BIZ_TAG[t] || 'info' },
    historyTag (h) {
      if (h.result === 'pass') return 'success'
      if (h.result === 'reject') return 'danger'
      return 'info'
    },
    historyResult (h) {
      const map = { pass: '通过', reject: '驳回', transfer: '转办', urge: '催办', revoke: '撤销' }
      return map[h.result] || h.result || ''
    },
    formatAvg (v) {
      return (v === null || v === undefined || v === '') ? '-' : (v + ' 小时')
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.biz_type) p.biz_type = this.query.biz_type
      if (this.query.business_no) p.business_no = this.query.business_no
      if (this.query.business_title) p.business_title = this.query.business_title
      if (this.query.result !== '' && this.query.result !== null) p.result = this.query.result
      if (this.query.role !== '' && this.query.role !== null) p.role = this.query.role
      if (this.query.dateRange && this.query.dateRange.length === 2) {
        p.start_date = this.query.dateRange[0]
        p.end_date = this.query.dateRange[1]
      }
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getApprovalHistory(this.buildParams())
        if (r.code === 0 && r.data) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.stats = r.data.stats || { total_count: 0, approved_count: 0, rejected_count: 0, avg_duration: null }
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () {
      this.query = { biz_type: '', business_no: '', business_title: '', result: '', role: '', dateRange: [] }
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
    async handleExport () {
      this.exporting = true
      try {
        const response = await exportApprovalHistory(this.buildParams())
        const blob = response.data
        const url = URL.createObjectURL(new Blob([blob]))
        const link = document.createElement('a')
        const now = new Date()
        const pad = n => String(n).padStart(2, '0')
        const ts = `${now.getFullYear()}${pad(now.getMonth() + 1)}${pad(now.getDate())}_${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`
        link.href = url
        link.download = `审批历史_${ts}.xlsx`
        document.body.appendChild(link)
        link.click()
        document.body.removeChild(link)
        URL.revokeObjectURL(url)
        this.$message.success('导出成功')
      } catch (e) {} finally { this.exporting = false }
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
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}
.stat-total_count { background: linear-gradient(135deg, #ecf5ff, #d9ecff); }
.stat-approved_count { background: linear-gradient(135deg, #f0f9eb, #e1f3d8); }
.stat-rejected_count { background: linear-gradient(135deg, #fef0f0, #fde2e2); }
.stat-avg { background: linear-gradient(135deg, #fff7e6, #ffe7ba); }
.stat-icon { font-size: 34px; color: #909399; margin-right: 14px; }
.stat-total_count .stat-icon { color: #409EFF; }
.stat-approved_count .stat-icon { color: #67C23A; }
.stat-rejected_count .stat-icon { color: #F56C6C; }
.stat-avg .stat-icon { color: #E6A23C; }
.stat-num { font-size: 24px; font-weight: 700; line-height: 1.1; }
.num-total_count { color: #409EFF; }
.num-approved_count { color: #67C23A; }
.num-rejected_count { color: #F56C6C; }
.num-avg { color: #E6A23C; }
.stat-label { font-size: 13px; color: #909399; margin-top: 4px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.link-blue { color: #409EFF; cursor: pointer; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.drawer-body { padding: 8px 20px 30px; }
.section-title { font-size: 15px; font-weight: 600; margin: 20px 0 12px; color: #303133; border-left: 3px solid #409EFF; padding-left: 8px; }
.tl-card { border: 1px solid #ebeef5; border-radius: 6px; padding: 8px 12px; background: #fff; }
.tl-mine { border-color: #409EFF; background: #f0f7ff; }
.tl-mine-tag { color: #409EFF; font-size: 12px; font-weight: 600; }
.tl-head { display: flex; align-items: center; gap: 10px; }
.tl-operator { font-weight: 600; color: #303133; }
.tl-result { color: #606266; }
.tl-comment { margin-top: 6px; color: #606266; font-size: 13px; }
</style>
