<template>
  <div class="diy-upload-img">
    <div class="diy-upload-box" @click="triggerUpload">
      <img v-if="value" :src="value" class="diy-upload-preview" alt="" />
      <div v-else class="diy-upload-placeholder">
        <i class="el-icon-plus"></i>
        <span>上传图片</span>
      </div>
      <div v-if="value" class="diy-upload-del" @click.stop="clearValue">
        <i class="el-icon-delete"></i>
      </div>
    </div>
    <input ref="fileInput" type="file" accept="image/*" style="display:none" @change="handleFileChange" />
  </div>
</template>

<script>
import request from '@/api/request'

export default {
  name: 'DiyUploadImg',
  props: {
    value: { type: String, default: '' },
    // 上传类型参数（如 image/logo/banner），透传给后端
    uploadType: { type: String, default: 'image' }
  },
  methods: {
    triggerUpload() {
      this.$refs.fileInput.click()
    },
    async handleFileChange(e) {
      const file = e.target.files && e.target.files[0]
      if (!file) return
      const fd = new FormData()
      fd.append('file', file)
      try {
        // 通用上传接口：/api/upload（UploadController/index），返回 { url: '/uploads/...' }
        const r = await request({ url: '/upload', method: 'post', data: fd })
        if (r.code === 0 && r.data && r.data.url) {
          this.$emit('input', r.data.url)
          this.$message.success('上传成功')
        } else {
          this.$message.error(r.msg || '上传失败')
        }
      } catch (err) {
        this.$message.error('上传失败')
      } finally {
        e.target.value = ''
      }
    },
    clearValue() {
      this.$emit('input', '')
    }
  }
}
</script>

<style scoped>
.diy-upload-img { display: inline-block; }
.diy-upload-box { position: relative; width: 72px; height: 72px; border: 1px solid #E8ECF1; border-radius: 6px; overflow: hidden; cursor: pointer; background: #f7f8fa; }
.diy-upload-preview { width: 100%; height: 100%; object-fit: cover; display: block; }
.diy-upload-placeholder { display: flex; flex-direction: column; align-items: center; justify-content: center; width: 100%; height: 100%; color: #909399; font-size: 12px; gap: 4px; }
.diy-upload-placeholder i { font-size: 22px; }
.diy-upload-del { position: absolute; top: 0; right: 0; background: rgba(0,0,0,0.5); color: #fff; width: 20px; height: 20px; display: flex; align-items: center; justify-content: center; border-radius: 0 0 0 6px; font-size: 12px; }
</style>
