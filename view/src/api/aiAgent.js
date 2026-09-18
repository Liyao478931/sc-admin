/**
 * AI 智能体 API
 * 路由前缀：/ai/agent
 */
import request from './request'

/** 智能体列表（分页 + 多维度筛选） */
export const getAiAgentList = (params) => request({ url: '/ai/agent/list', method: 'get', params })
/** 智能体详情 */
export const getAiAgentDetail = (id) => request({ url: `/ai/agent/detail/${id}`, method: 'get' })
/** 创建智能体 */
export const addAiAgent = (data) => request({ url: '/ai/agent/add', method: 'post', data })
/** 编辑智能体 */
export const editAiAgent = (id, data) => request({ url: `/ai/agent/edit/${id}`, method: 'put', data })
/** 删除智能体 */
export const deleteAiAgent = (id) => request({ url: `/ai/agent/delete/${id}`, method: 'delete' })
/** 切换智能体状态 */
export const toggleAiAgentStatus = (id, status) => request({ url: `/ai/agent/status/${id}`, method: 'put', data: { status } })
/** 复制智能体 */
export const copyAiAgent = (id) => request({ url: `/ai/agent/copy/${id}`, method: 'post' })
/** 智能体统计 */
export const getAiAgentStats = () => request({ url: '/ai/agent/statistics', method: 'get' })
/** 启用智能体下拉选项 */
export const getAiAgentOptions = () => request({ url: '/ai/agent/options', method: 'get' })
/** 智能体对话配置（人设/知识库/工具，对话页用） */
export const getAiAgentDetailForChat = (agentId) => request({ url: '/ai/agent/detail-for-chat', method: 'get', params: { agent_id: agentId } })
/** 智能体名称唯一性校验（编辑时传 id 排除自身） */
export const checkAiAgentName = (agentName, id) => request({ url: '/ai/agent/check-name', method: 'get', params: { agent_name: agentName, id: id || undefined } })
