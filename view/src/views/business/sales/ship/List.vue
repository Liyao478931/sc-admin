<!--
  文件：admin/src/views/business/sales/ship/List.vue
  功能：发货单列表（搜索/编辑/删除/确认发货/登记签收/取消/物流追踪/打印/导出 + 详情抽屉）
  权限：sales:ship:list:view/add/edit/delete/confirm/sign/export
  说明：发货单为出库完成后的正式发货凭证（无审批环节），从出库单生成
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>销售管理</el-breadcrumb-item>
      <el-breadcrumb-item>发货管理</el-breadcrumb-item>
      <el-breadcrumb-item>发货单列表</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="发货单编号"><el-input v-model="query.ship_no" placeholder="请输入发货单编号" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="出库单"><el-input v-model="query.out_no" placeholder="请输入出库单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="销售订单"><el-input v-model="query.order_no" placeholder="请输入销售订单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="客户名称"><el-input v-model="query.customer_name" placeholder="请输入客户名称" clearable style="width:140px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="物流公司"><el-input v-model="query.logistics_company" placeholder="请输入物流公司" clearable style="width:130px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="发货状态">
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
        <el-button v-permission="'sales:ship:add'" type="primary" size="small" icon="el-icon-plus" @click="handleAdd">新增发货单</el-button>
        <el-button v-permission="'sales:ship:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无发货单数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="发货单编号" width="160">
        <template slot-scope="s"><el-link type="primary" @click="openDetail(s.row)">{{ s.row.ship_no }}</el-link></template>
      </el-table-column>
      <el-table-column label="出库单" width="140">
        <template slot-scope="s"><el-link type="primary" @click="$router.push({ path: `/business/sales/out/detail/${s.row.out_id}` })">{{ s.row.out_no || '-' }}</el-link></template>
      </el-table-column>
      <el-table-column label="销售订单" width="140">
        <template slot-scope="s"><el-link type="primary" @click="$router.push({ path: '/business/order' })">{{ s.row.order_no || '-' }}</el-link></template>
      </el-table-column>
      <el-table-column prop="customer_name" label="客户名称" width="130" show-overflow-tooltip />
      <el-table-column prop="receiver" label="收货人" width="90" align="center" />
      <el-table-column label="物流信息" min-width="180">
        <template slot-scope="s">
          <span v-if="s.row.logistics_info">{{ s.row.logistics_company }} / <el-link v-if="s.row.tracking_no" type="primary" @click="openTrack(s.row)">{{ s.row.tracking_no }}</el-link><span v-else>-</span></span>
          <span v-else>-</span>
        </template>
      </el-table-column>
      <el-table-column label="发货日期" width="110" align="center"><template slot-scope="s">{{ s.row.ship_date || '-' }}</template></el-table-column>
      <el-table-column label="发货状态" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="创建时间" width="160" align="center"><template slot-scope="s">{{ s.row.created_at || '-' }}</template></el-table-column>
      <el-table-column label="操作" width="220" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="openDetail(s.row)">查看详情</el-button>
          <el-button v-if="s.row.status === 0" v-permission="'sales:ship:edit'" type="text" size="mini" @click="openEdit(s.row)">编辑</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 3" v-permission="'sales:ship:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
            <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right" /></el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-if="s.row.status === 0" v-permission="'sales:ship:confirm'" command="confirm" icon="el-icon-check">确认发货</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1" v-permission="'sales:ship:sign'" command="sign" icon="el-icon-finished">登记签收</el-dropdown-item>
              <el-dropdown-item v-if="s.row.tracking_no" command="track" icon="el-icon-truck">物流追踪</el-dropdown-item>
              <el-dropdown-item command="print" icon="el-icon-printer">打印发货单</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 0 || s.row.status === 1" command="cancel" icon="el-icon-circle-close">取消发货</el-dropdown-item>
              <el-dropdown-item v-if="!(s.row.status === 0 || s.row.status === 1)" disabled>当前状态无可执行操作</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 编辑弹窗（仅草稿可编辑物流/收货/备注） -->
    <el-dialog title="编辑发货单" :visible.sync="editVisible" width="520px">
      <el-form :model="editForm" label-width="90px" size="small">
        <el-form-item label="收货人"><el-input v-model="editForm.receiver" /></el-form-item>
        <el-form-item label="收货电话"><el-input v-model="editForm.receiver_phone" /></el-form-item>
        <el-form-item label="收货地址"><el-input v-model="editForm.receiver_address" type="textarea" :rows="2" /></el-form-item>
        <el-form-item label="发货日期"><el-date-picker v-model="editForm.ship_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
        <el-form-item label="发货方式">
          <el-select v-model="editForm.ship_method" style="width:100%">
            <el-option :value="1" label="物流" /><el-option :value="2" label="自提" /><el-option :value="3" label="快递" />
          </el-select>
        </el-form-item>
        <el-form-item label="物流公司"><el-input v-model="editForm.logistics_company" /></el-form-item>
        <el-form-item label="物流单号"><el-input v-model="editForm.tracking_no" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="editForm.remark" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <span slot="footer"><el-button size="small" @click="editVisible=false">取消</el-button><el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button></span>
    </el-dialog>

    <!-- 确认发货弹窗 -->
    <el-dialog title="确认发货" :visible.sync="confirmVisible" width="460px">
      <el-form :model="confirmForm" label-width="90px" size="small">
        <el-form-item label="发货日期"><el-date-picker v-model="confirmForm.ship_date" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
        <el-form-item label="发货方式">
          <el-select v-model="confirmForm.ship_method" style="width:100%">
            <el-option :value="1" label="物流" /><el-option :value="2" label="自提" /><el-option :value="3" label="快递" />
          </el-select>
        </el-form-item>
        <el-form-item label="物流公司"><el-input v-model="confirmForm.logistics_company" /></el-form-item>
        <el-form-item label="物流单号"><el-input v-model="confirmForm.tracking_no" /></el-form-item>
      </el-form>
      <span slot="footer"><el-button size="small" @click="confirmVisible=false">取消</el-button><el-button size="small" type="primary" :loading="saving" @click="handleConfirm">确认</el-button></span>
    </el-dialog>

    <!-- 登记签收弹窗 -->
    <el-dialog title="登记签收" :visible.sync="signVisible" width="420px">
      <el-form :model="signForm" label-width="90px" size="small">
        <el-form-item label="签收人"><el-input v-model="signForm.signer" placeholder="请输入签收人" /></el-form-item>
        <el-form-item label="签收时间"><el-date-picker v-model="signForm.sign_time" type="date" value-format="yyyy-MM-dd" style="width:100%" /></el-form-item>
      </el-form>
      <span slot="footer"><el-button size="small" @click="signVisible=false">取消</el-button><el-button size="small" type="primary" :loading="saving" @click="handleSign">确认</el-button></span>
    </el-dialog>

    <!-- 物流追踪弹窗 -->
    <el-dialog title="物流追踪" :visible.sync="trackVisible" width="460px">
      <div v-if="trackShip">
        <el-descriptions :column="1" border size="small">
          <el-descriptions-item label="物流公司">{{ trackShip.logistics_company || '-' }}</el-descriptions-item>
          <el-descriptions-item label="物流单号">{{ trackShip.tracking_no || '-' }}</el-descriptions-item>
          <el-descriptions-item label="发货日期">{{ trackShip.ship_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="收货人">{{ trackShip.receiver || '-' }}（{{ trackShip.receiver_phone || '-' }}）</el-descriptions-item>
        </el-descriptions>
        <el-alert type="info" :closable="false" show-icon title="暂未集成物流轨迹服务，当前仅展示本地物流信息。" style="margin-top:12px;" />
      </div>
    </el-dialog>

    <!-- 详情抽屉 -->
    <el-drawer :title="'发货单详情 - ' + (detail.ship_no || '')" :visible.sync="detailVisible" size="600px">
      <div class="drawer-body" v-if="detail.id">
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="发货单编号">{{ detail.ship_no }}</el-descriptions-item>
          <el-descriptions-item label="状态"><el-tag :type="detail.status_tag" size="mini">{{ detail.status_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="出库单">{{ detail.out_no || '-' }}</el-descriptions-item>
          <el-descriptions-item label="销售订单">{{ detail.order_no || '-' }}</el-descriptions-item>
          <el-descriptions-item label="客户名称">{{ detail.customer_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="收货人">{{ detail.receiver || '-' }}</el-descriptions-item>
          <el-descriptions-item label="收货电话">{{ detail.receiver_phone || '-' }}</el-descriptions-item>
          <el-descriptions-item label="发货方式">{{ detail.ship_method_label || '-' }}</el-descriptions-item>
          <el-descriptions-item label="物流公司">{{ detail.logistics_company || '-' }}</el-descriptions-item>
          <el-descriptions-item label="物流单号">{{ detail.tracking_no || '-' }}</el-descriptions-item>
          <el-descriptions-item label="发货日期">{{ detail.ship_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="签收人">{{ detail.signer || '-' }}</el-descriptions-item>
          <el-descriptions-item label="签收时间">{{ detail.sign_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建人">{{ detail.creator_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ detail.created_at || '-' }}</el-descriptions-item>
          <el-descriptions-item label="收货地址" :span="2">{{ detail.receiver_address || '-' }}</el-descriptions-item>
          <el-descriptions-item label="备注" :span="2">{{ detail.remark || '-' }}</el-descriptions-item>
        </el-descriptions>
        <h4 class="section-title">发货明细</h4>
        <el-table :data="detail.items || []" size="mini" border>
          <el-table-column prop="product_code" label="编码" width="90" />
          <el-table-column prop="product_name" label="产品" min-width="110" show-overflow-tooltip />
          <el-table-column prop="specification" label="规格" width="100" show-overflow-tooltip />
          <el-table-column prop="unit" label="单位" width="50" align="center" />
          <el-table-column prop="ship_quantity" label="发货数量" width="80" align="right" />
        </el-table>
      </div>
    </el-drawer>
  </div>
</template>

<script>
import { getShipList, getShipDetail, saveShip, deleteShip, confirmShip, signShip, cancelShip, exportShip } from '@/api/sales'

const STATUS_TEXT = { 0: '草稿', 1: '已发货', 2: '已签收', 3: '已取消', 4: '异常' }

export default {
  name: 'ShipOrderList',
  data () {
    return {
      STATUS_TEXT,
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false, saving: false,
      query: { ship_no: '', out_no: '', order_no: '', customer_name: '', logistics_company: '', status: '' },
      dateRange: [],
      editVisible: false, editForm: {}, currentEdit: null,
      confirmVisible: false, confirmForm: {}, currentConfirm: null,
      signVisible: false, signForm: {}, currentSign: null,
      trackVisible: false, trackShip: null,
      detailVisible: false, detail: {}
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
        const r = await getShipList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.query = { ship_no: '', out_no: '', order_no: '', customer_name: '', logistics_company: '', status: '' }; this.dateRange = []; this.handleSearch() },
    handleAdd () {
      this.$confirm('发货单从「已出库」的出库单生成。是否前往出库单列表，选择已出库的出库单并生成发货单？', '新增发货单', { type: 'info', confirmButtonText: '前往出库单列表' }).then(() => {
        this.$router.push({ path: '/business/sales/out/list' })
      }).catch(() => {})
    },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.getList() },
    openDetail (row) {
      getShipDetail(row.id).then(r => { if (r.code === 0 && r.data) this.detail = r.data })
      this.detailVisible = true
    },
    openEdit (row) {
      this.currentEdit = row
      this.editForm = {
        id: row.id, receiver: row.receiver || '', receiver_phone: row.receiver_phone || '',
        receiver_address: row.receiver_address || '', ship_date: row.ship_date || '',
        ship_method: row.ship_method || 1, logistics_company: row.logistics_company || '',
        tracking_no: row.tracking_no || '', remark: row.remark || ''
      }
      this.editVisible = true
    },
    handleSave () {
      this.saving = true
      saveShip(this.editForm).then(r => {
        if (r.code === 0) { this.$message.success('保存成功'); this.editVisible = false; this.getList() } else this.$message.error(r.msg || '保存失败')
      }).catch(() => {}).finally(() => { this.saving = false })
    },
    handleDelete (row) {
      this.$confirm('确认删除该发货单吗？删除后不可恢复', '提示', { type: 'warning' }).then(() => {
        deleteShip(row.id).then(r => { if (r.code === 0) { this.$message.success('删除成功'); this.getList() } else this.$message.error(r.msg || '删除失败') })
      }).catch(() => {})
    },
    handleMore (cmd, row) {
      if (cmd === 'confirm') this.handleConfirmOpen(row)
      else if (cmd === 'sign') this.handleSignOpen(row)
      else if (cmd === 'track') this.openTrack(row)
      else if (cmd === 'print') this.handlePrint(row)
      else if (cmd === 'cancel') this.handleCancel(row)
    },
    handleConfirmOpen (row) {
      this.currentConfirm = row
      this.confirmForm = {
        ship_date: row.ship_date || new Date().toISOString().slice(0, 10),
        ship_method: row.ship_method || 1, logistics_company: row.logistics_company || '', tracking_no: row.tracking_no || ''
      }
      this.confirmVisible = true
    },
    handleConfirm () {
      this.saving = true
      confirmShip(this.currentConfirm.id, this.confirmForm).then(r => {
        if (r.code === 0) { this.$message.success('已确认发货'); this.confirmVisible = false; this.getList() } else this.$message.error(r.msg || '操作失败')
      }).catch(() => {}).finally(() => { this.saving = false })
    },
    handleSignOpen (row) {
      this.currentSign = row
      this.signForm = { signer: '', sign_time: new Date().toISOString().slice(0, 10) }
      this.signVisible = true
    },
    handleSign () {
      if (!this.signForm.signer) { this.$message.warning('请填写签收人'); return }
      this.saving = true
      signShip(this.currentSign.id, this.signForm).then(r => {
        if (r.code === 0) { this.$message.success('已登记签收'); this.signVisible = false; this.getList() } else this.$message.error(r.msg || '操作失败')
      }).catch(() => {}).finally(() => { this.saving = false })
    },
    handleCancel (row) {
      this.$confirm(`确认取消发货单 ${row.ship_no} 吗？`, '取消发货', { type: 'warning' }).then(() => {
        cancelShip(row.id).then(r => { if (r.code === 0) { this.$message.success('已取消'); this.getList() } else this.$message.error(r.msg || '操作失败') })
      }).catch(() => {})
    },
    openTrack (row) {
      this.trackShip = row
      this.trackVisible = true
    },
    handlePrint (row) {
      this.$router.push({ path: `/business/sales/ship/detail/${row.id}`, query: { print: 1 } })
    },
    async handleExport () {
      this.exporting = true
      try {
        const p = { ...this.buildParams() }
        delete p.page; delete p.pageSize
        const r = await exportShip(p)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `发货单列表_${new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14)}.xlsx`
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
.drawer-body { padding: 0 20px 20px; }
.section-title { margin: 20px 0 10px; color: #606266; border-bottom: 1px solid #f0f0f0; padding-bottom: 6px; }
</style>
