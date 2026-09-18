<!--
  文件：admin/src/views/business/product/components/ProductQrcodeDialog.vue
  功能：产品二维码弹窗（生成/预览/下载/删除/打印标签，参考设备台账二维码功能）
  权限：business:product:qrcode（入口按钮在列表页控制显隐）
-->
<template>
  <el-dialog title="产品二维码" :visible="visible" width="440px" :close-on-click-modal="false" @close="handleClose">
    <div class="qr-body" v-loading="generating">
      <el-image v-if="qrcodeUrl" :src="qrcodeUrl" fit="contain" style="width:220px;height:220px" :preview-src-list="[qrcodeUrl]" />
      <el-empty v-else description="尚未生成二维码" :image-size="70" />
      <div class="qr-meta">
        <div>产品：{{ row.product_name || '-' }}</div>
        <div>编码：{{ row.product_code || '-' }}</div>
      </div>
    </div>
    <div slot="footer">
      <el-button size="small" :loading="generating" @click="handleGenerate">{{ qrcodeUrl ? '重新生成' : '生成二维码' }}</el-button>
      <el-button size="small" type="primary" icon="el-icon-download" :disabled="!qrcodeUrl || generating" @click="handleDownload">下载</el-button>
      <el-button size="small" type="primary" plain icon="el-icon-printer" :disabled="!qrcodeUrl || generating" :loading="printing" @click="handlePrint">打印标签</el-button>
      <el-button size="small" type="danger" :disabled="!qrcodeUrl" @click="handleDelete">删除</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { generateProductQrcode, downloadProductQrcode, deleteProductQrcode, getProductQrcodePrintData } from '../../../../api/product'

export default {
  name: 'ProductQrcodeDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: () => ({}) }
  },
  data() {
    return {
      generating: false,
      printing: false,
      qrcodeUrl: ''
    }
  },
  watch: {
    visible(v) {
      if (v) this.qrcodeUrl = (this.row && this.row.qrcode_url) || ''
    }
  },
  methods: {
    handleClose() {
      this.$emit('update:visible', false)
    },
    async handleGenerate() {
      this.generating = true
      try {
        const r = await generateProductQrcode(this.row.id)
        if (r.code === 0) {
          this.qrcodeUrl = r.data.qrcode_url
          this.$message.success(r.msg || '二维码生成成功')
          this.$emit('saved')
        }
      } catch (e) {}
      this.generating = false
    },
    async handleDownload() {
      try {
        const res = await downloadProductQrcode(this.row.id)
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('下载失败'); return }
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = (this.row.product_code || 'product') + '.png'
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
      } catch (e) {}
    },
    handleDelete() {
      this.$confirm('确认删除该产品二维码吗？', '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteProductQrcode(this.row.id)
          if (r.code === 0) {
            this.$message.success('二维码已删除')
            this.qrcodeUrl = ''
            this.$emit('saved')
          }
        } catch (e) {}
      }).catch(() => {})
    },
    /** 打印标签：获取打印数据后新窗口生成 A4 标签页并调起打印 */
    async handlePrint() {
      if (!this.qrcodeUrl) { this.$message.warning('请先生成二维码'); return }
      this.printing = true
      try {
        const res = await getProductQrcodePrintData([this.row.id])
        if (res.code === 0 && res.data) this.openPrintWindow(res.data)
      } catch (e) {}
      this.printing = false
    },
    openPrintWindow(data) {
      const company = data.company || '华能装备'
      const items = (data.list || []).filter(x => x.qrcode_exists)
      if (!items.length) { this.$message.warning('该产品尚未生成二维码，请先生成后再打印'); return }
      // HTML 转义，防止产品名称/编码注入
      const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]))
      // 完整 URL（Blob 打印页内相对路径可能无法加载图片）；仅允许 http/https 绝对地址或站内相对路径
      const fullUrl = (u) => {
        if (!u) return ''
        if (u.indexOf('/') === 0) return location.origin + u
        try {
          const parsed = new URL(u, location.origin)
          return (parsed.protocol === 'http:' || parsed.protocol === 'https:') ? parsed.href : ''
        } catch (e) { return '' }
      }
      // 品牌 Logo：优先界面配置的品牌 Logo，无图时用系统名称
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
.qr-body { display: flex; flex-direction: column; align-items: center; }
.qr-meta { margin-top: 12px; font-size: 13px; color: #606266; text-align: center; line-height: 1.8; }
</style>
