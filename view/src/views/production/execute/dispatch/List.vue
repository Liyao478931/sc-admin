<!--
  文件：admin/src/views/production/execute/dispatch/List.vue
  功能：工单派工列表（筛选/状态操作流：确认派工·开始执行·完成任务·撤销/导出）
  权限：production:dispatch:view 及各项操作权限
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>生产执行</el-breadcrumb-item>
      <el-breadcrumb-item>工单派工</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索与筛选区域 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="派工单编号"><el-input v-model="query.dispatch_no" placeholder="请输入派工单编号" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="工单编号"><el-input v-model="query.work_order_no" placeholder="请输入工单编号" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="派工人"><el-input v-model="query.dispatcher_name" placeholder="请输入派工人姓名" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="派工状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in statusOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="派工日期">
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
        <el-button v-permission="'production:dispatch:add'" type="primary" size="small" icon="el-icon-plus" @click="$router.push('/production/execute/dispatch/add')">新增派工</el-button>
        <el-button v-permission="'production:dispatch:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
      </div>
      <div class="toolbar-right">
        <span class="total-text">共 {{ total }} 条</span>
      </div>
    </div>

    <!-- 数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无派工数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="派工单编号" width="160">
        <template slot-scope="s"><span class="link-blue" @click="$router.push(`/production/execute/dispatch/detail/${s.row.id}`)">{{ s.row.dispatch_no }}</span></template>
      </el-table-column>
      <el-table-column label="关联工单" width="150">
        <template slot-scope="s"><span class="link-blue" @click="$router.push(`/production/plan/order/detail/${s.row.work_order_id}`)">{{ s.row.work_order_no }}</span></template>
      </el-table-column>
      <el-table-column prop="dispatcher_name" label="派工人" width="90" show-overflow-tooltip />
      <el-table-column label="派工类型" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.dispatch_type_tag" size="mini">{{ s.row.dispatch_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="worker_names" label="被派工人/班组" min-width="140" show-overflow-tooltip />
      <el-table-column label="工序数" width="70" align="center"><template slot-scope="s">{{ s.row.task_count || 0 }}</template></el-table-column>
      <el-table-column prop="dispatch_date" label="派工日期" width="110" align="center" />
      <el-table-column label="状态" width="90" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="230" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="$router.push(`/production/execute/dispatch/detail/${s.row.id}`)">查看详情</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 1" v-permission="'production:dispatch:edit'" type="text" size="mini" @click="$router.push(`/production/execute/dispatch/edit/${s.row.id}`)">编辑</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 1" v-permission="'production:dispatch:delete'" type="text" size="mini" class="danger-text" @click="handleDelete(s.row)">删除</el-button>
          <el-dropdown trigger="click" @command="(cmd) => handleCommand(cmd, s.row)">
            <span class="el-dropdown-link">更多<i class="el-icon-arrow-down el-icon--right" /></span>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-if="s.row.status === 0" v-permission="'production:dispatch:edit'" command="confirm">确认派工</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1" v-permission="'production:dispatch:edit'" command="start">开始执行</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 2" v-permission="'production:dispatch:edit'" command="complete">完成任务</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 0 || s.row.status === 1" v-permission="'production:dispatch:edit'" command="cancel">撤销</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页组件 -->
    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />
  </div>
</template>

<script>
import { getDispatchList, deleteDispatch, confirmDispatch, startDispatch, completeDispatch, cancelDispatch, exportDispatch } from '@/api/production'

export default {
  name: 'ProductionDispatchList',
  data () {
    return {
      statusOptions: { 0: '草稿', 1: '已派工', 2: '执行中', 3: '已完成', 4: '已撤销' },
      query: { dispatch_no: '', work_order_no: '', dispatcher_name: '', status: '', dateRange: [] },
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false
    }
  },
  created () { this.loadData() },
  methods: {
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.dispatch_no) p.dispatch_no = this.query.dispatch_no
      if (this.query.work_order_no) p.work_order_no = this.query.work_order_no
      if (this.query.dispatcher_name) p.dispatcher_name = this.query.dispatcher_name
      if (this.query.status !== '' && this.query.status !== null) p.status = this.query.status
      if (this.query.dateRange && this.query.dateRange.length === 2) {
        p.start_date = this.query.dateRange[0]
        p.end_date = this.query.dateRange[1]
      }
      return p
    },
    async loadData () {
      this.loading = true
      try {
        const r = await getDispatchList(this.buildParams())
        if (r.code === 0 && r.data) {
          this.list = r.data.list || []
          this.total = r.data.total || 0
        }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () { this.query = { dispatch_no: '', work_order_no: '', dispatcher_name: '', status: '', dateRange: [] }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    handleDelete (row) {
      this.$confirm('确认删除该派工单吗？删除后不可恢复', '删除派工', { type: 'warning' }).then(async () => {
        try { const r = await deleteDispatch(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadData() } else this.$message.error(r.msg || '删除失败') } catch (e) {}
      }).catch(() => {})
    },
    handleCommand (cmd, row) {
      const actionMap = {
        confirm: { api: confirmDispatch, tip: '确认派工后，工单状态将变为「已派工」且不可再编辑，是否确认？', title: '确认派工' },
        start: { api: startDispatch, tip: '确认开始执行？工单状态将变为「进行中」。', title: '开始执行' },
        complete: { api: completeDispatch, tip: '确认所有工序任务已完成？工单状态将变为「待质检」。', title: '完成任务' },
        cancel: { api: cancelDispatch, tip: '确认撤销该派工单？工单将恢复为「待派工」。', title: '撤销派工' }
      }
      const m = actionMap[cmd]
      if (!m) return
      this.$confirm(m.tip, m.title, { type: 'warning' }).then(async () => {
        try {
          const r = await m.api(row.id)
          if (r.code === 0) { this.$message.success(r.msg || '操作成功'); this.loadData() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    async handleExport () {
      this.exporting = true
      try {
        const params = { ...this.buildParams() }
        delete params.page
        delete params.pageSize
        const r = await exportDispatch(params)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          const d = new Date()
          const pad = n => String(n).padStart(2, '0')
          a.href = url
          a.download = `工单派工列表_${d.getFullYear()}${pad(d.getMonth() + 1)}${pad(d.getDate())}_${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}.xlsx`
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
.toolbar-right { display: flex; align-items: center; }
.total-text { color: #909399; font-size: 14px; }
.link-blue { color: #409EFF; cursor: pointer; }
.danger-text { color: #F56C6C; }
.el-dropdown-link { cursor: pointer; color: #409EFF; font-size: 13px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
</style>
