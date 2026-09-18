/**
 * 经营管理 - 采购申请 API
 */
import request from './request'

// ===== 采购申请 =====
export function getRequestList(params) { return request({ url: '/business/purchase/request/list', method: 'get', params }) }
export function getRequestDetail(id) { return request({ url: `/business/purchase/request/detail/${id}`, method: 'get' }) }
export function saveRequest(data) { return request({ url: '/business/purchase/request/save', method: 'post', data }) }
export function deleteRequest(id) { return request({ url: `/business/purchase/request/delete/${id}`, method: 'delete' }) }
export function submitRequest(id) { return request({ url: `/business/purchase/request/submit/${id}`, method: 'post' }) }
export function cancelRequest(id) { return request({ url: `/business/purchase/request/cancel/${id}`, method: 'post' }) }
export function approveRequest(id, remark) { return request({ url: `/business/purchase/request/approve/${id}`, method: 'post', data: { approval_remark: remark } }) }
export function rejectRequest(id, remark) { return request({ url: `/business/purchase/request/reject/${id}`, method: 'post', data: { approval_remark: remark } }) }
export function copyRequest(id) { return request({ url: `/business/purchase/request/copy/${id}`, method: 'get' }) }
export function getRequestTracking(id) { return request({ url: `/business/purchase/request/tracking/${id}`, method: 'get' }) }
export function exportRequests(params) { return request({ url: '/business/purchase/request/export', method: 'get', params, responseType: 'blob' }) }
export function getSourceOrderDetail(sourceType, sourceId) { return request({ url: '/business/purchase/request/source-detail', method: 'get', params: { source_type: sourceType, source_id: sourceId } }) }
export function getSourceOptions(sourceType, keyword) { return request({ url: '/business/purchase/request/source-options', method: 'get', params: { source_type: sourceType, keyword: keyword || '' } }) }
export function generateOrder(id) { return request({ url: `/business/purchase/request/generate-order/${id}`, method: 'post' }) }
export function updateRequestContract(id, data) { return request({ url: `/business/purchase/request/update-contract/${id}`, method: 'put', data }) }

// ===== 部门 =====
export function getDepartmentList() { return request({ url: '/organization/departments', method: 'get' }) }

// ===== 采购订单 =====
export function getOrderList(params) { return request({ url: '/business/purchase/order/list', method: 'get', params }) }
export function getOrderDetail(id) { return request({ url: `/business/purchase/order/detail/${id}`, method: 'get' }) }
export function saveOrder(data) { return request({ url: '/business/purchase/order/save', method: 'post', data }) }
export function deleteOrder(id) { return request({ url: `/business/purchase/order/delete/${id}`, method: 'delete' }) }
export function submitOrderApproval(id) { return request({ url: `/business/purchase/order/submit/${id}`, method: 'post' }) }
export function approveOrder(id, remark) { return request({ url: `/business/purchase/order/approve/${id}`, method: 'post', data: { approval_remark: remark } }) }
export function rejectOrder(id, remark) { return request({ url: `/business/purchase/order/reject/${id}`, method: 'post', data: { approval_remark: remark } }) }
export function confirmOrder(id) { return request({ url: `/business/purchase/order/confirm/${id}`, method: 'post' }) }
export function registerShipment(id, data) { return request({ url: `/business/purchase/order/ship/${id}`, method: 'post', data }) }
export function registerReceipt(id, data) { return request({ url: `/business/purchase/order/receive/${id}`, method: 'post', data }) }
export function abortOrder(id) { return request({ url: `/business/purchase/order/abort/${id}`, method: 'post' }) }
export function getOrderLogs(id) { return request({ url: `/business/purchase/order/logs/${id}`, method: 'get' }) }
export function exportOrders(params) { return request({ url: '/business/purchase/order/export', method: 'get', params, responseType: 'blob' }) }
export function getOrderPool() { return request({ url: '/business/purchase/order/pool', method: 'get' }) }
export function checkOrderCode(code, id) { return request({ url: '/business/purchase/order/check-code', method: 'get', params: { code, id: id || 0 } }) }

