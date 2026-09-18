<!--
  文件：admin/src/views/warehouse/parts/purchase-in/List.vue
  功能：采购入库列表（查看/编辑/删除/确认入库/导出）
  权限：warehouse:purchase:in:view/add/edit/delete/confirm/export
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>配件出入库</el-breadcrumb-item>
      <el-breadcrumb-item>采购入库</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="100px" @submit.native.prevent>
        <el-form-item label="入库单编号"><el-input v-model="q.in_no" placeholder="请输入入库单编号" clearable style="width:170px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="采购到货单"><el-input v-model="q.arrival_no" placeholder="请输入采购到货单编号" clearable style="width:170px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="供应商"><el-input v-model="q.supplier_name" placeholder="请输入供应商名称" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="入库状态">
          <el-select v-model="q.status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in STATUS_TYPES" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="入库日期">
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始" end-placeholder="结束" value-format="yyyy-MM-dd" style="width:230px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </div>

    <div class="toolbar">
      <div class="toolbar-left">
        <el-button v-permission="'warehouse:purchase:in:add'" type="primary" size="small" icon="el-icon-plus" @click="$router.push('/warehouse/parts/purchase-in/add')">新增入库单</el-button>
        <el-button v-permission="'warehouse:purchase:in:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="入库单编号" width="150">
        <template slot-scope="s"><span class="link" @click="goDetail(s.row)">{{ s.row.in_no }}</span></template>
      </el-table-column>
      <el-table-column label="关联采购到货单" width="140">
        <template slot-scope="s"><span class="link" @click="goArrival(s.row)">{{ s.row.arrival_no || '-' }}</span></template>
      </el-table-column>
      <el-table-column prop="supplier_name" label="供应商" width="130" show-overflow-tooltip />
      <el-table-column prop="warehouse_name" label="入库仓库" width="120" show-overflow-tooltip />
      <el-table-column prop="in_date" label="入库日期" width="120" />
      <el-table-column prop="in_user_name" label="入库人" width="90" />
      <el-table-column label="入库状态" width="90" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="200" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="goDetail(s.row)">查看详情</el-button>
          <el-button v-if="s.row.status === 0" v-permission="'warehouse:purchase:in:edit'" type="text" size="mini" @click="$router.push('/warehouse/parts/purchase-in/edit/' + s.row.id)">编辑</el-button>
          <el-button v-if="s.row.status === 0" v-permission="'warehouse:purchase:in:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          <el-button v-if="s.row.status === 1" v-permission="'warehouse:purchase:in:reverse'" type="text" size="mini" class="danger" @click="openReverse(s.row)">冲销入库</el-button>
          <el-dropdown v-if="s.row.status === 0" trigger="click" @command="cmd => handleMore(cmd, s.row)">
            <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right"></i></el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-permission="'warehouse:purchase:in:confirm'" command="confirm">确认入库</el-dropdown-item>
              <el-dropdown-item command="print">打印入库单</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="p => { page = p; getList() }" @size-change="s => { pageSize = s; page = 1; getList() }" />

    <!-- 冲销入库弹窗 -->
    <el-dialog title="冲销入库" :visible="reverseVisible" @update:visible="v => reverseVisible = v" width="460px" top="8vh">
      <el-alert type="warning" :closable="false" show-icon title="冲销后将恢复库存并删除流水记录，此操作不可逆" style="margin-bottom:12px" />
      <el-input v-model="reverseReason" type="textarea" :rows="3" placeholder="请填写冲销原因（必填）" />
      <span slot="footer">
        <el-button size="small" @click="reverseVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="reversing" @click="handleReverse">确认冲销</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getPurchaseInList, deletePurchaseIn, confirmPurchaseIn, exportPurchaseIn, reversePurchaseIn } from '../../../../api/warehouse'

const STATUS_TYPES = { 0: '草稿', 1: '已入库', 2: '已撤销', 3: '已冲销' }

export default {
  name: 'WarehousePurchaseInList',
  data () {
    return {
      STATUS_TYPES,
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false,
      q: { in_no: '', arrival_no: '', supplier_name: '', status: '' },
      dateRange: null,
      reverseVisible: false, reverseReason: '', reversing: false, reverseRow: null
    }
  },
  created () { this.getList() },
  methods: {
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize }
      Object.keys(this.q).forEach(k => { if (this.q[k] !== '' && this.q[k] !== null) p[k] = this.q[k] })
      if (this.dateRange && this.dateRange.length === 2) { p.start_date = this.dateRange[0]; p.end_date = this.dateRange[1] }
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getPurchaseInList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.q = { in_no: '', arrival_no: '', supplier_name: '', status: '' }; this.dateRange = null; this.handleSearch() },
    goDetail (row) { this.$router.push('/warehouse/parts/purchase-in/detail/' + row.id) },
    goArrival (row) { if (row.arrival_id) this.$router.push('/business/purchase/arrival/detail/' + row.arrival_id) },
    handleDelete (row) {
      this.$confirm('确认删除该采购入库单吗？删除后不可恢复', '提示', { type: 'warning' }).then(async () => {
        try {
          const r = await deletePurchaseIn(row.id)
          if (r.code === 0) { this.$message.success('删除成功'); this.getList() } else this.$message.error(r.msg || '删除失败')
        } catch (e) {}
      }).catch(() => {})
    },
    handleMore (cmd, row) {
      if (cmd === 'confirm') {
        this.$confirm('确认入库将执行库存增加、流水记录与成本核算，确认继续吗？', '确认入库', { type: 'warning' }).then(() => this.doConfirm(row)).catch(() => {})
      } else if (cmd === 'print') {
        this.$router.push('/warehouse/parts/purchase-in/detail/' + row.id + '?print=1')
      }
    },
    async doConfirm (row) {
      this.$message({ message: '正在处理入库，请稍候...', type: 'info', duration: 0 })
      try {
        const r = await confirmPurchaseIn(row.id)
        this.$message.closeAll()
        if (r.code === 0) { this.$message.success(r.msg || '入库成功'); this.getList() } else this.$message.error(r.msg || '入库失败')
      } catch (e) { this.$message.closeAll() }
    },
    async handleExport () {
      this.exporting = true
      try {
        const resp = await exportPurchaseIn(this.buildParams())
        const url = window.URL.createObjectURL(new Blob([resp.data]))
        const a = document.createElement('a')
        a.href = url; a.download = '采购入库单列表_' + new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14) + '.xlsx'
        a.click(); window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') } finally { this.exporting = false }
    },
    openReverse (row) {
      this.reverseRow = row
      this.reverseReason = ''
      this.reverseVisible = true
    },
    async handleReverse () {
      if (!this.reverseReason.trim()) { this.$message.warning('请填写冲销原因'); return }
      this.reversing = true
      try {
        const r = await reversePurchaseIn(this.reverseRow.id, this.reverseReason)
        if (r.code === 0) { this.$message.success('冲销成功'); this.reverseVisible = false; this.getList() } else this.$message.error(r.msg || '冲销失败')
      } catch (e) {} finally { this.reversing = false }
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
.link { color: #409EFF; cursor: pointer; }
</style>
