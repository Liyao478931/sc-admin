<!--
  文件：admin/src/views/business/sales/out/Add.vue
  功能：新增/编辑销售出库单（来源销售订单 → 自动填充客户/收货/明细，分批出库数量校验）
  权限：sales:out:add / edit
  说明：发货信息（物流公司/单号等）在确认出库后的"登记发货"环节填写；本页保存收货人/电话/地址
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>销售管理</el-breadcrumb-item>
      <el-breadcrumb-item>出库单列表</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑出库单' : '新增出库单' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ isEdit ? `编辑出库单 - ${form.out_no || ''}` : '新增出库单' }}</span>
      <div>
        <el-button size="small" @click="handleBack">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </div>

    <el-card shadow="never" class="form-card">
      <el-form ref="form" :model="form" :rules="rules" label-width="120px" size="small">
        <el-row :gutter="24">
          <!-- 第一列：来源信息 + 基本信息 -->
          <el-col :span="12">
            <el-form-item label="来源销售订单" prop="sales_order_id">
              <el-select v-model="form.sales_order_id" filterable :disabled="isEdit" placeholder="选择已确认且未全部出库的订单" style="width:100%" @change="handleOrderChange">
                <el-option v-for="o in orderOptions" :key="o.id" :label="`${o.order_no} - ${o.customer_name} - ${o.items && o.items[0] ? o.items[0].product_name : ''}`" :value="o.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="客户名称" prop="customer_name">
              <el-input v-model="form.customer_name" disabled placeholder="从订单自动带出" />
            </el-form-item>
            <el-form-item label="出库类型" prop="out_type">
              <el-select v-model="form.out_type" style="width:100%">
                <el-option :value="3" label="销售出库" />
              </el-select>
            </el-form-item>
            <el-form-item label="出库仓库" prop="warehouse_id">
              <el-select v-model="form.warehouse_id" filterable placeholder="请选择仓库" style="width:100%" @change="handleWarehouseChange">
                <el-option v-for="w in warehouseOptions" :key="w.id" :label="w.warehouse_name" :value="w.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="出库日期" prop="out_date">
              <el-date-picker v-model="form.out_date" type="date" value-format="yyyy-MM-dd" placeholder="请选择日期" style="width:100%" />
            </el-form-item>
            <el-form-item label="出库人" prop="out_user_id">
              <el-select v-model="form.out_user_id" filterable placeholder="请选择出库人" style="width:100%">
                <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="备注">
              <el-input v-model="form.remark" type="textarea" :rows="3" placeholder="备注（选填）" />
            </el-form-item>
          </el-col>
          <!-- 第二列：收货信息 -->
          <el-col :span="12">
            <el-form-item label="收货人" prop="consignee">
              <el-input v-model="form.consignee" placeholder="从订单带出，可修改" />
            </el-form-item>
            <el-form-item label="收货电话" prop="consignee_phone">
              <el-input v-model="form.consignee_phone" placeholder="从订单带出，可修改" maxlength="20" />
            </el-form-item>
            <el-form-item label="发货地址" prop="delivery_address">
              <el-input v-model="form.delivery_address" type="textarea" :rows="2" placeholder="从订单/客户带出，可修改" />
            </el-form-item>
            <el-alert type="info" :closable="false" show-icon title="物流公司、物流单号等发货信息将在确认出库后的「登记发货」环节填写。" style="margin-top:4px;" />
          </el-col>
        </el-row>
      </el-form>
    </el-card>

    <el-card shadow="never" class="items-card">
      <div slot="header" class="items-header">
        <span>出库明细（共 {{ items.length }} 项，总数量 {{ totalQuantity }}，总金额 {{ money(totalAmount) }}）</span>
        <el-button size="mini" icon="el-icon-download" :disabled="!form.sales_order_id" @click="importFromOrder">从订单加载明细</el-button>
      </div>
      <el-table :data="items" size="small" border empty-text="请选择来源销售订单并加载明细">
        <el-table-column type="index" label="#" width="42" align="center" />
        <el-table-column prop="product_code" label="产品编码" width="100" />
        <el-table-column prop="product_name" label="产品名称" min-width="110" show-overflow-tooltip />
        <el-table-column prop="specification" label="规格型号" width="100" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="45" align="center" />
        <el-table-column label="订单数量" width="80" align="right"><template slot-scope="s">{{ s.row.order_quantity }}</template></el-table-column>
        <el-table-column label="已出库" width="80" align="right"><template slot-scope="s">{{ s.row.out_quantity }}</template></el-table-column>
        <el-table-column label="本次出库" width="120">
          <template slot-scope="s">
            <el-input-number v-model="s.row.quantity" :min="0.01" :max="s.row.available_quantity" :precision="4" size="mini" style="width:100%" @change="v => onQtyChange(s.row, v)" />
          </template>
        </el-table-column>
        <el-table-column label="出库单价" width="110">
          <template slot-scope="s"><el-input-number v-model="s.row.unit_price" :min="0" :precision="4" :controls="false" size="mini" style="width:100%" /></template>
        </el-table-column>
        <el-table-column label="出库总价" width="100" align="right">
          <template slot-scope="s">¥ {{ (Number(s.row.quantity || 0) * Number(s.row.unit_price || 0)).toFixed(2) }}</template>
        </el-table-column>
        <el-table-column label="存放货位" width="120">
          <template slot-scope="s">
            <el-select v-model="s.row.location_id" filterable size="mini" placeholder="必选" style="width:100%">
              <el-option v-for="l in locationOptions" :key="l.id" :label="l.location_name" :value="l.id" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="批次号" width="90">
          <template slot-scope="s"><el-input v-model="s.row.batch_no" size="mini" placeholder="可选" /></template>
        </el-table-column>
        <el-table-column label="设备编号/序列号" width="110">
          <template slot-scope="s"><el-input v-model="s.row.serial_number" size="mini" placeholder="必填" /></template>
        </el-table-column>
        <el-table-column label="操作" width="55" align="center">
          <template slot-scope="s"><el-button type="text" size="mini" class="danger" @click="items.splice(s.$index, 1)">删</el-button></template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { getSalesOutDetail, saveSalesOut, getAvailableOrders } from '@/api/sales'
