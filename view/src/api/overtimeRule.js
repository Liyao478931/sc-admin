/**
 * 加班规则配置 API
 */
import request from './request'

export function getOvertimeRules() { return request({ url: '/salary/overtime/rules', method: 'get' }) }
export function saveOvertimeRule(data) { return request({ url: '/salary/overtime/rule/save', method: 'post', data }) }
export function getOvertimeHolidays(params) { return request({ url: '/salary/overtime/holidays', method: 'get', params }) }
export function saveOvertimeHoliday(data) { return request({ url: '/salary/overtime/holiday/save', method: 'post', data }) }
export function deleteOvertimeHoliday(id) { return request({ url: `/salary/overtime/holiday/delete/${id}`, method: 'delete' }) }
export function getOvertimeSpecial() { return request({ url: '/salary/overtime/special', method: 'get' }) }
export function saveOvertimeSpecial(data) { return request({ url: '/salary/overtime/special/save', method: 'post', data }) }
export function deleteOvertimeSpecial(id) { return request({ url: `/salary/overtime/special/delete/${id}`, method: 'delete' }) }
