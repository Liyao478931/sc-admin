/**
 * 系统设置 - 公司信息管理 API
 * 路由前缀：/settings/company
 */
import request from './request'

/** 获取公司信息（我方 + 合作方 + 权限标识） */
export const getCompanyConfig = () => request({ url: '/settings/company/config', method: 'get' })

/** 保存草稿（我方 + 合作方） */
export const saveCompanyConfig = (d) => request({ url: '/settings/company/config', method: 'put', data: d })

/** 发布上线 */
export const publishCompany = () => request({ url: '/settings/company/publish', method: 'put' })

/** 预览（对外展示数据） */
export const previewCompany = () => request({ url: '/settings/company/preview', method: 'get' })

/** 操作日志 */
export const getCompanyLogs = () => request({ url: '/settings/company/logs', method: 'get' })

/** 信息同步 */
export const syncCompany = (channels) => request({ url: '/settings/company/sync', method: 'post', data: { channels } })

/** 历史交易记录 */
export const getTradeRecords = () => request({ url: '/settings/company/trade-records', method: 'get' })
