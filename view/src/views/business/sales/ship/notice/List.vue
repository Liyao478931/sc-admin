<!--
  文件：admin/src/views/business/sales/ship/notice/List.vue
  功能：发货通知列表（搜索/新增/批量提交/编辑/删除/提交审核[统一审批]/撤销/下推出库单/取消/导出/详情）
  权限：sales:ship:notice:view/add/edit/delete/audit/push/export
  说明：审核走统一审批（提交后由统一审批待办处理，本页不提供审核通过/驳回按钮）
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>销售管理</el-breadcrumb-item>
      <el-breadcrumb-item>发货管理</el-breadcrumb-item>
      <el-breadcrumb-item>发货通知</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="通知单编号"><el-input v-model="query.notice_no" placeholder="请输入通知单编号" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="销售订单"><el-input v-model="query.order_no" placeholder="请输入销售订单编号" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="客户名称"><el-input v-model="query.customer_name" placeholder="请输入客户名称" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="通知状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="发货日期">
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
        <el-button v-permission="'sales:ship:notice:add'" type="primary" size="small" icon="el-icon-plus" @click="$router.push({ path: '/business/sales/ship/notice/add' })">新增通知</el-button>
        <el-dropdown v-permission="'sales:ship:notice:audit'" trigger="click" @command="handleBatch">
          <el-button size="small" icon="el-icon-more">批量操作<i class="el-icon-arrow-down el-icon--right" /></el-button>
          <el-dropdown-menu slot="dropdown">
            <el-dropdown-item command="submit" icon="el-icon-upload2">批量提交审核</el-dropdown-item>
          </el-dropdown-menu>
        </el-dropdown>
        <el-button v-permission="'sales:ship:notice:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无发货通知数据" @selection-change="s => (selection = s)">
      <el-table-column type="selection" width="55" align="center" />
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="通知单编号" width="160">
        <template slot-scope="s"><el-link type="primary" @click="goDetail(s.row)">{{ s.row.notice_no }}</el-link></template>
      </el-table-column>
      <el-table-column prop="notice_name" label="通知单名称" min-width="160" show-overflow-tooltip />
      <el-table-column label="销售订单" width="140">
        <template slot-scope="s"><el-link type="primary" @click="$router.push({ path: '/business/order' })">{{ s.row.order_no || '-' }}</el-link></template>
      </el-table-column>
      <el-table-column prop="customer_name" label="客户名称" width="140" show-overflow-tooltip />
      <el-table-column prop="receiver" label="收货人" width="90" align="center" />
      <el-table-column label="发货日期" width="110" align="center"><template slot-scope="s">{{ s.row.ship_date || '-' }}</template></el-table-column>
      <el-table-column label="通知状态" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="创建时间" width="160" align="center"><template slot-scope="s">{{ s.row.created_at || '-' }}</template></el-table-column>
      <el-table-column label="操作" width="250" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="goDetail(s.row)">查看详情</el-button>
          <el-button v-if="s.row.status === 0" v-permission="'sales:ship:notice:edit'" type="text" size="mini" @click="goEdit(s.row)">编辑</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 4" v-permission="'sales:ship:notice:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
            <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right" /></el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-if="s.row.status === 0" command="submit" icon="el-icon-upload2">提交审核</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1" command="revoke" icon="el-icon-refresh-left">撤销审批</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 2" v-permission="'sales:ship:notice:push'" command="push" icon="el-icon-download">下推出库单</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 0 || s.row.status === 1" command="cancel" icon="el-icon-circle-close">取消通知</el-dropdown-item>
              <el-dropdown-item command="print" icon="el-icon-printer">打印通知</el-dropdown-item>
              <el-dropdown-item v-if="!(s.row.status === 0 || s.row.status === 1 || s.row.status === 2)" disabled>当前状态无可执行操作</el-dropdown-item>
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
import { getNoticeList, deleteNotice, submitNotice, revokeNotice, cancelNotice, pushNotice, batchSubmitNotices, exportNotice } from '@/api/sales'

const STATUS_TEXT = { 0: '草稿', 1: '待审核', 2: '已审核', 3: '已下推', 4: '已取消' }

