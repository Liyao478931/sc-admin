/**
 * 设置 API（登录页配置 + 系统参数）
 */
import request from './request'

// ===== 登录页配置（原有） =====
export function getLoginSettings() { return request({ url: '/settings/login', method: 'get' }) }
export function saveLoginSettings(data) { return request({ url: '/settings/login', method: 'put', data }) }
export function resetLoginSettings() { return request({ url: '/settings/login/reset', method: 'post' }) }
export function uploadSettingFile(data) { return request({ url: '/settings/login/upload', method: 'post', data }) }

// ===== 系统参数配置（新增） =====
export function getParams() { return request({ url: '/settings/params', method: 'get' }) }
export function getParam(key) { return request({ url: `/settings/params/${key}`, method: 'get' }) }
export function updateParam(key, data) { return request({ url: `/settings/params/${key}`, method: 'put', data }) }
export function resetParams() { return request({ url: '/settings/params/reset', method: 'post' }) }

// ===== 业务调用接口 =====
export function getSettingValue(key) { return request({ url: `/settings/get/${key}`, method: 'get' }) }
export function getSettingsBatch(keys) { return request({ url: '/settings/batch/get', method: 'get', params: { keys: keys.join(',') } }) }
