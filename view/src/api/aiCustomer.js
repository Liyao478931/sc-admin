/**
 * AI 客户智能分析 API（v1.66.0）
 * 路由前缀：/ai/customer
 */
import request from './request'
import { getToken } from '@/utils/auth'

/** 价值总览 */
export const getCustomerValueOverview = (params) => request({ url: '/ai/customer/value/overview', method: 'get', params })

/** RFM 分层列表 */
export const getCustomerValueList = (params) => request({ url: '/ai/customer/value/list', method: 'get', params })

/** 客户 360 画像 */
export const getCustomerProfile = (id) => request({ url: `/ai/customer/value/profile/${id}`, method: 'get' })

/** 价值趋势 */
export const getCustomerValueTrend = () => request({ url: '/ai/customer/value/trend', method: 'get' })

/** RFM 三维分布 */
export const getRfmDistribution = (params) => request({ url: '/ai/customer/value/rfm-distribution', method: 'get', params })

/** 流失预警总览 */
export const getChurnOverview = () => request({ url: '/ai/customer/churn/overview', method: 'get' })

/** 流失客户列表 */
export const getChurnList = (params) => request({ url: '/ai/customer/churn/list', method: 'get', params })

/** 流失原因 AI 分析 */
export const analyzeChurn = (id) => request({ url: `/ai/customer/churn/analyze/${id}`, method: 'get' })

/** 推荐挽回策略 */
export const getChurnStrategies = (id) => request({ url: `/ai/customer/churn/strategies/${id}`, method: 'get' })

/** 执行挽回策略 */
export const executeChurnStrategy = (data) => request({ url: '/ai/customer/churn/execute', method: 'post', data })

/** 挽回记录 */
export const getChurnActions = (id) => request({ url: `/ai/customer/churn/actions/${id}`, method: 'get' })

/** 导出流失客户（带 token） */
export async function exportChurnFile (params) {
  const token = getToken() || ''
  const qs = new URLSearchParams(params).toString()
  const resp = await fetch(`/api/ai/customer/churn/export?${qs}`, { headers: { 'Authorization': 'Bearer ' + token } })
  if (!resp.ok) throw new Error('导出失败')
  const blob = await resp.blob()
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = '流失客户_' + Date.now() + '.xlsx'
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}
