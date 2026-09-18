/**
 * 维修统计 API 封装
 * 路由前缀：/device/repair/statistics
 */
import request from './request'

// 概览统计
export const getRepairOverview = () => request({ url: '/device/repair/statistics/overview', method: 'get' })
// 工单趋势（近N个月）
export const getRepairTrend = (months) => request({ url: '/device/repair/statistics/trend', method: 'get', params: { months } })
// 故障类型分布
export const getFaultDistribution = () => request({ url: '/device/repair/statistics/fault-distribution', method: 'get' })
// 维修人员排行
export const getWorkerRanking = (limit) => request({ url: '/device/repair/statistics/worker-ranking', method: 'get', params: { limit } })
// 各故障类型平均维修时长
export const getAvgDuration = () => request({ url: '/device/repair/statistics/avg-duration', method: 'get' })
// 设备故障排行
export const getDeviceRanking = (limit) => request({ url: '/device/repair/statistics/device-ranking', method: 'get', params: { limit } })
// 紧急程度分布
export const getEmergencyDistribution = () => request({ url: '/device/repair/statistics/emergency-distribution', method: 'get' })
// 维修时长分布
export const getDurationDistribution = () => request({ url: '/device/repair/statistics/duration-distribution', method: 'get' })
// 同比/环比
export const getComparison = () => request({ url: '/device/repair/statistics/comparison', method: 'get' })
// 导出设备故障排行
export const exportDeviceRanking = (limit) => request({ url: '/device/repair/statistics/device-ranking-export', method: 'get', params: { limit } })
