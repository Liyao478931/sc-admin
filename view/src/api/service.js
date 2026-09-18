/**
 * 核心基础服务 API
 */
import request from './request'

// ---- 配置管理 ----
export function getAllServiceConfig() {
  return request({ url: '/services/config', method: 'get' })
}
export function getServiceConfig(service) {
  return request({ url: `/services/config/${service}`, method: 'get' })
}
export function saveServiceConfig(service, data) {
  return request({ url: `/services/config/${service}`, method: 'post', data })
}
export function testServiceConnection(service, params) {
  return request({ url: `/services/test/${service}`, method: 'post', params })
}
export function resetServiceConfig(service) {
  return request({ url: `/services/reset/${service}`, method: 'post' })
}

// ---- 状态监控 ----
export function getServiceStatus() {
  return request({ url: '/services/status', method: 'get' })
}
export function runHealthCheck() {
  return request({ url: '/services/health-check', method: 'post' })
}
export function getHealthStatus() {
  return request({ url: '/services/health-status', method: 'get' })
}

// ---- 存储服务 ----
export function getStorageStats() {
  return request({ url: '/services/storage/stats', method: 'get' })
}
export function getStorageActive() {
  return request({ url: '/services/storage/active', method: 'get' })
}

// ---- 短信服务 ----
export function getSmsStats(provider) {
  return request({ url: '/services/sms/stats', method: 'get', params: provider ? { provider } : {} })
}
export function smsTestSend(data) {
  return request({ url: '/services/sms/test-send', method: 'post', data })
}
export function getSmsProviders() {
  return request({ url: '/services/sms/providers', method: 'get' })
}

// ---- 邮件服务 ----
export function getEmailStats() {
  return request({ url: '/services/email/stats', method: 'get' })
}
export function emailTestSend(data) {
  return request({ url: '/services/email/test-send', method: 'post', data })
}

// ---- 微信服务 ----
export function getWechatStats() {
  return request({ url: '/services/wechat/stats', method: 'get' })
}
export function wechatTestOa() {
  return request({ url: '/services/wechat/test-oa', method: 'post' })
}
export function wechatTestMini() {
  return request({ url: '/services/wechat/test-mini', method: 'post' })
}
