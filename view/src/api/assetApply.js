import request from './request'

// 资产档案搜索（远程搜索）
export function searchAssetArchive(params) {
  return request({ url: '/personal-assets/asset-apply/archive-search', method: 'get', params })
}
// 创建申请（draft/submit）
export function createAssetApply(data) {
  return request({ url: '/personal-assets/asset-apply/submit', method: 'post', data })
}
// 我的申请列表
export function getMyAssetApplies(params) {
  return request({ url: '/personal-assets/asset-apply/my-list', method: 'get', params })
}
// 申请详情
export function getAssetApplyDetail(id) {
  return request({ url: `/personal-assets/asset-apply/detail/${id}`, method: 'get' })
}
// 取消申请
export function cancelAssetApply(id) {
  return request({ url: `/personal-assets/asset-apply/cancel/${id}`, method: 'post' })
}