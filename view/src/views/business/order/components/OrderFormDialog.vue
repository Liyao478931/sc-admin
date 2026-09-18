<!--
  文件：admin/src/views/business/order/components/OrderFormDialog.vue
  功能：新增/编辑订单弹窗（800px，两步）
    第一步：选择订单类别（销售/维修）
    第二步：根据类别动态填写（销售=产品明细，维修=设备维修明细）
    - 明细金额自动计算，订单金额自动汇总
    - 客户/业务员/业务类型下拉（字典/接口）
-->
<template>
  <el-dialog
    :title="isEdit ? '编辑订单' : '新增订单'"
    :visible="visible"
    width="1000px"
    :close-on-click-modal="false"
    @close="onClose"
  >
    <!-- 第一步：选择订单类别 -->
    <div v-if="step === 1" class="step-category">
      <div class="category-card" :class="{ active: form.order_category === 'sales' }" @click="form.order_category = 'sales'">
        <i class="el-icon-shopping-cart-2"></i>
        <div class="cc-name">生产订单</div>
        <div class="cc-desc">客户购买产品或配件，走制造发货流程</div>
      </div>
      <div class="category-card" :class="{ active: form.order_category === 'repair' }" @click="form.order_category = 'repair'">
        <i class="el-icon-wrench"></i>
        <div class="cc-name">维修订单</div>
        <div class="cc-desc">客户设备维修，走拆解维修流程</div>
      </div>
      <div class="step-actions">
        <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
        <el-button size="small" type="primary" :disabled="!form.order_category" @click="step = 2">下一步</el-button>
      </div>
    </div>

    <!-- 第二步：填写订单信息 -->
    <el-form v-else ref="form" :model="form" :rules="rules" label-width="100px" size="small" v-loading="loading">
      <el-divider content-position="left">基本信息</el-divider>
      <el-row :gutter="12">
        <el-col :span="12">
          <el-form-item label="订单类别">
            <el-tag size="small" :type="form.order_category === 'sales' ? 'primary' : 'warning'">{{ form.order_category === 'sales' ? '生产订单' : '维修订单' }}</el-tag>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="客户" prop="customer_id">
            <el-select v-model="form.customer_id" filterable style="width:100%" placeholder="选择客户">
              <el-option v-for="c in customerOptions" :key="c.id" :label="c.customer_name" :value="c.id" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="业务类型" prop="business_type">
            <el-select v-model="form.business_type" style="width:100%">
              <el-option v-for="opt in bizTypeFiltered" :key="opt.value" :label="opt.label" :value="opt.value" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="订单日期" prop="order_date">
            <el-date-picker v-model="form.order_date" type="date" value-format="yyyy-MM-dd" style="width:100%" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="交付日期">
            <el-date-picker v-model="form.delivery_date" type="date" value-format="yyyy-MM-dd" style="width:100%" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="业务员">
            <el-input value="当前操作账号（自动）" disabled />
          </el-form-item>
        </el-col>
      </el-row>

      <!-- 销售订单：产品明细（从产品列表选择） -->
      <template v-if="form.order_category === 'sales'">
        <el-divider content-position="left">产品明细</el-divider>
        <div v-for="(it, idx) in form.items" :key="idx" class="item-row">
          <ProductSelector v-model="it.product_id" :label-text="it.product_code + ' ' + it.product_name" @selected="p => onSalesProduct(idx, p)" style="width:220px" />
          <el-input :value="it.product_code" readonly placeholder="编码" style="width:110px" />
          <el-input :value="it.product_spec" readonly placeholder="规格" style="width:90px" />
          <el-input :value="it.product_unit" readonly placeholder="单位" style="width:60px" />
          <el-input-number v-model="it.quantity" :min="1" style="width:100px" @change="recalcSales(idx)" />
          <el-input-number v-model="it.unit_price" :min="0" :precision="2" style="width:120px" @change="recalcSales(idx)" />
          <el-input :value="(Number(it.quantity) || 0) * (Number(it.unit_price) || 0)" readonly style="width:100px" />
          <el-button type="text" icon="el-icon-delete" class="danger" @click="form.items.splice(idx, 1)"></el-button>
        </div>
        <el-button size="mini" icon="el-icon-plus" @click="form.items.push({ product_id: 0, product_code: '', product_name: '', product_spec: '', product_unit: '', quantity: 1, unit_price: 0 })">添加产品</el-button>
      </template>

      <!-- 维修订单：产品维修明细（与生产订单一致，产品从产品列表选择） -->
      <template v-else>
        <el-divider content-position="left">产品维修明细</el-divider>
        <el-table :data="form.items" size="small" border>
          <el-table-column type="index" label="序号" width="55" align="center" />
          <el-table-column label="产品（从产品列表选择）" min-width="190">
            <template slot-scope="s">
              <ProductSelector v-model="s.row.product_id" :label-text="s.row.product_code + ' ' + s.row.product_name" @selected="p => onRepairProduct(s.$index, p)" />
            </template>
          </el-table-column>
          <el-table-column prop="product_code" label="编码" width="105" show-overflow-tooltip />
          <el-table-column prop="product_spec" label="规格" width="90" show-overflow-tooltip />
          <el-table-column prop="product_unit" label="单位" width="60" align="center" />
          <el-table-column label="数量" width="120">
            <template slot-scope="s"><el-input-number v-model="s.row.quantity" :min="1" controls-position="right" size="small" style="width:100%" @change="recalcRepair(s.$index)" /></template>
          </el-table-column>
          <el-table-column label="单价" width="130">
            <template slot-scope="s"><el-input-number v-model="s.row.unit_price" :min="0" :precision="2" controls-position="right" size="small" style="width:100%" @change="recalcRepair(s.$index)" /></template>
          </el-table-column>
          <el-table-column label="金额" width="110" align="right">
            <template slot-scope="s">¥{{ (Number(s.row.quantity || 0) * Number(s.row.unit_price || 0)).toFixed(2) }}</template>
          </el-table-column>
          <el-table-column label="操作" width="60" align="center">
            <template slot-scope="s"><el-button type="text" icon="el-icon-delete" class="danger" @click="form.items.splice(s.$index, 1)"></el-button></template>
          </el-table-column>
        </el-table>
        <el-button size="mini" icon="el-icon-plus" @click="form.items.push({ product_id: 0, product_code: '', product_name: '', product_spec: '', product_unit: '', quantity: 1, unit_price: 0 })">添加产品</el-button>
      </template>

      <el-form-item label="备注">
        <el-input v-model="form.remark" type="textarea" :rows="2" maxlength="500" />
      </el-form-item>

      <div class="amount-sum">订单金额合计：<b style="color:#f56c6c;font-size:16px">¥{{ totalAmount.toLocaleString() }}</b></div>
    </el-form>

    <!-- 弹窗底部操作（el-dialog 直接子节点，slot=footer 才生效） -->
    <div slot="footer" class="dialog-footer">
      <el-button v-if="step === 2" size="small" @click="step = 1">上一步</el-button>
      <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
      <el-button size="small" type="primary" :loading="saving" @click="handleSubmit">保存</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { addOrder, editOrder, getOrderDetail, getOrderSuggestNo } from '../../../../api/businessOrder'
