<!--
  文件：admin/src/views/business/product/bom/components/BomHeaderForm.vue
  功能：BOM 头信息表单（新增/编辑共用）
    - 产品远程搜索、BOM编号唯一性校验（失焦）、版本/数量/单位/默认/日期/备注
  props：form（对象，直接修改属性）、disabled（已审批只读）、id（编辑时BOM ID，编号校验排除自身）
  emits：code-status（{valid, msg}）通知父级编号是否可用
-->
<template>
  <el-form ref="headerForm" :model="form" :rules="rules" label-width="120px" size="small">
    <el-row :gutter="16">
      <el-col :span="12">
        <el-form-item label="选择产品" prop="product_id">
          <ProductSelector v-model="form.product_id" :disabled="disabled" :label-text="productLabel" @input="onProductChange" @selected="onProductSelected" />
        </el-form-item>
      </el-col>
      <el-col :span="12">
        <el-form-item label="BOM编号" prop="bom_code">
          <el-input v-model="form.bom_code" :disabled="disabled" placeholder="如 BOM202608120001" clearable @blur="checkCode" @input="codeChecked = false" />
          <div v-if="codeError" class="code-error">{{ codeError }}</div>
        </el-form-item>
      </el-col>
      <el-col :span="12">
        <el-form-item label="BOM名称" prop="bom_name">
          <el-input v-model="form.bom_name" :disabled="disabled" placeholder="请输入BOM名称" clearable />
        </el-form-item>
      </el-col>
      <el-col :span="12">
        <el-form-item label="版本号" prop="version">
          <el-input v-model="form.version" :disabled="disabled" placeholder="如 V1.0" clearable />
        </el-form-item>
      </el-col>
      <el-col :span="12">
        <el-form-item label="父件数量" prop="quantity">
          <el-input-number v-model="form.quantity" :disabled="disabled" :min="0.0001" :max="999999" :precision="4" :step="1" style="width:100%" />
        </el-form-item>
      </el-col>
      <el-col :span="12">
        <el-form-item label="单位" prop="unit">
          <el-input v-model="form.unit" :disabled="disabled" placeholder="选中产品自动带出" clearable />
        </el-form-item>
      </el-col>
      <el-col :span="12">
        <el-form-item label="是否默认">
          <el-switch v-model="form.is_default" :active-value="1" :inactive-value="0" :disabled="disabled" @change="onDefaultChange" />
          <div class="form-tip">开启后将取消该产品其他BOM的默认状态</div>
        </el-form-item>
      </el-col>
      <el-col :span="12">
        <el-form-item label="状态">
          <el-radio-group v-model="form.status" :disabled="disabled">
            <el-radio :label="1">启用</el-radio>
            <el-radio :label="0">停用</el-radio>
          </el-radio-group>
        </el-form-item>
      </el-col>
      <el-col :span="12">
        <el-form-item label="生效日期" prop="effective_date">
          <el-date-picker v-model="form.effective_date" :disabled="disabled" type="date" value-format="yyyy-MM-dd" placeholder="选择生效日期" style="width:100%" />
        </el-form-item>
      </el-col>
      <el-col :span="12">
        <el-form-item label="失效日期" prop="expiry_date">
          <el-date-picker v-model="form.expiry_date" :disabled="disabled" type="date" value-format="yyyy-MM-dd" placeholder="选择失效日期" style="width:100%" />
        </el-form-item>
      </el-col>
      <el-col :span="24">
        <el-form-item label="备注" prop="remark">
          <el-input v-model="form.remark" :disabled="disabled" type="textarea" :rows="3" placeholder="备注说明（可选）" />
        </el-form-item>
      </el-col>
    </el-row>
  </el-form>
</template>

<script>
import ProductSelector from './ProductSelector.vue'
import { checkBomCode } from '../../../../../api/product'

export default {
  name: 'BomHeaderForm',
  components: { ProductSelector },
  props: {
    form: { type: Object, required: true },
    disabled: { type: Boolean, default: false },
    id: { type: Number, default: 0 },
    productLabel: { type: String, default: '' }
  },
  data() {
    return {
      codeError: '',
      codeChecked: false,
      rules: {
        product_id: [{ required: true, message: '请选择产品', trigger: 'change' }],
        bom_code: [{ required: true, message: '请输入BOM编号', trigger: 'blur' }],
        bom_name: [{ required: true, message: '请输入BOM名称', trigger: 'blur' }],
        version: [{ required: true, message: '请输入版本号', trigger: 'blur' }]
      }
    }
  },
  methods: {
    /** 产品变化：重置编号校验状态 */
    onProductChange() {
      this.codeChecked = false
    },
    /** 选中产品：带出单位（选中对象由 ProductSelector 提供） */
    onProductSelected(p) {
      if (p) this.form.unit = p.unit || ''
    },
    /** BOM编号失焦唯一性校验 */
    async checkCode() {
      const code = (this.form.bom_code || '').trim()
      if (!code) { this.codeError = ''; this.$emit('code-status', { valid: true }); return }
      try {
        const r = await checkBomCode(code, this.id)
        const exists = r.code === 0 && r.data && r.data.exists
        this.codeChecked = true
        this.codeError = exists ? '该BOM编号已存在，请重新输入' : ''
        this.$emit('code-status', { valid: !exists })
      } catch (e) { this.codeError = '' }
    },
    onDefaultChange(v) {
      if (v === 1) this.$message.info('将该BOM设为默认后，该产品原有的默认BOM将被取消')
    },
    /** 供父组件调用：校验表单，返回是否通过 */
    validate() {
      return new Promise(resolve => {
        this.$refs.headerForm.validate(valid => resolve(valid))
      })
    }
  }
}
</script>

<style scoped>
.code-error { color: #f56c6c; font-size: 12px; line-height: 1.4; margin-top: 4px; }
.form-tip { font-size: 12px; color: #909399; line-height: 1.4; margin-top: 4px; }
</style>
