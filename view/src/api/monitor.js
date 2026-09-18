import request from './request'
export function getOverview() { return request({ url: '/monitor/overview', method: 'get' }) }
export function getInfo() { return request({ url: '/monitor/info', method: 'get' }) }
export function getSystemInfo() { return request({ url: '/monitor/system-info', method: 'get' }) }
export function getCpuTrend(range) { return request({ url: '/monitor/cpu-trend', method: 'get', params: { range } }) }
export function getMemoryTrend(range) { return request({ url: '/monitor/memory-trend', method: 'get', params: { range } }) }
export function getDiskTrend(range) { return request({ url: '/monitor/disk-trend', method: 'get', params: { range } }) }
export function getNetworkTrend(range) { return request({ url: '/monitor/network-trend', method: 'get', params: { range } }) }
export function getProcesses() { return request({ url: '/monitor/processes', method: 'get' }) }
export function killProcess(pid) { return request({ url: `/monitor/processes/${pid}`, method: 'delete' }) }
export function getAlarmSettings() { return request({ url: '/monitor/alarm-settings', method: 'get' }) }
export function saveAlarmSettings(data) { return request({ url: '/monitor/alarm-settings', method: 'put', data }) }
export function getAlarmHistory(params) { return request({ url: '/monitor/alarm-history', method: 'get', params }) }
export function markAlarmRead(id) { return request({ url: `/monitor/alarm-history/${id}/read`, method: 'put' }) }
