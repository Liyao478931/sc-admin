// API 请求封装 - 所有请求走 Vite proxy（开发环境相对路径）
const BASE_URL = ''
const HEADER = { 'Content-Type': 'application/x-www-form-urlencoded' }

function request(url, method = 'GET', data = {}) {
  return new Promise((resolve, reject) => {
    const token = uni.getStorageSync('token') || ''
    const header = { ...HEADER }
    if (token) header['token'] = token
    uni.request({
      url: BASE_URL + url,
      method,
      data,
      header,
      success(res) {
        if (res.statusCode === 200) {
          resolve(res.data)
        } else if (res.statusCode === 401) {
          uni.removeStorageSync('token')
          uni.reLaunch({ url: '/pages/login/index' })
          reject(new Error('登录已过期'))
        } else {
          reject(new Error('请求失败: ' + res.statusCode))
        }
      },
      fail(err) { reject(err) }
    })
  })
}

export function getLoginPageConfig() {
  return request('/api/app/login-page-config')
}

export function getLoginMethods() {
  return request('/api/app/login-methods')
}

export function getFooterConfig() {
  return request('/api/settings/footer-config')
}

export function login(data) {
  return request('/api/auth/login', 'POST', data)
}

export function sendSms(data) {
  return request('/api/mobile/send-sms', 'POST', data)
}

export function smsLogin(data) {
  return request('/api/mobile/login', 'POST', data)
}

export function wechatMpLogin(code) {
  return request('/api/mobile/wechat/mp-login', 'POST', { code })
}

export function wechatMiniLogin(code) {
  return request('/api/mobile/wechat/mini-login', 'POST', { code })
}

export function wechatBind(data) {
  return request('/api/mobile/wechat/bind', 'POST', data)
}
