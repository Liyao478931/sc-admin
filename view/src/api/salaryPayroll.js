/**
 * 工资计算与工资配置 API
 */
import request from './request'

export function getPayrollList(params) { return request({ url: '/hr/salary/payroll/list', method: 'get', params }) }
export function calculatePayroll(data) { return request({ url: '/hr/salary/payroll/calculate', method: 'post', data }) }
export function confirmPayroll(id) { return request({ url: `/hr/salary/payroll/confirm/${id}`, method: 'post' }) }
export function getPayrollDetail(id) { return request({ url: `/hr/salary/payroll/detail/${id}`, method: 'get' }) }
export function exportPayroll(params) { return request({ url: '/hr/salary/payroll/export', method: 'get', params, responseType: 'blob' }) }
export function getSalaryConfigList(params) { return request({ url: '/hr/salary/payroll/config/list', method: 'get', params }) }
export function saveSalaryConfig(data) { return request({ url: '/hr/salary/payroll/config/save', method: 'post', data }) }
export function deleteSalaryConfig(id) { return request({ url: `/hr/salary/payroll/config/delete/${id}`, method: 'delete' }) }
export function toggleSalaryConfig(id) { return request({ url: `/hr/salary/payroll/config/toggle/${id}`, method: 'post' }) }
