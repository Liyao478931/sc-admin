/**
 * 消息通知中心 API
 * 路由前缀：/notification（需登录，无需额外权限码）
 */
import request from './request'

/** 消息列表（分页 + 多维筛选） */
export const getNotificationList = (p) => request({ url: '/notification/list', method: 'get', params: p })

/** 未读消息数 */
export const getUnreadCount = () => request({ url: '/notification/unread-count', method: 'get' })

/** 消息详情（查看时自动标记已读） */
export const getNotificationDetail = (id) => request({ url: '/notification/detail/' + id, method: 'get' })

/** 单条标记已读 */
export const readNotification = (id) => request({ url: '/notification/read/' + id, method: 'put' })

/** 单条标记未读（手动切换） */
export const unreadNotification = (id) => request({ url: '/notification/unread/' + id, method: 'put' })

/** 批量标记已读 */
export const readNotificationsBatch = (ids) => request({ url: '/notification/read-batch', method: 'put', data: { ids } })

/** 全部标记已读 */
export const readAllNotifications = () => request({ url: '/notification/read-all', method: 'put' })

/** 删除单条消息（软删除） */
export const deleteNotification = (id) => request({ url: '/notification/delete/' + id, method: 'delete' })

/** 批量删除消息 */
export const deleteNotificationsBatch = (ids) => request({ url: '/notification/delete-batch', method: 'delete', data: { ids } })

/** 顶部最近5条未读 */
export const getTopUnread = () => request({ url: '/notification/top-unread', method: 'get' })

/** 消息统计（总/未读/今日新增） */
export const getNotificationStatistics = () => request({ url: '/notification/statistics', method: 'get' })

/** 发送消息（管理后台） */
export const sendMessage = (d) => request({ url: '/notification/send', method: 'post', data: d })
