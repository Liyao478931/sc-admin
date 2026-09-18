/**
 * 文件：admin/src/api/aiApiKey.js
 * AI 应用 API 密钥 API（路由前缀 /ai/apikey）
 */
import request from './request'

/** 密钥列表 */
export const getApiKeyList = (p) => request({ url: '/ai/apikey/list', method: 'get', params: p })

/** 密钥详情 */
export const getApiKeyDetail = (id) => request({ url: '/ai/apikey/detail/' + id, method: 'get' })

/** 生成密钥 */
export const generateApiKey = (d) => request({ url: '/ai/apikey/generate', method: 'post', data: d })

/** 查看明文 */
export const revealApiKey = (keyId) => request({ url: '/ai/apikey/reveal', method: 'post', data: { key_id: keyId } })

/** 删除密钥 */
export const deleteApiKey = (id) => request({ url: '/ai/apikey/delete/' + id, method: 'delete' })

/** 切换启用/停用 */
export const updateApiKeyStatus = (id, status) => request({ url: '/ai/apikey/status/' + id, method: 'put', data: { status } })

/** 刷新密钥 */
export const refreshApiKey = (id) => request({ url: '/ai/apikey/refresh/' + id, method: 'post' })

/** 密钥统计 */
export const getApiKeyStatistics = () => request({ url: '/ai/apikey/statistics', method: 'get' })

/** 调用趋势 */
export const getApiKeyTrend = (id, p) => request({ url: '/ai/apikey/trend/' + id, method: 'get', params: p })
