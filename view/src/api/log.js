/**
 * 日志管理 API
 */
import request from './request'

/** 日志列表 */
export function getLogList(params) {
  return request({ url: '/logs/list', method: 'get', params })
}

/** 日志详情 */
export function getLogDetail(id) {
  return request({ url: '/logs/detail', method: 'get', params: { id } })
}

/** 相邻日志 */
export function getNeighborLog(id, direction) {
  return request({ url: '/logs/neighbor', method: 'get', params: { id, direction } })
}

/** 统计看板 */
export function getLogStatistics(params) {
  return request({ url: '/logs/statistics', method: 'get', params })
}

/** 导出日志 */
export function exportLogs(data) {
  return request({ url: '/logs/export', method: 'post', data })
}

/** 导出任务列表 */
export function getExportTasks() {
  return request({ url: '/logs/export-tasks', method: 'get' })
}

/** 下载导出文件 */
export function downloadExportFile(taskId) {
  return `/api/logs/download?task_id=${taskId}`
}

/** 获取日志设置 */
export function getLogSettings() {
  return request({ url: '/logs/settings', method: 'get' })
}

/** 保存日志设置 */
export function saveLogSettings(data) {
  return request({ url: '/logs/settings', method: 'post', data })
}

/** 恢复默认设置 */
export function resetLogSettings() {
  return request({ url: '/logs/settings/reset', method: 'post' })
}

/** 清理日志 */
export function cleanLogs(days) {
  return request({ url: '/logs/clean', method: 'post', data: { days } })
}

/** 清理日志预览 */
export function cleanLogsPreview(days) {
  return request({ url: '/logs/clean-preview', method: 'post', data: { days } })
}

/** 安全告警 */
export function getLogAlerts() {
  return request({ url: '/logs/alerts', method: 'get' })
}
