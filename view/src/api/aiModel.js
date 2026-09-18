/**
 * AI 模型配置 API
 * 路由前缀：/ai/settings/model
 */
import request from './request'

// ---- 服务商管理 ----
export const getAiProviderList = (params) => request({ url: '/ai/settings/model/provider/list', method: 'get', params })
export const getAiProviderOptions = () => request({ url: '/ai/settings/model/provider/options', method: 'get' })
export const getAiProviderDetail = (id) => request({ url: `/ai/settings/model/provider/detail/${id}`, method: 'get' })
export const addAiProvider = (data) => request({ url: '/ai/settings/model/provider/add', method: 'post', data })
export const editAiProvider = (id, data) => request({ url: `/ai/settings/model/provider/edit/${id}`, method: 'put', data })
export const deleteAiProvider = (id) => request({ url: `/ai/settings/model/provider/delete/${id}`, method: 'delete' })
export const toggleAiProviderStatus = (id, status) => request({ url: `/ai/settings/model/provider/status/${id}`, method: 'put', data: { status } })

// ---- 模型管理 ----
export const getAiModelList = (params) => request({ url: '/ai/settings/model/list', method: 'get', params })
export const getAiModelOptions = () => request({ url: '/ai/settings/model/options', method: 'get' })
export const getAiModelDetail = (id) => request({ url: `/ai/settings/model/detail/${id}`, method: 'get' })
export const addAiModel = (data) => request({ url: '/ai/settings/model/add', method: 'post', data })
export const editAiModel = (id, data) => request({ url: `/ai/settings/model/edit/${id}`, method: 'put', data })
export const deleteAiModel = (id) => request({ url: `/ai/settings/model/delete/${id}`, method: 'delete' })
export const toggleAiModelStatus = (id, status) => request({ url: `/ai/settings/model/status/${id}`, method: 'put', data: { status } })
export const setDefaultAiModel = (id) => request({ url: `/ai/settings/model/set-default/${id}`, method: 'put' })

// ---- 连接测试 / 统计 ----
export const testAiModel = (modelId) => request({ url: '/ai/settings/model/test', method: 'post', data: { model_id: modelId } })
export const getAiModelStatistics = (params) => request({ url: '/ai/settings/model/statistics', method: 'get', params })
