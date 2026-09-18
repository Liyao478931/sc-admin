/**
 * 仓储管理 API
 */
import request from './request'

// ===== 仓库 =====
export function getWarehouseList(params) { return request({ url: '/warehouse/setting/warehouse/list', method: 'get', params }) }
export function saveWarehouse(data) { return request({ url: '/warehouse/setting/warehouse/save', method: 'post', data }) }
export function deleteWarehouse(id) { return request({ url: `/warehouse/setting/warehouse/delete/${id}`, method: 'delete' }) }
export function checkWarehouseCode(code, id) { return request({ url: '/warehouse/setting/warehouse/check-code', method: 'get', params: { code: code || '', id: id || 0 } }) }

// ===== 货位 =====
export function getLocationList(params) { return request({ url: '/warehouse/setting/location/list', method: 'get', params }) }
// 货位下拉选项（按仓库，兼容旧调用）
export function getLocationOptions(params) { return request({ url: '/warehouse/setting/location/list', method: 'get', params }) }
export function saveLocation(data) { return request({ url: '/warehouse/setting/location/save', method: 'post', data }) }
export function deleteLocation(id) { return request({ url: `/warehouse/setting/location/delete/${id}`, method: 'delete' }) }
export function checkLocationCode(warehouseId, code, id) { return request({ url: '/warehouse/setting/location/check-code', method: 'get', params: { warehouse_id: warehouseId || 0, code: code || '', id: id || 0 } }) }
export function getLocationTree() { return request({ url: '/warehouse/setting/location/tree', method: 'get' }) }

// ===== 物料 =====
export function getMaterialList(params) { return request({ url: '/warehouse/setting/material/list', method: 'get', params }) }
export function saveMaterial(data) { return request({ url: '/warehouse/setting/material/save', method: 'post', data }) }
export function deleteMaterial(id) { return request({ url: `/warehouse/setting/material/delete/${id}`, method: 'delete' }) }
export function checkMaterialCode(code, id) { return request({ url: '/warehouse/setting/material/check-code', method: 'get', params: { code: code || '', id: id || 0 } }) }
export function getMaterialCategoryTree() { return request({ url: '/warehouse/setting/material/category/tree', method: 'get' }) }
export function exportMaterial(params) { return request({ url: '/warehouse/setting/material/export', method: 'get', params, responseType: 'blob' }) }
export function getMaterialTemplate() { return request({ url: '/warehouse/setting/material/template', method: 'get', responseType: 'blob' }) }
export function importMaterial(formData) { return request({ url: '/warehouse/setting/material/import', method: 'post', data: formData }) }
export function syncProductsToMaterial() { return request({ url: '/warehouse/setting/material/sync-products', method: 'post' }) }
export function rebuildMaterialCodes() { return request({ url: '/warehouse/setting/material/rebuild-codes', method: 'post' }) }
export function getNextMaterialCode(categoryId, materialType) { return request({ url: '/warehouse/setting/material/next-code', method: 'get', params: { category_id: categoryId || 0, material_type: materialType || 0 } }) }
export function getMaterialCategoryList(params) { return request({ url: '/warehouse/setting/material/category/list', method: 'get', params }) }
export function saveMaterialCategory(data) { return request({ url: '/warehouse/setting/material/category/save', method: 'post', data }) }
export function deleteMaterialCategory(id) { return request({ url: `/warehouse/setting/material/category/delete/${id}`, method: 'delete' }) }
export function getCodeRule() { return request({ url: '/settings/code-rule/material', method: 'get' }) }
export function saveCodeRule(data) { return request({ url: '/settings/code-rule/material/save', method: 'post', data }) }
export function batchEnableMaterial(ids) { return request({ url: '/warehouse/setting/material/batch/enable', method: 'post', data: { ids } }) }
export function batchDisableMaterial(ids) { return request({ url: '/warehouse/setting/material/batch/disable', method: 'post', data: { ids } }) }
export function batchCategoryMaterial(ids, categoryId) { return request({ url: '/warehouse/setting/material/batch/category', method: 'post', data: { ids, category_id: categoryId } }) }
export function batchDeleteMaterial(ids) { return request({ url: '/warehouse/setting/material/batch/delete', method: 'delete', data: { ids } }) }
export function batchAddLocation(data) { return request({ url: '/warehouse/setting/location/batch-add', method: 'post', data }) }
export function getLocationQrcode(id) { return request({ url: `/warehouse/setting/location/qrcode/${id}`, method: 'get' }) }
export function getNextLocationCode(warehouseId) { return request({ url: '/warehouse/setting/location/next-code', method: 'get', params: { warehouse_id: warehouseId || 0 } }) }
export function getLocationCodeRule() { return request({ url: '/settings/code-rule/location', method: 'get' }) }
export function saveLocationCodeRule(data) { return request({ url: '/settings/code-rule/location/save', method: 'post', data }) }
export function getMaterialDetail(id) { return request({ url: `/warehouse/setting/material/detail/${id}`, method: 'get' }) }
export function getMaterialStockDistribution(id) { return request({ url: `/warehouse/setting/material/stock-distribution/${id}`, method: 'get' }) }
export function getMaterialStockFlow(id, params) { return request({ url: `/warehouse/setting/material/stock-flow/${id}`, method: 'get', params }) }

