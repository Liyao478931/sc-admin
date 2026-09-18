/**
 * 多端版本管理 API（v1.69.0）
 * 路由前缀：/settings/versions
 */
import request from './request'

/** 多端总览 */
export const getMultiVersionDashboard = () => request({ url: '/settings/versions/dashboard', method: 'get' })

/** 版本列表（平台筛选） */
export const getMultiVersionList = (params) => request({ url: '/settings/versions/list', method: 'get', params })

/** 创建版本 */
export const createMultiVersion = (data) => request({ url: '/settings/versions/create', method: 'post', data })

/** 版本详情 */
export const getMultiVersionDetail = (id) => request({ url: `/settings/versions/detail/${id}`, method: 'get' })

/** 更新版本 */
export const updateMultiVersion = (id, data) => request({ url: `/settings/versions/update/${id}`, method: 'put', data })

/** 提交灰度 */
export const grayMultiVersion = (id, grayRatio) => request({ url: `/settings/versions/gray/${id}`, method: 'post', data: { gray_ratio: grayRatio } })

/** 调整灰度比例 */
export const grayRatioMultiVersion = (id, grayRatio) => request({ url: `/settings/versions/gray-ratio/${id}`, method: 'put', data: { gray_ratio: grayRatio } })

/** 全量发布 */
export const publishMultiVersion = (id) => request({ url: `/settings/versions/publish/${id}`, method: 'post' })

/** 回滚 */
export const rollbackMultiVersion = (id) => request({ url: `/settings/versions/rollback/${id}`, method: 'post' })

/** 删除版本 */
export const deleteMultiVersion = (id) => request({ url: `/settings/versions/delete/${id}`, method: 'delete' })

/** 发布日志 */
export const getMultiVersionLogs = (params) => request({ url: '/settings/versions/logs', method: 'get', params })
