<template>
  <div class="tab-config-page">
    <div class="page-header">
      <div>
        <h2>底部导航配置</h2>
        <span class="sub-title">管理移动端底部导航 Tab（DIY 页面可作一级入口）</span>
      </div>
      <div>
        <el-button size="small" @click="loadList">刷新</el-button>
        <el-button size="small" type="primary" icon="el-icon-plus" @click="openForm()">新增 Tab</el-button>
      </div>
    </div>

    <div class="table-container">
      <el-table :data="list" size="small" border stripe v-loading="loading" style="width:100%">
        <el-table-column label="排序" width="110" align="center">
          <template slot-scope="{row, $index}">
            <el-button size="mini" type="text" icon="el-icon-top" :disabled="$index === 0" @click="move($index, -1)"></el-button>
            <el-button size="mini" type="text" icon="el-icon-bottom" :disabled="$index === list.length - 1" @click="move($index, 1)"></el-button>
          </template>
        </el-table-column>
        <el-table-column prop="title" label="Tab 名称" width="120" />
        <el-table-column label="图标" width="90" align="center">
          <template slot-scope="{row}">
            <el-image v-if="isImgUrl(row.icon)" :src="row.icon" class="cell-icon-img" fit="contain" />
            <span v-else style="font-size:18px">{{ row.icon || '📌' }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="path" label="跳转路径" min-width="220" show-overflow-tooltip />
        <el-table-column label="可见性" width="130" align="center">
          <template slot-scope="{row}">
            <el-tag v-if="row.require_login === 0" type="info" size="small">公开</el-tag>
            <el-tag v-else-if="!row.roles || !row.roles.length" type="warning" size="small">仅登录用户</el-tag>
            <el-tag v-else type="danger" size="small">指定角色({{ row.roles.length }})</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="{row}">
            <el-tag :type="row.status === 1 ? 'success' : 'info'" size="small">{{ row.status === 1 ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150" align="center" fixed="right">
          <template slot-scope="{row}">
            <el-button size="mini" type="text" @click="openForm(row)">编辑</el-button>
            <el-button size="mini" type="text" style="color:#f56c6c" @click="delTab(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <!-- 新增/编辑弹窗 -->
    <el-dialog :title="form.id ? '编辑 Tab' : '新增 Tab'" :visible.sync="showForm" width="560px" append-to-body>
      <el-form label-width="100px" size="small">
        <el-form-item label="Tab 标识" required>
          <el-input v-model="form.tab_key" placeholder="如 tab_showroom" maxlength="50" :disabled="!!form.id" />
        </el-form-item>
        <el-form-item label="显示名称" required>
          <el-input v-model="form.title" placeholder="底部显示的文字" maxlength="20" />
        </el-form-item>
        <el-form-item label="默认图标">
          <div class="icon-field">
            <el-input v-model="form.icon" placeholder="uview-plus图标名（如 account）或图片URL" style="flex:1">
              <el-button slot="append" icon="el-icon-picture-outline" @click="openIconPicker('icon')">选择</el-button>
            </el-input>
            <el-image v-if="isImgUrl(form.icon)" :src="form.icon" class="icon-preview" fit="contain" />
            <span v-else-if="form.icon" class="icon-name-tag">{{ form.icon }}</span>
          </div>
        </el-form-item>
        <el-form-item label="选中图标">
          <div class="icon-field">
            <el-input v-model="form.icon_active" placeholder="uview-plus图标名（如 account-fill）或图片URL" style="flex:1">
              <el-button slot="append" icon="el-icon-picture-outline" @click="openIconPicker('icon_active')">选择</el-button>
            </el-input>
            <el-image v-if="isImgUrl(form.icon_active)" :src="form.icon_active" class="icon-preview" fit="contain" />
            <span v-else-if="form.icon_active" class="icon-name-tag">{{ form.icon_active }}</span>
          </div>
        </el-form-item>
        <el-form-item label="跳转路径" required>
          <DiyLinkPicker v-model="form.path" />
        </el-form-item>
        <el-form-item label="页面路径">
          <el-input v-model="form.page_path" placeholder="pages.json 注册路径，如 /pages/diy/index" />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="form.sort" :min="0" size="mini" />
        </el-form-item>
        <el-form-item label="可见性">
          <el-radio-group v-model="visType" size="small">
            <el-radio-button :label="0">公开</el-radio-button>
            <el-radio-button :label="1">仅登录用户</el-radio-button>
            <el-radio-button :label="2">指定角色</el-radio-button>
          </el-radio-group>
        </el-form-item>
        <el-form-item v-if="visType === 2" label="指定角色">
          <el-select v-model="form.roles" multiple filterable placeholder="选择可见角色" style="width:100%">
            <el-option v-for="r in rolesOptions" :key="r.value" :label="r.label" :value="r.value"></el-option>
          </el-select>
        </el-form-item>
        <el-form-item label="角标">
          <el-radio-group v-model="form.badge" size="small">
            <el-radio-button label="">无</el-radio-button>
            <el-radio-button label="dot">小圆点</el-radio-button>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.status" :active-value="1" :inactive-value="0" active-text="启用" inactive-text="停用" />
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="showForm = false">取消</el-button>
        <el-button size="small" type="primary" :loading="saving" @click="submitForm">保存</el-button>
      </span>
    </el-dialog>

    <!-- 图标选择器 -->
    <el-dialog title="选择图标" :visible.sync="showIconPicker" width="620px" append-to-body>
      <el-tabs v-model="iconTab">
        <el-tab-pane label="图标库" name="library">
          <div class="icon-grid">
            <div
              v-for="ic in iconList"
              :key="ic.name"
              class="icon-grid-item"
              :class="{ active: form[pickerTarget] === ic.name }"
              @click="chooseIcon(ic.name)"
            >
              <div class="icon-grid-label">{{ ic.label }}</div>
              <div class="icon-grid-name">{{ ic.name }}</div>
            </div>
          </div>
          <div class="icon-tip">点击图标名即可选中（uview-plus 图标名，移动端底部导航可用）。</div>
        </el-tab-pane>
        <el-tab-pane label="上传图片" name="image">
          <el-upload
            class="icon-uploader"
            action="/api/upload"
            :headers="uploadHeaders"
            :show-file-list="false"
            :on-success="handleUploadSuccess"
            :on-error="handleUploadError"
            accept="image/*"
          >
            <el-button size="small" type="primary">上传图标图片</el-button>
          </el-upload>
          <div class="icon-tip">上传后将以图片 URL 作为图标（支持 jpg/png/gif/webp，最多 20MB）。</div>
        </el-tab-pane>
      </el-tabs>
    </el-dialog>
  </div>
</template>

<script>
import { tabList, tabCreate, tabUpdate, tabDelete, tabSort, getRoleOptions } from '@/api/diy'
import DiyLinkPicker from '@/views/diy/DiyLinkPicker.vue'

// uview-plus 常用图标库（名字均取自 uview-plus/components/u-icon/icons.js，保证有效）
const UVIEW_ICONS = [
  { name: 'home', label: '首页' },
  { name: 'home-fill', label: '首页实' },
  { name: 'account', label: '通讯录' },
  { name: 'account-fill', label: '通讯录实' },
  { name: 'bell', label: '消息' },
  { name: 'bell-fill', label: '消息实' },
  { name: 'setting', label: '设置' },
  { name: 'setting-fill', label: '设置实' },
  { name: 'chat', label: '聊天' },
  { name: 'chat-fill', label: '聊天实' },
  { name: 'man', label: '人员' },
  { name: 'man-add', label: '加人' },
  { name: 'woman', label: '女性' },
  { name: 'search', label: '搜索' },
  { name: 'plus', label: '加号' },
  { name: 'plus-circle', label: '加号圆' },
  { name: 'star', label: '星标' },
  { name: 'star-fill', label: '星标实' },
  { name: 'heart', label: '爱心' },
  { name: 'heart-fill', label: '爱心实' },
  { name: 'phone', label: '电话' },
  { name: 'phone-fill', label: '电话实' },
  { name: 'email', label: '邮件' },
  { name: 'list', label: '列表' },
  { name: 'grid', label: '宫格' },
  { name: 'calendar', label: '日历' },
  { name: 'clock', label: '时钟' },
  { name: 'file-text', label: '文件' },
  { name: 'edit-pen', label: '编辑' },
  { name: 'trash', label: '删除' },
  { name: 'download', label: '下载' },
  { name: 'scan', label: '扫码' },
  { name: 'fingerprint', label: '指纹' },
  { name: 'map', label: '地图' },
  { name: 'map-fill', label: '地图实' },
  { name: 'car', label: '车辆' },
  { name: 'shopping-cart', label: '购物车' },
  { name: 'bag', label: '背包' },
  { name: 'order', label: '订单' },
  { name: 'eye', label: '查看' },
  { name: 'lock', label: '锁' },
  { name: 'camera', label: '相机' },
  { name: 'photo', label: '图片' },
  { name: 'info-circle', label: '信息' },
  { name: 'warning', label: '警告' },
  { name: 'checkmark-circle', label: '完成' },
  { name: 'close', label: '关闭' },
  { name: 'share', label: '分享' },
  { name: 'tags', label: '标签' },
  { name: 'bookmark', label: '书签' },
  { name: 'server-man', label: '服务' },
  { name: 'weixin-fill', label: '微信' },
  { name: 'thumb-up', label: '赞' },
  { name: 'more-dot-fill', label: '更多' },
  { name: 'reload', label: '刷新' }
]

export default {
  name: 'TabConfigPage',
  components: { DiyLinkPicker },
  data() {
    return {
      list: [], loading: false, showForm: false, saving: false,
      rolesOptions: [],
      visType: 0,
      form: { id: 0, tab_key: '', title: '', icon: '', icon_active: '', path: '', page_path: '', sort: 0, status: 1, require_login: 1, roles: [], badge: '' },
      // 图标选择器
      iconList: UVIEW_ICONS,
      showIconPicker: false,
      pickerTarget: 'icon',
      iconTab: 'library'
    }
  },
  computed: {
    uploadHeaders() {
      const token = localStorage.getItem('sc_admin_token') || sessionStorage.getItem('sc_admin_token') || ''
      return { Authorization: token ? `Bearer ${token}` : '' }
    }
  },
  created() { this.loadList(); this.loadRoles() },
  methods: {
    /** 判断是否为图片 URL */
    isImgUrl(val) {
      return !!val && (val.startsWith('http://') || val.startsWith('https://') || val.startsWith('/uploads') || val.startsWith('data:'))
    },
    /** 打开图标选择器：target = icon / icon_active */
    openIconPicker(target) {
      this.pickerTarget = target
      this.iconTab = 'library'
      this.showIconPicker = true
    },
    /** 从图标库选中 */
    chooseIcon(name) {
      this.form[this.pickerTarget] = name
      this.showIconPicker = false
    },
    /** 上传图片成功回调 */
    handleUploadSuccess(res) {
      if (res && res.code === 0 && res.data && res.data.url) {
        this.form[this.pickerTarget] = res.data.url
        this.showIconPicker = false
        this.$message.success('上传成功')
      } else {
        this.$message.error((res && res.msg) || '上传失败')
      }
    },
    handleUploadError() {
      this.$message.error('上传失败，请重试')
    },
    async loadList() {
      this.loading = true
      try {
        const res = await tabList({ page: 1, limit: 100 })
        if (res.code === 0) this.list = res.data.list || []
      } catch (e) {}
      this.loading = false
    },
    async loadRoles() {
      try {
        const r = await getRoleOptions()
        if (r.code === 0) this.rolesOptions = r.data || []
      } catch (e) {}
    },
    openForm(row) {
      this.visType = 0
      this.form = { id: 0, tab_key: '', title: '', icon: '', icon_active: '', path: '', page_path: '', sort: this.list.length, status: 1, require_login: 1, roles: [], badge: '' }
      if (row && row.id) {
        this.form = { ...row }
        this.form.roles = Array.isArray(row.roles) ? row.roles : []
        this.visType = row.require_login === 0 ? 0 : (row.roles && row.roles.length ? 2 : 1)
      }
      this.showForm = true
    },
    async submitForm() {
      if (!this.form.title) return this.$message.warning('请填写显示名称')
      if (!this.form.path) return this.$message.warning('请填写跳转路径')
      const data = { ...this.form }
      data.require_login = this.visType === 0 ? 0 : 1
      data.roles = this.visType === 2 ? (this.form.roles || []) : []
      this.saving = true
      try {
        if (data.id) await tabUpdate(data.id, data)
        else await tabCreate(data)
        this.$message.success('保存成功')
        this.showForm = false
        this.loadList()
      } catch (e) { this.$message.error(e.message || '保存失败') }
      this.saving = false
    },
    async delTab(row) {
      this.$confirm(`确定删除 Tab「${row.title}」吗？`, '删除确认', { type: 'warning' }).then(async () => {
        try {
          await tabDelete(row.id)
          this.$message.success('删除成功')
          this.loadList()
        } catch (e) { this.$message.error(e.message || '删除失败') }
      }).catch(() => {})
    },
    async move(index, dir) {
      const arr = [...this.list]
      const target = index + dir
      if (target < 0 || target >= arr.length) return
      const a = arr[index]; const b = arr[target]
      const tmp = a.sort; a.sort = b.sort; b.sort = tmp
      arr[index] = b; arr[target] = a
      this.list = arr
      try {
        await tabSort(this.list.map((it, i) => ({ id: it.id, sort: i + 1 })))
        this.loadList()
      } catch (e) { this.$message.error('排序保存失败') }
    },
  },
}
</script>

<style scoped>
.tab-config-page { padding: 0; background: #f5f7fa; min-height: 100%; }
.page-header { height: 56px; background: #fff; border-bottom: 1px solid #EBEEF5; padding: 0 24px; display: flex; align-items: center; justify-content: space-between; }
.page-header h2 { font-size: 20px; font-weight: bold; color: #303133; margin: 0; display: inline; }
.sub-title { font-size: 13px; color: #909399; margin-left: 12px; }
.table-container { background: #fff; margin: 16px 24px; padding: 8px; }
/* 图标字段 */
.icon-field { display: flex; align-items: center; gap: 8px; width: 100%; }
.icon-field .el-input { flex: 1; }
.icon-preview { width: 32px; height: 32px; border-radius: 4px; border: 1px solid #EBEEF5; flex-shrink: 0; }
.icon-name-tag { font-size: 12px; color: #606266; background: #F5F7FA; border: 1px solid #EBEEF5; border-radius: 4px; padding: 2px 8px; flex-shrink: 0; max-width: 140px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.cell-icon-img { width: 24px; height: 24px; }
/* 图标选择器 */
.icon-grid { display: flex; flex-wrap: wrap; gap: 8px; max-height: 420px; overflow: auto; }
.icon-grid-item { width: 84px; border: 1px solid #EBEEF5; border-radius: 6px; text-align: center; padding: 8px 4px; cursor: pointer; transition: all .15s; }
.icon-grid-item:hover { border-color: #409EFF; }
.icon-grid-item.active { border-color: #409EFF; background: #ECF5FF; }
.icon-grid-label { font-size: 14px; color: #606266; margin-bottom: 4px; }
.icon-grid-item.active .icon-grid-label { color: #409EFF; }
.icon-grid-name { font-size: 11px; color: #909399; word-break: break-all; }
.icon-tip { margin-top: 12px; font-size: 12px; color: #909399; line-height: 1.6; }
</style>
