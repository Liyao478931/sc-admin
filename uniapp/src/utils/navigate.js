// ============================================================================
// 文件路径：src/utils/navigate.js
// 统一跳转工具函数 - 所有路径从常量读取，不硬编码
// ============================================================================

import { PAGE_PATHS, TAB_PATHS } from '@/constants/pages'
import { buildQuery, joinPath } from '@/utils/url'

// 登录状态直接从本地存储读取（避免 Pinia 初始化时序问题）
function isLoggedIn() {
  return !!(uni.getStorageSync('access_token') || uni.getStorageSync('token'))
}

/**
 * 页面跳转（保留当前页面）
 * @param {string} path 目标路径（建议从 PAGE_PATHS 读取）
 * @param {Object} params 查询参数
 * @param {Object} options uni.navigateTo 额外配置
 * @returns {Promise}
 */
export function navigateTo(path, params = {}, options = {}) {
  const url = joinPath(path, params)
  return new Promise((resolve, reject) => {
    uni.navigateTo({
      url,
      ...options,
      success: resolve,
      fail: (err) => {
        console.error('navigateTo 失败:', url, err)
        uni.showToast({ title: '页面跳转失败', icon: 'none' })
        reject(err)
      }
    })
  })
}

/**
 * 页面重定向（关闭当前页面）
 * @param {string} path 目标路径
 * @param {Object} params 查询参数
 * @param {Object} options uni.redirectTo 额外配置
 * @returns {Promise}
 */
export function redirectTo(path, params = {}, options = {}) {
  const url = joinPath(path, params)
  return new Promise((resolve, reject) => {
    uni.redirectTo({
      url,
      ...options,
      success: resolve,
      fail: (err) => {
        console.error('redirectTo 失败:', url, err)
        uni.showToast({ title: '页面跳转失败', icon: 'none' })
        reject(err)
      }
    })
  })
}

/**
 * 切换 Tab（switchTab 不支持传参）
 * @param {string} path Tab 路径（从 TAB_PATHS 读取）
 * @returns {Promise}
 */
export function switchTab(path) {
  return new Promise((resolve, reject) => {
    uni.switchTab({
      url: path,
      success: resolve,
      fail: (err) => {
        console.error('switchTab 失败:', path, err)
        // switchTab 仅支持原生tabBar，项目用CustomTabBar，回退为 reLaunch
        uni.reLaunch({ url: path, success: resolve, fail: reject })
      }
    })
  })
}

/**
 * 关闭所有页面重新打开（清空页面栈）
 * @param {string} path 目标路径
 * @param {Object} params 查询参数
 * @returns {Promise}
 */
export function reLaunch(path, params = {}) {
  const url = joinPath(path, params)
  return new Promise((resolve, reject) => {
    uni.reLaunch({
      url,
      success: resolve,
      fail: (err) => {
        console.error('reLaunch 失败:', url, err)
        uni.showToast({ title: '页面跳转失败', icon: 'none' })
        reject(err)
      }
    })
  })
}

/**
 * 返回上一页
 * @param {number} delta 返回层数，默认 1
 * @returns {Promise}
 */
export function navigateBack(delta = 1) {
  return new Promise((resolve, reject) => {
    uni.navigateBack({
      delta,
      fail: (err) => { console.error('navigateBack 失败:', err); reject(err) }
    })
  })
}

/**
 * 回到首页（工作台）
 * @returns {Promise}
 */
export function goHome() {
  return redirectTo(TAB_PATHS.HOME)
}

/**
 * 跳转到登录页（清空页面栈）
 * @returns {Promise}
 */
export function goLogin() {
  return reLaunch(PAGE_PATHS.LOGIN)
}

/**
 * redirectTo 别名
 */
export const replace = redirectTo
