<template>
  <aside class="sidebar" :class="[modeClass]" :style="sidebarStyle">
    <!-- 经典树形菜单模式 -->
    <template v-if="theme.menu_layout_mode !== 'left_right'">
      <div class="sidebar-logo" :style="logoStyle">
        <template v-if="theme.logo_display_mode==='image_only'&&theme.logo_image"><img :src="theme.logo_image" class="logo-img" /></template>
        <template v-else>
          <i v-if="theme.logo_display_mode!=='text_only'" :class="theme.logo_icon||'el-icon-s-home'" />
          <span v-if="theme.logo_display_mode!=='icon_only'">{{collapsed?(theme.system_name_abbr||'SC'):theme.system_name}}</span>
        </template>
      </div>
      <el-menu :key="'menu-'+menuItems.length" :default-active="$route.path" :background-color="theme.sidebar_bg_color" :text-color="theme.sidebar_text_color" :active-text-color="theme.sidebar_active_color" :unique-opened="theme.menu_accordion" :collapse="collapsed" :collapse-transition="true" :style="menuStyle">
        <template v-for="item in menuItems">
          <el-menu-item v-if="!item.children || item.children.length === 0" :key="item.path || item.name" :index="item.path || item.name" @click="goTo(item.path)">
            <i v-if="theme.menu_icon_show && (!theme.menu_icon_top_only || item===menuItems[0])" :class="item.icon" />
            <span slot="title">{{item.name}}</span>
          </el-menu-item>
          <el-submenu v-else :key="item.name" :index="item.name">
            <template slot="title">
              <i v-if="theme.menu_icon_show" :class="item.icon" />
              <span>{{item.name}}</span>
            </template>
            <template v-for="child in item.children">
              <el-menu-item v-if="!child.children || child.children.length === 0" :key="child.path" :index="child.path" @click="goTo(child.path)">
                <i v-if="theme.menu_icon_show" :class="child.icon" />
                <span slot="title" :style="{fontSize:textSize+'px',overflow:theme.menu_text_overflow==='ellipsis'?'hidden':'visible',textOverflow:theme.menu_text_overflow==='ellipsis'?'ellipsis':'clip',whiteSpace:theme.menu_text_overflow==='ellipsis'?'nowrap':'normal'}">{{child.name}}</span>
              </el-menu-item>
              <el-submenu v-else :key="child.name" :index="item.name+'-'+child.name">
                <template slot="title">
                  <i v-if="theme.menu_icon_show" :class="child.icon" />
                  <span>{{child.name}}</span>
                </template>
                <template v-for="sub in child.children">
                  <el-menu-item v-if="!sub.children || sub.children.length === 0" :key="sub.path" :index="sub.path" @click="goTo(sub.path)">
                    <i v-if="theme.menu_icon_show" :class="sub.icon" />
                    <span slot="title" :style="{fontSize:textSize+'px',overflow:theme.menu_text_overflow==='ellipsis'?'hidden':'visible',textOverflow:theme.menu_text_overflow==='ellipsis'?'ellipsis':'clip',whiteSpace:theme.menu_text_overflow==='ellipsis'?'nowrap':'normal'}">{{sub.name}}</span>
                  </el-menu-item>
                  <!-- 第4级子菜单（如：安全培训 → 培训考试 → 题库管理） -->
                  <el-submenu v-else :key="sub.name" :index="item.name+'-'+child.name+'-'+sub.name">
                    <template slot="title">
                      <i v-if="theme.menu_icon_show" :class="sub.icon" />
                      <span>{{sub.name}}</span>
                    </template>
                    <el-menu-item v-for="sub2 in sub.children" :key="sub2.path" :index="sub2.path" @click="goTo(sub2.path)">
                      <i v-if="theme.menu_icon_show" :class="sub2.icon" />
                      <span slot="title" :style="{fontSize:textSize+'px',overflow:theme.menu_text_overflow==='ellipsis'?'hidden':'visible',textOverflow:theme.menu_text_overflow==='ellipsis'?'ellipsis':'clip',whiteSpace:theme.menu_text_overflow==='ellipsis'?'nowrap':'normal'}">{{sub2.name}}</span>
                    </el-menu-item>
                  </el-submenu>
                </template>
              </el-submenu>
            </template>
          </el-submenu>
        </template>
      </el-menu>
    </template>
    <!-- 左一右子菜单模式 -->
    <template v-else>
      <div class="sidebar-logo" :style="logoStyle">
        <template v-if="theme.logo_display_mode==='image_only'&&theme.logo_image"><img :src="theme.logo_image" class="logo-img" /></template>
        <template v-else>
          <i v-if="theme.logo_display_mode!=='text_only'" :class="theme.logo_icon||'el-icon-s-home'" />
          <span v-if="theme.logo_display_mode!=='icon_only'">{{collapsed?(theme.system_name_abbr||'SC'):theme.system_name}}</span>
        </template>
      </div>
      <div v-if="!collapsed" class="left-right-content">
        <div class="left-menu-panel" :style="{width:theme.left_menu_width+'px',backgroundColor:theme.sidebar_bg_color}">
          <div v-for="item in topLevelMenus" :key="item.name" ref="menuItems" class="lr-menu-item" :class="{active:activeTopMenu===item.name}" :style="{color:activeTopMenu===item.name?theme.sidebar_active_color:theme.sidebar_text_color}" @click="clickTopMenu(item, $event)">
            <i :class="item.icon||'el-icon-menu'" class="lr-menu-icon" />
            <span class="lr-menu-name">{{item.name}}</span>
          </div>
        </div>
      <!-- 弹出浮层 -->
      <div v-if="popupVisible && popupItems" class="submenu-popup" :style="popupStyle" @mouseleave="closePopup">
        <div v-for="child in popupItems" :key="child.path" class="lr-menu-item" :class="{active:$route.path===child.path}" :style="{color:$route.path===child.path?theme.sidebar_active_color:theme.sidebar_text_color}" @click="goTo(child.path);closePopup()">
          <i :class="child.icon||'el-icon-menu'" class="lr-menu-icon" />
          <span class="lr-menu-name">{{child.name}}</span>
        </div>
      </div>
        <!-- 点击遮罩关闭浮层 -->
        <div v-if="popupVisible" class="popup-overlay" @click="closePopup" @click.self="closePopup"></div>
      </div>
    </template>
  </aside>
