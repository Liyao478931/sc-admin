// 开发环境用相对路径走 Vite proxy，生产环境用完整 URL
const FALLBACK_BASE = import.meta.env.VITE_API_BASE || 'https://qq.yywyrh.cn'
export const BASE_URL = import.meta.env.DEV ? '' : ((typeof window !== 'undefined' && window.location && window.location.origin) ? window.location.origin : FALLBACK_BASE)

// 统一清除登录态（token 双 key + userInfo），避免残留导致反复跳转
export function clearLoginState() {
  uni.removeStorageSync('access_token')
  uni.removeStorageSync('token')
  uni.removeStorageSync('userInfo')
}

// 跳转登录页（带 redirect 保留原目标，登录后可返回）
export function goLoginPage() {
  try {
    const pages = getCurrentPages()
    const cur = pages.length ? pages[pages.length - 1] : null
    const curPath = cur ? cur.route : ''
    let redirect = ''
    if (curPath && curPath !== 'pages/login/index') {
      redirect = encodeURIComponent('/' + curPath)
    }
    uni.reLaunch({ url: '/pages/login/index' + (redirect ? '?redirect=' + redirect : '') })
  } catch (e) {
    uni.reLaunch({ url: '/pages/login/index' })
  }
}

// ---- GET 接口 30s 内存缓存（慢网络优化：避免隧道下重复请求） ----
const _respCache = new Map()
const _CACHE_TTL = 30 * 1000

export function _clearRespCache() {
  _respCache.clear()
}

function _cacheKey(url, data, token) {
  return (url + '|' + JSON.stringify(data || {})) + '|' + (token || '')
}

export function request(options = {}) {
  return new Promise((resolve, reject) => {
    const token = uni.getStorageSync('access_token') || ''

    const _isGET = (options.method || 'GET').toUpperCase() === 'GET'
    const _force = !!(options.force)
    const _ck = _cacheKey(options.url, options.data, token)
    if (_isGET && !_force) {
      const _hit = _respCache.get(_ck)
      if (_hit && (Date.now() - _hit.t) < _CACHE_TTL) {
        resolve(_hit.d)
        return
      }
    }

    const header = {
      'Content-Type': 'application/x-www-form-urlencoded',
      ...(options.header || {})
    }
    
    if (token) {
      header['Authorization'] = 'Bearer ' + token
    }
    
    uni.request({
      url: BASE_URL + options.url,
      method: options.method || 'GET',
      data: options.data || {},
      header,
      success(res) {
        // 后端 401 通过 HTTP 200 + data.code=401 返回（AuthMiddleware），必须同时识别
        const body = res.data || {}
        const biz401 = res.statusCode === 200 && body && body.code === 401
        if (res.statusCode === 200 && !biz401) {
          if (_isGET) { _respCache.set(_ck, { t: Date.now(), d: res.data }) }
          resolve(res.data)
        } else if (res.statusCode === 401 || biz401) {
          clearLoginState()
          goLoginPage()
          reject(new Error(body.msg || '登录已过期'))
        } else {
          reject(new Error('请求失败: ' + res.statusCode))
        }
      },
      fail(err) {
        reject(err)
      }
    })
  })
}

export function get(url, data = {}, force = false) {
  return request({ url, method: 'GET', data, force })
}

export function post(url, data = {}) {
  return request({ url, method: 'POST', data })
}
