<template>
  <div class="layout-wrapper" :class="['layout-'+theme.layout_mode, { 'sidebar-right': theme.sidebar_position==='right', 'sidebar-collapsed': sidebarCollapsed, 'is-mobile': isMobile, 'is-tablet': isTablet, 'drawer-open': drawerOpen }]" :style="layoutStyle">
    <!-- 移动端抽屉遮罩 -->
    <div v-if="isMobile && drawerOpen" class="drawer-overlay" @click="drawerOpen = false"></div>
    
    <AppSidebar v-if="loaded" :collapsed="sidebarCollapsed || (isMobile && !drawerOpen)" :sidebar-width="sidebarWidth" :class="{ 'drawer-sidebar': isMobile }" />
    
    <div v-if="loaded" class="main-area" :style="mainAreaStyle">
      <!-- 试用期提示条（持续显示，功能可用） -->
      <div v-if="licenseTrial" class="license-trial-bar">
        <i class="el-icon-info"></i>
        <span class="license-warning-text">系统处于试用期，剩余 {{ licenseTrialDays }} 天，请及时输入授权码完成正式授权。</span>
        <el-button type="text" size="small" class="license-trial-link" @click="goLicense">前往授权</el-button>
      </div>
      <!-- 系统授权失效警告条（试用期结束且无有效授权码：功能被锁定） -->
      <div v-if="licenseExpired" class="license-warning-bar">
        <i class="el-icon-warning-outline"></i>
        <span class="license-warning-text">系统授权已失效，后台功能已被限制，请联系管理员更新激活码或续费授权。</span>
        <el-button type="text" size="small" class="license-warning-link" @click="goLicense">前往授权管理</el-button>
      </div>
      <AppNavbar v-if="showNavbar" :collapsed="sidebarCollapsed" :collapsible="theme.sidebar_collapsible" :is-mobile="isMobile" @toggle-sidebar="toggleSidebar" @refresh="refreshPage" @global-search="handleGlobalSearch" />
      <AppTagsView v-if="theme.tabs_show" :visited-tabs="visitedTabs" :active-tab="activeTab" @remove-tab="removeTab" />
      <main class="content" :class="{ 'table-adapt-scroll': isMobile && theme.mobile_table_adapt === 'scroll' }" :style="contentStyle"><router-view /></main>
      <AppFooter />
    </div>
  </div>
