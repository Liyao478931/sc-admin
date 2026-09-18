/**
 * 维修工单 API 封装
 */
import request from './request'

export const getOrderList = (p) => request({ url: '/device/repair/order/list', method: 'get', params: p })
export const getOrderDetail = (id) => request({ url: `/device/repair/order/detail/${id}`, method: 'get' })
export const addOrder = (d) => request({ url: '/device/repair/order/add', method: 'post', data: d })
export const editOrder = (id, d) => request({ url: `/device/repair/order/edit/${id}`, method: 'put', data: d })
export const deleteOrder = (id) => request({ url: `/device/repair/order/delete/${id}`, method: 'delete' })
export const batchDeleteOrders = (ids) => request({ url: '/device/repair/order/batch-delete', method: 'delete', data: { ids } })
export const assignOrder = (id, d) => request({ url: `/device/repair/order/assign/${id}`, method: 'put', data: d })
export const batchAssignOrders = (ids, handlerId) => request({ url: '/device/repair/order/batch-assign', method: 'put', data: { ids, handler_id: handlerId } })
export const transferOrder = (id, d) => request({ url: `/device/repair/order/transfer/${id}`, method: 'put', data: d })
export const acceptOrder = (id, d) => request({ url: `/device/repair/order/accept/${id}`, method: 'put', data: d })
export const rejectOrder = (id, d) => request({ url: `/device/repair/order/reject/${id}`, method: 'put', data: d })
export const getOrderStatistics = () => request({ url: '/device/repair/order/statistics', method: 'get' })
export const exportOrders = (p) => request({ url: '/device/repair/order/export', method: 'get', params: p })
