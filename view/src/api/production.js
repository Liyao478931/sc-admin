/**
 * 生产管理 API（工单）
 */
import request from './request'

export function getOrderList(params) { return request({ url: '/production/order/list', method: 'get', params }) }
export function getOrderDetail(id) { return request({ url: `/production/order/detail/${id}`, method: 'get' }) }
export function createOrder(data) { return request({ url: '/production/order/create', method: 'post', data }) }
export function editOrder(id, data) { return request({ url: `/production/order/edit/${id}`, method: 'post', data }) }
export function deleteOrder(id) { return request({ url: `/production/order/delete/${id}`, method: 'delete' }) }
export function dispatchOrder(id, data) { return request({ url: `/production/order/dispatch/${id}`, method: 'post', data }) }
export function startOrder(id) { return request({ url: `/production/order/start/${id}`, method: 'post' }) }
export function reportOrder(id, data) { return request({ url: `/production/order/report/${id}`, method: 'post', data }) }
export function applyQuality(id) { return request({ url: `/production/order/apply-quality/${id}`, method: 'post' }) }
export function qualityPass(id, data) { return request({ url: `/production/order/quality-pass/${id}`, method: 'post', data }) }
export function qualityReject(id, data) { return request({ url: `/production/order/quality-reject/${id}`, method: 'post', data }) }
export function closeOrder(id) { return request({ url: `/production/order/close/${id}`, method: 'post' }) }
export function exportOrder(params) { return request({ url: '/production/order/export', method: 'get', params, responseType: 'blob' }) }
export function getOrderProducts() { return request({ url: '/production/order/products', method: 'get' }) }
export function getOrderMaterials() { return request({ url: '/production/order/materials', method: 'get' }) }
export function getOrderUsers() { return request({ url: '/production/order/users', method: 'get' }) }
// ---- 订单↔工单关联 ----
export function getSourceData(params) { return request({ url: '/production/order/get-source-data', method: 'get', params }) }
export function createFromOrder(data) { return request({ url: '/production/order/create-from-order', method: 'post', data }) }
export function getBySource(params) { return request({ url: '/production/order/get-by-source', method: 'get', params }) }
export function getAvailableSalesOrders() { return request({ url: '/business/order/available-list', method: 'get' }) }
export function getAvailableRepairOrders() { return request({ url: '/business/repair/order/available-list', method: 'get' }) }
// ---- 工单整合 工序/工位/BOM ----
export function getOrderBom(productId) { return request({ url: `/product/bom/by-product/${productId}`, method: 'get' }) }
export function checkWorkstation(id) { return request({ url: `/production/workstation/check/${id}`, method: 'get' }) }
// ---- 生产报工 ----
export function getReportList(params) { return request({ url: '/production/report/list', method: 'get', params }) }
export function getAuditList(params) { return request({ url: '/production/report/audit/list', method: 'get', params }) }
export function getReportDetail(id) { return request({ url: `/production/report/detail/${id}`, method: 'get' }) }
export function getReportableOrders() { return request({ url: '/production/order/available-for-report', method: 'get' }) }
export function saveReport(data) { return request({ url: '/production/report/save', method: 'post', data }) }
export function deleteReport(id) { return request({ url: `/production/report/delete/${id}`, method: 'delete' }) }
export function submitReport(id) { return request({ url: `/production/report/submit/${id}`, method: 'post' }) }
export function approveReport(id, data) { return request({ url: `/production/report/approve/${id}`, method: 'post', data }) }
export function rejectReport(id, data) { return request({ url: `/production/report/reject/${id}`, method: 'post', data }) }
export function cancelReport(id) { return request({ url: `/production/report/cancel/${id}`, method: 'post' }) }
export function exportReport(params) { return request({ url: '/production/report/export', method: 'get', params, responseType: 'blob' }) }
// ---- 工序管理 ----
export function getProcessList(params) { return request({ url: '/production/process/list', method: 'get', params }) }
export function getProcessGroups() { return request({ url: '/production/process/groups', method: 'get' }) }
export function saveProcess(data) { return request({ url: '/production/process/save', method: 'post', data }) }
export function deleteProcess(id) { return request({ url: `/production/process/delete/${id}`, method: 'delete' }) }
export function toggleProcess(id) { return request({ url: `/production/process/toggle/${id}`, method: 'post' }) }
// ---- 工位管理 ----
export function getWorkstationList(params) { return request({ url: '/production/workstation/list', method: 'get', params }) }
export function saveWorkstation(data) { return request({ url: '/production/workstation/save', method: 'post', data }) }
export function deleteWorkstation(id) { return request({ url: `/production/workstation/delete/${id}`, method: 'delete' }) }
export function toggleWorkstation(id) { return request({ url: `/production/workstation/toggle/${id}`, method: 'post' }) }
export function getWsDeviceOptions() { return request({ url: '/production/workstation/devices/options', method: 'get' }) }
export function getWsDevices(id) { return request({ url: `/production/workstation/devices/${id}`, method: 'get' }) }
export function attachWsDevices(data) { return request({ url: '/production/workstation/devices/attach', method: 'post', data }) }
export function detachWsDevice(id) { return request({ url: `/production/workstation/devices/detach/${id}`, method: 'delete' }) }
export function setWsPrimary(data) { return request({ url: '/production/workstation/devices/set-primary', method: 'post', data }) }
export function getWsStaffOptions() { return request({ url: '/production/workstation/staff/options', method: 'get' }) }
export function getWsStaff(id) { return request({ url: `/production/workstation/staff/${id}`, method: 'get' }) }
export function attachWsStaff(data) { return request({ url: '/production/workstation/staff/attach', method: 'post', data }) }
export function detachWsStaff(id) { return request({ url: `/production/workstation/staff/detach/${id}`, method: 'delete' }) }
export function setWsRole(data) { return request({ url: '/production/workstation/staff/set-role', method: 'post', data }) }
// ---- 工位联动工序（工位-工序关联） ----
export function getWsProcesses(id) { return request({ url: `/production/workstation/processes/${id}`, method: 'get' }) }
export function getProcessWorkstations(id) { return request({ url: `/production/process/workstations/${id}`, method: 'get' }) }
export function getWsAvailableProcesses(id) { return request({ url: `/production/workstation/available-processes/${id}`, method: 'get' }) }
export function attachProcessToWs(data) { return request({ url: '/production/process-workstation/attach', method: 'post', data }) }
export function attachWsToProcess(data) { return request({ url: '/production/process-workstation/attach-workstations', method: 'post', data }) }
export function detachProcessWs(id) { return request({ url: `/production/process-workstation/detach/${id}`, method: 'delete' }) }
export function setProcessWsDefault(data) { return request({ url: '/production/process-workstation/set-default', method: 'post', data }) }
// ---- 报工完整信息采集 ----
export function uploadReportPhoto(formData) { return request({ url: '/production/report/upload', method: 'post', data: formData, headers: { 'Content-Type': 'multipart/form-data' } }) }
// ---- 生产进度 ----
export function getProgressList(params) { return request({ url: '/production/execute/progress/list', method: 'get', params }) }
export function getProgressDetail(id, params) { return request({ url: `/production/execute/progress/detail/${id}`, method: 'get', params }) }
export function exportProgress(params) { return request({ url: '/production/execute/progress/export', method: 'get', params, responseType: 'blob' }) }
// ---- 工单派工 ----
export function getDispatchList(params) { return request({ url: '/production/dispatch/list', method: 'get', params }) }
export function getDispatchDetail(id) { return request({ url: `/production/dispatch/detail/${id}`, method: 'get' }) }
export function getDispatchableOrders() { return request({ url: '/production/order/available-for-dispatch', method: 'get' }) }
export function getOrderTasks(id) { return request({ url: `/production/order/tasks/${id}`, method: 'get' }) }
export function getDispatchWsOptions() { return request({ url: '/production/dispatch/workstations', method: 'get' }) }
export function getDispatchDevices(wsId) { return request({ url: `/production/dispatch/devices/${wsId}`, method: 'get' }) }
export function getDispatchStaff(wsId) { return request({ url: `/production/dispatch/staff/${wsId}`, method: 'get' }) }
export function getDispatchTeams() { return request({ url: '/production/dispatch/teams', method: 'get' }) }
export function saveDispatch(data) { return request({ url: '/production/dispatch/save', method: 'post', data }) }
export function confirmDispatch(id) { return request({ url: `/production/dispatch/confirm/${id}`, method: 'post' }) }
export function startDispatch(id) { return request({ url: `/production/dispatch/start/${id}`, method: 'post' }) }
export function completeDispatch(id) { return request({ url: `/production/dispatch/complete/${id}`, method: 'post' }) }
export function cancelDispatch(id) { return request({ url: `/production/dispatch/cancel/${id}`, method: 'post' }) }
export function deleteDispatch(id) { return request({ url: `/production/dispatch/delete/${id}`, method: 'delete' }) }
export function exportDispatch(params) { return request({ url: '/production/dispatch/export', method: 'get', params, responseType: 'blob' }) }
// ---- 生产排程 ----
export function getScheduleData(params) { return request({ url: '/production/schedule/data', method: 'get', params }) }
export function saveSchedule(data) { return request({ url: '/production/schedule/save', method: 'post', data }) }
export function autoSchedule(data) { return request({ url: '/production/schedule/auto', method: 'post', data }) }
export function confirmSchedule(data) { return request({ url: '/production/schedule/confirm', method: 'post', data }) }
export function checkScheduleConflict(data) { return request({ url: '/production/schedule/check-conflict', method: 'post', data }) }
export function exportSchedule(params) { return request({ url: '/production/schedule/export', method: 'get', params, responseType: 'blob' }) }
// ---- 质量管理 ----
export function getQualityStandardList(params) { return request({ url: '/production/quality/standard/list', method: 'get', params }) }
export function saveQualityStandard(data) { return request({ url: '/production/quality/standard/save', method: 'post', data }) }
export function deleteQualityStandard(id) { return request({ url: `/production/quality/standard/delete/${id}`, method: 'delete' }) }
export function toggleQualityStandard(id) { return request({ url: `/production/quality/standard/toggle/${id}`, method: 'post' }) }
export function getQualityOrders() { return request({ url: '/production/order/available-for-quality', method: 'get' }) }
export function getQualityTaskList(params) { return request({ url: '/production/quality/task/list', method: 'get', params }) }
export function getQualityTaskDetail(id) { return request({ url: `/production/quality/task/detail/${id}`, method: 'get' }) }
export function saveQualityTask(data) { return request({ url: '/production/quality/task/save', method: 'post', data }) }
export function executeQualityTask(id) { return request({ url: `/production/quality/task/execute/${id}`, method: 'post' }) }
export function deleteQualityTask(id) { return request({ url: `/production/quality/task/delete/${id}`, method: 'delete' }) }
export function getQualityRejectList(params) { return request({ url: '/production/quality/reject/list', method: 'get', params }) }
export function handleQualityReject(id, data) { return request({ url: `/production/quality/reject/handle/${id}`, method: 'post', data }) }
export function closeQualityReject(id) { return request({ url: `/production/quality/reject/close/${id}`, method: 'post' }) }
export function getQualityStatistics(params) { return request({ url: '/production/quality/statistics', method: 'get', params }) }
export function exportQualityStatistics(params) { return request({ url: '/production/quality/statistics/export', method: 'get', params, responseType: 'blob' }) }
// ---- 生产看板 ----
export function getDashboardData() { return request({ url: '/production/dashboard/data', method: 'get' }) }

