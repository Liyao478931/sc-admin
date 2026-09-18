/**
 * AI 智能体发布 API
 */
import request from './request'

// ===== 版本管理 =====
export function getPublishVersions(params) { return request({ url: '/ai/agent/publish/versions', method: 'get', params }) }
export function getPublishVersionDetail(id) { return request({ url: `/ai/agent/publish/version/detail/${id}`, method: 'get' }) }
export function createPublishVersion(data) { return request({ url: '/ai/agent/publish/version/create', method: 'post', data }) }
export function editPublishVersion(id, data) { return request({ url: `/ai/agent/publish/version/edit/${id}`, method: 'put', data }) }
export function deletePublishVersion(id) { return request({ url: `/ai/agent/publish/version/delete/${id}`, method: 'delete' }) }
export function comparePublishVersions(params) { return request({ url: '/ai/agent/publish/version/compare', method: 'get', params }) }
export function rollbackPublishVersion(id) { return request({ url: `/ai/agent/publish/version/rollback/${id}`, method: 'post' }) }

// ===== 发布审批 =====
export function submitPublish(data) { return request({ url: '/ai/agent/publish/submit', method: 'post', data }) }
export function getPublishApprovals(params) { return request({ url: '/ai/agent/publish/approvals', method: 'get', params }) }
export function approvePublish(id, data) { return request({ url: `/ai/agent/publish/approve/${id}`, method: 'put', data }) }
export function rejectPublish(id, data) { return request({ url: `/ai/agent/publish/reject/${id}`, method: 'put', data }) }
export function cancelPublish(id) { return request({ url: `/ai/agent/publish/cancel/${id}`, method: 'put' }) }

// ===== 发布执行 =====
export function executePublish(id, data) { return request({ url: `/ai/agent/publish/execute/${id}`, method: 'post', data }) }
export function offlinePublish(id) { return request({ url: `/ai/agent/publish/offline/${id}`, method: 'post' }) }
export function promotePublish(id) { return request({ url: `/ai/agent/publish/promote/${id}`, method: 'post' }) }

// ===== 渠道管理 =====
export function getPublishChannels(params) { return request({ url: '/ai/agent/publish/channels', method: 'get', params }) }
export function configPublishChannel(data) { return request({ url: '/ai/agent/publish/channel/config', method: 'post', data }) }
export function testPublishChannel(data) { return request({ url: '/ai/agent/publish/channel/test', method: 'post', data }) }
export function updateChannelStatus(id, data) { return request({ url: `/ai/agent/publish/channel/status/${id}`, method: 'put', data }) }

// ===== 发布统计 =====
export function getPublishStatistics(params) { return request({ url: '/ai/agent/publish/statistics', method: 'get', params }) }
