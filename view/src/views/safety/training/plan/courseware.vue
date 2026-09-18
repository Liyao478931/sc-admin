<template>
  <div class="training-courseware-page">
    <!-- 筛选 + 工具栏 -->
    <el-card shadow="never" style="margin-bottom:16px;">
      <el-form :inline="true" size="small">
        <el-form-item><el-input v-model="filters.keyword" placeholder="按课件名称搜索" clearable style="width:180px" @keyup.enter.native="onSearch" /></el-form-item>
        <el-form-item>
          <el-select v-model="filters.file_type" clearable placeholder="全部类型" style="width:120px" @change="onSearch">
            <el-option v-for="f in fileTypeOptions" :key="f.value" :label="f.label" :value="f.value" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" icon="el-icon-search" @click="onSearch">搜索</el-button>
          <el-button icon="el-icon-refresh-left" @click="resetFilters">重置</el-button>
        </el-form-item>
        <el-form-item style="float:right">
          <el-button v-if="hasPerm('safety:training:plan:add')" size="small" type="primary" icon="el-icon-upload2" @click="uploadVisible = true">上传课件</el-button>
          <el-button size="small" icon="el-icon-refresh" @click="loadList">刷新</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 表格 -->
    <el-card shadow="never">
      <el-table :data="list" v-loading="loading" border stripe size="small">
        <el-table-column type="index" label="序号" width="60" />
        <el-table-column prop="courseware_code" label="课件编号" width="180" />
        <el-table-column prop="courseware_name" label="课件名称" min-width="180" show-overflow-tooltip />
        <el-table-column label="文件类型" width="90" align="center">
          <template slot-scope="{ row }">
            <el-tag size="mini" :type="fileTagType(row.file_type)">{{ row.file_type_text }}</el-tag>
          
</template>
        </el-table-column>
        <el-table-column label="文件大小" width="100" align="center">
          <template slot-scope="{ row }">{{ fmtSize(row.file_size) }}</template>
        </el-table-column>
        <el-table-column prop="uploader_name" label="上传人" width="100" />
        <el-table-column prop="create_time" label="上传时间" width="160" />
        <el-table-column label="操作" width="200" align="center">
          <template slot-scope="{ row }">
            <el-button v-if="canPreview(row) && hasPerm('safety:training:plan:query')" size="mini" type="text" @click="openPreview(row)">预览</el-button>
            <el-button v-if="hasPerm('safety:training:plan:query')" size="mini" type="text" @click="handleDownload(row)">下载</el-button>
            <el-button v-if="hasPerm('safety:training:plan:delete')" size="mini" type="text" style="color:#F56C6C" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination style="margin-top:12px;text-align:right" background layout="total, sizes, prev, pager, next"
        :total="total" :current-page.sync="page" :page-size.sync="limit"
        :page-sizes="[10, 20, 50]" @current-change="loadList" @size-change="loadList" />
    </el-card>

    <!-- 上传弹窗 -->
    <el-dialog title="上传课件" :visible.sync="uploadVisible" width="500px" append-to-body>
      <el-form :model="form" :rules="rules" ref="formRef" label-width="100px" size="small">
        <el-form-item label="课件名称" prop="courseware_name"><el-input v-model="form.courseware_name" /></el-form-item>
        <el-form-item label="文件" prop="file">
          <el-upload drag action="#" :auto-upload="false" :limit="1" :on-change="onFileChange" :file-list="fileList" :before-upload="beforeUpload" accept=".pdf,.ppt,.pptx,.doc,.docx,.mp4,.avi,.mov">
            <i class="el-icon-upload"></i>
            <div class="el-upload__text">将文件拖到此处，或<em>点击选择文件</em></div>
            <div class="el-upload__tip" slot="tip">支持 pdf/ppt/word/视频，最大 50MB</div>
          </el-upload>
          <div style="margin-top:6px">
            <el-button size="mini" type="primary" plain icon="el-icon-folder-opened" @click="driveVisible = true">从企业网盘选择</el-button>
          </div>
          <drive-file-picker :visible="driveVisible" mode="file" :multiple="false" @update:visible="driveVisible = $event" @confirm="onDrivePick" />
        </el-form-item>
        <el-form-item label="描述说明"><el-input v-model="form.description" type="textarea" :rows="3" /></el-form-item>
      </el-form>
      <div slot="footer">
        <el-button size="small" @click="uploadVisible = false">取消</el-button>
        <el-button size="small" type="primary" :loading="uploading" @click="handleUpload">上传</el-button>
      </div>
    </el-dialog>

    <!-- 预览弹窗 -->
    <el-dialog title="课件预览" :visible.sync="previewVisible" width="800px" top="5vh" append-to-body>
      <iframe v-if="previewType === 'pdf'" :src="previewUrl" style="width:100%;height:70vh;border:none"></iframe>
      <img v-else-if="previewType === 'image'" :src="previewUrl" style="max-width:100%;display:block;margin:0 auto" />
      <el-empty v-else description="该格式不支持在线预览，请下载查看" />
    </el-dialog>
  </div>
</template>

<script>
import { getCoursewareList, uploadCourseware, previewCourseware, deleteCourseware } from '@/api/safetyTraining'
import request from '@/api/request'
import { getToken } from '@/utils/auth'

