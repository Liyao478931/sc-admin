/**
 * 薪酬标准表 API
 */
import request from './request'

export function getSalaryStandardList(params) { return request({ url: '/salary/standard/list', method: 'get', params }) }
export function getSalaryStandardDetail(id) { return request({ url: `/salary/standard/detail/${id}`, method: 'get' }) }
export function getSalaryStandardOptions(params) { return request({ url: '/salary/standard/options', method: 'get', params }) }
export function createSalaryStandard(data) { return request({ url: '/salary/standard/create', method: 'post', data }) }
export function updateSalaryStandard(id, data) { return request({ url: `/salary/standard/update/${id}`, method: 'put', data }) }
export function toggleSalaryStandard(id) { return request({ url: `/salary/standard/toggle/${id}`, method: 'post' }) }
export function deleteSalaryStandard(id) { return request({ url: `/salary/standard/delete/${id}`, method: 'delete' }) }
export function exportSalaryStandard(params) { return request({ url: '/salary/standard/export', method: 'get', params, responseType: 'blob' }) }
