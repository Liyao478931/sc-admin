<template>
  <el-dialog title="导入设备数据" :visible.sync="dialogVisible" width="500px" @closed="resetForm">
    <div class="import-body">
      <div class="import-tip">
        <el-button size="small" icon="el-icon-download" @click="downloadTemplate">下载导入模板</el-button>
        <span class="tip-text">模板列：设备编码、设备名称、设备类型、所属分类编码、型号、品牌、状态、备注</span>
      </div>
      <el-upload drag action="#" :auto-upload="false" :limit="1" :on-change="onFileChange" :file-list="fileList" accept=".xlsx,.xls">
        <i class="el-icon-upload"></i>
        <div class="el-upload__text">将文件拖到此处，或<em>点击上传</em></div>
      </el-upload>
      <el-form label-width="100px" size="small" style="margin-top:12px">
        <el-form-item label="导入模式">
          <el-radio-group v-model="mode">
            <el-radio label="append">追加</el-radio>
            <el-radio label="cover">覆盖（编码相同则更新）</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="progressVisible" label="导入进度">
          <el-progress :percentage="progress" />
        </el-form-item>
      </el-form>
    </div>
    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="importing" :disabled="!selectedFile" @click="doImport">开始导入</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { importAssets } from '@/api/deviceAsset'

export default {
  name: 'AssetImportDialog',
  props: { visible: Boolean },
  data() {
    return {
      dialogVisible: this.visible,
      fileList: [],
      selectedFile: null,
      mode: 'append',
      importing: false,
      progressVisible: false,
      progress: 0
    }
  },
  watch: {
    visible(val) { this.dialogVisible = val }
  },
  methods: {
    onFileChange(file, list) {
      this.selectedFile = file.raw
      this.fileList = list.slice(-1)
    },
    downloadTemplate() {
      // 前端生成 CSV 模板（UTF-8 BOM，兼容 Excel）
      const header = '设备编码,设备名称,设备类型,所属分类编码,型号,品牌,状态,备注\n'
      const sample = ',示例设备,普通设备,GENERAL_EQUIPMENT_OFFICE,型号A,品牌A,in_use,示例行\n'
      const blob = new Blob(['\ufeff' + header + sample], { type: 'text/csv;charset=utf-8' })
      const a = document.createElement('a')
      a.href = URL.createObjectURL(blob)
      a.download = '设备导入模板.csv'
      a.click()
      URL.revokeObjectURL(a.href)
    },
    resetForm() {
      this.fileList = []
      this.selectedFile = null
      this.mode = 'append'
      this.progressVisible = false
      this.progress = 0
    },
    doImport() {
      if (!this.selectedFile) return
      this.importing = true
      this.progressVisible = true
      this.progress = 10
      const timer = setInterval(() => { if (this.progress < 90) this.progress += 10 }, 200)
      const fd = new FormData()
      fd.append('file', this.selectedFile)
      fd.append('mode', this.mode)
      importAssets(fd).then(res => {
        clearInterval(timer)
        this.progress = 100
        setTimeout(() => {
          this.progressVisible = false
          if (res.code === 0) {
            const data = res.data || {}
            this.$message.success(`导入完成：成功 ${data.success || 0} 条，失败 ${data.fail || 0} 条`)
            if (data.errors && data.errors.length) {
              this.$alert(data.errors.join('\n').slice(0, 2000), '失败明细', { confirmButtonText: '知道了', type: 'warning' })
            }
            this.$emit('saved')
          }
          this.dialogVisible = false
        }, 600)
      }).catch(() => {
        clearInterval(timer)
        this.progressVisible = false
      }).finally(() => { this.importing = false })
    }
  }
}
</script>

<style scoped>
.import-body { padding: 4px 0; }
.import-tip { display: flex; align-items: center; gap: 10px; margin-bottom: 12px; }
.tip-text { color: #909399; font-size: 12px; }
</style>
