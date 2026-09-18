<!--
  文件：admin/src/views/business/order/components/OrderAddDialog.vue
  功能：新增订单弹窗（两步）
    第一步：选择订单类别（销售订单/维修订单卡片）
    第二步：按类别动态填写（销售=产品明细，维修=设备维修明细）
    - 明细行支持增删改，金额自动计算
    - 底部显示订单金额合计
    - 提交校验：客户/业务类型/订单日期必填，明细至少一行且必填字段已填
-->
<template>
  <el-dialog
    title="新增订单"
    :visible="dialogVisible"
    width="1100px"
    :close-on-click-modal="false"
    @close="close"
  >
    <!-- 第一步：选择订单类别 -->
    <div v-if="step === 1" class="step-category">
      <div
        class="category-card"
        :class="{ active: selectedCategory === 'sales' }"
        @click="selectCategory('sales')"
      >
        <i class="el-icon-shopping-cart-2"></i>
        <div class="cc-name">生产订单</div>
        <div class="cc-desc">客户购买产品或配件，走制造发货流程</div>
      </div>
      <div
        class="category-card"
        :class="{ active: selectedCategory === 'repair' }"
        @click="selectCategory('repair')"
      >
        <i class="el-icon-wrench"></i>
        <div class="cc-name">维修订单</div>
        <div class="cc-desc">客户设备维修，走拆解维修流程</div>
      </div>
      <div class="step-actions">
        <el-button size="small" plain @click="close">取消</el-button>
        <el-button size="small" type="primary" :disabled="!selectedCategory" @click="nextStep">下一步</el-button>
      </div>
    </div>

    <!-- 第二步：填写订单信息 -->
    <el-form v-else ref="orderForm" :model="orderForm" label-width="100px" size="small">
      <el-divider content-position="left">基本信息</el-divider>
      <el-row :gutter="12">
        <el-col :span="8">
          <el-form-item label="客户名称" required>
            <el-select v-model="orderForm.customer_id" filterable style="width:100%" placeholder="选择客户">
              <el-option v-for="c in customerOptions" :key="c.id" :label="c.customer_name" :value="c.id" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="业务类型" required>
            <el-select v-model="orderForm.business_type" style="width:100%" placeholder="选择业务类型">
              <el-option v-for="opt in filteredBizType" :key="opt.value" :label="opt.label" :value="opt.value" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="订单日期" required>
            <el-date-picker v-model="orderForm.order_date" type="date" value-format="yyyy-MM-dd" style="width:100%" placeholder="选择日期" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="交付日期">
            <el-date-picker v-model="orderForm.delivery_date" type="date" value-format="yyyy-MM-dd" style="width:100%" placeholder="选填" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="业务员">
            <el-input value="当前操作账号（自动）" disabled />
          </el-form-item>
        </el-col>
      </el-row>

      <!-- 销售订单明细 -->
      <template v-if="isSales">
        <el-divider content-position="left">产品明细</el-divider>
        <el-table :data="salesItems" size="small" border>
          <el-table-column type="index" label="序号" width="55" align="center" />
          <el-table-column label="产品（从产品列表选择）" min-width="200">
            <template slot-scope="s">
              <ProductSelector v-model="s.row.product_id" :label-text="s.row.product_code + ' ' + s.row.product_name" @selected="p => onSalesProduct(s.$index, p)" />
            </template>
          </el-table-column>
          <el-table-column prop="product_code" label="编码" width="110" show-overflow-tooltip />
          <el-table-column prop="product_spec" label="规格" width="90" show-overflow-tooltip />
          <el-table-column prop="product_unit" label="单位" width="60" align="center" />
          <el-table-column label="数量" width="110">
            <template slot-scope="s"><el-input-number v-model="s.row.quantity" :min="1" controls-position="right" size="small" style="width:100%" @change="calcSalesAmount(s.$index)" /></template>
          </el-table-column>
          <el-table-column label="单价" width="120">
            <template slot-scope="s"><el-input-number v-model="s.row.unit_price" :min="0" :precision="2" controls-position="right" size="small" style="width:100%" @change="calcSalesAmount(s.$index)" /></template>
          </el-table-column>
          <el-table-column label="金额" width="110" align="right">
            <template slot-scope="s">¥{{ (Number(s.row.amount) || 0).toFixed(2) }}</template>
          </el-table-column>
          <el-table-column label="操作" width="60" align="center">
            <template slot-scope="s"><el-button type="text" icon="el-icon-delete" class="danger" @click="removeSalesItem(s.$index)"></el-button></template>
          </el-table-column>
        </el-table>
        <el-button size="mini" type="text" icon="el-icon-plus" @click="addSalesItem">添加产品</el-button>
      </template>

      <!-- 维修订单明细（产品维修：与生产订单一致，产品从产品列表选择） -->
      <template v-else>
        <el-divider content-position="left">产品维修明细</el-divider>
        <el-table :data="repairItems" size="small" border>
          <el-table-column type="index" label="序号" width="55" align="center" />
          <el-table-column label="产品（从产品列表选择）" min-width="200">
            <template slot-scope="s">
              <ProductSelector v-model="s.row.product_id" :label-text="s.row.product_code + ' ' + s.row.product_name" @selected="p => onRepairProduct(s.$index, p)" />
            </template>
          </el-table-column>
          <el-table-column prop="product_code" label="编码" width="110" show-overflow-tooltip />
          <el-table-column prop="product_spec" label="规格" width="90" show-overflow-tooltip />
          <el-table-column prop="product_unit" label="单位" width="60" align="center" />
          <el-table-column label="数量" width="110">
            <template slot-scope="s"><el-input-number v-model="s.row.quantity" :min="1" controls-position="right" size="small" style="width:100%" @change="calcRepairAmount(s.$index)" /></template>
          </el-table-column>
          <el-table-column label="单价" width="120">
            <template slot-scope="s"><el-input-number v-model="s.row.unit_price" :min="0" :precision="2" controls-position="right" size="small" style="width:100%" @change="calcRepairAmount(s.$index)" /></template>
          </el-table-column>
          <el-table-column label="金额" width="110" align="right">
            <template slot-scope="s">¥{{ (Number(s.row.amount) || 0).toFixed(2) }}</template>
          </el-table-column>
          <el-table-column label="操作" width="60" align="center">
            <template slot-scope="s"><el-button type="text" icon="el-icon-delete" class="danger" @click="removeRepairItem(s.$index)"></el-button></template>
          </el-table-column>
        </el-table>
        <el-button size="mini" type="text" icon="el-icon-plus" @click="addRepairItem">添加产品</el-button>
      </template>

      <el-form-item label="备注">
        <el-input v-model="orderForm.remark" type="textarea" :rows="2" maxlength="500" placeholder="选填" />
      </el-form-item>

      <div class="amount-sum">
        {{ stepTitle }}金额合计：<b>¥{{ totalAmount.toFixed(2) }}</b>
      </div>

      <div class="dialog-footer">
        <el-button size="small" type="text" @click="prevStep">上一步</el-button>
        <el-button size="small" plain @click="close">取消</el-button>
        <el-button size="small" type="primary" :loading="submitting" @click="handleSubmit">确认提交</el-button>
      </div>
    </el-form>
  </el-dialog>
