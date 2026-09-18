<template>
  <div class="func-page">
    <div class="page-header">
      <div>
        <h2>功能配置</h2>
        <span class="sub-title">管理员工端功能入口 · 共 {{ total }} 个功能</span>
      </div>
      <el-button v-if="hasPerm('app:function:create')" type="primary" size="medium" icon="el-icon-plus" @click="openForm()">新增功能</el-button>
    </div>

    <div class="filter-bar">
      <div></div>
      <div class="filter-right">
        <el-select v-model="filter.location" size="small" placeholder="显示位置" clearable style="width:160px;margin-right:8px" @change="onSearchInput">
          <el-option label="🏠 首页" value="home" />
          <el-option label="👤 我的页面" value="profile" />
          <el-option label="🏠+👤 都显示" value="both" />
          <el-option label="✅ OA审批" value="oa" />
        </el-select>
        <el-input v-model="filter.keyword" size="small" placeholder="搜索功能名称或编码" prefix-icon="el-icon-search" clearable style="width:240px" @input="onSearchInput" />
      </div>
    </div>

    <div class="table-container">
      <el-table :data="list" size="small" border stripe style="width:100%" :row-style="{height:'44px'}" @sort-change="onSortChange" highlight-current-row>
        <el-table-column type="index" label="#" width="60" align="center" />
        <el-table-column prop="name" label="功能名称" width="120" sortable="custom">
          <template slot-scope="{row}"><strong style="color:#303133">{{ row.name }}</strong></template>
        </el-table-column>
        <el-table-column prop="code" label="功能编码" width="120">
          <template slot-scope="{row}"><span style="font-family:Consolas,monospace;color:#909399;font-size:12px">{{ row.code }}</span></template>
        </el-table-column>
        <el-table-column label="图标" width="80" align="center">
          <template slot-scope="{row}">
            <i :class="renderIconClass(row.icon)" style="font-size:24px;color:#409EFF"></i>
          </template>
        </el-table-column>
<el-table-column label="关联路径" width="180">
  <template slot-scope="{row}">
    <div style="line-height:1.5">
      <div style="font-weight:500;font-size:13px">{{ row.path_name }}</div>
      <div v-if="row.path_name" style="font-family:Consolas,monospace;font-size:11px;color:#C0C4CC">{{ pathMap[row.path_id] || '' }}</div>
    </div>
  </template>
