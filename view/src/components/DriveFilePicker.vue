<!--
  文件：admin/src/components/DriveFilePicker.vue
  功能：企业网盘文件选择器（全局组件）。上传图片/文件时可先从网盘选择，网盘没有可现场上传。
  props：visible（弹窗开关）、mode（image-选图片 / file-选文件）、multiple（是否多选）
  events：update:visible、confirm(list)  list: [{ id, name, url, type }]
-->
<template>
  <el-dialog
    :title="title"
    :visible.sync="dialogVisible"
    width="820px"
    top="6vh"
    :close-on-click-modal="false"
    append-to-body
    :z-index="4000"
    @open="onOpen"
  >
    <el-tabs v-model="activeTab">
      <!-- 从网盘选择 -->
      <el-tab-pane label="从企业网盘选择" name="drive">
        <div class="dp-toolbar">
          <el-breadcrumb separator="/">
            <el-breadcrumb-item v-for="(c, i) in crumb" :key="c.id" @click.native="enterCrumb(i)">{{ c.name }}</el-breadcrumb-item>
          </el-breadcrumb>
          <div class="dp-toolbar-right">
            <el-input v-model="keyword" placeholder="搜索文件名" size="small" clearable style="width:160px" @keyup.enter.native="loadList" />
            <el-button size="small" type="primary" plain @click="loadList">查询</el-button>
          </div>
        </div>
        <div class="dp-grid">
          <template v-if="mode === 'image'">
            <div v-for="f in files" :key="f.id" class="dp-item dp-img" :class="{selected: isSelected(f)}" @click="togglePick(f)">
              <div v-if="f.file_type === 'folder'" class="dp-folder" @click.stop="enterFolder(f)">
                <i class="el-icon-folder"></i>
                <span>{{ f.file_name }}</span>
              </div>
              <template v-else>
                <img :src="fileUrl(f)" :alt="f.file_name" />
                <span class="dp-name">{{ f.file_name }}</span>
                <span class="dp-check"><i class="el-icon-check"></i></span>
              </template>
            </div>
          </template>
          <template v-else>
            <el-table :data="files" size="small" highlight-current-row @row-click="onRowClick" empty-text="暂无文件，可切换“本地上传”">
              <el-table-column width="46" align="center">
                <template slot-scope="scope">
                  <i :class="scope.row.file_type === 'folder' ? 'el-icon-folder' : iconOf(scope.row.file_name)"></i>
                </template>
              </el-table-column>
              <el-table-column prop="file_name" label="名称" min-width="200" show-overflow-tooltip />
              <el-table-column label="大小" width="110">
                <template slot-scope="scope">{{ scope.row.file_type === 'folder' ? '-' : formatSize(scope.row.file_size) }}</template>
              </el-table-column>
              <el-table-column label="" width="40" align="center">
                <template slot-scope="scope">
                  <i v-if="isSelected(scope.row)" class="el-icon-check" style="color:#409EFF;font-weight:700"></i>
                </template>
              </el-table-column>
            </el-table>
          </template>
        </div>
      </el-tab-pane>

      <!-- 本地上传 -->
      <el-tab-pane label="本地上传" name="local">
        <el-upload
          drag
          multiple
          :action="uploadAction"
          :headers="uploadHeaders"
          :data="uploadData"
          :show-file-list="false"
          :on-success="onUploadSuccess"
          :on-error="onUploadError"
          :before-upload="beforeUpload"
          accept="*"
        >
          <i class="el-icon-upload"></i>
          <div class="el-upload__text">将文件拖到此处，或<em>点击上传</em></div>
          <div class="el-upload__tip" slot="tip">
            上传后自动存入当前所在文件夹（单个文件不超过 50MB）。已选 {{ picked.length }} 个文件
          </div>
        </el-upload>
        <div v-if="localPicked.length" class="dp-local-list">
          <div v-for="(f, i) in localPicked" :key="i" class="dp-local-item">
            <i class="el-icon-document"></i>
            <span>{{ f.name }}</span>
            <el-button type="text" size="mini" @click="localPicked.splice(i, 1)">移除</el-button>
          </div>
        </div>
      </el-tab-pane>
    </el-tabs>

    <div slot="footer">
      <el-button size="small" @click="dialogVisible = false">取消</el-button>
      <el-button size="small" type="primary" :disabled="!picked.length" @click="confirmPick">确定（已选 {{ picked.length }} 项）</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getToken } from '../utils/auth'
