/**
 * AI 自然语言交互 API（v1.68.0）
 * 路由前缀：/ai/voice
 */
import request from './request'

/** 意图识别 */
export const recognizeVoice = (input) => request({ url: '/ai/voice/recognize', method: 'post', data: { input } })

/** 执行指令 */
export const executeVoice = (input) => request({ url: '/ai/voice/execute', method: 'post', data: { input } })

/** 指令模板列表 */
export const getVoiceTemplates = () => request({ url: '/ai/voice/templates', method: 'get' })

/** 新建模板 */
export const addVoiceTemplate = (data) => request({ url: '/ai/voice/templates', method: 'post', data })

/** 更新模板 */
export const updateVoiceTemplate = (id, data) => request({ url: `/ai/voice/templates/${id}`, method: 'put', data })

/** 删除模板 */
export const deleteVoiceTemplate = (id) => request({ url: `/ai/voice/templates/${id}`, method: 'delete' })

/** 模板测试 */
export const testVoiceTemplate = (input) => request({ url: '/ai/voice/templates/test', method: 'post', data: { input } })

/** 执行历史列表 */
export const getVoiceHistory = (params) => request({ url: '/ai/voice/history', method: 'get', params })

/** 执行详情 */
export const getVoiceHistoryDetail = (id) => request({ url: `/ai/voice/history/${id}`, method: 'get' })

/** 热门指令 */
export const getVoicePopular = () => request({ url: '/ai/voice/popular', method: 'get' })

/** 提交反馈 */
export const submitVoiceFeedback = (data) => request({ url: '/ai/voice/feedback', method: 'post', data })