export default {
  name: 'SafetyTrainingCourseware',
  data() {
    return {
      driveVisible: false,
      loading: false, list: [], total: 0, page: 1, limit: 10,
      filters: { keyword: '', file_type: '' },
      fileTypeOptions: [
        { value: 'pdf', label: 'PDF' }, { value: 'ppt', label: 'PPT' }, { value: 'word', label: 'Word' },
        { value: 'video', label: '视频' }, { value: 'other', label: '其他' }
      ],
      uploadVisible: false, uploading: false,
      form: { courseware_name: '', description: '' },
      rules: {
        courseware_name: [{ required: true, message: '请输入课件名称', trigger: 'blur' }]
      },
      fileList: [], selectedFile: null,
      previewVisible: false, previewUrl: '', previewType: ''
    }
  },
  computed: {
    uploadHeaders() { return { Authorization: 'Bearer ' + getToken() } }
  },
  created() {
    // 权限为空时刷新（避免新加权限未及时拉取导致按钮不显示）
    if (this.$store.state.user && this.$store.state.user.permissions && !this.$store.state.user.permissions.length) {
      this.$store.dispatch('user/loadPermissions')
    }
    this.loadList()
  },
  methods: {
    hasPerm(code) {
      const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []
      return p.indexOf(code) > -1
    },
    async loadList() {
      this.loading = true
      try {
        const r = await getCoursewareList({
          page: this.page, limit: this.limit,
          keyword: this.filters.keyword || '',
          file_type: this.filters.file_type || ''
        })
        if (r.code === 0) { this.list = r.data.list || []; this.total = r.data.total || 0 }
      } catch (e) {}
      this.loading = false
    },
    onSearch() { this.page = 1; this.loadList() },
    resetFilters() { this.filters = { keyword: '', file_type: '' }; this.page = 1; this.loadList() },
    fileTagType(v) {
      return { pdf: 'danger', ppt: 'warning', word: 'primary', video: 'success', other: 'info' }[v] || 'info'
    },
    fmtSize(kb) {
      if (!kb) return '-'
      return kb >= 1024 ? (kb / 1024).toFixed(1) + ' MB' : kb + ' KB'
    },
    canPreview(row) {
      const ext = (row.file_path || '').split('.').pop().toLowerCase()
      return row.file_type === 'pdf' || ['jpg', 'jpeg', 'png', 'gif', 'webp'].indexOf(ext) > -1
    },
    onDrivePick(list) {
      const f = list[0]
      if (!f) return
      fetch(f.url).then(res => res.blob()).then(blob => {
        const raw = new File([blob], f.name, { type: blob.type || 'application/octet-stream' })
        if (raw.size > 50 * 1024 * 1024) { this.$message.error('文件不能超过 50MB'); return }
        this.onFileChange({ raw, name: f.name, size: raw.size, status: 'ready' })
      }).catch(() => this.$message.error('读取网盘文件失败'))
    },
    onFileChange(file) { this.selectedFile = file.raw; this.form.file = file.raw; this.fileList = [file] },
    beforeUpload(file) {
      const ok = /\.(pdf|ppt|pptx|doc|docx|mp4|avi|mov)$/i.test(file.name)
      const okSize = file.size <= 50 * 1024 * 1024
      if (!ok) this.$message.error('不支持的文件类型')
      if (!okSize) this.$message.error('文件不能超过 50MB')
      return ok && okSize
    },
    async handleUpload() {
      if (!this.selectedFile) { this.$message.error('请选择文件'); return }
      this.$refs.formRef.validate(async (valid) => {
        if (!valid) return
        this.uploading = true
        try {
          const fd = new FormData()
          fd.append('file', this.selectedFile)
          fd.append('courseware_name', this.form.courseware_name)
          fd.append('description', this.form.description || '')
          const token = getToken()
          const res = await fetch('/api/safety/training/courseware/upload', {
            method: 'POST',
            headers: { 'Authorization': 'Bearer ' + token },
            body: fd
          }).then(r => r.json())
          if (res.code === 0) { this.$message.success('上传成功'); this.uploadVisible = false; this.fileList = []; this.form = { courseware_name: '', description: '' }; this.loadList() }
          else this.$message.error(res.msg || '上传失败')
        } catch (e) { this.$message.error('上传失败') }
        this.uploading = false
      })
    },
    async openPreview(row) {
      try {
        const r = await previewCourseware(row.id)
        if (r.code === 0) {
          this.previewUrl = r.data.file_path
          this.previewType = r.data.file_type === 'pdf' ? 'pdf' : 'image'
          this.previewVisible = true
        } else { this.$message.error(r.msg || '预览失败') }
      } catch (e) {}
    },
    async handleDownload(row) {
      // blob 下载：token 走 Authorization header，避免明文 token 进入 URL/日志
      try {
        const resp = await request({ url: '/safety/training/courseware/download/' + row.id, method: 'get', responseType: 'blob' })
        const blob = new Blob([resp.data])
        const url = URL.createObjectURL(blob)
        const a = document.createElement('a')
        a.href = url
        a.download = (row.courseware_name || 'courseware') + '.' + (row.file_type || 'file')
        a.click()
        URL.revokeObjectURL(url)
      } catch (e) { this.$message.error('下载失败') }
    },
    handleDelete(row) {
      this.$confirm(`确认删除课件「${row.courseware_name}」？`, '删除确认', { type: 'warning' }).then(async () => {
        try { const r = await deleteCourseware(row.id); if (r.code === 0) { this.$message.success('删除成功'); this.loadList() } } catch (e) {}
      }).catch(() => {})
    }
  }
}
</script>

<style scoped>
</style>
