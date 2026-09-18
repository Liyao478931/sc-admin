<!--
  文件：admin/src/views/business/receive/List.vue
  功能：产品接收单列表（搜索/分页/状态流转）
  权限：business:receive:list/add/edit/delete/confirm/export
-->
<template>
  <div class="rc-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品接收管理</el-breadcrumb-item>
      <el-breadcrumb-item>接收单列表</el-breadcrumb-item>
    </el-breadcrumb>

    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="接收单号"><el-input v-model="q.receipt_no" placeholder="请输入接收单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="维修工单"><el-input v-model="q.work_order_no" placeholder="请输入维修工单编号" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="来源地点"><el-input v-model="q.source_location" placeholder="请输入来源矿井/地点" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="接收类型">
          <el-select v-model="q.receipt_type" placeholder="全部" clearable style="width:130px" @change="handleSearch">
            <el-option v-for="(t, v) in RECEIPT_TYPES" :key="v" :label="t" :value="v" />
          </el-select>
        </el-form-item>
        <el-form-item label="产品状态">
          <el-select v-model="q.product_status" placeholder="全部" clearable style="width:110px" @change="handleSearch">
            <el-option v-for="(t, v) in PRODUCT_STATUSES" :key="v" :label="t" :value="v" />
          </el-select>
        </el-form-item>
        <el-form-item label="接收状态">
          <el-select v-model="q.status" placeholder="全部" clearable style="width:130px" @change="handleSearch">
            <el-option v-for="(t, v) in STATUSES" :key="v" :label="t" :value="v" />
          </el-select>
        </el-form-item>
        <el-form-item label="接收日期">
          <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始" end-placeholder="结束" value-format="yyyy-MM-dd" style="width:230px" @change="handleSearch" />
        </el-form-item>
        <div class="filter-btns">
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </div>
      </el-form>
    </el-card>

    <el-card shadow="never">
      <div class="toolbar">
        <el-button v-permission="'business:receive:add'" type="primary" size="small" icon="el-icon-plus" @click="$router.push('/business/receive/add')">新增接收单</el-button>
        <el-button v-permission="'business:receive:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" @click="getList">刷新</el-button>
        <span class="flex-1"></span>
        <span class="total-tip">共 {{ total }} 条</span>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe border empty-text="暂无接收单数据">
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column label="接收单编号" width="150">
          <template slot-scope="s"><span class="link" @click="goDetail(s.row.id)">{{ s.row.receipt_no }}</span></template>
        </el-table-column>
        <el-table-column label="接收类型" width="120" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="typeTag(s.row.receipt_type)">{{ s.row.receipt_type_label }}</el-tag></template>
        </el-table-column>
        <el-table-column label="关联维修工单" width="130">
          <template slot-scope="s">
            <span v-if="s.row.work_order_id" class="link" @click="$router.push('/business/order?category=repair')">{{ s.row.work_order_no }}</span>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column label="客户" width="140" show-overflow-tooltip>
          <template slot-scope="s">{{ s.row.customer_name || s.row.source_location || '-' }}</template>
        </el-table-column>
        <el-table-column prop="receipt_date" label="接收日期" width="110" />
        <el-table-column prop="receiver_name" label="接收人" width="90" align="center" />
        <el-table-column prop="total_quantity" label="产品数量" width="90" align="center" />
        <el-table-column label="产品状态" width="95" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="pStatusTag(s.row.product_status)">{{ s.row.product_status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column label="接收状态" width="110" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="statusTag(s.row.status)">{{ s.row.status_label }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="220" align="center" fixed="right">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="goDetail(s.row.id)">查看详情</el-button>
            <el-button v-if="s.row.status === 0" v-permission="'business:receive:edit'" type="text" size="mini" @click="$router.push('/business/receive/edit/' + s.row.id)">编辑</el-button>
            <el-button v-if="s.row.status === 0" v-permission="'business:receive:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
            <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
              <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right" /></el-button>
              <el-dropdown-menu slot="dropdown">
                <el-dropdown-item v-if="s.row.status === 0" v-permission="'business:receive:confirm'" command="confirm">确认接收</el-dropdown-item>
                <el-dropdown-item v-if="s.row.status === 1" command="warehouse">生成入库单</el-dropdown-item>
                <el-dropdown-item v-if="s.row.has_transport" command="transport">查看运输信息</el-dropdown-item>
                <el-dropdown-item command="print">打印接收单</el-dropdown-item>
              </el-dropdown-menu>
            </el-dropdown>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper" :total="total" :page-sizes="[10, 20, 50, 100]" :page-size="q.pageSize" :current-page="q.page" @current-change="p => { q.page = p; getList() }" @size-change="s => { q.pageSize = s; q.page = 1; getList() }" />
    </el-card>

    <!-- 运输信息弹窗 -->
    <el-dialog title="运输信息" :visible="transportVisible" @update:visible="v => transportVisible = v" width="640px" top="6vh">
      <el-descriptions v-if="transport" :column="2" border size="small">
        <el-descriptions-item label="运输单号">{{ transport.transport_no }}</el-descriptions-item>
        <el-descriptions-item label="运输方式">{{ transport.transport_type_label }}</el-descriptions-item>
        <el-descriptions-item label="车牌号">{{ transport.plate_no || '-' }}</el-descriptions-item>
        <el-descriptions-item label="司机">{{ (transport.driver_name || '') + (transport.driver_phone ? ' ' + transport.driver_phone : '') || '-' }}</el-descriptions-item>
        <el-descriptions-item label="物流公司">{{ transport.logistics_company || '-' }}</el-descriptions-item>
        <el-descriptions-item label="物流单号">{{ transport.track_no || '-' }}</el-descriptions-item>
        <el-descriptions-item label="发车日期">{{ transport.depart_date || '-' }}</el-descriptions-item>
        <el-descriptions-item label="预计到达">{{ transport.expected_arrive_date || '-' }}</el-descriptions-item>
        <el-descriptions-item label="实际到达">{{ transport.actual_arrive_date || '-' }}</el-descriptions-item>
        <el-descriptions-item label="运费">{{ transport.freight_amount ? '¥ ' + Number(transport.freight_amount).toFixed(2) : '-' }}</el-descriptions-item>
        <el-descriptions-item label="发货地址" :span="2">{{ transport.ship_address || '-' }}</el-descriptions-item>
        <el-descriptions-item label="收货地址" :span="2">{{ transport.receive_address || '-' }}</el-descriptions-item>
      </el-descriptions>
    </el-dialog>
  </div>
</template>

<script>
import { getReceiveList, deleteReceive, confirmReceive, warehouseReceive, exportReceive, getReceiveDetail } from '../../../api/purchase'

const RECEIPT_TYPES = { 1: '煤矿拉回', 2: '维修完成移交', 3: '客户退货', 4: '内部调拨', 5: '其他' }
const PRODUCT_STATUSES = { 1: '完好', 2: '待维修', 3: '待保养', 4: '报废', 5: '待检验' }
const STATUSES = { 0: '草稿', 1: '已接收', 2: '已入库', 3: '已移交/已发货' }

export default {
  name: 'ProductReceiveList',
  data () {
    return {
      RECEIPT_TYPES, PRODUCT_STATUSES, STATUSES,
      q: { page: 1, pageSize: 10, receipt_no: '', work_order_no: '', source_location: '', receipt_type: '', product_status: '', status: '' },
      dateRange: null, list: [], total: 0, loading: false, exporting: false,
      transportVisible: false, transport: null
    }
  },
  created () { this.getList() },
  methods: {
    async getList () {
      this.loading = true
      try {
        const params = { page: this.q.page, pageSize: this.q.pageSize, ...this.q }
        if (this.dateRange && this.dateRange.length === 2) { params.start_date = this.dateRange[0]; params.end_date = this.dateRange[1] }
        const r = await getReceiveList(params)
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.q.page = 1; this.getList() },
    handleReset () {
      this.q = { page: 1, pageSize: this.q.pageSize, receipt_no: '', work_order_no: '', source_location: '', receipt_type: '', product_status: '', status: '' }
      this.dateRange = null
      this.getList()
    },
    typeTag (v) { return { 1: 'primary', 2: 'success', 3: 'warning', 4: 'primary', 5: 'info' }[v] || 'info' },
    pStatusTag (v) { return { 1: 'success', 2: 'warning', 3: 'primary', 4: 'danger', 5: 'info' }[v] || 'info' },
    statusTag (v) { return { 0: 'info', 1: 'primary', 2: 'success', 3: 'primary' }[v] || 'info' },
    goDetail (id) { this.$router.push('/business/receive/detail/' + id) },
    handleDelete (row) {
      this.$confirm('确认删除该接收单吗？删除后不可恢复', '删除确认', { type: 'warning' }).then(async () => {
        try { const r = await deleteReceive(row.id); if (r.code === 0) { this.$message.success('已删除'); this.getList() } } catch (e) {}
      }).catch(() => {})
    },
    handleMore (cmd, row) {
      if (cmd === 'confirm') {
        this.$confirm('确认接收该接收单？确认后不可再编辑。', '确认接收', { type: 'info' }).then(async () => {
          try { const r = await confirmReceive(row.id); if (r.code === 0) { this.$message.success('已确认接收'); this.getList() } } catch (e) {}
        }).catch(() => {})
      }
      if (cmd === 'warehouse') {
        this.$confirm('确认生成入库单？接收单状态将变为"已入库"。', '生成入库单', { type: 'info' }).then(async () => {
          try { const r = await warehouseReceive(row.id); if (r.code === 0) { this.$message.success(r.msg || '已生成入库单'); this.getList() } else this.$message.error(r.msg || '操作失败') } catch (e) {}
        }).catch(() => {})
      }
      if (cmd === 'transport') this.openTransport(row.id)
      if (cmd === 'print') window.print()
    },
    async openTransport (id) {
      try {
        const r = await getReceiveDetail(id)
        if (r.code === 0 && r.data && r.data.transport) { this.transport = r.data.transport; this.transportVisible = true }
        else this.$message.info('该接收单暂无运输信息')
      } catch (e) {}
    },
    async handleExport () {
      this.exporting = true
      try {
        const params = { ...this.q }
        if (this.dateRange && this.dateRange.length === 2) { params.start_date = this.dateRange[0]; params.end_date = this.dateRange[1] }
        const blob = await exportReceive(params)
        const url = window.URL.createObjectURL(new Blob([blob]))
        const a = document.createElement('a'); a.href = url; a.download = `产品接收单_${new Date().toISOString().slice(0, 10)}.xlsx`
        a.click(); window.URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('导出失败') } finally { this.exporting = false }
    }
  }
}
</script>

<style scoped>
.rc-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.breadcrumb { margin-bottom: 12px; }
.filter-card { margin-bottom: 12px; }
.filter-btns { display: inline-block; margin-left: 4px; }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.total-tip { font-size: 14px; color: #909399; }
.link { color: #409EFF; cursor: pointer; }
.danger { color: #F56C6C; }
.pager { margin-top: 12px; text-align: right; }
</style>
