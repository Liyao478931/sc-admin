/**
 * 安全培训 API 封装
 * 讲师/课件：/safety/training/*；计划：/safety/training/plan/*
 */
import request from './request'

// ===== 培训类型 =====
export const getTypeList = (p) => request({ url: '/safety/training/plan/type/list', method: 'get', params: p })
export const getTypeOptions = () => request({ url: '/safety/training/plan/type/options', method: 'get' })
export const addType = (d) => request({ url: '/safety/training/plan/type/add', method: 'post', data: d })
export const editType = (id, d) => request({ url: `/safety/training/plan/type/edit/${id}`, method: 'put', data: d })
export const deleteType = (id) => request({ url: `/safety/training/plan/type/delete/${id}`, method: 'delete' })

// ===== 培训讲师 =====
export const getTeacherList = (p) => request({ url: '/safety/training/teacher/list', method: 'get', params: p })
export const getTeacherOptions = () => request({ url: '/safety/training/teacher/options', method: 'get' })
export const getTeacherDetail = (id) => request({ url: `/safety/training/teacher/detail/${id}`, method: 'get' })
export const addTeacher = (d) => request({ url: '/safety/training/teacher/add', method: 'post', data: d })
export const editTeacher = (id, d) => request({ url: `/safety/training/teacher/edit/${id}`, method: 'put', data: d })
export const deleteTeacher = (id) => request({ url: `/safety/training/teacher/delete/${id}`, method: 'delete' })

// ===== 培训课件 =====
export const getCoursewareList = (p) => request({ url: '/safety/training/courseware/list', method: 'get', params: p })
export const getCoursewareOptions = () => request({ url: '/safety/training/courseware/options', method: 'get' })
export const getCoursewareDetail = (id) => request({ url: `/safety/training/courseware/detail/${id}`, method: 'get' })
export const uploadCourseware = (d) => request({ url: '/safety/training/courseware/upload', method: 'post', data: d })
export const previewCourseware = (id) => request({ url: `/safety/training/courseware/preview/${id}`, method: 'get' })
export const downloadCourseware = (id) => request({ url: `/safety/training/courseware/download/${id}`, method: 'get', responseType: 'blob' })
export const deleteCourseware = (id) => request({ url: `/safety/training/courseware/delete/${id}`, method: 'delete' })

// ===== 培训计划 =====
export const getPlanList = (p) => request({ url: '/safety/training/plan/list', method: 'get', params: p })
export const getPlanDetail = (id) => request({ url: `/safety/training/plan/detail/${id}`, method: 'get' })
export const addPlan = (d) => request({ url: '/safety/training/plan/add', method: 'post', data: d })
export const editPlan = (id, d) => request({ url: `/safety/training/plan/edit/${id}`, method: 'put', data: d })
export const deletePlan = (id) => request({ url: `/safety/training/plan/delete/${id}`, method: 'delete' })
export const copyPlan = (id) => request({ url: `/safety/training/plan/copy/${id}`, method: 'post' })
export const executePlan = (id) => request({ url: `/safety/training/plan/execute/${id}`, method: 'put' })
export const completePlan = (id) => request({ url: `/safety/training/plan/complete/${id}`, method: 'put' })
export const cancelPlan = (id, reason) => request({ url: `/safety/training/plan/cancel/${id}`, method: 'put', data: { cancel_reason: reason } })
export const getPlanStatistics = () => request({ url: '/safety/training/plan/statistics', method: 'get' })
export const getTargetUsers = (p) => request({ url: '/safety/training/plan/target-users', method: 'get', params: p })
