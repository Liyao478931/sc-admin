/**
 * 钉钉服务管理 API
 * 路由前缀：/services/dingtalk
 */
import request from './request'

/** 获取钉钉服务配置 */
export const getDingtalkConfig = () => request({ url: '/services/dingtalk/config', method: 'get' })

/** 保存钉钉服务配置 */
export const saveDingtalkConfig = (d) => request({ url: '/services/dingtalk/config', method: 'put', data: d })

/** 测试连接 */
export const testDingtalk = () => request({ url: '/services/dingtalk/test', method: 'post' })

/** 同步状态 */
export const getDingtalkSyncStatus = () => request({ url: '/services/dingtalk/sync-status', method: 'get' })

/** 手动同步 */
export const syncDingtalk = (dataTypes) => request({ url: '/services/dingtalk/sync', method: 'post', data: { data_types: dataTypes } })

/** 用户映射列表 */
export const getDingtalkUserMap = (p) => request({ url: '/services/dingtalk/user-map', method: 'get', params: p })

/** 绑定用户映射 */
export const bindDingtalkUserMap = (d) => request({ url: '/services/dingtalk/user-map/bind', method: 'post', data: d })

/** 解绑用户映射 */
export const unbindDingtalkUserMap = (id) => request({ url: '/services/dingtalk/user-map/unbind', method: 'delete', data: { id } })

/** 导入用户映射（Excel） */
export const importDingtalkUserMap = (formData) => request({ url: '/services/dingtalk/user-map/import', method: 'post', data: formData })

/** 同步日志列表 */
export const getDingtalkSyncLogs = (p) => request({ url: '/services/dingtalk/sync-logs', method: 'get', params: p })
