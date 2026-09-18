<!--
  文件：admin/src/views/business/quotation/components/QuotationFormDialog.vue
  功能：新增/编辑报价单弹窗（两步）
    第一步：选择报价类别（维修报价/销售报价卡片）
    第二步：填写基本信息 + 报价明细（项目名称必填，金额自动计算）
    - 有效期截止日期自动计算（报价日期 + 有效期天数）
-->
<template>
  <el-dialog
    :title="isEdit ? '编辑报价单' : '新增报价单'"
    :visible="visible"
    width="800px"
    :close-on-click-modal="false"
    @close="onClose"
  >
    <!-- 第一步：选择报价类别 -->
    <div v-if="step === 1" class="step-category">
      <div class="category-card" :class="{ active: form.quotation_category === 'repair' }" @click="form.quotation_category = 'repair'">
        <i class="el-icon-wrench"></i>
        <div class="cc-name">维修报价</div>
        <div class="cc-desc">针对设备维修需求，估算工时费、配件费、服务费</div>
      </div>
      <div class="category-card" :class="{ active: form.quotation_category === 'sales' }" @click="form.quotation_category = 'sales'">
        <i class="el-icon-shopping-cart-2"></i>
        <div class="cc-name">销售报价</div>
        <div class="cc-desc">针对产品或配件采购需求，估算销售价格</div>
      </div>
      <div class="step-actions">
        <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
        <el-button size="small" type="primary" :disabled="!form.quotation_category" @click="step = 2">下一步</el-button>
      </div>
    </div>

    <!-- 第二步：填写报价单信息 -->
    <el-form v-else ref="form" :model="form" label-width="100px" size="small" v-loading="loading">
      <el-divider content-position="left">基本信息</el-divider>
      <el-row :gutter="12">
        <el-col :span="12">
          <el-form-item label="报价类别">
            <el-tag size="small" :type="form.quotation_category === 'repair' ? 'warning' : 'primary'">{{ form.quotation_category === 'repair' ? '维修报价' : '销售报价' }}</el-tag>
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="客户" prop="customer_id">
            <el-select v-model="form.customer_id" filterable style="width:100%" placeholder="选择客户">
              <el-option v-for="c in customerOptions" :key="c.id" :label="c.customer_name" :value="c.id" />
            </el-select>
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="报价日期" prop="quotation_date">
            <el-date-picker v-model="form.quotation_date" type="date" value-format="yyyy-MM-dd" style="width:100%" @change="calcValidity" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="有效期天数">
            <el-input-number v-model="form.validity_days" :min="1" :max="365" style="width:100%" @change="calcValidity" />
          </el-form-item>
        </el-col>
        <el-col :span="8">
          <el-form-item label="有效期至">
            <el-input :value="form.validity_date || '--'" disabled />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="预计交付日期">
            <el-date-picker v-model="form.delivery_date" type="date" value-format="yyyy-MM-dd" style="width:100%" />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="业务员">
            <el-select v-model="form.salesperson_id" filterable clearable style="width:100%">
              <el-option v-for="u in userOptions" :key="u.id" :label="u.real_name || u.username" :value="u.id" />
            </el-select>
          </el-form-item>
        </el-col>
      </el-row>

      <!-- 报价明细 -->
      <el-divider content-position="left">报价明细</el-divider>
      <el-table :data="form.items" size="small" border>
        <el-table-column type="index" label="序号" width="50" align="center" />
        <el-table-column label="项目类型" width="100">
          <template slot-scope="s">
            <el-select v-model="s.row.item_type" size="small" style="width:100%">
              <el-option v-for="opt in itemTypeOptions" :key="opt.value" :label="opt.label" :value="opt.value" />
            </el-select>
          </template>
        </el-table-column>
        <el-table-column label="项目名称" min-width="150">
          <template slot-scope="s"><el-input v-model="s.row.item_name" placeholder="项目名称*" /></template>
        </el-table-column>
        <el-table-column label="规格型号" width="110">
          <template slot-scope="s"><el-input v-model="s.row.item_spec" placeholder="规格型号" /></template>
        </el-table-column>
        <el-table-column label="数量" width="100">
          <template slot-scope="s"><el-input-number v-model="s.row.quantity" :min="1" controls-position="right" size="small" style="width:100%" @change="calcAmount(s.$index)" /></template>
        </el-table-column>
        <el-table-column label="单价" width="120">
          <template slot-scope="s"><el-input-number v-model="s.row.unit_price" :min="0" :precision="2" controls-position="right" size="small" style="width:100%" @change="calcAmount(s.$index)" /></template>
        </el-table-column>
        <el-table-column label="金额" width="110" align="right">
          <template slot-scope="s">¥{{ (Number(s.row.amount) || 0).toFixed(2) }}</template>
        </el-table-column>
        <el-table-column label="操作" width="55" align="center">
          <template slot-scope="s"><el-button type="text" icon="el-icon-delete" class="danger" @click="form.items.splice(s.$index, 1)"></el-button></template>
        </el-table-column>
      </el-table>
      <el-button size="mini" type="text" icon="el-icon-plus" @click="addItem">添加明细</el-button>

      <el-form-item label="备注">
        <el-input v-model="form.remark" type="textarea" :rows="2" maxlength="500" />
      </el-form-item>

      <div class="amount-sum">报价金额合计：<b style="color:#f56c6c;font-size:16px">¥{{ totalAmount.toLocaleString() }}</b></div>

      <div class="dialog-footer">
        <el-button size="small" type="text" @click="step = 1">上一步</el-button>
        <el-button size="small" @click="$emit('update:visible', false)">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="handleSubmit">保存</el-button>
      </div>
    </el-form>
  </el-dialog>
