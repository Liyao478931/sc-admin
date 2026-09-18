/**
 * 设备分类 API 封装
 */
import request from './request'

export function getCategoryTree(params) { return request({ url: '/device/category/tree', method: 'get', params }) }
export function getCategoryOptions() { return request({ url: '/device/category/options', method: 'get' }) }
export function getCategoryDetail(id) { return request({ url: `/device/category/detail/${id}`, method: 'get' }) }
export function addCategory(data) { return request({ url: '/device/category/add', method: 'post', data }) }
export function editCategory(id, data) { return request({ url: `/device/category/edit/${id}`, method: 'put', data }) }
export function deleteCategory(id) { return request({ url: `/device/category/delete/${id}`, method: 'delete' }) }
export function changeCategoryStatus(id, status) { return request({ url: `/device/category/status/${id}`, method: 'put', data: { status } }) }
export function suggestCategoryCode(params) { return request({ url: '/device/category/suggest-code', method: 'get', params }) }
