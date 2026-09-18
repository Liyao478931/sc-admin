/**
 * 安全培训记录 API 封装
 * 路由前缀：/safety/training/record
 */
import request from './request'

export const getRecordList = (p) => request({ url: '/safety/training/record/list', method: 'get', params: p })
export const getRecordDetail = (id) => request({ url: `/safety/training/record/detail/${id}`, method: 'get' })
export const generateRecord = (planId) => request({ url: '/safety/training/record/generate', method: 'post', data: { plan_id: planId } })
export const updateExecution = (id, d) => request({ url: `/safety/training/record/update-execution/${id}`, method: 'put', data: d })
export const checkinRecord = (id, userId) => request({ url: `/safety/training/record/checkin/${id}`, method: 'put', data: { user_id: userId } })
export const batchCheckin = (id, userIds) => request({ url: `/safety/training/record/batch-checkin/${id}`, method: 'put', data: { user_ids: userIds } })
export const undoCheckinRecord = (id, userId) => request({ url: `/safety/training/record/undo-checkin/${id}`, method: 'put', data: { user_id: userId } })
export const getCheckinQrcode = (id) => request({ url: `/safety/training/record/qrcode/${id}`, method: 'get' })
export const evaluateRecord = (id, d) => request({ url: `/safety/training/record/evaluate/${id}`, method: 'put', data: d })
export const exportRecords = (p) => request({ url: '/safety/training/record/export', method: 'get', params: p })
export const exportCheckin = (id) => request({ url: `/safety/training/record/export-checkin/${id}`, method: 'get' })
export const getRecordStatistics = () => request({ url: '/safety/training/record/statistics', method: 'get' })
export const getTypeOptions = () => request({ url: '/safety/training/plan/type/options', method: 'get' })
export const reverseGeocode = (lat, lng) => request({ url: '/services/map/reverse-geocode', method: 'get', params: { lat, lng } })
