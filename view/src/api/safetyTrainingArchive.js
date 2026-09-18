/**
 * 培训档案 + 证书 API 封装
 * 档案：/safety/training/archive；证书：/safety/training/certificate
 */
import request from './request'

// ===== 培训档案 =====
export const getArchiveList = (p) => request({ url: '/safety/training/archive/list', method: 'get', params: p })
export const getArchiveDetail = (id) => request({ url: `/safety/training/archive/detail/${id}`, method: 'get' })
export const getArchiveHistory = (id, p) => request({ url: `/safety/training/archive/history/${id}`, method: 'get', params: p })
export const exportArchiveHistory = (id, p) => request({ url: `/safety/training/archive/export-history/${id}`, method: 'get', params: p })
export const getArchiveStatistics = () => request({ url: '/safety/training/archive/statistics', method: 'get' })

// ===== 培训证书 =====
export const getCertificateList = (p) => request({ url: '/safety/training/certificate/list', method: 'get', params: p })
export const getCertificateDetail = (id) => request({ url: `/safety/training/certificate/detail/${id}`, method: 'get' })
export const generateCertificate = (recordId, userIds) => request({ url: '/safety/training/certificate/generate', method: 'post', data: { record_id: recordId, user_ids: userIds || [] } })
export const previewCertificate = (id) => request({ url: `/safety/training/certificate/preview/${id}`, method: 'get' })
export const exportCertificate = (id) => request({ url: `/safety/training/certificate/export/${id}`, method: 'get' })
export const batchExportCertificate = (d) => request({ url: '/safety/training/certificate/batch-export', method: 'post', data: d })
export const deleteCertificate = (id) => request({ url: `/safety/training/certificate/delete/${id}`, method: 'delete' })

// ===== 证书模板 =====
export const getCertificateTemplateList = (p) => request({ url: '/safety/training/certificate/template/list', method: 'get', params: p })
export const saveCertificateTemplate = (d) => request({ url: '/safety/training/certificate/template/save', method: 'post', data: d })
export const deleteCertificateTemplate = (id) => request({ url: `/safety/training/certificate/template/delete/${id}`, method: 'delete' })

// ===== 关联数据 =====
export const getTypeOptions = () => request({ url: '/safety/training/plan/type/options', method: 'get' })
