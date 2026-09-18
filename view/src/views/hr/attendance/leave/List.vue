<!--
  文件：admin/src/views/hr/attendance/leave/List.vue
  功能：假勤申请列表（搜索/审批/撤销/催办/删除/导出）
  权限：hr:attendance:leave:view/add/edit/delete/approve/export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>考勤管理</el-breadcrumb-item>
      <el-breadcrumb-item>假勤申请</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="申请编号"><el-input v-model="query.request_no" placeholder="请输入申请编号" clearable style="width:170px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="申请人"><el-input v-model="query.applicant_name" placeholder="请输入申请人姓名" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="假勤类型">
          <el-select v-model="query.leave_type" clearable placeholder="全部" style="width:120px">
            <el-option v-for="(t, v) in LEAVE_TYPES" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="申请日期">
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:230px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'hr:attendance:leave:add'" type="primary" size="small" icon="el-icon-plus" @click="$router.push({ path: '/hr/attendance/leave/add' })">新增申请</el-button>
        <el-button v-permission="'hr:attendance:leave:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无假勤申请数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="申请编号" width="150">
        <template slot-scope="s"><el-link type="primary" @click="goDetail(s.row)">{{ s.row.request_no }}</el-link></template>
      </el-table-column>
      <el-table-column prop="applicant_name" label="申请人" width="90" align="center" />
      <el-table-column prop="department_name" label="部门" width="120" show-overflow-tooltip />
      <el-table-column label="假勤类型" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.leave_type_tag" effect="plain" size="mini">{{ s.row.leave_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="date_range" label="申请日期范围" width="200" />
      <el-table-column label="总天数" width="90" align="right"><template slot-scope="s">{{ Number(s.row.total_days) }} 天</template></el-table-column>
      <el-table-column label="申请事由" min-width="150" show-overflow-tooltip><template slot-scope="s">{{ s.row.reason || '-' }}</template></el-table-column>
      <el-table-column label="状态" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="申请日期" width="160" align="center"><template slot-scope="s">{{ s.row.created_at || '-' }}</template></el-table-column>
      <el-table-column label="操作" width="250" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="goDetail(s.row)">详情</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 3" v-permission="'hr:attendance:leave:edit'" type="text" size="mini" @click="goEdit(s.row)">编辑</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 3" v-permission="'hr:attendance:leave:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
            <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right" /></el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-if="s.row.status === 0" command="submit" icon="el-icon-upload2">提交审批</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1 && isApprover(s.row)" v-permission="'hr:attendance:leave:approve'" command="approve" icon="el-icon-check">审批通过</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1 && isApprover(s.row)" v-permission="'hr:attendance:leave:approve'" command="reject" icon="el-icon-close">审批驳回</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 0 || s.row.status === 1" command="cancel" icon="el-icon-refresh-left">撤销申请</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1" command="urge" icon="el-icon-bell">催办</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status !== 0 && s.row.status !== 1" disabled>当前状态无可执行操作</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />
  </div>
</template>

<script>
import { getLeaveList, deleteLeave, submitLeave, approveLeave, rejectLeave, cancelLeave, urgeLeave, exportLeave } from '@/api/attendanceLeave'

const LEAVE_TYPES = { 1: '年假', 2: '事假', 3: '病假', 4: '调休', 5: '加班', 6: '出差', 7: '婚假', 8: '丧假', 9: '产假', 10: '其他' }
const STATUS_TEXT = { 0: '草稿', 1: '待审批', 2: '已通过', 3: '已驳回', 4: '已撤销' }

export default {
  name: 'HrLeaveList',
  data () {
    return {
      LEAVE_TYPES, STATUS_TEXT,
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false,
      query: { request_no: '', applicant_name: '', leave_type: '', status: '' },
      dateRange: []
    }
  },
  created () { this.getList() },
  methods: {
    isApprover (row) {
      const uid = this.$store.state.user.userInfo && this.$store.state.user.userInfo.id
      return row.approver_id === uid
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      Object.keys(this.query).forEach(k => { if (this.query[k] !== '' && this.query[k] !== null) p[k] = this.query[k] })
      if (this.dateRange && this.dateRange.length === 2) p.date_range = this.dateRange
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getLeaveList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.query = { request_no: '', applicant_name: '', leave_type: '', status: '' }; this.dateRange = []; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.getList() },
    goDetail (row) { this.$router.push({ path: `/hr/attendance/leave/detail/${row.id}` }) },
    goEdit (row) { this.$router.push({ path: `/hr/attendance/leave/edit/${row.id}` }) },
    handleDelete (row) {
      this.$confirm('确认删除该申请吗？删除后不可恢复', '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteLeave(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.getList() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleMore (cmd, row) {
      if (cmd === 'submit') this.handleSubmit(row)
      else if (cmd === 'approve') this.handleApprove(row)
      else if (cmd === 'reject') this.handleReject(row)
      else if (cmd === 'cancel') this.handleCancel(row)
      else if (cmd === 'urge') this.handleUrge(row)
    },
    handleSubmit (row) {
      this.$confirm(`确认提交申请 ${row.request_no} 审批吗？提交后不可再编辑。`, '提交审批', { type: 'warning' }).then(async () => {
        try {
          const r = await submitLeave(row.id)
          if (r.code === 0) { this.$message.success('已提交审批'); this.getList() } else this.$message.error(r.msg || '提交失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleApprove (row) {
      this.$prompt('请输入审批备注（可选）', '审批通过', { inputPlaceholder: '审批备注', inputValue: '' }).then(async ({ value }) => {
        try {
          const r = await approveLeave(row.id, value || '')
          if (r.code === 0) { this.$message.success('审批已通过'); this.getList() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleReject (row) {
      this.$prompt('请输入驳回原因（必填）', '审批驳回', { inputPlaceholder: '驳回原因' }).then(async ({ value }) => {
        if (!value || !value.trim()) { this.$message.warning('驳回原因必填'); return }
        try {
          const r = await rejectLeave(row.id, value.trim())
          if (r.code === 0) { this.$message.success('已驳回'); this.getList() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleCancel (row) {
      this.$confirm(`确认撤销申请 ${row.request_no} 吗？`, '撤销申请', { type: 'warning' }).then(async () => {
        try {
          const r = await cancelLeave(row.id)
          if (r.code === 0) { this.$message.success('已撤销'); this.getList() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleUrge (row) {
      this.$confirm(`确认催办申请 ${row.request_no} 吗？将通知审批人尽快处理。`, '催办', { type: 'warning' }).then(async () => {
        try {
          const r = await urgeLeave(row.id)
          if (r.code === 0) { this.$message.success('已催办'); this.getList() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    async handleExport () {
      this.exporting = true
      try {
        const p = { ...this.buildParams() }
        delete p.page; delete p.pageSize
        const r = await exportLeave(p)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `假勤申请列表_${new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14)}.xlsx`
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
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.danger { color: #F56C6C; }
</style>
