<!--
  文件：admin/src/views/hr/salary/score/Summary.vue
  功能：工分汇总（按月汇总、统计卡片、员工工分表、工分明细抽屉、导出）
  权限：hr:salary:score:view / export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>薪酬管理</el-breadcrumb-item>
      <el-breadcrumb-item>工资核算</el-breadcrumb-item>
      <el-breadcrumb-item>工分汇总</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 筛选条件 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="统计月份">
          <el-date-picker v-model="query.month" type="month" value-format="yyyy-MM" style="width:130px" />
        </el-form-item>
        <el-form-item label="部门">
          <el-select v-model="query.department_id" multiple filterable clearable placeholder="全部" style="width:180px">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="员工姓名"><el-input v-model="query.user_name" placeholder="请输入员工姓名" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="审核状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:120px">
            <el-option label="已通过" :value="2" /><el-option label="待审核" :value="1" /><el-option label="已驳回" :value="3" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">查询</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <el-alert type="info" show-icon :closable="false" class="rule-alert" title="注：工分汇总仅统计车间岗位工，科员无工分数据。" />

    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="8"><div class="stat-card stat-blue" @click="loadData"><div class="stat-icon"><i class="el-icon-star-on" /></div><div class="stat-info"><div class="stat-num">{{ cards.total_score }} <span class="stat-unit">分</span></div><div class="stat-label">总工分</div></div></div></el-col>
      <el-col :span="8"><div class="stat-card stat-green" @click="loadData"><div class="stat-icon"><i class="el-icon-user" /></div><div class="stat-info"><div class="stat-num" style="color:#67C23A">{{ cards.participant_count }} <span class="stat-unit">人</span></div><div class="stat-label">参与人数</div></div></div></el-col>
      <el-col :span="8"><div class="stat-card stat-orange"><div class="stat-icon"><i class="el-icon-data-line" /></div><div class="stat-info"><div class="stat-num" style="color:#E6A23C">{{ cards.avg_score }} <span class="stat-unit">分</span></div><div class="stat-label">人均工分</div></div></div></el-col>
    </el-row>

    <!-- 操作按钮栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'hr:salary:score:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出报表</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 人</span>
    </div>

    <!-- 数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无工分汇总数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column prop="user_name" label="员工姓名" width="90" />
      <el-table-column prop="department_name" label="部门" width="120" show-overflow-tooltip />
      <el-table-column prop="rank_name" label="职级" width="100" show-overflow-tooltip />
      <el-table-column label="岗位工分单价" width="120" align="right"><template slot-scope="s">{{ Number(s.row.score_price).toFixed(2) }} 元/分</template></el-table-column>
      <el-table-column label="审核通过工分" width="130" align="right"><template slot-scope="s"><span style="color:#67C23A">{{ Number(s.row.approved_score).toFixed(1) }} 分</span></template></el-table-column>
      <el-table-column label="待审核工分" width="130" align="right">
        <template slot-scope="s"><el-link v-if="s.row.pending_score > 0" type="warning" @click="openDetail(s.row, 1)">{{ Number(s.row.pending_score).toFixed(1) }} 分</el-link><span v-else style="color:#E6A23C">0.0 分</span></template>
      </el-table-column>
      <el-table-column label="已驳回工分" width="130" align="right">
        <template slot-scope="s"><el-link v-if="s.row.rejected_score > 0" type="danger" @click="openDetail(s.row, 3)">{{ Number(s.row.rejected_score).toFixed(1) }} 分</el-link><span v-else style="color:#F56C6C">0.0 分</span></template>
      </el-table-column>
      <el-table-column label="计件工资" width="130" align="right"><template slot-scope="s">¥ {{ Number(s.row.piecework_wage).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) }}</template></el-table-column>
      <el-table-column prop="report_count" label="报工次数" width="90" align="center" />
      <el-table-column label="操作" width="120" align="center" fixed="right">
        <template slot-scope="s"><el-button type="text" size="mini" @click="openDetail(s.row, 0)">查看明细</el-button></template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 工分明细抽屉 -->
    <el-drawer :title="`${detail.user ? detail.user.name : ''} ${detail.month || ''} 工分明细`" :visible.sync="drawerVisible" size="800px" :close-on-press-escape="true">
      <div v-if="detail.user" class="drawer-body">
        <el-descriptions :column="3" border size="small" style="margin-bottom:16px">
          <el-descriptions-item label="审核通过工分">{{ Number(detail.summary.approved).toFixed(1) }} 分</el-descriptions-item>
          <el-descriptions-item label="待审核工分">{{ Number(detail.summary.pending).toFixed(1) }} 分</el-descriptions-item>
          <el-descriptions-item label="已驳回工分">{{ Number(detail.summary.rejected).toFixed(1) }} 分</el-descriptions-item>
          <el-descriptions-item label="计件工资">¥ {{ Number(detail.summary.wage).toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) }}</el-descriptions-item>
          <el-descriptions-item label="报工次数">{{ detail.summary.count }} 次</el-descriptions-item>
          <el-descriptions-item label="岗位工分单价">{{ Number(detail.score_price).toFixed(2) }} 元/分</el-descriptions-item>
        </el-descriptions>
        <el-table :data="detail.list || []" size="small" border>
          <el-table-column prop="report_date" label="报工日期" width="120" />
          <el-table-column prop="task_type_label" label="任务类型" width="90" align="center" />
          <el-table-column prop="task_desc" label="任务描述" min-width="150" show-overflow-tooltip />
          <el-table-column prop="score" label="报工工分" width="90" align="right" />
          <el-table-column label="审核状态" width="100" align="center">
            <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="auditor_name" label="审核人" width="90" align="center"><template slot-scope="s">{{ s.row.auditor_name || '-' }}</template></el-table-column>
          <el-table-column prop="audit_time" label="审核时间" width="150" align="center"><template slot-scope="s">{{ s.row.audit_time || '-' }}</template></el-table-column>
          <el-table-column prop="remark" label="备注" min-width="100" show-overflow-tooltip />
        </el-table>
        <el-pagination class="pager" background layout="total, prev, pager, next" :total="detail.total || 0" :page-size="detail.limit || 10" :current-page="detail.page || 1" @current-change="handleDetailPage" />
      </div>
    </el-drawer>
  </div>