</template>

<script>
import { addOrder } from '../../../../api/businessOrder'
import { getCustomerOptions } from '../../../../api/businessCustomer'
import ProductSelector from '../../product/bom/components/ProductSelector.vue'

export default {
  name: 'OrderAddDialog',
  components: { ProductSelector },
  data() {
    return {
      dialogVisible: false,
      step: 1,
      selectedCategory: '',
      submitting: false,
      orderForm: {
        customer_id: null,
        business_type: '',
        order_date: '',
        delivery_date: '',
        remark: ''
      },
      salesItems: [],
      repairItems: [],
      customerOptions: [],
      userOptions: [],
      businessTypeOptions: [
        { label: '产品销售', value: 'product_sales' },
        { label: '配件销售', value: 'parts_sales' },
        { label: '维修服务', value: 'repair' },
        { label: '其他', value: 'other' }
      ]
    }
  },
  computed: {
    // 是否销售订单
    isSales() { return this.selectedCategory === 'sales' },
    // 是否维修订单
    isRepair() { return this.selectedCategory === 'repair' },
    // 业务类型按类别过滤：销售=产品/配件/其他；维修=维修服务
    filteredBizType() {
      if (this.isRepair) return this.businessTypeOptions.filter(o => o.value === 'repair')
      return this.businessTypeOptions.filter(o => o.value !== 'repair')
    },
    // 销售订单金额合计
    salesTotalAmount() {
      return this.salesItems.reduce((s, it) => s + (Number(it.amount) || 0), 0)
    },
    // 维修订单金额合计
    repairTotalAmount() {
      return this.repairItems.reduce((s, it) => s + (Number(it.amount) || 0), 0)
    },
    // 当前合计
    totalAmount() { return this.isRepair ? this.repairTotalAmount : this.salesTotalAmount },
    // 步骤标题
    stepTitle() {
      if (this.step === 1) return '选择订单类别'
      return this.isSales ? '销售订单' : '维修订单'
    }
  },
  methods: {
    /** 打开弹窗：重置数据并加载下拉选项 */
    async open() {
      this.dialogVisible = true
      this.resetForm()
      await this.loadCustomerOptions()
    },
    /** 关闭弹窗：重置所有数据 */
    close() {
      this.dialogVisible = false
      this.resetForm()
    },
    /** 重置表单为全新状态 */
    resetForm() {
      this.step = 1
      this.selectedCategory = ''
      this.submitting = false
      this.orderForm = { customer_id: null, business_type: '', order_date: this.today(), delivery_date: '', remark: '' }
      this.salesItems = []
      this.repairItems = []
    },
    /** 选择订单类别 */
    selectCategory(category) {
      // 已选中则保持选中（不允许取消，只能切换）
      this.selectedCategory = category
    },
    /** 进入第二步（需已选类别） */
    nextStep() {
      if (!this.selectedCategory) { this.$message.warning('请先选择订单类别'); return }
      // 进入第二步时初始化一行空明细
      if (this.isSales && !this.salesItems.length) this.addSalesItem()
      if (this.isRepair && !this.repairItems.length) this.addRepairItem()
      this.step = 2
    },
    /** 返回第一步 */
    prevStep() { this.step = 1 },
    /** 添加销售订单明细行 */
    addSalesItem() {
      this.salesItems.push({ product_id: 0, product_code: '', product_name: '', product_spec: '', product_unit: '', quantity: 1, unit_price: 0, amount: 0, remark: '' })
    },
    /** 删除销售订单明细行 */
    removeSalesItem(index) {
      this.salesItems.splice(index, 1)
    },
    /** 计算销售订单行金额（金额=数量×单价） */
    calcSalesAmount(index) {
      const it = this.salesItems[index]
      if (!it) return
      it.amount = Number(Number(it.quantity) || 0) * Number(Number(it.unit_price) || 0)
    },
    /** 销售明细：选中产品带出编码/名称/规格/单位 */
    onSalesProduct(index, p) {
      if (!p || !p.id) return
      const it = this.salesItems[index]
      it.product_code = p.product_code
      it.product_name = p.product_name
      it.product_spec = p.specification || ''
      it.product_unit = p.unit || ''
    },
    /** 维修明细：选中产品带出信息并算金额 */
    onRepairProduct(index, p) {
      if (!p || !p.id) return
      const it = this.repairItems[index]
      it.product_code = p.product_code
      it.product_name = p.product_name
      it.product_spec = p.specification || ''
      it.product_unit = p.unit || ''
      it.quantity = it.quantity || 1
      this.calcRepairAmount(index)
    },
    /** 添加维修订单明细行 */
    addRepairItem() {
      this.repairItems.push({ product_id: 0, product_code: '', product_name: '', product_spec: '', product_unit: '', quantity: 1, unit_price: 0, amount: 0, remark: '' })
    },
    /** 删除维修订单明细行 */
    removeRepairItem(index) {
      this.repairItems.splice(index, 1)
    },
    /** 计算维修订单行金额（金额=数量×单价） */
    calcRepairAmount(index) {
      const it = this.repairItems[index]
      if (!it) return
      it.amount = Number(Number(it.quantity) || 0) * Number(Number(it.unit_price) || 0)
    },
    /** 加载客户下拉（仅启用客户） */
    async loadCustomerOptions() {
      try {
        const r = await getCustomerOptions()
        this.customerOptions = r.data || []
      } catch (e) { this.customerOptions = [] }
    },
    /** 表单校验并提交 */
    async handleSubmit() {
      // 基本信息校验
      if (!this.orderForm.customer_id) { this.$message.warning('请选择客户'); return }
      if (!this.orderForm.business_type) { this.$message.warning('请选择业务类型'); return }
      if (!this.orderForm.order_date) { this.$message.warning('请选择订单日期'); return }
      // 明细校验
      const items = this.isSales ? this.salesItems : this.repairItems
      if (!items.length) { this.$message.warning('请至少添加一条明细'); return }
      const invalidIndex = items.findIndex(it => !it.product_id)
      if (invalidIndex > -1) {
        this.$message.warning(`第 ${invalidIndex + 1} 行明细：请选择产品`)
        return
      }
      // 提交
      this.submitting = true
      try {
        const payload = {
          order_category: this.selectedCategory,
          customer_id: this.orderForm.customer_id,
          business_type: this.orderForm.business_type,
          order_date: this.orderForm.order_date,
          delivery_date: this.orderForm.delivery_date || '',
          remark: this.orderForm.remark || '',
          items: items.map(it => ({ product_id: it.product_id, quantity: it.quantity, unit_price: it.unit_price, remark: it.remark || '' }))
        }
        const r = await addOrder(payload)
        if (r.code === 0) {
          this.$message.success(r.msg || '订单创建成功')
          this.dialogVisible = false
          this.resetForm()
          this.$emit('success')
        }
      } catch (e) {
        // 提交失败：弹窗保持打开，错误信息已由拦截器提示
      }
      this.submitting = false
    },
    today() {
      const d = new Date()
      return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
    }
  }
}
</script>

