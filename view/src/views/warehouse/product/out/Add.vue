<!--
  文件：admin/src/views/warehouse/product/out/Add.vue
  功能：新增/编辑产品出库单（出库类型 + 来源单据带出 + 多明细 + 库存校验）
  权限：warehouse:product:out:add / edit
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>仓储管理</el-breadcrumb-item>
      <el-breadcrumb-item>设备出入库</el-breadcrumb-item>
      <el-breadcrumb-item>产品出库</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑产品出库单' : '新增产品出库单' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ isEdit ? `编辑产品出库单 - ${form.out_no || ''}` : '新增产品出库单' }}</span>
      <div>
        <el-button size="small" @click="handleBack">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </div>

    <el-card shadow="never" class="form-card">
      <el-form ref="form" :model="form" :rules="rules" label-width="120px" size="small">
        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="出库类型" prop="out_type">
              <el-select v-model="form.out_type" placeholder="请选择出库类型" style="width:100%" @change="handleOutTypeChange">
                <el-option v-for="(t, v) in OUT_TYPES" :key="v" :label="t" :value="Number(v)" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col v-if="form.out_type === 1" :span="12">
            <el-form-item label="维修工单" prop="repair_order_id">
              <el-select v-model="form.repair_order_id" filterable remote :remote-method="searchRepair" :loading="repairLoading" placeholder="请输入编号/设备名称搜索" style="width:100%" @change="handleRepairChange">
                <el-option v-for="p in repairOptions" :key="p.id" :label="`${p.order_code} - ${p.device_name}`" :value="p.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col v-if="form.out_type === 3" :span="12">
            <el-form-item label="销售订单" prop="sales_order_id">
              <el-select v-model="form.sales_order_id" filterable remote :remote-method="searchSales" :loading="salesLoading" placeholder="请输入订单编号/客户名称搜索" style="width:100%" @change="handleSalesChange">
                <el-option v-for="p in salesOptions" :key="p.id" :label="`${p.order_no} - ${p.customer_name}`" :value="p.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="客户名称" prop="customer_id">
              <el-select v-model="form.customer_id" filterable placeholder="请选择客户" style="width:100%" @change="handleCustomerChange">
                <el-option v-for="c in customerOptions" :key="c.id" :label="c.customer_name" :value="c.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="交付地址">
              <el-input v-model="form.delivery_address" placeholder="交付/发货地址（可选）" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="出库仓库" prop="warehouse_id">
              <el-select v-model="form.warehouse_id" filterable placeholder="请选择仓库" style="width:100%" @change="handleWarehouseChange">
                <el-option v-for="w in warehouseOptions" :key="w.id" :label="w.warehouse_name" :value="w.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="出库人" prop="out_user_id">
              <el-select v-model="form.out_user_id" filterable placeholder="请选择出库人" style="width:100%">
                <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="出库日期" prop="out_date">
              <el-date-picker v-model="form.out_date" type="date" value-format="yyyy-MM-dd" placeholder="请选择日期" style="width:100%" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </el-card>

    <el-card shadow="never" class="logs-card">
      <div slot="header" class="logs-header">
        <span>出库明细（共 {{ items.length }} 项，总数量 {{ totalQuantity }}，总金额 ¥{{ totalAmount.toFixed(2) }}）</span>
        <div>
          <el-button v-if="hasSource" size="mini" icon="el-icon-download" @click="importFromSource">从来源单据导入明细</el-button>
          <el-button size="mini" icon="el-icon-plus" @click="openProductDialog">添加产品</el-button>
        </div>
      </div>
      <el-table :data="items" size="small" border empty-text="请选择来源单据导入或手动添加产品">
        <el-table-column type="index" label="#" width="45" align="center" />
        <el-table-column prop="product_code" label="产品编码" width="110" />
        <el-table-column prop="product_name" label="产品名称" min-width="130" show-overflow-tooltip />
        <el-table-column prop="specification" label="规格型号" width="110" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="50" align="center" />
        <el-table-column label="出库数量" width="110">
          <template slot-scope="s"><el-input-number v-model="s.row.quantity" :min="0.01" :max="s.row.remaining_quantity" :precision="4" size="mini" style="width:100%" /></template>
        </el-table-column>
        <el-table-column label="出库单价" width="110">
          <template slot-scope="s"><el-input :value="Number(s.row.unit_price || 0).toFixed(4)" size="mini" disabled /></template>
        </el-table-column>
        <el-table-column label="出库总价" width="110" align="right">
          <template slot-scope="s">¥ {{ (Number(s.row.quantity || 0) * Number(s.row.unit_price || 0)).toFixed(2) }}</template>
        </el-table-column>
        <el-table-column label="设备编号/序列号" width="130">
          <template slot-scope="s"><el-input v-model="s.row.serial_number" size="mini" placeholder="必填" /></template>
        </el-table-column>
        <el-table-column label="出库货位" width="130">
          <template slot-scope="s">
            <el-select v-model="s.row.location_id" filterable size="mini" placeholder="货位" style="width:100%">
              <el-option v-for="l in locationOptions" :key="l.id" :label="l.location_name" :value="l.id" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="备注" width="110">
          <template slot-scope="s"><el-input v-model="s.row.remark" size="mini" placeholder="可选" /></template>
        </el-table-column>
        <el-table-column label="操作" width="65" align="center">
          <template slot-scope="s"><el-button type="text" size="mini" class="danger" @click="items.splice(s.$index, 1)">删除</el-button></template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-card shadow="never" class="logs-card">
      <el-form label-width="120px" size="small">
        <el-form-item label="备注"><el-input v-model="form.remark" type="textarea" :rows="3" placeholder="补充说明（可选）" /></el-form-item>
      </el-form>
    </el-card>

    <el-dialog title="选择产品" :visible.sync="productDialog" width="640px">
      <el-input v-model="productKeyword" placeholder="输入产品名称/编码搜索" clearable style="margin-bottom:12px" @keyup.enter.native="searchProducts" />
      <el-table :data="productOptions" size="small" border max-height="360" @row-click="addProduct">
        <el-table-column prop="product_code" label="产品编码" width="130" />
        <el-table-column prop="product_name" label="产品名称" min-width="150" show-overflow-tooltip />
        <el-table-column prop="specification" label="规格型号" width="120" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="60" align="center" />
        <el-table-column label="" width="70" align="center"><template><el-button type="text" size="mini">选择</el-button></template></el-table-column>
      </el-table>
      <div v-if="!productOptions.length" class="empty-tip">暂无数据，请搜索</div>
    </el-dialog>
  </div>
