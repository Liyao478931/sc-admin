<template>
  <el-dialog :title="`人脸照片 - ${emp.name || ''}`" :visible.sync="visible" width="420px">
    <div class="photo-wrap">
      <img v-if="info.face_image" :src="info.face_image" class="face-photo" />
      <div v-else class="photo-empty">暂无照片</div>
      <div class="photo-meta">
        <div class="meta-item"><span class="meta-label">录入时间：</span>{{ info.created_at || '-' }}</div>
        <div class="meta-item"><span class="meta-label">腾讯云 FaceId：</span>{{ info.face_id || '-' }}</div>
        <div class="meta-item"><span class="meta-label">人员ID：</span>{{ info.person_id || '-' }}</div>
      </div>
    </div>
  </el-dialog>
</template>

<script>
import { getFaceInfo } from '@/api/face'

export default {
  name: 'PhotoPreview',
  props: {
    visible: { type: Boolean, default: false },
    emp: { type: Object, default: () => ({}) }
  },
  data () {
    return { info: {} }
  },
  watch: {
    visible (v) {
      if (v && this.emp.user_id) this.loadInfo()
    },
    'emp.user_id' (v) {
      if (v && this.visible) this.loadInfo()
    }
  },
  created () {
    // 父组件 v-if 挂载时 watch.visible 首次不触发，必须在 created 加载
    if (this.emp.user_id) this.loadInfo()
  },
  methods: {
    async loadInfo () {
      try {
        const r = await getFaceInfo(this.emp.user_id)
        if (r.code === 0) this.info = r.data || {}
      } catch (e) {
        this.$message && this.$message.error('加载照片信息失败')
      }
    }
  }
}
</script>

<style scoped>
.photo-wrap { text-align: center; }
.face-photo { width: 300px; height: 300px; object-fit: cover; border-radius: 8px; border: 1px solid #e4e7ed; }
.photo-empty { width: 300px; height: 300px; display: flex; align-items: center; justify-content: center; background: #f5f7fa; border-radius: 8px; color: #c0c4cc; font-size: 14px; margin: 0 auto; }
.photo-meta { margin-top: 14px; text-align: left; background: #f5f7fa; border-radius: 6px; padding: 10px 14px; }
.meta-item { font-size: 13px; color: #606266; line-height: 1.8; }
.meta-label { color: #909399; }
</style>
