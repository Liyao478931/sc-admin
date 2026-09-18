/**
 * 销售出库单 API（经营管理 -> 销售管理 -> 出库单列表）
 * 复用产品出库控制器（warehouse_product_out），接口路径 /business/sales/out/*
 */
import request from './request'

export function getSalesOutList(params) { return request({ url: '/business/sales/out/list', method: 'get', params }) }
export function getSalesOutDetail(id) { return request({ url: `/business/sales/out/detail/${id}`, method: 'get' }) }
export function saveSalesOut(data) { return request({ url: '/business/sales/out/save', method: 'post', data }) }
export function deleteSalesOut(id) { return request({ url: `/business/sales/out/delete/${id}`, method: 'delete' }) }
export function submitSalesOut(id) { return request({ url: `/business/sales/out/submit/${id}`, method: 'post' }) }
export function cancelSalesOut(id) { return request({ url: `/business/sales/out/cancel/${id}`, method: 'post' }) }
export function confirmSalesOut(id) { return request({ url: `/business/sales/out/confirm/${id}`, method: 'post' }) }
export function shipSalesOut(id, data) { return request({ url: `/business/sales/out/ship/${id}`, method: 'post', data }) }
export function getSalesOutLogs(id) { return request({ url: `/business/sales/out/logs/${id}`, method: 'get' }) }
export function exportSalesOut(params) { return request({ url: '/business/sales/out/export', method: 'get', params, responseType: 'blob' }) }

// 新增出库单：可出库订单列表（已确认且未全部出库，支持分批）
export function getAvailableOrders() { return request({ url: '/business/sales/order/available-for-out', method: 'get' }) }

// 发货通知
export function getNoticeList(params) { return request({ url: '/business/sales/ship/notice/list', method: 'get', params }) }
export function getNoticeDetail(id) { return request({ url: `/business/sales/ship/notice/detail/${id}`, method: 'get' }) }
export function getAvailableShipOrders() { return request({ url: '/business/sales/order/available-for-ship', method: 'get' }) }
export function saveNotice(data) { return request({ url: '/business/sales/ship/notice/save', method: 'post', data }) }
export function deleteNotice(id) { return request({ url: `/business/sales/ship/notice/delete/${id}`, method: 'delete' }) }
export function submitNotice(id) { return request({ url: `/business/sales/ship/notice/submit/${id}`, method: 'post' }) }
export function revokeNotice(id) { return request({ url: `/business/sales/ship/notice/revoke/${id}`, method: 'post' }) }
export function cancelNotice(id) { return request({ url: `/business/sales/ship/notice/cancel/${id}`, method: 'post' }) }
export function pushNotice(id) { return request({ url: `/business/sales/ship/notice/push/${id}`, method: 'post' }) }
export function batchSubmitNotices(ids) { return request({ url: '/business/sales/ship/notice/batch-submit', method: 'post', data: { ids } }) }
export function exportNotice(params) { return request({ url: '/business/sales/ship/notice/export', method: 'get', params, responseType: 'blob' }) }

// 发货单
export function getShipList(params) { return request({ url: '/business/sales/ship/list', method: 'get', params }) }
export function getShipDetail(id) { return request({ url: `/business/sales/ship/detail/${id}`, method: 'get' }) }
export function generateShip(outId) { return request({ url: `/business/sales/ship/generate/${outId}`, method: 'post' }) }
export function saveShip(data) { return request({ url: '/business/sales/ship/save', method: 'post', data }) }
export function deleteShip(id) { return request({ url: `/business/sales/ship/delete/${id}`, method: 'delete' }) }
export function confirmShip(id, data) { return request({ url: `/business/sales/ship/confirm/${id}`, method: 'post', data }) }
export function signShip(id, data) { return request({ url: `/business/sales/ship/sign/${id}`, method: 'post', data }) }
export function cancelShip(id) { return request({ url: `/business/sales/ship/cancel/${id}`, method: 'post' }) }
export function exportShip(params) { return request({ url: '/business/sales/ship/export', method: 'get', params, responseType: 'blob' }) }

// 物流跟踪
export function getTrackList(params) { return request({ url: '/business/sales/ship/track/list', method: 'get', params }) }
export function getTrackDetail(id) { return request({ url: `/business/sales/ship/track/detail/${id}`, method: 'get' }) }
export function refreshTrack(id) { return request({ url: `/business/sales/ship/track/refresh/${id}`, method: 'post' }) }
export function batchRefreshTrack(data) { return request({ url: '/business/sales/ship/track/batch-refresh', method: 'post', data }) }
export function exportTrack(params) { return request({ url: '/business/sales/ship/track/export', method: 'get', params, responseType: 'blob' }) }

// 销售额分析
export function getRevenueOverview(params) { return request({ url: '/business/sales/statistics/revenue/overview', method: 'get', params }) }
export function getRevenueTrend(params) { return request({ url: '/business/sales/statistics/revenue/trend', method: 'get', params }) }
export function getRevenueCategory(params) { return request({ url: '/business/sales/statistics/revenue/category', method: 'get', params }) }
export function getCustomerRanking(params) { return request({ url: '/business/sales/statistics/revenue/customer-ranking', method: 'get', params }) }
export function getSalespersonRanking(params) { return request({ url: '/business/sales/statistics/revenue/salesperson-ranking', method: 'get', params }) }
export function getRevenueDetails(params) { return request({ url: '/business/sales/statistics/revenue/details', method: 'get', params }) }
export function exportRevenue(params) { return request({ url: '/business/sales/statistics/revenue/export', method: 'get', params, responseType: 'blob' }) }
export function getRevenueOptions() { return request({ url: '/business/sales/statistics/revenue/options', method: 'get' }) }

// 客户排行
export function getCustomerRankingList(params) { return request({ url: '/business/sales/statistics/customer/list', method: 'get', params }) }
export function exportCustomerRanking(params) { return request({ url: '/business/sales/statistics/customer/export', method: 'get', params, responseType: 'blob' }) }

// 产品排行
export function getProductRanking(params) { return request({ url: '/business/sales/statistics/product/list', method: 'get', params }) }
export function exportProductRanking(params) { return request({ url: '/business/sales/statistics/product/export', method: 'get', params, responseType: 'blob' }) }
export function getProductRankingOptions() { return request({ url: '/business/sales/statistics/product/options', method: 'get' }) }
