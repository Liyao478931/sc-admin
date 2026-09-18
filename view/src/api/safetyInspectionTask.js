/**
 * 安全检查任务 API 封装
 * 路由前缀：/safety/inspection/task
 */
import request from './request'

// ===== 任务列表 =====
export const getTaskList = (p) => request({ url: '/safety/inspection/task/list', method: 'get', params: p })
export const getTaskDetail = (id) => request({ url: `/safety/inspection/task/detail/${id}`, method: 'get' })
export const getTaskStatistics = () => request({ url: '/safety/inspection/task/statistics', method: 'get' })
export const getTaskItems = (id) => request({ url: `/safety/inspection/task/items/${id}`, method: 'get' })

// ===== 任务操作 =====
export const assignTask = (id, executorId) => request({ url: `/safety/inspection/task/assign/${id}`, method: 'put', data: { executor_id: executorId } })
export const cancelTask = (id, cancelReason) => request({ url: `/safety/inspection/task/cancel/${id}`, method: 'put', data: { cancel_reason: cancelReason } })
export const generateTask = (d) => request({ url: '/safety/inspection/task/generate', method: 'post', data: d })
export const startTask = (id) => request({ url: `/safety/inspection/task/start/${id}`, method: 'put' })
export const submitTask = (id, d) => request({ url: `/safety/inspection/task/submit/${id}`, method: 'post', data: d })
export const sendTaskRemind = (id) => request({ url: `/safety/inspection/task/send-remind/${id}`, method: 'post' })

// ===== 关联数据 =====
export const getPlanOptions = () => request({ url: '/safety/inspection/plan/list', method: 'get', params: { page: 1, limit: 100 } })
export const getTypeOptions = () => request({ url: '/safety/inspection/plan/type/options', method: 'get' })
