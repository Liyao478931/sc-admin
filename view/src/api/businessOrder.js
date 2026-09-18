/**
 * 经营管理 - 订单管理 API
 */
import request from './request'

// ===== 订单 =====
export function getOrderList(params) { return request({ url: '/business/order/list', method: 'get', params }) }
export function getOrderDetail(id) { return request({ url: `/business/order/detail/${id}`, method: 'get' }) }
export function getOrderSuggestNo() { return request({ url: '/business/order/suggest-no', method: 'get' }) }
export function addOrder(data) { return request({ url: '/business/order/add', method: 'post', data }) }
export function editOrder(id, data) { return request({ url: `/business/order/edit/${id}`, method: 'put', data }) }
export function deleteOrder(id) { return request({ url: `/business/order/delete/${id}`, method: 'delete' }) }
export function submitOrder(id) { return request({ url: `/business/order/submit/${id}`, method: 'put' }) }
export function reviewPassOrder(id, data) { return request({ url: `/business/order/review-pass/${id}`, method: 'put', data }) }
export function reviewRejectOrder(id, data) { return request({ url: `/business/order/review-reject/${id}`, method: 'put', data }) }
export function changeOrderStatus(id, data) { return request({ url: `/business/order/status/${id}`, method: 'put', data }) }
export function copyOrder(id) { return request({ url: `/business/order/copy/${id}`, method: 'post' }) }
export function exportOrder(params) { return request({ url: '/business/order/export', method: 'get', params, responseType: 'blob' }) }
export function getOrderStatistics() { return request({ url: '/business/order/statistics', method: 'get' }) }
// 订单关联合同（多订单可关联同一合同；contract_id=0 解除）
export function bindOrderContract(id, contractId) { return request({ url: '/business/order/contract/bind', method: 'post', data: { id, contract_id: contractId } }) }

// ===== 评审 =====
export function getReviewList(params) { return request({ url: '/business/order/review/list', method: 'get', params }) }
export function getReviewDetail(id) { return request({ url: `/business/order/review/detail/${id}`, method: 'get' }) }
