<template>
  <el-dialog title="证书预览" :visible.sync="dialogVisible" width="950px" append-to-body @open="loadDetail">
    <div v-loading="loading" style="text-align:center;overflow:auto;max-height:70vh;">
      <div v-html="html"></div>
    </div>
    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">关闭</el-button>
      <el-button size="small" type="primary" @click="printCert">打印/导出PDF</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { previewCertificate } from '@/api/safetyTrainingArchive'

export default {
  name: 'CertificatePreviewDialog',
  props: {
    visible: Boolean,
    certId: { type: Number, default: 0 },
  },
  data() {
    return { dialogVisible: this.visible, loading: false, html: '' }
  },
  watch: {
    visible(val) { this.dialogVisible = val },
    dialogVisible(val) { this.$emit('update:visible', val) },
  },
  methods: {
    async loadDetail() {
      if (!this.certId) return
      this.loading = true
      try {
        const r = await previewCertificate(this.certId)
        if (r.code === 0) this.html = r.data.html || ''
      } catch (e) {}
      this.loading = false
    },
    printCert() {
      const w = window.open('', '_blank')
      w.document.write('<html><head><title>证书</title></head><body>' + this.html + '<script>window.print();<\/script></body></html>')
      w.document.close()
    }
  }
}
</script>
