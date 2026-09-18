/**
 * 补助标准配置 API（学历补助 / 职称补助）
 */
import request from './request'

export function getSubsidyList(params) { return request({ url: '/salary/subsidy/list', method: 'get', params }) }
export function getSubsidyOptions(params) { return request({ url: '/salary/subsidy/options', method: 'get', params }) }
export function createSubsidy(data) { return request({ url: '/salary/subsidy/create', method: 'post', data }) }
export function updateSubsidy(id, data) { return request({ url: `/salary/subsidy/update/${id}`, method: 'put', data }) }
export function deleteSubsidy(id, type) { return request({ url: `/salary/subsidy/delete/${id}`, method: 'delete', params: { type } }) }
