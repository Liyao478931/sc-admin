/**
 * 物流服务管理 API
 * 路由前缀：/services/logistics（后台，需登录）
 */
import request from './request'

/** 配置列表 */
export const getLogisticsList = (p) => request({ url: '/services/logistics/list', method: 'get', params: p })

/** 新增配置 */
export const saveLogistics = (d) => request({ url: '/services/logistics/save', method: 'post', data: d })

/** 编辑配置 */
export const updateLogistics = (id, d) => request({ url: `/services/logistics/update/${id}`, method: 'post', data: d })

/** 删除配置 */
export const deleteLogistics = (id) => request({ url: `/services/logistics/delete/${id}`, method: 'post' })

/** 测试连接 */
export const testLogistics = (id, trackingNo) => request({ url: `/services/logistics/test/${id}`, method: 'post', data: { tracking_no: trackingNo } })

/** 设为默认 */
export const setDefaultLogistics = (id) => request({ url: `/services/logistics/set-default/${id}`, method: 'post' })

/** 启用/停用 */
export const toggleLogistics = (id) => request({ url: `/services/logistics/toggle/${id}`, method: 'post' })

/** 调用日志列表 */
export const getLogisticsLogs = (p) => request({ url: '/services/logistics/logs', method: 'get', params: p })

/** 统一轨迹查询 */
export const queryLogistics = (d) => request({ url: '/services/logistics/query', method: 'post', data: d })

/** 订阅推送 */
export const subscribeLogistics = (d) => request({ url: '/services/logistics/subscribe', method: 'post', data: d })
