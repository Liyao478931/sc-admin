/**
 * 保养统计 API 封装
 */
import request from './request'

export const getStatisticsOverview = () => request({ url: '/device/maintenance/statistics/overview', method: 'get' })
export const getTrend = () => request({ url: '/device/maintenance/statistics/trend', method: 'get' })
export const getLevelDistribution = () => request({ url: '/device/maintenance/statistics/level-distribution', method: 'get' })
export const getCoverage = () => request({ url: '/device/maintenance/statistics/coverage', method: 'get' })
export const getExecutorTop = (limit) => request({ url: '/device/maintenance/statistics/executor-top', method: 'get', params: { limit } })
export const getFailureRate = () => request({ url: '/device/maintenance/statistics/failure-rate', method: 'get' })
export const getCost = () => request({ url: '/device/maintenance/statistics/cost', method: 'get' })
export const getOverdueDevices = () => request({ url: '/device/maintenance/statistics/overdue-devices', method: 'get' })
export const exportOverdueDevices = () => request({ url: '/device/maintenance/statistics/overdue-export', method: 'get' })
