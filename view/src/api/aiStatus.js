/**
 * AI 系统状态监控 API（工作台 → 系统状态）
 */
import request from './request'

// ===== 服务健康状态 =====
export function getSystemStatusServices() { return request({ url: '/system/status/services', method: 'get' }) }
export function getSystemStatusDetail(params) { return request({ url: '/system/status/service/detail', method: 'get', params }) }
export function getSystemStatusTrend(params) { return request({ url: '/system/status/trend', method: 'get', params }) }

// ===== 性能指标 =====
export function getSystemStatusMetrics() { return request({ url: '/system/status/metrics', method: 'get' }) }

// ===== 运行信息 / 最近告警 =====
export function getSystemStatusInfo() { return request({ url: '/system/status/info', method: 'get' }) }
export function getSystemStatusAlerts(params) { return request({ url: '/system/status/alerts', method: 'get', params }) }
