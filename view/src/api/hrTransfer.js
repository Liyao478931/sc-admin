/**
 * 员工异动 API（人事管理 -> 员工异动）
 */
import request from './request'

export function getTransferList(params) { return request({ url: '/hr/transfer/list', method: 'get', params }) }
export function getTransferDetail(id) { return request({ url: `/hr/transfer/detail/${id}`, method: 'get' }) }
export function saveTransfer(data) { return request({ url: '/hr/transfer/save', method: 'post', data }) }
export function deleteTransfer(id) { return request({ url: `/hr/transfer/delete/${id}`, method: 'delete' }) }
export function submitTransfer(id) { return request({ url: `/hr/transfer/submit/${id}`, method: 'post' }) }
export function revokeTransfer(id) { return request({ url: `/hr/transfer/revoke/${id}`, method: 'post' }) }
export function confirmTransfer(id) { return request({ url: `/hr/transfer/confirm/${id}`, method: 'post' }) }
export function exportTransfer(params) { return request({ url: '/hr/transfer/export', method: 'get', params, responseType: 'blob' }) }
export function uploadTransferAttachment(formData) { return request({ url: '/hr/transfer/upload', method: 'post', data: formData }) }
export function getTransferOptions() { return request({ url: '/hr/transfer/options', method: 'get' }) }
export function getTransferEmployees(params) { return request({ url: '/hr/transfer/employees', method: 'get', params }) }
