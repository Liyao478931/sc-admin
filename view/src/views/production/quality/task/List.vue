<!--
  文件：admin/src/views/production/quality/task/List.vue
  功能：检验任务列表（筛选/执行检验/编辑/删除/详情）
  权限：quality:task:view 及各项操作权限
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>质量管理</el-breadcrumb-item>
      <el-breadcrumb-item>检验任务</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="检验单编号"><el-input v-model="query.inspection_no" placeholder="请输入检验单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="工单编号"><el-input v-model="query.work_order_no" placeholder="请输入工单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="产品名称"><el-input v-model="query.product_name" placeholder="请输入产品名称" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="检验结果">
          <el-select v-model="query.result" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in resultOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="检验状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in statusOptions" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="检验日期">
          <el-date-picker v-model="query.dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始" end-placeholder="结束" style="width:230px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'quality:task:add'" type="primary" size="small" icon="el-icon-plus" @click="$router.push('/production/quality/task/add')">新增检验</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="loadData">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无检验任务">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="检验单编号" width="150">
        <template slot-scope="s"><span class="link-blue" @click="$router.push(`/production/quality/task/detail/${s.row.id}`)">{{ s.row.inspection_no }}</span></template>
      </el-table-column>
      <el-table-column label="关联工单" width="140">
        <template slot-scope="s"><span class="link-blue" @click="$router.push(`/production/plan/order/detail/${s.row.work_order_id}`)">{{ s.row.work_order_no }}</span></template>
      </el-table-column>
      <el-table-column prop="product_name" label="产品名称" min-width="130" show-overflow-tooltip />
      <el-table-column prop="standard_name" label="质检标准" min-width="130" show-overflow-tooltip />
      <el-table-column prop="inspector_name" label="质检员" width="80" />
      <el-table-column prop="inspection_date" label="检验日期" width="100" align="center" />
      <el-table-column label="检验结果" width="90" align="center">
        <template slot-scope="s"><el-tag :type="s.row.result_tag" size="mini">{{ s.row.result_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="检验状态" width="90" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="220" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="$router.push(`/production/quality/task/detail/${s.row.id}`)">查看详情</el-button>
          <el-button v-if="s.row.status === 0" v-permission="'quality:task:edit'" type="text" size="mini" @click="$router.push(`/production/quality/task/add?id=${s.row.id}`)">编辑</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 1" v-permission="'quality:task:execute'" type="text" size="mini" @click="handleExecute(s.row)">执行检验</el-button>
          <el-button v-if="s.row.status === 0" v-permission="'quality:task:delete'" type="text" size="mini" class="danger-text" @click="handleDelete(s.row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />
  </div>
</template>

<script>
import { getQualityTaskList, executeQualityTask, deleteQualityTask } from '@/api/production'

export default {
  name: 'QualityTaskList',
  data () {
    return {
      resultOptions: { 1: '合格', 2: '不合格', 3: '待判定' },
      statusOptions: { 0: '待检验', 1: '检验中', 2: '已完成' },
      query: { inspection_no: '', work_order_no: '', product_name: '', result: '', status: '', dateRange: [] },
      list: [], total: 0, page: 1, pageSize: 10, loading: false
    }
  },
  created () { this.loadData() },
  methods: {
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      if (this.query.inspection_no) p.inspection_no = this.query.inspection_no
      if (this.query.work_order_no) p.work_order_no = this.query.work_order_no
      if (this.query.product_name) p.product_name = this.query.product_name
      if (this.query.result !== '' && this.query.result !== null) p.result = this.query.result
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
        const r = await getQualityTaskList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.loadData() },
    handleReset () { this.query = { inspection_no: '', work_order_no: '', product_name: '', result: '', status: '', dateRange: [] }; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.loadData() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.loadData() },
    handleExecute (row) {
      this.$confirm(`确认执行检验单 ${row.inspection_no}？执行后判定为「${row.result_label}」并联动工单与接收单状态。`, '执行检验', { type: 'warning' }).then(async () => {
        try {
          const r = await executeQualityTask(row.id)
          if (r.code === 0) { this.$message.success(r.msg || '执行完成'); this.loadData() } else this.$message.error(r.msg || '执行失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleDelete (row) {
      this.$confirm('确认删除该检验单吗？', '删除检验', { type: 'warning' }).then(async () => {
        try { const r = await deleteQualityTask(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadData() } else this.$message.error(r.msg) } catch (e) {}
      }).catch(() => {})
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