</template>

<script>
import { getProductOutDetail, saveProductOut, getRepairReadyOut, getSalesReadyOut, getWarehouseList, getLocationList, getCustomerOptions, getProductSearch } from '../../../../api/warehouse'
import { getUserList } from '../../../../api/user'

const OUT_TYPES = { 1: '维修完成交付', 2: '调拨出库', 3: '销售出库', 4: '其他出库' }

export default {
  name: 'WarehouseProductOutAdd',
  data () {
    return {
      OUT_TYPES,
      isEdit: false, saving: false,
      repairOptions: [], salesOptions: [], repairLoading: false, salesLoading: false, repairMap: {}, salesMap: {},
      warehouseOptions: [], locationOptions: [], customerOptions: [], customerMap: {}, userOptions: [],
      productDialog: false, productKeyword: '', productOptions: [],
      form: {
        id: 0, out_no: '', out_type: 1, repair_order_id: 0, repair_order_no: '', sales_order_id: 0, sales_order_no: '',
        customer_id: 0, customer_name: '', delivery_address: '', warehouse_id: 0, warehouse_name: '',
        out_user_id: 0, out_date: this.today(), remark: ''
      },
      items: [],
      rules: {
        out_type: [{ required: true, message: '请选择出库类型', trigger: 'change' }],
        warehouse_id: [{ required: true, message: '请选择出库仓库', trigger: 'change' }],
        out_user_id: [{ required: true, message: '请选择出库人', trigger: 'change' }],
        out_date: [{ required: true, message: '请选择出库日期', trigger: 'change' }]
      }
    }
  },
  computed: {
    hasSource () { return (this.form.out_type === 1 && this.form.repair_order_id) || (this.form.out_type === 3 && this.form.sales_order_id) },
    totalQuantity () { return this.items.reduce((s, it) => s + (Number(it.quantity) || 0), 0) },
    totalAmount () { return this.items.reduce((s, it) => s + (Number(it.quantity) || 0) * (Number(it.unit_price) || 0), 0) }
  },
  created () {
    this.isEdit = !!this.$route.params.id
    this.loadWarehouses(); this.loadUsers(); this.loadCustomers()
    if (this.form.out_type === 1) this.searchRepair('')
    if (this.form.out_type === 3) this.searchSales('')
    if (this.isEdit) this.loadDetail(Number(this.$route.params.id))
  },
  methods: {
    today () {
      const d = new Date()
      return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
    },
    async loadWarehouses () {
      try {
        const r = await getWarehouseList({ page: 1, pageSize: 100, status: 1 })
        this.warehouseOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
      } catch (e) { this.warehouseOptions = [] }
    },
    async loadLocations () {
      if (!this.form.warehouse_id) { this.locationOptions = []; return }
      try {
        const r = await getLocationList({ warehouse_id: this.form.warehouse_id, page: 1, pageSize: 100 })
        this.locationOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
      } catch (e) { this.locationOptions = [] }
    },
    async loadUsers () {
      try {
        const r = await getUserList({ page: 1, limit: 200 })
        this.userOptions = (r.data && r.data.list) || []
        if (!this.isEdit && this.userOptions.length) {
          const cur = this.userOptions.find(u => u.id === (this.$store.state.user.userInfo && this.$store.state.user.userInfo.id))
          this.form.out_user_id = cur ? cur.id : this.userOptions[0].id
        }
      } catch (e) { this.userOptions = [] }
    },
    async loadCustomers () {
      try {
        const r = await getCustomerOptions()
        this.customerOptions = (r.code === 0 && r.data) ? r.data : []
        this.customerOptions.forEach(c => { this.customerMap[c.id] = c })
      } catch (e) { this.customerOptions = [] }
    },
    async searchRepair (kw) {
      this.repairLoading = true
      try {
        const r = await getRepairReadyOut(kw || '')
        this.repairOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
        this.repairOptions.forEach(p => { this.repairMap[p.id] = p })
      } catch (e) { this.repairOptions = [] } finally { this.repairLoading = false }
    },
    async searchSales (kw) {
      this.salesLoading = true
      try {
        const r = await getSalesReadyOut(kw || '')
        this.salesOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
        this.salesOptions.forEach(p => { this.salesMap[p.id] = p })
      } catch (e) { this.salesOptions = [] } finally { this.salesLoading = false }
    },
    async searchProducts () {
      const kw = this.productKeyword || ''
      try {
        const r = await getProductSearch(kw)
        this.productOptions = (r.code === 0 && r.data) ? r.data : []
      } catch (e) { this.productOptions = [] }
    },
    handleOutTypeChange (v) {
      this.form.repair_order_id = 0; this.form.repair_order_no = ''
      this.form.sales_order_id = 0; this.form.sales_order_no = ''
      this.items = []
      if (v === 1) this.searchRepair('')
      else if (v === 3) this.searchSales('')
    },
    handleRepairChange (rid) {
      const s = this.repairMap[rid]
      if (!s) return
      this.form.repair_order_no = s.order_code || ''
      this.form.customer_id = s.customer_id || 0
      this.form.customer_name = s.customer_name || ''
      this.form.delivery_address = s.delivery_address || ''
      this.handleCustomerChange(this.form.customer_id)
      this.importItems(s.items)
    },
    handleSalesChange (sid) {
      const s = this.salesMap[sid]
      if (!s) return
      this.form.sales_order_no = s.order_no || ''
      this.form.customer_id = s.customer_id || 0
      this.form.customer_name = s.customer_name || ''
      this.form.delivery_address = ''
      this.handleCustomerChange(this.form.customer_id)
      this.importItems(s.items)
    },
    handleCustomerChange (cid) {
      const c = this.customerMap[cid]
      if (c && c.address && !this.form.delivery_address) this.form.delivery_address = c.address
    },
    handleWarehouseChange () {
      this.form.warehouse_name = (this.warehouseOptions.find(w => w.id === this.form.warehouse_id) || {}).warehouse_name || ''
      this.loadLocations()
    },
    importFromSource () {
      const s = this.form.out_type === 1 ? this.repairMap[this.form.repair_order_id] : this.salesMap[this.form.sales_order_id]
      if (!s) return
      if (this.items.length) {
        this.$confirm('导入将覆盖当前明细列表，是否继续？', '提示', { type: 'warning' }).then(() => this.importItems(s.items)).catch(() => {})
      } else this.importItems(s.items)
    },
    importItems (srcItems) {
      this.items = (srcItems || []).filter(it => Number(it.available_quantity) > 0).map(it => ({
        product_id: it.product_id, product_code: it.product_code, product_name: it.product_name,
        specification: it.specification, unit: it.unit,
        quantity: Number(it.available_quantity) || 0, unit_price: Number(it.avg_price) || 0,
        serial_number: it.serial_number || '', location_id: it.location_id || 0, location_name: it.location_name || '',
        remark: it.remark || '', remaining_quantity: Number(it.available_quantity) || 0, stock: it.stock || 0
      }))
    },
    openProductDialog () {
      this.productKeyword = ''; this.productOptions = []
      this.productDialog = true
      this.searchProducts()
    },
    addProduct (row) {
      if (this.items.some(it => it.product_id === row.id)) { this.$message.warning('该产品已在明细中'); return }
      this.items.push({
        product_id: row.id, product_code: row.product_code, product_name: row.product_name,
        specification: row.specification || '', unit: row.unit || '',
        quantity: 1, unit_price: 0, serial_number: '', location_id: 0, location_name: '',
        remark: '', remaining_quantity: 999999, stock: 0
      })
      this.$message.success('已添加，请填写数量/序列号/货位')
    },
    async loadDetail (id) {
      try {
        const r = await getProductOutDetail(id)
        if (r.code === 0 && r.data) {
          const d = r.data
          this.form = {
            id: d.id, out_no: d.out_no, out_type: d.out_type,
            repair_order_id: d.repair_order_id, repair_order_no: d.repair_order_no || '',
            sales_order_id: d.sales_order_id, sales_order_no: d.sales_order_no || '',
            customer_id: d.customer_id, customer_name: d.customer_name || '',
            delivery_address: d.delivery_address || '', warehouse_id: d.warehouse_id, warehouse_name: d.warehouse_name || '',
            out_user_id: d.out_user_id, out_date: d.out_date, remark: d.remark || ''
          }
          this.items = (d.items || []).map(it => ({
            product_id: it.product_id, product_code: it.product_code, product_name: it.product_name,
            specification: it.specification, unit: it.unit,
            quantity: Number(it.quantity) || 0, unit_price: Number(it.unit_price) || 0,
            serial_number: it.serial_number || '', location_id: it.location_id || 0, location_name: it.location_name || '',
            remark: it.remark || '', remaining_quantity: 999999, stock: 0
          }))
          this.loadLocations()
        } else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
    },
    handleBack () {
      if (this.items.length) {
        this.$confirm('当前有未保存的内容，确认离开吗？', '提示', { type: 'warning' }).then(() => {
          this.$router.push({ path: '/warehouse/product/out/list' })
        }).catch(() => {})
        return
      }
      this.$router.push({ path: '/warehouse/product/out/list' })
    },
    handleSave () {
      this.$refs.form.validate(async valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        if (this.form.out_type === 1 && !this.form.repair_order_id) { this.$message.warning('请选择维修工单'); return }
        if (this.form.out_type === 3 && !this.form.sales_order_id) { this.$message.warning('请选择销售订单'); return }
        if (!this.form.customer_id) { this.$message.warning('请选择客户'); return }
        if (!this.items.length) { this.$message.warning('请至少添加一条出库明细'); return }
        const invalid = this.items.find(it => !it.quantity || it.quantity <= 0 || !it.serial_number || !it.location_id)
        if (invalid) { this.$message.warning('请完善明细：数量大于 0、设备编号与出库货位必填'); return }
        const overStock = this.items.find(it => Number(it.stock) > 0 && Number(it.quantity) > Number(it.stock))
        if (overStock) {
          this.$message.warning(`产品 ${overStock.product_name} 库存不足，当前库存为 ${Number(overStock.stock).toFixed(4)}`)
          return
        }
        this.saving = true
        try {
          const r = await saveProductOut({ ...this.form, items: this.items })
          if (r.code === 0) {
            this.$message.success(r.msg || '保存成功')
            this.$router.push({ path: '/warehouse/product/out/list' })
          } else this.$message.error(r.msg || '保存失败')
        } catch (e) {} finally { this.saving = false }
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
.logs-card { margin-bottom: 16px; }
.logs-header { display: flex; justify-content: space-between; align-items: center; }
.danger { color: #F56C6C; }
.empty-tip { color: #909399; font-size: 13px; text-align: center; padding: 16px 0; }
</style>
