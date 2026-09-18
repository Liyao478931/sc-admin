/**
 * 考勤管理 - 打卡记录 API
 * 路由前缀：/hr/attendance/record
 */
import request from './request'

/** 打卡记录列表 */
export const getRecordList = (p) => request({ url: '/hr/attendance/record/list', method: 'get', params: p })

/** 打卡记录详情 */
export const getRecordDetail = (id) => request({ url: '/hr/attendance/record/detail/' + id, method: 'get' })

/** 打卡记录统计 */
export const getRecordStatistics = () => request({ url: '/hr/attendance/record/statistics', method: 'get' })

/** 手动补录打卡 */
export const addRecord = (d) => request({ url: '/hr/attendance/record/add', method: 'post', data: d })

/** 删除打卡记录（仅手动） */
export const deleteRecord = (id) => request({ url: '/hr/attendance/record/delete/' + id, method: 'delete' })

/** 修正打卡记录 */
export const fixRecord = (d) => request({ url: '/hr/attendance/record/fix', method: 'post', data: d })

/** 导出发卡记录 */
export const exportRecord = (p) => request({ url: '/hr/attendance/record/export', method: 'get', params: p })
