/**
 * 招聘管理 API（人事管理 -> 招聘管理）
 */
import request from './request'

// 招聘需求
export function getRequirementList(params) { return request({ url: '/hr/recruit/requirement/list', method: 'get', params }) }
export function getRequirementDetail(id) { return request({ url: `/hr/recruit/requirement/detail/${id}`, method: 'get' }) }
export function saveRequirement(data) { return request({ url: '/hr/recruit/requirement/save', method: 'post', data }) }
export function deleteRequirement(id) { return request({ url: `/hr/recruit/requirement/delete/${id}`, method: 'delete' }) }
export function submitRequirement(id) { return request({ url: `/hr/recruit/requirement/submit/${id}`, method: 'post' }) }
export function revokeRequirement(id) { return request({ url: `/hr/recruit/requirement/revoke/${id}`, method: 'post' }) }
export function closeRequirement(id) { return request({ url: `/hr/recruit/requirement/close/${id}`, method: 'post' }) }
export function exportRequirement(params) { return request({ url: '/hr/recruit/requirement/export', method: 'get', params, responseType: 'blob' }) }

// 招聘职位
export function getPositionList(params) { return request({ url: '/hr/recruit/position/list', method: 'get', params }) }
export function getPositionDetail(id) { return request({ url: `/hr/recruit/position/detail/${id}`, method: 'get' }) }
export function savePosition(data) { return request({ url: '/hr/recruit/position/save', method: 'post', data }) }
export function deletePosition(id) { return request({ url: `/hr/recruit/position/delete/${id}`, method: 'delete' }) }
export function publishPosition(id) { return request({ url: `/hr/recruit/position/publish/${id}`, method: 'post' }) }
export function offlinePosition(id) { return request({ url: `/hr/recruit/position/offline/${id}`, method: 'post' }) }
export function closePosition(id) { return request({ url: `/hr/recruit/position/close/${id}`, method: 'post' }) }
export function exportPosition(params) { return request({ url: '/hr/recruit/position/export', method: 'get', params, responseType: 'blob' }) }

// 简历管理
export function getResumeList(params) { return request({ url: '/hr/recruit/resume/list', method: 'get', params }) }
export function getResumeDetail(id) { return request({ url: `/hr/recruit/resume/detail/${id}`, method: 'get' }) }
export function saveResume(data) { return request({ url: '/hr/recruit/resume/save', method: 'post', data }) }
export function deleteResume(id) { return request({ url: `/hr/recruit/resume/delete/${id}`, method: 'delete' }) }
export function screenResume(id, screeningRemark) { return request({ url: `/hr/recruit/resume/screen/${id}`, method: 'post', data: { screening_remark: screeningRemark || '' } }) }
export function eliminateResume(id) { return request({ url: `/hr/recruit/resume/eliminate/${id}`, method: 'post' }) }
export function importResume(formData) { return request({ url: '/hr/recruit/resume/import', method: 'post', data: formData }) }
export function exportResume(params) { return request({ url: '/hr/recruit/resume/export', method: 'get', params, responseType: 'blob' }) }

// 面试
export function scheduleInterview(data) { return request({ url: '/hr/recruit/interview/schedule', method: 'post', data }) }
export function evaluateInterview(id, data) { return request({ url: `/hr/recruit/interview/evaluate/${id}`, method: 'post', data }) }
export function cancelInterview(id) { return request({ url: `/hr/recruit/interview/cancel/${id}`, method: 'post' }) }

// 录用管理
export function getOfferList(params) { return request({ url: '/hr/recruit/offer/list', method: 'get', params }) }
export function getOfferDetail(id) { return request({ url: `/hr/recruit/offer/detail/${id}`, method: 'get' }) }
export function saveOffer(data) { return request({ url: '/hr/recruit/offer/save', method: 'post', data }) }
export function deleteOffer(id) { return request({ url: `/hr/recruit/offer/delete/${id}`, method: 'delete' }) }
export function submitOffer(id) { return request({ url: `/hr/recruit/offer/submit/${id}`, method: 'post' }) }
export function revokeOffer(id) { return request({ url: `/hr/recruit/offer/revoke/${id}`, method: 'post' }) }
export function sendOfferNotice(id, channels) { return request({ url: `/hr/recruit/offer/send-notice/${id}`, method: 'post', data: { channels: channels || ['inbox'] } }) }
export function createEmployeeFromOffer(id) { return request({ url: `/hr/recruit/offer/create-employee/${id}`, method: 'post' }) }
export function exportOffer(params) { return request({ url: '/hr/recruit/offer/export', method: 'get', params, responseType: 'blob' }) }

// 统计 / 选项 / 上传
export function getRecruitStatistics() { return request({ url: '/hr/recruit/statistics', method: 'get' }) }
export function getRecruitOptions() { return request({ url: '/hr/recruit/options', method: 'get' }) }
export function uploadRecruitFile(formData) { return request({ url: '/hr/recruit/upload', method: 'post', data: formData }) }

// 招聘投递 H5（公开，无需登录）
export function getPublicPositionList() { return request({ url: '/hr/recruit/position/public-list', method: 'get' }) }
export function submitPublicResume(data) { return request({ url: '/hr/recruit/resume/public-submit', method: 'post', data }) }
export function uploadPublicResumeFile(formData) { return request({ url: '/hr/recruit/resume/public-upload', method: 'post', data: formData }) }
