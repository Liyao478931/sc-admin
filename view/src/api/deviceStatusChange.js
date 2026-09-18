/**
 * 设备状态变更 API 封装
 */
import request from './request'

export function getStatusChangeList(params) { return request({ url: '/device/status-change/list', method: 'get', params }) }
export function getStatusChangeDetail(id) { return request({ url: `/device/status-change/detail/${id}`, method: 'get' }) }
export function getDeviceHistory(id) { return request({ url: `/device/status-change/device-history/${id}`, method: 'get' }) }
export function createStatusChange(data) { return request({ url: '/device/status-change/create', method: 'post', data }) }
export function batchCreateStatusChange(data) { return request({ url: '/device/status-change/batch-create', method: 'post', data }) }
export function rollbackStatusChange(id) { return request({ url: `/device/status-change/rollback/${id}`, method: 'post' }) }
export function getAvailableTargets(id) { return request({ url: `/device/status-change/available-targets/${id}`, method: 'get' }) }
export function getStatusChangeStatistics() { return request({ url: '/device/status-change/statistics', method: 'get' }) }
export function exportStatusChange(params) { return request({ url: '/device/status-change/export', method: 'get', params }) }
export function getPresetReasons() { return request({ url: '/device/status-change/preset-reasons', method: 'get' }) }