// ===== 物料二维码 =====
export function generateMaterialQrcode(materialId) { return request({ url: '/warehouse/setting/material/qrcode/generate', method: 'post', data: { material_id: materialId } }) }
export function batchGenerateMaterialQrcode(materialIds, force) { return request({ url: '/warehouse/setting/material/qrcode/batch-generate', method: 'post', data: { material_ids: materialIds, force: force ? 1 : 0 } }) }
export function downloadMaterialQrcode(materialId) { return request({ url: '/warehouse/setting/material/qrcode/download', method: 'get', params: { material_id: materialId }, responseType: 'blob' }) }
export function deleteMaterialQrcode(materialId) { return request({ url: '/warehouse/setting/material/qrcode/delete', method: 'delete', data: { material_id: materialId } }) }
export function getMaterialQrcodePrintData(materialIds) { return request({ url: '/warehouse/setting/material/qrcode/print-data', method: 'get', params: { material_ids: materialIds } }) }

// ===== 采购入库 =====
export function getPurchaseInList(params) { return request({ url: '/warehouse/purchase/in/list', method: 'get', params }) }
export function getPurchaseInDetail(id) { return request({ url: `/warehouse/purchase/in/detail/${id}`, method: 'get' }) }
export function savePurchaseIn(data) { return request({ url: '/warehouse/purchase/in/save', method: 'post', data }) }
export function confirmPurchaseIn(id) { return request({ url: `/warehouse/purchase/in/confirm/${id}`, method: 'post' }) }
export function deletePurchaseIn(id) { return request({ url: `/warehouse/purchase/in/delete/${id}`, method: 'delete' }) }
export function exportPurchaseIn(params) { return request({ url: '/warehouse/purchase/in/export', method: 'get', params, responseType: 'blob' }) }
export function getReadyArrivalList() { return request({ url: '/business/purchase/arrival/ready-in', method: 'get' }) }
export function reversePurchaseIn(id, reason) { return request({ url: `/warehouse/purchase/in/reverse/${id}`, method: 'post', data: { reverse_reason: reason } }) }
export function uploadInAttachment(id, formData) { return request({ url: `/warehouse/purchase/in/upload/${id}`, method: 'post', data: formData }) }
export function getInAttachments(id) { return request({ url: `/warehouse/purchase/in/attachments/${id}`, method: 'get' }) }
export function deleteInAttachment(id) { return request({ url: `/warehouse/purchase/in/attachment/${id}`, method: 'delete' }) }
export function downloadInAttachment(id) { return request({ url: `/warehouse/purchase/in/attachment/download/${id}`, method: 'get', responseType: 'blob' }) }
export function getPurchaseInStatistics(params) { return request({ url: '/warehouse/purchase/in/statistics', method: 'get', params }) }
export function getPurchaseInNextCode() { return request({ url: '/warehouse/purchase/in/next-code', method: 'get' }) }
export function getPurchaseInCodeRule() { return request({ url: '/settings/code-rule/purchase-in', method: 'get' }) }
export function savePurchaseInCodeRule(data) { return request({ url: '/settings/code-rule/purchase-in/save', method: 'post', data }) }