const request = (options) => {
  const base = '/api'
  const token = getToken()
  const headers = Object.assign({}, options.headers || {})
  if (token) headers.Authorization = 'Bearer ' + token
  const body = options.data
  const opts = { method: options.method || 'GET', headers }
  if (body !== undefined) {
    if (body instanceof FormData) {
      opts.body = body
    } else if (options.form) {
      opts.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      opts.body = Object.keys(body).map(k => encodeURIComponent(k) + '=' + encodeURIComponent(body[k])).join('&')
    } else {
      opts.headers['Content-Type'] = 'application/json'
      opts.body = JSON.stringify(body)
    }
  }
  return fetch(base + options.url, opts).then(r => r.json()).then(j => ({ code: j.code, data: j.data, msg: j.msg }))
}

export default {
  name: 'DriveFilePicker',
  props: {
    visible: { type: Boolean, default: false },
    mode: { type: String, default: 'file' }, // image | file
    multiple: { type: Boolean, default: true }
  },
  data() {
    return {
      activeTab: 'drive',
      keyword: '',
      files: [],
      crumb: [{ id: 0, name: '全部文件' }],
      picked: [],
      localPicked: [],
      loading: false
    }
  },
  computed: {
    dialogVisible: {
      get() { return this.visible },
      set(v) { this.$emit('update:visible', v) }
    },
    title() {
      return (this.mode === 'image' ? '选择图片' : '选择文件') + '（企业网盘）'
    },
    uploadAction() { return '/api/drive/upload' },
    /** 上传到当前所在文件夹（crumb 最后一项 id，根目录为 0） */
    uploadData() {
      const cur = this.crumb[this.crumb.length - 1]
      return { parent_id: cur ? cur.id : 0 }
    },
    uploadHeaders() { return { Authorization: 'Bearer ' + getToken() } }
  },
  methods: {
    /** 表格行点击：文件夹进入，文件选中 */
    onRowClick(row) {
      if (row.file_type === 'folder') this.enterFolder(row)
      else this.togglePick(row)
    },
    onOpen() {
      this.activeTab = 'drive'
      this.keyword = ''
      this.picked = []
      this.localPicked = []
      this.crumb = [{ id: 0, name: '全部文件' }]
      this.loadList()
    },
    async loadList() {
      this.loading = true
      const parentId = this.crumb[this.crumb.length - 1].id
      try {
        const params = new URLSearchParams({ parent_id: String(parentId) })
        if (this.keyword) params.append('keyword', this.keyword)
        const res = await fetch('/api/drive/list?' + params.toString(), { headers: { Authorization: 'Bearer ' + getToken() } }).then(r => r.json())
        let rows = (res.data || []).filter(f => !f.is_deleted)
        if (this.mode === 'image') {
          rows = rows.filter(f => f.file_type === 'folder' || String(f.mime || '').startsWith('image/') || /\.(jpg|jpeg|png|gif|webp|bmp)$/i.test(f.file_name || ''))
        }
        this.files = rows
      } catch (e) {
        this.$message.error('加载网盘文件失败')
      } finally {
        this.loading = false
      }
    },
    enterFolder(f) {
      this.crumb.push({ id: f.id, name: f.file_name })
      this.loadList()
    },
    enterCrumb(i) {
      this.crumb = this.crumb.slice(0, i + 1)
      this.loadList()
    },
    fileUrl(f) { return location.origin + f.file_path },
    isSelected(f) {
      return this.picked.some(p => p.id === f.id)
    },
    togglePick(f) {
      if (f.file_type === 'folder') return
      if (this.multiple) {
        const idx = this.picked.findIndex(p => p.id === f.id)
        if (idx > -1) this.picked.splice(idx, 1)
        else this.picked.push({ id: f.id, name: f.file_name, url: this.fileUrl(f), path: f.file_path, type: 'drive' })
      } else {
        this.picked = [{ id: f.id, name: f.file_name, url: this.fileUrl(f), path: f.file_path, type: 'drive' }]
      }
    },
    iconOf(name) {
      const ext = String(name || '').split('.').pop().toLowerCase()
      if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].includes(ext)) return 'el-icon-picture-outline'
      if (['pdf'].includes(ext)) return 'el-icon-document'
      if (['doc', 'docx'].includes(ext)) return 'el-icon-document'
      if (['xls', 'xlsx', 'csv'].includes(ext)) return 'el-icon-document'
      if (['zip', 'rar', '7z'].includes(ext)) return 'el-icon-box'
      return 'el-icon-document'
    },
    formatSize(bytes) {
      const b = Number(bytes || 0)
      if (b < 1024 * 1024) return (b / 1024).toFixed(1) + 'KB'
      return (b / (1024 * 1024)).toFixed(1) + 'MB'
    },
    beforeUpload(file) {
      if (file.size > 50 * 1024 * 1024) {
        this.$message.error('单个文件不能超过 50MB')
        return false
      }
      return true
    },
    onUploadSuccess(res) {
      if (res.code === 0 && res.data && res.data.path) {
        const path = res.data.path
        const name = res.data.name || path.split('/').pop()
        this.localPicked.push({ id: Date.now(), name, url: location.origin + path, path, type: 'drive' })
        this.$message.success('上传成功，已加入选择列表')
        // 刷新网盘列表
        if (this.activeTab === 'drive') this.loadList()
      } else {
        this.$message.error((res && res.msg) || '上传失败')
      }
    },
    onUploadError() {
      this.$message.error('上传失败，请重试')
    },
    confirmPick() {
      const list = this.picked.concat(this.localPicked.map(f => ({ id: f.id, name: f.name, url: f.url, path: f.path, type: 'drive' })))
      if (!list.length) {
        this.$message.warning('请先选择或上传文件')
        return
      }
      this.$emit('confirm', list)
      this.dialogVisible = false
    }
  }
}
</script>

