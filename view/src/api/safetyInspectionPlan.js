/**
 * 安全检查计划 API 封装
 * 路由前缀：/safety/inspection/plan
 */
import request from './request'

// ===== 检查类型 =====
export const getTypeList = (p) => request({ url: '/safety/inspection/plan/type/list', method: 'get', params: p })
export const getTypeOptions = () => request({ url: '/safety/inspection/plan/type/options', method: 'get' })
export const getTypeDetail = (id) => request({ url: `/safety/inspection/plan/type/detail/${id}`, method: 'get' })
export const addType = (d) => request({ url: '/safety/inspection/plan/type/add', method: 'post', data: d })
export const editType = (id, d) => request({ url: `/safety/inspection/plan/type/edit/${id}`, method: 'put', data: d })
export const deleteType = (id) => request({ url: `/safety/inspection/plan/type/delete/${id}`, method: 'delete' })

// ===== 检查标准模板 =====
export const getTemplateList = (p) => request({ url: '/safety/inspection/plan/template/list', method: 'get', params: p })
export const getTemplateDetail = (id) => request({ url: `/safety/inspection/plan/template/detail/${id}`, method: 'get' })
export const getTemplateOptions = (typeId) => request({ url: '/safety/inspection/plan/template/options', method: 'get', params: { inspection_type_id: typeId } })
export const addTemplate = (d) => request({ url: '/safety/inspection/plan/template/add', method: 'post', data: d })
export const editTemplate = (id, d) => request({ url: `/safety/inspection/plan/template/edit/${id}`, method: 'put', data: d })
export const deleteTemplate = (id) => request({ url: `/safety/inspection/plan/template/delete/${id}`, method: 'delete' })
export const copyTemplate = (id) => request({ url: `/safety/inspection/plan/template/copy/${id}`, method: 'post' })

// ===== 检查计划 =====
export const getPlanList = (p) => request({ url: '/safety/inspection/plan/list', method: 'get', params: p })
export const getPlanDetail = (id) => request({ url: `/safety/inspection/plan/detail/${id}`, method: 'get' })
export const addPlan = (d) => request({ url: '/safety/inspection/plan/add', method: 'post', data: d })
export const editPlan = (id, d) => request({ url: `/safety/inspection/plan/edit/${id}`, method: 'put', data: d })
export const deletePlan = (id) => request({ url: `/safety/inspection/plan/delete/${id}`, method: 'delete' })
export const changePlanStatus = (id, status) => request({ url: `/safety/inspection/plan/status/${id}`, method: 'put', data: { status } })
export const copyPlan = (id) => request({ url: `/safety/inspection/plan/copy/${id}`, method: 'post' })
export const getNextDate = (p) => request({ url: '/safety/inspection/plan/next-date', method: 'get', params: p })
export const getPlanStatistics = () => request({ url: '/safety/inspection/plan/statistics', method: 'get' })