<style scoped>
/* ===== 类别选择卡片 ===== */
.step-category { display: flex; gap: 16px; padding: 16px 0; }
.category-card {
  flex: 1; width: 50%; height: 150px; padding: 20px; box-sizing: border-box;
  text-align: center; cursor: pointer; border: 1px solid #dcdfe6; border-radius: 8px;
  background: #fff; transition: all .25s;
}
.category-card:hover { box-shadow: 0 6px 16px rgba(0,0,0,.12); }
.category-card.active { background: #f0f7ff; border: 2px solid #409eff; box-shadow: 0 6px 16px rgba(64,158,255,.2); }
.category-card i { font-size: 48px; color: #909399; }
.category-card.active i { color: #409eff; }
.cc-name { font-size: 18px; font-weight: 600; margin: 12px 0 6px; color: #303133; }
.cc-desc { font-size: 14px; color: #909399; }
.step-actions { margin-top: 24px; text-align: right; }

/* ===== 金额合计 ===== */
.amount-sum { text-align: right; margin: 12px 0; color: #606266; }
.amount-sum b { color: #409eff; font-size: 16px; }
.dialog-footer { text-align: right; }
.danger { color: #f56c6c; }

/* 明细表头底色（Element 默认，加深） */
::v-deep .el-table th { background: #f5f7fa; }
</style>
