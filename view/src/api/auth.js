/**
 * 认证相关 API
 */
import request from './request'

/** 密码登录 */
export function login(data) {
  return request({
    url: '/auth/login',
    method: 'post',
    data
  })
}

/** 获取登录验证码（数学算式） */
export function getCaptcha() {
  return request({
    url: '/auth/captcha',
    method: 'get'
  })
}

/** 注册 */
export function register(data) {
  return request({
    url: '/auth/register',
    method: 'post',
    data
  })
}

/** 获取用户信息 */
export function getUserInfo() {
  return request({
    url: '/auth/userinfo',
    method: 'get'
  })
}

/** 获取本次登录信息 */
export function getLoginInfo() {
  return request({
    url: '/auth/login-info',
    method: 'get'
  })
}

/** 获取当前用户权限列表 */
export function getLoginPermissions() {
  return request({
    url: '/auth/permissions',
    method: 'get'
  })
}

/** 发送短信验证码 */
export function sendSms(data) {
  return request({
    url: '/auth/sendSms',
    method: 'post',
    data
  })
}

/** 短信验证码登录 */
export function smsLogin(data) {
  return request({
    url: '/auth/smsLogin',
    method: 'post',
    data
  })
}

/** 重置密码 */
export function resetPassword(data) {
  return request({
    url: '/auth/resetPassword',
    method: 'post',
    data
  })
}
