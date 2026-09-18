import request from './request'

// 配件搜索（带库存）
export function searchPickMaterials(params) {
  return request({ url: '/personal-assets/pick-apply/materials', method: 'get', params })
}
// 创建申请（draft/submit）
export function createPickApply(data) {
  return request({ url: '/personal-assets/pick-apply/create', method: 'post', data })
}
// 我的申请列表
export function getMyPickApplies(params) {
  return request({ url: '/personal-assets/pick-apply/my-list', method: 'get', params })
}
// 申请详情
export function getPickApplyDetail(id) {
  return request({ url: `/personal-assets/pick-apply/detail/${id}`, method: 'get' })
}
// 取消申请
export function cancelPickApply(id) {
  return request({ url: `/personal-assets/pick-apply/cancel/${id}`, method: 'post' })
}
// 领用审批列表
export function getPickApproveList(params) {
  return request({ url: '/personal-assets/pick-apply/approve-list', method: 'get', params })
}
// 审批操作
export function approvePickApply(id, data) {
  return request({ url: `/personal-assets/pick-apply/approve/${id}`, method: 'post', data })
}
