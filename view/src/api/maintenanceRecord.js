/**
 * 保养记录 API 封装
 */
import request from './request'

export const getRecordList = (p) => request({ url: '/device/maintenance/record/list', method: 'get', params: p })
export const getRecordDetail = (id) => request({ url: `/device/maintenance/record/detail/${id}`, method: 'get' })
export const acceptRecord = (id, d) => request({ url: `/device/maintenance/record/accept/${id}`, method: 'put', data: d })
export const rejectRecord = (id, d) => request({ url: `/device/maintenance/record/reject/${id}`, method: 'put', data: d })
export const getRecordHistory = (p) => request({ url: '/device/maintenance/record/history', method: 'get', params: p })
export const exportRecords = (p) => request({ url: '/device/maintenance/record/export', method: 'get', params: p })
export const getRecordStatistics = () => request({ url: '/device/maintenance/record/statistics', method: 'get' })
