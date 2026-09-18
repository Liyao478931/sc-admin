/**
 * 文件：admin/src/api/aiWorkflow.js
 * AI 工作流 API（路由前缀 /ai/workflow）
 */
import request from './request'

/** 工作流列表（分页 + 多维度筛选） */
export const getWorkflowList = (p) => request({ url: '/ai/workflow/list', method: 'get', params: p })

/** 工作流详情 */
export const getWorkflowDetail = (id) => request({ url: '/ai/workflow/detail/' + id, method: 'get' })

/** 创建工作流 */
export const addWorkflow = (d) => request({ url: '/ai/workflow/add', method: 'post', data: d })

/** 编辑工作流 */
export const editWorkflow = (id, d) => request({ url: '/ai/workflow/edit/' + id, method: 'put', data: d })

/** 删除工作流（软删除） */
export const deleteWorkflow = (id) => request({ url: '/ai/workflow/delete/' + id, method: 'delete' })

/** 切换启用/停用状态 */
export const updateWorkflowStatus = (id, status) => request({ url: '/ai/workflow/status/' + id, method: 'put', data: { status } })

/** 复制工作流 */
export const copyWorkflow = (id) => request({ url: '/ai/workflow/copy/' + id, method: 'post' })

/** 手动触发工作流 */
export const triggerWorkflow = (id) => request({ url: '/ai/workflow/trigger/' + id, method: 'post' })

/** 工作流统计 */
export const getWorkflowStatistics = () => request({ url: '/ai/workflow/statistics', method: 'get' })

/** 工作流下拉选项（启用状态） */
export const getWorkflowOptions = () => request({ url: '/ai/workflow/options', method: 'get' })

/** 验证工作流配置 */
export const validateWorkflow = (config) => request({ url: '/ai/workflow/validate', method: 'post', data: { config } })

/** 运行日志列表 */
export const getWorkflowLogList = (p) => request({ url: '/ai/workflow/logs/list', method: 'get', params: p })

/** 运行日志详情 */
export const getWorkflowLogDetail = (id) => request({ url: '/ai/workflow/logs/detail/' + id, method: 'get' })

/** 日志统计 */
export const getWorkflowLogStatistics = (p) => request({ url: '/ai/workflow/logs/statistics', method: 'get', params: p })

/** 运行趋势 */
export const getWorkflowLogTrend = (p) => request({ url: '/ai/workflow/logs/trend', method: 'get', params: p })

/** 状态分布 */
export const getWorkflowLogStatusDist = (p) => request({ url: '/ai/workflow/logs/status-distribution', method: 'get', params: p })

/** 工作流运行排行 */
export const getWorkflowLogRanking = (p) => request({ url: '/ai/workflow/logs/workflow-ranking', method: 'get', params: p })

/** 导出日志（xlsx→CSV / json） */
export const exportWorkflowLogs = (p) => request({ url: '/ai/workflow/logs/export', method: 'get', params: p, responseType: 'blob' })

/** 删除单条日志 */
export const deleteWorkflowLog = (id) => request({ url: '/ai/workflow/logs/delete/' + id, method: 'delete' })

/** 批量删除日志（ids 或时间范围） */
export const batchDeleteWorkflowLogs = (data) => request({ url: '/ai/workflow/logs/batch-delete', method: 'delete', data })
