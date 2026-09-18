/**
 * 文件：admin/src/api/aiApp.js
 * AI 应用 API（路由前缀 /ai/app）
 */
import request from './request'

/** 应用列表 */
export const getAppList = (p) => request({ url: '/ai/app/list', method: 'get', params: p })

/** 应用详情 */
export const getAppDetail = (id) => request({ url: '/ai/app/detail/' + id, method: 'get' })

/** 创建应用 */
export const addApp = (d) => request({ url: '/ai/app/add', method: 'post', data: d })

/** 编辑应用 */
export const editApp = (id, d) => request({ url: '/ai/app/edit/' + id, method: 'put', data: d })

/** 删除应用 */
export const deleteApp = (id) => request({ url: '/ai/app/delete/' + id, method: 'delete' })

/** 切换启用/停用 */
export const updateAppStatus = (id, status) => request({ url: '/ai/app/status/' + id, method: 'put', data: { status } })

/** 复制应用 */
export const copyApp = (id) => request({ url: '/ai/app/copy/' + id, method: 'post' })

/** 应用统计 */
export const getAppStatistics = () => request({ url: '/ai/app/statistics', method: 'get' })

/** 调用趋势 */
export const getAppTrend = (id, p) => request({ url: '/ai/app/trend/' + id, method: 'get', params: p })

/** 应用下拉选项（启用状态） */
export const getAppOptions = () => request({ url: '/ai/app/options', method: 'get' })
