<template>
  <header class="navbar" :style="navbarStyle">
    <div class="navbar-left">
      <el-button v-if="collapsible" type="text" class="collapse-btn" @click="$emit('toggle-sidebar')">
        <i :class="collapsed ? 'el-icon-s-unfold' : 'el-icon-s-fold'" />
      </el-button>
      <el-breadcrumb v-if="theme.breadcrumb_show" :separator="theme.breadcrumb_separator || '/'">
        <el-breadcrumb-item v-for="(crumb, idx) in breadcrumbs" :key="idx" v-show="idx < (theme.breadcrumb_max_level||4)" :to="crumb.path ? { path: crumb.path } : undefined">
          <i v-if="idx === 0 && theme.breadcrumb_home_icon" class="el-icon-s-home" />
          {{ theme.breadcrumb_show_current !== false ? crumb.name : '' }}
        </el-breadcrumb-item>
      </el-breadcrumb>
    </div>
    <div class="navbar-right" :style="{gap:(theme.navbar_element_gap||12)+'px'}">
      <notification-bell class="navbar-right-item" />
      <!-- 更新提示角标：检测到新版本显示红点 + 版本号 -->
      <el-tooltip v-if="updateBadge.has_update" content="发现新版本，点击前往系统更新" placement="bottom">
        <el-button type="text" class="navbar-btn update-badge" :size="btnSize" @click="$router.push('/system-update')">
          <el-badge :value="'v' + updateBadge.new_version" type="danger" class="update-badge-inner">
            <i class="el-icon-refresh" />
          </el-badge>
        </el-button>
      </el-tooltip>
      <template v-for="el in navbarRightElements">
        <el-tooltip v-if="el==='global_search' && theme.global_search_show" :key="el" :content="theme.global_search_placeholder+(theme.global_search_shortcut?' ('+theme.global_search_shortcut+')':'')" placement="bottom">
          <el-button type="text" class="navbar-btn" :size="btnSize" @click="$emit('global-search')"><i class="el-icon-search" /></el-button>
        </el-tooltip>
        <el-tooltip v-if="el==='fullscreen'" :key="el" content="全屏" placement="bottom">
          <el-button type="text" class="navbar-btn" :size="btnSize" @click="toggleFullscreen"><i class="el-icon-full-screen" /></el-button>
        </el-tooltip>
        <el-tooltip v-if="el==='refresh'" :key="el" content="刷新" placement="bottom">
          <el-button type="text" class="navbar-btn" :size="btnSize" @click="$emit('refresh')"><i class="el-icon-refresh" /></el-button>
        </el-tooltip>
      </template>
      <span v-if="theme.user_avatar_show" class="navbar-right-item">
        <el-dropdown trigger="click" @command="handleCommand">
          <span class="user-trigger">
            <el-avatar :size="avatarSize" :src="userInfo?.avatar" :shape="theme.user_avatar_round!==false?'circle':'square'" :style="avatarStyle">{{ avatarText }}</el-avatar>
            <span v-if="theme.navbar_btn_style!=='icon'" class="user-name">{{ displayName }}</span>
            <i class="el-icon-arrow-down el-icon--right" />
          </span>
          <el-dropdown-menu slot="dropdown">
            <el-dropdown-item v-if="theme.user_dropdown_show_role" disabled><span style="color:#909399;font-size:12px">{{ userRoleText }}</span></el-dropdown-item>
            <el-dropdown-item command="checkUpdate"><i class="el-icon-refresh" /> 检查更新</el-dropdown-item>
            <el-dropdown-item command="profile"><i class="el-icon-s-custom" /> 个人中心</el-dropdown-item>
            <el-dropdown-item v-if="userDropdownItems.includes('change_password')" command="changePassword"><i class="el-icon-key" /> 修改密码</el-dropdown-item>
            <el-dropdown-item v-if="userDropdownItems.includes('logout')" command="logout" divided><i class="el-icon-switch-button" /> 退出登录</el-dropdown-item>
          </el-dropdown-menu>
        </el-dropdown>
      </span>
    </div>

    <!-- 强制更新弹窗（不可关闭，引导立即更新） -->
    <el-dialog title="系统强制更新" :visible.sync="forceUpdate.visible" width="480px" :close-on-click-modal="false" :close-on-press-escape="false" :show-close="false" append-to-body>
      <div class="force-update-body">
        <div class="force-version">发现新版本 v{{ forceUpdate.version }}</div>
        <div class="force-warning">该版本为<el-tag type="danger" size="mini">强制更新</el-tag>，为保障系统安全与正常使用，请立即更新。</div>
        <div v-if="forceUpdate.changelog" class="force-changelog">
          <div class="force-label">更新内容：</div>
          <pre>{{ forceUpdate.changelog }}</pre>
        </div>
      </div>
      <span slot="footer">
        <el-button type="primary" @click="goForceUpdate">立即更新</el-button>
      </span>
    </el-dialog>
  </header>
