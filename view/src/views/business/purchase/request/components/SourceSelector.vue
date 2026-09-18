<!--
  文件：admin/src/views/business/purchase/request/components/SourceSelector.vue
  功能：来源单据选择器（销售订单/维修订单远程搜索；其他来源不显示）
  props：sourceType / sourceId / sourceNo
  emits：input（选中 {id, no}） / cleared
-->
<template>
  <div>
    <el-select
      v-if="sourceType === 2 || sourceType === 3"
      :value="sourceId"
      filterable
      remote
      :remote-method="search"
      :loading="loading"
      placeholder="输入单号/名称搜索"
      style="width:100%"
      @focus="!loadedOnce && search('')"
      @change="onChange"
    >
      <el-option v-for="o in options" :key="o.id" :label="o.label" :value="o.id" />
    </el-select>
    <div v-else class="none-tip">该来源类型无需来源单据</div>
  </div>
</template>

<script>
import { getSourceOptions } from '../../../../../api/purchase'

export default {
  name: 'SourceSelector',
  props: {
    sourceType: { type: Number, default: 1 },
    sourceId: { type: Number, default: 0 },
    sourceNo: { type: String, default: '' }
  },
  data() {
    return { options: [], loading: false, loadedOnce: false }
  },
  methods: {
    async search(keyword) {
      this.loading = true
      try {
        const r = await getSourceOptions(this.sourceType, keyword || '')
        this.options = (r.code === 0 && r.data) ? r.data : []
        this.loadedOnce = true
      } catch (e) { this.options = [] }
      this.loading = false
    },
    onChange(id) {
      const o = this.options.find(x => x.id === id)
      this.$emit('input', { id, no: o ? o.no : '', expected_date: o ? (o.expected_date || '') : '' })
    }
  }
}
</script>

<style scoped>
.none-tip { color: #909399; font-size: 12px; line-height: 32px; }
</style>
