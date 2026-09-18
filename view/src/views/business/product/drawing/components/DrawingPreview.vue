<!--
  文件：admin/src/views/business/product/drawing/components/DrawingPreview.vue
  功能：图纸预览（PDF/图片在线预览；CAD/三维提示下载）
  props：drawing（图纸对象，含 drawing_type/file_path/file_name）
  emits：download
-->
<template>
  <div class="drawing-preview">
    <template v-if="drawing.drawing_type === 2">
      <!-- PDF 在线预览 -->
      <iframe :src="fullUrl(drawing.file_path)" class="preview-frame" title="PDF预览"></iframe>
      <div class="preview-actions">
        <el-button size="small" type="primary" icon="el-icon-download" @click="$emit('download')">下载图纸</el-button>
      </div>
    </template>
    <template v-else-if="drawing.drawing_type === 3">
      <!-- 图片预览 -->
      <div class="preview-img-wrap">
        <el-image :src="fullUrl(drawing.file_path)" fit="contain" style="max-width:100%" :preview-src-list="[fullUrl(drawing.file_path)]" />
      </div>
      <div class="preview-actions">
        <el-button size="small" type="primary" icon="el-icon-download" @click="$emit('download')">下载图纸</el-button>
      </div>
    </template>
    <template v-else>
      <!-- CAD / 三维 / 其他 -->
      <el-empty description="该格式不支持在线预览，请下载后使用对应软件（AutoCAD、SolidWorks等）打开查看">
        <el-button size="small" type="primary" icon="el-icon-download" @click="$emit('download')">下载图纸</el-button>
      </el-empty>
    </template>
  </div>
</template>

<script>
export default {
  name: 'DrawingPreview',
  props: {
    drawing: { type: Object, default: () => ({}) }
  },
  methods: {
    fullUrl(u) {
      if (!u) return ''
      if (u.indexOf('/') === 0) return location.origin + u
      return u
    }
  }
}
</script>

<style scoped>
.preview-frame { width: 100%; height: 560px; border: 1px solid #ebeef5; border-radius: 4px; }
.preview-img-wrap { text-align: center; padding: 12px 0; }
.preview-actions { text-align: center; margin-top: 12px; }
</style>
