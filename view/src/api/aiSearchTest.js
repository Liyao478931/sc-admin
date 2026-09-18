/**
 * AI 检索测试 API
 */
import request from './request'

// ===== 检索执行 =====
export function executeSearchTest(data) { return request({ url: '/ai/knowledge/search-test/execute', method: 'post', data }) }

// ===== 检索历史 =====
export function getSearchHistory(params) { return request({ url: '/ai/knowledge/search-test/history', method: 'get', params }) }
export function getSearchHistoryDetail(id) { return request({ url: `/ai/knowledge/search-test/history/detail/${id}`, method: 'get' }) }
export function submitSearchFeedback(data) { return request({ url: '/ai/knowledge/search-test/feedback', method: 'post', data }) }
export function exportSearchHistory(params) { return request({ url: '/ai/knowledge/search-test/history/export', method: 'get', params, responseType: 'blob' }) }

// ===== 检索方案 =====
export function getSearchSchemas(params) { return request({ url: '/ai/knowledge/search-test/schemas', method: 'get', params }) }
export function saveSearchSchema(data) { return request({ url: '/ai/knowledge/search-test/schema/save', method: 'post', data }) }
export function deleteSearchSchema(id) { return request({ url: `/ai/knowledge/search-test/schema/delete/${id}`, method: 'delete' }) }

// ===== 统计 =====
export function getSearchStatistics(params) { return request({ url: '/ai/knowledge/search-test/statistics', method: 'get', params }) }
