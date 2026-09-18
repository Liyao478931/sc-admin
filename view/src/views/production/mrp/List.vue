<!--
  文件：admin/src/views/production/mrp/List.vue
  功能：MRP物料需求计划 - 运算批次列表（搜索/分页/执行运算/详情/导出/删除）
  权限：production:mrp:view/run/delete/export
-->
<template>
  <div class="mrp-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>生产管理</el-breadcrumb-item>
      <el-breadcrumb-item>生产计划</el-breadcrumb-item>
      <el-breadcrumb-item>物料需求计划</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索区 -->
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="批次编号">
          <el-input v-model="queryParams.run_no" placeholder="请输入批次编号" clearable style="width:170px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="运算名称">
          <el-input v-model="queryParams.run_name" placeholder="请输入运算名称" clearable style="width:170px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="queryParams.status" placeholder="全部" clearable style="width:100px" @change="handleSearch">
            <el-option label="全部" value="" />
            <el-option label="计算中" value="1" />
            <el-option label="完成" value="2" />
            <el-option label="部分失败" value="3" />
          </el-select>
        </el-form-item>
        <el-form-item label="运算时间">
          <el-date-picker v-model="timeRange" type="datetimerange" range-separator="至" start-placeholder="开始时间" end-placeholder="结束时间" value-format="yyyy-MM-dd HH:mm:ss" style="width:320px" @change="handleSearch" />
        </el-form-item>
        <div class="filter-btns">
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </div>
      </el-form>
    </el-card>

    <!-- 工具栏 + 表格 -->
    <el-card shadow="never">
      <div class="toolbar">
        <el-button v-permission="'production:mrp:run'" type="primary" size="small" icon="el-icon-cpu" :loading="running" @click="openRunDialog">执行MRP运算</el-button>
        <el-button size="small" icon="el-icon-refresh" @click="getList">刷新</el-button>
        <span class="flex-1"></span>
        <span class="total-tip">共 {{ total }} 条</span>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe border>
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column prop="run_no" label="批次编号" width="150" align="center">
          <template slot-scope="s"><span class="link-text" @click="viewDetail(s.row.id)">{{ s.row.run_no }}</span></template>
        </el-table-column>
        <el-table-column prop="run_name" label="运算名称" min-width="160" show-overflow-tooltip />
        <el-table-column label="范围" width="100" align="center">
          <template slot-scope="s">{{ s.row.scope_type === 1 ? '全部在产工单' : '指定工单' }}</template>
        </el-table-column>
        <el-table-column label="状态" width="90" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="s.row.status === 2 ? 'success' : (s.row.status === 3 ? 'warning' : 'info')">{{ s.row.status_text }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="total_orders" label="工单数" width="70" align="center" />
        <el-table-column prop="total_items" label="物料数" width="70" align="center" />
        <el-table-column prop="total_demand" label="毛需求" width="110" align="right" />
        <el-table-column prop="total_net" label="净需求" width="110" align="right" />
        <el-table-column prop="total_suggest" label="建议数" width="70" align="center" />
        <el-table-column prop="no_bom_products" label="无BOM产品" min-width="120" show-overflow-tooltip>
          <template slot-scope="s"><span v-if="s.row.no_bom_products" class="warn-text">{{ s.row.no_bom_products }}</span><span v-else>-</span></template>
        </el-table-column>
        <el-table-column prop="created_by_name" label="创建人" width="90" align="center" />
        <el-table-column prop="create_time" label="运算时间" width="160" align="center" />
        <el-table-column label="操作" width="150" align="center" fixed="right">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="viewDetail(s.row.id)">详情</el-button>
            <el-button v-permission="'production:mrp:export'" type="text" size="mini" @click="handleExport(s.row.id)">导出</el-button>
            <el-button v-permission="'production:mrp:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row.id)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        class="pager"
        background
        layout="total, sizes, prev, pager, next, jumper"
        :total="total"
        :page-sizes="[10, 20, 50, 100]"
        :page-size="queryParams.pageSize"
        :current-page="queryParams.page"
        @current-change="handlePageChange"
        @size-change="handleSizeChange"
      />
    </el-card>

    <!-- 执行MRP运算弹窗 -->
    <el-dialog title="执行 MRP 物料需求运算" :visible.sync="runVisible" width="620px" @closed="resetRunForm">
      <el-form ref="runForm" :model="runForm" :rules="runRules" label-width="110px" size="small">
        <el-form-item label="运算范围" prop="scope_type">
          <el-radio-group v-model="runForm.scope_type">
            <el-radio :label="1">全部在产工单</el-radio>
            <el-radio :label="2">指定工单</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="runForm.scope_type === 2" label="选择工单" prop="order_ids">
          <el-select v-model="runForm.order_ids" multiple filterable collapse-tags placeholder="请选择生产工单" style="width:100%">
            <el-option v-for="o in orderOptions" :key="o.id" :label="`${o.order_no}（${o.product_name} × ${o.plan_quantity}）`" :value="o.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="运算名称">
          <el-input v-model="runForm.run_name" placeholder="默认：MRP物料需求计划-时间" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="runForm.remark" type="textarea" :rows="2" placeholder="选填" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="runVisible = false">取消</el-button>
        <el-button type="primary" size="small" :loading="running" @click="handleRun">开始运算</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getMrpList, runMrp, deleteMrp, exportMrp, getOrderList } from '../../../api/production'

