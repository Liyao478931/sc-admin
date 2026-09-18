/**
 * AI 对话 API
 * 路由前缀：/ai/chat
 */
import request from './request'
import { getToken } from '@/utils/auth'

/** 创建新会话（可选指定智能体） */
export const createAiSession = (agentId) => request({ url: '/ai/chat/create', method: 'post', data: { agent_id: agentId || undefined } })

/** 会话详情（含关联智能体与会话工具，供加载历史会话恢复） */
export const getAiChatSessionDetail = (sessionId) => request({ url: '/ai/chat/detail', method: 'get', params: { session_id: sessionId } })

/** 发送消息（非流式封装；流式用 fetch 单独处理） */
export const sendAiMessage = (data) => request({ url: '/ai/chat/send', method: 'post', data })

/** 会话历史 */
export const getAiHistory = (params) => request({ url: '/ai/chat/history', method: 'get', params })

/** 会话消息（传 session_id 字符串） */
export const getAiMessages = (sessionId) => request({ url: '/ai/chat/messages', method: 'get', params: { session_id: sessionId } })

/** 删除会话 */
export const deleteAiSession = (sessionId) => request({ url: '/ai/chat/delete', method: 'delete', data: { session_id: sessionId } })

/** 重命名会话 */
export const renameAiSession = (sessionId, title) => request({ url: '/ai/chat/rename', method: 'put', data: { session_id: sessionId, title } })

/** 确认/拒绝写操作工具 */
export const confirmAiTool = (sessionId, decision) => request({ url: '/ai/chat/tool-confirm', method: 'post', data: { session_id: sessionId, decision } })

/** 确认/取消工具调用（confirmed=true/false） */
export const confirmToolCall = (sessionId, confirmed) => request({ url: '/ai/chat/confirm-tool', method: 'post', data: { session_id: sessionId, confirmed } })

/** 重试失败的工具调用 */
export const retryAiTool = (sessionId, messageId) => request({ url: '/ai/chat/retry-tool', method: 'post', data: { session_id: sessionId, message_id: messageId } })

/** 获取会话可用工具及统计 */
export const getAiSessionTools = (sessionId) => request({ url: '/ai/chat/session-tools', method: 'get', params: { session_id: sessionId } })

/** 切换会话工具启用状态 */
export const toggleAiSessionTool = (sessionId, toolId, enabled) => request({ url: '/ai/chat/session-tools/toggle', method: 'put', data: { session_id: sessionId, tool_id: toolId, enabled } })

// ---- 对话历史（AiChatHistoryController） ----
/** 会话列表（多维度筛选） */
export const getAiHistoryList = (params) => request({ url: '/ai/chat/history/list', method: 'get', params })
/** 会话详情 */
export const getAiHistoryDetail = (sessionId) => request({ url: '/ai/chat/history/detail', method: 'get', params: { session_id: sessionId } })
/** 重命名（history 版，2-50字符） */
export const renameAiHistory = (sessionId, title) => request({ url: '/ai/chat/history/rename', method: 'put', data: { session_id: sessionId, title } })
/** 删除（history 版） */
export const deleteAiHistory = (sessionId) => request({ url: '/ai/chat/history/delete', method: 'delete', data: { session_id: sessionId } })
/** 批量删除 */
export const batchDeleteAiHistory = (sessionIds) => request({ url: '/ai/chat/history/batch-delete', method: 'delete', data: { session_ids: sessionIds } })
/** 归档 */
export const archiveAiHistory = (sessionId) => request({ url: '/ai/chat/history/archive', method: 'put', data: { session_id: sessionId } })
/** 恢复 */
export const restoreAiHistory = (sessionId) => request({ url: '/ai/chat/history/restore', method: 'put', data: { session_id: sessionId } })
/** 统计 */
export const getAiHistoryStatistics = () => request({ url: '/ai/chat/history/statistics', method: 'get' })
/** 导出单会话（带 token 下载） */
export async function exportAiHistory (sessionId, format = 'md') {
  const token = getToken() || ''
  const resp = await fetch(`/api/ai/chat/history/export?session_id=${sessionId}&format=${format}`, {
    headers: { 'Authorization': 'Bearer ' + token }
  })
  if (!resp.ok) throw new Error('导出失败')
  return resp.blob()
}
/** 批量导出（带 token，返回 blob） */
export async function batchExportAiHistory (sessionIds) {
  const token = getToken() || ''
  const resp = await fetch('/api/ai/chat/history/batch-export', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
    body: JSON.stringify({ session_ids: sessionIds })
  })
  if (!resp.ok) throw new Error('导出失败')
  return resp.blob()
}

// ---- AI 助手上下文感知（v1.63.0） ----
/** 执行快捷操作（客户分析/产品分析/趋势分析/导出/报告） */
export const executeQuickAction = (data) => request({ url: '/ai/actions/execute', method: 'post', data })

/** 提交消息反馈（like/dislike + 可选原因） */
export const submitMessageFeedback = (data) => request({ url: '/ai/chat/feedback', method: 'post', data })

/** 重新生成回复（SSE 流式，由组件 fetch 消费） */
export async function streamRegenerate (messageId, onEvent) {
  const token = getToken() || ''
  const resp = await fetch('/api/ai/chat/regenerate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
    body: JSON.stringify({ message_id: messageId })
  })
  if (!resp.ok) throw new Error('重新生成失败')
  const reader = resp.body.getReader()
  const decoder = new TextDecoder()
  let buffer = ''
  while (true) {
    const { done, value } = await reader.read()
    if (done) break
    buffer += decoder.decode(value, { stream: true })
    const lines = buffer.split('\n')
    buffer = lines.pop()
    for (const line of lines) {
      const t = line.trim()
      if (!t.startsWith('data: ')) continue
      try { onEvent(JSON.parse(t.slice(6))) } catch (e) { /* 忽略非 JSON 行 */ }
    }
  }
}
