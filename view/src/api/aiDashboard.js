/**
 * AI 运营概览 API
 */
import request from './request'

export function getDashboardMetrics(params) { return request({ url: '/ai/dashboard/metrics', method: 'get', params }) }
export function getDashboardTrend(params) { return request({ url: '/ai/dashboard/trend', method: 'get', params }) }
export function getDashboardRanking(params) { return request({ url: '/ai/dashboard/ranking', method: 'get', params }) }
export function getDashboardRecent(params) { return request({ url: '/ai/dashboard/recent', method: 'get', params }) }
export function getDashboardStatus() { return request({ url: '/ai/dashboard/status', method: 'get' }) }
export function getDashboardQuickActions() { return request({ url: '/ai/dashboard/quick-actions', method: 'get' }) }