</el-table-column>
        <el-table-column label="权限标识" width="130">
          <template slot-scope="{row}"><span style="font-size:12px;color:#909399;font-family:Consolas,monospace">{{ row.permission || '-' }}</span></template>
        </el-table-column>
        <el-table-column label="显示位置" width="120" align="center">
          <template slot-scope="{row}">
            <el-tag size="mini" :type="row.display_location === 'home' ? 'primary' : (row.display_location === 'profile' ? 'warning' : 'success')" effect="plain">
              {{ locationText(row.display_location) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="可见性" width="130" align="center">
          <template slot-scope="{row}">
            <el-tag v-if="row.visible_type === 'role'" size="mini" type="primary" effect="plain">角色可见（{{ (row.visible_targets || []).length }}）</el-tag>
            <el-tag v-else-if="row.visible_type === 'user'" size="mini" type="warning" effect="plain">用户可见（{{ (row.visible_targets || []).length }}）</el-tag>
            <el-tag v-else size="mini" type="success" effect="plain">全部可见</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="排序" width="80" align="center" sortable="custom">
          <template slot-scope="{row}"><el-tag size="mini" type="info" effect="plain">{{ row.sort }}</el-tag></template>
        </el-table-column>
        <el-table-column label="状态" width="80" align="center">
          <template slot-scope="{row}"><el-switch :value="!!row.status" @change="v => toggleStatus(row, v)" /></template>
        </el-table-column>
        <el-table-column label="操作" width="160" align="center" fixed="right">
          <template slot-scope="{row}">
            <el-button v-if="hasPerm('app:function:edit')" size="mini" type="text" icon="el-icon-edit" @click="openForm(row)">编辑</el-button>
            <el-button v-if="hasPerm('app:function:delete')" size="mini" type="text" icon="el-icon-delete" style="color:#F56C6C" @click="confirmDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>

    <div class="pagination-wrap">
      <el-pagination
        :current-page="page" :page-sizes="[10,20,50,100]" :page-size="limit" :total="total"
        layout="total, sizes, prev, pager, next, jumper"
        @size-change="s => { limit = s; loadList() }"
        @current-change="p => { page = p; loadList() }"
      />
    </div>

    <!-- 新增/编辑弹窗 -->
    <el-dialog :title="form.id ? '编辑功能' : '新增功能'" :visible.sync="showForm" width="560px" :close-on-click-modal="true" @closed="resetForm">
      <el-form ref="form" :model="form" label-width="110px" label-position="right" size="small" :rules="rules">
        <el-form-item label="功能名称" prop="name">
          <el-input v-model="form.name" placeholder="请输入功能名称" maxlength="20" />
        </el-form-item>
        <el-form-item label="功能编码" prop="code">
          <el-input v-model="form.code" placeholder="请输入功能编码，如 attendance" maxlength="50" :disabled="!!form.id" />
        </el-form-item>
        <el-form-item label="图标" prop="icon">
          <el-input v-model="form.icon" placeholder="请选择图标" readonly style="cursor:pointer" @focus="showIconPicker=true">
            <i slot="prefix" :class="renderIconClass(form.icon || 'question')" style="margin-top:7px;font-size:16px;color:#409EFF"></i>
          </el-input>
        </el-form-item>
        <el-form-item label="跳转路径" prop="path_id">
          <el-select v-model="form.path_id" style="width:100%" filterable remote :remote-method="searchPath" :loading="loadingPath" placeholder="请选择跳转路径">
            <el-option v-for="item in pathOptions" :key="item.id" :label="item.name + '（' + item.path + '）'" :value="item.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="权限标识">
          <el-select v-model="form.permission" style="width:100%" filterable clearable placeholder="请选择权限标识（可选）">
            <el-option v-for="item in permOptions" :key="item.code" :label="item.name + '（' + item.code + '）'" :value="item.code" />
          </el-select>
        </el-form-item>
        <el-form-item label="显示位置">
          <el-radio-group v-model="form.display_location">
            <el-radio-button label="home">🏠 首页</el-radio-button>
            <el-radio-button label="profile">👤 我的页面</el-radio-button>
            <el-radio-button label="both">🏠+👤 都显示</el-radio-button>
            <el-radio-button label="oa">✅ OA审批</el-radio-button>
          </el-radio-group>
          <div style="font-size:12px;color:#C0C4CC;line-height:1.5;margin-top:4px">home=仅首页 · profile=仅我的页面 · both=两处都显示 · oa=OA审批页面（按角色权限过滤）</div>
        </el-form-item>
        <el-form-item label="可见性控制">
          <el-radio-group v-model="form.visible_type">
            <el-radio-button label="all">全部可见</el-radio-button>
            <el-radio-button label="role">指定角色可见</el-radio-button>
            <el-radio-button label="user">指定用户可见</el-radio-button>
          </el-radio-group>
          <div style="font-size:12px;color:#C0C4CC;line-height:1.5;margin-top:4px">不满足可见性条件的用户将看不到该功能；超级管理员不受限制</div>
          <el-select
            v-if="form.visible_type === 'role'"
            v-model="form.visible_targets"
            multiple filterable collapse-tags
            placeholder="选择可见角色（可多选）"
            style="width:100%;margin-top:8px"
          >
            <el-option v-for="r in roleOptions" :key="r.value" :label="r.label" :value="Number(r.value)" />
          </el-select>
          <el-select
            v-if="form.visible_type === 'user'"
            v-model="form.visible_targets"
            multiple filterable collapse-tags
            placeholder="选择可见用户（可多选）"
            style="width:100%;margin-top:8px"
          >
            <el-option v-for="u in userOptions" :key="u.value" :label="u.label" :value="Number(u.value)" />
          </el-select>
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="form.sort" :min="0" :max="9999" :step="10" style="width:100%" />
        </el-form-item>
        <el-form-item label="状态">
          <el-switch v-model="form.status" :active-value="1" :inactive-value="0" />
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button @click="showForm = false" size="small">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveForm" size="small">确定</el-button>
      </span>
    </el-dialog>

    <!-- 图标选择器弹窗 -->
    <el-dialog title="选择图标" :visible.sync="showIconPicker" width="520px" :close-on-click-modal="true" @closed="iconPickerClosed">
      <el-input v-model="iconSearch" size="small" placeholder="搜索图标名称" prefix-icon="el-icon-search" clearable style="margin-bottom:12px" />
      <div class="icon-grid">
        <div v-for="icon in filteredIconList" :key="icon" class="icon-card" :class="{active: selectedIcon === icon}" @click="selectedIcon = icon">
          <i :class="renderIconClass(icon)" style="font-size:24px;color:#606266"></i>
          <span class="icon-name">{{ icon }}</span>
        </div>
      </div>
      <span slot="footer">
        <el-button @click="showIconPicker = false" size="small">取消</el-button>
        <el-button type="primary" size="small" @click="confirmIcon">确定</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getFunctionList, createFunction, updateFunction, deleteFunction, toggleFunctionStatus } from '@/api/app'
import { getPathAll } from '@/api/app'
import { getAppPermissions } from '@/api/role'
import request from '@/api/request'

export default {
  name: 'FunctionManage',
  data() {
    return {
      list: [], total: 0, page: 1, limit: 20,
      filter: { keyword: '', location: '' },
      searchTimer: null, sortProp: '', sortOrder: '',
      showForm: false, saving: false,
      pathOptions: [], pathMap: {}, loadingPath: false,
      permOptions: [],
      roleOptions: [], userOptions: [],
      form: { name: '', code: '', icon: '', path_id: '', permission: '', display_location: 'both', sort: 0, status: 1, visible_type: 'all', visible_targets: [] },
      rules: {
        name: [
          { required: true, message: '请输入功能名称', trigger: 'blur' },
          { max: 20, message: '长度不能超过20个字符', trigger: 'blur' },
        ],
        code: [
          { required: true, message: '请输入功能编码', trigger: 'blur' },
          { pattern: /^[a-z][a-z0-9_]*$/, message: '格式应为小写字母开头，包含小写字母、数字和下划线', trigger: 'blur' },
        ],
        icon: [{ required: true, message: '请选择图标', trigger: 'change' }],
        path_id: [{ required: true, message: '请选择跳转路径', trigger: 'change' }],
      },
      // 图标选择器（uview-plus 3.8.86）
      iconList: [
        'account', 'account-fill',
        'home', 'home-fill',
        'setting', 'setting-fill',
        'search', 'scan',
        'bell', 'bell-fill',
        'chat', 'chat-fill',
        'calendar', 'calendar-fill',
        'phone', 'phone-fill',
        'map', 'map-fill',
        'clock', 'clock-fill',
        'file-text', 'file-text-fill',
        'list', 'grid',
        'order', 'shopping-cart', 'shopping-cart-fill',
        'star', 'star-fill',
        'warning', 'info', 'info-circle',
        'question', 'question-circle',
        'edit-pen', 'edit-pen-fill',
        'trash', 'trash-fill',
        'plus', 'minus',
        'checkmark', 'checkmark-circle',
        'close', 'close-circle',
        'reload', 'download',
        'share', 'camera',
        'mic', 'lock', 'lock-fill',
        'gift', 'gift-fill',
        'coupon', 'coupon-fill',
        'integral', 'integral-fill',
        'rmb', 'rmb-circle',
        'photo', 'photo-fill',
        'more-dot-fill',
        'thumb-up', 'thumb-up-fill', 'thumb-down', 'thumb-down-fill',
        'heart', 'heart-fill',
        'play-circle', 'play-circle-fill',
        'pause-circle', 'pause-circle-fill',
        'arrow-up', 'arrow-down', 'arrow-left', 'arrow-right',
        'error', 'error-circle',
        'success', 'checkmark-circle',
        // OA审批相关（限uview-plus有效图标）
        'bag', 'bag-fill', 'car', 'car-fill',
        'email', 'email-fill', 'eye', 'eye-fill', 'eye-off',
        'man-add', 'man-add-fill', 'man-delete', 'man-delete-fill',
        'server-man', 'server-fill', 'wifi', 'wifi-off',
        'attach', 'bookmark', 'bookmark-fill',
        'pushpin', 'pushpin-fill', 'tags', 'tags-fill',
        'volume', 'volume-fill', 'volume-off', 'volume-off-fill',
        'empty-car', 'empty-wifi',
      ],
      showIconPicker: false,
      selectedIcon: '',
      iconSearch: '',
    }
  },
  computed: {
    filteredIconList() {
      if (!this.iconSearch) return this.iconList
      const q = this.iconSearch.toLowerCase()
      return this.iconList.filter(i => i.toLowerCase().includes(q))
    }
  },
  async created() {
    await Promise.all([this.loadPaths(), this.loadPerms(), this.loadRoleUserOptions()])
    this.loadList()
  },
  methods: {
    // 权限判断：按钮权限控制
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    async loadPaths() {
      try {
        const res = await getPathAll()
        const list = res.data.list || []
        this.pathOptions = list
        this.pathMap = {}
        list.forEach(p => { this.pathMap[p.id] = p.path })
      } catch (e) {}
    },
    searchPath(query) {
      if (!query) { this.loadPaths(); return }
      this.pathOptions = this.pathOptions.filter(p =>
        p.name.includes(query) || p.path.includes(query)
      )
    },
    async loadPerms() {
      try {
        const res = await getAppPermissions()
        this.permOptions = res.data || []
      } catch (e) { this.permOptions = [] }
    },
    // 加载角色/用户下拉（可见性控制）
    async loadRoleUserOptions() {
      try {
        const [rr, ur] = await Promise.all([
          request({ url: '/admin/roles/options', method: 'get' }).catch(() => null),
          request({ url: '/admin/users/options', method: 'get' }).catch(() => null)
        ])
        this.roleOptions = (rr && Array.isArray(rr.data)) ? rr.data : []
        this.userOptions = (ur && Array.isArray(ur.data)) ? ur.data : []
      } catch (e) { this.roleOptions = []; this.userOptions = [] }
    },
    async loadList() {
      try {
        const res = await getFunctionList({
          page: this.page, limit: this.limit,
          keyword: this.filter.keyword,
          location: this.filter.location || '',
          sort_prop: this.sortProp, sort_order: this.sortOrder,
        })
        this.list = res.data.list
        this.total = res.data.total
      } catch (e) {}
    },
    onSearchInput() {
      clearTimeout(this.searchTimer)
      this.searchTimer = setTimeout(() => { this.page = 1; this.loadList() }, 300)
    },
    onSortChange({ prop, order }) {
      this.sortProp = prop || ''; this.sortOrder = order || ''; this.loadList()
    },
    openForm(row) {
      if (row) {
        this.form = { ...row, visible_type: row.visible_type || 'all', visible_targets: Array.isArray(row.visible_targets) ? row.visible_targets.map(Number) : [] }
      } else {
        this.form = { name: '', code: '', icon: '', path_id: '', permission: '', display_location: 'both', sort: 0, status: 1, visible_type: 'all', visible_targets: [] }
      }
      this.showForm = true
    },
    locationText(loc) {
      return { home: '🏠首页', profile: '👤我的页面', both: '🏠+👤', oa: '✅OA审批' }[loc] || '🏠+👤'
    },
    resetForm() { this.$refs.form?.clearValidate() },
    async saveForm() {
      try { await this.$refs.form.validate() } catch (e) { return }
      this.saving = true
      try {
        const payload = { ...this.form }
        // 可见性：all 清空 targets
        if (payload.visible_type === 'all') payload.visible_targets = []
        if (this.form.id) {
          await updateFunction(this.form.id, payload)
          this.$message.success('编辑成功')
        } else {
          await createFunction(payload)
          this.$message.success('新增成功')
        }
        this.showForm = false; this.loadList()
      } catch (e) {}
      this.saving = false
    },
    async toggleStatus(row, val) {
      const old = row.status; row.status = val ? 1 : 0
      try { await toggleFunctionStatus(row.id, row.status); this.$message.success('状态已更新') }
      catch (e) { row.status = old }
    },
    confirmDelete(row) {
      this.$confirm(`确认删除功能「${row.name}」吗？该功能被装修引用时将无法删除。`, '删除确认', {
        confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning'
      }).then(async () => {
        try { await deleteFunction(row.id); this.$message.success('删除成功'); this.loadList() } catch (e) {}
      }).catch(() => {})
    },
    confirmIcon() {
      this.form.icon = this.selectedIcon
      this.showIconPicker = false
    },
    iconPickerClosed() { this.selectedIcon = ''; this.iconSearch = '' },
    // 渲染 uview-plus 图标名到 Element UI 类名（管理端显示用）
    renderIconClass(name) {
      const map = {
        'account': 'el-icon-user', 'account-fill': 'el-icon-user-solid',
        'home': 'el-icon-s-home', 'home-fill': 'el-icon-s-home',
        'setting': 'el-icon-setting', 'setting-fill': 'el-icon-setting',
        'search': 'el-icon-search', 'scan': 'el-icon-scan',
        'bell': 'el-icon-bell', 'bell-fill': 'el-icon-bell',
        'chat': 'el-icon-chat-dot-round', 'chat-fill': 'el-icon-chat-dot-round',
        'calendar': 'el-icon-date', 'calendar-fill': 'el-icon-date',
        'phone': 'el-icon-phone', 'phone-fill': 'el-icon-phone',
        'map': 'el-icon-location', 'map-fill': 'el-icon-location',
        'clock': 'el-icon-time', 'clock-fill': 'el-icon-time',
        'file-text': 'el-icon-document', 'file-text-fill': 'el-icon-document',
        'list': 'el-icon-s-operation', 'grid': 'el-icon-s-grid',
        'order': 'el-icon-document', 'shopping-cart': 'el-icon-shopping-cart-2',
        'star': 'el-icon-star-on', 'star-fill': 'el-icon-star-on',
        'warning': 'el-icon-warning', 'info': 'el-icon-info', 'info-circle': 'el-icon-info',
        'question': 'el-icon-question', 'question-circle': 'el-icon-question',
        'edit-pen': 'el-icon-edit', 'edit-pen-fill': 'el-icon-edit',
        'trash': 'el-icon-delete', 'trash-fill': 'el-icon-delete',
        'plus': 'el-icon-plus', 'minus': 'el-icon-minus',
        'checkmark': 'el-icon-success', 'checkmark-circle': 'el-icon-success',
        'close': 'el-icon-close', 'close-circle': 'el-icon-close',
        'reload': 'el-icon-refresh', 'download': 'el-icon-download',
        'share': 'el-icon-share', 'camera': 'el-icon-camera',
        'mic': 'el-icon-microphone', 'lock': 'el-icon-lock', 'lock-fill': 'el-icon-lock',
        'gift': 'el-icon-present', 'gift-fill': 'el-icon-present',
        'coupon': 'el-icon-tickets', 'coupon-fill': 'el-icon-tickets',
        'integral': 'el-icon-medal', 'integral-fill': 'el-icon-medal',
        'rmb': 'el-icon-money', 'rmb-circle': 'el-icon-money',
        'photo': 'el-icon-picture', 'photo-fill': 'el-icon-picture',
        'more-dot-fill': 'el-icon-more',
        'thumb-up': 'el-icon-thumb', 'thumb-up-fill': 'el-icon-thumb',
        'heart': 'el-icon-star-off', 'heart-fill': 'el-icon-star-off',
        'play-circle': 'el-icon-video-play', 'play-circle-fill': 'el-icon-video-play',
        'pause-circle': 'el-icon-video-pause', 'pause-circle-fill': 'el-icon-video-pause',
        'arrow-up': 'el-icon-arrow-up', 'arrow-down': 'el-icon-arrow-down', 'arrow-left': 'el-icon-arrow-left', 'arrow-right': 'el-icon-arrow-right',
        'error': 'el-icon-error', 'error-circle': 'el-icon-error',
        'success': 'el-icon-success', 'checkmark-circle': 'el-icon-success',
      }
      return map[name] || 'el-icon-question' // 默认
    },
  }
}
</script>

<style scoped>
.func-page { padding: 0; background: #f5f7fa; min-height: 100%; }
.page-header {
  height: 56px; background: #fff; border-bottom: 1px solid #EBEEF5;
  padding: 0 24px; display: flex; align-items: center; justify-content: space-between;
}
.page-header h2 { font-size: 20px; font-weight: bold; color: #303133; margin: 0; display: inline; }
.sub-title { font-size: 13px; color: #909399; margin-left: 12px; }
.filter-bar {
  height: 48px; background: #fff; border-radius: 8px; margin: 12px 24px 0;
  padding: 0 24px; display: flex; align-items: center; justify-content: flex-end;
}
.table-container { background: #fff; margin: 0 24px; padding: 0; }
.table-container .el-table { border-radius: 0; }
.table-container .el-table::before { display: none; }
.pagination-wrap {
  display: flex; justify-content: flex-end; padding: 16px 24px;
  background: #fff; margin: 0 24px 24px; border-top: 1px solid #EBEEF5;
}
/* 图标选择器 */
.icon-grid { display: flex; flex-wrap: wrap; gap: 8px; max-height: 400px; overflow-y: auto; }
.icon-card {
  width: 52px; height: 56px; display: flex; flex-direction: column;
  align-items: center; justify-content: center; border: 1px solid #EBEEF5;
  border-radius: 6px; cursor: pointer; transition: all 0.2s;
}
.icon-card:hover { border-color: #409EFF; background: #ecf5ff; }
.icon-card.active { border: 2px solid #409EFF; background: #ecf5ff; }
.icon-name { font-size: 11px; color: #606266; margin-top: 4px; text-align: center; word-break: break-all; line-height: 1.3; }
</style>
