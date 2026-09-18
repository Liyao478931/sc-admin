/**
 * 工资配置 V2 API（参考页面：基本设置/工资项目/等级标准/工龄工资/社保公积金）
 */
import request from './request'

// 配置管理
export function getSalaryConfigV2List(params) { return request({ url: '/hr/salary/config-v2/list', method: 'get', params }) }
export function getSalaryConfigV2Detail(id) { return request({ url: `/hr/salary/config-v2/detail/${id}`, method: 'get' }) }
export function createSalaryConfigV2(data) { return request({ url: '/hr/salary/config-v2/create', method: 'post', data }) }
export function updateSalaryConfigV2(id, data) { return request({ url: `/hr/salary/config-v2/update/${id}`, method: 'post', data }) }
export function copySalaryConfigV2(id) { return request({ url: `/hr/salary/config-v2/copy/${id}`, method: 'post' }) }
export function activateSalaryConfigV2(id) { return request({ url: `/hr/salary/config-v2/activate/${id}`, method: 'post' }) }
export function deleteSalaryConfigV2(id) { return request({ url: `/hr/salary/config-v2/delete/${id}`, method: 'delete' }) }

// 工资项目
export function saveSalaryItem(data) { return request({ url: '/hr/salary/config-v2/item/save', method: 'post', data }) }
export function deleteSalaryItem(id) { return request({ url: `/hr/salary/config-v2/item/delete/${id}`, method: 'delete' }) }

// 等级标准
export function saveSalaryGrade(data) { return request({ url: '/hr/salary/config-v2/grade/save', method: 'post', data }) }
export function deleteSalaryGrade(id) { return request({ url: `/hr/salary/config-v2/grade/delete/${id}`, method: 'delete' }) }

// 工龄工资 / 社保公积金
export function saveSalaryAdvanced(data) { return request({ url: '/hr/salary/config-v2/advanced/save', method: 'post', data }) }

// 系统模板
export function getSalaryTemplate() { return request({ url: '/hr/salary/config-v2/template', method: 'get' }) }
