<template>
  <el-dialog title="物料二维码" :visible="visible" width="460px" :close-on-click-modal="false" @close="handleClose">
    <div class="qr-body" v-loading="generating">
      <el-image v-if="qrcodeUrl" :src="qrcodeUrl" fit="contain" style="width:200px;height:200px" :preview-src-list="[qrcodeUrl]" />
      <el-empty v-else description="尚未生成二维码" :image-size="70" />
      <!-- 物料详细信息 -->
      <div class="qr-meta">
        <div class="meta-row"><span class="meta-label">物料名称：</span>{{ row.material_name || '-' }}</div>
        <div class="meta-row"><span class="meta-label">物料编码：</span>{{ row.material_code || '-' }}</div>
        <div class="meta-row"><span class="meta-label">规格型号：</span>{{ row.specification || '-' }}</div>
        <div class="meta-row"><span class="meta-label">物料类型：</span>{{ typeText(row.material_type) }}</div>
        <div class="meta-row"><span class="meta-label">物料分类：</span>{{ row.category_name || '-' }}</div>
        <div class="meta-row"><span class="meta-label">单位：</span>{{ row.unit || '-' }}</div>
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
import { generateMaterialQrcode, downloadMaterialQrcode, deleteMaterialQrcode, getMaterialQrcodePrintData } from '../../../../../api/warehouse'

const TYPE_TEXT = { 1: '原材料', 2: '半成品', 3: '成品', 4: '备件', 5: '辅料' }

export default {
  name: 'MaterialQrcodeDialog',
  props: {
    visible: { type: Boolean, default: false },
    row: { type: Object, default: () => ({}) }
  },
  data () {
    return { generating: false, printing: false, qrcodeUrl: '' }
  },
  watch: {
    visible (v) {
      if (v) this.qrcodeUrl = (this.row && this.row.qrcode_url) || ''
    }
  },
  methods: {
    typeText (v) { return TYPE_TEXT[v] || '-' },
    handleClose () { this.$emit('update:visible', false) },
    async handleGenerate () {
      this.generating = true
      try {
        const r = await generateMaterialQrcode(this.row.id)
        if (r.code === 0) {
          this.qrcodeUrl = r.data.qrcode_url
          this.$message.success(r.msg || '二维码生成成功')
          this.$emit('saved')
        }
      } catch (e) {}
      this.generating = false
    },
    async handleDownload () {
      try {
        const res = await downloadMaterialQrcode(this.row.id)
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('下载失败'); return }
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = (this.row.material_code || 'material') + '.png'
        document.body.appendChild(a)
        a.click()
        document.body.removeChild(a)
        URL.revokeObjectURL(url)
      } catch (e) {}
    },
    handleDelete () {
      this.$confirm('确认删除该物料二维码吗？', '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteMaterialQrcode(this.row.id)
          if (r.code === 0) {
            this.$message.success('二维码已删除')
            this.qrcodeUrl = ''
            this.$emit('saved')
          }
        } catch (e) {}
      }).catch(() => {})
    },
    async handlePrint () {
      if (!this.qrcodeUrl) { this.$message.warning('请先生成二维码'); return }
      this.printing = true
      try {
        const res = await getMaterialQrcodePrintData([this.row.id])
        if (res.code === 0 && res.data) this.openPrintWindow(res.data)
      } catch (e) {}
      this.printing = false
    },
    openPrintWindow (data) {
      const company = data.company || '华能装备'
      const items = (data.list || []).filter(x => x.qrcode_exists)
      if (!items.length) { this.$message.warning('该物料尚未生成二维码，请先生成后再打印'); return }
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
              '<div class="label-name">' + esc(d.material_name) + '</div>' +
              '<div class="label-code">' + esc(d.material_code) + '</div>' +
              (d.specification ? '<div class="label-spec">规格：' + esc(d.specification) + '</div>' : '') +
              '<div class="label-meta">' + esc(d.material_type || '') + (d.unit ? ' · ' + esc(d.unit) : '') + (d.category_name ? ' · ' + esc(d.category_name) : '') + '</div>' +
            '</div>' +
            '<div class="label-qr"><img src="' + esc(fullUrl(d.qrcode_url)) + '"></div>' +
          '</div>' +
          '<div class="label-tip">微信扫码查看物料信息</div>' +
        '</div>'
      }).join('')
      const html = '<!DOCTYPE html><html><head><meta charset="utf-8"><title>物料二维码标签</title><style>' +
        '@media print { body * { visibility:hidden; } .print-area, .print-area * { visibility:visible; } .print-area { position:absolute; left:0; top:0; } }' +
        '.label { width:90mm; height:50mm; border:1px solid #dde3ec; border-radius:2.5mm; display:inline-block; margin:2mm; padding:0; box-sizing:border-box; vertical-align:top; overflow:hidden; background:#fff; position:relative; }' +
        '.label-head { display:flex; align-items:center; padding:2mm 3mm; background:linear-gradient(90deg,#2563eb,#3b82f6); color:#fff; }' +
        '.label-logo-img { width:6mm; height:6mm; object-fit:contain; border-radius:1.2mm; margin-right:2mm; display:block; }' +
        '.label-company { font-size:3.8mm; font-weight:700; letter-spacing:.4mm; }' +
        '.label-body { display:flex; justify-content:space-between; align-items:center; padding:2.5mm 3mm 0; }' +
        '.label-info { flex:1; min-width:0; margin-right:2mm; }' +
        '.label-name { font-size:4.2mm; font-weight:700; color:#1f2937; margin-bottom:1.5mm; line-height:1.25; word-break:break-all; }' +
        '.label-code { font-size:3mm; color:#6b7280; font-family:"Courier New",monospace; margin-bottom:1mm; }' +
        '.label-spec { font-size:2.8mm; color:#4b5563; margin-bottom:1mm; line-height:1.3; word-break:break-all; }' +
        '.label-meta { font-size:2.6mm; color:#9ca3af; line-height:1.4; }' +
        '.label-qr img { width:26mm; height:26mm; display:block; border:1px solid #eef1f4; border-radius:1mm; padding:.4mm; box-sizing:border-box; }' +
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
.qr-meta { margin-top: 12px; font-size: 13px; color: #606266; text-align: left; line-height: 1.9; width: 100%; padding: 10px 16px; background: #f8f9fa; border-radius: 8px; }
.meta-row { font-size: 13px; color: #4a5a6a; }
.meta-label { color: #909399; margin-right: 2px; }
</style>