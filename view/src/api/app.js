import request from './request'

// 路径管理
export function getPathList(params) { return request({ url: '/admin/paths', method: 'get', params }) }
export function getPathAll() { return request({ url: '/admin/paths/all', method: 'get' }) }
export function getPath(id) { return request({ url: `/admin/paths/${id}`, method: 'get' }) }
export function createPath(data) { return request({ url: '/admin/paths', method: 'post', data }) }
export function updatePath(id, data) { return request({ url: `/admin/paths/${id}`, method: 'put', data }) }
export function deletePath(id) { return request({ url: `/admin/paths/${id}`, method: 'delete' }) }
export function togglePathStatus(id, status) { return request({ url: `/admin/paths/${id}/status`, method: 'put', data: { status } }) }

// 功能配置
export function getFunctionList(params) { return request({ url: '/admin/functions', method: 'get', params }) }
export function getFunctionAll() { return request({ url: '/admin/functions/all', method: 'get' }) }
export function getFunction(id) { return request({ url: `/admin/functions/${id}`, method: 'get' }) }
export function createFunction(data) { return request({ url: '/admin/functions', method: 'post', data }) }
export function updateFunction(id, data) { return request({ url: `/admin/functions/${id}`, method: 'put', data }) }
export function deleteFunction(id) { return request({ url: `/admin/functions/${id}`, method: 'delete' }) }
export function toggleFunctionStatus(id, status) { return request({ url: `/admin/functions/${id}/status`, method: 'put', data: { status } }) }

// 轮播组管理
export function getBannerGroups() { return request({ url: '/admin/banner-groups', method: 'get' }) }
export function createBannerGroup(data) { return request({ url: '/admin/banner-groups', method: 'post', data }) }
export function updateBannerGroup(id, data) { return request({ url: `/admin/banner-groups/${id}`, method: 'put', data }) }
export function deleteBannerGroup(id) { return request({ url: `/admin/banner-groups/${id}`, method: 'delete' }) }

// 轮播图管理
export function getBannerList(params) { return request({ url: '/admin/banners', method: 'get', params }) }
export function createBanner(data) { return request({ url: '/admin/banners', method: 'post', data }) }
export function updateBanner(id, data) { return request({ url: `/admin/banners/${id}`, method: 'put', data }) }
export function deleteBanner(id) { return request({ url: `/admin/banners/${id}`, method: 'delete' }) }
export function batchUploadBanners(data) { return request({ url: '/admin/banners/batch', method: 'post', data, headers: { 'Content-Type': 'multipart/form-data' } }) }
export function sortBanners(ids) { return request({ url: '/admin/banners/sort', method: 'put', data: { ids } }) }
export function getBannerStats(params) { return request({ url: '/admin/banners/statistics', method: 'get', params }) }

// 启动页配置
export function getSplashConfig() { return request({ url: '/admin/splash', method: 'get' }) }
export function saveSplashConfig(data) { return request({ url: '/admin/splash', method: 'put', data }) }
export function uploadSplashFile(data) { return request({ url: '/admin/splash/upload', method: 'post', data, headers: { 'Content-Type': 'multipart/form-data' } }) }

// 登录方式配置
export function getLoginMethods() { return request({ url: '/admin/login-methods', method: 'get' }) }
export function saveLoginMethods(data) { return request({ url: '/admin/login-methods', method: 'put', data }) }

// 登录页面管理
export function getLoginPageConfig() { return request({ url: '/admin/login-page', method: 'get' }) }
export function saveLoginPageConfig(data) { return request({ url: '/admin/login-page', method: 'put', data }) }