// ===== 配件退库 =====
export function getReturnList(params) { return request({ url: '/warehouse/return/list', method: 'get', params }) }
export function getReturnDetail(id) { return request({ url: `/warehouse/return/detail/${id}`, method: 'get' }) }
export function getReturnablePickList() { return request({ url: '/warehouse/return/returnable-pick-list', method: 'get' }) }
export function saveReturn(data) { return request({ url: '/warehouse/return/save', method: 'post', data }) }
export function deleteReturn(id) { return request({ url: `/warehouse/return/delete/${id}`, method: 'delete' }) }
export function submitReturn(id) { return request({ url: `/warehouse/return/submit/${id}`, method: 'post' }) }
export function cancelReturn(id) { return request({ url: `/warehouse/return/cancel/${id}`, method: 'post' }) }
export function approveReturn(id, remark) { return request({ url: `/warehouse/return/approve/${id}`, method: 'post', data: { remark: remark || '' } }) }
export function rejectReturn(id, reason) { return request({ url: `/warehouse/return/reject/${id}`, method: 'post', data: { reason } }) }
export function confirmReturn(id) { return request({ url: `/warehouse/return/confirm/${id}`, method: 'post' }) }
export function getReturnLogs(id) { return request({ url: `/warehouse/return/logs/${id}`, method: 'get' }) }
export function exportReturn(params) { return request({ url: '/warehouse/return/export', method: 'get', params, responseType: 'blob' }) }

// ===== 报废出库 =====
export function getScrapList(params) { return request({ url: '/warehouse/scrap/list', method: 'get', params }) }
export function getScrapDetail(id) { return request({ url: `/warehouse/scrap/detail/${id}`, method: 'get' }) }
export function saveScrap(data) { return request({ url: '/warehouse/scrap/save', method: 'post', data }) }
export function deleteScrap(id) { return request({ url: `/warehouse/scrap/delete/${id}`, method: 'delete' }) }
export function submitScrap(id) { return request({ url: `/warehouse/scrap/submit/${id}`, method: 'post' }) }
export function cancelScrap(id) { return request({ url: `/warehouse/scrap/cancel/${id}`, method: 'post' }) }
export function approveScrap(id, remark) { return request({ url: `/warehouse/scrap/approve/${id}`, method: 'post', data: { remark: remark || '' } }) }
export function rejectScrap(id, reason) { return request({ url: `/warehouse/scrap/reject/${id}`, method: 'post', data: { reason } }) }
export function confirmScrap(id) { return request({ url: `/warehouse/scrap/confirm/${id}`, method: 'post' }) }
export function getScrapLogs(id) { return request({ url: `/warehouse/scrap/logs/${id}`, method: 'get' }) }
export function exportScrap(params) { return request({ url: '/warehouse/scrap/export', method: 'get', params, responseType: 'blob' }) }

// ===== 产品接收（设备入库） =====
export function getDeviceReceiptList(params) { return request({ url: '/warehouse/device/receive/list', method: 'get', params }) }
export function getDeviceReceiptDetail(id) { return request({ url: `/warehouse/device/receive/detail/${id}`, method: 'get' }) }
export function saveDeviceReceipt(data) { return request({ url: '/warehouse/device/receive/save', method: 'post', data }) }
export function deleteDeviceReceipt(id) { return request({ url: `/warehouse/device/receive/delete/${id}`, method: 'delete' }) }
export function submitDeviceReceipt(id) { return request({ url: `/warehouse/device/receive/submit/${id}`, method: 'post' }) }
export function cancelDeviceReceipt(id) { return request({ url: `/warehouse/device/receive/cancel/${id}`, method: 'post' }) }
export function approveDeviceReceipt(id, remark) { return request({ url: `/warehouse/device/receive/approve/${id}`, method: 'post', data: { remark: remark || '' } }) }
export function rejectDeviceReceipt(id, reason) { return request({ url: `/warehouse/device/receive/reject/${id}`, method: 'post', data: { reason } }) }
export function confirmDeviceReceipt(id) { return request({ url: `/warehouse/device/receive/confirm/${id}`, method: 'post' }) }
export function getDeviceReceiptLogs(id) { return request({ url: `/warehouse/device/receive/logs/${id}`, method: 'get' }) }
export function exportDeviceReceipt(params) { return request({ url: '/warehouse/device/receive/export', method: 'get', params, responseType: 'blob' }) }
export function getReadyReceiveList() { return request({ url: '/business/receive/ready-in', method: 'get' }) }
export function getReadyDeviceReceiptList() { return request({ url: '/warehouse/device/receive/ready-in', method: 'get' }) }

