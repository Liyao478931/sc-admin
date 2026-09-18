import request from './request'

// 盘点单列表
export function getInventoryList(params) {
  return request({ url: '/personal-assets/inventory/list', method: 'get', params })
}
// 创建盘点单
export function createInventory(data) {
  return request({ url: '/personal-assets/inventory/create', method: 'post', data })
}
// 盘点任务列表
export function getInventoryTasks(params) {
  return request({ url: '/personal-assets/inventory/tasks', method: 'get', params })
}
// 录入盘点结果
export function checkInventory(data) {
  return request({ url: '/personal-assets/inventory/check', method: 'post', data })
}
// 提交盘点
export function submitInventory(data) {
  return request({ url: '/personal-assets/inventory/submit', method: 'post', data })
}
// 盘点详情
export function getInventoryDetail(params) {
  return request({ url: '/personal-assets/inventory/detail', method: 'get', params })
}
// 处理差异
export function handleInventoryDiff(data) {
  return request({ url: '/personal-assets/inventory/handle-diff', method: 'post', data })
}
// 导出盘点报告
export function exportInventory(params) {
  return request({ url: '/personal-assets/inventory/export', method: 'get', params, responseType: 'blob' })
}
// 取消盘点单
export function cancelInventory(data) {
  return request({ url: '/personal-assets/inventory/cancel', method: 'post', data })
}