</template>

<script>
import { getScoreSummary, getScoreDetail, exportScoreSummary } from '@/api/salaryScore'
import { getDepartmentOptions } from '@/api/attendanceStatistics'

export default {
  name: 'HrScoreSummary',
  data () {
    return {
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false,
      query: { month: this.currentMonth(), department_id: [], user_name: '', status: '' },
      cards: { total_score: 0, participant_count: 0, avg_score: 0 },
      deptOptions: [],
      drawerVisible: false, detail: {}, detailUserId: 0, detailFilter: 0
    }
  },
  created () {
    this.loadDepts()
    this.loadData()
  },
  methods: {
    currentMonth () {
      const d = new Date()
      return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
    },
    async loadDepts () {
      try {
        const r = await getDepartmentOptions()
        const out = []
        const walk = (nodes) => { (nodes || []).forEach(n => { out.push({ id: n.id, name: n.name }); walk(n.children) }) }
        walk(r.data)
        this.deptOptions = out
      } catch (e) { this.deptOptions = [] }
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize, month: this.query.month }
      if (this.query.department_id && this.query.department_id.length) p.department_id = this.query.department_id
      if (this.query.user_name) p.user_name = this.query.user_name
      if (this.query.status !== '' && this.query.status !== null) p.status = this.query.status
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getScoreSummary(this.buildParams())
        if (r.code === 0 && r.data) {
          this.cards = r.data.cards || this.cards
          this.list = r.data.list || []
          this.total = r.data.total || 0
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () { this.query = { month: this.currentMonth(), department_id: [], user_name: '', status: '' }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    async openDetail (row, filter) {
      this.detailUserId = row.user_id
      this.detailFilter = filter
      this.drawerVisible = true
      this.detail = {}
      this.loadDetail(1)
    },
    async loadDetail (page) {
      try {
        const r = await getScoreDetail(this.detailUserId, { month: this.query.month, page, pageSize: 10 })
        if (r.code === 0 && r.data) this.detail = r.data
        else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
    },
    handleDetailPage (p) { this.loadDetail(p) },
    async handleExport () {
      this.exporting = true
      try {
        const p = { month: this.query.month }
        if (this.query.department_id && this.query.department_id.length) p.department_id = this.query.department_id
        if (this.query.user_name) p.user_name = this.query.user_name
        if (this.query.status !== '' && this.query.status !== null) p.status = this.query.status
        const r = await exportScoreSummary(p)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `工分汇总报表_${this.query.month}.xlsx`
          a.click()
          window.URL.revokeObjectURL(url)
        }
      } catch (e) {} finally { this.exporting = false }
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.stat-row { margin-top: 16px; }
.stat-card { display: flex; align-items: center; padding: 16px 20px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); cursor: pointer; transition: transform .2s; }
.stat-card:hover { transform: translateY(-3px); }
.stat-blue { background: linear-gradient(135deg, #ecf5ff, #d9ecff); }
.stat-green { background: linear-gradient(135deg, #f0f9eb, #e1f3d8); }
.stat-orange { background: linear-gradient(135deg, #fdf6ec, #fae8cd); }
.stat-icon { font-size: 30px; margin-right: 14px; }
.stat-blue .stat-icon { color: #409EFF; }
.stat-green .stat-icon { color: #67C23A; }
.stat-orange .stat-icon { color: #E6A23C; }
.stat-num { font-size: 24px; font-weight: bold; color: #303133; line-height: 1.2; }
.stat-unit { font-size: 13px; color: #909399; font-weight: normal; }
.stat-label { font-size: 13px; color: #909399; margin-top: 2px; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; margin-top: 16px; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.drawer-body { padding: 0 20px; }
</style>
