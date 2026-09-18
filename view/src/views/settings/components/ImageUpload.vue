<!--
  文件：admin/src/views/settings/components/ImageUpload.vue
  功能：图片上传组件（v-model 数组，支持 limit 数量与回显删除）
-->
<template>
  <div class="img-upload">
    <el-upload
      :action="uploadUrl" :headers="uploadHeaders" list-type="picture-card"
      :file-list="fileList" :limit="limit" :on-success="onSuccess" :on-remove="onRemove"
      :on-exceed="onExceed" :disabled="disabled" accept="image/*"
    >
      <i class="el-icon-plus"></i>
      <div class="el-upload__text"></div>
    </el-upload>
    <div v-if="!disabled" class="img-drive-btn">
      <el-button size="mini" type="primary" plain icon="el-icon-folder-opened" @click="driveVisible = true">从企业网盘选择</el-button>
    </div>
    <drive-file-picker :visible="driveVisible" mode="image" :multiple="limit > 1" @update:visible="driveVisible = $event" @confirm="onDrivePick" />
  </div>
</template>

<script>
import { getToken } from '../../../utils/auth'

export default {
  name: 'ImageUpload',
  data() {
    return { driveVisible: false }
  },
  props: {
    value: { type: Array, default: () => [] },
    limit: { type: Number, default: 1 },
    disabled: { type: Boolean, default: false }
  },
  computed: {
    uploadUrl() { return '/api/upload' },
    uploadHeaders() { return { Authorization: 'Bearer ' + getToken() } },
    fileList() { return (this.value || []).map((u, i) => ({ name: 'img_' + i, url: u })) }
  },
  methods: {
    onSuccess(res, file, fileList) {
      if (res.code === 0 && res.data && res.data.url) {
        const list = [...(this.value || [])]
        if (list.length < this.limit) list.push(res.data.url)
        this.$emit('input', list)
      } else {
        this.$message.error(res.msg || '上传失败')
        fileList.pop()
      }
    },
    onRemove(file) {
      const url = file.url || (file.response && file.response.data && file.response.data.url)
      this.$emit('input', (this.value || []).filter(u => u !== url))
    },
    onExceed() { this.$message.warning(`最多上传 ${this.limit} 张`) },
    onDrivePick(list) {
      const urls = list.map(f => f.url)
      const merged = [...(this.value || [])]
      for (const u of urls) {
        if (merged.length < this.limit) merged.push(u)
      }
      this.$emit('input', merged)
      if (list.length + (this.value || []).length > this.limit) {
        this.$message.warning(`最多 ${this.limit} 张，已截取前 ${this.limit} 张`)
      }
    }
  }
}
</script>

<style scoped>
.img-upload :deep(.el-upload--picture-card) { width: 100px; height: 100px; line-height: 100px; }
.img-upload :deep(.el-upload-list--picture-card .el-upload-list__item) { width: 100px; height: 100px; }
</style>
