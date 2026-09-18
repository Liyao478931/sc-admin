import request from './request'

// 资产分类列表（树形）
export function getAssetCategoryList() {
  return request({ url: '/personal-assets/asset-category/list', method: 'get' })
}
// 新增分类
export function createAssetCategory(data) {
  return request({ url: '/personal-assets/asset-category/create', method: 'post', data })
}
// 更新分类
export function updateAssetCategory(id, data) {
  return request({ url: `/personal-assets/asset-category/update/${id}`, method: 'put', data })
}
// 删除分类
export function deleteAssetCategory(id) {
  return request({ url: `/personal-assets/asset-category/delete/${id}`, method: 'delete' })
}
// 资产档案列表
export function getAssetArchiveList(params) {
  return request({ url: '/personal-assets/asset-archive/list', method: 'get', params })
}
// 生成资产编号
export function generateAssetNo() {
  return request({ url: '/personal-assets/asset-archive/generate-no', method: 'get' })
}
// 新增资产
export function createAssetArchive(data) {
  return request({ url: '/personal-assets/asset-archive/create', method: 'post', data })
}
// 更新资产
export function updateAssetArchive(id, data) {
  return request({ url: `/personal-assets/asset-archive/update/${id}`, method: 'put', data })
}
// 删除资产
export function deleteAssetArchive(id) {
  return request({ url: `/personal-assets/asset-archive/delete/${id}`, method: 'delete' })
}
// 资产详情
export function getAssetArchiveDetail(id) {
  return request({ url: `/personal-assets/asset-archive/detail/${id}`, method: 'get' })
}
// 导出资产档案
export function exportAssetArchive(params) {
  return request({ url: '/personal-assets/asset-archive/export', method: 'get', params, responseType: 'blob' })
}
// 下载导入模板
export function getAssetImportTemplate() {
  return request({ url: '/personal-assets/asset-archive/import-template', method: 'get', responseType: 'blob' })
}
// 导入资产档案
export function importAssetArchive(data) {
  return request({ url: '/personal-assets/asset-archive/import', method: 'post', data, headers: { 'Content-Type': 'multipart/form-data' } })
}
// 折旧统计
export function getDepreciationStats(params) {
  return request({ url: '/personal-assets/asset-depreciation/statistics', method: 'get', params })
}
// 折旧列表
export function getDepreciationList(params) {
  return request({ url: '/personal-assets/asset-depreciation/list', method: 'get', params })
}
// 计提本月折旧
export function executeDepreciation() {
  return request({ url: '/personal-assets/asset-depreciation/execute', method: 'post' })
}
// 折旧历史
export function getDepreciationHistory(params) {
  return request({ url: '/personal-assets/asset-depreciation/history', method: 'get', params })
}
// 导出折旧明细
export function exportDepreciation(params) {
  return request({ url: '/personal-assets/asset-depreciation/export', method: 'get', params, responseType: 'blob' })
}