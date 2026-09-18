import { get, post } from '../../utils/request.js'

// 设备巡检 API 封装（移动端）

// 我的巡检任务列表
export function getInspectionTasks(status = '', page = 1, limit = 10) {
  return get('/api/mobile/inspection/tasks', { status, page, limit })
}

// 巡检任务详情
export function getInspectionTaskDetail(taskId) {
  return get('/api/mobile/inspection/task-detail', { task_id: taskId })
}

// 获取检查项（含已保存结果）
export function getInspectionCheckItems(taskId) {
  return get('/api/mobile/inspection/check-items', { task_id: taskId })
}

// 开始执行
export function startInspectionTask(taskId) {
  return post('/api/mobile/inspection/execute-start', { task_id: taskId })
}

// 提交巡检结果
export function submitInspection(taskId, payload) {
  return post('/api/mobile/inspection/execute-submit', {
    task_id: taskId,
    items: JSON.stringify(payload.items || []),
    remark: payload.remark || ''
  })
}

// 我的巡检记录
export function getInspectionRecords(page = 1, limit = 10) {
  return get('/api/mobile/inspection/records', { page, limit })
}

// 巡检记录详情
export function getInspectionRecordDetail(recordId) {
  return get('/api/mobile/inspection/record-detail', { record_id: recordId })
}

// 上传巡检图片
export function uploadInspectionImage(filePath) {
  return new Promise((resolve, reject) => {
    uni.uploadFile({
      url: uni.$base + '/api/mobile/inspection/upload',
      filePath,
      name: 'file',
      header: { 'Authorization': 'Bearer ' + (uni.getStorageSync('access_token') || uni.getStorageSync('token') || '') },
      success: (r) => {
        try { resolve(JSON.parse(r.data)) } catch (e) { reject(e) }
      },
      fail: reject
    })
  })
}
