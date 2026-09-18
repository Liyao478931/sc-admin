import request from './request'

// 角色
export function getRoleList() { return request({ url: '/roles', method: 'get' }) }
export function createRole(data) { return request({ url: '/roles', method: 'post', data }) }
export function updateRole(id, data) { return request({ url: `/roles/${id}`, method: 'put', data }) }
export function deleteRole(id) { return request({ url: `/roles/${id}`, method: 'delete' }) }
export function getRolePermissions(id) { return request({ url: `/roles/${id}/permissions`, method: 'get' }) }
export function saveRolePermissions(id, permissionIds) { return request({ url: `/roles/${id}/permissions`, method: 'put', data: { permission_ids: permissionIds } }) }

// 权限
export function getPermissionTree(type) { return request({ url: '/permissions/tree', method: 'get', params: type ? { type } : {} }) }
export function createPermission(data) { return request({ url: '/permissions', method: 'post', data }) }
export function updatePermission(id, data) { return request({ url: `/permissions/${id}`, method: 'put', data }) }
export function sortPermission(data) { return request({ url: '/permissions/sort', method: 'put', data }) }
export function deletePermission(id) { return request({ url: `/permissions/${id}`, method: 'delete' }) }
export function syncPermissions() { return request({ url: '/permissions/sync', method: 'post' }) }

// 应用权限（供功能配置下拉选择）
export function getAppPermissions() { return request({ url: '/permissions/app', method: 'get' }) }
