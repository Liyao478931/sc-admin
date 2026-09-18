<!--
  文件：admin/src/views/business/sales/ship/notice/Add.vue
  功能：新增/编辑发货通知（来源销售订单 → 自动填充客户/收货/明细，通知数量校验）
  权限：sales:ship:notice:add / edit
-->
<template>
  <div class="wh-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>销售管理</el-breadcrumb-item>
      <el-breadcrumb-item>发货管理</el-breadcrumb-item>
      <el-breadcrumb-item>发货通知</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑通知' : '新增通知' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ isEdit ? `编辑发货通知 - ${form.notice_no || ''}` : '新增发货通知' }}</span>
      <div>
        <el-button size="small" @click="handleBack">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSave">保存</el-button>
      </div>
    </div>

    <el-card shadow="never" class="form-card">
      <el-form ref="form" :model="form" :rules="rules" label-width="120px" size="small">
        <el-row :gutter="24">
          <el-col :span="12">
            <el-form-item label="关联销售订单" prop="order_id">
              <el-select v-model="form.order_id" filterable :disabled="isEdit" placeholder="选择已确认且未全部发货的订单" style="width:100%" @change="handleOrderChange">
                <el-option v-for="o in orderOptions" :key="o.id" :label="`${o.order_no} - ${o.customer_name} - ${o.items && o.items[0] ? o.items[0].product_name : ''}`" :value="o.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="通知单名称" prop="notice_name">
              <el-input v-model="form.notice_name" placeholder="请输入通知单名称" />
            </el-form-item>
            <el-form-item label="客户名称" prop="customer_name">
              <el-input v-model="form.customer_name" disabled placeholder="从订单自动带出" />
            </el-form-item>
            <el-form-item label="发货日期" prop="ship_date">
              <el-date-picker v-model="form.ship_date" type="date" value-format="yyyy-MM-dd" placeholder="请选择发货日期" style="width:100%" />
            </el-form-item>
            <el-form-item label="备注">
              <el-input v-model="form.remark" type="textarea" :rows="3" placeholder="备注（选填）" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="收货人" prop="receiver">
              <el-input v-model="form.receiver" placeholder="从订单带出，可修改" />
            </el-form-item>
            <el-form-item label="收货电话" prop="receiver_phone">
              <el-input v-model="form.receiver_phone" placeholder="从订单带出，可修改" maxlength="20" />
            </el-form-item>
            <el-form-item label="收货地址" prop="receiver_address">
              <el-input v-model="form.receiver_address" type="textarea" :rows="2" placeholder="从订单/客户带出，可修改" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </el-card>

    <el-card shadow="never" class="items-card">
      <div slot="header" class="items-header">
        <span>通知明细（共 {{ items.length }} 项，总数量 {{ totalQuantity }}）</span>
        <el-button size="mini" icon="el-icon-download" :disabled="!form.order_id" @click="importFromOrder">从订单加载明细</el-button>
      </div>
      <el-table :data="items" size="small" border empty-text="请选择关联销售订单并加载明细">
        <el-table-column type="index" label="#" width="42" align="center" />
        <el-table-column prop="product_code" label="产品编码" width="100" />
        <el-table-column prop="product_name" label="产品名称" min-width="110" show-overflow-tooltip />
        <el-table-column prop="specification" label="规格型号" width="100" show-overflow-tooltip />
        <el-table-column prop="unit" label="单位" width="45" align="center" />
        <el-table-column label="通知数量" width="120">
          <template slot-scope="s">
            <el-input-number v-model="s.row.notice_quantity" :min="0.0001" :max="s.row.available_quantity" :precision="4" size="mini" style="width:100%" @change="v => onQtyChange(s.row, v)" />
          </template>
        </el-table-column>
        <el-table-column label="存放货位建议" width="130">
          <template slot-scope="s">
            <el-select v-model="s.row.suggest_location_id" filterable clearable size="mini" placeholder="选填" style="width:100%">
              <el-option v-for="l in locationOptions" :key="l.id" :label="l.location_name" :value="l.id" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="备注" width="100">
          <template slot-scope="s"><el-input v-model="s.row.remark" size="mini" placeholder="选填" /></template>
        </el-table-column>
        <el-table-column label="操作" width="55" align="center">
          <template slot-scope="s"><el-button type="text" size="mini" class="danger" @click="items.splice(s.$index, 1)">删</el-button></template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { getNoticeDetail, saveNotice, getAvailableShipOrders } from '@/api/sales'
import { getLocationList } from '@/api/warehouse'

