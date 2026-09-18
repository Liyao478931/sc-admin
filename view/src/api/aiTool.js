/**
 * AI 工具列表 API
 * 路由前缀：/ai/tools
 */
import request from './request'

/** 工具列表（多维度筛选） */
export const getAiToolList = (params) => request({ url: '/ai/tools/list', method: 'get', params })
/** 已启用工具下拉（智能体表单用） */
export const getAiToolOptions = () => request({ url: '/ai/tools/options', method: 'get' })
/** 工具详情 */
export const getAiToolDetail = (id) => request({ url: `/ai/tools/detail/${id}`, method: 'get' })
/** 工具统计 */
export const getAiToolStatistics = () => request({ url: '/ai/tools/statistics', method: 'get' })
/** 切换状态 */
export const toggleAiToolStatus = (id, status) => request({ url: `/ai/tools/status/${id}`, method: 'put', data: { status } })
/** 批量切换状态 */
export const batchToggleAiToolStatus = (ids, status) => request({ url: '/ai/tools/batch-status', method: 'put', data: { ids, status } })
/** 测试工具 */
export const testAiTool = (toolId, testParams) => request({ url: '/ai/tools/test', method: 'post', data: { tool_id: toolId, test_params: testParams } })

// ---- 新增工具 ----
/** 检查工具名称唯一性 */
export const checkAiToolName = (toolName) => request({ url: '/ai/tools/check-name', method: 'get', params: { tool_name: toolName } })
/** 新增工具 */
export const addAiTool = (data) => request({ url: '/ai/tools/add', method: 'post', data })

// ---- 工具测试 ----
/** 执行工具测试 */
export const runToolTest = (toolId, params) => request({ url: '/ai/tools/test', method: 'post', data: { tool_id: toolId, params } })
/** 获取测试历史 */
export const getToolTestHistory = (toolId, page, limit) => request({ url: '/ai/tools/test-history', method: 'get', params: { tool_id: toolId, page, limit } })
/** 获取单条测试详情 */
export const getToolTestDetail = (logId) => request({ url: '/ai/tools/test-history/detail', method: 'get', params: { log_id: logId } })
/** 清空测试历史 */
export const clearToolTestHistory = (toolId) => request({ url: '/ai/tools/test-history/clear', method: 'delete', data: { tool_id: toolId } })