// ===== 产品入库（上架确认） =====
export function getProductInList(params) { return request({ url: '/warehouse/product/in/list', method: 'get', params }) }
export function getProductInDetail(id) { return request({ url: `/warehouse/product/in/detail/${id}`, method: 'get' }) }
export function saveProductIn(data) { return request({ url: '/warehouse/product/in/save', method: 'post', data }) }
export function deleteProductIn(id) { return request({ url: `/warehouse/product/in/delete/${id}`, method: 'delete' }) }
export function submitProductIn(id) { return request({ url: `/warehouse/product/in/submit/${id}`, method: 'post' }) }
export function cancelProductIn(id) { return request({ url: `/warehouse/product/in/cancel/${id}`, method: 'post' }) }
export function approveProductIn(id, remark) { return request({ url: `/warehouse/product/in/approve/${id}`, method: 'post', data: { remark: remark || '' } }) }
export function rejectProductIn(id, reason) { return request({ url: `/warehouse/product/in/reject/${id}`, method: 'post', data: { reason } }) }
export function confirmProductIn(id) { return request({ url: `/warehouse/product/in/confirm/${id}`, method: 'post' }) }
export function getProductInLogs(id) { return request({ url: `/warehouse/product/in/logs/${id}`, method: 'get' }) }
export function exportProductIn(params) { return request({ url: '/warehouse/product/in/export', method: 'get', params, responseType: 'blob' }) }

// ===== 配件领用 =====
export function getPickList(params) { return request({ url: '/warehouse/pick/list', method: 'get', params }) }
export function getPickDetail(id) { return request({ url: `/warehouse/pick/detail/${id}`, method: 'get' }) }
export function savePick(data) { return request({ url: '/warehouse/pick/save', method: 'post', data }) }
export function deletePick(id) { return request({ url: `/warehouse/pick/delete/${id}`, method: 'delete' }) }
export function submitPick(id) { return request({ url: `/warehouse/pick/submit/${id}`, method: 'post' }) }
export function approvePick(id, remark) { return request({ url: `/warehouse/pick/approve/${id}`, method: 'post', data: { audit_remark: remark || '' } }) }
export function rejectPick(id, reason) { return request({ url: `/warehouse/pick/reject/${id}`, method: 'post', data: { reject_reason: reason } }) }
export function confirmPick(id) { return request({ url: `/warehouse/pick/confirm/${id}`, method: 'post' }) }
export function cancelPick(id) { return request({ url: `/warehouse/pick/cancel/${id}`, method: 'post' }) }
export function getPickLogs(id) { return request({ url: `/warehouse/pick/logs/${id}`, method: 'get' }) }
export function getPickVersions(id) { return request({ url: `/warehouse/pick/versions/${id}`, method: 'get' }) }
export function getPickVersionDetail(id, version) { return request({ url: `/warehouse/pick/versions/${id}/${version}`, method: 'get' }) }
export function comparePickVersions(id, v1, v2) { return request({ url: `/warehouse/pick/versions/compare/${id}`, method: 'get', params: { version1: v1, version2: v2 } }) }
export function restorePickVersion(id, version) { return request({ url: `/warehouse/pick/versions/restore/${id}`, method: 'post', data: { version } }) }
export function exportPick(params) { return request({ url: '/warehouse/pick/export', method: 'get', params, responseType: 'blob' }) }
export function getPickWorkOrders(type, keyword) { return request({ url: '/warehouse/pick/work-orders', method: 'get', params: { pick_type: type || 1, keyword: keyword || '' } }) }

// ===== 产品出库（设备出入库 -> 产品出库） =====
export function getProductOutList(params) { return request({ url: '/warehouse/product/out/list', method: 'get', params }) }
export function getProductOutDetail(id) { return request({ url: `/warehouse/product/out/detail/${id}`, method: 'get' }) }
export function saveProductOut(data) { return request({ url: '/warehouse/product/out/save', method: 'post', data }) }
export function deleteProductOut(id) { return request({ url: `/warehouse/product/out/delete/${id}`, method: 'delete' }) }
export function submitProductOut(id) { return request({ url: `/warehouse/product/out/submit/${id}`, method: 'post' }) }
export function cancelProductOut(id) { return request({ url: `/warehouse/product/out/cancel/${id}`, method: 'post' }) }
export function approveProductOut(id, remark) { return request({ url: `/warehouse/product/out/approve/${id}`, method: 'post', data: { remark: remark || '' } }) }
export function rejectProductOut(id, reason) { return request({ url: `/warehouse/product/out/reject/${id}`, method: 'post', data: { reason } }) }
export function confirmProductOut(id) { return request({ url: `/warehouse/product/out/confirm/${id}`, method: 'post' }) }
export function getProductOutLogs(id) { return request({ url: `/warehouse/product/out/logs/${id}`, method: 'get' }) }
export function exportProductOut(params) { return request({ url: '/warehouse/product/out/export', method: 'get', params, responseType: 'blob' }) }
export function getRepairReadyOut(keyword) { return request({ url: '/device/repair/order/ready-out', method: 'get', params: { keyword: keyword || '' } }) }
export function getSalesReadyOut(keyword) { return request({ url: '/business/order/ready-out', method: 'get', params: { keyword: keyword || '' } }) }
export function getCustomerOptions() { return request({ url: '/business/customer/options', method: 'get' }) }
export function getProductSearch(keyword) { return request({ url: '/business/product/search', method: 'get', params: { keyword: keyword || '', limit: 50 } }) }

