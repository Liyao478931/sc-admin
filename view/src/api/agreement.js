/**
 * 系统设置 - 移动端协议管理 API
 * 路由前缀：/settings/agreements
 */
import request from './request'

export const getAgreements = () => request({ url: '/settings/agreements', method: 'get' })

export const saveAgreements = (data) => request({ url: '/settings/agreements', method: 'post', data })