export default {
  name: 'ShipNoticeList',
  data () {
    return {
      STATUS_TEXT,
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false,
      query: { notice_no: '', order_no: '', customer_name: '', status: '' },
      dateRange: [], selection: []
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
        const r = await getNoticeList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.query = { notice_no: '', order_no: '', customer_name: '', status: '' }; this.dateRange = []; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.getList() },
    goDetail (row) { this.$router.push({ path: `/business/sales/ship/notice/detail/${row.id}` }) },
    goEdit (row) { this.$router.push({ path: `/business/sales/ship/notice/edit/${row.id}` }) },
    handleDelete (row) {
      this.$confirm('确认删除该发货通知吗？删除后不可恢复', '提示', { type: 'warning' }).then(() => {
        deleteNotice(row.id).then(r => { if (r.code === 0) { this.$message.success('删除成功'); this.getList() } else this.$message.error(r.msg || '删除失败') })
      }).catch(() => {})
    },
    handleMore (cmd, row) {
      if (cmd === 'submit') this.handleSubmit(row)
      else if (cmd === 'revoke') this.handleRevoke(row)
      else if (cmd === 'push') this.handlePush(row)
      else if (cmd === 'cancel') this.handleCancel(row)
      else if (cmd === 'print') this.handlePrint(row)
    },
    handleSubmit (row) {
      this.$confirm(`确认提交通知 ${row.notice_no} 审核吗？提交后将由统一审批流程处理，提交后不可再编辑。`, '提交审核', { type: 'warning' }).then(() => {
        submitNotice(row.id).then(r => { if (r.code === 0) { this.$message.success('已提交审核'); this.getList() } else this.$message.error(r.msg || '提交失败') })
      }).catch(() => {})
    },
    handleRevoke (row) {
      this.$confirm(`确认撤销通知 ${row.notice_no} 的审批吗？撤销后回到草稿可修改重提。`, '撤销审批', { type: 'warning' }).then(() => {
        revokeNotice(row.id).then(r => { if (r.code === 0) { this.$message.success('已撤销'); this.getList() } else this.$message.error(r.msg || '操作失败') })
      }).catch(() => {})
    },
    handlePush (row) {
      this.$confirm(`确认将通知 ${row.notice_no} 下推为销售出库单吗？系统将自动生成草稿出库单，通知状态变为已下推。`, '下推出库单', { type: 'warning' }).then(() => {
        pushNotice(row.id).then(r => {
          if (r.code === 0) {
            this.$message.success(r.msg || '已下推出库单')
            this.getList()
            if (r.data && r.data.out_id) this.$router.push({ path: `/business/sales/out/detail/${r.data.out_id}` })
          } else this.$message.error(r.msg || '操作失败')
        })
      }).catch(() => {})
    },
    handleCancel (row) {
      this.$confirm(`确认取消通知 ${row.notice_no} 吗？`, '取消通知', { type: 'warning' }).then(() => {
        cancelNotice(row.id).then(r => { if (r.code === 0) { this.$message.success('已取消'); this.getList() } else this.$message.error(r.msg || '操作失败') })
      }).catch(() => {})
    },
    handlePrint (row) {
      this.$router.push({ path: `/business/sales/ship/notice/detail/${row.id}`, query: { print: 1 } })
    },
    handleBatch (cmd) {
      if (cmd !== 'submit') return
      const drafts = this.selection.filter(x => x.status === 0)
      if (!drafts.length) { this.$message.warning('请选择草稿状态的通知'); return }
      this.$confirm(`确认批量提交选中的 ${drafts.length} 个通知吗？`, '批量提交审核', { type: 'warning' }).then(() => {
        batchSubmitNotices(drafts.map(x => x.id)).then(r => {
          if (r.code === 0) { this.$message.success(r.msg || '批量提交完成'); this.getList() } else this.$message.error(r.msg || '操作失败')
        })
      }).catch(() => {})
    },
    async handleExport () {
      this.exporting = true
      try {
        const p = { ...this.buildParams() }
        delete p.page; delete p.pageSize
        const r = await exportNotice(p)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `发货通知_${new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14)}.xlsx`
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
