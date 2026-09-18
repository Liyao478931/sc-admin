/**
 * 设备台账 API 封装
 */
import request from './request'

export function getAssetList(params) { return request({ url: '/device/asset/list', method: 'get', params }) }
export function getAssetDetail(id) { return request({ url: `/device/asset/detail/${id}`, method: 'get' }) }
export function addAsset(data) { return request({ url: '/device/asset/add', method: 'post', data }) }
export function editAsset(id, data) { return request({ url: `/device/asset/edit/${id}`, method: 'put', data }) }
export function deleteAsset(id) { return request({ url: `/device/asset/delete/${id}`, method: 'delete' }) }
export function batchDeleteAssets(ids) { return request({ url: '/device/asset/batch-delete', method: 'delete', data: { ids } }) }
export function changeAssetStatus(id, data) { return request({ url: `/device/asset/status/${id}`, method: 'put', data }) }
export function suggestAssetCode() { return request({ url: '/device/asset/suggest-code', method: 'get' }) }
export function importAssets(formData) { return request({ url: '/device/asset/import', method: 'post', data: formData }) }
export function exportAssets(params) { return request({ url: '/device/asset/export', method: 'get', params }) }
export function getAssetStatistics() { return request({ url: '/device/asset/statistics', method: 'get' }) }
export function getAssetStatusLog(id) { return request({ url: `/device/asset/status-log/${id}`, method: 'get' }) }
export function getSuppliers() { return request({ url: '/device/asset/suppliers', method: 'get' }) }
export function getManagers() { return request({ url: '/device/asset/managers', method: 'get' }) }
