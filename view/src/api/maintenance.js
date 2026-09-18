/**
 * 设备保养管理 API 封装
 */
import request from './request'

// ===== 保养等级 =====
export const getLevelList = (p) => request({ url: '/device/maintenance/level/list', method: 'get', params: p })
export const getLevelOptions = () => request({ url: '/device/maintenance/level/options', method: 'get' })
export const getLevelDetail = (id) => request({ url: `/device/maintenance/level/detail/${id}`, method: 'get' })
export const addLevel = (d) => request({ url: '/device/maintenance/level/add', method: 'post', data: d })
export const editLevel = (id, d) => request({ url: `/device/maintenance/level/edit/${id}`, method: 'put', data: d })
export const deleteLevel = (id) => request({ url: `/device/maintenance/level/delete/${id}`, method: 'delete' })

// ===== 保养模板 =====
export const getTemplateList = (p) => request({ url: '/device/maintenance/template/list', method: 'get', params: p })
export const getTemplateOptions = (p) => request({ url: '/device/maintenance/template/options', method: 'get', params: p })
export const getTemplateDetail = (id) => request({ url: `/device/maintenance/template/detail/${id}`, method: 'get' })
export const addTemplate = (d) => request({ url: '/device/maintenance/template/add', method: 'post', data: d })
export const editTemplate = (id, d) => request({ url: `/device/maintenance/template/edit/${id}`, method: 'put', data: d })
export const deleteTemplate = (id) => request({ url: `/device/maintenance/template/delete/${id}`, method: 'delete' })
export const copyTemplate = (id) => request({ url: `/device/maintenance/template/copy/${id}`, method: 'post' })

// ===== 保养计划 =====
export const getPlanList = (p) => request({ url: '/device/maintenance/plan/list', method: 'get', params: p })
export const getPlanDetail = (id) => request({ url: `/device/maintenance/plan/detail/${id}`, method: 'get' })
export const addPlan = (d) => request({ url: '/device/maintenance/plan/add', method: 'post', data: d })
export const editPlan = (id, d) => request({ url: `/device/maintenance/plan/edit/${id}`, method: 'put', data: d })
export const deletePlan = (id) => request({ url: `/device/maintenance/plan/delete/${id}`, method: 'delete' })
export const togglePlanStatus = (id, status) => request({ url: `/device/maintenance/plan/status/${id}`, method: 'put', data: { status } })
export const copyPlan = (id) => request({ url: `/device/maintenance/plan/copy/${id}`, method: 'post' })
export const getNextDate = (p) => request({ url: '/device/maintenance/plan/next-date', method: 'get', params: p })
export const getPlanStatistics = () => request({ url: '/device/maintenance/plan/statistics', method: 'get' })
