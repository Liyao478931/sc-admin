<!--
  文件：admin/src/views/business/contract/template/components/TemplatePreviewDialog.vue
  功能：模板预览弹窗（850px，展示模板渲染后的完整效果）
-->
<template>
  <el-dialog title="模板预览" :visible="visible" width="850px" :close-on-click-modal="false" top="4vh" @close="$emit('update:visible', false)">
    <div v-loading="loading" class="preview-body">
      <iframe v-if="html" :srcdoc="html" class="preview-frame"></iframe>
      <el-empty v-else description="暂无预览内容" />
    </div>
  </el-dialog>
</template>

<script>
import { getTemplateDetail } from '../../../../../api/contractTemplate'

export default {
  name: 'TemplatePreviewDialog',
  props: {
    visible: { type: Boolean, default: false },
    templateId: { type: Number, default: 0 }
  },
  data() {
    return { loading: false, html: '' }
  },
  watch: {
    visible(val) { if (val && this.templateId) this.open() }
  },
  methods: {
    async open() {
      this.loading = true
      this.html = ''
      try {
        const r = await getTemplateDetail(this.templateId)
        if (r.code === 0 && r.data) {
          // 示例数据渲染预览（未保存变量保留占位符）
          const sample = { contract_no: 'CT-20260810-0001', contract_name: '示例合同', sign_date: '2026年08月10日', sign_location: '山西省大同市', customer_name: '客户名称', supplier_name: '供应商名称', total_amount: '10000.00', total_amount_cn: '壹万元整', payment_terms: '验收合格后付清全款', items_table: '<table border="1" cellpadding="6" style="width:100%;border-collapse:collapse;text-align:center;"><tr><th>序号</th><th>名称</th><th>数量</th><th>金额（元）</th></tr><tr><td>1</td><td>示例服务</td><td>1</td><td>10000.00</td></tr></table>' }
          let html = r.data.content || ''
          Object.keys(sample).forEach(k => { html = html.split('{' + k + '}').join(sample[k]) })
          this.html = html
        }
      } catch (e) {}
      this.loading = false
    }
  }
}
</script>

<style scoped>
.preview-body { height: 70vh; }
.preview-frame { width: 100%; height: 100%; border: 1px solid #ebeef5; }
</style>