</template>
<script>
import { mapState } from 'vuex'
import AppSidebar from './components/Sidebar.vue'
import AppNavbar from './components/Navbar.vue'
import AppTagsView from './components/TagsView.vue'
import AppFooter from './components/Footer.vue'
import themeMixin from '@/mixins/theme'
import request from '@/api/request'
export default {
  name: 'MainLayout',
  components: { AppSidebar, AppNavbar, AppTagsView, AppFooter },
  mixins: [themeMixin],
  data() { return { sidebarCollapsed: false, visitedTabs: [], activeTab: '', isMobile: false, isTablet: false, drawerOpen: false, lastActive: Date.now(), idleAlerted: false, idleTimer: null, _idleTrack: null, licenseExpired: false, licenseTrial: false, licenseTrialDays: 0, licenseTimer: null } },
  computed: {
    ...mapState('user', ['userInfo']), ...mapState('theme', ['loaded', 'config']),
    mode() { return this.theme.layout_mode || 'classic' },
    showSidebar() { if (!this.theme.mobile_adaptive) return ['classic','sidebar','mixed','double'].includes(this.mode); if (this.isMobile) return this.theme.mobile_sidebar_behavior!=='hidden'; return ['classic','sidebar','mixed','double'].includes(this.mode) },
    showNavbar() { return ['classic','topbar','mixed'].includes(this.mode) },
    sidebarWidth() {
      if (this.isMobile && this.theme.mobile_sidebar_behavior==='drawer') return this.theme.sidebar_width || 220
      if (this.sidebarCollapsed || (this.isMobile && this.theme.mobile_menu_collapsed)) return this.theme.sidebar_collapsed_width || 64
      if (this.theme.menu_layout_mode === 'left_right') return this.theme.left_menu_width || 200
      return this.theme.sidebar_width
    },
    mainAreaStyle() {
      const s = { display: 'flex', flexDirection: 'column', minHeight: '100vh' }
      if (!this.isMobile && this.showSidebar) {
        if (this.theme.sidebar_position==='right') s.marginRight = this.sidebarWidth+'px'
        else s.marginLeft = this.sidebarWidth+'px'
      }
      return s
    },
    contentStyle() { 
      const s = { backgroundColor: this.theme.content_bg_color }
      // 内容区占满剩余空间，页脚始终推至页面最底部（不遮挡内容）
      s.flex = '1 1 auto'
      // content_padding 优先，兼容旧配置；无则用 content_padding_v/h
      if (this.theme.content_padding) {
        s.padding = this.theme.content_padding+'px'
      } else {
        s.padding = (this.theme.content_padding_v||20)+'px '+(this.theme.content_padding_h||20)+'px'
      }
      if (this.theme.content_bg_image) {
        s.backgroundImage = 'url('+this.theme.content_bg_image+')'
        s.backgroundSize = 'cover'
        s.backgroundPosition = 'center'
      }
      if (this.theme.content_min_height === 'viewport') {
        s.minHeight = 'calc(100vh - '+(this.theme.navbar_fixed!==false ? 60 : 0)+'px)'
      }
      // 页脚固定采用 sticky 粘性定位（文档流内不遮挡内容），无需额外 padding 避让
      return s
    },
    layoutStyle() { return { minHeight: this.theme.page_min_height?'100vh':'auto', backgroundImage: this.theme.page_bg_image?'url('+this.theme.page_bg_image+')':'none', backgroundRepeat: this.theme.page_bg_repeat, backgroundAttachment: this.theme.page_bg_fixed?'fixed':'scroll', backgroundColor: this.theme.page_bg_color||'#f0f2f5' } },
  },
  watch: {
    config: { deep: true, handler() { if (this.loaded) this.applyTheme() } },
    '$route.path': { immediate: true, handler(p) { this.addTab(p); this.activeTab = p; if (this.isMobile) this.drawerOpen = false } },
  },
  async created() {
    if (!this.$store.state.theme.loaded) await this.$store.dispatch('theme/loadConfig')
    this.applyTheme()
    if (this.theme.sidebar_default_collapsed) this.sidebarCollapsed = true
    this.checkScreen()
    window.addEventListener('resize', this.checkScreen)
    // 会话闲置提醒（安全策略 → 会话安全：session_timeout / session_idle_alert_minutes / session_idle_detect）
    const track = () => { this.lastActive = Date.now(); this.idleAlerted = false }
    window.addEventListener('mousemove', track)
    window.addEventListener('keydown', track)
    window.addEventListener('click', track)
    this._idleTrack = track
    this.idleTimer = setInterval(() => {
      try {
        const cfg = (this.$store.state.user.userInfo && this.$store.state.user.userInfo.session_config) || {}
        if (!cfg.idle_detect) return
        const timeoutMin = cfg.timeout_minutes || 30
        const alertMin = cfg.idle_alert_minutes || 5
        const threshold = Math.max(1, timeoutMin - alertMin) * 60000
        if (!this.idleAlerted && Date.now() - this.lastActive >= threshold) {
          this.idleAlerted = true
          this.$alert('您已长时间未操作，系统即将自动退出登录。继续操作可保持登录状态。', '即将超时', { confirmButtonText: '知道了', type: 'warning' }).catch(() => {})
        }
      } catch (e) {}
    }, 30000)
    // 系统授权状态检测（实时轮询：授权失效时显示常驻警告条）
    this.checkLicense()
    this.licenseTimer = setInterval(this.checkLicense, 30000)
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.checkScreen)
    if (this._idleTrack) {
      window.removeEventListener('mousemove', this._idleTrack)
      window.removeEventListener('keydown', this._idleTrack)
      window.removeEventListener('click', this._idleTrack)
    }
    if (this.idleTimer) clearInterval(this.idleTimer)
    if (this.licenseTimer) clearInterval(this.licenseTimer)
  },
  methods: {
    // 查询授权状态（实时）：trial 显示试用期提示条，expired 显示失效警告条
    async checkLicense() {
      try {
        const res = await request({ url: '/system/license/info', method: 'get', timeout: 10000 })
        const data = res.data || {}
        const wasExpired = this.licenseExpired
        this.licenseExpired = data.status === 'expired' || !data.valid
        this.licenseTrial = data.status === 'trial'
        this.licenseTrialDays = data.trial_days_left || 0
        if (this.licenseExpired && !wasExpired) {
          // 首次变为失效：弹出常驻通知
          this.$notify({
            title: '系统授权已失效',
            message: '试用期已结束，后台功能已被限制，请立即输入授权码。',
            type: 'error',
            duration: 0,
          })
        }
      } catch (e) {
        // 未登录/网络异常时静默（不做处理）
      }
    },
    // 跳转授权管理页
    goLicense() {
      this.$router.push('/license')
    },
    checkScreen() {
      const w = window.innerWidth
      const mb = this.theme.mobile_breakpoint || 768
      const tb = this.theme.tablet_breakpoint || 1024
      this.isMobile = w < mb
      this.isTablet = w >= mb && w < tb
      if (!this.isMobile) this.drawerOpen = false
    },
    toggleSidebar() {
      if (this.isMobile && this.theme.mobile_sidebar_behavior==='drawer') { this.drawerOpen = !this.drawerOpen; return }
      this.sidebarCollapsed = !this.sidebarCollapsed
    },
    handleGlobalSearch() { if (window.__scGlobalSearch) window.__scGlobalSearch(); else this.$message.info('全局搜索功能开发中') },
    refreshPage() { this.$router.go(0) },
    addTab(p) { if (!p || !this.visitedTabs.some(t => t.path === p)) { this.visitedTabs.push({ path: p, title: this.$route.meta?.title || '' }) }; if (this.visitedTabs.length > (this.theme.tabs_max_count || 20)) this.visitedTabs.shift() },
    removeTab(p) { if (this.visitedTabs.length <= 1) return; const i = this.visitedTabs.findIndex(t => t.path === p); if (i !== -1) { this.visitedTabs.splice(i, 1); if (this.activeTab === p) { const n = this.visitedTabs[i] || this.visitedTabs[i-1]; if (n) this.$router.push(n.path) } } },
  },
}
</script>
<style scoped>
/* 系统授权试用期提示条（黄色常驻） */
.license-trial-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  background: #fdf6ec;
  border-bottom: 1px solid #faecd8;
  color: #e6a23c;
  font-size: 13px;
  flex-shrink: 0;
}

