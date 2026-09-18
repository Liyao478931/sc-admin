<!--
  文件：admin/src/views/warehouse/parts/return/List.vue
  功能：配件退库管理（列表/搜索/审核/确认退库/撤销/删除）
  权限：warehouse:return:view/add/edit/delete/audit/confirm/export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>配件出入库</el-breadcrumb-item>
      <el-breadcrumb-item>配件退库</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索筛选 -->
    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="退库单编号"><el-input v-model="query.return_no" placeholder="请输入退库单编号" clearable style="width:170px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="领料单编号"><el-input v-model="query.pick_no" placeholder="请输入领料单编号" clearable style="width:170px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="退库部门">
          <el-select v-model="query.department_id" clearable filterable placeholder="全部" style="width:150px">
            <el-option v-for="d in departmentOptions" :key="d.id" :label="d.name" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="退库类型">
          <el-select v-model="query.return_type" clearable placeholder="全部" style="width:120px">
            <el-option v-for="(t, v) in RETURN_TYPES" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="退库日期">
          <el-date-picker v-model="dateRange" type="daterange" value-format="yyyy-MM-dd" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" style="width:240px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <!-- 操作栏 -->
    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'warehouse:return:add'" type="primary" size="small" icon="el-icon-plus" @click="handleAdd">新增退库单</el-button>
        <el-button v-permission="'warehouse:return:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <!-- 数据表格 -->
    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无退库单数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="退库单编号" width="150">
        <template slot-scope="s"><el-link type="primary" @click="goDetail(s.row)">{{ s.row.return_no }}</el-link></template>
      </el-table-column>
      <el-table-column label="退库类型" width="110" align="center">
        <template slot-scope="s"><el-tag :type="s.row.return_type_tag" effect="plain" size="mini">{{ s.row.return_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="关联领料单" width="140">
        <template slot-scope="s"><el-link v-if="s.row.pick_no" type="primary" @click="goPickDetail(s.row)">{{ s.row.pick_no }}</el-link><span v-else>-</span></template>
      </el-table-column>
      <el-table-column prop="department_name" label="退库部门" width="120" />
      <el-table-column prop="returner_name" label="退库人" width="90" align="center" />
      <el-table-column prop="return_date" label="退库日期" width="110" align="center" />
      <el-table-column prop="item_count" label="物料种类数" width="100" align="center" />
      <el-table-column prop="total_quantity" label="总数量" width="100" align="center" />
      <el-table-column label="状态" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="240" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="goDetail(s.row)">详情</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 4" v-permission="'warehouse:return:edit'" type="text" size="mini" @click="handleEdit(s.row)">编辑</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 4" v-permission="'warehouse:return:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
            <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right" /></el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-if="s.row.status === 0" command="submit" icon="el-icon-upload2">提交审核</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1" v-permission="'warehouse:return:audit'" command="approve" icon="el-icon-check">审核通过</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1" v-permission="'warehouse:return:audit'" command="reject" icon="el-icon-close">审核驳回</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 2" v-permission="'warehouse:return:confirm'" command="confirm" icon="el-icon-box">确认退库</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 0 || s.row.status === 1" command="cancel" icon="el-icon-refresh-left">撤销申请</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
        </template>
      </el-table-column>
    </el-table>

    <!-- 分页 -->
    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />
  </div>
</template>

<script>
import {
  getReturnList, deleteReturn, submitReturn, cancelReturn, approveReturn, rejectReturn, confirmReturn, exportReturn
} from '../../../../api/warehouse'
import { getDepartmentList } from '../../../../api/organization'

const RETURN_TYPES = { 1: '生产退库', 2: '维修退库', 3: '质量退库', 4: '其他退库' }
const RETURN_TAGS = { 1: 'primary', 2: 'warning', 3: 'danger', 4: 'info' }
const STATUS_TEXT = { 0: '草稿', 1: '待审核', 2: '已审核', 3: '已退库', 4: '已驳回', 5: '已撤销' }

export default {
  name: 'WarehouseReturnList',
  data () {
    return {
      RETURN_TYPES, RETURN_TAGS, STATUS_TEXT,
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false,
      query: { return_no: '', pick_no: '', department_id: '', return_type: '', status: '' },
      dateRange: [], departmentOptions: []
    }
  },
  created () {
    this.getList()
    this.loadDepartments()
  },
  methods: {
    async loadDepartments () {
      try {
        const r = await getDepartmentList()
        this.departmentOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : ((r.code === 0 && Array.isArray(r.data)) ? r.data : [])
      } catch (e) { this.departmentOptions = [] }
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
        const r = await getReturnList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () {
      this.query = { return_no: '', pick_no: '', department_id: '', return_type: '', status: '' }
      this.dateRange = []
      this.handleSearch()
    },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.getList() },
    goDetail (row) { this.$router.push({ path: `/warehouse/parts/return/detail/${row.id}` }) },
    goPickDetail (row) { this.$router.push({ path: `/warehouse/parts/pick/detail/${row.pick_id}` }) },
    handleAdd () { this.$router.push({ path: '/warehouse/parts/return/add' }) },
    handleEdit (row) { this.$router.push({ path: `/warehouse/parts/return/edit/${row.id}` }) },
    handleDelete (row) {
      this.$confirm('确认删除该退库单吗？删除后不可恢复', '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteReturn(row.id)
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
      this.$confirm(`确认提交退库单 ${row.return_no} 审核吗？提交后不可再编辑。`, '提交审核', { type: 'warning' }).then(async () => {
        try {
          const r = await submitReturn(row.id)
          if (r.code === 0) { this.$message.success('已提交审核'); this.getList() } else this.$message.error(r.msg || '提交失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleApprove (row) {
      this.$prompt('请输入审核备注（可选）', '审核通过', { inputPlaceholder: '审核备注', inputValue: '' }).then(async ({ value }) => {
        try {
          const r = await approveReturn(row.id, value || '')
          if (r.code === 0) { this.$message.success('审核已通过'); this.getList() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleReject (row) {
      this.$prompt('请输入驳回原因（必填）', '审核驳回', { inputPlaceholder: '驳回原因', inputValidator: v => (v && v.trim()) || '驳回原因必填' }).then(async ({ value }) => {
        try {
          const r = await rejectReturn(row.id, (value || '').trim())
          if (r.code === 0) { this.$message.success('已驳回'); this.getList() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleConfirm (row) {
      this.$confirm(`确认退库单 ${row.return_no} 确认退库吗？将执行入库操作（增加库存、生成流水）。`, '确认退库', { type: 'warning' }).then(async () => {
        try {
          const r = await confirmReturn(row.id)
          if (r.code === 0) { this.$message.success(r.msg || '退库成功'); this.getList() } else this.$message.error(r.msg || '退库失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleCancel (row) {
      this.$confirm(`确认撤销退库单 ${row.return_no} 吗？`, '撤销申请', { type: 'warning' }).then(async () => {
        try {
          const r = await cancelReturn(row.id)
          if (r.code === 0) { this.$message.success('已撤销'); this.getList() } else this.$message.error(r.msg || '操作失败')
        } catch (e) {}
      }).catch(() => {})
    },
    async handleExport () {
      this.exporting = true
      try {
        const r = await exportReturn(this.buildParams())
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `配件退库_${new Date().toLocaleDateString()}.xlsx`
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
