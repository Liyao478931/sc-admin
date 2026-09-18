/**
 * 安全策略 API
 */
import request from './request'

// ===== 策略管理 =====
export function getPolicyList(params) { return request({ url: '/settings/security/policy/list', method: 'get', params }) }
export function getPolicyDetail(id) { return request({ url: `/settings/security/policy/detail/${id}`, method: 'get' }) }
export function savePolicy(data) { return request({ url: '/settings/security/policy/save', method: 'put', data }) }
export function batchSavePolicy(data) { return request({ url: '/settings/security/policy/batch-save', method: 'put', data }) }
export function resetPolicy(id) { return request({ url: `/settings/security/policy/reset/${id}`, method: 'post' }) }
export function getSecurityScore() { return request({ url: '/settings/security/policy/score', method: 'get' }) }

// ===== 敏感词管理 =====
export function getSensitiveWords(params) { return request({ url: '/settings/security/sensitive-words/list', method: 'get', params }) }
export function addSensitiveWord(data) { return request({ url: '/settings/security/sensitive-words/add', method: 'post', data }) }
export function editSensitiveWord(id, data) { return request({ url: `/settings/security/sensitive-words/edit/${id}`, method: 'put', data }) }
export function deleteSensitiveWord(id) { return request({ url: `/settings/security/sensitive-words/delete/${id}`, method: 'delete' }) }
export function batchDeleteSensitiveWord(ids) { return request({ url: '/settings/security/sensitive-words/batch-delete', method: 'delete', data: { ids } }) }
export function importSensitiveWords(formData) { return request({ url: '/settings/security/sensitive-words/import', method: 'post', data: formData }) }
export function exportSensitiveWords() { return request({ url: '/settings/security/sensitive-words/export', method: 'get', responseType: 'blob' }) }
export function detectSensitiveWords(text) { return request({ url: '/settings/security/sensitive-words/detect', method: 'post', data: { text } }) }

// ===== IP白名单管理 =====
export function getIpWhitelist(params) { return request({ url: '/settings/security/ip-whitelist/list', method: 'get', params }) }
export function addIpWhitelist(data) { return request({ url: '/settings/security/ip-whitelist/add', method: 'post', data }) }
export function editIpWhitelist(id, data) { return request({ url: `/settings/security/ip-whitelist/edit/${id}`, method: 'put', data }) }
export function deleteIpWhitelist(id) { return request({ url: `/settings/security/ip-whitelist/delete/${id}`, method: 'delete' }) }
export function batchDeleteIpWhitelist(ids) { return request({ url: '/settings/security/ip-whitelist/batch-delete', method: 'delete', data: { ids } }) }
export function getCurrentIp() { return request({ url: '/settings/security/ip-whitelist/current-ip', method: 'get' }) }
export function checkIpInWhitelist(ip) { return request({ url: '/settings/security/ip-whitelist/check', method: 'get', params: { ip } }) }
