/**
 * 经营管理 - 合同管理 API
 */
import request from './request'

// ===== 合同 =====
export function getContractList(params) { return request({ url: '/business/contract/list', method: 'get', params }) }
export function getContractDetail(id) { return request({ url: `/business/contract/detail/${id}`, method: 'get' }) }
export function getContractSuggestNo() { return request({ url: '/business/contract/suggest-no', method: 'get' }) }
export function addContract(data) { return request({ url: '/business/contract/add', method: 'post', data }) }
export function editContract(id, data) { return request({ url: `/business/contract/edit/${id}`, method: 'put', data }) }
export function deleteContract(id) { return request({ url: `/business/contract/delete/${id}`, method: 'delete' }) }
export function submitContract(id) { return request({ url: `/business/contract/submit/${id}`, method: 'put' }) }
export function approveContract(id, data) { return request({ url: `/business/contract/approve/${id}`, method: 'put', data }) }
export function rejectContract(id, data) { return request({ url: `/business/contract/reject/${id}`, method: 'put', data }) }
export function effectContract(id) { return request({ url: `/business/contract/effect/${id}`, method: 'put' }) }
export function terminateContract(id, data) { return request({ url: `/business/contract/terminate/${id}`, method: 'put', data }) }
export function renewContract(id, data) { return request({ url: `/business/contract/renew/${id}`, method: 'post', data }) }
export function changeContract(id, data) { return request({ url: `/business/contract/change/${id}`, method: 'put', data }) }
export function voidContract(id) { return request({ url: `/business/contract/void/${id}`, method: 'put' }) }
export function changeContractStatus(id, data) { return request({ url: `/business/contract/status/${id}`, method: 'put', data }) }
export function copyContract(id) { return request({ url: `/business/contract/copy/${id}`, method: 'post' }) }
export function exportContract(params) { return request({ url: '/business/contract/export', method: 'get', params, responseType: 'blob' }) }
export function getContractStatistics() { return request({ url: '/business/contract/statistics', method: 'get' }) }

// ===== 到期提醒 =====
export function getContractRemindList(params) { return request({ url: '/business/contract/remind/list', method: 'get', params }) }
export function getContractRemindStatistics() { return request({ url: '/business/contract/remind/statistics', method: 'get' }) }

// ===== 电子签章 =====
export function initiateContractSign(id) { return request({ url: `/business/contract/sign/initiate/${id}`, method: 'post' }) }
export function getContractSignUrl(id) { return request({ url: `/business/contract/sign/url/${id}`, method: 'get' }) }
export function getContractSignStatus(id) { return request({ url: `/business/contract/sign/status/${id}`, method: 'get' }) }
export function resendContractSign(id) { return request({ url: `/business/contract/sign/resend/${id}`, method: 'post' }) }

// ===== 模板集成（列表/详情：预览/生成/导出） =====
export function previewContractByTemplate(data) { return request({ url: '/business/contract/preview', method: 'post', data }) }
export function generateContractByTemplate(data) { return request({ url: '/business/contract/generate', method: 'post', data }) }
export function exportContractWord(id) { return request({ url: `/business/contract/export-word/${id}`, method: 'get', responseType: 'blob' }) }
export function exportContractPdf(id) { return request({ url: `/business/contract/export-pdf/${id}`, method: 'get', responseType: 'blob' }) }
// 合同关联订单（多订单可关联同一合同）
export function getContractOrderList(contractId) { return request({ url: `/business/contract/order/list/${contractId}`, method: 'get' }) }
export function bindContractOrder(contractId, orderId, action) { return request({ url: '/business/contract/order/bind', method: 'post', data: { contract_id: contractId, order_id: orderId, action } }) }
