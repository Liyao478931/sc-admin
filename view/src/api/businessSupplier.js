/**
 * 经营管理 - 供应商管理 API
 */
import request from './request'

// ===== 供应商 =====
export function getSupplierList(params) { return request({ url: '/business/supplier/list', method: 'get', params }) }
export function getSupplierDetail(id) { return request({ url: `/business/supplier/detail/${id}`, method: 'get' }) }
export function getSupplierOptions() { return request({ url: '/business/supplier/options', method: 'get' }) }
export function addSupplier(data) { return request({ url: '/business/supplier/add', method: 'post', data }) }
export function editSupplier(id, data) { return request({ url: `/business/supplier/edit/${id}`, method: 'put', data }) }
export function deleteSupplier(id) { return request({ url: `/business/supplier/delete/${id}`, method: 'delete' }) }
export function updateSupplierStatus(id, status) { return request({ url: `/business/supplier/status/${id}`, method: 'put', data: { status } }) }
export function updateSupplierLevel(id, level) { return request({ url: `/business/supplier/level/${id}`, method: 'put', data: { supplier_level: level } }) }
export function importSupplier(formData) { return request({ url: '/business/supplier/import', method: 'post', data: formData }) }
export function exportSupplier(params) { return request({ url: '/business/supplier/export', method: 'get', params, responseType: 'blob' }) }
export function getSupplierStatistics() { return request({ url: '/business/supplier/statistics', method: 'get' }) }

// ===== 供应商分类 =====
export function getSupplierCategoryList(params) { return request({ url: '/business/supplier/category/list', method: 'get', params }) }
export function getSupplierCategoryOptions() { return request({ url: '/business/supplier/category/options', method: 'get' }) }
export function addSupplierCategory(data) { return request({ url: '/business/supplier/category/add', method: 'post', data }) }
export function editSupplierCategory(id, data) { return request({ url: `/business/supplier/category/edit/${id}`, method: 'put', data }) }
export function deleteSupplierCategory(id) { return request({ url: `/business/supplier/category/delete/${id}`, method: 'delete' }) }
export function updateSupplierCategoryStatus(id, status) { return request({ url: `/business/supplier/category/status/${id}`, method: 'put', data: { status } }) }
