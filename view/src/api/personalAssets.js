import request from './request'

// 我的资产列表（含统计）
export function getMyAssetList(params) {
  return request({ url: '/personal-assets/my-list', method: 'get', params })
}
// 资产详情
export function getMyAssetDetail(id) {
  return request({ url: `/personal-assets/detail/${id}`, method: 'get' })
}
// 部门资产列表（按员工分组）
export function getDeptAssetList(params) {
  return request({ url: '/personal-assets/dept-list', method: 'get', params })
}
// 部门切换列表
export function getAssetDepartments() {
  return request({ url: '/personal-assets/departments', method: 'get' })
}
// 员工选项（调拨目标）
export function getAssetEmployeeOptions(keyword) {
  return request({ url: '/personal-assets/employee-options', method: 'get', params: { keyword } })
}
// 调拨资产
export function transferAsset(data) {
  return request({ url: '/personal-assets/transfer', method: 'post', data })
}
// 退还资产
export function returnAsset(data) {
  return request({ url: '/personal-assets/return', method: 'post', data })
}
// 更新存放位置
export function updateAssetLocation(data) {
  return request({ url: '/personal-assets/update-location', method: 'post', data })
}
// 更新资产关联采购信息
export function updateAssetRelated(data) {
  return request({ url: '/personal-assets/update-related', method: 'post', data })
}
// 获取我的资产配件（供报工选择）
export function getMyMaterials(params) {
  return request({ url: '/personal-assets/my-materials', method: 'get', params })
}
// 校验个人配件库存
export function checkMaterial(data) {
  return request({ url: '/personal-assets/check-material', method: 'post', data })
}
// 领用记录列表
export function getApplyRecords(params) {
  return request({ url: '/personal-assets/apply-records', method: 'get', params })
}
// 领用单详情
export function getApplyDetail(params) {
  return request({ url: '/personal-assets/apply-detail', method: 'get', params })
}
// 领用记录导出
export function exportApplyRecords(params) {
  return request({ url: '/personal-assets/apply-export', method: 'get', params, responseType: 'blob' })
}
// 可借用资产列表
export function getBorrowableAssets(params) {
  return request({ url: '/personal-assets/borrowable', method: 'get', params })
}
// 申请调拨
export function applyTransfer(data) {
  return request({ url: '/personal-assets/transfer-apply', method: 'post', data })
}
// 发起调拨
export function createTransfer(data) {
  return request({ url: '/personal-assets/transfer-create', method: 'post', data })
}
// 待确认调拨列表
export function getPendingTransfers(params) {
  return request({ url: '/personal-assets/transfer-pending', method: 'get', params })
}
// 确认调拨
export function confirmTransfer(data) {
  return request({ url: '/personal-assets/transfer-confirm', method: 'post', data })
}
// 拒绝调拨
export function rejectTransfer(data) {
  return request({ url: '/personal-assets/transfer-reject', method: 'post', data })
}
// 调拨记录列表
export function getTransferRecords(params) {
  return request({ url: '/personal-assets/transfer-records', method: 'get', params })
}
// 调拨详情
export function getTransferDetail(params) {
  return request({ url: '/personal-assets/transfer-detail', method: 'get', params })
}
// 调拨记录导出
export function exportTransferRecords(params) {
  return request({ url: '/personal-assets/transfer-export', method: 'get', params, responseType: 'blob' })
}
// 消耗记录列表（来源于报工）
export function getConsumeRecords(params) {
  return request({ url: '/personal-assets/consume-records', method: 'get', params })
}
// 消耗详情
export function getConsumeDetail(params) {
  return request({ url: '/personal-assets/consume-detail', method: 'get', params })
}
// 消耗统计-总览
export function getConsumeStatsOverview(params) {
  return request({ url: '/personal-assets/consume-stats/overview', method: 'get', params })
}
// 消耗统计-趋势
export function getConsumeStatsTrend(params) {
  return request({ url: '/personal-assets/consume-stats/trend', method: 'get', params })
}
// 消耗统计-配件排行
export function getConsumeStatsPartRanking(params) {
  return request({ url: '/personal-assets/consume-stats/part-ranking', method: 'get', params })
}
// 消耗统计-工单排名
export function getConsumeStatsOrderRanking(params) {
  return request({ url: '/personal-assets/consume-stats/order-ranking', method: 'get', params })
}
// 消耗统计-分类占比
export function getConsumeStatsCategory(params) {
  return request({ url: '/personal-assets/consume-stats/category-distribution', method: 'get', params })
}
// 可退还资产列表
export function getReturnableAssets(params) {
  return request({ url: '/personal-assets/returnable-assets', method: 'get', params })
}
// 提交退还申请
export function submitReturn(data) {
  return request({ url: '/personal-assets/return-submit', method: 'post', data })
}
// 退还记录列表
export function getReturnRecords(params) {
  return request({ url: '/personal-assets/return-records', method: 'get', params })
}
// 退还详情
export function getReturnDetail(params) {
  return request({ url: '/personal-assets/return-detail', method: 'get', params })
}
// 个人资产报表-总览
export function getReportPersonalOverview(params) {
  return request({ url: '/personal-assets/report/personal/overview', method: 'get', params })
}
// 个人资产报表-类型分布
export function getReportTypeDistribution(params) {
  return request({ url: '/personal-assets/report/personal/type-distribution', method: 'get', params })
}
// 个人资产报表-状态分布
export function getReportStatusDistribution(params) {
  return request({ url: '/personal-assets/report/personal/status-distribution', method: 'get', params })
}
// 个人资产报表-趋势
export function getReportPersonalTrend(params) {
  return request({ url: '/personal-assets/report/personal/trend', method: 'get', params })
}
// 个人资产报表-明细
export function getReportPersonalDetail(params) {
  return request({ url: '/personal-assets/report/personal/detail', method: 'get', params })
}
// 个人资产报表-导出
export function exportReportPersonal(params) {
  return request({ url: '/personal-assets/report/personal/export', method: 'get', params, responseType: 'blob' })
}
// 部门资产汇总-总览
export function getReportDeptOverview(params) {
  return request({ url: '/personal-assets/report/dept/overview', method: 'get', params })
}
// 部门资产汇总-排行
export function getReportDeptRanking(params) {
  return request({ url: '/personal-assets/report/dept/ranking', method: 'get', params })
}
// 部门资产汇总-类型分布
export function getReportDeptTypeDistribution(params) {
  return request({ url: '/personal-assets/report/dept/type-distribution', method: 'get', params })
}
// 部门资产汇总-对比表
export function getReportDeptComparison(params) {
  return request({ url: '/personal-assets/report/dept/comparison', method: 'get', params })
}
// 部门资产汇总-导出
export function exportReportDept(params) {
  return request({ url: '/personal-assets/report/dept/export', method: 'get', params, responseType: 'blob' })
}
// 调拨统计-总览
export function getReportTransferOverview(params) {
  return request({ url: '/personal-assets/report/transfer/overview', method: 'get', params })
}
// 调拨统计-趋势
export function getReportTransferTrend(params) {
  return request({ url: '/personal-assets/report/transfer/trend', method: 'get', params })
}
// 调拨统计-类型分布
export function getReportTransferType(params) {
  return request({ url: '/personal-assets/report/transfer/type-distribution', method: 'get', params })
}
// 调拨统计-调出排行
export function getReportTransferSource(params) {
  return request({ url: '/personal-assets/report/transfer/source-ranking', method: 'get', params })
}
// 调拨统计-调入排行
export function getReportTransferTarget(params) {
  return request({ url: '/personal-assets/report/transfer/target-ranking', method: 'get', params })
}
// 调拨统计-明细
export function getReportTransferDetail(params) {
  return request({ url: '/personal-assets/report/transfer/detail', method: 'get', params })
}
// 调拨统计-导出
export function exportReportTransfer(params) {
  return request({ url: '/personal-assets/report/transfer/export', method: 'get', params, responseType: 'blob' })
}
// 成本核算-总览
export function getCostOverview(params) {
  return request({ url: '/personal-assets/report/cost/overview-v2', method: 'get', params })
}
// 成本核算-工单
export function getCostOrders(params) {
  return request({ url: '/personal-assets/report/cost/orders', method: 'get', params })
}
// 成本核算-产品
export function getCostProducts(params) {
  return request({ url: '/personal-assets/report/cost/products', method: 'get', params })
}
// 成本核算-部门
export function getCostDepartments(params) {
  return request({ url: '/personal-assets/report/cost/departments', method: 'get', params })
}
// 成本核算-设备
export function getCostEquipment(params) {
  return request({ url: '/personal-assets/report/cost/equipment', method: 'get', params })
}
// 成本核算-工单详情
export function getCostOrderDetail(params) {
  return request({ url: '/personal-assets/report/cost/order-detail', method: 'get', params })
}
// 成本核算-导出
export function exportCostReport(params) {
  return request({ url: '/personal-assets/report/cost/export-v2', method: 'get', params, responseType: 'blob' })
}
// 部门资产导出
export function exportDeptAsset(params) {
  return request({ url: '/personal-assets/dept-export', method: 'get', params, responseType: 'blob' })
}
// 全部资产列表（支持 tab 参数：all/warehouse/personal）
export function getAllAssetList(params) {
  return request({ url: '/personal-assets/all-list', method: 'get', params })
}
// 全部资产统计（支持 tab 参数）
export function getAllAssetStatistics(params) {
  return request({ url: '/personal-assets/all-statistics', method: 'get', params })
}
// 在库资产列表（总仓库）
export function getWarehouseAssetList(params) {
  return request({ url: '/personal-assets/warehouse-list', method: 'get', params })
}
// 在册资产列表（个人名下）
export function getInServiceAssetList(params) {
  return request({ url: '/personal-assets/in-service-list', method: 'get', params })
}
// 全部部门树
export function getAllAssetDepartments() {
  return request({ url: '/personal-assets/all-departments', method: 'get' })
}
// 全部资产导出
export function exportAllAsset(params) {
  return request({ url: '/personal-assets/all-export', method: 'get', params, responseType: 'blob' })
}
