/**
 * AI 监控告警 API
 */
import request from './request'

// ===== 监控总览 =====
export function getMonitorHealth() { return request({ url: '/ai/operation/monitor/health', method: 'get' }) }
export function getMonitorMetrics() { return request({ url: '/ai/operation/monitor/metrics', method: 'get' }) }
export function getMonitorTrend(params) { return request({ url: '/ai/operation/monitor/trend', method: 'get', params }) }

// ===== 告警规则 =====
export function getAlertRules(params) { return request({ url: '/ai/operation/monitor/rules', method: 'get', params }) }
export function getAlertRuleDetail(id) { return request({ url: `/ai/operation/monitor/rule/detail/${id}`, method: 'get' }) }
export function addAlertRule(data) { return request({ url: '/ai/operation/monitor/rule/add', method: 'post', data }) }
export function editAlertRule(id, data) { return request({ url: `/ai/operation/monitor/rule/edit/${id}`, method: 'put', data }) }
export function deleteAlertRule(id) { return request({ url: `/ai/operation/monitor/rule/delete/${id}`, method: 'delete' }) }
export function updateAlertRuleStatus(id, status) { return request({ url: `/ai/operation/monitor/rule/status/${id}`, method: 'put', data: { status } }) }

// ===== 告警历史 =====
export function getAlertHistory(params) { return request({ url: '/ai/operation/monitor/history', method: 'get', params }) }
export function getAlertHistoryDetail(id) { return request({ url: `/ai/operation/monitor/history/detail/${id}`, method: 'get' }) }
export function confirmAlertHistory(id) { return request({ url: `/ai/operation/monitor/history/confirm/${id}`, method: 'put' }) }
export function getAlertHistoryStatistics() { return request({ url: '/ai/operation/monitor/history/statistics', method: 'get' }) }
