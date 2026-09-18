/**
 * 维修记录 API 封装
 * 维修记录是维修工单验收通过后的归档视图（status=approved/closed）
 */
import request from './request'

// 记录列表（分页 + 多维度筛选）
export const getRecordList = (p) => request({ url: '/device/repair/record/list', method: 'get', params: p })
// 记录详情（完整档案：诊断/方案/过程/备件/验收）
export const getRecordDetail = (id) => request({ url: `/device/repair/record/detail/${id}`, method: 'get' })
// 设备维修履历
export const getRecordHistory = (p) => request({ url: '/device/repair/record/history', method: 'get', params: p })
// 导出维修记录（返回下载 url）
export const exportRecords = (p) => request({ url: '/device/repair/record/export', method: 'get', params: p })
// 记录统计（总/本月新增/本月时长/平均时长）
export const getRecordStatistics = () => request({ url: '/device/repair/record/statistics', method: 'get' })
// 有维修记录的设备列表（履历选择）
export const getRecordDevices = () => request({ url: '/device/repair/record/devices', method: 'get' })
// 有维修记录的维修人员列表（筛选）
export const getRecordHandlers = () => request({ url: '/device/repair/record/handlers', method: 'get' })
