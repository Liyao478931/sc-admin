/**
 * 界面配置 API
 */
import request from './request'

export function getThemeConfig() { return request({ url: '/theme/config', method: 'get' }) }
export function saveThemeConfig(data) { return request({ url: '/theme/config', method: 'put', data }) }
export function resetThemeConfig() { return request({ url: '/theme/reset', method: 'post' }) }
export function getThemeSchemes() { return request({ url: '/theme/schemes', method: 'get' }) }
export function createThemeScheme(data) { return request({ url: '/theme/schemes', method: 'post', data }) }
export function updateThemeScheme(id, data) { return request({ url: `/theme/schemes/${id}`, method: 'put', data }) }
export function deleteThemeScheme(id) { return request({ url: `/theme/schemes/${id}`, method: 'delete' }) }
export function activateThemeScheme(id) { return request({ url: `/theme/schemes/${id}/activate`, method: 'post' }) }
export function duplicateThemeScheme(id, data) { return request({ url: `/theme/schemes/${id}/duplicate`, method: 'post', data }) }
export function exportThemeConfig(params) { return request({ url: '/theme/export', method: 'get', params }) }
export function importThemeConfig(data) { return request({ url: '/theme/import', method: 'post', data }) }
export function uploadThemeFile(data) { return request({ url: '/theme/upload', method: 'post', data }) }
