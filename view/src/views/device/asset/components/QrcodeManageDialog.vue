<template>
  <el-dialog title="设备二维码管理" :visible.sync="dialogVisible" width="720px" top="5vh">
    <el-tabs v-model="activeTab">
      <!-- 批量生成 -->
      <el-tab-pane label="批量生成" name="generate">
        <div class="tip-bar">已选 {{ selected.length }} 台设备<el-switch v-model="force" active-text="强制重新生成" inactive-text="跳过已生成" style="margin-left:12px" /></div>
        <el-table :data="selected" size="mini" border max-height="260" style="width:100%">
          <el-table-column prop="device_code" label="设备编码" width="150" />
          <el-table-column prop="name" label="设备名称" min-width="120" />
          <el-table-column label="二维码状态" width="110">
            <template slot-scope="{ row }"><el-tag :type="row.qrcode_url ? 'success' : 'info'" size="mini">{{ row.qrcode_url ? '已生成' : '未生成' }}</el-tag></template>
          </el-table-column>
        </el-table>
        <el-progress v-if="generating" :percentage="progress" style="margin:12px 0" />
        <div v-if="resultText" style="color:#67C23A;font-size:13px;margin-top:8px">{{ resultText }}</div>
        <div style="text-align:right;margin-top:12px">
          <el-button size="small" type="primary" :loading="generating" :disabled="!selected.length" @click="doBatchGenerate">开始生成</el-button>
        </div>
      </el-tab-pane>

      <!-- 下载 -->
      <el-tab-pane label="下载" name="download">
        <div class="tip-bar">选择下载方式：</div>
        <div style="margin-top:12px">
          <el-button size="small" :disabled="!selected.length" @click="doDownload('selected')">下载选中设备二维码</el-button>
          <el-button size="small" :disabled="!allCount" @click="doDownload('all')">下载全部设备二维码</el-button>
          <el-button size="small" type="text" @click="downloadTemplateHelp">生成后将自动打包为 ZIP</el-button>
        </div>
      </el-tab-pane>

      <!-- 打印 -->
      <el-tab-pane label="打印标签" name="print">
        <div class="tip-bar">勾选设备后生成打印标签（新窗口，A4 每页 6 个标签）</div>
        <el-table :data="selected" size="mini" border max-height="220" style="width:100%;margin-top:12px">
          <el-table-column prop="device_code" label="设备编码" width="150" />
          <el-table-column prop="name" label="设备名称" min-width="140" />
          <el-table-column label="二维码" width="90" align="center">
            <template slot-scope="{ row }"><el-tag :type="row.qrcode_url ? 'success' : 'info'" size="mini">{{ row.qrcode_url ? '有' : '无' }}</el-tag></template>
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
import { batchGenerateQrcode, batchDownloadQrcode, getQrcodePrintData } from '@/api/deviceQrcode'