export default {
  name: 'ShipNoticeAdd',
  data () {
    return {
      isEdit: false, saving: false,
      orderOptions: [], orderMap: {}, locationOptions: [],
      items: [],
      form: {
        id: 0, notice_no: '', order_id: 0, notice_name: '', customer_name: '',
        receiver: '', receiver_phone: '', receiver_address: '',
        ship_date: new Date().toISOString().slice(0, 10), remark: ''
      },
      rules: {
        order_id: [{ required: true, message: '请选择关联销售订单', trigger: 'change' }],
        notice_name: [{ required: true, message: '请填写通知单名称', trigger: 'blur' }],
        receiver: [{ required: true, message: '请填写收货人', trigger: 'blur' }],
        receiver_phone: [{ required: true, message: '请填写收货电话', trigger: 'blur' }],
        receiver_address: [{ required: true, message: '请填写收货地址', trigger: 'blur' }],
        ship_date: [{ required: true, message: '请选择发货日期', trigger: 'change' }]
      }
    }
  },
  computed: {
    totalQuantity () { return this.items.reduce((s, x) => s + Number(x.notice_quantity || 0), 0) }
  },
  created () {
    this.isEdit = !!this.$route.params.id
    this.loadOrders()
    this.loadLocations()
    if (this.isEdit) this.loadDetail(Number(this.$route.params.id))
  },
  methods: {
    async loadOrders () {
      try {
        const r = await getAvailableShipOrders()
        this.orderOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
        this.orderOptions.forEach(x => { this.orderMap[x.id] = x })
      } catch (e) { this.orderOptions = [] }
    },
    async loadLocations () {
      try {
        const r = await getLocationList({ page: 1, pageSize: 300 })
        this.locationOptions = (r.code === 0 && r.data && r.data.list) ? r.data.list : []
      } catch (e) { this.locationOptions = [] }
    },
    handleOrderChange (oid) {
      const s = this.orderMap[oid]
      if (!s) return
      this.form.customer_name = s.customer_name || ''
      this.form.receiver = s.contact_person || ''
      this.form.receiver_phone = s.contact_phone || ''
      this.form.receiver_address = s.delivery_address || ''
      if (!this.form.notice_name || this.form.notice_name.startsWith('为[')) {
        this.form.notice_name = `为[${s.order_no}]发货通知`
      }
      this.importItems(s.items)
    },
    importFromOrder () {
      const s = this.orderMap[this.form.order_id]
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
        notice_quantity: Number(it.available_quantity) || 0,
        suggest_location_id: 0, remark: ''
      }))
    },
    onQtyChange (row, v) {
      if (Number(v) > Number(row.available_quantity)) {
        this.$message.warning(`通知数量不能超过可发货数量（${row.available_quantity}）`)
        row.notice_quantity = Number(row.available_quantity)
      }
    },
    async loadDetail (id) {
      try {
        const r = await getNoticeDetail(id)
        if (r.code === 0 && r.data) {
          const d = r.data
          this.form = {
            id: d.id, notice_no: d.notice_no || '', order_id: d.order_id, notice_name: d.notice_name || '',
            customer_name: d.customer_name || '', receiver: d.receiver || '', receiver_phone: d.receiver_phone || '',
            receiver_address: d.receiver_address || '', ship_date: d.ship_date || '', remark: d.remark || ''
          }
          this.items = (d.items || []).map(it => ({
            product_id: it.product_id, product_code: it.product_code, product_name: it.product_name,
            specification: it.specification, unit: it.unit,
            order_quantity: Number(it.notice_quantity) || 0, out_quantity: Number(it.out_quantity) || 0,
            available_quantity: Number(it.notice_quantity) || 0,
            notice_quantity: Number(it.notice_quantity) || 0,
            suggest_location_id: it.suggest_location_id || 0, remark: it.remark || ''
          }))
        } else this.$message.error(r.msg || '加载失败')
      } catch (e) {}
    },
    handleBack () {
      if (this.form.order_id || this.form.receiver || this.items.length) {
        this.$confirm('确认离开吗？未保存的内容将丢失', '提示', { type: 'warning' }).then(() => {
          this.$router.push({ path: '/business/sales/ship/notice' })
        }).catch(() => {})
        return
      }
      this.$router.push({ path: '/business/sales/ship/notice' })
    },
    handleSave () {
      this.$refs.form.validate(valid => {
        if (!valid) { this.$message.warning('请完善必填项'); return }
        if (!this.items.length) { this.$message.warning('请至少添加一条通知明细'); return }
        const bad = this.items.find(it => !Number(it.notice_quantity))
        if (bad) { this.$message.warning('请完善明细的通知数量'); return }
        this.saving = true
        const payload = {
          id: this.form.id, order_id: this.form.order_id, notice_name: this.form.notice_name,
          customer_id: (this.orderMap[this.form.order_id] || {}).customer_id || 0,
          customer_name: this.form.customer_name,
          receiver: this.form.receiver, receiver_phone: this.form.receiver_phone,
          receiver_address: this.form.receiver_address, ship_date: this.form.ship_date, remark: this.form.remark,
          items: this.items.map(it => ({
            product_id: it.product_id, product_code: it.product_code, product_name: it.product_name,
            specification: it.specification, unit: it.unit, notice_quantity: it.notice_quantity,
            suggest_location_id: it.suggest_location_id || 0, remark: it.remark || ''
          }))
        }
        saveNotice(payload).then(r => {
          if (r.code === 0) {
            this.$message.success(r.msg || '保存成功')
            this.$router.push({ path: '/business/sales/ship/notice' })
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
