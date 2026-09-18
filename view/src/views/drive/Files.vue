<template>
  <div class="page-container">
    <el-card shadow="never" class="drive-card">
      <div class="drive-head">
        <div class="drive-title">
          <el-breadcrumb separator="/">
            <el-breadcrumb-item><a @click.prevent="goRoot">企业网盘</a></el-breadcrumb-item>
            <el-breadcrumb-item v-for="f in breadcrumb" :key="f.id"><a @click.prevent="cd(f.id)">{{ f.file_name }}</a></el-breadcrumb-item>
          </el-breadcrumb>
        </div>
        <div class="drive-filter">
          <el-input v-model="filterKeyword" size="small" prefix-icon="el-icon-search" placeholder="搜索名称" clearable style="width:180px" />
          <el-select v-model="filterType" size="small" style="width:110px;margin-left:8px">
            <el-option label="全部类型" value="" />
            <el-option label="文件夹" value="folder" />
            <el-option label="文件" value="file" />
          </el-select>
          <el-select v-model="filterUploader" size="small" style="width:130px;margin-left:8px" clearable placeholder="上传人">
            <el-option v-for="u in uploaderOptions" :key="u" :label="u" :value="u" />
          </el-select>
        </div>
        <div class="drive-actions">
          <el-button v-permission="'drive:file:add'" type="primary" size="small" icon="el-icon-folder-add" @click="openMkdir">新建文件夹</el-button>
          <el-upload :action="uploadUrl" :headers="uploadHeaders" :data="{ parent_id: currentId }" :show-file-list="false" :on-success="onUpload" accept="*">
            <el-button v-permission="'drive:file:add'" type="success" size="small" icon="el-icon-upload2">上传文件</el-button>
          </el-upload>
        </div>
      </div>
      <el-table :data="filteredList" v-loading="loading" border stripe size="small">
        <el-table-column label="名称" min-width="260">
          <template #default="{row}">
            <span class="file-name" @click="row.file_type === 'folder' ? cd(row.id) : preview(row)">
              <i :class="row.file_type === 'folder' ? (row.locked ? 'el-icon-lock' : 'el-icon-folder') : 'el-icon-document'" :style="{ color: row.file_type === 'folder' ? '#E6A23C' : '#409EFF', marginRight: '6px' }"></i>{{ row.file_name }}
            </span>
          </template>
        </el-table-column>
        <el-table-column prop="file_type" label="类型" width="90"><template #default="{row}">{{ row.file_type === 'folder' ? '文件夹' : '文件' }}</template></el-table-column>
        <el-table-column label="大小" width="110"><template #default="{row}">{{ fmtSize(row.file_size) }}</template></el-table-column>
        <el-table-column prop="uploader" label="上传人" width="110" />
        <el-table-column prop="created_at" label="时间" width="155" />
        <el-table-column label="操作" width="150" fixed="right">
          <template #default="{row}">
            <el-button v-if="row.file_type === 'file'" type="text" size="small" @click="preview(row)">下载</el-button>
            <el-button v-if="row.file_type === 'folder' && row.locked" type="text" size="small" @click="forgot(row)">忘记密码</el-button>
            <el-button v-permission="'drive:file:delete'" type="text" size="small" class="danger" @click="del(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog title="新建文件夹" :visible.sync="mkdirVisible" width="440px">
      <el-form size="small" label-width="90px">
        <el-form-item label="文件夹名称"><el-input v-model="mkdirName" placeholder="请输入名称" @keyup.enter.native="doMkdir" /></el-form-item>
        <el-form-item label="设置密码">
          <el-switch v-model="mkdirPasswordOn" />
          <div v-if="mkdirPasswordOn" style="margin-top:8px">
            <el-input v-model="mkdirPassword" type="password" show-password placeholder="4-32位密码" />
          </div>
        </el-form-item>
        <el-form-item label="查看权限">
          <el-radio-group v-model="mkdirScope" size="small">
            <el-radio-button label="all">所有人</el-radio-button>
            <el-radio-button label="dept">指定部门</el-radio-button>
            <el-radio-button label="users">指定员工</el-radio-button>
            <el-radio-button label="owner">仅创建者</el-radio-button>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="mkdirScope === 'dept'" label="可见部门">
          <el-select v-model="mkdirDeptIds" multiple filterable size="small" style="width:100%" placeholder="选择可查看的部门（含子部门）">
            <el-option v-for="d in deptOptions" :key="d.id" :label="d.label" :value="d.id" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="mkdirScope === 'users'" label="可见员工">
          <el-select v-model="mkdirUserIds" multiple filterable size="small" style="width:100%" placeholder="选择可查看的员工">
            <el-option v-for="u in userOptions" :key="u.value" :label="u.label" :value="u.value" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button size="small" @click="mkdirVisible = false">取消</el-button>
        <el-button size="small" type="primary" @click="doMkdir">创建</el-button>
      </template>
    </el-dialog>

    <el-dialog title="请输入访问密码" :visible.sync="passwordVisible" width="400px" :close-on-click-modal="false">
      <el-form size="small" label-width="90px">
        <el-form-item label="文件夹"><b>{{ pendingName }}</b></el-form-item>
        <el-form-item label="访问密码"><el-input v-model="password" type="password" show-password placeholder="请输入密码" @keyup.enter.native="doVerify" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button size="small" @click="passwordVisible = false">取消</el-button>
        <el-button size="small" type="primary" @click="doVerify">进入</el-button>
        <el-button size="small" type="text" style="float:left" @click="forgot(pendingRow)">忘记密码？</el-button>
      </template>
    </el-dialog>

    <el-dialog title="找回文件夹密码" :visible.sync="resetVisible" width="440px" :close-on-click-modal="false">
      <el-form size="small" label-width="100px">
        <el-form-item label="文件夹"><b>{{ pendingName }}</b></el-form-item>
        <el-form-item label="发送验证码">
          <el-button size="small" type="primary" plain @click="sendReset" :disabled="resetSending">{{ resetSending ? '发送中...' : '发送到上传人手机' }}</el-button>
          <span v-if="resetPhoneMask" style="margin-left:8px;color:#67C23A">{{ resetPhoneMask }}</span>
        </el-form-item>
        <el-form-item label="短信验证码"><el-input v-model="resetCode" placeholder="6位验证码" maxlength="6" /></el-form-item>
        <el-form-item label="新密码"><el-input v-model="resetNewPassword" type="password" show-password placeholder="4-32位新密码" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button size="small" @click="resetVisible = false">取消</el-button>
        <el-button size="small" type="primary" @click="doReset">重置密码</el-button>
      </template>
    </el-dialog>
  </div>