export default {
  name: 'QrcodeManageDialog',
  props: {
    visible: Boolean,
    selected: { type: Array, default: () => [] },
    allCount: { type: Number, default: 0 },
    activeTab: { type: String, default: 'generate' }
  },
  data() {
    return {
      dialogVisible: this.visible,
      force: false,
      generating: false,
      printing: false,
      progress: 0,
      resultText: ''
    }
  },
  computed: {
    activeTab: {
      get() { return this.$props.activeTab },
      set(val) { this.$emit('update:activeTab', val) }
    }
  },
  watch: {
    visible(val) { this.dialogVisible = val }
  },
  methods: {
    async doBatchGenerate() {
      if (!this.selected.length) return
      this.generating = true
      this.resultText = ''
      this.progress = 10
      try {
        const res = await batchGenerateQrcode(this.selected.map(x => x.id), this.force)
        this.progress = 100
        if (res.code === 0) {
          const data = res.data || {}
          const done = (data.success || []).length
          const fail = (data.fail || []).length
          this.resultText = `生成完成：成功 ${done} 条，失败 ${fail} 条`
          this.$emit('saved')
        }
      } catch (e) { /* 拦截器已提示 */ }
      setTimeout(() => { this.generating = false; this.progress = 0 }, 500)
    },
    doDownload(type) {
      const ids = type === 'selected' ? this.selected.map(x => x.id) : []
      if (type === 'selected' && !ids.length) { this.$message.warning('请先勾选设备'); return }
      this.$confirm(type === 'selected' ? `确定下载选中的 ${ids.length} 台设备二维码吗？` : `确定下载全部 ${this.allCount} 台设备二维码吗？`, '下载确认', { type: 'info' })
        .then(async () => {
          try {
            if (type === 'all') {
              // 全部下载：后端限制，前端先获取全部列表再传 ids（简化：提示使用选中方式）
              this.$message.warning('请先在列表中勾选设备后使用"下载选中设备二维码"')
              return
            }
            const res = await batchDownloadQrcode(ids)
            if (res.code === 0 && res.data && res.data.url) {
              // 后端返回可访问的 ZIP URL，直接跳转下载（适配移动端浏览器）
              const win = window.open(res.data.url)
              if (!win) window.location.href = res.data.url
              this.$message.success('已开始下载，请在下载管理中查看')
            } else if (res && res.data instanceof Blob) {
              // 兼容旧逻辑
              this.triggerBlobDownload(res.data, `设备二维码_${ids.length}台.zip`)
              this.$message.success('下载已开始')
            } else if (res.code === 0) {
              this.$emit('downloaded', res.data ? res.data.url : '')
            }
          } catch (e) { /* 拦截器已提示 */ }
        }).catch(() => {})
    },
    triggerBlobDownload(blob, filename) {
      const url = window.URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = filename
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
      window.URL.revokeObjectURL(url)
    },
    async doPrint() {
      if (!this.selected.length) return
      this.printing = true
      try {
        const res = await getQrcodePrintData(this.selected.map(x => x.id))
        if (res.code === 0 && res.data) {
          this.openPrintWindow(res.data)
        }
      } catch (e) { /* 拦截器已提示 */ }
      this.printing = false
    },
    openPrintWindow(data) {
      const company = data.company || '华能装备'
      const items = (data.list || []).filter(x => x.qrcode_exists)
      if (!items.length) { this.$message.warning('所选设备均未生成二维码，请先在设备列表生成后再打印'); return }
      // HTML 转义，防止设备名称/编码字段注入
      const esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]))
      // 完整 URL（Blob 打印页内相对路径可能无法加载图片）；严格仅允许 http/https 绝对地址或站内相对路径
      const fullUrl = (u) => {
        if (!u) return ''
        if (u.indexOf('/') === 0) return location.origin + u
        try {
          const parsed = new URL(u, location.origin)
          return (parsed.protocol === 'http:' || parsed.protocol === 'https:') ? parsed.href : ''
        } catch (e) { return '' }
      }
      // 品牌 Logo：优先用界面配置的品牌 Logo 图片，无图时用系统名称
      const brand = data.brand || {}
      const brandImg = brand.logo_image ? '<img class="label-logo-img" src="' + esc(fullUrl(brand.logo_image)) + '">' : ''
      const brandText = esc(brand.system_name || data.company || '')
      const labels = items.map(function (d) {
        return '<div class="label">' +
          '<div class="label-head">' + brandImg + '<span class="label-company">' + brandText + '</span></div>' +
          '<div class="label-body">' +
            '<div class="label-info">' +
              '<div class="label-name">' + esc(d.device_name) + '</div>' +
              '<div class="label-code">' + esc(d.device_code) + '</div>' +
            '</div>' +
            '<div class="label-qr"><img src="' + esc(fullUrl(d.qrcode_url)) + '"></div>' +
          '</div>' +
          '<div class="label-tip">微信扫码查看设备信息</div>' +
        '</div>'
      }).join('')
      const html = '<!DOCTYPE html><html><head><meta charset="utf-8"><title>设备二维码标签</title><style>' +
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
      this.$emit('saved')
    },
    downloadTemplateHelp() { /* 提示文案已内联 */ }
  }
}
</script>

<style scoped>
.tip-bar { color:#606266; font-size:13px; margin-bottom:8px; }
</style>
