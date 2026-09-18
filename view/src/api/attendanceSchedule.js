/**
 * 考勤管理 - 排班管理 API
 * 路由前缀：/hr/attendance/schedule
 */
import request from './request'

/** 排班日历（员工某月） */
export const getScheduleCalendar = (p) => request({ url: '/hr/attendance/schedule/calendar', method: 'get', params: p })

/** 员工排班列表 */
export const getEmployeeScheduleList = (p) => request({ url: '/hr/attendance/schedule/employee-list', method: 'get', params: p })

/** 可排班员工列表 */
export const getScheduleEmployees = (p) => request({ url: '/hr/attendance/schedule/employees', method: 'get', params: p })

/** 单个排班 */
export const setSchedule = (d) => request({ url: '/hr/attendance/schedule/set', method: 'post', data: d })

/** 批量排班（按员工） */
export const batchSetSchedule = (d) => request({ url: '/hr/attendance/schedule/batch-set', method: 'post', data: d })

/** 按部门批量排班 */
export const batchSetScheduleByDept = (d) => request({ url: '/hr/attendance/schedule/batch-by-department', method: 'post', data: d })

/** 调班换班 */
export const swapSchedule = (d) => request({ url: '/hr/attendance/schedule/swap', method: 'post', data: d })

/** 复制排班（源周→目标周） */
export const copySchedule = (d) => request({ url: '/hr/attendance/schedule/copy', method: 'post', data: d })

/** 删除排班（设为休息） */
export const deleteSchedule = (p) => request({ url: '/hr/attendance/schedule/delete', method: 'delete', data: p })

/** 导出排班表 */
export const exportSchedule = (p) => request({ url: '/hr/attendance/schedule/export', method: 'get', params: p })

/** 排班统计 */
export const getScheduleStatistics = (p) => request({ url: '/hr/attendance/schedule/statistics', method: 'get', params: p })
