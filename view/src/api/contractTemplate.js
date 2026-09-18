/**
 * 经营管理 - 合同模板管理 API
 * 路由前缀：/business/contract/template
 */
import request from './request'

// ===== 模板管理 =====
export function getTemplateList(params) { return request({ url: '/business/contract/template/list', method: 'get', params }) }
export function getTemplateDetail(id) { return request({ url: `/business/contract/template/detail/${id}`, method: 'get' }) }
export function getTemplateOptions(params) { return request({ url: '/business/contract/template/options', method: 'get', params }) }
export function getAvailableTemplates(params) { return request({ url: '/business/contract/template/available', method: 'get', params }) }
export function addTemplate(data) { return request({ url: '/business/contract/template/add', method: 'post', data }) }
export function editTemplate(id, data) { return request({ url: `/business/contract/template/edit/${id}`, method: 'put', data }) }
export function deleteTemplate(id) { return request({ url: `/business/contract/template/delete/${id}`, method: 'delete' }) }
export function setDefaultTemplate(id) { return request({ url: `/business/contract/template/set-default/${id}`, method: 'put' }) }
export function toggleTemplateStatus(id) { return request({ url: `/business/contract/template/status/${id}`, method: 'put' }) }
export function copyTemplate(id) { return request({ url: `/business/contract/template/copy/${id}`, method: 'post' }) }
export function importTemplate(formData) { return request({ url: '/business/contract/template/import', method: 'post', data: formData, headers: { 'Content-Type': 'multipart/form-data' } }) }
export function exportTemplate(id) { return request({ url: `/business/contract/template/export/${id}`, method: 'get', responseType: 'blob' }) }

// ===== 合同生成 =====
export function previewContract(data) { return request({ url: '/business/contract/template/preview', method: 'post', data }) }
export function generateContract(data) { return request({ url: '/business/contract/template/generate', method: 'post', data }) }
export function exportContractWord(id) { return request({ url: `/business/contract/template/export-word/${id}`, method: 'get', responseType: 'blob' }) }
export function exportContractPdf(id) { return request({ url: `/business/contract/template/export-pdf/${id}`, method: 'get', responseType: 'blob' }) }

// ===== 变量管理 =====
export function getTemplateVariables() { return request({ url: '/business/contract/template/variables', method: 'get' }) }
export function getTemplateVariableCategories() { return request({ url: '/business/contract/template/variables/categories', method: 'get' }) }
