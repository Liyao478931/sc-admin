// ============================================================================
// 文件路径：src/main.js
// 应用入口 + 全局路由拦截
// ============================================================================

import { createSSRApp } from 'vue'
import { createPinia } from 'pinia'
import uviewPlus from 'uview-plus'
import App from './App.vue'
import { PAGE_PATHS } from '@/constants/pages'
import { goLogin } from '@/utils/navigate'
import MIcon from '@/components/MIcon.vue'

// 无需登录即可访问的白名单页面
const WHITE_LIST = [
  PAGE_PATHS.LOGIN,       // 登录页
  PAGE_PATHS.SPLASH,      // 启动页
  PAGE_PATHS.DIY_INDEX,   // DIY 入口（页面内组件自行校验）
]

// 校验登录态
function isLoggedIn() {
  return !!(uni.getStorageSync('access_token') || uni.getStorageSync('token'))
}

// 全局混入：启用小程序分享（否则页面右上角提示"当前页面不可转发"）
const shareMixin = {
  // #ifdef MP-WEIXIN
  onShareAppMessage() {
    return {
      title: '企业管理系统',
      path: '/pages/login/index'
    }
  },
  onShareTimeline() {
    return { title: '企业管理系统' }
  }
  // #endif
}

// 获取路径的基础部分（去掉 query 参数）
function getBasePath(url) {
  return (url || '').split('?')[0]
}

// 初始化全局路由拦截
function setupRouteInterceptor() {
  const methods = ['navigateTo', 'redirectTo', 'reLaunch', 'switchTab']
  methods.forEach(method => {
    uni.addInterceptor(method, {
      invoke(args) {
        const url = args.url || ''
        const base = getBasePath(url)
        // 白名单直接放行
        if (WHITE_LIST.includes(base)) return
        // 已登录放行
        if (isLoggedIn()) return
        // 未登录：阻止跳转，跳登录页
        uni.showToast({ title: '请先登录', icon: 'none' })
        // 记录原目标，登录后可返回
        uni.setStorageSync('redirect_after_login', url)
        setTimeout(() => goLogin(), 300)
        return false
      }
    })
  })
}

uni.$base = (typeof window !== 'undefined' && window.location && window.location.origin) ? window.location.origin : (import.meta.env.VITE_API_BASE || 'https://qq.yywyrh.cn')

export function createApp() {
  const app = createSSRApp(App)
  const pinia = createPinia()
  app.use(pinia)
  app.use(uviewPlus)
  app.component('MIcon', MIcon)
  // 全局混入：小程序分享
  app.mixin(shareMixin)
  setupRouteInterceptor()
  return { app, pinia }
}
