/**
 * 腾讯电子签服务配置 API
 * 路由前缀：/services/esign
 */
import request from './request'

/** 获取电子签服务配置 */
export const getEsignConfig = () => request({ url: '/services/esign/config', method: 'get' })

/** 保存电子签服务配置 */
export const saveEsignConfig = (d) => request({ url: '/services/esign/config', method: 'put', data: d })

/** 测试连接（获取 AccessToken） */
export const testEsign = () => request({ url: '/services/esign/test', method: 'post' })

/** 获取模板列表（本地） */
export const getEsignTemplates = () => request({ url: '/services/esign/templates', method: 'get' })

/** 同步电子签模板 */
export const syncEsignTemplates = () => request({ url: '/services/esign/templates/sync', method: 'post' })

/** 获取签署日志列表（分页） */
export const getEsignLogs = (params) => request({ url: '/services/esign/logs', method: 'get', params })

/** 获取签署日志详情 */
export const getEsignLogDetail = (id) => request({ url: `/services/esign/logs/detail/${id}`, method: 'get' })
