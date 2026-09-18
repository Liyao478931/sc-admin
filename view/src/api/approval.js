/**
 * 统一审批管理 - 我的待办 API
 */
import request from './request'

// 待办列表（含统计卡 + 业务类型）
export function getMyTasks (params) { return request({ url: '/approval/my-tasks', method: 'get', params }) }
// 我发起的列表（含统计卡）
export function getMyInitiated (params) { return request({ url: '/approval/my-initiated', method: 'get', params }) }
// 审批历史列表（含统计卡）
export function getApprovalHistory (params) { return request({ url: '/approval/history', method: 'get', params }) }
// 导出审批历史（Excel）
export function exportApprovalHistory (params) { return request({ url: '/approval/history/export', method: 'get', params, responseType: 'blob' }) }
// 审批流程配置列表
export function getApprovalDefinitions (params) { return request({ url: '/approval/definitions', method: 'get', params }) }
// 保存审批流程配置（新增/编辑）
export function saveApprovalDefinition (data) { return request({ url: '/approval/definitions/save', method: 'post', data }) }
// 切换审批流程配置状态（启用/停用）
export function toggleApprovalDefinition (id) { return request({ url: `/approval/definitions/toggle/${id}`, method: 'post' }) }
// 可配置业务类型列表
export function getBusinessTypes () { return request({ url: '/approval/business-types', method: 'get' }) }
// 审批代理列表
export function getProxyList (params) { return request({ url: '/approval/proxy/list', method: 'get', params }) }
// 新增代理
export function saveProxy (data) { return request({ url: '/approval/proxy/save', method: 'post', data }) }
// 取消代理
export function cancelProxy (id) { return request({ url: `/approval/proxy/cancel/${id}`, method: 'post' }) }
// 当前代理状态
export function getCurrentProxyStatus () { return request({ url: '/approval/proxy/current-status', method: 'get' }) }
// 审批统计（KPI + 图表 + 明细）
export function getApprovalStatistics (params) { return request({ url: '/approval/statistics', method: 'get', params }) }
// 导出审批统计报表
export function exportApprovalStatistics (params) { return request({ url: '/approval/statistics/export', method: 'get', params, responseType: 'blob' }) }
// 保存常用语（新增/编辑）
export function saveCommonPhrase (data) { return request({ url: '/approval/common-phrases/save', method: 'post', data }) }
// 删除常用语
export function deleteCommonPhrase (id) { return request({ url: `/approval/common-phrases/delete/${id}`, method: 'delete' }) }
// 增加常用语使用次数
export function incrementPhraseUsage (id) { return request({ url: `/approval/common-phrases/increment/${id}`, method: 'post' }) }
// 撤销申请
export function revokeApproval (id, data) { return request({ url: `/approval/revoke/${id}`, method: 'post', data }) }
// 审批详情（实例 + 节点 + 历史 + 业务摘要）
export function getApprovalDetail (id) { return request({ url: `/approval/detail/${id}`, method: 'get' }) }
// 审批通过
export function approveTask (id, data) { return request({ url: `/approval/approve/${id}`, method: 'post', data }) }
// 审批驳回
export function rejectTask (id, data) { return request({ url: `/approval/reject/${id}`, method: 'post', data }) }
// 转办
export function transferTask (id, data) { return request({ url: `/approval/transfer/${id}`, method: 'post', data }) }
// 催办
export function urgeTask (id) { return request({ url: `/approval/urge/${id}`, method: 'post' }) }
// 催办检查（24 小时限制）
export function urgeCheckTask (id) { return request({ url: `/approval/urge/check/${id}`, method: 'get' }) }
// 批量审批
export function batchApproveTasks (data) { return request({ url: '/approval/batch-approve', method: 'post', data }) }
// 通知配置
export function getNotifyConfig () { return request({ url: '/approval/notification/config', method: 'get' }) }
export function saveNotifyConfig (data) { return request({ url: '/approval/notification/config/save', method: 'post', data }) }
// 常用语
export function getCommonPhrases () { return request({ url: '/approval/common-phrases', method: 'get' }) }
// 用户列表（转办人选人）
export function getUserOptions (params) { return request({ url: '/users', method: 'get', params }) }
// 审批节点"指定用户"下拉（仅需审批配置权限）
export function getApprovalUserOptions () { return request({ url: '/approval/user-options', method: 'get' }) }
// 角色下拉（审批节点"指定角色"）
export function getRoleOptions () { return request({ url: '/admin/roles/options', method: 'get' }) }
