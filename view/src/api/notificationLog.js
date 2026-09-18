/**
 * 消息发送记录 API
 * 路由前缀：/notification/log
 */
import request from './request'

/** 发送记录列表（分页 + 筛选） */
export const getNotificationLogList = (p) => request({ url: '/notification/log/list', method: 'get', params: p })

/** 发送详情 */
export const getNotificationLogDetail = (id) => request({ url: '/notification/log/detail/' + id, method: 'get' })

/** 发送统计 */
export const getNotificationLogStatistics = () => request({ url: '/notification/log/statistics', method: 'get' })

/** 失败重发 */
export const retryNotificationLog = (id) => request({ url: '/notification/log/retry/' + id, method: 'post' })

/** 批量重发 */
export const batchRetryNotificationLog = (ids) => request({ url: '/notification/log/batch-retry', method: 'post', data: { ids } })

/** 导出发送记录（返回文件URL） */
export const exportNotificationLog = (p) => request({ url: '/notification/log/export', method: 'get', params: p })
