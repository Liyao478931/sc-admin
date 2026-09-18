<!--
  文件：admin/src/views/business/purchase/arrival/Add.vue
  功能：新增/编辑到货登记（选择已发货订单自动带入供应商与明细）
  权限：business:purchase:arrival:add / edit
-->
<template>
  <div class="ar-add-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购到货</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑到货单' : '新增到货登记' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">{{ isEdit ? '编辑到货单 - ' + form.arrival_no : '新增到货登记' }}</span>
      <div class="header-actions">
        <el-button type="primary" size="small" :loading="saving" @click="handleSave">保存</el-button>
        <el-button size="small" @click="$router.push('/business/purchase/arrival/list')">取消</el-button>
      </div>
    </div>

    <el-card shadow="never">
      <el-form ref="form" :model="form" :rules="rules" label-width="120px" size="small">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="关联采购订单" prop="order_id">
              <el-select v-model="form.order_id" filterable :disabled="isEdit" placeholder="选择已发货的采购订单" style="width:100%" @change="onOrderChange">
                <el-option v-for="o in orderOptions" :key="o.id" :label="o.order_no + ' - ' + (o.supplier_name || '') + (o.title ? ' - ' + o.title : '')" :value="o.id" />
              </el-select>
            </el-form-item>
            <el-form-item label="供应商" prop="supplier_id">
              <el-input v-model="supplierName" disabled placeholder="选择订单后自动带出" />
            </el-form-item>
            <el-form-item label="物流公司" prop="logistics_company">
              <el-input v-model="form.logistics_company" placeholder="承运物流公司" maxlength="100" />
            </el-form-item>
            <el-form-item label="物流单号" prop="track_no">
              <el-input v-model="form.track_no" placeholder="快递单号" maxlength="60" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="到货日期" prop="arrival_date">
              <el-date-picker v-model="form.arrival_date" type="date" value-format="yyyy-MM-dd" style="width:100%" />
            </el-form-item>
            <el-form-item label="收货人" prop="receiver">
              <el-input v-model="form.receiver" placeholder="签收人" maxlength="50" />
            </el-form-item>
            <el-form-item label="备注">
              <el-input v-model="form.remark" type="textarea" :rows="3" placeholder="补充说明（可选）" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </el-card>

    <!-- 到货明细 -->
    <el-card shadow="never" style="margin-top:14px;">
      <div class="section-title">到货明细</div>
      <el-table :data="items" size="small" border empty-text="请先选择关联采购订单">
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column prop="product_code" label="产品编码" width="120" show-overflow-tooltip />
        <el-table-column prop="product_name" label="产品名称" min-width="140" show-overflow-tooltip />
        <el-table-column prop="product_spec" label="规格型号" width="100" show-overflow-tooltip />
        <el-table-column prop="product_unit" label="单位" width="55" align="center" />
        <el-table-column prop="order_quantity" label="订单数量" width="90" align="right" />
        <el-table-column label="到货数量" width="110">
          <template slot-scope="s">
            <el-input-number v-model="s.row.arrival_quantity" :min="0" :precision="0" :max="s.row.order_quantity" size="small" style="width:100%" @change="v => onQtyChange(s.$index, v)" />
          </template>
        </el-table-column>
        <el-table-column label="备注" min-width="120">
          <template slot-scope="s"><el-input v-model="s.row.remark" size="small" placeholder="选填" /></template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script>
import { saveArrival, getArrivalDetail, getArrivableOrders } from '../../../../api/purchase'

