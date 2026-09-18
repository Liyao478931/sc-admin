/**
 * AI 智能报告 API（v1.65.0）
 * 路由前缀：/ai/reports
 */
import request from './request'
import { getToken } from '@/utils/auth'

/** 报告模板列表 */
export const getReportTemplates = () => request({ url: '/ai/reports/templates', method: 'get' })

/** 报告列表 */
export const getReportList = (params) => request({ url: '/ai/reports/list', method: 'get', params })

/** 报告详情 */
export const getReportDetail = (id) => request({ url: `/ai/reports/detail/${id}`, method: 'get' })

/** 删除报告 */
export const deleteReport = (id) => request({ url: `/ai/reports/delete/${id}`, method: 'delete' })

/** 定时任务：保存/更新（action=save） */
export const saveReportSchedule = (data) => request({ url: '/ai/reports/schedule', method: 'post', data })

/** 定时任务：删除/启停 */
export const operateReportSchedule = (id, action, status) => request({ url: '/ai/reports/schedule', method: 'post', data: { id, action, status } })

/** 定时任务列表 */
export const getReportSchedules = () => request({ url: '/ai/reports/schedules', method: 'get' })

/** 生成报告（SSE 流式进度） */
export async function streamReportGenerate (payload, onEvent) {
  const token = getToken() || ''
  const resp = await fetch('/api/ai/reports/generate', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
    body: JSON.stringify(payload)
  })
  if (!resp.ok) throw new Error('生成请求失败')
  await consumeSse(resp, onEvent)
}

/** 重新生成报告（SSE 流式） */
export async function streamReportRegenerate (id, onEvent) {
  const token = getToken() || ''
  const resp = await fetch(`/api/ai/reports/regenerate/${id}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token }
  })
  if (!resp.ok) throw new Error('重新生成请求失败')
  await consumeSse(resp, onEvent)
}

async function consumeSse (resp, onEvent) {
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
      try { onEvent(JSON.parse(t.slice(6))) } catch (e) { /* 忽略 */ }
    }
  }
}

/** 下载报告文件（PDF/Word，带 token） */
export async function downloadReportFile (id, format = 'pdf') {
  const token = getToken() || ''
  const resp = await fetch(`/api/ai/reports/download/${id}?format=${format}`, {
    headers: { 'Authorization': 'Bearer ' + token }
  })
  if (!resp.ok) throw new Error('下载失败')
  const blob = await resp.blob()
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `report_${id}.${format === 'word' ? 'doc' : 'pdf'}`
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}
