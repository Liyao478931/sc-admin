/**
 * 考勤统计 API
 */
import request from './request'

export function getAttendanceStatistics(params) { return request({ url: '/hr/attendance/statistics', method: 'get', params }) }
export function getAttendanceDetail(userId, params) { return request({ url: `/hr/attendance/statistics/detail/${userId}`, method: 'get', params }) }
export function batchMarkAttendance(data) { return request({ url: '/hr/attendance/statistics/batch-mark', method: 'post', data }) }
export function exportAttendanceStatistics(params) { return request({ url: '/hr/attendance/statistics/export', method: 'get', params, responseType: 'blob' }) }
export function getDepartmentOptions() { return request({ url: '/organization/departments', method: 'get' }) }
