/**
 * 经营管理 - 产品管理 API
 * 说明：接口前缀 /api/business/product/* 由后端 ThinkPHP 提供，统一返回 {code, msg, data}
 */
import request from './request'

// ===== 产品 =====
export function getProductList(params) { return request({ url: '/business/product/list', method: 'get', params }) }
export function getProductDetail(id) { return request({ url: `/business/product/detail/${id}`, method: 'get' }) }
export function getProductParams(id) { return request({ url: `/business/product/param/${id}`, method: 'get' }) }
export function addProduct(data) { return request({ url: '/business/product/add', method: 'post', data }) }
export function editProduct(id, data) { return request({ url: `/business/product/edit/${id}`, method: 'put', data }) }
export function deleteProduct(id) { return request({ url: `/business/product/delete/${id}`, method: 'delete' }) }
export function exportProduct(params) { return request({ url: '/business/product/export', method: 'get', params, responseType: 'blob' }) }

// ===== 产品二维码 =====
export function generateProductQrcode(productId) { return request({ url: '/business/product/qrcode/generate', method: 'post', data: { product_id: productId } }) }
export function batchGenerateProductQrcode(productIds, force) { return request({ url: '/business/product/qrcode/batch-generate', method: 'post', data: { product_ids: productIds, force: force ? 1 : 0 } }) }
export function downloadProductQrcode(productId) { return request({ url: '/business/product/qrcode/download', method: 'get', params: { product_id: productId }, responseType: 'blob' }) }
export function deleteProductQrcode(productId) { return request({ url: '/business/product/qrcode/delete', method: 'delete', data: { product_id: productId } }) }
export function getProductQrcodePrintData(productIds) { return request({ url: '/business/product/qrcode/print-data', method: 'get', params: { product_ids: productIds } }) }

// ===== 产品分类 =====
export function getProductCategoryTree() { return request({ url: '/business/product/category/tree', method: 'get' }) }
export function getProductCategoryList(params) { return request({ url: '/business/product/category/list', method: 'get', params }) }
export function getProductCategoryOptions() { return request({ url: '/business/product/category/options', method: 'get' }) }
export function addProductCategory(data) { return request({ url: '/business/product/category/add', method: 'post', data }) }
export function editProductCategory(id, data) { return request({ url: `/business/product/category/edit/${id}`, method: 'put', data }) }
export function deleteProductCategory(id) { return request({ url: `/business/product/category/delete/${id}`, method: 'delete' }) }
export function updateProductCategoryStatus(id, status) { return request({ url: `/business/product/category/status/${id}`, method: 'put', data: { status } }) }

// ===== 产品BOM =====
export function getBomList(params) { return request({ url: '/business/product/bom/list', method: 'get', params }) }
export function getBomDetail(id) { return request({ url: `/business/product/bom/detail/${id}`, method: 'get' }) }
export function saveBom(data) { return request({ url: '/business/product/bom/save', method: 'post', data }) }
export function deleteBom(id) { return request({ url: `/business/product/bom/delete/${id}`, method: 'delete' }) }
export function copyBom(id) { return request({ url: `/business/product/bom/copy/${id}`, method: 'post' }) }
export function setDefaultBom(id) { return request({ url: `/business/product/bom/default/${id}`, method: 'post' }) }
export function submitBomApproval(id) { return request({ url: `/business/product/bom/approve/${id}`, method: 'post' }) }
export function toggleBomStatus(id, status) { return request({ url: `/business/product/bom/status/${id}`, method: 'put', data: { status } }) }
export function exportBom(params) { return request({ url: '/business/product/bom/export', method: 'get', params, responseType: 'blob' }) }
export function checkBomCode(bomCode, id) { return request({ url: '/business/product/bom/check-code', method: 'get', params: { bom_code: bomCode, id: id || 0 } }) }
export function getApprovedBomList() { return request({ url: '/business/product/bom/approved-list', method: 'get' }) }
export function getBomItems(id) { return request({ url: `/business/product/bom/items/${id}`, method: 'get' }) }
export function importBomItems(formData) { return request({ url: '/business/product/bom/import-items', method: 'post', data: formData }) }
export function getBomChildren(bomId, parentItemId) { return request({ url: '/business/product/bom/children', method: 'get', params: { bom_id: bomId, parent_item_id: parentItemId } }) }
export function checkBomCircular(data) { return request({ url: '/business/product/bom/check-circular', method: 'post', data }) }
export function searchProducts(keyword) { return request({ url: '/business/product/search', method: 'get', params: { keyword } }) }

// ===== 产品图纸 =====
export function getDrawingList(params) { return request({ url: '/business/product/drawing/list', method: 'get', params }) }
export function getDrawingDetail(id) { return request({ url: `/business/product/drawing/detail/${id}`, method: 'get' }) }
export function saveDrawing(formData) { return request({ url: '/business/product/drawing/save', method: 'post', data: formData }) }
export function deleteDrawing(id) { return request({ url: `/business/product/drawing/delete/${id}`, method: 'delete' }) }
export function downloadDrawing(id) { return request({ url: `/business/product/drawing/download/${id}`, method: 'get', responseType: 'blob' }) }
export function downloadDrawingVersion(id) { return request({ url: `/business/product/drawing/version/download/${id}`, method: 'get', responseType: 'blob' }) }
export function uploadDrawingVersion(data) { return request({ url: '/business/product/drawing/upload-version', method: 'post', data }) }
export function checkDrawingCode(code, id) { return request({ url: '/business/product/drawing/check-code', method: 'get', params: { drawing_code: code, id: id || 0 } }) }
export function getDrawingCategoryTree() { return request({ url: '/business/product/drawing/category/tree', method: 'get' }) }
export function getDrawingCategoryList(params) { return request({ url: '/business/product/drawing/category/list', method: 'get', params }) }
export function saveDrawingCategory(data) { return request({ url: '/business/product/drawing/category/save', method: 'post', data }) }
export function deleteDrawingCategory(id) { return request({ url: `/business/product/drawing/category/delete/${id}`, method: 'delete' }) }
export function exportDrawings(params) { return request({ url: '/business/product/drawing/export', method: 'get', params, responseType: 'blob' }) }
