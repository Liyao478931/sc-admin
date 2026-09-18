/**
 * AI 工具分类 API
 */
import request from './request'

// ===== 分类管理 =====
export function getToolCategories(params) { return request({ url: '/ai/tools/category/list', method: 'get', params }) }
export function getToolCategoryDetail(id) { return request({ url: `/ai/tools/category/detail/${id}`, method: 'get' }) }
export function getToolCategoryOptions() { return request({ url: '/ai/tools/category/options', method: 'get' }) }
export function addToolCategory(data) { return request({ url: '/ai/tools/category/add', method: 'post', data }) }
export function editToolCategory(id, data) { return request({ url: `/ai/tools/category/edit/${id}`, method: 'put', data }) }
export function deleteToolCategory(id) { return request({ url: `/ai/tools/category/delete/${id}`, method: 'delete' }) }
export function updateToolCategoryStatus(id, status) { return request({ url: `/ai/tools/category/status/${id}`, method: 'put', data: { status } }) }
export function batchSortToolCategories(items) { return request({ url: '/ai/tools/category/sort-batch', method: 'put', data: { items } }) }
export function getToolCategoryStatistics() { return request({ url: '/ai/tools/category/statistics', method: 'get' }) }
export function getToolCategoryTools(params) { return request({ url: '/ai/tools/category/tools', method: 'get', params }) }
