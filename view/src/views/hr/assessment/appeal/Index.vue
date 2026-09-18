<!--
  文件：admin/src/views/hr/assessment/appeal/Index.vue
  功能：申诉处理中心（统计卡片 + 筛选栏 + 申诉列表 + 详情侧滑 + 处理弹窗）
  视觉：对齐参考模板（主色 #1e6fff）
-->
<template>
  <div class="wh-page assessment-appeal-page">
    <div class="page-header">
      <div class="header-left">
        <el-breadcrumb separator="/" class="breadcrumb">
          <el-breadcrumb-item>人事管理</el-breadcrumb-item>
          <el-breadcrumb-item>绩效考核</el-breadcrumb-item>
          <el-breadcrumb-item>申诉处理中心</el-breadcrumb-item>
        </el-breadcrumb>
        <span class="badge-module">⚖️ 申诉处理中心</span>
      </div>
      <div class="header-actions">
        <el-button v-permission="'assessment:appeal:export'" size="small" icon="el-icon-download" @click="doExport">导出申诉记录</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadList">刷新</el-button>
      </div>
    </div>

    <div class="appeal-layout">
      <!-- 统计卡片 -->
      <div class="stat-cards">
        <div class="stat-card" :style="{ borderTopColor: '#1e6fff' }">
          <div class="sc-icon">📋</div>
          <div class="sc-info"><div class="sc-value">{{ stats.total || 0 }}</div><div class="sc-label">总申诉</div></div>
        </div>
        <div class="stat-card" :style="{ borderTopColor: '#ffb020' }">
          <div class="sc-icon">⏳</div>
          <div class="sc-info"><div class="sc-value warn">{{ stats.pending || 0 }}</div><div class="sc-label">待处理</div></div>
        </div>
        <div class="stat-card" :style="{ borderTopColor: '#00b42a' }">
          <div class="sc-icon">✅</div>
          <div class="sc-info"><div class="sc-value">{{ stats.approved || 0 }}</div><div class="sc-label">已通过</div></div>
        </div>
        <div class="stat-card" :style="{ borderTopColor: '#9B59B6' }">
          <div class="sc-icon">📊</div>
          <div class="sc-info"><div class="sc-value">{{ stats.pass_rate || 0 }}%</div><div class="sc-label">通过率</div></div>
        </div>
      </div>

      <!-- 筛选栏 -->
      <div class="filter-bar">
        <div class="filter-left">
          <el-select v-model="query.status" size="small" clearable placeholder="全部状态" style="width:110px" @change="loadList">
            <el-option label="待处理" :value="0" /><el-option label="已通过" :value="1" /><el-option label="已驳回" :value="2" />
          </el-select>
          <el-select v-model="query.department_id" size="small" clearable placeholder="全部部门" style="width:130px" @change="loadList">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
          <el-input v-model="query.keyword" size="small" prefix-icon="el-icon-search" clearable placeholder="申诉人姓名" style="width:130px" @keyup.enter.native="loadList" @clear="loadList" />
          <el-date-picker v-model="dateRange" size="small" type="daterange" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" value-format="yyyy-MM-dd" style="width:240px" @change="loadList" />
          <el-button size="small" icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </div>
      </div>

      <!-- 申诉列表 -->
      <div class="table-wrap">
        <el-table :data="list" v-loading="loading" size="small" border stripe>
          <el-table-column type="index" label="#" width="55" align="center" />
          <el-table-column prop="employee_name" label="申诉人" width="90" fixed="left" />
          <el-table-column prop="department_name" label="部门" width="100" />
          <el-table-column prop="indicator_name" label="扣分指标" width="120" />
          <el-table-column prop="deduct_score" label="扣分" width="70" align="center">
            <template slot-scope="s">{{ s.row.deduct_score || 0 }}</template>
          </el-table-column>
          <el-table-column prop="appeal_reason" label="申诉理由" min-width="160" show-overflow-tooltip />
          <el-table-column prop="created_at" label="提交时间" width="150" />
          <el-table-column label="状态" width="85" align="center">
            <template slot-scope="s"><el-tag :type="statusTag(s.row.status)" size="mini">{{ s.row.status_text }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="handler_name" label="处理人" width="80" align="center">
            <template slot-scope="s">{{ s.row.handler_name || '—' }}</template>
          </el-table-column>
          <el-table-column label="操作" width="130" align="center" fixed="right">
            <template slot-scope="s">
              <el-button v-permission="'assessment:appeal:handle'" v-if="s.row.status === 0" type="text" size="mini" @click="openHandle(s.row)">处理</el-button>
              <el-button type="text" size="mini" @click="openDetail(s.row)">详情</el-button>
            </template>
          </el-table-column>
        </el-table>
        <div class="pager">
          <el-pagination background layout="total, prev, pager, next" :total="total" :page-size="limit" :current-page="page" @current-change="onPageChange" />
        </div>
      </div>
    </div>

    <!-- 详情侧滑 -->
    <el-drawer title="申诉详情" :visible.sync="detailVisible" size="480px">
      <div class="detail-body" v-if="detail">
        <div class="detail-section">
          <div class="section-title">基本信息</div>
          <div class="d-row">申诉人：{{ detail.employee_name }}（{{ detail.department_name }}）</div>
          <div class="d-row">考核周期：{{ detail.task ? detail.task.period : '—' }}</div>
          <div class="d-row">扣分指标：{{ detail.indicator_name }}（分值：{{ detail.deduct_score }}分）</div>
          <div class="d-row">扣分原因：{{ detail.reason || '—' }}</div>
        </div>
        <div class="detail-section">
          <div class="section-title">申诉内容</div>
          <div class="d-row">申诉理由：{{ detail.appeal_reason }}</div>
          <div class="d-row" v-if="detail.attachments && detail.attachments.length">附件：{{ detail.attachments.join('、') }}</div>
          <div class="d-row">提交时间：{{ detail.created_at }}</div>
        </div>
        <div class="detail-section" v-if="detail.status !== 0">
          <div class="section-title">处理信息</div>
          <div class="d-row">处理人：{{ detail.handler_name || '—' }}</div>
          <div class="d-row">处理意见：{{ detail.handler_reply || '—' }}</div>
          <div class="d-row">处理结果：{{ detail.status_text }}</div>
          <div class="d-row">处理时间：{{ detail.handled_at || '—' }}</div>
        </div>
        <div class="detail-actions" v-if="detail.status === 0">
          <el-button v-permission="'assessment:appeal:handle'" type="primary" size="small" @click="openHandle(detail)">处理申诉</el-button>
        </div>
      </div>
    </el-drawer>

    <!-- 处理弹窗 -->
    <el-dialog title="处理申诉" :visible.sync="handleVisible" width="560px" :close-on-click-modal="false">
      <div class="handle-info" v-if="handleForm">
        <div class="d-row"><b>申诉人：</b>{{ handleForm.employee_name }}（{{ handleForm.department_name }}）　<b>指标：</b>{{ handleForm.indicator_name }}　<b>扣分：</b>{{ handleForm.deduct_score }}分</div>
        <div class="d-row"><b>申诉理由：</b>{{ handleForm.appeal_reason }}</div>
        <el-divider></el-divider>
      </div>
      <el-form v-if="handleForm" label-width="90px" size="small">
        <el-form-item label="处理结果">
          <el-radio-group v-model="handleForm.status">
            <el-radio :label="1">通过（撤销扣分，恢复分值）</el-radio>
            <el-radio :label="2">驳回（维持扣分）</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="处理意见">
          <el-input v-model="handleForm.handler_reply" type="textarea" :rows="4" placeholder="请填写处理意见（必填）" />
        </el-form-item>
        <el-alert type="warning" :closable="false" show-icon title="通过后：该条扣分将被撤销，员工考核总分将重新计算。" />
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="handleVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="handling" @click="doHandle">确认处理</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import request from '@/api/request'
import { getAppealList, getAppealDetail, handleAppeal, exportAppealRecords } from '@/api/assessment'

export default {
  name: 'AssessmentAppealIndex',
  data () {
    return {
      query: { status: '', department_id: '', keyword: '' },
      dateRange: [],
      deptOptions: [],
      list: [], total: 0, page: 1, limit: 20, loading: false, stats: {},
      detailVisible: false, detail: null,
      handleVisible: false, handling: false,
      handleForm: { id: 0, employee_name: '', department_name: '', indicator_name: '', deduct_score: 0, appeal_reason: '', status: 1, handler_reply: '' }
    }
  },
  created () {
    this.loadDepts()
    this.loadList()
  },
  methods: {
    async loadDepts () {
      try {
        const r = await request({ url: '/departments/tree', method: 'get' })
        if (r.code === 0) {
          const flat = []
          const walk = nodes => { (nodes || []).forEach(n => { flat.push({ id: n.id, name: n.name }); if (n.children) walk(n.children) }) }
          walk(r.data)
          this.deptOptions = flat
        }
      } catch (e) {}
    },
    async loadList () {
      this.loading = true
      try {
        const params = { page: this.page, limit: this.limit }
        if (this.query.status !== '') params.status = this.query.status
        if (this.query.department_id) params.department_id = this.query.department_id
        if (this.query.keyword) params.keyword = this.query.keyword
        if (this.dateRange && this.dateRange.length === 2) {
          params.start_date = this.dateRange[0]
          params.end_date = this.dateRange[1]
        }
        const r = await getAppealList(params)
        if (r.code === 0 && r.data) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
          this.stats = r.data.statistics || {}
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleReset () {
      this.query = { status: '', department_id: '', keyword: '' }
      this.dateRange = []
      this.page = 1
      this.loadList()
    },
    onPageChange (p) { this.page = p; this.loadList() },
    statusTag (s) {
      return { 0: 'warning', 1: 'success', 2: 'danger' }[s] || 'info'
    },
    async openDetail (row) {
      try {
        const r = await getAppealDetail(row.id)
        if (r.code === 0) { this.detail = r.data; this.detailVisible = true }
      } catch (e) {}
    },
    openHandle (row) {
      this.handleForm = { id: row.id, employee_name: row.employee_name, department_name: row.department_name, indicator_name: row.indicator_name, deduct_score: row.deduct_score, appeal_reason: row.appeal_reason, status: 1, handler_reply: '' }
      this.handleVisible = true
    },
    async doHandle () {
      if (!this.handleForm.handler_reply.trim()) { this.$message.warning('请填写处理意见'); return }
      this.handling = true
      try {
        const r = await handleAppeal(this.handleForm.id, { status: this.handleForm.status, handler_reply: this.handleForm.handler_reply })
        if (r.code === 0) {
          this.$message.success('处理完成')
          this.handleVisible = false
          this.detailVisible = false
          this.loadList()
        } else this.$message.error(r.msg || '处理失败')
      } catch (e) {} finally { this.handling = false }
    },
    async doExport () {
      try {
        const params = {}
        if (this.query.status !== '') params.status = this.query.status
        if (this.dateRange && this.dateRange.length === 2) {
          params.start_date = this.dateRange[0]
          params.end_date = this.dateRange[1]
        }
        const r = await exportAppealRecords(params)
        const blob = new Blob([r.data], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' })
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = `申诉记录_${new Date().toISOString().slice(0, 10)}.xlsx`
        a.click()
        URL.revokeObjectURL(url)
        this.$message.success('导出成功')
      } catch (e) { this.$message.error('导出失败') }
    }
  }
}
</script>

<style scoped>
.assessment-appeal-page { padding: 16px; }
.page-header { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 12px; padding: 12px 18px; background: #fafbfc; border: 1px solid #e8ecf1; border-bottom: none; border-radius: 12px 12px 0 0; }
.header-left { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.header-left .breadcrumb { font-size: 14px; color: #8c8f9c; }
.header-left .breadcrumb >>> .el-breadcrumb__inner { color: #8c8f9c; }
.header-left .breadcrumb >>> .el-breadcrumb__item:last-child .el-breadcrumb__inner { color: #1d2129; font-weight: 500; }
.badge-module { background: #e8f3ff; color: #1e6fff; font-size: 12px; padding: 2px 12px; border-radius: 12px; font-weight: 500; }
.header-actions { display: flex; gap: 8px; }
.appeal-layout { border: 1px solid #e8ecf1; border-radius: 0 0 12px 12px; background: #f7f9fc; padding: 16px; display: flex; flex-direction: column; gap: 16px; }
.stat-cards { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; }
.stat-card { background: #fff; border: 1px solid #e8ecf1; border-top: 3px solid #1e6fff; border-radius: 12px; padding: 16px; display: flex; align-items: center; gap: 12px; }
.sc-icon { font-size: 26px; }
.sc-value { font-size: 22px; font-weight: 600; color: #1d2129; }
.sc-value.warn { color: #ffb020; }
.sc-label { font-size: 12px; color: #8c8f9c; margin-top: 2px; }
.filter-bar { display: flex; align-items: center; background: #fff; border: 1px solid #e8ecf1; border-radius: 12px; padding: 12px 16px; }
.filter-left { display: flex; align-items: center; gap: 8px; flex-wrap: wrap; }
.table-wrap { background: #fff; border: 1px solid #e8ecf1; border-radius: 12px; padding: 14px 16px; }
.pager { display: flex; justify-content: flex-end; margin-top: 12px; }
.detail-body { padding: 0 20px 20px; }
.detail-section { margin-bottom: 18px; }
.section-title { font-size: 13px; font-weight: 600; color: #1d2129; margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid #e8ecf1; }
.d-row { font-size: 13px; color: #4e5a6b; line-height: 2; }
.detail-actions { margin-top: 12px; }
.handle-info { padding: 0 0 4px 20px; }
@media (max-width: 900px) { .stat-cards { grid-template-columns: repeat(2, 1fr); } }
</style>

<!-- 模块级主题覆盖 -->
<style>
.assessment-appeal-page .el-button--primary { background-color: #1e6fff; border-color: #1e6fff; }
.assessment-appeal-page .el-button--primary:hover, .assessment-appeal-page .el-button--primary:focus { background-color: #4d8bff; border-color: #4d8bff; }
.assessment-appeal-page .el-radio__input.is-checked .el-radio__inner { border-color: #1e6fff; background: #1e6fff; }
.assessment-appeal-page .el-radio__input.is-checked + .el-radio__label { color: #1e6fff; }
.assessment-appeal-page .el-input__inner:focus, .assessment-appeal-page .el-textarea__inner:focus { border-color: #1e6fff; }
.assessment-appeal-page .el-pagination.is-background .el-pager li:not(.disabled).active { background-color: #1e6fff; }
</style>
