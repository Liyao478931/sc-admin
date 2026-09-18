/**
 * 考勤管理 - 班次设置 API
 * 路由前缀：/hr/attendance/shift
 */
import request from './request'

/** 班次列表（分页 + 筛选） */
export const getShiftList = (p) => request({ url: '/hr/attendance/shift/list', method: 'get', params: p })

/** 班次详情 */
export const getShiftDetail = (id) => request({ url: '/hr/attendance/shift/detail/' + id, method: 'get' })

/** 班次下拉选项（启用，排班管理用） */
export const getShiftOptions = () => request({ url: '/hr/attendance/shift/options', method: 'get' })

/** 新增班次 */
export const addShift = (d) => request({ url: '/hr/attendance/shift/add', method: 'post', data: d })

/** 编辑班次 */
export const editShift = (id, d) => request({ url: '/hr/attendance/shift/edit/' + id, method: 'put', data: d })

/** 删除班次 */
export const deleteShift = (id) => request({ url: '/hr/attendance/shift/delete/' + id, method: 'delete' })

/** 复制班次 */
export const copyShift = (id) => request({ url: '/hr/attendance/shift/copy/' + id, method: 'post' })

/** 切换状态 */
export const toggleShiftStatus = (id, status) => request({ url: '/hr/attendance/shift/status/' + id, method: 'put', data: { status } })

/** 班次统计 */
export const getShiftStatistics = () => request({ url: '/hr/attendance/shift/statistics', method: 'get' })
