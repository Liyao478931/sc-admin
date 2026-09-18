<!--
  文件：admin/src/views/business/product/drawing/List.vue
  功能：产品图纸管理列表（搜索/分页/上传/导出/预览/下载/编辑/删除/版本历史/上传新版本）
  权限：business:product:drawing:list/add/edit/delete/export/download
-->
<template>
  <div class="drawing-page">
    <el-breadcrumb separator="/" class="breadcrumb">
      <el-breadcrumb-item>经营管理</el-breadcrumb-item>
      <el-breadcrumb-item>产品管理</el-breadcrumb-item>
      <el-breadcrumb-item>图纸管理</el-breadcrumb-item>
    </el-breadcrumb>

    <!-- 搜索区 -->
    <el-card shadow="never" class="filter-card">
      <el-form inline size="small" label-width="80px" @submit.native.prevent>
        <el-form-item label="图纸名称">
          <el-input v-model="queryParams.drawing_name" placeholder="请输入图纸名称" clearable style="width:150px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="图纸编号">
          <el-input v-model="queryParams.drawing_code" placeholder="请输入图纸编号" clearable style="width:150px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="产品名称">
          <el-input v-model="queryParams.product_name" placeholder="请输入产品名称" clearable style="width:150px" @keyup.enter.native="handleSearch" />
        </el-form-item>
        <el-form-item label="图纸类型">
          <el-select v-model="queryParams.drawing_type" placeholder="全部" clearable style="width:120px" @change="handleSearch">
            <el-option label="全部" value="" />
            <el-option label="CAD图纸" value="1" />
            <el-option label="PDF图纸" value="2" />
            <el-option label="图片" value="3" />
            <el-option label="三维模型" value="4" />
            <el-option label="其他" value="5" />
          </el-select>
        </el-form-item>
        <el-form-item label="图纸分类">
          <el-cascader
            v-model="categoryId"
            :options="categoryOptions"
            :props="{ value: 'value', label: 'label', children: 'children' }"
            clearable
            filterable
            style="width:180px"
            placeholder="请选择分类"
            @change="handleSearch"
          />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="queryParams.status" placeholder="全部" clearable style="width:100px" @change="handleSearch">
            <el-option label="全部" value="" />
            <el-option label="启用" value="1" />
            <el-option label="停用" value="0" />
          </el-select>
        </el-form-item>
        <el-form-item label="上传时间">
          <el-date-picker v-model="timeRange" type="datetimerange" range-separator="至" start-placeholder="开始时间" end-placeholder="结束时间" value-format="yyyy-MM-dd HH:mm:ss" style="width:320px" @change="handleSearch" />
        </el-form-item>
        <div class="filter-btns">
          <el-button type="primary" icon="el-icon-search" @click="handleSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="handleReset">重置</el-button>
        </div>
      </el-form>
    </el-card>

    <!-- 工具栏 + 表格 -->
    <el-card shadow="never">
      <div class="toolbar">
        <el-button v-permission="'business:product:drawing:add'" type="primary" size="small" icon="el-icon-upload2" @click="handleUpload">上传图纸</el-button>
        <el-button v-permission="'business:product:drawing:export'" size="small" icon="el-icon-download" :loading="exporting" @click="handleExport">导出</el-button>
        <el-button size="small" icon="el-icon-refresh" @click="getList">刷新</el-button>
        <span class="flex-1"></span>
        <span class="total-tip">共 {{ total }} 条</span>
      </div>

      <el-table :data="list" v-loading="loading" size="small" stripe border>
        <el-table-column type="index" label="序号" width="55" align="center" />
        <el-table-column prop="drawing_code" label="图纸编号" width="150" show-overflow-tooltip>
          <template slot-scope="s"><span class="link-text" @click="viewDetail(s.row.id)">{{ s.row.drawing_code }}</span></template>
        </el-table-column>
        <el-table-column prop="drawing_name" label="图纸名称" width="150" show-overflow-tooltip>
          <template slot-scope="s"><span class="link-text" @click="viewDetail(s.row.id)">{{ s.row.drawing_name }}</span></template>
        </el-table-column>
        <el-table-column prop="product_name" label="关联产品" width="130" show-overflow-tooltip>
          <template slot-scope="s"><span class="link-text" @click="viewProduct(s.row.product_id)">{{ s.row.product_name }}</span></template>
        </el-table-column>
        <el-table-column label="图纸类型" width="100" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="typeTag(s.row.drawing_type)" :class="{ 'tag-purple': s.row.drawing_type === 4 }">{{ s.row.drawing_type_label }}</el-tag></template>
        </el-table-column>
        <el-table-column label="文件大小" width="90" align="right">
          <template slot-scope="s">{{ formatSize(s.row.file_size) }}</template>
        </el-table-column>
        <el-table-column label="版本号" width="90" align="center">
          <template slot-scope="s">
            {{ s.row.version }}
            <el-tag v-if="s.row.is_newest === 1" size="mini" type="success" style="margin-left:2px">最新</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="category_name" label="图纸分类" width="100" show-overflow-tooltip />
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="s"><el-tag size="mini" :type="s.row.status === 1 ? 'success' : 'info'">{{ s.row.status === 1 ? '启用' : '停用' }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="uploader_name" label="上传人" width="100" show-overflow-tooltip />
        <el-table-column prop="uploaded_at" label="上传时间" width="160" align="center" />
        <el-table-column label="操作" width="220" align="center" fixed="right">
          <template slot-scope="s">
            <el-button type="text" size="mini" @click="handlePreview(s.row)">预览</el-button>
            <el-button v-permission="'business:product:drawing:download'" type="text" size="mini" @click="handleDownload(s.row.id)">下载</el-button>
            <el-button v-permission="'business:product:drawing:edit'" type="text" size="mini" @click="handleEdit(s.row.id)">编辑</el-button>
            <el-button v-permission="'business:product:drawing:delete'" type="text" size="mini" class="danger" @click="handleDelete(s.row.id)">删除</el-button>
            <el-dropdown trigger="click" @command="cmd => handleMore(cmd, s.row)">
              <el-button type="text" size="mini">更多<i class="el-icon-arrow-down el-icon--right"></i></el-button>
              <el-dropdown-menu slot="dropdown">
                <el-dropdown-item command="history">查看版本历史</el-dropdown-item>
                <el-dropdown-item v-permission="'business:product:drawing:add'" command="newversion">上传新版本</el-dropdown-item>
              </el-dropdown-menu>
            </el-dropdown>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination class="pager" background layout="total, sizes, prev, pager, next, jumper" :total="total" :page-sizes="[10, 20, 50, 100]" :page-size="queryParams.pageSize" :current-page="queryParams.page" @current-change="handlePageChange" @size-change="handleSizeChange" />
    </el-card>

    <!-- 版本历史弹窗 -->
    <el-dialog title="版本历史" :visible="historyVisible" width="720px" :close-on-click-modal="false" @close="historyVisible = false">
      <VersionHistory :versions="historyVersions" @download="downloadVersion" />
    </el-dialog>

    <!-- 上传新版本弹窗 -->
    <el-dialog title="上传新版本" :visible="versionVisible" width="560px" :close-on-click-modal="false" @close="closeVersionDialog">
      <el-form label-width="90px" size="small">
        <el-form-item label="当前版本">{{ currentRow.version }}</el-form-item>
        <el-form-item label="新版本号">
          <el-input v-model="newVersion" placeholder="留空自动升级（如 V1.0→V1.1）" clearable />
        </el-form-item>
        <el-form-item label="变更说明">
          <el-input v-model="changeDesc" type="textarea" :rows="2" placeholder="本次版本变更说明（可选）" />
        </el-form-item>
        <el-form-item label="新文件" required>
          <FileUploader ref="versionUploader" :file-type="currentRow.drawing_type" @file="v => (versionFile = v)" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="closeVersionDialog">取消</el-button>
        <el-button size="small" type="primary" :loading="versionUploading" @click="confirmUploadVersion">上传</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import VersionHistory from './components/VersionHistory.vue'
import FileUploader from './components/FileUploader.vue'
import {
  getDrawingList, getDrawingDetail, deleteDrawing, downloadDrawing, downloadDrawingVersion,
  uploadDrawingVersion, exportDrawings, getDrawingCategoryTree
} from '../../../../api/product'

export default {
  name: 'BusinessProductDrawingList',
  components: { VersionHistory, FileUploader },
  data() {
    return {
      loading: false,
      exporting: false,
      list: [],
      total: 0,
      categoryOptions: [],
      categoryId: [],
      timeRange: [],
      queryParams: { page: 1, pageSize: 10, drawing_name: '', drawing_code: '', product_name: '', drawing_type: '', status: '', start_time: '', end_time: '' },
      historyVisible: false,
      historyVersions: [],
      versionVisible: false,
      currentRow: {},
      newVersion: '',
      changeDesc: '',
      versionFile: null,
      versionUploading: false
    }
  },
  created() {
    this.loadCategoryTree()
    // 从产品列表"查看图纸"进入：自动按产品名称筛选
    if (this.$route.query && this.$route.query.product_name) {
      this.queryParams.product_name = this.$route.query.product_name
    }
    this.getList()
  },
  methods: {
    typeTag(t) { return { 1: 'primary', 2: 'warning', 3: 'success', 4: 'primary', 5: 'info' }[t] || 'info' },
    formatSize(bytes) {
      if (bytes === null || bytes === undefined) return '-'
      const b = Number(bytes)
      if (b < 1024 * 1024) return (b / 1024).toFixed(1) + 'KB'
      return (b / (1024 * 1024)).toFixed(1) + 'MB'
    },
    async loadCategoryTree() {
      try {
        const r = await getDrawingCategoryTree()
        this.categoryOptions = (r && r.code === 0 && r.data) ? r.data : []
      } catch (e) { this.categoryOptions = [] }
    },
    buildParams() {
      const p = { ...this.queryParams }
      p.category_id = this.categoryId.length ? this.categoryId[this.categoryId.length - 1] : ''
      if (this.timeRange && this.timeRange.length === 2) { p.start_time = this.timeRange[0]; p.end_time = this.timeRange[1] } else { p.start_time = ''; p.end_time = '' }
      return p
    },
    async getList() {
      this.loading = true
      try {
        const r = await getDrawingList(this.buildParams())
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    handleSearch() { this.queryParams.page = 1; this.getList() },
    handleReset() {
      this.queryParams = { page: 1, pageSize: this.queryParams.pageSize, drawing_name: '', drawing_code: '', product_name: '', drawing_type: '', status: '', start_time: '', end_time: '' }
      this.categoryId = []
      this.timeRange = []
      this.handleSearch()
    },
    handlePageChange(p) { this.queryParams.page = p; this.getList() },
    handleSizeChange(size) { this.queryParams.pageSize = size; this.queryParams.page = 1; this.getList() },
    handleUpload() { this.$router.push('/business/product/drawing/upload') },
    viewDetail(id) { this.$router.push(`/business/product/drawing/detail/${id}`) },
    handleEdit(id) { this.$router.push(`/business/product/drawing/edit/${id}`) },
    viewProduct(id) { if (id) this.$router.push(`/business/product/detail/${id}`) },
    handlePreview(row) {
      if (row.drawing_type === 2 || row.drawing_type === 3) {
        window.open(row.file_path, '_blank')
      } else {
        this.$message.info('该格式不支持在线预览，请下载后使用对应软件打开')
      }
    },
    async handleDownload(id) {
      try {
        const res = await downloadDrawing(id)
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('下载失败'); return }
        this.triggerDownload(blob, (this.list.find(x => x.id === id) || {}).file_name || 'drawing')
      } catch (e) {}
    },
    async downloadVersion(version) {
      try {
        const res = await downloadDrawingVersion(version.id)
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('下载失败'); return }
        this.triggerDownload(blob, version.file_name || ('drawing_' + version.version))
      } catch (e) {}
    },
    triggerDownload(blob, filename) {
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = filename
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)
      URL.revokeObjectURL(url)
    },
    handleDelete(id) {
      this.$confirm('确认删除该图纸吗？删除后不可恢复', '删除确认', { type: 'warning' }).then(async () => {
        try {
          const r = await deleteDrawing(id)
          if (r.code === 0) {
            this.$message.success('删除成功')
            await this.getList()
            if (!this.list.length && this.queryParams.page > 1) { this.queryParams.page -= 1; await this.getList() }
          }
        } catch (e) {}
      }).catch(() => {})
    },
    async handleMore(cmd, row) {
      if (cmd === 'history') {
        try {
          const r = await getDrawingDetail(row.id)
          this.historyVersions = (r.code === 0 && r.data && r.data.versions) ? r.data.versions : []
          this.historyVisible = true
        } catch (e) {}
      } else if (cmd === 'newversion') {
        this.currentRow = row
        this.newVersion = ''
        this.changeDesc = ''
        this.versionFile = null
        this.versionVisible = true
      }
    },
    closeVersionDialog() { this.versionVisible = false; this.versionFile = null },
    async confirmUploadVersion() {
      if (!this.versionFile) { this.$message.warning('请选择新版本文件'); return }
      this.versionUploading = true
      try {
        const fd = new FormData()
        fd.append('drawing_id', this.currentRow.id)
        if (this.newVersion) fd.append('version', this.newVersion)
        if (this.changeDesc) fd.append('change_description', this.changeDesc)
        fd.append('file', this.versionFile)
        const r = await uploadDrawingVersion(fd)
        if (r.code === 0) { this.$message.success(r.msg || '新版本上传成功'); this.closeVersionDialog(); this.getList() }
      } catch (e) {}
      this.versionUploading = false
    },
    async handleExport() {
      this.exporting = true
      try {
        const res = await exportDrawings(this.buildParams())
        const blob = res.data
        if (!(blob instanceof Blob)) { this.$message.error('导出失败'); return }
        const filename = this.resolveName(res.headers) || '图纸列表_' + this.stamp() + '.xlsx'
        this.triggerDownload(blob, filename)
      } catch (e) {}
      this.exporting = false
    },
    resolveName(headers) {
      if (!headers) return null
      const d = headers['content-disposition'] || ''
      const star = d.match(/filename\*=(?:UTF-8'')?([^;]+)/i)
      if (star) return decodeURIComponent(star[1].replace(/^"|"$/g, ''))
      const plain = d.match(/filename="?([^";]+)"?/i)
      return plain ? plain[1] : null
    },
    stamp() {
      const n = new Date()
      const pad = x => String(x).padStart(2, '0')
      return `${n.getFullYear()}${pad(n.getMonth() + 1)}${pad(n.getDate())}_${pad(n.getHours())}${pad(n.getMinutes())}${pad(n.getSeconds())}`
    }
  }
}
</script>

<style scoped>
.drawing-page { padding: 4px 16px; }
.breadcrumb { margin-bottom: 14px; }
.filter-card { margin-bottom: 14px; }
.filter-btns { display: flex; align-items: center; margin-left: 8px; }
.filter-btns .el-button + .el-button { margin-left: 10px; }
.toolbar { display: flex; align-items: center; margin-bottom: 12px; }
.flex-1 { flex: 1; }
.total-tip { font-size: 14px; color: #909399; }
.link-text { color: #409eff; cursor: pointer; }
.pager { margin: 20px 0; text-align: right; }
.danger { color: #f56c6c; }
::v-deep .tag-purple { background-color: #f3e5f5; border-color: #ce93d8; color: #8e24aa; }
</style>
