<!--
  文件：admin/src/views/business/product/components/ProductQrcodeBatchDialog.vue
  功能：产品二维码批量管理（参考设备台账 QrcodeManageDialog）
    - 批量生成（force 强制重新生成，跳过已生成）
    - 打印标签（A4 每页 6 个，新窗口调起打印）
  props：visible / selected（选中产品数组）/ activeTab（generate|print）
  emits：saved（生成成功后刷新列表）
-->
<template>
  <el-dialog title="产品二维码批量管理" :visible.sync="dialogVisible" width="720px" top="5vh">
    <el-tabs v-model="tab">
      <!-- 批量生成 -->
      <el-tab-pane label="批量生成" name="generate">
        <div class="tip-bar">已选 {{ selected.length }} 个产品<el-switch v-model="force" active-text="强制重新生成" inactive-text="跳过已生成" style="margin-left:12px" /></div>
        <el-table :data="selected" size="mini" border max-height="280" style="width:100%">
          <el-table-column prop="product_code" label="产品编码" width="150" />
          <el-table-column prop="product_name" label="产品名称" min-width="140" />
          <el-table-column label="二维码状态" width="110" align="center">
            <template slot-scope="s"><el-tag :type="s.row.qrcode_url ? 'success' : 'info'" size="mini">{{ s.row.qrcode_url ? '已生成' : '未生成' }}</el-tag></template>
          </el-table-column>
        </el-table>
        <div v-if="resultText" class="result-text">{{ resultText }}</div>
        <div style="text-align:right;margin-top:12px">
          <el-button size="small" type="primary" :loading="generating" :disabled="!selected.length" @click="doBatchGenerate">开始生成</el-button>
        </div>
      </el-tab-pane>

      <!-- 打印标签 -->
      <el-tab-pane label="打印标签" name="print">
        <div class="tip-bar">勾选产品后生成打印标签（新窗口，A4 每页 6 个标签）</div>
        <el-table :data="selected" size="mini" border max-height="280" style="width:100%;margin-top:12px">
          <el-table-column prop="product_code" label="产品编码" width="150" />
          <el-table-column prop="product_name" label="产品名称" min-width="140" />
          <el-table-column label="二维码" width="90" align="center">
            <template slot-scope="s"><el-tag :type="s.row.qrcode_url ? 'success' : 'info'" size="mini">{{ s.row.qrcode_url ? '有' : '无' }}</el-tag></template>
          </el-table-column>
        </el-table>
        <div style="text-align:right;margin-top:12px">
          <el-button size="small" type="primary" :loading="printing" :disabled="!selected.length" @click="doPrint">生成打印页</el-button>
        </div>
      </el-tab-pane>
    </el-tabs>
  </el-dialog>
</template>

<script>
import { batchGenerateProductQrcode, getProductQrcodePrintData } from '../../../../api/product'

