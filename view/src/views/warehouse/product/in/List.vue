<!--
  文件：admin/src/views/warehouse/product/in/List.vue
  功能：产品入库（上架确认）管理（列表/搜索/审核/确认入库/撤销/删除/导出）
  权限：warehouse:product:in:view/add/edit/delete/audit/confirm/export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>设备出入库</el-breadcrumb-item>
      <el-breadcrumb-item>产品入库</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="90px" @submit.native.prevent>
        <el-form-item label="入库单编号"><el-input v-model="query.in_no" placeholder="请输入入库单编号" clearable style="width:170px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="来源单据编号"><el-input v-model="query.source_no" placeholder="请输入来源单据编号" clearable style="width:170px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="产品名称"><el-input v-model="query.product_name" placeholder="请输入产品名称" clearable style="width:170px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="入库仓库">
          <el-select v-model="query.warehouse_id" clearable filterable placeholder="全部" style="width:140px">
            <el-option v-for="w in warehouseOptions" :key="w.id" :label="w.warehouse_name" :value="w.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="来源类型">
          <el-select v-model="query.source_type" clearable placeholder="全部" style="width:130px">
            <el-option v-for="(t, v) in SOURCE_TYPES" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="入库日期">
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
        <el-button v-permission="'warehouse:product:in:add'" type="primary" size="small" icon="el-icon-plus" @click="handleAdd">新增入库单</el-button>
        <el-button v-permission="'warehouse:product:in:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无入库单数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="入库单编号" width="150">
        <template slot-scope="s"><el-link type="primary" @click="goDetail(s.row)">{{ s.row.in_no }}</el-link></template>
      </el-table-column>
      <el-table-column label="来源类型" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.source_type_tag" effect="plain" size="mini">{{ s.row.source_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="来源单据" width="150">
        <template slot-scope="s"><el-link v-if="s.row.source_no" type="primary" @click="goSourceDetail(s.row)">{{ s.row.source_no }}</el-link><span v-else>-</span></template>
      </el-table-column>
      <el-table-column prop="warehouse_name" label="入库仓库" width="120" />
      <el-table-column prop="in_date" label="入库日期" width="110" align="center" />
      <el-table-column prop="in_user_name" label="入库人" width="90" align="center" />
      <el-table-column label="总数量" width="100" align="right"><template slot-scope="s">{{ Number(s.row.total_quantity).toFixed(2) }}</template></el-table-column>
      <el-table-column label="总金额" width="110" align="right"><template slot-scope="s">¥ {{ Number(s.row.total_amount).toFixed(2) }}</template></el-table-column>
      <el-table-column label="状态" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="240" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="goDetail(s.row)">详情</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 4" v-permission="'warehouse:product:in:edit'" type="text" size="mini" @click="handleEdit(s.row)">编辑</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 4" v-permission="'warehouse:product:in:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
            <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right" /></el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-if="s.row.status === 0" command="submit" icon="el-icon-upload2">提交审核</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1" v-permission="'warehouse:product:in:audit'" command="approve" icon="el-icon-check">审核通过</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1" v-permission="'warehouse:product:in:audit'" command="reject" icon="el-icon-close">审核驳回</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 2" v-permission="'warehouse:product:in:confirm'" command="confirm" icon="el-icon-box">确认入库</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 0 || s.row.status === 1" command="cancel" icon="el-icon-refresh-left">撤销申请</el-dropdown-item>
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
import { getProductInList, deleteProductIn, submitProductIn, cancelProductIn, approveProductIn, rejectProductIn, confirmProductIn, exportProductIn, getWarehouseList } from '../../../../api/warehouse'

const SOURCE_TYPES = { 1: '产品接收单', 2: '调拨入库', 3: '盘盈入库', 4: '其他入库' }
const STATUS_TEXT = { 0: '草稿', 1: '待审核', 2: '已审核', 3: '已入库', 4: '已驳回', 5: '已撤销' }