</template>
<script>
import { mapState } from 'vuex'
import themeMixin from '@/mixins/theme'
import NotificationBell from '@/views/system/notification/NotificationBell.vue'
import request from '@/api/request'
export default {
  name: 'AppNavbar', mixins: [themeMixin], components: { NotificationBell },
  props: { collapsed: { type: Boolean, default: false }, collapsible: { type: Boolean, default: true }, isMobile: { type: Boolean, default: false } },
  data () {
    return { checking: false, updateBadge: { has_update: false, new_version: '' }, forceUpdate: { visible: false, version: '', changelog: '' } }
  },
  created () {
    this.loadUpdateBadge()
  },
  beforeDestroy () {},
  computed: {
    ...mapState('user', ['userInfo']), ...mapState('theme', ['config']),
    btnSize() { return { small:'mini', default:'small', large:'medium' }[this.theme.navbar_btn_size] || 'small' },
    displayName() { return this.userInfo?.real_name || this.userInfo?.username || '加载中...' },
    avatarText() { const n = this.displayName; return n && n !== '加载中...' ? n.charAt(0).toUpperCase() : '?' },
    avatarStyle() { return { backgroundColor: this.theme.brand_color, verticalAlign: 'middle', marginRight: '6px' } },
    avatarSize() { const s = this.theme.user_avatar_size; return s === 'small' ? 28 : s === 'large' ? 36 : 32 },
    breadcrumbs() {
      const m = this.$route.matched.filter(r => r.path)
      const l = []
      for (const r of m) { if (r.path !== '/') l.push({name: r.meta?.title || r.name || r.path, path: r.path}) }
      return l
    },
    navbarRightElements() { return Array.isArray(this.theme.navbar_right_elements) ? this.theme.navbar_right_elements : [] },
    userDropdownItems() { return this.theme.user_dropdown_items || ['profile','logout'] },
    userRoleText() { return this.userInfo?.roles?.length ? this.userInfo.roles.map(r => r.name || r).join(', ') : '' },
    navbarStyle() {
      const c = this.theme
      const h = c.navbar_height === 'short' ? '50px' : c.navbar_height === 'tall' ? '70px' : '60px'
      return {
        backgroundColor: c.navbar_bg_color, color: c.navbar_text_color,
        height: h, lineHeight: h,
        boxShadow: c.navbar_bottom_shadow ? '0 1px 4px ' + c.navbar_shadow_color : 'none',
        opacity: c.navbar_bg_opacity,
        backdropFilter: c.navbar_bg_blur && c.navbar_bg_opacity < 1 ? 'blur(' + c.navbar_blur_strength + 'px)' : 'none',
        position: c.navbar_fixed !== false ? 'sticky' : 'static',
      }
    },
  },
  methods: {
    toggleFullscreen() { if (!document.fullscreenElement) document.documentElement.requestFullscreen(); else document.exitFullscreen() },
    handleCommand(cmd) {
      if (cmd==='checkUpdate') this.handleCheckUpdate()
      else if (cmd==='profile') this.$router.push('/profile')
      else if (cmd==='changePassword') this.$router.push('/profile')
      else if (cmd==='logout') { this.$store.dispatch('user/logout'); this.$router.push('/login'); this.$message.success('已退出登录') }
    },
    // 加载更新角标（读本地缓存，不触发 aa 请求）
    async loadUpdateBadge() {
      try {
        const r = await request({ url: '/system/update/status', method: 'get' })
        if (r.code === 0 && r.data && r.data.has_update) {
          this.updateBadge = { has_update: true, new_version: r.data.new_version || '' }
          // 强制更新：弹不可关闭的提示窗，引导立即更新
          if (Number(r.data.force) === 1) {
            this.forceUpdate = {
              visible: true,
              version: r.data.new_version || '',
              changelog: r.data.changelog || r.data.title || '',
            }
          }
        }
      } catch (e) {
        // 未登录或接口异常：静默
      }
    },
    goForceUpdate() {
      this.forceUpdate.visible = false
      this.$router.push('/system-update')
    },
    // 检查 aa 平台发布的软件更新
    async handleCheckUpdate() {
      if (this.checking) return
      this.checking = true
      try {
        const r = await request({ url: '/system/update/refresh', method: 'post' })
        if (r.code === 0) {
          const d = r.data || {}
          if (d.has_update) {
            const content = (d.changelog || d.title || '').slice(0, 300) || '系统有新版本，请前往「系统维护 → 系统更新」执行更新。'
            this.$alert('发现新版本 v' + d.new_version + '\n\n' + content, '系统更新', {
              confirmButtonText: '去更新', cancelButtonText: '稍后', type: 'warning', center: true
            }).then(() => this.$router.push('/system-update')).catch(() => {})
          } else {
            this.$message({ message: '当前已是最新版本 v' + d.current_version, type: 'success', duration: 1500 })
          }
        } else {
          this.$message.error(r.msg || '检查更新失败')
        }
      } catch (e) {
        this.$message.error('检查更新失败，请稍后重试')
      } finally {
        this.checking = false
      }
    },
  },
}
</script>
<style scoped>
.navbar { display:flex; align-items:center; justify-content:space-between; padding:0 20px; flex-shrink:0; top:0; z-index:99; }
.navbar-left { flex:1; display:flex; align-items:center; gap:8px; }
.navbar-right { flex-shrink:0; display:flex; align-items:center; }
.navbar-btn { font-size:18px; padding:8px; color:inherit; }
.navbar-btn:hover { color:var(--brand-color,#409EFF); }
.navbar-right-item { display:inline-flex; align-items:center; }
.user-trigger { cursor:pointer; font-size:14px; display:inline-flex; align-items:center; color:inherit; }
.user-trigger:hover { color:var(--brand-color,#409EFF); }
.user-name { margin:0 4px; }
.collapse-btn { font-size:20px; padding:8px; }
.update-badge { color: #F56C6C; }
.update-badge .el-badge__content { font-size: 10px; }
.force-update-body { padding: 4px 0; }
.force-version { font-size: 20px; font-weight: bold; color: #F56C6C; margin-bottom: 10px; }
.force-warning { color: #606266; line-height: 1.8; margin-bottom: 10px; }
.force-changelog { background: #F8F9FB; border-radius: 6px; padding: 10px 14px; }
.force-label { font-size: 13px; color: #909399; margin-bottom: 4px; }
.force-changelog pre { margin: 0; white-space: pre-wrap; word-break: break-word; color: #606266; font-size: 13px; line-height: 1.7; font-family: inherit; }
</style>