// ===== 工艺路线 =====
export function getRoutingList(params) { return request({ url: '/production/routing/list', method: 'get', params }) }
export function getRoutingDetail(id) { return request({ url: `/production/routing/detail/${id}`, method: 'get' }) }
export function saveRouting(data) { return request({ url: '/production/routing/save', method: 'post', data }) }
export function deleteRouting(id) { return request({ url: `/production/routing/delete/${id}`, method: 'delete' }) }
export function copyRouting(id) { return request({ url: `/production/routing/copy/${id}`, method: 'post' }) }
export function setDefaultRouting(id) { return request({ url: `/production/routing/default/${id}`, method: 'post' }) }
export function submitRoutingApproval(id) { return request({ url: `/production/routing/approve/${id}`, method: 'post' }) }
export function toggleRoutingStatus(id, status) { return request({ url: `/production/routing/toggle/${id}?status=${status}`, method: 'post' }) }
export function exportRouting(params) { return request({ url: '/production/routing/export', method: 'get', params, responseType: 'blob' }) }
export function getRoutingItems(id) { return request({ url: `/production/routing/items/${id}`, method: 'get' }) }

// ===== MRP 物料需求计划 =====
export function getMrpList(params) { return request({ url: '/production/mrp/list', method: 'get', params }) }
export function getMrpDetail(id, params) { return request({ url: `/production/mrp/detail/${id}`, method: 'get', params }) }
export function runMrp(data) { return request({ url: '/production/mrp/run', method: 'post', data }) }
export function deleteMrp(id) { return request({ url: `/production/mrp/delete/${id}`, method: 'delete' }) }
export function exportMrp(id) { return request({ url: `/production/mrp/export/${id}`, method: 'get', responseType: 'blob' }) }
export function updateMrpStatus(id, status) { return request({ url: `/production/mrp/status/${id}`, method: 'post', data: { status } }) }
