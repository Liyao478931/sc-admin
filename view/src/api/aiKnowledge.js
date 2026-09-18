/**
 * AI 知识库 API
 * 路由前缀：/ai/knowledge
 */
import request from './request'
import { getToken } from '@/utils/auth'

/** 知识库列表（分页 + 多维度筛选） */
export const getAiKnowledgeList = (params) => request({ url: '/ai/knowledge/list', method: 'get', params })
/** 知识库详情（含文档列表） */
export const getAiKnowledgeDetail = (id, params) => request({ url: `/ai/knowledge/detail/${id}`, method: 'get', params })
/** 创建知识库 */
export const addAiKnowledge = (data) => request({ url: '/ai/knowledge/add', method: 'post', data })
/** 编辑知识库 */
export const editAiKnowledge = (id, data) => request({ url: `/ai/knowledge/edit/${id}`, method: 'put', data })
/** 删除知识库 */
export const deleteAiKnowledge = (id) => request({ url: `/ai/knowledge/delete/${id}`, method: 'delete' })
/** 知识库统计 */
export const getAiKnowledgeStats = () => request({ url: '/ai/knowledge/statistics', method: 'get' })
/** 知识库检索测试（关键词检索） */
export const retrieveAiKnowledge = (data) => request({ url: '/ai/knowledge/retrieve', method: 'post', data })
/** 已完成向量化知识库下拉（智能体表单用） */
export const getAiKnowledgeOptions = () => request({ url: '/ai/knowledge/options', method: 'get' })
/** 删除知识库文档 */
export const deleteAiKnowledgeDoc = (id) => request({ url: `/ai/knowledge/doc/delete/${id}`, method: 'delete' })

// ---- 文档上传（AiKnowledgeUploadController，前缀 /ai/knowledge/upload） ----
/** 上传配置 */
export const getUploadConfig = () => request({ url: '/ai/knowledge/upload/config', method: 'get' })
/** 知识库信息（上传页） */
export const getUploadKbInfo = (kbId) => request({ url: '/ai/knowledge/upload/info', method: 'get', params: { kb_id: kbId } })
/** 单文件上传（XHR 带进度） */
export function uploadDocFile (formData, onProgress) {
  return uploadViaXhr('/api/ai/knowledge/upload/file', formData, onProgress)
}
/** 批量上传（XHR 带进度） */
export function uploadDocBatch (formData, onProgress) {
  return uploadViaXhr('/api/ai/knowledge/upload/batch', formData, onProgress)
}
/** 文档列表（上传页，多维度筛选） */
export const getUploadDocs = (params) => request({ url: '/ai/knowledge/upload/documents', method: 'get', params })
/** 删除文档（按 doc_id） */
export const deleteUploadDoc = (docId) => request({ url: '/ai/knowledge/upload/delete', method: 'delete', data: { doc_id: docId } })
/** 批量删除文档 */
export const batchDeleteUploadDocs = (docIds) => request({ url: '/ai/knowledge/upload/batch-delete', method: 'delete', data: { doc_ids: docIds } })
/** 重新处理文档 */
export const retryUploadDoc = (docId) => request({ url: '/ai/knowledge/upload/retry', method: 'post', data: { doc_id: docId } })
/** 批量重新处理文档 */
export const batchRetryUploadDocs = (docIds) => request({ url: '/ai/knowledge/upload/batch-retry', method: 'post', data: { doc_ids: docIds } })

/** XHR 上传封装（携带 token + 进度回调） */
function uploadViaXhr (url, formData, onProgress) {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest()
    xhr.open('POST', url)
    xhr.setRequestHeader('Authorization', 'Bearer ' + getToken())
    xhr.upload.onprogress = (e) => {
      if (e.lengthComputable && onProgress) onProgress(Math.round((e.loaded / e.total) * 100))
    }
    xhr.onload = () => {
      try {
        const json = JSON.parse(xhr.responseText)
        if (xhr.status >= 200 && xhr.status < 300 && json.code === 0) resolve(json)
        else reject(new Error((json && json.msg) || '上传失败'))
      } catch (e) { reject(new Error('上传响应解析失败')) }
    }
    xhr.onerror = () => reject(new Error('网络错误，上传失败'))
    xhr.send(formData)
  })
}
