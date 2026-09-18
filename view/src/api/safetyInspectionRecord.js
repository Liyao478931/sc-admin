/**
 * 安全检查记录 API 封装
 * 路由前缀：/safety/inspection/record
 */
import request from './request'

export const getRecordList = (p) => request({ url: '/safety/inspection/record/list', method: 'get', params: p })
export const getRecordDetail = (id) => request({ url: `/safety/inspection/record/detail/${id}`, method: 'get' })
export const exportRecords = (p) => request({ url: '/safety/inspection/record/export', method: 'get', params: p })
export const getRecordStatistics = () => request({ url: '/safety/inspection/record/statistics', method: 'get' })
export const getTypeOptions = () => request({ url: '/safety/inspection/plan/type/options', method: 'get' })
