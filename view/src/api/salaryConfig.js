/**
 * 工资配置 API（按职级）
 */
import request from './request'

export function getSalaryConfigList(params) { return request({ url: '/hr/salary/config/list', method: 'get', params }) }
export function saveSalaryConfig(data) { return request({ url: '/hr/salary/config/save', method: 'post', data }) }
export function deleteSalaryConfig(id) { return request({ url: `/hr/salary/config/delete/${id}`, method: 'delete' }) }
export function toggleSalaryConfig(id) { return request({ url: `/hr/salary/config/toggle/${id}`, method: 'post' }) }
