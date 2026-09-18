import request from './request'

export function getMenuTree() { return request({ url: '/menus', method: 'get' }) }
export function getUserMenuTree() { return request({ url: '/menus/user', method: 'get' }) }
export function getMenu(id) { return request({ url: `/menus/${id}`, method: 'get' }) }
export function createMenu(data) { return request({ url: '/menus', method: 'post', data }) }
export function updateMenu(id, data) { return request({ url: `/menus/${id}`, method: 'put', data }) }
export function deleteMenu(id) { return request({ url: `/menus/${id}`, method: 'delete' }) }
export function sortMenu(id, sort) { return request({ url: `/menus/${id}/sort`, method: 'put', data: { sort } }) }
export function toggleMenuStatus(id) { return request({ url: `/menus/${id}/status`, method: 'put' }) }
export function clearMenuCache() { return request({ url: '/menus/cache', method: 'get' }) }
