<!--
  文件：admin/src/views/business/sales/out/List.vue
  功能：销售出库单列表（搜索/新增/编辑/删除/提交审核[统一审批]/撤销/确认出库/登记发货/取消/导出/详情）
  权限：sales:out:list:view/add/edit/delete/confirm/ship/export
  说明：审核走统一审批（提交后由统一审批待办处理，本页不提供审核按钮）
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>销售管理</el-breadcrumb-item>
      <el-breadcrumb-item>出库单列表</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="search-bar">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="出库单编号"><el-input v-model="query.out_no" placeholder="请输入出库单编号" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="销售订单"><el-input v-model="query.source_no" placeholder="请输入销售订单编号" clearable style="width:160px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="客户名称"><el-input v-model="query.customer_name" placeholder="请输入客户名称" clearable style="width:150px" @keyup.enter.native="handleSearch" /></el-form-item>
        <el-form-item label="出库状态">
          <el-select v-model="query.status" clearable placeholder="全部" style="width:110px">
            <el-option v-for="(t, v) in STATUS_TEXT" :key="v" :label="t" :value="Number(v)" />
          </el-select>
        </el-form-item>
        <el-form-item label="出库日期">
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
        <el-button v-permission="'sales:out:add'" type="primary" size="small" icon="el-icon-plus" @click="openForm()">新增出库单</el-button>
        <el-button v-permission="'sales:out:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" :loading="loading" @click="getList">刷新</el-button>
      </div>
      <span class="total-text">共 {{ total }} 条</span>
    </div>

    <el-table :data="list" v-loading="loading" size="small" border stripe empty-text="暂无销售出库单数据">
      <el-table-column type="index" label="#" width="55" align="center" />
      <el-table-column label="出库单编号" width="150">
        <template slot-scope="s"><el-link type="primary" @click="openDetail(s.row)">{{ s.row.out_no }}</el-link></template>
      </el-table-column>
      <el-table-column label="销售订单" width="140">
        <template slot-scope="s"><el-link type="primary" @click="goOrder(s.row)">{{ s.row.source_no || '-' }}</el-link></template>
      </el-table-column>
      <el-table-column prop="customer_name" label="客户名称" width="140" show-overflow-tooltip />
      <el-table-column label="出库类型" width="110" align="center">
        <template slot-scope="s"><el-tag :type="s.row.out_type_tag" effect="plain" size="mini">{{ s.row.out_type_label }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="warehouse_name" label="出库仓库" width="120" show-overflow-tooltip />
      <el-table-column label="出库数量" width="100" align="right"><template slot-scope="s">{{ s.row.total_quantity }}</template></el-table-column>
      <el-table-column label="出库总金额" width="120" align="right"><template slot-scope="s">{{ money(s.row.total_amount) }}</template></el-table-column>
      <el-table-column label="出库状态" width="100" align="center">
        <template slot-scope="s"><el-tag :type="s.row.status_tag" size="mini">{{ s.row.status_label }}</el-tag></template>
      </el-table-column>
      <el-table-column label="出库日期" width="110" align="center"><template slot-scope="s">{{ s.row.out_date || '-' }}</template></el-table-column>
      <el-table-column label="操作" width="250" align="center" fixed="right">
        <template slot-scope="s">
          <el-button type="text" size="mini" @click="openDetail(s.row)">查看详情</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 4" v-permission="'sales:out:edit'" type="text" size="mini" @click="openForm(s.row)">编辑</el-button>
          <el-button v-if="s.row.status === 0 || s.row.status === 4" v-permission="'sales:out:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row)">删除</el-button>
          <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
            <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right" /></el-button>
            <el-dropdown-menu slot="dropdown">
              <el-dropdown-item v-if="s.row.status === 0" command="submit" icon="el-icon-upload2">提交审核</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 1" command="cancel" icon="el-icon-refresh-left">取消出库</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 2" v-permission="'sales:out:confirm'" command="confirm" icon="el-icon-check">确认出库</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 3 && !s.row.ship_date" v-permission="'sales:out:ship'" command="ship" icon="el-icon-truck">登记发货</el-dropdown-item>
              <el-dropdown-item v-if="s.row.status === 0 || s.row.status === 2" command="cancel" icon="el-icon-circle-close">取消出库</el-dropdown-item>
              <el-dropdown-item v-if="!(s.row.status === 0 || s.row.status === 1 || s.row.status === 2 || (s.row.status === 3 && !s.row.ship_date))" disabled>当前状态无可执行操作</el-dropdown-item>
            </el-dropdown-menu>
          </el-dropdown>
        </template>
      </el-table-column>
    </el-table>

    <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper"
      :total="total" :current-page="page" :page-size="pageSize" :page-sizes="[10, 20, 50, 100]"
      @current-change="handlePageChange" @size-change="handleSizeChange" />

    <!-- 新增/编辑出库单弹窗 -->
    <el-dialog :title="formId ? '编辑销售出库单' : '新增销售出库单'" :visible.sync="formVisible" width="920px" top="4vh" :close-on-click-modal="false">
      <el-form ref="form" :model="form" :rules="rules" label-width="100px" size="small">
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="销售订单" prop="sales_order_id">
            <el-select v-model="form.sales_order_id" filterable remote :remote-method="searchSales" :loading="salesLoading" placeholder="输入订单编号/客户名称搜索" style="width:100%" @change="handleSalesChange">
              <el-option v-for="p in salesOptions" :key="p.id" :label="`${p.order_no} - ${p.customer_name}`" :value="p.id" />
            </el-select>
          </el-form-item></el-col>
          <el-col :span="12"><el-form-item label="客户" prop="customer_id">
            <el-select v-model="form.customer_id" filterable placeholder="请选择客户" style="width:100%">
              <el-option v-for="c in customerOptions" :key="c.id" :label="c.customer_name" :value="c.id" />
            </el-select>
          </el-form-item></el-col>
          <el-col :span="12"><el-form-item label="出库仓库" prop="warehouse_id">
            <el-select v-model="form.warehouse_id" filterable placeholder="请选择仓库" style="width:100%" @change="handleWarehouseChange">
              <el-option v-for="w in warehouseOptions" :key="w.id" :label="w.warehouse_name" :value="w.id" />
            </el-select>
          </el-form-item></el-col>
          <el-col :span="12"><el-form-item label="出库人" prop="out_user_id">
            <el-select v-model="form.out_user_id" filterable placeholder="请选择出库人" style="width:100%">
              <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
            </el-select>
          </el-form-item></el-col>
          <el-col :span="12"><el-form-item label="出库日期" prop="out_date"><el-date-picker v-model="form.out_date" type="date" value-format="yyyy-MM-dd" placeholder="请选择日期" style="width:100%" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="交付地址"><el-input v-model="form.delivery_address" placeholder="交付/发货地址（可选）" /></el-form-item></el-col>
        </el-row>
        <el-divider content-position="left">出库明细（共 {{ items.length }} 项，总数量 {{ totalQuantity }}，总金额 {{ money(totalAmount) }}）</el-divider>
        <el-table :data="items" size="mini" border empty-text="请选择销售订单导入明细">
          <el-table-column type="index" label="#" width="40" align="center" />
          <el-table-column prop="product_code" label="产品编码" width="100" />
          <el-table-column prop="product_name" label="产品名称" min-width="120" show-overflow-tooltip />
          <el-table-column prop="specification" label="规格型号" width="100" show-overflow-tooltip />
          <el-table-column prop="unit" label="单位" width="45" align="center" />
          <el-table-column label="出库数量" width="100">
            <template slot-scope="s"><el-input-number v-model="s.row.quantity" :min="0.01" :max="s.row.remaining_quantity" :precision="4" size="mini" style="width:100%" /></template>
          </el-table-column>
          <el-table-column label="设备编号/序列号" width="120">
            <template slot-scope="s"><el-input v-model="s.row.serial_number" size="mini" placeholder="必填" /></template>
          </el-table-column>
          <el-table-column label="出库货位" width="120">
            <template slot-scope="s">
              <el-select v-model="s.row.location_id" filterable size="mini" placeholder="货位" style="width:100%">
                <el-option v-for="l in locationOptions" :key="l.id" :label="l.location_name" :value="l.id" />
              </el-select>
            </template>
          </el-table-column>
          <el-table-column label="备注" width="90">
            <template slot-scope="s"><el-input v-model="s.row.remark" size="mini" placeholder="可选" /></template>
          </el-table-column>
          <el-table-column label="操作" width="55" align="center">
            <template slot-scope="s"><el-button type="text" size="mini" class="danger" @click="items.splice(s.$index, 1)">删</el-button></template>
          </el-table-column>
        </el-table>
        <el-form-item label="备注" style="margin-top:12px;"><el-input v-model="form.remark" type="textarea" :rows="2" placeholder="备注（可选）" /></el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="formVisible=false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </span>
    </el-dialog>

    <!-- 登记发货弹窗 -->
    <el-dialog title="登记发货" :visible.sync="shipVisible" width="480px">
      <el-form ref="shipForm" :model="shipForm" :rules="shipRules" label-width="90px" size="small">
        <el-form-item label="发货方式" prop="ship_method">
          <el-radio-group v-model="shipForm.ship_method">
            <el-radio :label="1">物流</el-radio>
            <el-radio :label="2">自提</el-radio>
            <el-radio :label="3">快递</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="shipForm.ship_method === 1" label="物流公司" prop="ship_company"><el-input v-model="shipForm.ship_company" placeholder="如：顺丰速运" /></el-form-item>
        <el-form-item v-if="shipForm.ship_method === 1" label="物流单号" prop="ship_no"><el-input v-model="shipForm.ship_no" placeholder="请输入物流单号" /></el-form-item>
        <el-form-item label="发货日期" prop="ship_date"><el-date-picker v-model="shipForm.ship_date" type="date" value-format="yyyy-MM-dd" placeholder="请选择发货日期" style="width:100%" /></el-form-item>
        <el-form-item label="收货人"><el-input v-model="shipForm.consignee" placeholder="选填" /></el-form-item>
        <el-form-item label="收货电话"><el-input v-model="shipForm.consignee_phone" placeholder="选填" /></el-form-item>
      </el-form>
      <span slot="footer"><el-button size="small" @click="shipVisible=false">取消</el-button><el-button size="small" type="primary" :loading="saving" @click="handleShip">确认登记</el-button></span>
    </el-dialog>

    <!-- 详情抽屉 -->
    <el-drawer :title="'销售出库单详情 - ' + (detail.out_no || '')" :visible.sync="detailVisible" size="620px">
      <div class="drawer-body" v-if="detail.id">
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="出库单编号">{{ detail.out_no }}</el-descriptions-item>
          <el-descriptions-item label="状态"><el-tag :type="detail.status_tag" size="mini">{{ detail.status_label }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="销售订单">{{ detail.source_no || '-' }}</el-descriptions-item>
          <el-descriptions-item label="客户">{{ detail.customer_name }}</el-descriptions-item>
          <el-descriptions-item label="出库类型">{{ detail.out_type_label }}</el-descriptions-item>
          <el-descriptions-item label="出库仓库">{{ detail.warehouse_name }}</el-descriptions-item>
          <el-descriptions-item label="出库数量">{{ detail.total_quantity }}</el-descriptions-item>
          <el-descriptions-item label="出库总金额">{{ money(detail.total_amount) }}</el-descriptions-item>
          <el-descriptions-item label="出库人">{{ detail.out_user_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="出库日期">{{ detail.out_date || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建人">{{ detail.creator_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="交付地址" :span="2">{{ detail.delivery_address || '-' }}</el-descriptions-item>
          <el-descriptions-item v-if="detail.ship_date" label="发货方式">{{ detail.ship_method_label || '-' }}</el-descriptions-item>
          <el-descriptions-item v-if="detail.ship_date" label="发货日期">{{ detail.ship_date }}</el-descriptions-item>
          <el-descriptions-item v-if="detail.ship_company" label="物流公司" :span="2">{{ detail.ship_company }}（{{ detail.ship_no || '-' }}）</el-descriptions-item>
          <el-descriptions-item v-if="detail.consignee" label="收货人" :span="2">{{ detail.consignee }}</el-descriptions-item>
          <el-descriptions-item v-if="detail.consignee_phone" label="收货电话" :span="2">{{ detail.consignee_phone }}</el-descriptions-item>
          <el-descriptions-item label="备注" :span="2">{{ detail.remark || '-' }}</el-descriptions-item>
        </el-descriptions>
        <h4 class="section-title">出库明细</h4>
        <el-table :data="detail.items || []" size="mini" border>
          <el-table-column prop="product_code" label="编码" width="90" />
          <el-table-column prop="product_name" label="产品" min-width="110" show-overflow-tooltip />
          <el-table-column prop="quantity" label="数量" width="70" align="right" />
          <el-table-column prop="unit_price" label="单价" width="90" align="right" />
          <el-table-column prop="total_price" label="总价" width="90" align="right" />
          <el-table-column prop="serial_number" label="序列号" width="110" show-overflow-tooltip />
        </el-table>
        <h4 class="section-title">操作日志</h4>
        <el-timeline v-if="detail.logs && detail.logs.length" style="padding-left:8px;">
          <el-timeline-item v-for="(lg, i) in detail.logs" :key="i" :timestamp="lg.operator_time" placement="top">
            <div>{{ lg.action_label }} <span style="color:#909399">({{ lg.operator_name }})</span></div>
            <div v-if="lg.remark" style="color:#606266;font-size:12px;">{{ lg.remark }}</div>
          </el-timeline-item>
        </el-timeline>
        <el-empty v-else description="暂无操作日志" :image-size="50" />
      </div>
    </el-drawer>
  </div>
</template>

<script>
import { getSalesOutList, getSalesOutDetail, saveSalesOut, deleteSalesOut, submitSalesOut, cancelSalesOut, confirmSalesOut, shipSalesOut, exportSalesOut } from '@/api/sales'
import { getSalesReadyOut, getWarehouseList, getLocationList, getCustomerOptions } from '@/api/warehouse'
import { getUserList } from '@/api/user'

const OUT_TYPES = { 1: '普通销售出库', 2: '销售退货出库', 3: '赠品出库' }
const STATUS_TEXT = { 0: '草稿', 1: '待审核', 2: '已审核', 3: '已出库', 4: '已发货', 5: '已取消' }

export default {
  name: 'SalesOutList',
  data () {
    return {
      OUT_TYPES, STATUS_TEXT,
      list: [], total: 0, page: 1, pageSize: 10, loading: false, exporting: false, saving: false,
      query: { out_no: '', source_no: '', customer_name: '', status: '' },
      dateRange: [],
      formVisible: false, formId: null, form: {}, items: [], salesLoading: false,
      salesOptions: [], salesMap: {}, warehouseOptions: [], locationOptions: [], customerOptions: [], userOptions: [],
      shipVisible: false, shipForm: {}, currentShip: null,
      detailVisible: false, detail: {},
      rules: {
        sales_order_id: [{ required: true, message: '请选择销售订单', trigger: 'change' }],
        customer_id: [{ required: true, message: '请选择客户', trigger: 'change' }],
        warehouse_id: [{ required: true, message: '请选择出库仓库', trigger: 'change' }],
        out_user_id: [{ required: true, message: '请选择出库人', trigger: 'change' }],
        out_date: [{ required: true, message: '请选择出库日期', trigger: 'change' }]
      },
      shipRules: {
        ship_method: [{ required: true, message: '请选择发货方式', trigger: 'change' }],
        ship_date: [{ required: true, message: '请选择发货日期', trigger: 'change' }],
        ship_company: [{ required: true, message: '请填写物流公司', trigger: 'blur' }],
        ship_no: [{ required: true, message: '请填写物流单号', trigger: 'blur' }]
      }
    }
  },
  computed: {
    totalQuantity () { return this.items.reduce((s, x) => s + Number(x.quantity || 0), 0) },
    totalAmount () { return this.items.reduce((s, x) => s + Number(x.quantity || 0) * Number(x.unit_price || 0), 0) }
  },
  created () {
    this.getList()
    this.loadOptions()
  },
  methods: {
    money (v) { const n = Number(v) || 0; return n ? '¥ ' + n.toLocaleString('zh-CN', { minimumFractionDigits: 2 }) : '-' },
    async loadOptions () {
      try {
        const [w, c, u] = await Promise.all([getWarehouseList({ page: 1, pageSize: 100 }), getCustomerOptions(), getUserList({ page: 1, limit: 500 })])
        this.warehouseOptions = (w.code === 0 && w.data && w.data.list) ? w.data.list : []
        this.customerOptions = (c.code === 0 && c.data) ? c.data : []
        this.userOptions = (u.data && u.data.list) || []
      } catch (e) {}
    },
    async loadLocations () {
      if (!this.form.warehouse_id) { this.locationOptions = []; return }
      try {
        const r = await getLocationList({ warehouse_id: this.form.warehouse_id, page: 1, pageSize: 200 })
        this.locationOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
      } catch (e) { this.locationOptions = [] }
    },
    async searchSales (kw) {
      this.salesLoading = true
      try {
        const r = await getSalesReadyOut(kw || '')
        this.salesOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
        this.salesOptions.forEach(p => { this.salesMap[p.id] = p })
      } catch (e) { this.salesOptions = [] } finally { this.salesLoading = false }
    },
    buildParams () {
      const p = { page: this.page, pageSize: this.pageSize, out_type: 3 }
      Object.keys(this.query).forEach(k => { if (this.query[k] !== '' && this.query[k] !== null) p[k] = this.query[k] })
      if (this.dateRange && this.dateRange.length === 2) p.date_range = this.dateRange
      return p
    },
    async getList () {
      this.loading = true
      try {
        const r = await getSalesOutList(this.buildParams())
        if (r.code === 0 && r.data) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {} finally { this.loading = false }
    },
    handleSearch () { this.page = 1; this.getList() },
    handleReset () { this.query = { out_no: '', source_no: '', customer_name: '', status: '' }; this.dateRange = []; this.handleSearch() },
    handlePageChange (p) { this.page = p; this.getList() },
    handleSizeChange (s) { this.pageSize = s; this.page = 1; this.getList() },
    goOrder (row) { this.$router.push({ path: '/business/order' }) },
    openForm (row) {
      this.formId = row ? row.id : null
      this.form = row ? {
        id: row.id, sales_order_id: row.sales_order_id, customer_id: row.customer_id,
        warehouse_id: row.warehouse_id, out_user_id: row.out_user_id, out_date: row.out_date || '',
        delivery_address: row.delivery_address || '', remark: row.remark || ''
      } : {
        id: 0, sales_order_id: 0, customer_id: 0, warehouse_id: 0, out_user_id: 0,
        out_date: new Date().toISOString().slice(0, 10), delivery_address: '', remark: ''
      }
      this.items = row && row.items ? row.items.map(it => ({ ...it, remaining_quantity: Number(it.quantity) || 0 })) : []
      this.formVisible = true
      this.searchSales('')
      if (row) { this.form.warehouse_name = row.warehouse_name; this.loadLocations() }
    },
    handleSalesChange (sid) {
      const s = this.salesMap[sid]
      if (!s) return
      this.form.customer_id = s.customer_id || 0
      this.form.customer_name = s.customer_name || ''
      this.form.delivery_address = ''
      this.importItems(s.items)
    },
    handleWarehouseChange () {
      this.form.warehouse_name = (this.warehouseOptions.find(w => w.id === this.form.warehouse_id) || {}).warehouse_name || ''
      this.loadLocations()
    },
    importItems (srcItems) {
      if (this.items.length) {
        this.$confirm('导入将覆盖当前明细列表，是否继续？', '提示', { type: 'warning' }).then(() => {
          this.items = (srcItems || []).filter(it => Number(it.available_quantity) > 0).map(it => ({
            product_id: it.product_id, product_code: it.product_code, product_name: it.product_name,
            specification: it.specification, unit: it.unit,
            quantity: Number(it.available_quantity) || 0, unit_price: Number(it.avg_price) || 0,
            serial_number: it.serial_number || '', location_id: it.location_id || 0, location_name: it.location_name || '',
            remark: it.remark || '', remaining_quantity: Number(it.available_quantity) || 0, stock: it.stock || 0
          }))
        }).catch(() => {})
        return
      }
      this.items = (srcItems || []).filter(it => Number(it.available_quantity) > 0).map(it => ({
        product_id: it.product_id, product_code: it.product_code, product_name: it.product_name,
        specification: it.specification, unit: it.unit,
        quantity: Number(it.available_quantity) || 0, unit_price: Number(it.avg_price) || 0,
        serial_number: it.serial_number || '', location_id: it.location_id || 0, location_name: it.location_name || '',
        remark: it.remark || '', remaining_quantity: Number(it.available_quantity) || 0, stock: it.stock || 0
      }))
    },
    handleSave () {
      this.$refs.form.validate(valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        if (!this.items.length) { this.$message.warning('请至少添加一条出库明细'); return }
        const bad = this.items.find(it => !it.serial_number || !it.location_id || !Number(it.quantity))
        if (bad) { this.$message.warning('请完善明细的序列号、货位和数量'); return }
        this.saving = true
        const payload = {
          id: this.form.id, out_type: 3, sales_order_id: this.form.sales_order_id,
          customer_id: this.form.customer_id, customer_name: this.form.customer_name || '',
          delivery_address: this.form.delivery_address, warehouse_id: this.form.warehouse_id,
          out_user_id: this.form.out_user_id, out_date: this.form.out_date, remark: this.form.remark,
          items: this.items.map(it => ({
            product_id: it.product_id, product_code: it.product_code, product_name: it.product_name,
            specification: it.specification, unit: it.unit, quantity: it.quantity,
            serial_number: it.serial_number, location_id: it.location_id, remark: it.remark || ''
          }))
        }
        saveSalesOut(payload).then(r => {
          if (r.code === 0) { this.$message.success(r.msg || '保存成功'); this.formVisible = false; this.getList() } else this.$message.error(r.msg || '保存失败')
        }).catch(() => {}).finally(() => { this.saving = false })
      })
    },
    handleDelete (row) {
      this.$confirm('确认删除该出库单吗？删除后不可恢复', '提示', { type: 'warning' }).then(() => {
        deleteSalesOut(row.id).then(r => { if (r.code === 0) { this.$message.success('删除成功'); this.getList() } else this.$message.error(r.msg || '删除失败') })
      }).catch(() => {})
    },
    handleMore (cmd, row) {
      if (cmd === 'submit') this.handleSubmit(row)
      else if (cmd === 'cancel') this.handleCancel(row)
      else if (cmd === 'confirm') this.handleConfirm(row)
      else if (cmd === 'ship') this.handleShip(row)
    },
    handleSubmit (row) {
      this.$confirm(`确认提交出库单 ${row.out_no} 审核吗？提交后将由统一审批流程处理，提交后不可再编辑。`, '提交审核', { type: 'warning' }).then(() => {
        submitSalesOut(row.id).then(r => { if (r.code === 0) { this.$message.success('已提交审核'); this.getList() } else this.$message.error(r.msg || '提交失败') })
      }).catch(() => {})
    },
    handleCancel (row) {
      this.$confirm(`确认取消出库单 ${row.out_no} 吗？`, '取消出库', { type: 'warning' }).then(() => {
        cancelSalesOut(row.id).then(r => { if (r.code === 0) { this.$message.success('已取消'); this.getList() } else this.$message.error(r.msg || '操作失败') })
      }).catch(() => {})
    },
    handleConfirm (row) {
      this.$confirm(`确认出库单 ${row.out_no} 出库吗？系统将扣减产品库存、生成库存流水并回写销售订单，且不可撤回。`, '确认出库', { type: 'warning' }).then(() => {
        confirmSalesOut(row.id).then(r => { if (r.code === 0) { this.$message.success(r.msg || '出库成功'); this.getList() } else this.$message.error(r.msg || '操作失败') })
      }).catch(() => {})
    },
    handleShip (row) {
      this.currentShip = row
      this.shipForm = { ship_method: 1, ship_company: '', ship_no: '', ship_date: new Date().toISOString().slice(0, 10), consignee: row.consignee || '', consignee_phone: row.consignee_phone || '' }
      this.shipVisible = true
    },
    handleShipSave () {
      this.$refs.shipForm.validate(valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        this.saving = true
        shipSalesOut(this.currentShip.id, this.shipForm).then(r => {
          if (r.code === 0) { this.$message.success('发货已登记'); this.shipVisible = false; this.getList() } else this.$message.error(r.msg || '操作失败')
        }).catch(() => {}).finally(() => { this.saving = false })
      })
    },
    async openDetail (row) {
      this.detail = {}
      try {
        const r = await getSalesOutDetail(row.id)
        if (r.code === 0 && r.data) this.detail = r.data
      } catch (e) {}
      this.detailVisible = true
    },
    async handleExport () {
      this.exporting = true
      try {
        const p = { ...this.buildParams() }
        delete p.page; delete p.pageSize
        const r = await exportSalesOut(p)
        if (r instanceof Blob) {
          const url = window.URL.createObjectURL(r)
          const a = document.createElement('a')
          a.href = url
          a.download = `出库单列表_${new Date().toISOString().replace(/[-:T]/g, '').slice(0, 14)}.xlsx`
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