export default {
  name: 'ProductionMrpList',
  data() {
    return {
      loading: false,
      running: false,
      list: [],
      total: 0,
      timeRange: [],
      queryParams: { page: 1, pageSize: 10, run_no: '', run_name: '', status: '', start_time: '', end_time: '' },
      runVisible: false,
      runForm: { scope_type: 1, order_ids: [], run_name: '', remark: '' },
      runRules: {
        scope_type: [{ required: true, message: '请选择运算范围', trigger: 'change' }],
        order_ids: [{ required: true, type: 'array', message: '请选择工单', trigger: 'change' }]
      },
      orderOptions: []
    }
  },
  created() {
    this.getList()
    this.loadOrders()
  },
  methods: {
    buildParams() {
      const p = { ...this.queryParams }
      if (this.timeRange && this.timeRange.length === 2) { p.start_time = this.timeRange[0]; p.end_time = this.timeRange[1] } else { p.start_time = ''; p.end_time = '' }
      return p
    },
    async getList() {
      this.loading = true
      try {
        const r = await getMrpList(this.buildParams())
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) { this.$message.error('加载列表失败') }
      this.loading = false
    },
    async loadOrders() {
      try {
        const r = await getOrderList({ page: 1, pageSize: 200 })
        if (r.code === 0) this.orderOptions = (r.data.list || []).filter(o => [0, 1, 2].includes(o.status))
      } catch (e) {}
    },
    handleSearch() { this.queryParams.page = 1; this.getList() },
    handleReset() {
      this.queryParams = { page: 1, pageSize: this.queryParams.pageSize, run_no: '', run_name: '', status: '', start_time: '', end_time: '' }
      this.timeRange = []
      this.handleSearch()
    },
    handlePageChange(p) { this.queryParams.page = p; this.getList() },
    handleSizeChange(size) { this.queryParams.pageSize = size; this.queryParams.page = 1; this.getList() },
    openRunDialog() {
      this.runForm = { scope_type: 1, order_ids: [], run_name: '', remark: '' }
      this.runVisible = true
    },
    resetRunForm() { this.$refs.runForm && this.$refs.runForm.clearValidate() },
    async handleRun() {
      try { await this.$refs.runForm.validate() } catch (e) { return }
      this.running = true
      try {
        const data = {
          scope_type: this.runForm.scope_type,
          run_name: this.runForm.run_name,
          remark: this.runForm.remark
        }
        if (this.runForm.scope_type === 2) data.order_ids = (this.runForm.order_ids || []).join(',')
        const r = await runMrp(data)
        if (r.code === 0) {
          this.$message.success('运算完成，共生成 ' + (r.data.total_items || 0) + ' 条物料需求')
          if (r.data.no_bom_products) this.$message.warning('以下产品无BOM：' + r.data.no_bom_products)
          this.runVisible = false
          this.getList()
          this.$router.push('/production/mrp/detail/' + r.data.run_id)
        } else { this.$message.error(r.msg || '运算失败') }
      } catch (e) { this.$message.error('运算失败') }
      this.running = false
    },
    viewDetail(id) { this.$router.push(`/production/mrp/detail/${id}`) },
    handleExport(id) {
      exportMrp(id).then(res => {
        const blob = new Blob([res], { type: 'text/csv;charset=utf-8' })
        const link = document.createElement('a')
        link.href = URL.createObjectURL(blob)
        link.download = 'MRP_' + id + '.csv'
        link.click()
      })
    },
    handleDelete(id) {
      this.$confirm('确认删除该运算批次及其需求明细？', '提示', { type: 'warning' }).then(async () => {
        const r = await deleteMrp(id)
        if (r.code === 0) { this.$message.success('删除成功'); this.getList() } else { this.$message.error(r.msg || '删除失败') }
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
.breadcrumb { margin-bottom: 12px; }
.filter-card { margin-bottom: 12px; }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.total-tip { color: #909399; font-size: 13px; }
.link-text { color: #409EFF; cursor: pointer; }
.link-text:hover { text-decoration: underline; }
.warn-text { color: #E6A23C; font-size: 12px; }
.danger { color: #F56C6C; }
.pager { margin-top: 12px; text-align: right; }
</style>
