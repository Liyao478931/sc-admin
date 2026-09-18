/**
 * 经营管理 - 客户管理 API
 */
import request from './request'

// ===== 客户 =====
export function getCustomerList(params) { return request({ url: '/business/customer/list', method: 'get', params }) }
export function getCustomerDetail(id) { return request({ url: `/business/customer/detail/${id}`, method: 'get' }) }
export function getCustomerOptions() { return request({ url: '/business/customer/options', method: 'get' }) }
export function addCustomer(data) { return request({ url: '/business/customer/add', method: 'post', data }) }
export function editCustomer(id, data) { return request({ url: `/business/customer/edit/${id}`, method: 'put', data }) }
export function deleteCustomer(id) { return request({ url: `/business/customer/delete/${id}`, method: 'delete' }) }
export function updateCustomerStatus(id, status) { return request({ url: `/business/customer/status/${id}`, method: 'put', data: { status } }) }
export function importCustomer(formData) { return request({ url: '/business/customer/import', method: 'post', data: formData }) }
export function exportCustomer(params) { return request({ url: '/business/customer/export', method: 'get', params, responseType: 'blob' }) }
export function getCustomerStatistics() { return request({ url: '/business/customer/statistics', method: 'get' }) }
export function mergeCustomer(data) { return request({ url: '/business/customer/merge', method: 'post', data }) }

// ===== 客户分类 =====
export function getCategoryList(params) { return request({ url: '/business/customer/category/list', method: 'get', params }) }
export function getCategoryOptions() { return request({ url: '/business/customer/category/options', method: 'get' }) }
export function addCategory(data) { return request({ url: '/business/customer/category/add', method: 'post', data }) }
export function editCategory(id, data) { return request({ url: `/business/customer/category/edit/${id}`, method: 'put', data }) }
export function deleteCategory(id) { return request({ url: `/business/customer/category/delete/${id}`, method: 'delete' }) }
export function updateCategoryStatus(id, status) { return request({ url: `/business/customer/category/status/${id}`, method: 'put', data: { status } }) }
