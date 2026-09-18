import request from './request'

// ===== 事故登记 =====
export const getAccidentList = (p) => request({ url: '/safety/accident/list', method: 'get', params: p })
export const getAccidentDetail = (id) => request({ url: `/safety/accident/detail/${id}`, method: 'get' })
export const getAccidentStatistics = () => request({ url: '/safety/accident/statistics', method: 'get' })
export const addAccident = (d) => request({ url: '/safety/accident/add', method: 'post', data: d })
export const editAccident = (id, d) => request({ url: `/safety/accident/edit/${id}`, method: 'put', data: d })
export const deleteAccident = (id) => request({ url: `/safety/accident/delete/${id}`, method: 'delete' })
export const changeAccidentStatus = (id, status, reason) => request({ url: `/safety/accident/status/${id}`, method: 'put', data: { status, reason } })
export const exportAccident = (p) => request({ url: '/safety/accident/export', method: 'get', params: p })

// 责任人候选人（从员工档案搜索）
export const getResponsibleCandidates = (keyword) => request({ url: '/profiles', method: 'get', params: { keyword, page: 1, limit: 10 } })

// ===== 事故调查 =====
export const getInvestigateList = (p) => request({ url: '/safety/accident/investigate/list', method: 'get', params: p })
export const getInvestigateDetail = (id) => request({ url: `/safety/accident/investigate/detail/${id}`, method: 'get' })
export const getInvestigateStatistics = () => request({ url: '/safety/accident/investigate/statistics', method: 'get' })
export const assignInvestigator = (d) => request({ url: '/safety/accident/investigate/assign', method: 'post', data: d })
export const startInvestigate = (id) => request({ url: `/safety/accident/investigate/start/${id}`, method: 'put' })
export const saveInvestigateDraft = (d) => request({ url: '/safety/accident/investigate/save-draft', method: 'post', data: d })
export const submitInvestigate = (id) => request({ url: `/safety/accident/investigate/submit/${id}`, method: 'put' })
export const approveInvestigate = (id) => request({ url: `/safety/accident/investigate/approve/${id}`, method: 'put' })
export const rejectInvestigate = (id, reason) => request({ url: `/safety/accident/investigate/reject/${id}`, method: 'put', data: { reject_reason: reason } })
export const exportInvestigate = (id) => request({ url: `/safety/accident/investigate/export/${id}`, method: 'get' })
export const uploadInvestigateAttachment = (formData) => request({ url: '/safety/accident/investigate/upload-attachment', method: 'post', data: formData })

// ===== 事故统计 =====
export const getAccidentOverview = (p) => request({ url: '/safety/accident/statistics/overview', method: 'get', params: p })
export const getAccidentTrend = (p) => request({ url: '/safety/accident/statistics/trend', method: 'get', params: p })
export const getTypeDistribution = () => request({ url: '/safety/accident/statistics/type-distribution', method: 'get' })
export const getLevelDistribution = () => request({ url: '/safety/accident/statistics/level-distribution', method: 'get' })
export const getDepartmentDistribution = () => request({ url: '/safety/accident/statistics/department-distribution', method: 'get' })
export const getTypeLevelCross = () => request({ url: '/safety/accident/statistics/type-level-cross', method: 'get' })
export const getCasualtyRanking = (limit) => request({ url: '/safety/accident/statistics/casualty-ranking', method: 'get', params: { limit } })
export const getEconomicRanking = (limit) => request({ url: '/safety/accident/statistics/economic-ranking', method: 'get', params: { limit } })
export const getAccidentDetailList = (p) => request({ url: '/safety/accident/statistics/detail-list', method: 'get', params: p })
export const exportAccidentStatistics = (p) => request({ url: '/safety/accident/statistics/export', method: 'get', params: p })
