/**
 * 考核模板管理 API（人事管理 -> 绩效考核 -> 考核模板管理）
 */
import request from './request'

// ===== 模板管理 =====
export function getTemplateList(params) { return request({ url: '/assessment/templates', method: 'get', params }) }
export function getTemplateDetail(id) { return request({ url: `/assessment/templates/${id}`, method: 'get' }) }
export function createTemplate(data) { return request({ url: '/assessment/templates', method: 'post', data }) }
export function updateTemplate(id, data) { return request({ url: `/assessment/templates/${id}`, method: 'put', data }) }
export function deleteTemplate(id) { return request({ url: `/assessment/templates/${id}`, method: 'delete' }) }
export function toggleTemplateStatus(id) { return request({ url: `/assessment/templates/${id}/toggle-status`, method: 'post' }) }
export function duplicateTemplate(id) { return request({ url: `/assessment/templates/${id}/duplicate`, method: 'post' }) }
export function getNextTemplateCode(category) { return request({ url: '/assessment/templates/next-code', method: 'get', params: { category } }) }
export function checkTemplateCode(params) { return request({ url: '/assessment/templates/check-code', method: 'get', params }) }
export function checkTemplateScore(id) { return request({ url: `/assessment/templates/${id}/check-score`, method: 'post' }) }

// ===== 指标管理 =====
export function getIndicatorTree(id) { return request({ url: `/assessment/templates/${id}/indicators`, method: 'get' }) }
export function addIndicator(id, data) { return request({ url: `/assessment/templates/${id}/indicators`, method: 'post', data }) }
export function batchAddIndicators(id, data) { return request({ url: `/assessment/templates/${id}/indicators/batch`, method: 'post', data }) }
export function updateIndicator(templateId, indicatorId, data) { return request({ url: `/assessment/templates/${templateId}/indicators/${indicatorId}`, method: 'put', data }) }
export function deleteIndicator(templateId, indicatorId) { return request({ url: `/assessment/templates/${templateId}/indicators/${indicatorId}`, method: 'delete' }) }
export function sortIndicators(id, ids) { return request({ url: `/assessment/templates/${id}/indicators/sort`, method: 'put', data: { ids } }) }
export function toggleIndicatorStatus(templateId, indicatorId) { return request({ url: `/assessment/templates/${templateId}/indicators/${indicatorId}/toggle-status`, method: 'post' }) }

// ===== 指标库管理 =====
export function getLibraryList(params) { return request({ url: '/assessment/indicator-library', method: 'get', params }) }
export function createLibrary(data) { return request({ url: '/assessment/indicator-library', method: 'post', data }) }
export function updateLibrary(id, data) { return request({ url: `/assessment/indicator-library/${id}`, method: 'put', data }) }
export function deleteLibrary(id) { return request({ url: `/assessment/indicator-library/${id}`, method: 'delete' }) }

// ===== 导出 =====
export function exportTemplatePreview(id) { return request({ url: `/assessment/templates/${id}/export-preview`, method: 'get', responseType: 'blob' }) }

// ===== 考核任务管理 =====
export function getTaskList(params) { return request({ url: '/assessment/tasks', method: 'get', params }) }
export function getTaskDetail(id) { return request({ url: `/assessment/tasks/${id}`, method: 'get' }) }
export function generateTasks(data) { return request({ url: '/assessment/tasks/generate', method: 'post', data }) }
export function runAutoDeduct(data) { return request({ url: '/assessment/tasks/auto-deduct', method: 'post', data }) }
export function manualDeduct(data) { return request({ url: '/assessment/tasks/deduction', method: 'post', data }) }
export function confirmDeduction(ids) { return request({ url: '/assessment/tasks/deduction/confirm', method: 'post', data: { deduction_ids: ids } }) }
export function confirmTask(id) { return request({ url: `/assessment/tasks/${id}/confirm`, method: 'post' }) }
export function approveTask(id, data) { return request({ url: `/assessment/tasks/${id}/approve`, method: 'post', data }) }
export function batchConfirmTasks(ids) { return request({ url: '/assessment/tasks/batch-confirm', method: 'post', data: { task_ids: ids } }) }

// ===== 申诉 =====
export function createAppeal(data) { return request({ url: '/assessment/appeals', method: 'post', data }) }
export function getAppealList(params) { return request({ url: '/assessment/appeals/list', method: 'get', params }) }
export function getMyAppealList(params) { return request({ url: '/assessment/appeals/my-list', method: 'get', params }) }
export function getAvailableDeductions(params) { return request({ url: '/assessment/appeals/available-deductions', method: 'get', params }) }
export function getAppealDetail(id) { return request({ url: `/assessment/appeals/${id}`, method: 'get' }) }
export function handleAppeal(id, data) { return request({ url: `/assessment/appeals/${id}/handle`, method: 'post', data }) }
export function getAppealStatistics(params) { return request({ url: '/assessment/appeals/statistics', method: 'get', params }) }
export function exportAppealRecords(params) { return request({ url: '/assessment/appeals/export', method: 'get', params, responseType: 'blob' }) }

// ===== 看板 =====
export function getDashboardFilters() { return request({ url: '/assessment/dashboard/filters', method: 'get' }) }
export function getDashboardOverview(params) { return request({ url: '/assessment/dashboard/overview', method: 'get', params }) }
export function getDeptRanking(params) { return request({ url: '/assessment/dashboard/dept-ranking', method: 'get', params }) }
export function getDeductionAnalysis(params) { return request({ url: '/assessment/dashboard/deduction-analysis', method: 'get', params }) }
export function getAssessmentTrend(params) { return request({ url: '/assessment/dashboard/trend', method: 'get', params }) }
export function getAssessmentWarning(params) { return request({ url: '/assessment/dashboard/warning', method: 'get', params }) }

// ===== 导出报表 =====
export function exportAssessmentReport(params) { return request({ url: '/assessment/export', method: 'get', params, responseType: 'blob' }) }

// ===== 移动端 =====
export function getMyAssessmentOverview(params) { return request({ url: '/assessment/mobile/my-overview', method: 'get', params }) }
export function getMyAssessmentDeductions(params) { return request({ url: '/assessment/mobile/my-deductions', method: 'get', params }) }
export function mobileQuickDeduct(data) { return request({ url: '/assessment/mobile/quick-deduct', method: 'post', data }) }
