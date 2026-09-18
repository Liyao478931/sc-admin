/**
 * 设备提醒 API 封装
 * 路由前缀：/device/remind
 */
import request from './request'

// 提醒列表（分页 + 多维筛选）
export const getRemindList = (p) => request({ url: '/device/remind/list', method: 'get', params: p })
// 提醒概览统计
export const getRemindStatistics = () => request({ url: '/device/remind/statistics', method: 'get' })
// 获取提醒配置
export const getRemindConfig = () => request({ url: '/device/remind/config', method: 'get' })
// 保存提醒配置
export const saveRemindConfig = (d) => request({ url: '/device/remind/config', method: 'put', data: d })
// 标记提醒已处理
export const markRemindHandled = (id, remindType) => request({ url: `/device/remind/mark-handled/${id}`, method: 'put', data: { remind_type: remindType } })
// 提醒历史
export const getRemindHistory = (p) => request({ url: '/device/remind/history', method: 'get', params: p })
