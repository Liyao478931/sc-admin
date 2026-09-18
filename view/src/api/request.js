/**
 * Axios 请求封装
 * 自动携带 Authorization: Bearer {token}
 */
import axios from 'axios'
import qs from 'qs'
import { getToken, removeToken } from '../utils/auth'
import { Message } from 'element-ui'

const request = axios.create({
  baseURL: '/api',
  timeout: 15000,
  headers: {
    'Content-Type': 'application/x-www-form-urlencoded'
  },
  transformRequest: [(data, headers) => {
    // FormData 原样发送（用于文件上传），交由浏览器自动设置 multipart boundary
    if (data instanceof FormData) {
      delete headers['Content-Type']
      return data
    }
    // 普通对象以 x-www-form-urlencoded 序列化，保证后端 $request->post() 可解析
    return qs.stringify(data)
  }]
})

// 请求拦截器 - 自动携带 Token
request.interceptors.request.use(
  config => {
    const token = getToken()
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  error => Promise.reject(error)
)

// 响应拦截器 - 统一处理
request.interceptors.response.use(
  response => {
    const res = response.data

    // 二进制流（文件下载）直接返回整个 response，由调用方处理 Blob
    if (res instanceof Blob) {
      return response
    }

    // 未登录或过期
    if (res.code === 401) {
      removeToken()
      Message.error(res.msg || '登录已过期')
      window.location.href = '/admin/#/login'
      return Promise.reject(new Error(res.msg))
    }

    if (res.code !== 0) {
      Message.error(res.msg || '请求失败')
      return Promise.reject(new Error(res.msg))
    }

    return res
  },
  error => {
    Message.error('网络错误，请稍后重试')
    return Promise.reject(error)
  }
)

export default request
