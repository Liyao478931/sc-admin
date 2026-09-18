/**
 * 经营管理 - 经营总览 API
 */
import request from './request'

// ===== 经营总览 =====
export function getOverviewData(params) { return request({ url: '/business/dashboard/overview', method: 'get', params }) }
export function getDepartments() { return request({ url: '/organization/departments', method: 'get' }) }
