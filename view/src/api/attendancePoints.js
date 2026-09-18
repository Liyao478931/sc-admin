/**
 * 打卡点管理 API
 * 路由前缀：/hr/attendance/points
 */
import request from './request'

/** 获取打卡点列表 */
export const getPointsList = (params) => request({ url: '/hr/attendance/points/list', method: 'get', params })

/** 获取打卡点详情 */
export const getPointDetail = (id) => request({ url: `/hr/attendance/points/detail/${id}`, method: 'get' })

/** 新增打卡点 */
export const createPoint = (data) => request({ url: '/hr/attendance/points/add', method: 'post', data })

/** 更新打卡点 */
export const updatePoint = (id, data) => request({ url: `/hr/attendance/points/edit/${id}`, method: 'put', data })

/** 删除打卡点 */
export const deletePoint = (id) => request({ url: `/hr/attendance/points/delete/${id}`, method: 'delete' })

/** 启停打卡点 */
export const togglePoint = (id, status) => request({ url: `/hr/attendance/points/toggle/${id}`, method: 'post', data: { status } })
