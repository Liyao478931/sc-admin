<!--
  文件：admin/src/views/business/product/drawing/components/FileUploader.vue
  功能：图纸文件上传（拖拽/点击，格式与大小校验，编辑模式显示当前文件）
  props：fileType（1-5 图纸类型，用于扩展名白名单）、existingFile（编辑模式当前文件）、disabled
  emits：file（选中的 File 或 null）
-->
<template>
  <div class="file-uploader">
    <div v-if="!disabled" class="fu-drive-btn">
      <el-button size="mini" type="primary" plain icon="el-icon-folder-opened" @click="driveVisible = true">从企业网盘选择</el-button>
    </div>
    <drive-file-picker :visible="driveVisible" mode="file" :multiple="false" @update:visible="driveVisible = $event" @confirm="onDrivePick" />
    <el-upload
      drag
      :auto-upload="false"
      :limit="1"
      :disabled="disabled"
      accept=".dwg,.dxf,.pdf,.jpg,.jpeg,.png,.gif,.bmp,.stp,.step,.igs,.iges"
      :file-list="fileList"
      :on-change="onChange"
      :on-remove="onRemove"
      :on-exceed="onExceed"
    >
      <i class="el-icon-upload"></i>
      <div class="el-upload__text">点击或拖拽上传图纸文件</div>
      <div class="el-upload__tip" slot="tip">
        支持格式：{{ allowedText }}；单个文件不超过 50MB
      </div>
    </el-upload>

    <!-- 已选新文件 -->
    <div v-if="selectedFile" class="file-info">
      <i class="el-icon-document"></i>
      <span class="file-name">{{ selectedFile.name }}</span>
      <span class="file-meta">{{ formatSize(selectedFile.size) }} · {{ extOf(selectedFile.name) }}</span>
      <el-button type="text" size="mini" @click="removeSelected">删除</el-button>
    </div>
    <!-- 编辑模式：当前文件（未重新上传时） -->
    <div v-else-if="existingFile && existingFile.file_name" class="file-info current">
      <i class="el-icon-document"></i>
      <span class="file-name">{{ existingFile.file_name }}</span>
      <span class="file-meta">{{ formatSize(existingFile.file_size) }} · {{ existingFile.file_ext }}（当前版本，重新上传将生成历史版本）</span>
    </div>
  </div>
</template>

<script>
const TYPE_EXTS = {
  1: ['dwg', 'dxf'],
  2: ['pdf'],
  3: ['jpg', 'jpeg', 'png', 'gif', 'bmp'],
  4: ['stp', 'step', 'igs', 'iges'],
  5: ['dwg', 'dxf', 'pdf', 'jpg', 'jpeg', 'png', 'gif', 'bmp', 'stp', 'step', 'igs', 'iges', 'zip', 'rar', 'doc', 'docx', 'xls', 'xlsx', 'txt']
}
const MAX_SIZE = 50 * 1024 * 1024

export default {
  name: 'FileUploader',
  props: {
    fileType: { type: Number, default: 1 },
    existingFile: { type: Object, default: () => ({}) },
    disabled: { type: Boolean, default: false }
  },
  data() {
    return { fileList: [], selectedFile: null, driveVisible: false }
  },
  computed: {
    allowed() { return TYPE_EXTS[this.fileType] || TYPE_EXTS[5] },
    allowedText() { return '.' + this.allowed.join('/.') }
  },
  methods: {
    extOf(name) {
      const i = String(name || '').lastIndexOf('.')
      return i > -1 ? String(name).slice(i + 1).toLowerCase() : ''
    },
    formatSize(bytes) {
      if (bytes === null || bytes === undefined) return '-'
      const b = Number(bytes)
      if (b < 1024 * 1024) return (b / 1024).toFixed(1) + 'KB'
      return (b / (1024 * 1024)).toFixed(1) + 'MB'
    },
    onChange(file) {
      // file.raw 为原始 File；校验格式与大小
      const raw = file.raw
      if (!raw) return
      const ext = this.extOf(raw.name)
      if (!this.allowed.includes(ext)) {
        this.$message.warning('文件格式不支持：.' + ext + '，该类型允许：' + this.allowedText)
        this.fileList = []
        this.selectedFile = null
        this.$emit('file', null)
        return
      }
      if (raw.size > MAX_SIZE) {
        this.$message.warning('文件大小不能超过50MB')
        this.fileList = []
        this.selectedFile = null
        this.$emit('file', null)
        return
      }
      this.fileList = [file]
      this.selectedFile = raw
      this.$emit('file', raw)
    },
    onRemove() {
      this.fileList = []
      this.selectedFile = null
      this.$emit('file', null)
    },
    onExceed() {
      this.$message.warning('只能选择一个文件')
    },
    removeSelected() {
      this.fileList = []
      this.selectedFile = null
      this.$emit('file', null)
    },
    async onDrivePick(list) {
      const f = list[0]
      if (!f) return
      if (this.fileType && this.allowed.length) {
        const ext = this.extOf(f.name)
        if (!this.allowed.includes(ext)) {
          this.$message.warning('该文件类型不支持：.' + ext + '，允许：' + this.allowedText)
          return
        }
      }
      try {
        const blob = await fetch(f.url).then(res => res.blob())
        const raw = new File([blob], f.name, { type: blob.type || 'application/octet-stream' })
        if (raw.size > MAX_SIZE) {
          this.$message.warning('文件大小不能超过50MB')
          return
        }
        this.fileList = [{ name: f.name, url: f.url, raw }]
        this.selectedFile = raw
        this.$emit('file', raw)
        this.$message.success('已从网盘选择：' + f.name)
      } catch (e) {
        this.$message.error('读取网盘文件失败，请重试')
      }
    }
  }
}
</script>

<style scoped>
.file-info { display: flex; align-items: center; margin-top: 10px; font-size: 13px; color: #606266; }
.file-info .file-name { margin: 0 8px; font-weight: 600; }
.file-info .file-meta { color: #909399; margin-right: 8px; }
.file-info.current { background: #f5f7fa; padding: 8px 10px; border-radius: 4px; }
</style>
