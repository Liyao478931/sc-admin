import { get, post } from '../../utils/request.js'

// 获取登录页视觉配置
export function getLoginPageConfig() {
  return get('/api/app/login-page-config')
}

// 获取可用登录方式（自动识别平台）
export function getLoginMethods() {
  return get('/api/app/login-methods')
}

// 获取底部版权信息
export function getFooterConfig() {
  return get('/api/settings/footer-config')
}

// 发送短信验证码
export function sendSms(phone, type = 'login') {
  return post('/api/mobile/send-sms', { phone, type })
}

// 账号密码登录
export function loginByPassword(username, password) {
  return post('/api/auth/login', { username, password })
}

// 验证码登录
export function loginBySms(phone, code) {
  return post('/api/mobile/login', { phone, code })
}

// 公众号微信授权登录
export function wechatMpLogin(code) {
  return post('/api/mobile/wechat/mp-login', { code })
}

// 小程序 wx.login 登录
export function wechatMiniLogin(code) {
  return post('/api/mobile/wechat/mini-login', { code })
}

// 微信登录后绑定手机号
export function wechatBind(openid, phone, code) {
  return post('/api/mobile/wechat/bind', { openid, phone, code })
}