</template>

<script>
import { addQuotation, editQuotation, getQuotationDetail } from '../../../../api/businessQuotation'
import { getCustomerOptions } from '../../../../api/businessCustomer'
import { getDictByCode } from '../../../../api/dictionary'

export default {
  name: 'QuotationFormDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: null }
  },
  data() {
    return {
      step: 1, loading: false, saving: false,
      customerOptions: [], userOptions: [], itemTypeOptions: [],
      form: {
        quotation_category: '', customer_id: null, quotation_date: '', validity_days: 30, validity_date: '',
        delivery_date: '', salesperson_id: null, remark: '', items: []
      }
    }
  },
  computed: {
    isEdit() { return !!(this.row && this.row.id) },
    totalAmount() { return this.form.items.reduce((s, it) => s + (Number(it.quantity) || 0) * (Number(it.unit_price) || 0), 0) }
  },
  watch: {
    visible(val) { if (val) this.open() }
  },
  methods: {
    async open() {
      this.step = 1
      this.loading = true
      this.form = { quotation_category: '', customer_id: null, quotation_date: this.today(), validity_days: 30, validity_date: '', delivery_date: '', salesperson_id: null, remark: '', items: [] }
      // 加载下拉
      try { const r = await getDictByCode('quotation_item_type'); this.itemTypeOptions = r.data || [] } catch (e) { this.itemTypeOptions = [] }
      try { const r = await getCustomerOptions(); this.customerOptions = r.data || [] } catch (e) { this.customerOptions = [] }
      try {
        const { getUserList } = await import('../../../../api/user')
        const r = await getUserList({ limit: 500 })
        this.userOptions = (r.data && r.data.list) || []
      } catch (e) { this.userOptions = [] }

      if (this.isEdit) {
        try {
          const r = await getQuotationDetail(this.row.id)
          if (r.code === 0) {
            const d = r.data
            this.form = {
              quotation_category: d.quotation_category, customer_id: d.customer_id, quotation_date: d.quotation_date,
              validity_days: d.validity_days, validity_date: d.validity_date || '', delivery_date: d.delivery_date || '',
              salesperson_id: d.salesperson_id || null, remark: d.remark || '', items: (d.items || []).map(it => ({ ...it }))
            }
            this.step = 2
          }
        } catch (e) {}
      } else {
        this.form.quotation_date = this.today()
        this.calcValidity()
        this.addItem()
      }
      this.loading = false
    },
    today() { const d = new Date(); return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}` },
    // 计算有效期截止日期（报价日期 + 有效期天数）
    calcValidity() {
      if (!this.form.quotation_date) { this.form.validity_date = ''; return }
      const d = new Date(this.form.quotation_date)
      d.setDate(d.getDate() + (Number(this.form.validity_days) || 30))
      this.form.validity_date = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
    },
    addItem() {
      const defaultType = this.form.quotation_category === 'repair' ? 'repair' : 'product'
      this.form.items.push({ item_type: defaultType, item_name: '', item_spec: '', quantity: 1, unit_price: 0, amount: 0, remark: '' })
    },
    calcAmount(index) {
      const it = this.form.items[index]
      if (!it) return
      it.amount = (Number(it.quantity) || 0) * (Number(it.unit_price) || 0)
    },
    onClose() { this.step = 1; this.$emit('update:visible', false) },
    async handleSubmit() {
      if (!this.form.customer_id) { this.$message.warning('请选择客户'); return }
      if (!this.form.quotation_date) { this.$message.warning('请选择报价日期'); return }
      if (!this.form.items.length) { this.$message.warning('请至少添加一条明细'); return }
      const invalidIndex = this.form.items.findIndex(it => !it.item_name)
      if (invalidIndex > -1) { this.$message.warning(`第 ${invalidIndex + 1} 行明细：项目名称不能为空`); return }
      this.saving = true
      try {
        const payload = {
          quotation_category: this.form.quotation_category,
          customer_id: this.form.customer_id,
          quotation_date: this.form.quotation_date,
          validity_days: this.form.validity_days,
          delivery_date: this.form.delivery_date || '',
          salesperson_id: this.form.salesperson_id || 0,
          remark: this.form.remark || '',
          items: this.form.items.map(it => ({ item_type: it.item_type, item_name: it.item_name, item_spec: it.item_spec || '', quantity: it.quantity, unit_price: it.unit_price, remark: it.remark || '' }))
        }
        if (this.isEdit) {
          const r = await editQuotation(this.row.id, payload)
          if (r.code === 0) { this.$message.success('报价单已更新'); this.$emit('success') }
        } else {
          const r = await addQuotation(payload)
          if (r.code === 0) { this.$message.success('报价单创建成功'); this.$emit('success') }
        }
      } catch (e) {}
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
.amount-sum { text-align: right; margin: 12px 0; color: #303133; }
.dialog-footer { text-align: right; }
.danger { color: #f56c6c; }
</style>
