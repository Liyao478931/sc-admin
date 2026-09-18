import request from './request'

// ============ DIY 页面访问统计（E方案） ============
export function getDiyStatsOverview(params) {
  return request({ url: '/admin/diy-stats/overview', method: 'get', params })
}
export function getDiyStatsDetail(params) {
  return request({ url: '/admin/diy-stats/detail', method: 'get', params })
}
export function getDiyStatsPages(params) {
  return request({ url: '/admin/diy-stats/pages', method: 'get', params })
}
