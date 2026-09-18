/**
 * AI 工具审批 API
 */
import request from './request'

// ===== 审批管理 =====
export function submitToolApproval(data) { return request({ url: '/ai/tools/approval/submit', method: 'post', data }) }
export function getToolApprovals(params) { return request({ url: '/ai/tools/approval/list', method: 'get', params }) }
export function getToolApprovalDetail(id) { return request({ url: `/ai/tools/approval/detail/${id}`, method: 'get' }) }
export function processToolApproval(id, data) { return request({ url: `/ai/tools/approval/process/${id}`, method: 'put', data }) }
export function batchProcessToolApproval(data) { return request({ url: '/ai/tools/approval/batch-process', method: 'post', data }) }
export function cancelToolApproval(id) { return request({ url: `/ai/tools/approval/cancel/${id}`, method: 'put' }) }
export function getToolApprovalStatistics() { return request({ url: '/ai/tools/approval/statistics', method: 'get' }) }

// ===== 审批规则配置 =====
export function getApprovalConfig() { return request({ url: '/ai/tools/approval/config', method: 'get' }) }
export function saveApprovalConfig(data) { return request({ url: '/ai/tools/approval/config', method: 'put', data: { config: data } }) }
