/**
 * U8服务配置 API
 * 路由前缀：/services/u8
 */
import request from './request'

/** 获取U8服务配置 */
export const getU8Config = () => request({ url: '/services/u8/config', method: 'get' })

/** 保存U8服务配置 */
export const saveU8Config = (d) => request({ url: '/services/u8/config', method: 'put', data: d })

/** 测试连接 */
export const testU8 = () => request({ url: '/services/u8/test', method: 'post' })

/** 同步状态 */
export const getU8SyncStatus = () => request({ url: '/services/u8/sync-status', method: 'get' })

/** 手动同步（单据状态） */
export const syncU8 = (dataTypes) => request({ url: '/services/u8/sync', method: 'post', data: { data_types: dataTypes } })

/** 保存U8回调配置（开关+签名密钥） */
export const saveU8CallbackConfig = (d) => request({ url: '/services/u8/callback-config', method: 'put', data: d })

/** 获取U8回调日志（分页） */
export const getU8CallbackLogs = (params) => request({ url: '/services/u8/callback-logs', method: 'get', params })

/** 获取U8单据状态台账（分页） */
export const getU8Documents = (params) => request({ url: '/services/u8/documents', method: 'get', params })
