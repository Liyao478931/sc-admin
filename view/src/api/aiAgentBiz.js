/**
 * AI 业务智能体 API（v1.67.0）
 * 路由前缀：/ai/agents
 */
import request from './request'

/** 智能体总览 */
export const getAgentDashboard = () => request({ url: '/ai/agents/dashboard', method: 'get' })

/** 执行记录 */
export const getAgentExecutions = (params) => request({ url: '/ai/agents/executions', method: 'get', params })

/** 审批待办列表 */
export const getApprovalTodos = (params) => request({ url: '/ai/agents/approval/todos', method: 'get', params })

/** 审批建议 */
export const getApprovalRecommend = (id) => request({ url: `/ai/agents/approval/recommend/${id}`, method: 'get' })

/** 执行审批 */
export const executeApproval = (data) => request({ url: '/ai/agents/approval/execute', method: 'post', data })

/** 批量审批建议 */
export const getApprovalBatchSuggest = (params) => request({ url: '/ai/agents/approval/batch-suggest', method: 'get', params })

/** 批量审批执行 */
export const batchExecuteApproval = (data) => request({ url: '/ai/agents/approval/batch-execute', method: 'post', data })

/** 催办任务列表 */
export const getChurnTasks = (params) => request({ url: '/ai/agents/churn/tasks', method: 'get', params })

/** 执行催办 */
export const executeChurn = (data) => request({ url: '/ai/agents/churn/execute', method: 'post', data })

/** 催办规则 */
export const getChurnRules = () => request({ url: '/ai/agents/churn/rules', method: 'get' })
export const saveChurnRules = (rules) => request({ url: '/ai/agents/churn/rules', method: 'put', data: { rules } })

/** 订单处理任务 */
export const getOrderTasks = (params) => request({ url: '/ai/agents/order/tasks', method: 'get', params })

/** 订单处理详情 */
export const getOrderDetail = (id) => request({ url: `/ai/agents/order/detail/${id}`, method: 'get' })

/** 人工介入处理订单 */
export const manualOrder = (id, action) => request({ url: `/ai/agents/order/manual/${id}`, method: 'post', data: { action } })

/** 订单处理规则 */
export const getOrderRules = () => request({ url: '/ai/agents/order/rules', method: 'get' })
export const saveOrderRules = (rules) => request({ url: '/ai/agents/order/rules', method: 'put', data: { rules } })
