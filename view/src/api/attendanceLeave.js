/**
 * 假勤申请 API
 */
import request from './request'

export function getLeaveList(params) { return request({ url: '/hr/attendance/leave/list', method: 'get', params }) }
export function getLeaveDetail(id) { return request({ url: `/hr/attendance/leave/detail/${id}`, method: 'get' }) }
export function saveLeave(data) { return request({ url: '/hr/attendance/leave/save', method: 'post', data }) }
export function deleteLeave(id) { return request({ url: `/hr/attendance/leave/delete/${id}`, method: 'delete' }) }
export function submitLeave(id) { return request({ url: `/hr/attendance/leave/submit/${id}`, method: 'post' }) }
export function approveLeave(id, remark) { return request({ url: `/hr/attendance/leave/approve/${id}`, method: 'post', data: { remark: remark || '' } }) }
export function rejectLeave(id, reason) { return request({ url: `/hr/attendance/leave/reject/${id}`, method: 'post', data: { reason } }) }
export function cancelLeave(id) { return request({ url: `/hr/attendance/leave/cancel/${id}`, method: 'post' }) }
export function urgeLeave(id) { return request({ url: `/hr/attendance/leave/urge/${id}`, method: 'post' }) }
export function uploadLeaveAttachment(formData) { return request({ url: '/hr/attendance/leave/upload', method: 'post', data: formData }) }
export function exportLeave(params) { return request({ url: '/hr/attendance/leave/export', method: 'get', params, responseType: 'blob' }) }
