/**
 * 安全驾驶舱 API
 * 路由前缀：/safety/dashboard
 */
import request from './request'

/** 获取概览统计 */
export const getDashboardOverview = () => request({ url: '/safety/dashboard/overview', method: 'get' })

/** 获取隐患趋势（近 N 个月发现/关闭） */
export const getHazardTrend = (months = 12) => request({ url: '/safety/dashboard/hazard-trend', method: 'get', params: { months } })

/** 获取事故趋势（近 N 个月） */
export const getAccidentTrend = (months = 12) => request({ url: '/safety/dashboard/accident-trend', method: 'get', params: { months } })

/** 获取隐患等级分布 */
export const getHazardLevel = () => request({ url: '/safety/dashboard/hazard-level', method: 'get' })

/** 获取风险等级分布 */
export const getRiskLevel = () => request({ url: '/safety/dashboard/risk-level', method: 'get' })

/** 获取今日待办事项 */
export const getDashboardTodos = () => request({ url: '/safety/dashboard/todos', method: 'get' })

/** 获取即将到期预警 */
export const getUpcomingWarnings = () => request({ url: '/safety/dashboard/upcoming-warnings', method: 'get' })
