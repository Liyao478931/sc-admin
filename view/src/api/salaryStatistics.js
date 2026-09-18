/**
 * 薪酬统计 API
 */
import request from './request'

export function getSalaryStatistics(params) { return request({ url: '/hr/salary/statistics', method: 'get', params }) }
export function getSalaryStatisticsDetail(userId, params) { return request({ url: `/hr/salary/statistics/detail/${userId}`, method: 'get', params }) }
export function exportSalaryStatistics(params) { return request({ url: '/hr/salary/statistics/export', method: 'get', params, responseType: 'blob' }) }
