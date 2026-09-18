<!--
  文件：admin/src/views/hr/transfer/List.vue
  功能：员工异动列表（搜索/新增/编辑/删除/提交审批/撤销审批/确认生效/导出）
  权限：hr:transfer:view/add/edit/delete/approve/export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>人事管理</el-breadcrumb-item>
      <el-breadcrumb-item>员工异动</el-breadcrumb-item>
      <el-breadcrumb-item>异动列表</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="异动编号"><el-input v-model="query.transfer_no" placeholder="请输入异动编号" clearable style="width:170px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="员工姓名"><el-input v-model="query.employee_name" placeholder="请输入员工姓名" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="异动类型">
          <el-select v-model="query.transfer_type" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in TRANSFER_TYPES" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="异动状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="审批状态">
          <el-select v-model="query.approval_status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in APPROVAL_STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="生效日期">
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
        <el-button v-permission="'hr:transfer:add'" type="primary" size="small" icon="el-icon-plus" @click="$router.push({ path: '/hr/transfer/add' })">新增异动</el-button>
        <el-button v-permission="'hr:transfer:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无员工异动数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="异动编号" width="150">
        <template slot-scope="s"><el-link type="primary" @click="goDetail(s.row)">{{ s.row.transfer_no }}</el-link></template>
      </el-table-column>
      <el-table-column prop="employee_name" label="员工姓名" width="90" align="center" />
      <el-table-column label="异动类型" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.transfer_type_tag" effect="plain" size="mini">{{ s.row.transfer_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="变更信息" min-width="200" show-overflow-tooltip>
        <template slot-scope="s">{{ s.row.change_summary || '-' }}</template>
      </el-table-column>
      <el-table-column label="异动原因" min-width="120" show-overflow-tooltip>
        <template slot-scope="s">{{ s.row.transfer_reason || '-' }}</template>
      </el-table-column>
      <el-table-column label="生效日期" width="110" align="center"><template slot-scope="s">{{ s.row.transfer_date || '-' }}</template></el-table-column>
      <el-table-column label="异动状态" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="260" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="goDetail(s.row)">查看详情</el-button>
          <el-button v-if="s.row.status === 0" v-permission="'hr:transfer:edit'" type="text" size="mini" @click="goEdit(s.row)">编辑</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 3" v-permission="'hr:transfer:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
            <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right" /></el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-if="s.row.status === 0" command="submit" icon="el-icon-upload2">提交审批</el-dropdown-item>
              <el-dropdown-item v-if="s.row.approval_status === 1" command="revoke" icon="el-icon-refresh-left">撤销审批</el-dropdown-item>
              <el-dropdown-item v-if="s.row.approval_status === 2 && s.row.status === 1" v-permission="'hr:transfer:approve'" command="confirm" icon="el-icon-check">确认生效</el-dropdown-item>
              <el-dropdown-item v-if="!(s.row.status === 0 || s.row.approval_status === 1 || (s.row.approval_status === 2 && s.row.status === 1))" disabled>当前状态无可执行操作</el-dropdown-item>
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
import { getTransferList, deleteTransfer, submitTransfer, revokeTransfer, confirmTransfer, exportTransfer } from '@/api/hrTransfer'

const TRANSFER_TYPES = { 1: '转正', 2: '调岗', 3: '晋升', 4: '降职', 5: '离职', 6: '复职' }
const STATUS_TEXT = { 0: '草稿', 1: '待生效', 2: '已生效', 3: '已取消' }
const APPROVAL_STATUS_TEXT = { 0: '草稿', 1: '待审批', 2: '已通过', 3: '已驳回', 4: '已撤销' }

export default {
  name: 'HrTransferList',
  data () {
    return {
      TRANSFER_TYPES, STATUS_TEXT, APPROVAL_STATUS_TEXT,
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false,
      query: { transfer_no: '', employee_name: '', transfer_type: '', status: '', approval_status: '' },
      dateRange: []
    }
  },
  created () { this.getList() },
  methods: {
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      Object.keys(this.query).forEach(k => { if (this.query[k] !== '' && this.query[k] !== null) p[k] = this.query[k] })
      if (this.dateRange && this.dateRange.length === 2) p.date_range = this.dateRange
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getTransferList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.query = { transfer_no: '', employee_name: '', transfer_type: '', status: '', approval_status: '' }; this.dateRange = []; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.getList() },
    goDetail (row) { this.$router.push({ path: `/hr/transfer/detail/${row.id}` }) },
    goEdit (row) { this.$router.push({ path: `/hr/transfer/edit/${row.id}` }) },
    handleDelete (row) {
      this.$confirm('确认删除该异动记录吗？删除后不可恢复', '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteTransfer(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.getList() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleMore (cmd, row) {
      if (cmd === 'submit') this.handleSubmit(row)
      else if (cmd === 'revoke') this.handleRevoke(row)
      else if (cmd === 'confirm') this.handleConfirm(row)
    },
    handleSubmit (row) {
      this.$confirm(`确认提交异动 ${row.transfer_no} 审批吗？提交后不可再编辑。`, '提交审批', { type: 'warning' }).then(async () => {
        try {
          const r = await submitTransfer(row.id)
          if (r.code === 0) { this.$message.success('已提交审批'); this.getList() } else this.$message.error(r.msg || '提交失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleRevoke (row) {
      this.$confirm(`确认撤销异动 ${row.transfer_no} 的审批吗？撤销后异动回到草稿，可修改后重新提交。`, '撤销审批', { type: 'warning' }).then(async () => {
        try {
          const r = await revokeTransfer(row.id)
          if (r.code === 0) { this.$message.success('已撤销'); this.getList() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleConfirm (row) {
      this.$confirm(`确认异动 ${row.transfer_no} 生效吗？生效后员工档案（部门/岗位/职级/状态）将自动更新，且不可撤回。`, '确认生效', { type: 'warning' }).then(async () => {
        try {
          const r = await confirmTransfer(row.id)
          if (r.code === 0) { this.$message.success('异动已生效'); this.getList() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    async handleExport () {
      this.exporting = true
      try {
        const p = { ...this.buildParams() }
        delete p.page; delete p.pageSize
        const r = await exportTransfer(p)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `员工异动列表_${new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14)}.xlsx`
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
