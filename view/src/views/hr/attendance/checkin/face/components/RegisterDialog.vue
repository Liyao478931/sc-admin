<template>
  <el-dialog :title="`${isReRegister ? '重新录入' : '录入'}人脸 - ${emp.name || ''}`" :visible.sync="visible" width="520px" :close-on-click-modal="false" @closed="reset">
    <!-- 员工信息 -->
    <div class="emp-info">
      <div class="emp-item"><span class="emp-label">工号：</span>{{ emp.employee_no || '-' }}</div>
      <div class="emp-item"><span class="emp-label">姓名：</span>{{ emp.name || '-' }}</div>
      <div class="emp-item"><span class="emp-label">部门：</span>{{ emp.department_name || '-' }}</div>
    </div>

    <!-- 照片上传 -->
    <div class="upload-area">
      <el-upload
        class="avatar-uploader"
        drag
        :show-file-list="false"
        :before-upload="beforeUpload"
        accept="image/jpeg,image/png"
        :disabled="uploading || registering"
      >
        <img v-if="previewUrl" :src="previewUrl" class="avatar-preview" />
        <div v-else class="upload-placeholder">
          <i class="el-icon-camera" style="font-size:42px;color:#c0c4cc"></i>
          <div class="upload-tip">点击或拖拽照片到此处上传</div>
          <div class="upload-sub">支持 JPG / PNG，单张不超过 5M</div>
        </div>
      </el-upload>
      <div v-if="previewUrl" class="file-meta">
        <span>{{ fileName }}</span>
        <span v-if="compressed" class="compress-tag">已压缩</span>
        <span class="file-size">{{ fileSizeText }}</span>
        <el-button type="text" size="mini" @click="reset">重新选择</el-button>
      </div>
      <div class="upload-hint">请上传正面免冠照片，保持光线充足</div>
      <div v-if="errMsg" class="err-msg">{{ errMsg }}</div>
    </div>

    <span slot="footer">
      <el-button size="small" @click="visible = false">取消</el-button>
      <el-button size="small" type="primary" :loading="registering" :disabled="!imageBase64" @click="doRegister">
        {{ registering ? '录入中...' : '开始录入' }}
      </el-button>
    </span>
  </el-dialog>
</template>

<script>
import { registerFace } from '@/api/face'

export default {
  name: 'RegisterDialog',
  props: {
    visible: { type: Boolean, default: false },
    emp: { type: Object, default: () => ({}) },
    isReRegister: { type: Boolean, default: false }
  },
  data () {
    return {
      previewUrl: '', imageBase64: '', fileName: '', fileSizeText: '',
      compressed: false, uploading: false, registering: false, errMsg: ''
    }
  },
  methods: {
    beforeUpload (file) {
      this.errMsg = ''
      const isImg = /image\/(jpeg|png)/.test(file.type)
      if (!isImg) { this.errMsg = '仅支持 JPG / PNG 格式'; return false }
      // 统一走压缩：控制分辨率（腾讯云要求长边 ≤ 4000px、短边 ≥ 64px）与文件大小
      this.compressImage(file)
      return false
    },
    readFile (file, compressed) {
      const reader = new FileReader()
      reader.onload = (e) => {
        this.previewUrl = e.target.result
        this.imageBase64 = e.target.result.split(',')[1]
        this.fileName = file.name
        this.fileSizeText = this.formatSize(file.size)
        this.compressed = compressed
      }
      reader.readAsDataURL(file)
    },
    // Canvas 压缩图片（目标长边 800px，质量 0.85，适配腾讯云分辨率/大小限制）
    compressImage (file) {
      this.uploading = true
      const reader = new FileReader()
      reader.onload = (e) => {
        const img = new Image()
        img.onload = () => {
          // 按长边缩放：最长边目标 800px（人脸识别足够，避免分辨率过大）
          const maxSide = 800
          const longSide = Math.max(img.width, img.height)
          const scale = Math.min(1, maxSide / longSide)
          const canvas = document.createElement('canvas')
          canvas.width = Math.max(1, Math.round(img.width * scale))
          canvas.height = Math.max(1, Math.round(img.height * scale))
          const ctx = canvas.getContext('2d')
          ctx.drawImage(img, 0, 0, canvas.width, canvas.height)
          const dataUrl = canvas.toDataURL('image/jpeg', 0.85)
          const base64 = dataUrl.split(',')[1]
          const bytes = Math.floor(base64.length * 3 / 4)
          this.previewUrl = dataUrl
          this.imageBase64 = base64
          this.fileName = file.name
          this.fileSizeText = this.formatSize(bytes)
          this.compressed = true
          this.uploading = false
          if (bytes > 5 * 1024 * 1024) this.errMsg = '压缩后仍超过 5M，请更换照片'
        }
        img.onerror = () => { this.uploading = false; this.errMsg = '图片解析失败' }
        img.src = e.target.result
      }
      reader.readAsDataURL(file)
    },
    formatSize (bytes) {
      if (!bytes) return ''
      if (bytes < 1024) return bytes + ' B'
      if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
      return (bytes / 1024 / 1024).toFixed(2) + ' MB'
    },
    async doRegister () {
      if (!this.imageBase64) { this.errMsg = '请先上传照片'; return }
      this.registering = true
      this.errMsg = ''
      try {
        const r = await registerFace({ user_id: this.emp.user_id, image: this.imageBase64 })
        if (r.code === 0) {
          this.$message.success(r.msg || '人脸录入成功')
          this.visible = false
          this.$emit('saved')
        } else {
          this.errMsg = r.msg || '录入失败'
        }
      } catch (e) {
        this.errMsg = '请求失败，请重试'
      } finally {
        this.registering = false
      }
    },
    reset () {
      this.previewUrl = ''; this.imageBase64 = ''; this.fileName = ''; this.fileSizeText = ''
      this.compressed = false; this.uploading = false; this.errMsg = ''
    }
  }
}
</script>

<style scoped>
.emp-info { display: flex; gap: 20px; flex-wrap: wrap; background: #f5f7fa; border-radius: 6px; padding: 10px 14px; margin-bottom: 16px; }
.emp-item { font-size: 13px; color: #606266; }
.emp-label { color: #909399; }
.upload-area { text-align: center; }
.avatar-uploader { width: 100%; }
.avatar-preview { width: 200px; height: 200px; object-fit: cover; border-radius: 8px; border: 1px solid #e4e7ed; }
.upload-placeholder { padding: 30px 0; }
.upload-tip { font-size: 14px; color: #606266; margin-top: 10px; }
.upload-sub { font-size: 12px; color: #c0c4cc; margin-top: 6px; }
.file-meta { margin-top: 10px; font-size: 13px; color: #606266; display: flex; align-items: center; justify-content: center; gap: 8px; }
.compress-tag { background: #fdf6ec; color: #e6a23c; font-size: 11px; padding: 1px 6px; border-radius: 3px; }
.file-size { color: #909399; }
.upload-hint { font-size: 12px; color: #c0c4cc; margin-top: 8px; }
.err-msg { color: #f56c6c; font-size: 13px; margin-top: 8px; }
</style>
