/**
 * 设备保养任务 API 封装
 */
import request from './request'

// 任务
export const getTaskList = (p) => request({ url: '/device/maintenance/task/list', method: 'get', params: p })
export const getTaskDetail = (id) => request({ url: `/device/maintenance/task/detail/${id}`, method: 'get' })
export const getDeviceTasks = (deviceId) => request({ url: `/device/maintenance/task/device-tasks/${deviceId}`, method: 'get' })
export const assignTask = (id, d) => request({ url: `/device/maintenance/task/assign/${id}`, method: 'put', data: d })
export const cancelTask = (id, d) => request({ url: `/device/maintenance/task/cancel/${id}`, method: 'put', data: d })
export const generateTask = (d) => request({ url: '/device/maintenance/task/generate', method: 'post', data: d })
export const getTaskStatistics = () => request({ url: '/device/maintenance/task/statistics', method: 'get' })
export const sendTaskRemind = (id) => request({ url: `/device/maintenance/task/send-remind/${id}`, method: 'post' })