export default {
  name: 'WarehouseProductInList',
  data () {
    return {
      SOURCE_TYPES, STATUS_TEXT,
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false,
      query: { in_no: '', source_no: '', product_name: '', warehouse_id: '', source_type: '', status: '' },
      dateRange: [], warehouseOptions: []
    }
  },
  created () { this.getList(); this.loadWarehouses() },
  methods: {
    async loadWarehouses () {
      try {
        const r = await getWarehouseList({ page: 1, pageSize: 100, status: 1 })
        this.warehouseOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
      } catch (e) { this.warehouseOptions = [] }
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
        const r = await getProductInList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.query = { in_no: '', source_no: '', product_name: '', warehouse_id: '', source_type: '', status: '' }; this.dateRange = []; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.getList() },
    goDetail (row) { this.$router.push({ path: `/warehouse/product/in/detail/${row.id}` }) },
    goSourceDetail (row) { this.$router.push({ path: `/business/receive/detail/${row.source_id}` }) },
    handleAdd () { this.$router.push({ path: '/warehouse/product/in/add' }) },
    handleEdit (row) { this.$router.push({ path: `/warehouse/product/in/edit/${row.id}` }) },
    handleDelete (row) {
      this.$confirm('确认删除该入库单吗？删除后不可恢复', '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteProductIn(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.getList() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleMore (cmd, row) {
      if (cmd === 'submit') this.handleSubmit(row)
      else if (cmd === 'approve') this.handleApprove(row)
      else if (cmd === 'reject') this.handleReject(row)
      else if (cmd === 'confirm') this.handleConfirm(row)
      else if (cmd === 'cancel') this.handleCancel(row)
    },
    handleSubmit (row) {
      this.$confirm(`确认提交入库单 ${row.in_no} 审核吗？提交后不可再编辑。`, '提交审核', { type: 'warning' }).then(async () => {
        try {
          const r = await submitProductIn(row.id)
          if (r.code === 0) { this.$message.success('已提交审核'); this.getList() } else this.$message.error(r.msg || '提交失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleApprove (row) {
      this.$prompt('请输入审核备注（可选）', '审核通过', { inputPlaceholder: '审核备注', inputValue: '' }).then(async ({ value }) => {
        try {
          const r = await approveProductIn(row.id, value || '')
          if (r.code === 0) { this.$message.success('审核已通过'); this.getList() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleReject (row) {
      this.$prompt('请输入驳回原因（必填）', '审核驳回', { inputPlaceholder: '驳回原因' }).then(async ({ value }) => {
        if (!value || !value.trim()) { this.$message.warning('驳回原因必填'); return }
        try {
          const r = await rejectProductIn(row.id, value.trim())
          if (r.code === 0) { this.$message.success('已驳回'); this.getList() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleConfirm (row) {
      this.$confirm(`确认入库单 ${row.in_no} 确认上架吗？将完成货位分配与上架确认。`, '确认入库', { type: 'warning' }).then(async () => {
        try {
          const r = await confirmProductIn(row.id)
          if (r.code === 0) { this.$message.success(r.msg || '入库成功'); this.getList() } else this.$message.error(r.msg || '入库失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleCancel (row) {
      this.$confirm(`确认撤销入库单 ${row.in_no} 吗？`, '撤销申请', { type: 'warning' }).then(async () => {
        try {
          const r = await cancelProductIn(row.id)
          if (r.code === 0) { this.$message.success('已撤销'); this.getList() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    async handleExport () {
      this.exporting = true
      try {
        const r = await exportProductIn(this.buildParams())
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `产品入库_${new Date().toLocaleDateString()}.xlsx`
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
.search-bar { background: #fff; padding: 16px 20px 0; border-bottom: 1px solid #ebeef5; border-radius: 8px 8px 0 0; }
.toolbar { display: flex; justify-content: space-between; align-items: center; padding: 12px 20px; background: #fff; border-bottom: 1px solid #ebeef5; }
.toolbar-left { display: flex; gap: 10px; }
.total-text { color: #909399; font-size: 14px; }
.pager { margin-top: 20px; margin-bottom: 20px; text-align: right; }
.danger { color: #F56C6C; }
</style>
