/**
 * 文件：admin/src/api/aiAudit.js
 * 操作审计 API（路由前缀 /ai/operation/audit）
 */
import request from './request'

/** 审计日志列表 */
export const getAuditList = (p) => request({ url: '/ai/operation/audit/list', method: 'get', params: p })

/** 审计日志详情 */
export const getAuditDetail = (id) => request({ url: '/ai/operation/audit/detail/' + id, method: 'get' })

/** 审计统计 */
export const getAuditStatistics = () => request({ url: '/ai/operation/audit/statistics', method: 'get' })

/** 操作趋势 */
export const getAuditTrend = (p) => request({ url: '/ai/operation/audit/trend', method: 'get', params: p })

/** 操作类型分布 */
export const getAuditActionDist = (p) => request({ url: '/ai/operation/audit/action-distribution', method: 'get', params: p })

/** 导出审计日志（CSV/JSON） */
export const exportAuditLogs = (p) => request({ url: '/ai/operation/audit/export', method: 'get', params: p, responseType: 'blob' })

/** 删除单条 */
export const deleteAuditLog = (id) => request({ url: '/ai/operation/audit/delete/' + id, method: 'delete' })

/** 批量删除（ids 或时间范围） */
export const batchDeleteAuditLogs = (data) => request({ url: '/ai/operation/audit/batch-delete', method: 'delete', data })
