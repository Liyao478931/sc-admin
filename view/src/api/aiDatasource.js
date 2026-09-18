/**
 * AI 数据源管理 API
 */
import request from './request'

// ===== 数据源管理 =====
export function getDatasources(params) { return request({ url: '/ai/knowledge/datasource/list', method: 'get', params }) }
export function getDatasourceDetail(id) { return request({ url: `/ai/knowledge/datasource/detail/${id}`, method: 'get' }) }
export function addDatasource(data) { return request({ url: '/ai/knowledge/datasource/add', method: 'post', data }) }
export function editDatasource(id, data) { return request({ url: `/ai/knowledge/datasource/edit/${id}`, method: 'put', data }) }
export function deleteDatasource(id) { return request({ url: `/ai/knowledge/datasource/delete/${id}`, method: 'delete' }) }
export function updateDatasourceStatus(id, status) { return request({ url: `/ai/knowledge/datasource/status/${id}`, method: 'put', data: { status } }) }
export function testDatasource(data) { return request({ url: '/ai/knowledge/datasource/test', method: 'post', data }) }
export function previewDatasource(data) { return request({ url: '/ai/knowledge/datasource/preview', method: 'post', data }) }

// ===== 同步任务 =====
export function syncDatasource(id) { return request({ url: `/ai/knowledge/datasource/sync/${id}`, method: 'post' }) }
export function getDatasourceSyncStatus(id) { return request({ url: `/ai/knowledge/datasource/sync-status/${id}`, method: 'get' }) }
export function cancelDatasourceSync(id) { return request({ url: `/ai/knowledge/datasource/sync-cancel/${id}`, method: 'post' }) }

// ===== 同步日志 =====
export function getDatasourceSyncLogs(params) { return request({ url: '/ai/knowledge/datasource/sync-logs', method: 'get', params }) }
export function getDatasourceSyncLogDetail(id) { return request({ url: `/ai/knowledge/datasource/sync-log/detail/${id}`, method: 'get' }) }
export function getDatasourceStatistics() { return request({ url: '/ai/knowledge/datasource/statistics', method: 'get' }) }