<style scoped>
.dp-toolbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px; }
.dp-grid { min-height: 320px; max-height: 420px; overflow: auto; }
.dp-grid :deep(.el-table) { width: 100%; }
.dp-item { position: relative; display: inline-block; width: 104px; height: 118px; margin: 4px 6px 4px 0; border: 1px solid #e4e7ed; border-radius: 6px; overflow: hidden; cursor: pointer; vertical-align: top; background: #fafafa; text-align: center; }
.dp-item.selected { border-color: #409EFF; box-shadow: 0 0 0 1px #409EFF; }
.dp-item img { width: 100%; height: 78px; object-fit: cover; display: block; }
.dp-name { display: block; font-size: 12px; color: #606266; padding: 2px 4px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.dp-check { position: absolute; top: 2px; right: 2px; width: 18px; height: 18px; border-radius: 50%; background: #409EFF; color: #fff; display: none; align-items: center; justify-content: center; font-size: 12px; }
.dp-item.selected .dp-check { display: flex; }
.dp-folder { height: 100%; display: flex; flex-direction: column; align-items: center; justify-content: center; }
.dp-folder i { font-size: 40px; color: #e6a23c; }
.dp-folder span { font-size: 12px; color: #606266; padding: 4px; max-width: 96px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.dp-local-list { margin-top: 12px; }
.dp-local-item { display: flex; align-items: center; padding: 6px 10px; background: #f5f7fa; border-radius: 4px; margin-bottom: 6px; }
.dp-local-item span { flex: 1; font-size: 13px; margin-left: 6px; }
</style>
