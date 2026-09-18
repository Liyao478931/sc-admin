<!--
  文件：admin/src/views/business/purchase/order/Add.vue
  功能：新增/编辑采购订单（来源申请需求池选择/编号唯一校验/明细产品列表选/保存并继续）
  权限：新增 business:purchase:order:add；编辑 business:purchase:order:edit
-->
<template>
  <div class="po-form-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购管理</el-breadcrumb-item>
      <el-breadcrumb-item>采购订单</el-breadcrumb-item>
      <el-breadcrumb-item>{{ isEdit ? '编辑采购订单' : '新增采购订单' }}</el-breadcrumb-item>
    </el-breadcrumb>

    <el-alert v-if="isEdit && form.request_no" type="info" :closable="false" show-icon :title="'该订单来源于采购申请：' + form.request_no + '，不可更换来源'" style="margin-bottom:12px" />

    <div class="page-header">
      <span class="page-title">{{ isEdit ? '编辑采购订单 - ' + form.order_no : '新增采购订单' }}</span>
      <div class="header-actions">
        <el-button type="primary" size="small" :loading="submitting" @click="handleSave(false)">保存</el-button>
        <el-button size="small" :loading="submitting" @click="handleSave(true)">保存并继续</el-button>
        <el-button size="small" @click="handleCancel">取消</el-button>
      </div>
    </div>

    <el-card shadow="never">
      <el-form ref="form" :model="form" :rules="rules" label-width="120px" size="small">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="来源采购申请" prop="request_id">
              <el-select v-model="form.request_id" filterable :disabled="isEdit" placeholder="选择已审批的采购申请" style="width:100%" @change="onRequestChange">
                <el-option v-for="r in poolOptions" :key="r.id" :label="r.request_code + ' - ' + r.title + ' - ' + (r.applicant_name || '')" :value="r.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="订单编号" prop="order_no">
              <el-input v-model="form.order_no" placeholder="留空自动生成 PO+日期+序号" clearable @blur="checkCode" @input="codeChecked = false" />
              <div v-if="codeError" class="code-error">{{ codeError }}</div>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="供应商" prop="supplier_id">
              <el-select v-model="form.supplier_id" filterable placeholder="选择供应商" style="width:100%">
                <el-option v-for="s in supplierOptions" :key="s.id" :label="s.supplier_name" :value="s.id" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="订单标题" prop="title">
              <el-input v-model="form.title" placeholder="从采购申请自动带入，可修改" clearable />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="订单日期" prop="order_date">
              <el-date-picker v-model="form.order_date" type="date" value-format="yyyy-MM-dd" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="期望交货日期" prop="expected_date">
              <el-date-picker v-model="form.expected_date" type="date" value-format="yyyy-MM-dd" style="width:100%" :picker-options="{ disabledDate: d => form.order_date && d.getTime() < new Date(form.order_date).getTime() }" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="运输方式">
              <el-select v-model="form.transport_type" placeholder="选择运输方式" clearable style="width:100%">
                <el-option label="公路运输" value="公路运输" />
                <el-option label="铁路运输" value="铁路运输" />
                <el-option label="航空运输" value="航空运输" />
                <el-option label="快递" value="快递" />
                <el-option label="自提" value="自提" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="收货地址">
              <el-input v-model="form.receive_address" placeholder="收货地址（可选）" clearable />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="收货人">
              <el-input v-model="form.receiver" placeholder="收货人（可选）" clearable />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="收货电话">
              <el-input v-model="form.receiver_phone" placeholder="收货电话（可选）" clearable />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="付款条款">
              <el-input v-model="form.payment_terms" placeholder="如 30%预付款，70%到货验收合格后付清" clearable />
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="用途说明">
              <el-input v-model="form.purpose" type="textarea" :rows="3" placeholder="从采购申请自动带入，可修改" />
            </el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="备注">
              <el-input v-model="form.remark" type="textarea" :rows="2" placeholder="备注（可选）" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
    </el-card>

    <!-- 订单明细 -->
    <el-card shadow="never" class="items-card">
      <div class="section-title">采购明细</div>
      <div class="toolbar">
        <el-button size="small" :disabled="isEdit || !form.request_id" @click="reloadFromRequest">从来源申请加载</el-button>
        <el-button size="small" type="primary" icon="el-icon-plus" @click="addItem">添加产品</el-button>
        <span class="flex-1"></span>
        <span class="total-tip">订单总金额：¥ {{ totalAmount }}</span>
      </div>
      <el-table :data="items" size="small" border>
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column label="产品" min-width="200">
          <template slot-scope="s">
            <ProductSelector v-model="s.row.product_id" :label-text="s.row.product_code + ' ' + s.row.product_name" @selected="p => onProductPicked(s.$index, p)" />
          </template>
        </el-table-column>
        <el-table-column prop="product_code" label="产品编码" width="110" show-overflow-tooltip />
        <el-table-column prop="product_name" label="产品名称" min-width="130" show-overflow-tooltip />
        <el-table-column prop="product_spec" label="规格型号" width="100" show-overflow-tooltip />
        <el-table-column prop="product_unit" label="单位" width="55" align="center" />
        <el-table-column label="申请数量" width="85" align="right">
          <template slot-scope="s">{{ s.row.apply_quantity || '-' }}</template>
        </el-table-column>
        <el-table-column label="下单数量" width="100">
          <template slot-scope="s">
            <el-input-number v-model="s.row.quantity" :min="0" :precision="0" :max="qtyMax(s.row)" size="small" style="width:100%" @change="v => onQtyChange(s.$index, v)" />
          </template>
        </el-table-column>
        <el-table-column label="采购单价" width="110">
          <template slot-scope="s"><el-input-number v-model="s.row.unit_price" :min="0.01" :precision="2" size="small" style="width:100%" /></template>
        </el-table-column>
        <el-table-column label="总价" width="105" align="right">
          <template slot-scope="s">¥ {{ (Number(s.row.quantity) * Number(s.row.unit_price)).toFixed(2) }}</template>
        </el-table-column>
        <el-table-column label="需求日期" width="125">
          <template slot-scope="s"><el-date-picker v-model="s.row.need_date" type="date" value-format="yyyy-MM-dd" size="small" style="width:100%" /></template>
        </el-table-column>
        <el-table-column label="操作" width="70" align="center" fixed="right">
          <template slot-scope="s">
            <el-button v-if="Number(s.row.received_quantity || 0) <= 0" type="text" size="mini" class="danger" @click="removeItem(s.$index)">删除</el-button>
            <span v-else class="gray">已入库</span>
          </template>
        </el-table-column>
      </el-table>
      <el-empty v-if="!items.length" description="请先选择来源采购申请，或点击「添加产品」" :image-size="70" />
    </el-card>
  </div>
