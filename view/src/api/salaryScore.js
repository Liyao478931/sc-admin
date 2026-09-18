/**
 * 工分汇总 API
 */
import request from './request'

export function getScoreSummary(params) { return request({ url: '/hr/salary/score/summary', method: 'get', params }) }
export function getScoreDetail(userId, params) { return request({ url: `/hr/salary/score/detail/${userId}`, method: 'get', params }) }
export function exportScoreSummary(params) { return request({ url: '/hr/salary/score/export', method: 'get', params, responseType: 'blob' }) }
