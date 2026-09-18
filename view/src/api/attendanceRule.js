/**
 * 打卡配置管理 API
 * 路由前缀：/hr/attendance/rule
 */
import request from './request'

/** 获取打卡规则列表 */
export const getRuleList = (params) => request({ url: '/hr/attendance/rule/list', method: 'get', params })

/** 获取规则详情 */
export const getRuleDetail = (id) => request({ url: `/hr/attendance/rule/detail/${id}`, method: 'get' })

/** 新增规则 */
export const createRule = (data) => request({ url: '/hr/attendance/rule/add', method: 'post', data })

/** 更新规则 */
export const updateRule = (id, data) => request({ url: `/hr/attendance/rule/edit/${id}`, method: 'put', data })

/** 删除规则 */
export const deleteRule = (id) => request({ url: `/hr/attendance/rule/delete/${id}`, method: 'delete' })

/** 设为默认规则 */
export const setDefaultRule = (id) => request({ url: `/hr/attendance/rule/set-default/${id}`, method: 'post' })

/** 启停规则 */
export const toggleRule = (id, status) => request({ url: `/hr/attendance/rule/toggle/${id}`, method: 'post', data: { status } })
