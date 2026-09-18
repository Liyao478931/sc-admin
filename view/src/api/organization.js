import request from './request'

export function getDeptTree() { return request({ url: '/organization/departments', method: 'get' }) }
export function getDept(id) { return request({ url: `/organization/departments/${id}`, method: 'get' }) }
export function createDept(data) { return request({ url: '/organization/departments', method: 'post', data }) }
export function updateDept(id, data) { return request({ url: `/organization/departments/${id}`, method: 'put', data }) }
export function deleteDept(id) { return request({ url: `/organization/departments/${id}`, method: 'delete' }) }
export function sortDept(id, sort) { return request({ url: `/organization/departments/${id}/sort`, method: 'put', data: { sort } }) }
export function getDeptMembers(id) { return request({ url: `/organization/departments/${id}/members`, method: 'get' }) }

export function getPositions(deptId) { return request({ url: '/organization/positions', method: 'get', params: { department_id: deptId } }) }
export function getPosition(id) { return request({ url: `/organization/positions/${id}`, method: 'get' }) }
export function createPosition(data) { return request({ url: '/organization/positions', method: 'post', data }) }
export function updatePosition(id, data) { return request({ url: `/organization/positions/${id}`, method: 'put', data }) }
export function deletePosition(id) { return request({ url: `/organization/positions/${id}`, method: 'delete' }) }
