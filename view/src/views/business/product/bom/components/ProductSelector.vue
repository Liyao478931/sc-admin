<!--
  文件：admin/src/views/business/product/bom/components/ProductSelector.vue
  功能：产品远程搜索选择器（编码/名称模糊，仅启用产品）
    - 支持 labelText 回显（远程未加载时显示外部提供的显示文本，避免显示数字ID）
    - @selected 事件返回选中产品对象（供带出单位/编码/名称/规格）
-->
<template>
  <el-select
    :value="value"
    filterable
    remote
    :remote-method="search"
    :loading="loading"
    :disabled="disabled"
    :placeholder="placeholder"
    style="width:100%"
    @focus="onFocus"
    @change="onChange"
  >
    <el-option v-if="!matched && labelText && value !== null && value !== ''" :key="'echo-' + value" :label="labelText" :value="value" />
    <el-option
      v-for="p in options"
      :key="p.id"
      :label="p.product_code + ' ' + p.product_name + (p.specification ? ' [' + p.specification + ']' : '')"
      :value="p.id"
    />
  </el-select>
</template>

<script>
import { searchProducts } from '../../../../../api/product'

export default {
  name: 'ProductSelector',
  props: {
    value: { type: [Number, String], default: null },
    disabled: { type: Boolean, default: false },
    placeholder: { type: String, default: '输入产品编码/名称搜索' },
    labelText: { type: String, default: '' }
  },
  data() {
    return { options: [], loading: false, loadedOnce: false }
  },
  computed: {
    matched() {
      return this.options.some(p => p.id === this.value)
    }
  },
  methods: {
    async search(keyword) {
      this.loading = true
      try {
        const r = await searchProducts(keyword || '')
        this.options = (r.code === 0 && r.data) ? r.data : []
        this.loadedOnce = true
      } catch (e) { this.options = [] }
      this.loading = false
    },
    /** 下拉展开时若未加载过，先加载默认产品列表（前50条启用产品），保证可直接下拉选择 */
    onFocus() {
      if (!this.loadedOnce) this.search('')
    },
    onChange(v) {
      this.$emit('input', v)
      const picked = this.options.find(p => p.id === v)
      if (picked) this.$emit('selected', picked)
    }
  }
}
</script>