</template>

<script>
import { saveOrder, getOrderDetail, getRequestDetail, getOrderPool, checkOrderCode } from '../../../../api/purchase'
import { getSupplierList } from '../../../../api/businessSupplier'
import ProductSelector from '../../product/bom/components/ProductSelector.vue'

export default {
  name: 'BusinessPurchaseOrderAdd',
  components: { ProductSelector },
  data() {
    return {
      id: Number(this.$route.params.id) || 0,
      isEdit: false,
      submitting: false,
      supplierOptions: [],
      poolOptions: [],
      codeError: '',
      codeChecked: false,
      form: {
        order_no: '', title: '', supplier_id: null, request_id: null, request_no: '',
        order_date: '', expected_date: '', transport_type: '', receive_address: '', receiver: '', receiver_phone: '',
        payment_terms: '', purpose: '', remark: ''
      },
      items: [],
      rules: {
        request_id: [{ required: true, message: '请选择来源采购申请', trigger: 'change' }],
        order_no: [{ required: true, message: '请输入订单编号', trigger: 'blur' }],
        title: [{ required: true, message: '请输入订单标题', trigger: 'blur' }],
        supplier_id: [{ required: true, message: '请选择供应商', trigger: 'change' }],
        order_date: [{ required: true, message: '请选择订单日期', trigger: 'change' }],
        expected_date: [{ required: true, message: '请选择期望交货日期', trigger: 'change' }]
      }
    }
  },
  computed: {
    totalAmount() {
      return this.items.reduce((s, it) => s + (Number(it.quantity) || 0) * (Number(it.unit_price) || 0), 0).toFixed(2)
    }
  },
  async created() {
    this.isEdit = this.id > 0
    this.form.order_date = this.today()
    await this.loadSuppliers()
    if (this.isEdit) {
      await this.loadDetail()
    } else {
      this.form.order_no = this.genCode()
      await this.loadPool()
      const q = this.$route.query
      if (q.request_id) {
        this.form.request_id = Number(q.request_id)
        await this.loadRequest(Number(q.request_id))
      }
    }
  },
  methods: {
    today() { const d = new Date(); return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}` },
    genCode() {
      const d = new Date()
      const pad = x => String(x).padStart(2, '0')
      return 'PO' + d.getFullYear() + pad(d.getMonth() + 1) + pad(d.getDate()) + '0001'
    },
    qtyMax(row) { return row.apply_quantity > 0 ? row.apply_quantity : undefined },
    onQtyChange(idx, v) {
      const it = this.items[idx]
      if (it.apply_quantity > 0 && Number(v) > Number(it.apply_quantity)) {
        it.quantity = Number(it.apply_quantity)
        this.$message.warning('下单数量不能超过申请数量（' + it.apply_quantity + '）')
      }
    },
    async loadSuppliers() {
      try {
        const r = await getSupplierList({ status: 1, page: 1, pageSize: 100 })
        this.supplierOptions = (r.code === 0 && r.data) ? (r.data.list || []) : []
      } catch (e) { this.supplierOptions = [] }
    },
    async loadPool() {
      try {
        const r = await getOrderPool()
        this.poolOptions = (r.code === 0 && r.data) ? r.data : []
      } catch (e) { this.poolOptions = [] }
    },
    async loadDetail() {
      try {
        const r = await getOrderDetail(this.id)
        if (r.code === 0 && r.data) {
          const d = r.data.order || {}
          this.form = {
            order_no: d.order_no, title: d.title, supplier_id: d.supplier_id, request_id: d.request_id, request_no: d.request_no,
            order_date: d.order_date || '', expected_date: d.expected_date || '', transport_type: d.transport_type || '',
            receive_address: d.receive_address || '', receiver: d.receiver || '', receiver_phone: d.receiver_phone || '',
            payment_terms: d.payment_terms || '', purpose: d.purpose || '', remark: d.remark || ''
          }
          this.items = (r.data.items || []).map(it => ({
            request_item_id: it.request_item_id, apply_quantity: it.apply_quantity || 0, product_id: it.product_id,
            product_code: it.product_code, product_name: it.product_name, product_spec: it.product_spec || '',
            product_unit: it.product_unit || '', quantity: Number(it.quantity) || 0, unit_price: Number(it.unit_price) || 0,
            need_date: it.need_date || '', received_quantity: it.received_quantity || 0
          }))
        } else {
          this.$message.error(r.msg || '采购订单不存在')
          this.$router.push('/business/purchase/order/list')
        }
      } catch (e) {}
    },
    async onRequestChange(requestId) {
      this.form.request_no = ''
      if (requestId) {
        await this.loadRequest(requestId)
      } else {
        this.items = []
      }
    },
    /** 从来源申请加载/重载明细 */
    async loadRequest(requestId) {
      try {
        const r = await getRequestDetail(requestId)
        if (r.code === 0 && r.data) {
          const req = r.data.request || {}
          this.form.request_no = req.request_code || ''
          if (!this.form.title) this.form.title = req.title || ''
          if (!this.form.expected_date) this.form.expected_date = req.expected_date || ''
          if (!this.form.purpose) this.form.purpose = req.purpose || ''
          if (!this.form.remark) this.form.remark = req.remark || ''
          this.items = (r.data.items || []).filter(x => x.product_id > 0).map(x => ({
            request_item_id: x.id, apply_quantity: Number(x.quantity) || 0, product_id: x.product_id, product_code: x.product_code,
            product_name: x.product_name, product_spec: x.product_spec || '', product_unit: x.product_unit || '',
            quantity: Math.max(0, Number(x.quantity) - Number(x.ordered_quantity)) || 0,
            unit_price: Number(x.unit_price) || 0, need_date: x.need_date || '', received_quantity: 0
          }))
        }
      } catch (e) {}
    },
    async reloadFromRequest() {
      if (!this.form.request_id) return
      if (this.items.length) {
        try { await this.$confirm('重新加载将覆盖当前明细数据，是否继续？', '提示', { type: 'warning' }) } catch (e) { return }
      }
      await this.loadRequest(this.form.request_id)
    },
    addItem() {
      this.items.push({ request_item_id: 0, apply_quantity: 0, product_id: 0, product_code: '', product_name: '', product_spec: '', product_unit: '', quantity: 1, unit_price: 0, need_date: '', received_quantity: 0 })
    },
    onProductPicked(idx, p) {
      if (!p || !p.id) return
      const row = this.items[idx]
      if (!row) return
      row.product_code = p.product_code
      row.product_name = p.product_name
      row.product_spec = p.specification || ''
      row.product_unit = p.unit || ''
      if (!row.unit_price || row.unit_price <= 0) row.unit_price = Number(p.unit_price) || 0
    },
    removeItem(idx) { this.items.splice(idx, 1) },
    async checkCode() {
      const code = (this.form.order_no || '').trim()
      if (!code) { this.codeError = ''; return }
      try {
        const r = await checkOrderCode(code, this.id)
        const exists = r.code === 0 && r.data && r.data.exists
        this.codeChecked = true
        this.codeError = exists ? '该订单编号已存在，请重新输入' : ''
      } catch (e) { this.codeError = '' }
    },
    handleCancel() {
      if (this.form.title || this.form.supplier_id || this.items.length) {
        this.$confirm('确认离开吗？未保存的内容将丢失', '提示', { type: 'warning' }).then(() => this.$router.push('/business/purchase/order/list')).catch(() => {})
      } else {
        this.$router.push('/business/purchase/order/list')
      }
    },
    async handleSave(continueEdit) {
      if (this.codeError) { this.$message.warning('订单编号已存在，请修改后再保存'); return }
      const valid = await this.$refs.form.validate().catch(() => false)
      if (!valid) {
        this.$message.warning('请完善必填项：来源采购申请、订单编号、标题、供应商、订单日期、期望交货日期')
        return
      }
      if (!this.items.length) { this.$message.warning('请至少添加一条明细'); return }
      const bad = this.items.findIndex(it => !it.product_id)
      if (bad > -1) { this.$message.warning(`第 ${bad + 1} 行明细：请选择产品`); return }
      if (this.items.some(it => !(Number(it.quantity) > 0))) { this.$message.warning('下单数量必须大于 0'); return }
      if (this.items.some(it => !(Number(it.unit_price) > 0))) { this.$message.warning('采购单价必须大于 0'); return }
      this.submitting = true
      try {
        const payload = {
          id: this.id || null,
          order_no: this.form.order_no,
          title: this.form.title, supplier_id: this.form.supplier_id, request_id: this.form.request_id, request_no: this.form.request_no,
          order_date: this.form.order_date, expected_date: this.form.expected_date || '',
          transport_type: this.form.transport_type, receive_address: this.form.receive_address,
          receiver: this.form.receiver, receiver_phone: this.form.receiver_phone,
          payment_terms: this.form.payment_terms, purpose: this.form.purpose, remark: this.form.remark,
          items: this.items.map(it => ({ request_item_id: it.request_item_id, product_id: it.product_id, quantity: it.quantity, unit_price: it.unit_price, need_date: it.need_date || '' }))
        }
        const r = await saveOrder(payload)
        if (r.code === 0) {
          this.$message.success('保存成功')
          if (continueEdit) {
            if (!this.id) { this.id = r.data.id || 0; this.isEdit = true }
          } else {
            this.$router.push('/business/purchase/order/list')
          }
        }
      } catch (e) {}
      this.submitting = false
    }
  }
}
</script>

<style scoped>
.po-form-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 700; color: #303133; }
.header-actions .el-button + .el-button { margin-left: 10px; }
.items-card { margin-top: 14px; }
.section-title { display: flex; align-items: center; font-size: 15px; font-weight: 600; margin-bottom: 12px; }
.section-title::before { content: ''; width: 4px; height: 14px; border-radius: 2px; background: #409eff; margin-right: 8px; }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.total-tip { font-size: 14px; font-weight: 600; color: #303133; }
.code-error { color: #f56c6c; font-size: 12px; line-height: 1.4; margin-top: 4px; }
.danger { color: #f56c6c; }
.gray { color: #c0c4cc; }
</style>
