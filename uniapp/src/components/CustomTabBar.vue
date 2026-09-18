<template>
  <view class="custom-tabbar" v-if="tabs.length > 0" :style="tabbarStyle">
    <view
      v-for="(tab, idx) in tabs"
      :key="idx"
      class="tab-item"
      :class="{ active: isActive(tab) }"
      @click="switchTab(tab)"
    >
      <image
        v-if="isImageUrl(getIcon(tab))"
        :src="toFullUrl(getIcon(tab))"
        mode="aspectFit"
        class="tab-icon"
      ></image>
      <MIcon
        v-else-if="getMIconName(getIcon(tab))"
        :name="getMIconName(getIcon(tab))"
        :color="isActive(tab) ? activeColor : textColor"
        :size="22"
        :weight="2"
        class="tab-icon"
      ></MIcon>
      <u-icon
        v-else-if="isUiIcon(getIcon(tab))"
        :name="getIcon(tab)"
        :color="isActive(tab) ? activeColor : textColor"
        size="24"
        class="tab-icon"
      ></u-icon>
      <text v-else class="tab-icon-text" :style="{ color: isActive(tab) ? activeColor : textColor }">
        {{ getDisplayIcon(tab) }}
      </text>
      <text class="tab-label" :style="{ color: isActive(tab) ? activeColor : textColor }">{{ tab.text || tab.name || 'Tab' }}</text>
    </view>
  </view>
</template>

<script>
// tab 配置缓存：避免切换页面时底部菜单重新请求导致闪烁
let tabCache = { key: '', data: null }
import { getDiyPage } from '@/api/diy.js'
import { BASE_URL, get } from '@/utils/request.js'
import uIcons from 'uview-plus/components/u-icon/icons.js'

// MIcon 图标名（与 components/MIcon.vue 内置图标集一致）
const M_ICON_NAMES = ['home','users','chat','user','bell','grid','list','settings','gear','clipboard','factory','inbox','alert','trend','chart','file','zap','scale','trophy','medal','shield','book','wrench','megaphone','mail','search','close','check','checkCircle','xmark','arrowRight','chevronRight','phone','link','camera','download','location','edit','folder','device','puzzle','calendar','clock','send','sun','moon','star','graduate','sparkles','box','building','refresh','info','flame','wallet','eye','heart','award','alertCircle','cart','shop','message','dashboard','plus','minus','menu','more','settings2']
// uview/旧图标名 → MIcon 名映射
const UI_ICON_MAP = {
  'home': 'home', 'home-fill': 'home',
  'account': 'user', 'account-fill': 'user',
  'person': 'user', 'person-fill': 'user', 'user': 'user',
  'account-fill-fill': 'user',
  'bell': 'bell', 'bell-fill': 'bell', 'notification': 'bell',
  'message': 'chat', 'chat': 'chat', 'chat-fill': 'chat', 'msg': 'chat', 'weixin-fill': 'chat',
  'grid': 'grid', 'grid-fill': 'grid', 'apps': 'grid', 'app': 'grid',
  'list': 'list', 'list-dot': 'list', 'bars': 'list', 'menu': 'menu', 'list-view': 'list',
  'setting': 'settings', 'setting-fill': 'settings', 'settings': 'settings',
  'bag': 'box', 'shopping-cart': 'cart', 'cart': 'cart', 'cart-fill': 'cart', 'shopping-cart-fill': 'cart',
  'order': 'clipboard', 'file-text': 'file', 'file': 'file', 'folder': 'folder', 'folder-open': 'folder',
  'calendar': 'calendar', 'clock': 'clock', 'clock-fill': 'clock',
  'search': 'search', 'plus': 'plus', 'minus': 'minus', 'close': 'close', 'close-circle': 'xmark',
  'checkmark': 'check', 'checkmark-circle': 'checkCircle', 'checkmark-circle-fill': 'checkCircle',
  'arrow-right': 'arrowRight', 'arrow-rightward': 'arrowRight', 'arrow-left': 'arrowRight',
  'arrow-down': 'arrowRight', 'arrow-up': 'arrowRight', 'arrow-right-fill': 'arrowRight',
  'map': 'location', 'map-fill': 'location', 'location': 'location', 'map-pin': 'location',
  'phone': 'phone', 'phone-fill': 'phone', 'camera': 'camera', 'camera-fill': 'camera',
  'photo': 'camera', 'image': 'camera', 'pic': 'camera',
  'download': 'download', 'download-fill': 'download', 'upload': 'download',
  'link': 'link', 'share': 'link', 'external-link': 'link',
  'edit-pen': 'edit', 'edit': 'edit', 'edit-pen-fill': 'edit',
  'trash': 'xmark', 'trash-fill': 'xmark', 'delete': 'xmark', 'minus-circle': 'xmark',
  'info': 'info', 'info-circle': 'info', 'question': 'info', 'error': 'alert', 'error-circle': 'alert', 'warning': 'alert', 'warn': 'alert', 'alert': 'alert', 'alert-circle': 'alertCircle',
  'star': 'star', 'star-fill': 'star', 'heart': 'heart', 'heart-fill': 'heart',
  'eye': 'eye', 'eye-fill': 'eye', 'lock': 'shield', 'shield': 'shield', 'shield-fill': 'shield', 'security': 'shield',
  'book': 'book', 'book-fill': 'book', 'red-packet': 'book', 'calendar-fill': 'calendar',
  'fire': 'flame', 'flame': 'flame', 'flash': 'zap', 'lightning': 'zap', 'thunder': 'zap',
  'trend': 'trend', 'trending-up': 'trend', 'bar-chart': 'chart', 'pie-chart': 'chart', 'chart': 'chart', 'data-analysis': 'chart',
  'server': 'building', 'building': 'building', 'shop': 'shop', 'shop-fill': 'shop', 'coupon': 'box',
  'kefu-ermai': 'chat', 'chat-fill-2': 'chat', 'phone-fill-2': 'phone', 'email': 'mail', 'mail': 'mail',
  'pushpin': 'location', 'tag': 'info', 'tags': 'info', 'gift': 'sparkles', 'gift-fill': 'sparkles',
  'play': 'arrowRight', 'pause': 'info', 'more-dot-fill': 'more', 'more-circle': 'more',
  'level': 'trophy', 'medal': 'medal', 'award': 'award', 'integral': 'star',
  'reload': 'refresh', 'refresh': 'refresh', 'refresh-fill': 'refresh',
  'gear': 'gear', 'gear-fill': 'gear', 'zhuanfa': 'send', 'send': 'send', 'paperplane': 'send',
  'spinner': 'refresh', 'loading': 'refresh', 'checkmark-circle-fill-2': 'checkCircle',
  'volume': 'megaphone', 'volume-fill': 'megaphone', 'mic': 'megaphone', 'rmb': 'wallet', 'rmb-circle': 'wallet', 'wallet': 'wallet', 'wallet-fill': 'wallet', 'gold': 'wallet',
  'red-packet-fill': 'sparkles', 'coupon-fill': 'box', 'gift-fill-2': 'sparkles',
  'qrscan': 'search', 'scan': 'search', 'kefu-ermai-fill': 'chat', 'man': 'user', 'woman': 'user'
}