// ===== 采购订单跟踪 =====
export function getOrderTrackList(params) { return request({ url: '/business/purchase/order/track/list', method: 'get', params }) }
export function getOrderLogistics(id) { return request({ url: `/business/purchase/order/track/logistics/${id}`, method: 'get' }) }
export function refreshLogistics(id, data) { return request({ url: `/business/purchase/order/track/refresh/${id}`, method: 'post', data }) }
export function sendReminder(id, data) { return request({ url: `/business/purchase/order/track/remind/${id}`, method: 'post', data }) }
export function getReminderHistory(id, params) { return request({ url: `/business/purchase/order/track/remind/history/${id}`, method: 'get', params }) }
export function exportTrackReport(params) { return request({ url: '/business/purchase/order/track/export', method: 'get', params, responseType: 'blob' }) }

// ===== 采购到货 =====
export function getArrivalList(params) { return request({ url: '/business/purchase/arrival/list', method: 'get', params }) }
export function getArrivalDetail(id) { return request({ url: `/business/purchase/arrival/detail/${id}`, method: 'get' }) }
export function saveArrival(data) { return request({ url: '/business/purchase/arrival/save', method: 'post', data }) }
export function deleteArrival(id) { return request({ url: `/business/purchase/arrival/delete/${id}`, method: 'delete' }) }
export function qualityArrival(id, data) { return request({ url: `/business/purchase/arrival/quality/${id}`, method: 'post', data }) }
export function warehouseArrival(id) { return request({ url: `/business/purchase/arrival/warehouse/${id}`, method: 'post' }) }
export function sendArrivalNotice(id, data) { return request({ url: `/business/purchase/arrival/notice/${id}`, method: 'post', data }) }
export function getArrivalNoticeHistory(id) { return request({ url: `/business/purchase/arrival/notice/history/${id}`, method: 'get' }) }
export function getArrivalRecord(params) { return request({ url: '/business/purchase/arrival/record', method: 'get', params }) }
export function exportArrivalRecord(params) { return request({ url: '/business/purchase/arrival/record/export', method: 'get', params, responseType: 'blob' }) }
export function getArrivableOrders() { return request({ url: '/business/purchase/order/arrivable', method: 'get' }) }

// ===== 采购统计 =====
export function getPurchaseOverview(params) { return request({ url: '/business/purchase/statistics/overview', method: 'get', params }) }
export function getPurchaseAmount(params) { return request({ url: '/business/purchase/statistics/amount', method: 'get', params }) }
export function getPurchaseSupplier(params) { return request({ url: '/business/purchase/statistics/supplier', method: 'get', params }) }
export function exportPurchaseAmount(params) { return request({ url: '/business/purchase/statistics/amount/export', method: 'get', params, responseType: 'blob' }) }
export function exportPurchaseSupplier(params) { return request({ url: '/business/purchase/statistics/supplier/export', method: 'get', params, responseType: 'blob' }) }

// ===== 产品接收 =====
export function getReceiveList(params) { return request({ url: '/business/receive/list', method: 'get', params }) }
export function getReceiveDetail(id) { return request({ url: `/business/receive/detail/${id}`, method: 'get' }) }
export function saveReceive(data) { return request({ url: '/business/receive/save', method: 'post', data }) }
export function deleteReceive(id) { return request({ url: `/business/receive/delete/${id}`, method: 'delete' }) }
export function confirmReceive(id) { return request({ url: `/business/receive/confirm/${id}`, method: 'post' }) }
export function warehouseReceive(id) { return request({ url: `/business/receive/warehouse/${id}`, method: 'post' }) }
export function exportReceive(params) { return request({ url: '/business/receive/export', method: 'get', params, responseType: 'blob' }) }
export function getReceiveArchive(params) { return request({ url: '/business/receive/archive/list', method: 'get', params }) }
export function getReceiveArchiveDetail(productId) { return request({ url: `/business/receive/archive/detail/${productId}`, method: 'get' }) }
export function exportReceiveArchive(params) { return request({ url: '/business/receive/archive/export', method: 'get', params, responseType: 'blob' }) }
export function getReceiveWorkOrders(keyword) { return request({ url: '/business/receive/work-orders', method: 'get', params: { keyword: keyword || '' } }) }
export function getReceiveCustomers() { return request({ url: '/business/receive/customers', method: 'get' }) }
