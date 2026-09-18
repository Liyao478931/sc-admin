/**
 * 设备巡检 API 封装
 */
import request from './request'

// 计划
export const getPlanList = (p) => request({ url: '/device/inspection/plan/list', method: 'get', params: p })
export const getPlanDetail = (id) => request({ url: `/device/inspection/plan/detail/${id}`, method: 'get' })
export const addPlan = (d) => request({ url: '/device/inspection/plan/add', method: 'post', data: d })
export const editPlan = (id, d) => request({ url: `/device/inspection/plan/edit/${id}`, method: 'put', data: d })
export const deletePlan = (id) => request({ url: `/device/inspection/plan/delete/${id}`, method: 'delete' })
export const togglePlanStatus = (id, status) => request({ url: `/device/inspection/plan/status/${id}`, method: 'put', data: { status } })
export const copyPlan = (id) => request({ url: `/device/inspection/plan/copy/${id}`, method: 'post' })
export const getPlanOptions = () => request({ url: '/device/inspection/plan/options', method: 'get' })

// 模板
export const getTemplateList = (p) => request({ url: '/device/inspection/template/list', method: 'get', params: p })
export const getTemplateDetail = (id) => request({ url: `/device/inspection/template/detail/${id}`, method: 'get' })
export const addTemplate = (d) => request({ url: '/device/inspection/template/add', method: 'post', data: d })
export const editTemplate = (id, d) => request({ url: `/device/inspection/template/edit/${id}`, method: 'put', data: d })
export const deleteTemplate = (id) => request({ url: `/device/inspection/template/delete/${id}`, method: 'delete' })
export const copyTemplate = (id) => request({ url: `/device/inspection/template/copy/${id}`, method: 'post' })
export const getTemplateOptions = () => request({ url: '/device/inspection/template/options', method: 'get' })

// 任务
export const getTaskList = (p) => request({ url: '/device/inspection/task/list', method: 'get', params: p })
export const getTaskDetail = (id) => request({ url: `/device/inspection/task/detail/${id}`, method: 'get' })
export const getDeviceTasks = (id) => request({ url: `/device/inspection/task/device-tasks/${id}`, method: 'get' })
export const assignTask = (id, executorId) => request({ url: `/device/inspection/task/assign/${id}`, method: 'put', data: { executor_id: executorId } })
export const cancelTask = (id) => request({ url: `/device/inspection/task/cancel/${id}`, method: 'put' })
export const generateTask = (planId, executeDate) => request({ url: '/device/inspection/task/generate', method: 'post', data: { plan_id: planId, execute_date: executeDate } })
export const getTaskStatistics = () => request({ url: '/device/inspection/task/statistics', method: 'get' })

// 执行
export const startExecute = (id) => request({ url: `/device/inspection/execute/start/${id}`, method: 'put' })
export const submitExecute = (d) => request({ url: '/device/inspection/execute/submit', method: 'post', data: d })
export const uploadAttachment = (formData) => request({ url: '/device/inspection/execute/upload-attachment', method: 'post', data: formData })
export const getCheckItems = (taskId) => request({ url: `/device/inspection/execute/check-items/${taskId}`, method: 'get' })
export const draftExecute = (d) => request({ url: '/device/inspection/execute/draft', method: 'post', data: d })

// 记录
export const getRecordList = (p) => request({ url: '/device/inspection/record/list', method: 'get', params: p })
export const getRecordDetail = (id) => request({ url: `/device/inspection/record/detail/${id}`, method: 'get' })
export const auditRecord = (id, d) => request({ url: `/device/inspection/record/audit/${id}`, method: 'put', data: d })
export const exportRecords = (p) => request({ url: '/device/inspection/record/export', method: 'get', params: p })
export const deleteRecord = (id) => request({ url: `/device/inspection/record/delete/${id}`, method: 'delete' })

// 隐患
export const getHazardList = (p) => request({ url: '/device/inspection/hazard/list', method: 'get', params: p })
export const getHazardDetail = (id) => request({ url: `/device/inspection/hazard/detail/${id}`, method: 'get' })
export const handleHazard = (id, d) => request({ url: `/device/inspection/hazard/handle/${id}`, method: 'put', data: d })
export const closeHazard = (id, d) => request({ url: `/device/inspection/hazard/close/${id}`, method: 'put', data: d })
export const convertHazard = (id) => request({ url: `/device/inspection/hazard/convert-repair/${id}`, method: 'post' })
export const getHazardStatistics = () => request({ url: '/device/inspection/hazard/statistics', method: 'get' })

// 统计
export const getOverview = () => request({ url: '/device/inspection/statistics/overview', method: 'get' })
export const getTrend = () => request({ url: '/device/inspection/statistics/trend', method: 'get' })
export const getAbnormalTop = () => request({ url: '/device/inspection/statistics/abnormal-top', method: 'get' })
export const getExecutorTop = () => request({ url: '/device/inspection/statistics/executor-top', method: 'get' })
export const getCoverage = () => request({ url: '/device/inspection/statistics/coverage', method: 'get' })
