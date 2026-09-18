/**
 * AI 收藏问答 API
 * 路由前缀：/ai/chat/favorite
 */
import request from './request'
import { getToken } from '@/utils/auth'

// ---- 分类管理 ----
export const getAiFavoriteCategories = () => request({ url: '/ai/chat/favorite/category/list', method: 'get' })
export const addAiFavoriteCategory = (data) => request({ url: '/ai/chat/favorite/category/add', method: 'post', data })
export const editAiFavoriteCategory = (id, data) => request({ url: `/ai/chat/favorite/category/edit/${id}`, method: 'put', data })
export const deleteAiFavoriteCategory = (id) => request({ url: `/ai/chat/favorite/category/delete/${id}`, method: 'delete' })

// ---- 收藏管理 ----
export const getAiFavoriteList = (params) => request({ url: '/ai/chat/favorite/list', method: 'get', params })
export const getAiFavoriteDetail = (id) => request({ url: `/ai/chat/favorite/detail/${id}`, method: 'get' })
export const addAiFavorite = (data) => request({ url: '/ai/chat/favorite/add', method: 'post', data })
export const deleteAiFavorite = (id) => request({ url: `/ai/chat/favorite/delete/${id}`, method: 'delete' })
export const batchDeleteAiFavorite = (ids) => request({ url: '/ai/chat/favorite/batch-delete', method: 'delete', data: { ids } })
export const updateAiFavoriteCategory = (favoriteId, categoryId) => request({ url: '/ai/chat/favorite/category/update', method: 'put', data: { favorite_id: favoriteId, category_id: categoryId } })
export const updateAiFavoriteNote = (favoriteId, note) => request({ url: '/ai/chat/favorite/note/update', method: 'put', data: { favorite_id: favoriteId, note } })

// ---- 统计 ----
export const getAiFavoriteStatistics = () => request({ url: '/ai/chat/favorite/statistics', method: 'get' })

// ---- 导出（带 token 下载） ----
export async function exportAiFavorites (params) {
  const token = getToken() || ''
  const query = new URLSearchParams()
  if (params.format) query.append('format', params.format)
  if (params.category_id) query.append('category_id', params.category_id)
  if (params.ids && params.ids.length) params.ids.forEach(id => query.append('ids[]', id))
  const qs = query.toString()
  const resp = await fetch(`/api/ai/chat/favorite/export${qs ? '?' + qs : ''}`, {
    headers: { 'Authorization': 'Bearer ' + token }
  })
  if (!resp.ok) throw new Error('导出失败')
  return resp.blob()
}