export default {
  name: 'CustomTabBar',
  props: {
    currentPath: { type: String, default: '' },
    currentType: { type: String, default: '' }
  },
  data() {
    return {
      tabs: [],
      bgColor: '#FFFFFF',
      textColor: '#999999',
      activeColor: '#4F46E5',
      iconSize: 24,
      fontSize: 10,
      dividerColor: '#E8ECF1',
      showDivider: true,
      loaded: false,
      cacheKey: '',
      // 悬浮风格支持（对齐 CRMEB：navConfig=1 悬浮圆角）
      navConfig: 0,
      bgColor2: '#FFFFFF',
      fillet: 0,
      bottomGap: 0
    }
  },
  computed: {
    tabbarStyle() {
      // navConfig=1 悬浮圆角风格：背景、圆角、左右边距
      if (this.navConfig === 1) {
        return {
          background: this.bgColor2,
          borderTop: 'none',
          borderRadius: (this.fillet || 16) + 'px',
          left: '8px',
          right: '8px',
          bottom: (this.bottomGap || 8) + 'px',
          boxShadow: '0 -2px 12px rgba(0,0,0,0.08)',
          margin: '0 8px'
        }
      }
      return {
        background: this.bgColor,
        borderTop: this.showDivider ? `1px solid ${this.dividerColor}` : 'none'
      }
    }
  },
  mounted() {
    this.loadTabConfig()
  },
  methods: {
    /** 获取 tab 跳转路径（兼容编辑器 pageFoot 的 link 字段 与 diy_pages 的 path 字段） */
    getTabPath(tab) {
      if (!tab) return ''
      return tab.path || tab.link || ''
    },
    /** 判断tab是否为激活状态 */
    isActive(tab) {
      const path = this.getTabPath(tab)
      if (!path) return false
      // 优先用 type 参数判断（所有tab共用 /pages/diy/index 路径时）
      const tabType = this.getTypeFromPath(path)
      if (tabType) {
        return tabType === this.currentType
      }
      // 兜底：比较路径（忽略首尾斜杠）
      const a = this.currentPath.replace(/^\/+|\/+$/g, '')
      const b = path.replace(/^\/+|\/+$/g, '')
      return a === b
    },
    /** 从路径提取 type 参数 */
    getTypeFromPath(path) {
      if (!path) return ''
      const m = String(path).match(/[?&]type=([^&]+)/)
      return m ? m[1] : ''
    },
    /** 获取当前显示的图标（激活优先用 activeIcon；兼容 CRMEB imgList[0]=选中 imgList[1]=普通） */
    getIcon(tab) {
      if (!tab) return ''
      if (this.isActive(tab)) {
        if (tab.activeIcon) return tab.activeIcon
        if (Array.isArray(tab.imgList) && tab.imgList[0]) return tab.imgList[0]
      }
      if (tab.icon) return tab.icon
      if (Array.isArray(tab.imgList) && tab.imgList[1]) return tab.imgList[1]
      return ''
    },
    /** 获取 MIcon 图标名：uview 名映射 / MIcon 原生名，均返回 MIcon 名；否则返回 '' */
    getMIconName(icon) {
      if (!icon) return ''
      if (M_ICON_NAMES.indexOf(icon) >= 0) return icon
      if (UI_ICON_MAP[icon]) return UI_ICON_MAP[icon]
      // 兼容 -fill 后缀
      if (icon.endsWith('-fill')) {
        const base = icon.slice(0, -5)
        if (M_ICON_NAMES.indexOf(base) >= 0) return base
        if (UI_ICON_MAP[base]) return UI_ICON_MAP[base]
      }
      return ''
    },
    /** text 兜底分支显示值：无效图标名（纯字母但非 uview 有效图标）回退默认，合法文本/emoji 原样显示 */
    getDisplayIcon(tab) {
      const icon = this.getIcon(tab)
      if (!icon) return '📌'
      if (/^[a-zA-Z0-9-]+$/.test(icon) && !uIcons['uicon-' + icon]) return '📌'
      return icon
    },
/** 将相对路径转为完整URL（小程序不支持 /uploads 相对路径） */
toFullUrl(val) {
  if (!val) return ''
  if (val.startsWith('http://') || val.startsWith('https://') || val.startsWith('data:')) return val
  if (val.startsWith('/')) return BASE_URL + val
  return val
},
    isImageUrl(val) {
      return val && (val.startsWith('http://') || val.startsWith('https://') || val.startsWith('/uploads') || val.startsWith('data:'))
    },
    /** uview-plus 图标名判断（如 home/account/bell；无效名如 contaca 会被排除，避免 u-icon 渲染出英文字母） */
    isUiIcon(val) {
      return !!val && !this.isImageUrl(val) && /^[a-zA-Z0-9-]+$/.test(val) && !!uIcons['uicon-' + val]
    },
    async loadTabConfig() {
      if (this.loaded) return
      this.loaded = true
      const token = uni.getStorageSync('token') || ''
      this.cacheKey = token ? token.slice(-8) : 'anon'
      const key = this.cacheKey
      // 1) 内存缓存命中：同步渲染（切换页面不闪烁）
      if (tabCache.key === key && tabCache.data && tabCache.data.tabs && tabCache.data.tabs.length) {
        this.applyTabs(tabCache.data)
        return
      }
      // 2) 本地缓存命中：同步渲染 + 后台静默刷新
      try {
        const ls = uni.getStorageSync('sc_tab_config_' + key)
        if (ls && ls.tabs && ls.tabs.length) {
          tabCache = { key: key, data: ls }
          this.applyTabs(ls)
          this.fetchTabConfig(key)
          return
        }
      } catch (e) {}
      // 3) 首次加载：请求后端
      this.fetchTabConfig(key)
    },
    /** 应用 tab 配置（同步渲染，幂等） */
    applyTabs(cfg) {
      if (!cfg || !Array.isArray(cfg.tabs) || !cfg.tabs.length) return
      this.tabs = cfg.tabs
      if (cfg.bgColor) this.bgColor = cfg.bgColor
      if (cfg.textColor) this.textColor = cfg.textColor
      if (cfg.activeColor) this.activeColor = cfg.activeColor
      if (typeof cfg.navConfig !== 'undefined') this.navConfig = cfg.navConfig
      if (cfg.bgColor2) this.bgColor2 = cfg.bgColor2
      if (typeof cfg.fillet !== 'undefined') this.fillet = cfg.fillet
      if (typeof cfg.bottomGap !== 'undefined') this.bottomGap = cfg.bottomGap
    },
    /** 请求后端 tab 配置并写入缓存 */
    async fetchTabConfig(key) {
      let data = null
      try {
        // D方案：优先读取后端底部导航配置（app_tab_config，已按登录态/角色过滤）
        const r = await get('/api/mobile/tab-config')
        if (r.code === 0 && r.data && Array.isArray(r.data.list) && r.data.list.length) {
          data = {
            tabs: r.data.list.map(t => ({
              name: t.title,
              text: t.title,
              icon: t.icon || '',
              activeIcon: t.icon_active || t.icon || '',
              path: t.path || t.page_path || ''
            }))
          }
        }
      } catch (e) {}
      // 回退：DIY 页面 pageFoot（编辑器配置的底部导航）
      if (!data) {
        try {
          const res = await getDiyPage('home')
          if (res.code === 0 && res.data && res.data.items) {
            // 兼容新结构（CRMEB name=pageFoot / 旧结构 type=bottom-nav）
            const bottomNav = res.data.items.find(i => i.name === 'pageFoot' || i.type === 'bottom-nav')
            if (bottomNav) {
              // CRMEB 结构：menuList 直接是数组；旧结构：data.items
              const menuList = bottomNav.menuList || bottomNav.data?.items || []
              data = {
                tabs: menuList,
                bgColor: bottomNav.bgColor?.color?.[0]?.item || bottomNav.data?.bgColor || '#FFFFFF',
                textColor: bottomNav.txtColor?.color?.[0]?.item || bottomNav.data?.textColor || '#999999',
                activeColor: bottomNav.activeTxtColor?.color?.[0]?.item || bottomNav.data?.activeColor || '#4F46E5'
              }
              // 悬浮风格（对齐 CRMEB：navConfig=1 悬浮 / navStyleConfig 导航样式）
              if (bottomNav.navConfig && typeof bottomNav.navConfig.tabVal !== 'undefined') data.navConfig = bottomNav.navConfig.tabVal
              else if (typeof bottomNav.navConfig !== 'undefined') data.navConfig = bottomNav.navConfig
              const bgColor2 = bottomNav.bgColor2?.color?.[0]?.item || bottomNav.data?.bgColor2 || '#FFFFFF'
              if (bgColor2) data.bgColor2 = bgColor2
              if (bottomNav.fillet && typeof bottomNav.fillet.val !== 'undefined') data.fillet = bottomNav.fillet.val
              if (bottomNav.bottomGap && typeof bottomNav.bottomGap.val !== 'undefined') data.bottomGap = bottomNav.bottomGap.val
            }
          }
        } catch (e) {
          console.error('加载底部导航配置失败', e)
        }
      }
      if (data && Array.isArray(data.tabs) && data.tabs.length) {
        tabCache = { key: key, data: data }
        try { uni.setStorageSync('sc_tab_config_' + key, data) } catch (e) {}
        this.applyTabs(data)
      }
    },
    switchTab(tab) {
      const path = this.getTabPath(tab)
      if (!path || path === this.currentPath) return
      // 统一用 reLaunch 触发路由跳转（H5 与小程序均生效，立即切换页面）
      uni.reLaunch({
        url: path,
        fail: (err) => {
          console.error('reLaunch失败', path, err)
          // 兜底：H5 直接改 hash
          // #ifdef H5
          window.location.hash = '#/' + (path.startsWith('/') ? path : '/' + path).slice(1)
          // #endif
        }
      })
    }
  }
}
</script>

<style scoped>
.custom-tabbar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: 999;
  display: flex;
  padding: 4px 0;
  padding-bottom: calc(4px + env(safe-area-inset-bottom));
}
.tab-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 2px 0;
  transition: transform 0.2s ease;
}
.tab-item.active { transform: translateY(-2px); }
.tab-item.active .tab-label { font-weight: 600; }
.tab-item.active .tab-icon, .tab-item.active .tab-icon-text { transform: scale(1.1); }
.tab-icon {
  width: 24px;
  height: 24px;
  display: block;
  margin-bottom: 1px;
  transition: transform 0.2s ease;
}
.tab-icon-text {
  font-size: 20px;
  line-height: 24px;
  margin-bottom: 1px;
}
.tab-label {
  font-size: 10px;
  line-height: 1.2;
}
</style>