// ===== 库存查询（仓储管理 -> 库存管理 -> 库存查询） =====
export function getInventoryList(params) { return request({ url: '/warehouse/inventory/query', method: 'get', params }) }
export function getStockDistribution(id) { return request({ url: `/warehouse/inventory/stock-distribution/${id}`, method: 'get' }) }
export function exportInventory(params) { return request({ url: '/warehouse/inventory/export', method: 'get', params, responseType: 'blob' }) }
export function getFlowList(params) { return request({ url: '/warehouse/inventory/flow/list', method: 'get', params }) }
export function exportFlow(params) { return request({ url: '/warehouse/inventory/flow/export', method: 'get', params, responseType: 'blob' }) }
export function getAlertList(params) { return request({ url: '/warehouse/inventory/alert/list', method: 'get', params }) }
export function adjustSafetyStock(data) { return request({ url: '/warehouse/inventory/alert/adjust-stock', method: 'post', data }) }
export function ignoreAlert(id, reason) { return request({ url: `/warehouse/inventory/alert/ignore/${id}`, method: 'post', data: { reason: reason || '' } }) }
export function getAlertConfig() { return request({ url: '/warehouse/inventory/alert/config', method: 'get' }) }
export function saveAlertConfig(data) { return request({ url: '/warehouse/inventory/alert/config/save', method: 'post', data }) }
export function exportAlert(params) { return request({ url: '/warehouse/inventory/alert/export', method: 'get', params, responseType: 'blob' }) }

// ===== 库存盘点 - 盘点计划（审核走统一审批） =====
export function getPlanList(params) { return request({ url: '/warehouse/check/plan/list', method: 'get', params }) }
export function getPlanDetail(id) { return request({ url: `/warehouse/check/plan/detail/${id}`, method: 'get' }) }
export function savePlan(data) { return request({ url: '/warehouse/check/plan/save', method: 'post', data }) }
export function deletePlan(id) { return request({ url: `/warehouse/check/plan/delete/${id}`, method: 'delete' }) }
export function submitPlan(id) { return request({ url: `/warehouse/check/plan/submit/${id}`, method: 'post' }) }
export function cancelPlan(id) { return request({ url: `/warehouse/check/plan/cancel/${id}`, method: 'post' }) }
export function startPlan(id) { return request({ url: `/warehouse/check/plan/start/${id}`, method: 'post' }) }
export function completePlan(id) { return request({ url: `/warehouse/check/plan/complete/${id}`, method: 'post' }) }
export function getPlanTasks(id) { return request({ url: `/warehouse/check/plan/tasks/${id}`, method: 'get' }) }
export function getPlanResults(id) { return request({ url: `/warehouse/check/plan/results/${id}`, method: 'get' }) }
export function exportPlan(params) { return request({ url: '/warehouse/check/plan/export', method: 'get', params, responseType: 'blob' }) }

// ===== 库存盘点 - 盘点执行 =====
export function getExecuteTasks(params) { return request({ url: '/warehouse/check/execute/tasks', method: 'get', params }) }
export function getExecuteTaskDetail(id) { return request({ url: `/warehouse/check/execute/task-detail/${id}`, method: 'get' }) }
export function saveExecuteDraft(data) { return request({ url: '/warehouse/check/execute/save-draft', method: 'post', data }) }
export function submitExecuteTask(id, data) { return request({ url: `/warehouse/check/execute/submit/${id}`, method: 'post', data }) }
export function exportExecuteTasks(params) { return request({ url: '/warehouse/check/execute/export', method: 'get', params, responseType: 'blob' }) }

// ===== 库存盘点 - 盘点差异 =====
export function getDiffList(params) { return request({ url: '/warehouse/check/diff/list', method: 'get', params }) }
export function getDiffDetail(id) { return request({ url: `/warehouse/check/diff/detail/${id}`, method: 'get' }) }
export function processDiff(id, data) { return request({ url: `/warehouse/check/diff/process/${id}`, method: 'post', data }) }
export function ignoreDiff(id, data) { return request({ url: `/warehouse/check/diff/ignore/${id}`, method: 'post', data }) }
export function exportDiff(params) { return request({ url: '/warehouse/check/diff/export', method: 'get', params, responseType: 'blob' }) }
