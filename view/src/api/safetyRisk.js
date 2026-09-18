import request from './request'

// ===== 风险辨识 =====
export const getRiskList = (p) => request({ url: '/safety/risk/identify/list', method: 'get', params: p })
export const getRiskDetail = (id) => request({ url: `/safety/risk/identify/detail/${id}`, method: 'get' })
export const getRiskStatistics = () => request({ url: '/safety/risk/identify/statistics', method: 'get' })
export const addRisk = (d) => request({ url: '/safety/risk/identify/add', method: 'post', data: d })
export const editRisk = (id, d) => request({ url: `/safety/risk/identify/edit/${id}`, method: 'put', data: d })
export const deleteRisk = (id) => request({ url: `/safety/risk/identify/delete/${id}`, method: 'delete' })
export const changeRiskStatus = (id, status) => request({ url: `/safety/risk/identify/status/${id}`, method: 'put', data: { status } })
export const exportRisk = (p) => request({ url: '/safety/risk/identify/export', method: 'get', params: p })
// 责任人候选人（从员工档案搜索，value=user_id）
export { getResponsibleCandidates } from './safetyAccident'

// ===== 风险评估（LEC法） =====
export const getAssessList = (p) => request({ url: '/safety/risk/assess/list', method: 'get', params: p })
export const getAssessDetail = (id) => request({ url: `/safety/risk/assess/detail/${id}`, method: 'get' })
export const getAssessHistory = (id) => request({ url: `/safety/risk/assess/history/${id}`, method: 'get' })
export const submitRiskAssessment = (d) => request({ url: '/safety/risk/assess/submit', method: 'post', data: d })
export const getAssessStatistics = () => request({ url: '/safety/risk/assess/statistics', method: 'get' })
export const exportAssess = (p) => request({ url: '/safety/risk/assess/export', method: 'get', params: p })

// ===== 管控措施 =====
export const getControlList = (p) => request({ url: '/safety/risk/control/list', method: 'get', params: p })
export const getControlDetail = (id) => request({ url: `/safety/risk/control/detail/${id}`, method: 'get' })
export const getAvailableRisks = () => request({ url: '/safety/risk/control/available-risks', method: 'get' })
export const addControl = (d) => request({ url: '/safety/risk/control/add', method: 'post', data: d })
export const editControl = (id, d) => request({ url: `/safety/risk/control/edit/${id}`, method: 'put', data: d })
export const deleteControl = (id) => request({ url: `/safety/risk/control/delete/${id}`, method: 'delete' })
export const startControl = (id) => request({ url: `/safety/risk/control/start/${id}`, method: 'put' })
export const completeControl = (id) => request({ url: `/safety/risk/control/complete/${id}`, method: 'put' })
export const invalidateControl = (id, reason) => request({ url: `/safety/risk/control/invalidate/${id}`, method: 'put', data: { invalid_reason: reason } })
export const verifyControl = (id, status, opinion) => request({ url: `/safety/risk/control/verify/${id}`, method: 'put', data: { verify_status: status, verify_opinion: opinion } })
export const getControlStatistics = () => request({ url: '/safety/risk/control/statistics', method: 'get' })
export const exportControl = (p) => request({ url: '/safety/risk/control/export', method: 'get', params: p })
