/**
 * AI 工具调用日志 API
 * 路由前缀：/ai/tools/logs
 */
import request from './request'
import { getToken } from '@/utils/auth'

/** 日志列表（多维度筛选） */
export const getAiToolLogs = (params) => request({ url: '/ai/tools/logs/list', method: 'get', params })
/** 日志详情 */
export const getAiToolLogDetail = (id) => request({ url: `/ai/tools/logs/detail/${id}`, method: 'get' })
/** 日志统计 */
export const getAiToolLogStats = (params) => request({ url: '/ai/tools/logs/statistics', method: 'get', params })
/** 调用趋势 */
export const getAiToolLogTrend = (params) => request({ url: '/ai/tools/logs/trend', method: 'get', params })
/** 状态分布 */
export const getAiToolLogStatusDist = (params) => request({ url: '/ai/tools/logs/status-distribution', method: 'get', params })
/** 删除单条 */
export const deleteAiToolLog = (id) => request({ url: `/ai/tools/logs/delete/${id}`, method: 'delete' })
/** 批量删除（ids 或时间范围） */
export const batchDeleteAiToolLog = (data) => request({ url: '/ai/tools/logs/batch-delete', method: 'delete', data })

/** 导出日志（带 token 下载） */
export async function exportAiToolLogs (params, format) {
  const token = getToken() || ''
  const query = new URLSearchParams()
  Object.keys(params || {}).forEach(k => { if (params[k] !== undefined && params[k] !== '') query.append(k, params[k]) })
  query.append('format', format || 'json')
  const qs = query.toString()
  const resp = await fetch(`/api/ai/tools/logs/export${qs ? '?' + qs : ''}`, {
    headers: { 'Authorization': 'Bearer ' + token }
  })
  if (!resp.ok) throw new Error('导出失败')
  return resp.blob()
}