export default {
  name: 'ProductQrcodeBatchDialog',
  props: {
    visible: Boolean,
    selected: { type: Array, default: () => [] },
    activeTab: { type: String, default: 'generate' }
  },
  data() {
    return {
      dialogVisible: this.visible,
      force: false,
      generating: false,
      printing: false,
      resultText: ''
    }
  },
  computed: {
    tab: {
      get() { return this.activeTab },
      set(v) { this.$emit('update:activeTab', v) }
    }
  },
  watch: {
    visible(v) { this.dialogVisible = v }
  },
  methods: {
    async doBatchGenerate() {
      if (!this.selected.length) return
      this.generating = true
      this.resultText = ''
      try {
        const res = await batchGenerateProductQrcode(this.selected.map(x => x.id), this.force)
        if (res.code === 0) {
          const done = (res.data.success || []).length
          const fail = (res.data.fail || []).length
          this.resultText = `生成完成：成功 ${done} 条，失败 ${fail} 条`
          this.$emit('saved')
        }
      } catch (e) {}
      this.generating = false
    },
    async doPrint() {
      if (!this.selected.length) return
      this.printing = true
      try {
        const res = await getProductQrcodePrintData(this.selected.map(x => x.id))
        if (res.code === 0 && res.data) this.openPrintWindow(res.data)
      } catch (e) {}
      this.printing = false
    },
    openPrintWindow(data) {
      const company = data.company || '华能装备'
      const items = (data.list || []).filter(x => x.qrcode_exists)
      if (!items.length) { this.$message.warning('所选产品均未生成二维码，请先生成后再打印'); return }
      const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]))
      const fullUrl = (u) => {
        if (!u) return ''
        if (u.indexOf('/') === 0) return location.origin + u
        try {
          const parsed = new URL(u, location.origin)
          return (parsed.protocol === 'http:' || parsed.protocol === 'https:') ? parsed.href : ''
        } catch (e) { return '' }
      }
      const brand = data.brand || {}
      const brandImg = brand.logo_image ? '<img class="label-logo-img" src="' + esc(fullUrl(brand.logo_image)) + '">' : ''
      const brandText = esc(brand.system_name || data.company || '')
      const labels = items.map(function (d) {
        return '<div class="label">' +
          '<div class="label-head">' + brandImg + '<span class="label-company">' + brandText + '</span></div>' +
          '<div class="label-body">' +
            '<div class="label-info">' +
              '<div class="label-name">' + esc(d.product_name) + '</div>' +
              '<div class="label-code">' + esc(d.product_code) + '</div>' +
            '</div>' +
            '<div class="label-qr"><img src="' + esc(fullUrl(d.qrcode_url)) + '"></div>' +
          '</div>' +
          '<div class="label-tip">微信扫码查看产品信息</div>' +
        '</div>'
      }).join('')
      const html = '<!DOCTYPE html><html><head><meta charset="utf-8"><title>产品二维码标签</title><style>' +
        '@media print { body * { visibility:hidden; } .print-area, .print-area * { visibility:visible; } .print-area { position:absolute; left:0; top:0; } }' +
        '.label { width:90mm; height:50mm; border:1px solid #dde3ec; border-radius:2.5mm; display:inline-block; margin:2mm; padding:0; box-sizing:border-box; vertical-align:top; overflow:hidden; background:#fff; position:relative; }' +
        '.label-head { display:flex; align-items:center; padding:2mm 3mm; background:linear-gradient(90deg,#2563eb,#3b82f6); color:#fff; }' +
        '.label-logo-img { width:6mm; height:6mm; object-fit:contain; border-radius:1.2mm; margin-right:2mm; display:block; }' +
        '.label-company { font-size:3.8mm; font-weight:700; letter-spacing:.4mm; }' +
        '.label-body { display:flex; justify-content:space-between; align-items:center; padding:2.5mm 3mm 0; }' +
        '.label-info { flex:1; min-width:0; margin-right:2mm; }' +
        '.label-name { font-size:4.2mm; font-weight:700; color:#1f2937; margin-bottom:2mm; line-height:1.25; word-break:break-all; }' +
        '.label-code { font-size:3mm; color:#6b7280; font-family:"Courier New",monospace; }' +
        '.label-qr img { width:28mm; height:28mm; display:block; border:1px solid #eef1f4; border-radius:1mm; padding:.4mm; box-sizing:border-box; }' +
        '.label-tip { position:absolute; left:3mm; right:3mm; bottom:2mm; font-size:2.6mm; color:#9ca3af; text-align:center; line-height:1.4; }' +
        '</style></head><body onload="window.print()">' +
        '<div class="print-area">' + labels + '</div></body></html>'
      const blob = new Blob([html], { type: 'text/html;charset=utf-8' })
      const url = URL.createObjectURL(blob)
      const win = window.open(url, '_blank')
      if (!win) { this.$message.warning('浏览器拦截了新窗口，请允许弹窗后重试'); return }
      setTimeout(function () { URL.revokeObjectURL(url) }, 60000)
    }
  }
}
</script>

<style scoped>
.tip-bar { color: #606266; font-size: 13px; margin-bottom: 8px; }
.result-text { color: #67c23a; font-size: 13px; margin-top: 8px; }
</style>
