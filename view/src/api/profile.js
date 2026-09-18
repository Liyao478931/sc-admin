import request from './request'

/** 获取职级下拉选项（hr_rank 启用记录，按 sort 升序） */
export function getRankOptions() {
  return request({ url: '/hr/rank/options', method: 'get' })
}

/** 职级管理列表 */
export function getRankList(params) {
  return request({ url: '/hr/rank/list', method: 'get', params })
}

/** 新增职级 */
export function addRank(data) {
  return request({ url: '/hr/rank/add', method: 'post', data })
}

/** 编辑职级 */
export function editRank(id, data) {
  return request({ url: `/hr/rank/edit/${id}`, method: 'put', data })
}

/** 删除职级 */
export function deleteRank(id) {
  return request({ url: `/hr/rank/delete/${id}`, method: 'delete' })
}

/** 启用/停用职级 */
export function toggleRank(id, status) {
  return request({ url: `/hr/rank/status/${id}`, method: 'put', data: { status } })
}

export function getProfileList(params) {
  return request({ url: '/profiles', method: 'get', params })
}
export function getProfileStatistics() {
  return request({ url: '/profiles/statistics', method: 'get' })
}
export function getProfileDetail(id) {
  return request({ url: `/profiles/${id}`, method: 'get' })
}
export function createProfile(data) {
  return request({ url: '/profiles', method: 'post', data })
}
export function updateProfile(id, data) {
  return request({ url: `/profiles/${id}`, method: 'put', data })
}
export function deleteProfile(id) {
  return request({ url: `/profiles/${id}`, method: 'delete' })
}
export function exportProfiles(params) {
  return request({ url: '/profiles/export', method: 'post', data: params })
}
export function getImportTemplate() {
  return request({ url: '/profiles/import/template', method: 'get' })
}
export function importProfiles(rows) {
  return request({ url: '/profiles/import', method: 'post', data: { rows } })
}
export function getProfilePermissions(id) {
  return request({ url: `/profiles/${id}/permissions`, method: 'get' })
}
export function changeProfileStatus(id, status, resignationDate) {
  return request({ url: `/profiles/${id}/status`, method: 'put', data: { status, resignation_date: resignationDate } })
}
export function syncAllProfiles() {
  return request({ url: '/profiles/sync', method: 'post' })
}
export function checkProfileConsistency() {
  return request({ url: '/profiles/check-consistency', method: 'get' })
}
