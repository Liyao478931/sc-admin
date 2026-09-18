<!--
  文件：admin/src/views/warehouse/check/plan/List.vue
  功能：盘点计划列表（审核走统一审批）
  权限：warehouse:check:plan:view / add / delete / execute / export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>库存盘点</el-breadcrumb-item>
      <el-breadcrumb-item>盘点计划</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="计划编号"><el-input v-model="query.plan_no" placeholder="请输入计划编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="计划名称"><el-input v-model="query.plan_name" placeholder="请输入计划名称" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="盘点仓库">
          <el-select v-model="query.warehouse_id" clearable placeholder="全部" style="width:140px">
            <el-option v-for="w in warehouses" :key="w.id" :label="w.warehouse_name" :value="w.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="盘点类型">
          <el-select v-model="query.plan_type" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in typeOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="计划状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in statusOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="计划日期">
          <el-date-picker v-model="query.dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:220px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'warehouse:check:plan:add'" type="primary" size="small" icon="el-icon-plus" @click="$router.push('/warehouse/check/plan/add')">新增计划</el-button>
        <el-button v-permission="'warehouse:check:plan:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无盘点计划">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="计划编号" width="150">
        <template slot-scope="s"><span class="link-blue" @click="$router.push(`/warehouse/check/plan/detail/${s.row.id}`)">{{ s.row.plan_no }}</span></template>
      </el-table-column>
      <el-table-column prop="plan_name" label="计划名称" min-width="160" show-overflow-tooltip />
      <el-table-column label="盘点类型" width="110" align="center">
        <template slot-scope="s"><el-tag :type="s.row.plan_type_tag" size="mini">{{ s.row.plan_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="warehouse_name" label="盘点仓库" width="130" />
      <el-table-column label="盘点方式" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.inventory_method_tag" size="mini">{{ s.row.inventory_method_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="plan_date_range" label="计划日期" width="200" />
      <el-table-column prop="responsible_person_name" label="负责人" width="90" />
      <el-table-column label="计划状态" width="110" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="260" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="$router.push(`/warehouse/check/plan/detail/${s.row.id}`)">查看详情</el-button>
          <el-button v-if="s.row.status === 0" v-permission="'warehouse:check:plan:edit'" type="text" size="mini" @click="$router.push(`/warehouse/check/plan/edit/${s.row.id}`)">编辑</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 5" v-permission="'warehouse:check:plan:delete'" type="text" size="mini" class="danger-text" @click="handleDelete(s.row)">删除</el-button>
          <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
            <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right" /></el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-if="s.row.status === 0" command="submit">提交审批</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 2" command="start">开始执行</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 3" command="complete">完成任务</el-dropdown-item>
              <el-dropdown-item v-if="[0, 1, 2].includes(s.row.status)" command="cancel" divided>取消计划</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1" disabled>审核中（统一审批待办）</el-dropdown-item>
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
import { getPlanList, deletePlan, submitPlan, cancelPlan, startPlan, completePlan, exportPlan, getWarehouseList } from '@/api/warehouse'

export default {
  name: 'InventoryPlanList',
  data () {
    return {
      typeOptions: { 1: '全盘', 2: '抽盘', 3: '循环盘点' },
      statusOptions: { 0: '草稿', 1: '待审核', 2: '已审核', 3: '执行中', 4: '已完成', 5: '已取消' },
      query: { plan_no: '', plan_name: '', warehouse_id: null, plan_type: '', status: '', dateRange: [] },
      warehouses: [],
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false
    }
  },
  created () { this.loadData(); this.loadWarehouses() },
  methods: {
    async loadWarehouses () {
      try {
        const r = await getWarehouseList({ status: 1, page: 1, pageSize: 100 })
        if (r.code === 0) this.warehouses = (r.data && r.data.list) || []
      } catch (e) {}
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.plan_no) p.plan_no = this.query.plan_no
      if (this.query.plan_name) p.plan_name = this.query.plan_name
      if (this.query.warehouse_id) p.warehouse_id = this.query.warehouse_id
      if (this.query.plan_type !== '' && this.query.plan_type !== null) p.plan_type = this.query.plan_type
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
        const r = await getPlanList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () { this.query = { plan_no: '', plan_name: '', warehouse_id: null, plan_type: '', status: '', dateRange: [] }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    handleDelete (row) {
      this.$confirm('确认删除该盘点计划吗？删除后不可恢复', '删除盘点计划', { type: 'warning' }).then(async () => {
        try {
          const r = await deletePlan(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.loadData() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleMore (cmd, row) {
      const actions = {
        submit: { msg: '确认提交该盘点计划审批吗？提交后将进入统一审批待办审核', fn: () => submitPlan(row.id), ok: '已提交审批' },
        start: { msg: '确认开始执行该盘点计划吗？', fn: () => startPlan(row.id), ok: '已开始执行' },
        complete: { msg: '确认完成该盘点计划吗？完成后生成盘点结果', fn: () => completePlan(row.id), ok: '盘点已完成' },
        cancel: { msg: '确认取消该盘点计划吗？', fn: () => cancelPlan(row.id), ok: '已取消' }
      }
      const a = actions[cmd]
      if (!a) return
      this.$confirm(a.msg, '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await a.fn()
          if (r.code === 0) { this.$message.success(r.msg || a.ok); this.loadData() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    async handleExport () {
      this.exporting = true
      try {
        const response = await exportPlan(this.buildParams())
        const url = URL.createObjectURL(new Blob([response.data]))
        const link = document.createElement('a')
        link.href = url
        link.download = '盘点计划_' + new Date().toISOString().slice(0, 19).replace(/[-:T]/g, '') + '.xlsx'
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
.search-bar { background: #fff; padding: 16px 20px 4px; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.link-blue { color: #409EFF; cursor: pointer; }
.danger-text { color: #F56C6C; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
</style>
