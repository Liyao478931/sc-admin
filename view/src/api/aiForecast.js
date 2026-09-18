/**
 * AI 销售预测 API（v1.65.0）
 * 路由前缀：/ai/forecast
 */
import request from './request'
import { getToken } from '@/utils/auth'

/** 预测总览（指标卡） */
export const getForecastOverview = (params) => request({ url: '/ai/forecast/overview', method: 'get', params })

/** 预测趋势图数据 */
export const getForecastTrend = (params) => request({ url: '/ai/forecast/trend', method: 'get', params })

/** 产品预测排行 */
export const getForecastProducts = (params) => request({ url: '/ai/forecast/products', method: 'get', params })

/** 预测因子分析 */
export const getForecastFactors = (params) => request({ url: '/ai/forecast/factors', method: 'get', params })

/** 导出预测报告（Excel，带 token） */
export async function exportForecastFile (params) {
  const token = getToken() || ''
  const qs = new URLSearchParams(params).toString()
  const resp = await fetch(`/api/ai/forecast/export?${qs}`, { headers: { 'Authorization': 'Bearer ' + token } })
  if (!resp.ok) throw new Error('导出失败')
  const blob = await resp.blob()
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = '销售预测_' + Date.now() + '.xlsx'
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}
