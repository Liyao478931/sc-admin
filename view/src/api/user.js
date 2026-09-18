/**
 * 用户管理 API
 */
import request from './request'

export function getUserList(params) {
  return request({ url: '/users', method: 'get', params })
}
export function getUserDetail(id) {
  return request({ url: `/users/${id}`, method: 'get' })
}
export function createUser(data) {
  return request({ url: '/users', method: 'post', data })
}
export function updateUser(id, data) {
  return request({ url: `/users/${id}`, method: 'put', data })
}
export function deleteUser(id) {
  return request({ url: `/users/${id}`, method: 'delete' })
}
export function setUserStatus(id, status) {
  return request({ url: `/users/${id}/status`, method: 'put', data: { status } })
}
export function resetUserPassword(id, password) {
  return request({ url: `/users/${id}/reset-password`, method: 'put', data: { password } })
}

/** 部门 */
export function getDepartmentTree() {
  return request({ url: '/departments/tree', method: 'get' })
}
export function createDept(data) {
  return request({ url: '/departments', method: 'post', data })
}
export function updateDept(id, data) {
  return request({ url: `/departments/${id}`, method: 'put', data })
}
export function deleteDept(id) {
  return request({ url: `/departments/${id}`, method: 'delete' })
}

/** 角色 */
export function getRoleList() {
  return request({ url: '/roles', method: 'get' })
}

/** 分配用户角色 */
export function assignUserRoles(userId, roleIds) {
  return request({ url: `/users/${userId}/roles`, method: 'put', data: { role_ids: roleIds } })
}

/** 个人中心 */
export function getProfile() {
  return request({ url: '/profile', method: 'get' })
}
export function updateProfile(data) {
  return request({ url: '/profile', method: 'put', data })
}
export function uploadAvatar(data) {
  return request({ url: '/profile/avatar', method: 'post', data })
}
export function removeAvatar() {
  return request({ url: '/profile/avatar', method: 'delete' })
}
export function sendChangePwdSms() {
  return request({ url: '/profile/send-sms', method: 'post' })
}
export function verifyChangePwdSms(code) {
  return request({ url: '/profile/verify-sms', method: 'post', data: { code } })
}
export function changeProfilePassword(data) {
  return request({ url: '/profile/password', method: 'put', data })
}
export function sendChangePhoneSms(newPhone) {
  return request({ url: '/profile/change-phone-sms', method: 'post', data: { new_phone: newPhone } })
}
export function changePhone(data) {
  return request({ url: '/profile/change-phone', method: 'post', data })
}
export function getLoginLogs(params) {
  return request({ url: '/profile/login-logs', method: 'get', params })
}

// 用户下拉选项（轻量，登录即可访问；避免完整列表 /users 需 user:view 权限）
export function getUserOptions() {
  return request({ url: '/users/options', method: 'get' })
}
