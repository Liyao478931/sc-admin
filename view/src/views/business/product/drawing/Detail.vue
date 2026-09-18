<!--
  文件：admin/src/views/business/product/drawing/Detail.vue
  功能：图纸详情（信息卡 + 预览 + 版本历史）
  权限：页面 business:product:drawing:list；编辑 drawing:edit；下载 drawing:download
-->
<template>
  <div class="drawing-detail-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品管理</el-breadcrumb-item>
      <el-breadcrumb-item>图纸管理</el-breadcrumb-item>
      <el-breadcrumb-item>图纸详情</el-breadcrumb-item>
    </el-breadcrumb>

    <div class="page-header">
      <span class="page-title">图纸详情 - {{ drawing.drawing_name || '' }}</span>
      <div class="header-actions">
        <el-button size="small" @click="$router.push('/business/product/drawing/list')">返回列表</el-button>
        <el-button v-permission="'business:product:drawing:download'" type="primary" size="small" icon="el-icon-download" @click="handleDownload">下载图纸</el-button>
        <el-button v-permission="'business:product:drawing:edit'" size="small" @click="$router.push(`/business/product/drawing/edit/${id}`)">编辑</el-button>
      </div>
    </div>

    <el-card shadow="never" v-loading="loading">
      <template v-if="loadFailed">
        <el-empty description="加载失败，请刷新重试">
          <el-button size="small" @click="$router.push('/business/product/drawing/list')">返回列表</el-button>
        </el-empty>
      </template>
      <template v-else-if="drawing.id">
        <!-- 信息卡 -->
        <div class="section-title">图纸信息</div>
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="图纸编号">{{ drawing.drawing_code }}</el-descriptions-item>
          <el-descriptions-item label="图纸名称">{{ drawing.drawing_name }}</el-descriptions-item>
          <el-descriptions-item label="关联产品">
            <span class="link-text" @click="viewProduct(drawing.product_id)">{{ drawing.product_name }}</span>
          </el-descriptions-item>
          <el-descriptions-item label="图纸类型">
            <el-tag size="mini" :type="typeTag(drawing.drawing_type)" :class="{ 'tag-purple': drawing.drawing_type === 4 }">{{ drawing.drawing_type_label }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="图纸分类">{{ drawing.category_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="版本号">
            {{ drawing.version }}
            <el-tag v-if="drawing.is_newest === 1" size="mini" type="success" style="margin-left:4px">最新</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="状态">
            <el-tag size="mini" :type="drawing.status === 1 ? 'success' : 'info'">{{ drawing.status === 1 ? '启用' : '停用' }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="文件名称">{{ drawing.file_name }}</el-descriptions-item>
          <el-descriptions-item label="文件大小">{{ formatSize(drawing.file_size) }}</el-descriptions-item>
          <el-descriptions-item label="文件格式">{{ drawing.file_ext || '-' }}</el-descriptions-item>
          <el-descriptions-item label="上传人">{{ drawing.uploader_name || '-' }}</el-descriptions-item>
          <el-descriptions-item label="上传时间">{{ drawing.uploaded_at || '-' }}</el-descriptions-item>
          <el-descriptions-item label="创建时间">{{ drawing.create_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="更新时间">{{ drawing.update_time || '-' }}</el-descriptions-item>
          <el-descriptions-item label="备注" :span="2">{{ drawing.remark || '-' }}</el-descriptions-item>
        </el-descriptions>

        <!-- 预览 -->
        <div class="section-title">图纸预览</div>
        <DrawingPreview :drawing="drawing" @download="handleDownload" />

        <!-- 版本历史 -->
        <div class="section-title">版本历史 <span class="section-sub">共 {{ versions.length }} 个版本</span></div>
        <VersionHistory :versions="versions" @download="downloadVersion" />
      </template>
    </el-card>
  </div>
</template>

<script>
import { getDrawingDetail, downloadDrawing, downloadDrawingVersion } from '../../../../api/product'
import DrawingPreview from './components/DrawingPreview.vue'
import VersionHistory from './components/VersionHistory.vue'

export default {
  name: 'BusinessProductDrawingDetail',
  components: { DrawingPreview, VersionHistory },
  data() {
    return {
      id: Number(this.$route.params.id) || 0,
      loading: false,
      loadFailed: false,
      drawing: {},
      versions: []
    }
  },
  created() {
    this.fetchDetail()
  },
  methods: {
    typeTag(t) { return { 1: 'primary', 2: 'warning', 3: 'success', 4: 'primary', 5: 'info' }[t] || 'info' },
    formatSize(bytes) {
      if (bytes === null || bytes === undefined) return '-'
      const b = Number(bytes)
      if (b < 1024 * 1024) return (b / 1024).toFixed(1) + 'KB'
      return (b / (1024 * 1024)).toFixed(1) + 'MB'
    },
    async fetchDetail() {
      this.loading = true
      this.loadFailed = false
      try {
        const r = await getDrawingDetail(this.id)
        if (r.code === 0 && r.data) {
          this.drawing = r.data.drawing || {}
          this.versions = r.data.versions || []
        } else {
          this.loadFailed = true
        }
      } catch (e) { this.loadFailed = true }
      this.loading = false
    },
    viewProduct(id) { if (id) this.$router.push(`/business/product/detail/${id}`) },
    async handleDownload() {
      try {
        const res = await downloadDrawing(this.id)
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('下载失败'); return }
        this.trigger(blob, this.drawing.file_name || this.drawing.drawing_code)
      } catch (e) {}
    },
    async downloadVersion(version) {
      try {
        const res = await downloadDrawingVersion(version.id)
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('下载失败'); return }
        this.trigger(blob, version.file_name || ('drawing_' + version.version))
      } catch (e) {}
    },
    trigger(blob, filename) {
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = filename
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
      URL.revokeObjectURL(url)
    }
  }
}
</script>

<style scoped>
.drawing-detail-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.page-title { font-size: 18px; font-weight: 700; color: #303133; }
.header-actions .el-button + .el-button { margin-left: 10px; }
.section-title { display: flex; align-items: center; font-size: 15px; font-weight: 600; margin: 18px 0 12px; }
.section-title::before { content: ''; width: 4px; height: 14px; border-radius: 2px; background: #409eff; margin-right: 8px; }
.section-sub { font-size: 12px; color: #909399; font-weight: 400; margin-left: 8px; }
.link-text { color: #409eff; cursor: pointer; }
::v-deep .tag-purple { background-color: #f3e5f5; border-color: #ce93d8; color: #8e24aa; }
</style>
