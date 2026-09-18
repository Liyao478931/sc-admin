/**
 * 设备二维码 API 封装
 */
import request from './request'

export function generateQrcode(assetId) { return request({ url: '/device/qrcode/generate', method: 'post', data: { asset_id: assetId } }) }
export function batchGenerateQrcode(assetIds, force) { return request({ url: '/device/qrcode/batch-generate', method: 'post', data: { asset_ids: assetIds, force: force ? 1 : 0 } }) }
export function downloadQrcode(assetId) { return request({ url: '/device/qrcode/download', method: 'get', params: { asset_id: assetId }, responseType: 'blob' }) }
export function batchDownloadQrcode(assetIds) { return request({ url: '/device/qrcode/batch-download', method: 'post', data: { asset_ids: assetIds } }) }
export function getQrcodePrintData(assetIds) { return request({ url: '/device/qrcode/print-data', method: 'get', params: { asset_ids: assetIds } }) }
export function deleteQrcode(assetId) { return request({ url: '/device/qrcode/delete', method: 'delete', data: { asset_id: assetId } }) }
