/**
 * 安全管理：隐患管理 API 封装
 */
import request from './request'

export const getHazardList = (p) => request({ url: '/safety/hazard/list', method: 'get', params: p })
export const getHazardDetail = (id) => request({ url: `/safety/hazard/detail/${id}`, method: 'get' })
export const exportHazards = (p) => request({ url: '/safety/hazard/export', method: 'get', params: p })
export const getHazardStatistics = () => request({ url: '/safety/hazard/statistics', method: 'get' })
export const getHazardTrend = (range) => request({ url: '/safety/hazard/trend', method: 'get', params: { range } })
export const batchDeleteHazards = (ids) => request({ url: '/safety/hazard/batch-delete', method: 'delete', data: { ids } })
export const changeHazardStatus = (id, data) => request({ url: `/safety/hazard/status/${id}`, method: 'put', data })
export const getHazardSourceDetail = (id) => request({ url: `/safety/hazard/source-detail/${id}`, method: 'get' })
export const createHazard = (data) => request({ url: '/safety/hazard/create', method: 'post', data })
export const deleteHazard = (id) => request({ url: `/safety/hazard/delete/${id}`, method: 'delete' })
// 隐患登记
export const suggestHazardCode = () => request({ url: '/safety/hazard/suggest-code', method: 'get' })
export const addHazard = (data) => request({ url: '/safety/hazard/add', method: 'post', data })
export const getAvailableInspections = (keyword) => request({ url: '/safety/hazard/available-inspections', method: 'get', params: { keyword } })
export const getAvailableSafetyChecks = (keyword) => request({ url: '/safety/hazard/available-safety-checks', method: 'get', params: { keyword } })
export const getAvailableRepairs = (keyword) => request({ url: '/safety/hazard/available-repairs', method: 'get', params: { keyword } })
export const getSourcePreview = (sourceType, sourceId) => request({ url: '/safety/hazard/source-preview', method: 'get', params: { source_type: sourceType, source_id: sourceId } })
// 整改/验证闭环
export const editHazard = (id, data) => request({ url: `/safety/hazard/edit/${id}`, method: 'put', data })
export const getHandleList = (p) => request({ url: '/safety/hazard/handle-list', method: 'get', params: p })
export const handleComplete = (id, data) => request({ url: `/safety/hazard/handle-complete/${id}`, method: 'put', data })
export const getVerifyList = (p) => request({ url: '/safety/hazard/verify-list', method: 'get', params: p })
export const getVerifyDetail = (id) => request({ url: `/safety/hazard/verify-detail/${id}`, method: 'get' })
export const getVerifyHistory = (id) => request({ url: `/safety/hazard/verify-history/${id}`, method: 'get' })
export const verifyPass = (id, data) => request({ url: `/safety/hazard/verify-pass/${id}`, method: 'put', data })
export const verifyReject = (id, data) => request({ url: `/safety/hazard/verify-reject/${id}`, method: 'put', data })
export const getVerifyStatistics = () => request({ url: '/safety/hazard/verify-statistics', method: 'get' })
// 隐患详情
export const getOperationLog = (id) => request({ url: `/safety/hazard/operation-log/${id}`, method: 'get' })
export const reopenHazard = (id) => request({ url: `/safety/hazard/reopen/${id}`, method: 'put' })