import { getCustomerOptions } from '../../../../api/businessCustomer'
import { getDictByCode } from '../../../../api/dictionary'
import ProductSelector from '../../product/bom/components/ProductSelector.vue'

export default {
  name: 'OrderFormDialog',
  components: { ProductSelector },
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null }
  },
  data() {
    return {
      step: 1, loading: false, saving: false,
      customerOptions: [], userOptions: [], bizTypeOptions: [],
      form: {
        order_category: '', customer_id: null, business_type: '', order_date: '', delivery_date: '',
        remark: '', items: []
      },
      rules: {
        customer_id: [{ required: true, message: '请选择客户', trigger: 'change' }],
        business_type: [{ required: true, message: '请选择业务类型', trigger: 'change' }],
        order_date: [{ required: true, message: '请选择订单日期', trigger: 'change' }]
      }
    }
  },
  computed: {
    isEdit() { return !!(this.row && this.row.id) },
    // 业务类型按订单类别过滤：维修=维修服务；销售=配件/产品/其他
    bizTypeFiltered() {
      if (this.form.order_category === 'repair') {
        return (this.bizTypeOptions || []).filter(o => o.value === 'repair')
      }
      return (this.bizTypeOptions || []).filter(o => o.value !== 'repair')
    },
    totalAmount() {
      if (this.form.order_category === 'repair') {
        return this.form.items.reduce((s, it) => s + this.repairItemAmount(it), 0)
      }
      return this.form.items.reduce((s, it) => s + (Number(it.quantity) || 0) * (Number(it.unit_price) || 0), 0)
    }
  },
  watch: {
    visible(val) { if (val) this.open() }
  },
  methods: {
    repairItemAmount(it) {
      return (Number(it.quantity) || 0) * (Number(it.unit_price) || 0)
    },
    onSalesProduct(idx, p) {
      if (!p || !p.id) return
      const it = this.form.items[idx]
      it.product_code = p.product_code
      it.product_name = p.product_name
      it.product_spec = p.specification || ''
      it.product_unit = p.unit || ''
    },
    onRepairProduct(idx, p) {
      if (!p || !p.id) return
      const it = this.form.items[idx]
      it.product_code = p.product_code
      it.product_name = p.product_name
      it.product_spec = p.specification || ''
      it.product_unit = p.unit || ''
      it.quantity = it.quantity || 1
    },
    recalcSales(idx) { /* 金额由 computed totalAmount 自动汇总 */ },
    recalcRepair(idx) { /* 小计由 repairItemAmount 自动计算 */ },
    async open() {
      this.step = 1
      this.loading = true
      this.form = { order_category: '', customer_id: null, business_type: '', order_date: this.today(), delivery_date: '', remark: '', items: [] }
      // 加载字典/客户
      try { const r = await getDictByCode('order_business_type'); this.bizTypeOptions = r.data || [] } catch (e) { this.bizTypeOptions = [] }
      try { const r = await getCustomerOptions(); this.customerOptions = r.data || [] } catch (e) { this.customerOptions = [] }
      if (this.isEdit) {
        try {
          const r = await getOrderDetail(this.row.id)
          if (r.code === 0) {
            const d = r.data
            this.form = {
              order_category: d.order_category, customer_id: d.customer_id, business_type: d.business_type,
              order_date: d.order_date, delivery_date: d.delivery_date || '',
              remark: d.remark || '', items: (d.items || []).map(it => ({ ...it }))
            }
            this.step = 2
          }
        } catch (e) {}
      } else {
        // 新增：预填订单日期 + 一行明细
        this.form.order_date = this.today()
        this.form.business_type = this.form.order_category === 'repair' ? 'repair' : ''
        if (this.form.order_category === 'sales') this.form.items.push({ product_id: 0, product_code: '', product_name: '', product_spec: '', product_unit: '', quantity: 1, unit_price: 0 })
        else this.form.items.push({ product_id: 0, product_code: '', product_name: '', product_spec: '', product_unit: '', quantity: 1, unit_price: 0 })
      }
      this.loading = false
    },
    today() { const d = new Date(); return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}` },
    onClose() { this.step = 1; this.$emit('update:visible', false) },
    async handleSubmit() {
      // 表单校验（ref 存在才校验，避免弹窗未渲染时静默失败）
      const formRef = this.$refs.orderForm
      if (formRef) {
        const valid = await formRef.validate().catch(() => false)
        if (!valid) { this.$message.warning('请完善必填项'); return }
      }
      // 校验明细
      if (!this.form.items.length) { this.$message.warning('请至少添加一条明细'); return }
      if (this.form.items.some(it => !it.product_id)) { this.$message.warning('请选择产品'); return }
      this.saving = true
      try {
        const payload = { ...this.form, order_amount: this.totalAmount }
        if (this.isEdit) {
          const r = await editOrder(this.row.id, payload)
          if (r.code === 0) { this.$message.success('订单已更新'); this.$emit('success') }
          else this.$message.error(r.msg || '保存失败')
        } else {
          const r = await addOrder(payload)
          if (r.code === 0) { this.$message.success('订单创建成功'); this.$emit('success') }
          else this.$message.error(r.msg || '保存失败')
        }
      } catch (e) {
        console.error('订单保存异常', e)
        this.$message.error('保存异常：' + (e.message || '未知错误'))
      }
      this.saving = false
    }
  }
}
</script>

<style scoped>
.step-category { display: flex; gap: 16px; padding: 20px 0; }
.category-card {
  flex: 1; border: 1px solid #dcdfe6; border-radius: 8px; padding: 28px 20px; text-align: center; cursor: pointer; transition: all .2s;
}
.category-card i { font-size: 36px; color: #909399; }
.category-card.active { border-color: #409eff; background: #ecf5ff; }
.category-card.active i { color: #409eff; }
.cc-name { font-size: 16px; font-weight: 600; margin: 10px 0 6px; color: #303133; }
.cc-desc { font-size: 12px; color: #909399; }
.step-actions { margin-top: 24px; text-align: right; }
.item-row, .repair-line { display: flex; gap: 8px; align-items: center; margin-bottom: 8px; }
.repair-row { border: 1px dashed #ebeef5; border-radius: 6px; padding: 10px; margin-bottom: 8px; }
.amount-sum { text-align: right; margin: 12px 0; color: #303133; }
.dialog-footer { text-align: right; }
.danger { color: #f56c6c; }
</style>
