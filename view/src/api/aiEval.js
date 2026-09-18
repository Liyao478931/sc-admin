/**
 * AI 智能体评测 API
 */
import request from './request'

// ===== 在线调试 =====
export function evalChat(data) { return request({ url: '/ai/agent/evaluate/chat', method: 'post', data }) }

// ===== 测试用例 =====
export function getEvalCases(params) { return request({ url: '/ai/agent/evaluate/cases', method: 'get', params }) }
export function getEvalCaseDetail(id) { return request({ url: `/ai/agent/evaluate/case/detail/${id}`, method: 'get' }) }
export function addEvalCase(data) { return request({ url: '/ai/agent/evaluate/case/add', method: 'post', data }) }
export function editEvalCase(id, data) { return request({ url: `/ai/agent/evaluate/case/edit/${id}`, method: 'put', data }) }
export function deleteEvalCase(id) { return request({ url: `/ai/agent/evaluate/case/delete/${id}`, method: 'delete' }) }
export function importEvalCases(data) { return request({ url: '/ai/agent/evaluate/cases/import', method: 'post', data }) }
export function exportEvalCases() { return request({ url: '/ai/agent/evaluate/cases/export', method: 'get', responseType: 'blob' }) }

// ===== 评测任务 =====
export function createEvalTask(data) { return request({ url: '/ai/agent/evaluate/task/create', method: 'post', data }) }
export function runEvalTask(id, data) { return request({ url: `/ai/agent/evaluate/task/run/${id}`, method: 'post', data }) }
export function getEvalTasks(params) { return request({ url: '/ai/agent/evaluate/task/list', method: 'get', params }) }
export function getEvalTaskDetail(id) { return request({ url: `/ai/agent/evaluate/task/detail/${id}`, method: 'get' }) }
export function deleteEvalTask(id) { return request({ url: `/ai/agent/evaluate/task/delete/${id}`, method: 'delete' }) }
export function getEvalTaskProgress(id) { return request({ url: `/ai/agent/evaluate/task/progress/${id}`, method: 'get' }) }
export function exportEvalTask(id, format) { return request({ url: `/ai/agent/evaluate/task/export/${id}`, method: 'get', params: { format }, responseType: 'blob' }) }

// ===== 评测对比 =====
export function compareEvalTasks(params) { return request({ url: '/ai/agent/evaluate/task/compare', method: 'get', params }) }
