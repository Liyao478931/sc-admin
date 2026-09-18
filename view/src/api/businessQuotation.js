/**
 * 经营管理 - 报价管理 API
 */
import request from './request'

// ===== 报价单 =====
export function getQuotationList(params) { return request({ url: '/business/quotation/list', method: 'get', params }) }
export function getQuotationDetail(id) { return request({ url: `/business/quotation/detail/${id}`, method: 'get' }) }
export function getQuotationSuggestNo() { return request({ url: '/business/quotation/suggest-no', method: 'get' }) }
export function addQuotation(data) { return request({ url: '/business/quotation/add', method: 'post', data }) }
export function editQuotation(id, data) { return request({ url: `/business/quotation/edit/${id}`, method: 'put', data }) }
export function deleteQuotation(id) { return request({ url: `/business/quotation/delete/${id}`, method: 'delete' }) }
export function submitQuotation(id) { return request({ url: `/business/quotation/submit/${id}`, method: 'put' }) }
export function approveQuotation(id, data) { return request({ url: `/business/quotation/approve/${id}`, method: 'put', data }) }
export function rejectQuotation(id, data) { return request({ url: `/business/quotation/reject/${id}`, method: 'put', data }) }
export function convertQuotation(id) { return request({ url: `/business/quotation/convert/${id}`, method: 'post' }) }
export function copyQuotation(id) { return request({ url: `/business/quotation/copy/${id}`, method: 'post' }) }
export function exportQuotation(params) { return request({ url: '/business/quotation/export', method: 'get', params, responseType: 'blob' }) }
export function getQuotationStatistics() { return request({ url: '/business/quotation/statistics', method: 'get' }) }

// ===== 审核 =====
export function getQuotationReviewList(params) { return request({ url: '/business/quotation/review/list', method: 'get', params }) }
export function getQuotationReviewDetail(id) { return request({ url: `/business/quotation/review/detail/${id}`, method: 'get' }) }
