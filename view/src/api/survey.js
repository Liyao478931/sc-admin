/**
 * 问卷管理 API
 */
import request from './request'

export function getSurveyList(params) { return request({ url: '/survey/list', method: 'get', params }) }
export function getSurveyDetail(id) { return request({ url: '/survey/detail', method: 'get', params: { id } }) }
export function saveSurvey(data) { return request({ url: '/survey/save', method: 'post', data }) }
export function toggleSurvey(data) { return request({ url: '/survey/toggle', method: 'post', data }) }
export function deleteSurvey(id) { return request({ url: '/survey/delete', method: 'post', data: { id } }) }
export function copySurvey(data) { return request({ url: '/survey/copy', method: 'post', data }) }
export function getSurveyStats(id) { return request({ url: '/survey/stats', method: 'get', params: { id } }) }
export function exportSurveyCsv(id) { return request({ url: '/survey/export', method: 'get', params: { id }, responseType: 'blob' }) }