.license-trial-bar .el-icon-info {
  font-size: 16px;
}

.license-trial-link {
  color: #e6a23c;
}

/* 系统授权失效警告条（红色常驻） */
.license-warning-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 16px;
  background: #fef0f0;
  border-bottom: 1px solid #fde2e2;
  color: #f56c6c;
  font-size: 13px;
  flex-shrink: 0;
}

.license-warning-bar .el-icon-warning-outline {
  font-size: 16px;
}

.license-warning-text {
  flex: 1;
}

.license-warning-link {
  color: #f56c6c;
}
.layout-wrapper { min-height: 100vh; display: flex; width: 100%; }
.layout-wrapper.sidebar-right { flex-direction: row-reverse; }
.layout-topbar .main-area { margin-left: 0 !important; margin-right: 0 !important; }
.layout-sidebar .navbar { display: none; }
.main-area { width: 100%; }
.layout-double .main-area { flex-direction: row; }
.layout-double .content { flex: 1; }
/* 移动端 */
.is-mobile .content { padding: 12px !important; }
.is-mobile .tags-view { display: none; }
.is-mobile .navbar { height: 50px !important; }
/* 抽屉式侧边栏 */
.drawer-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.4); z-index: 200; }
.drawer-sidebar { position: fixed !important; left: 0; top: 0; height: 100vh; z-index: 201 !important; transform: translateX(0); transition: transform 0.3s; }
.drawer-sidebar ~ .main-area { margin-left: 0 !important; }
/* 简化顶栏按钮文字 */
.is-mobile .navbar .user-name { display: none; }
.is-mobile .navbar .collapse-btn { display: none; }
/* 表格水平滚动 */
.table-adapt-scroll >>> .el-table { overflow-x: auto; display: block; }
</style>
