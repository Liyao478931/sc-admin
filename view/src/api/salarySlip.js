/**
 * 生成工资条 / 工资条查询 API
 */
import request from './request'

export function getSlipGenerateList(params) { return request({ url: '/hr/salary/slip/generate/list', method: 'get', params }) }
export function generateSlipBatch(data) { return request({ url: '/hr/salary/slip/generate/batch', method: 'post', data }) }
export function generateSlipSingle(userId, data) { return request({ url: `/hr/salary/slip/generate/single/${userId}`, method: 'post', data }) }
export function regenerateSlip(id) { return request({ url: `/hr/salary/slip/generate/regenerate/${id}`, method: 'post' }) }
export function previewSlip(id) { return request({ url: `/hr/salary/slip/preview/${id}`, method: 'get' }) }
export function sendSlipBatch(data) { return request({ url: '/hr/salary/slip/send/batch', method: 'post', data }) }
export function sendSlipSingle(id) { return request({ url: `/hr/salary/slip/send/single/${id}`, method: 'post' }) }
// ---- 工资条查询 ----
export function getSlipList(params) { return request({ url: '/hr/salary/slip/list', method: 'get', params }) }
export function exportSlip(params) { return request({ url: '/hr/salary/slip/export', method: 'get', params, responseType: 'blob' }) }
export function resendSlip(id) { return request({ url: `/hr/salary/slip/resend/${id}`, method: 'post' }) }
export function batchResendSlip(data) { return request({ url: '/hr/salary/slip/resend/batch', method: 'post', data }) }
export function printSlip(id) { return request({ url: `/hr/salary/slip/print/${id}`, method: 'get' }) }