</template>
<script>
import request from '@/api/request'
import { getToken } from '@/utils/auth'
export default {
  name: 'DriveFiles',
  data() {
    return {
      loading: false, list: [], currentId: 0, breadcrumb: [], mkdirVisible: false, mkdirName: '',
      mkdirPasswordOn: false, mkdirPassword: '',
      mkdirScope: 'all', mkdirDeptIds: [], mkdirUserIds: [],
      deptOptions: [], userOptions: [],
      filterKeyword: '', filterType: '', filterUploader: '',
      passwordVisible: false, password: '', pendingId: 0, pendingName: '', pendingRow: null,
      unlockTickets: {},
      resetVisible: false, resetCode: '', resetNewPassword: '', resetSending: false, resetPhoneMask: '',
      uploadUrl: '/api/drive/upload'
    }
  },
  computed: {
    uploadHeaders() { return { Authorization: 'Bearer ' + (getToken() || '') } },
    uploaderOptions() {
      const set = new Set(this.list.map(x => x.uploader).filter(Boolean))
      return Array.from(set)
    },
    filteredList() {
      let arr = this.list
      if (this.filterKeyword) arr = arr.filter(x => (x.file_name || '').toLowerCase().includes(this.filterKeyword.toLowerCase()))
      if (this.filterType) arr = arr.filter(x => x.file_type === this.filterType)
      if (this.filterUploader) arr = arr.filter(x => x.uploader === this.filterUploader)
      return arr
    }
  },
  created() { this.load(); this.loadOptions() },
  methods: {
    async loadOptions() {
      try {
        const users = await request({ url: '/users/options', method: 'get' })
        if (users.code === 0) this.userOptions = users.data || []
        const depts = await request({ url: '/departments/tree', method: 'get' })
        if (depts.code === 0) {
          const flat = []
          const walk = (nodes, prefix) => {
            (nodes || []).forEach(n => {
              flat.push({ id: n.id, label: (prefix ? prefix + ' / ' : '') + n.name })
              if (n.children && n.children.length) walk(n.children, (prefix ? prefix + ' / ' : '') + n.name)
            })
          }
          walk(depts.data || [], '')
          this.deptOptions = flat
        }
      } catch (e) { /* 忽略选项加载失败 */ }
    },
    async load() {
      this.loading = true
      try {
        const res = await request({ url: '/drive/list', method: 'get', params: { parent_id: this.currentId } })
        if (res.code === 0) this.list = res.data || []
      } catch (e) { this.$message.error('加载失败') }
      this.loading = false
    },
    goRoot() { this.currentId = 0; this.breadcrumb = []; this.load() },
    async cd(id) {
      const node = this.list.find(x => x.id === id)
      if (node && node.locked && !this.unlockTickets[id]) {
        this.pendingId = id; this.pendingName = node.file_name; this.pendingRow = node; this.password = ''
        this.passwordVisible = true
        return
      }
      this.enterFolder(id)
    },
    enterFolder(id) {
      this.currentId = id
      const node = this.list.find(x => x.id === id)
      if (node) this.breadcrumb.push({ id: node.id, file_name: node.file_name })
      this.load()
    },
    async doVerify() {
      if (!this.password) return this.$message.warning('请输入密码')
      const res = await request({ url: '/drive/verify-password', method: 'post', data: { id: this.pendingId, password: this.password } })
      if (res.code === 0) {
        this.$set(this.unlockTickets, this.pendingId, res.data.ticket)
        this.passwordVisible = false
        this.enterFolder(this.pendingId)
      } else {
        this.$message.error(res.msg || '密码错误')
      }
    },
    openMkdir() { this.mkdirName = ''; this.mkdirPasswordOn = false; this.mkdirPassword = ''; this.mkdirScope = 'all'; this.mkdirDeptIds = []; this.mkdirUserIds = []; this.mkdirVisible = true },
    async doMkdir() {
      if (!this.mkdirName) return this.$message.warning('请输入名称')
      const data = { name: this.mkdirName, parent_id: this.currentId }
      if (this.mkdirPasswordOn) data.password = this.mkdirPassword
      data.view_scope = this.mkdirScope
      if (this.mkdirScope === 'dept') data.view_dept_ids = this.mkdirDeptIds
      if (this.mkdirScope === 'users') data.view_user_ids = this.mkdirUserIds
      const res = await request({ url: '/drive/mkdir', method: 'post', data: data })
      if (res.code === 0) { this.$message.success('创建成功'); this.mkdirVisible = false; this.load() }
      else this.$message.error(res.msg || '创建失败')
    },
    forgot(row) {
      this.pendingRow = row; this.pendingId = row.id; this.pendingName = row.file_name
      this.resetCode = ''; this.resetNewPassword = ''; this.resetPhoneMask = ''
      this.passwordVisible = false
      this.resetVisible = true
    },
    async sendReset() {
      this.resetSending = true
      try {
        const res = await request({ url: '/drive/send-reset-code', method: 'post', data: { id: this.pendingId } })
        if (res.code === 0) { this.resetPhoneMask = res.data.phone_mask; this.$message.success('验证码已发送') }
        else this.$message.error(res.msg || '发送失败')
      } catch (e) { this.$message.error('发送失败') }
      this.resetSending = false
    },
    async doReset() {
      if (!/^\d{6}$/.test(this.resetCode || '')) return this.$message.warning('请输入6位验证码')
      if (!this.resetNewPassword) return this.$message.warning('请输入新密码')
      const res = await request({ url: '/drive/reset-password', method: 'post', data: { id: this.pendingId, code: this.resetCode, new_password: this.resetNewPassword } })
      if (res.code === 0) {
        this.$message.success('密码重置成功')
        this.resetVisible = false
        delete this.unlockTickets[this.pendingId]
        this.load()
      } else this.$message.error(res.msg || '重置失败')
    },
    onUpload(res) {
      if (res && res.code === 0) { this.$message.success('上传成功'); this.load() }
      else this.$message.error((res && res.msg) || '上传失败')
    },
    preview(row) {
      if (row.file_type !== 'file') return
      const token = getToken() || ''
      const url = '/api/drive/download?id=' + row.id + (token ? '&token=' + token : '')
      window.open(location.origin + url, '_blank')
    },
    fmtSize(s) {
      if (!s) return '-'
      if (s < 1024) return s + ' B'
      if (s < 1048576) return (s / 1024).toFixed(1) + ' KB'
      return (s / 1048576).toFixed(1) + ' MB'
    },
    del(row) {
      this.$confirm('确认删除「' + row.file_name + '」？', '提示', { type: 'warning' }).then(async () => {
        const res = await request({ url: '/drive/delete', method: 'post', data: { id: row.id } })
        if (res.code === 0) { this.$message.success('已删除'); this.load() }
      }).catch(() => {})
    }
  }
}
</script>
<style scoped>
.page-container { padding: 4px; }
.drive-card .el-upload { margin-left: 10px; }
.drive-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.drive-title { font-size: 15px; }
.drive-filter { display: flex; align-items: center; }
.drive-actions { display: flex; align-items: center; }
.file-name { cursor: pointer; }
.file-name:hover { color: #409EFF; }
</style>
