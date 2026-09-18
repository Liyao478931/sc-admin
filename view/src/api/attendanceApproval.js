/**
 * 考勤管理 - 审批记录 API
 * 路由前缀：/hr/attendance/approval
 */
import request from './request'

/** 审批记录列表 */
export const getApprovalList = (p) => request({ url: '/hr/attendance/approval/list', method: 'get', params: p })

/** 审批记录详情 */
export const getApprovalDetail = (id) => request({ url: '/hr/attendance/approval/detail/' + id, method: 'get' })

/** 审批记录统计 */
export const getApprovalStatistics = () => request({ url: '/hr/attendance/approval/statistics', method: 'get' })

/** 手动录入审批 */
export const addApproval = (d) => request({ url: '/hr/attendance/approval/add', method: 'post', data: d })

/** 编辑审批（仅手动） */
export const editApproval = (id, d) => request({ url: '/hr/attendance/approval/edit/' + id, method: 'put', data: d })

/** 删除审批（仅手动） */
export const deleteApproval = (id) => request({ url: '/hr/attendance/approval/delete/' + id, method: 'delete' })

/** 导出发批记录 */
export const exportApproval = (p) => request({ url: '/hr/attendance/approval/export', method: 'get', params: p })

/** 批量导入审批记录 */
export const importApproval = (formData) => request({ url: '/hr/attendance/approval/import', method: 'post', data: formData })

/** 下载导入模板 */
export const getApprovalTemplate = () => request({ url: '/hr/attendance/approval/template', method: 'get' })
