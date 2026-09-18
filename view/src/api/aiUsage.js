/**
 * 文件：admin/src/api/aiUsage.js
 * AI 用量统计 API（路由前缀 /ai/operation/usage）
 */
import request from './request'

/** 概览统计 */
export const getUsageOverview = (p) => request({ url: '/ai/operation/usage/overview', method: 'get', params: p })

/** 调用趋势 */
export const getUsageTrend = (p) => request({ url: '/ai/operation/usage/trend', method: 'get', params: p })

/** Token 消耗分布 */
export const getUsageTokenDist = (p) => request({ url: '/ai/operation/usage/token-distribution', method: 'get', params: p })

/** 资源使用排行 */
export const getUsageRanking = (p) => request({ url: '/ai/operation/usage/ranking', method: 'get', params: p })

/** 费用分析 */
export const getUsageCostAnalysis = (p) => request({ url: '/ai/operation/usage/cost-analysis', method: 'get', params: p })

/** 用量明细 */
export const getUsageDetail = (p) => request({ url: '/ai/operation/usage/detail', method: 'get', params: p })

/** 导出统计报表（CSV） */
export const exportUsageReport = (p) => request({ url: '/ai/operation/usage/export', method: 'get', params: p, responseType: 'blob' })