</template>
<script>
import { getLoginPermissions } from '@/api/auth'
import { getUserMenuTree } from '@/api/menus'
import themeMixin from '@/mixins/theme'

// 内置菜单配置（作为getUserMenuTree空数据时的后备）
const BUILTIN_MENUS = [
  { name: '控制台', path: '/dashboard', icon: 'el-icon-s-home', permission: 'dashboard:view' },
  { name: '人事管理', icon: 'el-icon-user', permission: 'hr:view', children: [
    { name: '组织架构', path: '/organization', icon: 'el-icon-share', permission: 'org:manage' },
    { name: '员工档案', path: '/profiles', icon: 'el-icon-user-solid', permission: 'employeeprofile:view' },
  ]},
  { name: '系统设置', icon: 'el-icon-setting', permission: 'system:view', children: [
    { name: '用户管理', path: '/users', icon: 'el-icon-user', permission: 'user:view' },
    { name: '角色管理', path: '/roles', icon: 'el-icon-s-custom', permission: 'role:view' },
    { name: '权限管理', path: '/permissions', icon: 'el-icon-lock', permission: 'permission:view' },
    { name: '基础服务', path: '/services', icon: 'el-icon-connection', permission: 'service:view' },
    { name: '登录页面配置', path: '/settings/login', icon: 'el-icon-edit-outline', permission: 'system:login_config' },
    { name: '界面配置', path: '/settings/theme', icon: 'el-icon-brush', permission: 'theme:config' },
    { name: '数据字典', path: '/dictionary', icon: 'el-icon-notebook-2', permission: 'dictionary:manage' },
    { name: '系统参数', path: '/settings/params', icon: 'el-icon-setting', permission: 'system:config' },
    { name: '菜单管理', path: '/settings/menus', icon: 'el-icon-menu', permission: 'menu:manage' },
  ]},
  { name: '应用管理', icon: 'el-icon-connection', permission: 'app:manage', children: [
    { name: '路径管理', path: '/app/paths', icon: 'el-icon-share', permission: 'app:path:manage' },
    { name: '功能配置', path: '/app/functions', icon: 'el-icon-s-operation', permission: 'app:function:manage' },
    { name: '移动端配置', path: '/app/mobile-config', icon: 'el-icon-picture-outline', permission: 'app:mobile:manage' },
    { name: '底部导航配置', path: '/settings/tab-config', icon: 'el-icon-s-grid', permission: 'app:mobile:manage' },
    { name: '页面数据统计', path: '/settings/diy-stats', icon: 'el-icon-data-analysis', permission: 'app:mobile:manage' },
    { name: '登录配置', path: '/app/login-config', icon: 'el-icon-mobile', permission: 'login:config:manage' },
    { name: '登录页面管理', path: '/app/login-page', icon: 'el-icon-edit-outline', permission: 'login:page:manage' },
    { name: '页面装修', path: '/diy/list', icon: 'el-icon-edit-outline', permission: 'diy:view' },
  ]},
  { name: '系统维护', icon: 'el-icon-s-operation', permission: 'maintenance:view', children: [
    { name: '系统日志', path: '/logs', icon: 'el-icon-document-copy', permission: 'log:view' },
    { name: '系统监控', path: '/monitor', icon: 'el-icon-data-line', permission: 'monitor:view' },
    { name: '安全维护', icon: 'el-icon-s-marketing', permission: 'security:manage', children: [
      { name: '数据库维护', path: '/database', icon: 'el-icon-data-analysis', permission: 'database:manage' },
    ]},
  ]},
]
export default {
  name: 'AppSidebar', mixins: [themeMixin],
  props: { collapsed: { type: Boolean, default: false }, sidebarWidth: { type: Number, default: 220 } },
  data() { return { menuItems: [], userPerms: [], activeTopMenu: '', popupVisible: false, popupItems: null, popupStyle: {} } },
  computed: {
    modeClass() {
      const c = this.theme.menu_layout_mode === 'left_right' ? 'layout-left-right' : ''
      return c + (this.theme.menu_expand_mode === 'hover' ? ' hover-expand' : '')
    },
    topLevelMenus() { return this.menuItems },
    sidebarStyle() {
      const w = this.theme.menu_layout_mode === 'left_right' ? (this.theme.left_menu_width || 200) : this.sidebarWidth
      return Object.assign({ width: w + 'px', backgroundColor: this.theme.sidebar_bg_color }, this.menuStyle)
    },
menuStyle() {
  const h = { compact:'40px', default:'50px', loose:'56px', xloose:'64px' }
  const ico = { small:'16px', default:'18px', large:'20px' }
  const baseSize = this.textSize
  // 根据侧边栏宽度缩放字体
  const w = this.collapsed ? (this.theme.sidebar_collapsed_width || 64) : (this.theme.sidebar_width || 220)
  const scale = w >= 220 ? 1 : w >= 180 ? 0.9 : w >= 120 ? 0.8 : 0.7
  const scaledSize = Math.round(baseSize * scale)
  const scaledIcon = Math.round(18 * scale)
  return {
    '--menu-item-height': h[this.theme.menu_item_height] || '50px',
    '--menu-icon-size': scaledIcon + 'px',
    '--menu-text-size': scaledSize + 'px',
    '--sidebar-text-hover': this.theme.sidebar_text_hover || this.theme.sidebar_active_color || '#ffffff',
    '--sidebar-active-color': this.theme.sidebar_active_color || '#409EFF',
    '--sidebar-hover-bg': this.theme.menu_hover_bg_color || 'rgba(255,255,255,0.08)',
    '--sidebar-active-bg': this.theme.sidebar_active_bg || 'rgba(64,158,255,0.1)',
    '--sidebar-submenu-bg': this.theme.sidebar_submenu_bg || 'rgba(0,0,0,0.2)',
  }
},
    textSize() { return { small:13, default:14, large:15 }[this.theme.menu_text_size] || 14 },
    logoStyle() {
      const ff = this.theme.logo_text_font_family
      return { height: this.theme.logo_area_height + 'px', lineHeight: this.theme.logo_area_height + 'px', backgroundColor: this.theme.logo_bg_color, color: this.theme.logo_text_color, fontSize: this.theme.logo_text_size + 'px', fontWeight: this.theme.logo_text_bold ? 'bold' : 'normal', letterSpacing: this.theme.logo_text_letter_spacing + 'px', borderRadius: this.theme.logo_area_radius + 'px', borderBottom: this.theme.logo_bottom_border ? '1px solid ' + this.theme.border_color : 'none', fontFamily: ff === 'system' ? '"Helvetica Neue", Helvetica, "PingFang SC", "Microsoft YaHei", sans-serif' : ff }
    },
    iconSize() { return { small: 24, default: 32, large: 40 }[this.theme.right_submenu_icon_size] || 32 },
    cardStyle() {
      const r = this.theme.right_submenu_card_radius || 8
      return { borderRadius: r + 'px', border: this.theme.right_submenu_card_style === 'bordered' ? '1px solid ' + this.theme.border_color : 'none', boxShadow: this.theme.right_submenu_card_style === 'shadow' ? '0 2px 8px rgba(0,0,0,0.08)' : 'none', transition: 'all 0.3s' }
    },
  },
  async created() {
    try {
      const [permRes, menuRes] = await Promise.all([
        getLoginPermissions(),
        getUserMenuTree(),
      ])
      this.userPerms = permRes.data.permissions || []
      // 使用 API 返回的动态菜单树，空数据时降级到内置兜底
      if (menuRes.data && Array.isArray(menuRes.data) && menuRes.data.length > 0) {
        this.menuItems = menuRes.data
      }
    } catch(e) {
      // 接口失败时保持 BUILTIN_MENUS 兜底
    }
    this.$watch('config', this.applyLogoStyle, { deep: true, immediate: true })
  },
  methods: {
    applyLogoStyle() {
      const ff = this.theme.logo_text_font_family
      const font = ff === 'system' ? '"Helvetica Neue", Helvetica, "PingFang SC", "Microsoft YaHei", sans-serif' : (ff || '')
      this.$nextTick(() => { const el = this.$el && this.$el.querySelector('.sidebar-logo'); if (el) el.style.fontFamily = font })
    },
    clickTopMenu(item, event) {
      this.activeTopMenu = item.name
      this.popupVisible = false
      if (!item.children || !item.children.length) {
        if (item.path) this.$router.push(item.path).catch(()=>{})
        return
      }
      this.popupItems = item.children
      this.$nextTick(() => {
        const el = event.currentTarget || this.$el.querySelector('.lr-menu-item.active')
        if (!el) return
        const rect = el.getBoundingClientRect()
        document.documentElement.style.setProperty('--submenu-hover-bg', this.theme.submenu_item_bg_hover || '#f5f7fa')
        document.documentElement.style.setProperty('--submenu-active-bg', this.theme.submenu_item_bg_active || '#ecf5ff')
        const sh = this.theme.submenu_popup_shadow
        const shadowMap = { none:'none', light:'0 2px 8px rgba(0,0,0,0.08)', medium:'0 6px 24px rgba(0,0,0,0.12)', heavy:'0 12px 40px rgba(0,0,0,0.18)' }
        this.popupStyle = {
          position: 'fixed', top: rect.top + 'px', left: (rect.right + 4) + 'px', zIndex: 1000,
          background: this.theme.sidebar_bg_color || '#304156',
          borderRadius: (this.theme.submenu_popup_radius || 8) + 'px',
          boxShadow: shadowMap[sh] || shadowMap.medium,
          minWidth: (this.theme.submenu_popup_min_width || 180) + 'px',
        }
        this.popupVisible = true
      })
    },
    closePopup() { this.popupVisible = false; this.popupItems = null },
    submenuItemStyle(isActive) {
      return { color: isActive ? (this.theme.sidebar_active_color || '#409EFF') : (this.theme.sidebar_text_color || '#303133') }
    },
    goTo(path) {
      // 外链（http/https 开头）新窗口打开，内部路由走 router.push
      if (/^https?:\/\//.test(path)) { window.open(path, '_blank'); this.closePopup(); return }
      this.$router.push(path).catch(()=>{}); this.closePopup()
    }
  },
}
</script>
<style scoped>
.sidebar { position: fixed; left: 0; top: 0; height: 100vh; z-index: 100; overflow-y: auto; overflow-x: hidden; transition: width var(--sidebar-anim-duration, 0.3s); box-sizing: border-box; }
.layout-left-right { display: flex; flex-direction: column; }
.sidebar-logo { text-align: center; user-select: none; overflow: hidden; white-space: nowrap; }
.sidebar-logo i { margin-right: 6px; vertical-align: middle; }
.sidebar-logo span { vertical-align: middle; }
/* el-menu 样式覆盖（深度选择器穿透scoped） */
.sidebar >>> .el-menu-item { height: var(--menu-item-height, 50px) !important; line-height: var(--menu-item-height, 50px) !important; font-size: var(--menu-text-size, 14px) !important; color: var(--sidebar-text, #bfcbd9) !important; }
.sidebar >>> .el-submenu__title { height: var(--menu-item-height, 50px) !important; line-height: var(--menu-item-height, 50px) !important; font-size: var(--menu-text-size, 14px) !important; color: var(--sidebar-text, #bfcbd9) !important; }
.sidebar >>> .el-menu-item i, .sidebar >>> .el-submenu__title i { font-size: var(--menu-icon-size, 18px) !important; }
.sidebar >>> .el-menu-item:hover, .sidebar >>> .el-submenu__title:hover { background-color: var(--sidebar-hover-bg, transparent) !important; color: var(--sidebar-text-hover, #ffffff) !important; }
.sidebar >>> .el-menu-item.is-active { color: var(--sidebar-active-color, #409EFF) !important; background-color: var(--sidebar-active-bg, rgba(64,158,255,0.1)) !important; }
.sidebar >>> .el-submenu .el-menu { background-color: var(--sidebar-submenu-bg, rgba(0,0,0,0.2)) !important; }
/* 悬停展开模式 */
.sidebar.hover-expand >>> .el-submenu .el-menu { display: none !important; }
.sidebar.hover-expand >>> .el-submenu:hover > .el-menu { display: block !important; }
/* 左一右子模式 */
.left-right-content { display: flex; flex-direction: row; min-height: 0; flex: 1; }
.left-menu-panel { flex-shrink: 0; overflow-y: auto; padding: 8px 0; }
.right-submenu-panel { flex: 1; overflow-y: auto; padding: 8px 0; }
/* 统一菜单项样式（左右一致） */
.lr-menu-item { display: flex; align-items: center; padding: 10px 16px; cursor: pointer; font-size: var(--menu-text-size, 14px); gap: 10px; transition: background 0.15s; min-height: var(--menu-item-height, 40px); }
.lr-menu-item:hover { background: rgba(255,255,255,0.08); }
.lr-menu-item.active { background: rgba(64,158,255,0.15); }
.lr-menu-icon { font-size: var(--menu-icon-size, 16px); flex-shrink: 0; }
.lr-menu-name { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.submenu-popup { position: fixed; padding: 6px 0; }
.submenu-popup .lr-menu-item { padding: 10px 20px; }
.popup-overlay { position: fixed; inset: 0; z-index: 999; }
</style>