export default {
  name: 'PurchaseArrivalAdd',
  data () {
    return {
      id: Number(this.$route.query.id) || 0,
      isEdit: false,
      saving: false,
      orderOptions: [],
      supplierName: '',
      form: {
        order_id: null, supplier_id: 0, arrival_no: '', arrival_date: this.today(), logistics_company: '', track_no: '', receiver: '', remark: ''
      },
      items: [],
      rules: {
        order_id: [{ required: true, message: '请选择关联采购订单', trigger: 'change' }],
        supplier_id: [{ required: true, message: '供应商必填', trigger: 'change' }],
        arrival_date: [{ required: true, message: '请选择到货日期', trigger: 'change' }]
      }
    }
  },
  created () {
    this.isEdit = this.id > 0
    // 默认收货人：当前登录用户
    const u = this.$store && this.$store.state && this.$store.state.user
    if (u) this.form.receiver = u.real_name || u.username || ''
    if (this.isEdit) this.loadDetail()
    else this.loadOrders()
  },
  methods: {
    today () { const d = new Date(); return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}` },
    async loadOrders () {
      try {
        const r = await getArrivableOrders()
        this.orderOptions = (r.code === 0 && r.data) ? r.data : []
      } catch (e) { this.orderOptions = [] }
    },
    async loadDetail () {
      try {
        const r = await getArrivalDetail(this.id)
        if (r.code === 0 && r.data) {
          const a = r.data.arrival || {}
          this.form = {
            order_id: a.order_id, supplier_id: a.supplier_id, arrival_no: a.arrival_no, arrival_date: a.arrival_date || this.today(),
            logistics_company: a.logistics_company || '', track_no: a.track_no || '', receiver: a.receiver || '', remark: a.remark || ''
          }
          this.supplierName = a.supplier_name || ''
          this.items = (r.data.items || []).map(it => ({
            order_item_id: it.order_item_id, product_id: it.product_id, product_code: it.product_code, product_name: it.product_name,
            product_spec: it.product_spec || '', product_unit: it.product_unit || '', order_quantity: it.order_quantity,
            arrival_quantity: it.arrival_quantity, remark: it.remark || ''
          }))
        }
      } catch (e) {}
    },
    onOrderChange (orderId) {
      const o = this.orderOptions.find(x => x.id === orderId)
      this.supplierName = o ? (o.supplier_name || '') : ''
      this.form.supplier_id = o ? (o.supplier_id || 0) : 0
      // 自动同步：物流公司/单号从订单带出；到货日期取推送签收时间
      if (o && o.express_name) this.form.logistics_company = o.express_name
      if (o && o.track_no) this.form.track_no = o.track_no
      if (o && o.arrival_date) this.form.arrival_date = o.arrival_date
      this.items = (o && o.items ? o.items : []).map(it => ({
        order_item_id: it.id, product_id: it.product_id, product_code: it.product_code, product_name: it.product_name,
        product_spec: it.product_spec || '', product_unit: it.product_unit || '', order_quantity: Number(it.quantity) || 0,
        arrival_quantity: Number(it.quantity) || 0, remark: ''
      }))
    },
    onQtyChange (idx, v) {
      const it = this.items[idx]
      if (it && it.order_quantity > 0 && Number(v) > Number(it.order_quantity)) {
        it.arrival_quantity = Number(it.order_quantity)
        this.$message.warning('到货数量不能超过订单数量（' + it.order_quantity + '）')
      }
    },
    async handleSave () {
      const valid = await this.$refs.form.validate().catch(() => false)
      if (!valid) { this.$message.warning('请完善必填项'); return }
      if (!this.items.length) { this.$message.warning('请至少添加一条到货明细'); return }
      if (this.items.some(it => !(Number(it.arrival_quantity) > 0))) { this.$message.warning('到货数量必须大于 0'); return }
      this.saving = true
      try {
        const r = await saveArrival({
          id: this.id || null,
          order_id: this.form.order_id, supplier_id: this.form.supplier_id, arrival_date: this.form.arrival_date,
          logistics_company: this.form.logistics_company, track_no: this.form.track_no, receiver: this.form.receiver, remark: this.form.remark,
          items: this.items.map(it => ({ order_item_id: it.order_item_id, product_id: it.product_id, product_code: it.product_code, product_name: it.product_name, product_spec: it.product_spec, product_unit: it.product_unit, order_quantity: it.order_quantity, arrival_quantity: it.arrival_quantity, remark: it.remark }))
        })
        if (r.code === 0) { this.$message.success('保存成功'); this.$router.push('/business/purchase/arrival/list') }
        else this.$message.error(r.msg || '保存失败')
      } catch (e) {} finally { this.saving = false }
    }
  }
}
</script>

<style scoped>
.ar-add-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.breadcrumb { margin-bottom: 12px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 700; color: #303133; }
.section-title { font-size: 15px; font-weight: 600; margin-bottom: 12px; }
</style>