import { getWarehouseList, getLocationList } from '@/api/warehouse'
import { getUserList } from '@/api/user'

export default {
  name: 'SalesOutAdd',
  data () {
    return {
      isEdit: false, saving: false, loadingOrder: false,
      orderOptions: [], orderMap: {}, warehouseOptions: [], locationOptions: [], userOptions: [],
      items: [],
      form: {
        id: 0, out_no: '', sales_order_id: 0, customer_name: '', out_type: 3, warehouse_id: 0,
        out_date: new Date().toISOString().slice(0, 10), out_user_id: 0,
        consignee: '', consignee_phone: '', delivery_address: '', remark: ''
      },
      rules: {
        sales_order_id: [{ required: true, message: '请选择来源销售订单', trigger: 'change' }],
        customer_name: [{ required: true, message: '客户名称缺失', trigger: 'blur' }],
        warehouse_id: [{ required: true, message: '请选择出库仓库', trigger: 'change' }],
        out_date: [{ required: true, message: '请选择出库日期', trigger: 'change' }],
        out_user_id: [{ required: true, message: '请选择出库人', trigger: 'change' }],
        consignee: [{ required: true, message: '请填写收货人', trigger: 'blur' }],
        consignee_phone: [{ required: true, message: '请填写收货电话', trigger: 'blur' }],
        delivery_address: [{ required: true, message: '请填写发货地址', trigger: 'blur' }]
      }
    }
  },
  computed: {
    totalQuantity () { return this.items.reduce((s, x) => s + Number(x.quantity || 0), 0) },
    totalAmount () { return this.items.reduce((s, x) => s + Number(x.quantity || 0) * Number(x.unit_price || 0), 0) }
  },
  created () {
    this.isEdit = !!this.$route.params.id
    this.loadBase()
    if (this.isEdit) this.loadDetail(Number(this.$route.params.id))
  },
  methods: {
    money (v) { const n = Number(v) || 0; return n ? '¥ ' + n.toLocaleString('zh-CN', { minimumFractionDigits: 2 }) : '-' },
    async loadBase () {
      try {
        const [o, w, u] = await Promise.all([getAvailableOrders(), getWarehouseList({ page: 1, pageSize: 100 }), getUserList({ page: 1, limit: 500 })])
        this.orderOptions = (o.code === 0 && o.data && o.data.list) ? o.data.list : []
        this.orderOptions.forEach(x => { this.orderMap[x.id] = x })
        this.warehouseOptions = (w.code === 0 && w.data && w.data.list) ? w.data.list : []
        this.userOptions = (u.data && u.data.list) || []
        const cur = this.userOptions.find(x => x.id === (this.$store.state.user.userInfo && this.$store.state.user.userInfo.id))
        if (!this.isEdit) this.form.out_user_id = cur ? cur.id : (this.userOptions[0] ? this.userOptions[0].id : 0)
      } catch (e) {}
    },
    async loadLocations () {
      if (!this.form.warehouse_id) { this.locationOptions = []; return }
      try {
        const r = await getLocationList({ warehouse_id: this.form.warehouse_id, page: 1, pageSize: 200 })
        this.locationOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
      } catch (e) { this.locationOptions = [] }
    },
    handleOrderChange (sid) {
      const s = this.orderMap[sid]
      if (!s) return
      this.form.customer_name = s.customer_name || ''
      this.form.consignee = s.contact_person || ''
      this.form.consignee_phone = s.contact_phone || ''
      this.form.delivery_address = s.delivery_address || ''
      this.importItems(s.items)
    },
    handleWarehouseChange () { this.loadLocations() },
    importFromOrder () {
      const s = this.orderMap[this.form.sales_order_id]
      if (!s) return
      if (this.items.length) {
        this.$confirm('加载将覆盖当前明细列表，是否继续？', '提示', { type: 'warning' }).then(() => this.importItems(s.items)).catch(() => {})
        return
      }
      this.importItems(s.items)
    },
    importItems (srcItems) {
      this.items = (srcItems || []).map(it => ({
        product_id: it.product_id, product_code: it.product_code, product_name: it.product_name,
        specification: it.specification, unit: it.unit,
        order_quantity: Number(it.order_quantity) || 0, out_quantity: Number(it.out_quantity) || 0,
        available_quantity: Number(it.available_quantity) || 0,
        quantity: Number(it.available_quantity) || 0, unit_price: Number(it.avg_price) || 0,
        location_id: 0, location_name: '', batch_no: '', serial_number: '', remark: ''
      }))
    },
    onQtyChange (row, v) {
      if (Number(v) > Number(row.available_quantity)) {
        this.$message.warning(`出库数量不能超过可出库数量（${row.available_quantity}）`)
        row.quantity = Number(row.available_quantity)
      }
    },
    async loadDetail (id) {
      try {
        const r = await getSalesOutDetail(id)
        if (r.code === 0 && r.data) {
          const d = r.data
          this.form = {
            id: d.id, out_no: d.out_no || '', sales_order_id: d.sales_order_id, customer_name: d.customer_name || '',
            out_type: 3, warehouse_id: d.warehouse_id, out_date: d.out_date || '', out_user_id: d.out_user_id || 0,
            consignee: d.consignee || '', consignee_phone: d.consignee_phone || '',
            delivery_address: d.delivery_address || '', remark: d.remark || ''
          }
          this.items = (d.items || []).map(it => ({
            product_id: it.product_id, product_code: it.product_code, product_name: it.product_name,
            specification: it.specification, unit: it.unit,
            order_quantity: Number(it.quantity) || 0, out_quantity: 0, available_quantity: Number(it.quantity) || 0,
            quantity: Number(it.quantity) || 0, unit_price: Number(it.unit_price) || 0,
            location_id: it.location_id || 0, location_name: it.location_name || '', batch_no: it.batch_no || '',
            serial_number: it.serial_number || '', remark: it.remark || ''
          }))
          if (d.warehouse_id) this.loadLocations()
        } else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
    },
    handleBack () {
      if (this.form.sales_order_id || this.form.consignee || this.items.length) {
        this.$confirm('确认离开吗？未保存的内容将丢失', '提示', { type: 'warning' }).then(() => {
          this.$router.push({ path: '/business/sales/out/list' })
        }).catch(() => {})
        return
      }
      this.$router.push({ path: '/business/sales/out/list' })
    },
    handleSave () {
      this.$refs.form.validate(valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        if (!this.items.length) { this.$message.warning('请至少添加一条出库明细'); return }
        const bad = this.items.find(it => !Number(it.quantity) || !it.location_id || !it.serial_number)
        if (bad) { this.$message.warning('请完善明细的出库数量、存放货位和序列号'); return }
        this.saving = true
        const payload = {
          id: this.form.id, out_type: 3, sales_order_id: this.form.sales_order_id,
          customer_id: (this.orderMap[this.form.sales_order_id] || {}).customer_id || 0,
          customer_name: this.form.customer_name,
          delivery_address: this.form.delivery_address,
          consignee: this.form.consignee, consignee_phone: this.form.consignee_phone,
          warehouse_id: this.form.warehouse_id, out_user_id: this.form.out_user_id,
          out_date: this.form.out_date, remark: this.form.remark,
          items: this.items.map(it => ({
            product_id: it.product_id, product_code: it.product_code, product_name: it.product_name,
            specification: it.specification, unit: it.unit, quantity: it.quantity,
            serial_number: it.serial_number, location_id: it.location_id, remark: it.remark || ''
          }))
        }
        saveSalesOut(payload).then(r => {
          if (r.code === 0) {
            this.$message.success(r.msg || '保存成功')
            this.$router.push({ path: '/business/sales/out/list' })
          } else this.$message.error(r.msg || '保存失败')
        }).catch(() => {}).finally(() => { this.saving = false })
      })
    }
  }
}
</script>

<style scoped>
.wh-page { padding: 16px; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.page-title { font-size: 18px; font-weight: bold; }
.form-card { margin-bottom: 16px; }
.items-card { margin-bottom: 16px; }
.items-header { display: flex; justify-content: space-between; align-items: center; }
.danger { color: #F56C6C; }
</style>
