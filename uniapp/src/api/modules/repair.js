// 设备维修执行 API 封装
import { get, post } from '../../utils/request.js'

// 获取当前维修人员待执行工单列表
export function getRepairTasks(status = '', page = 1, limit = 10) {
  return get('/api/mobile/repair/tasks', { status, page, limit })
}

// 扫码获取设备待维修工单
export function getDeviceRepairTasks(deviceCode) {
  return get('/api/mobile/repair/device-tasks', { device_code: deviceCode })
}

// 获取工单详情
export function getRepairTaskDetail(taskId) {
  return get('/api/mobile/repair/task/detail', { task_id: taskId })
}

// 开始维修
export function startRepair(taskId) {
  return post('/api/mobile/repair/execute/start', { task_id: taskId })
}

// 暂存维修记录
export function draftRepair(taskId, data) {
  return post('/api/mobile/repair/execute/draft', {
    task_id: taskId,
    diagnosis_cause: data.diagnosis_cause || '',
    diagnosis_conclusion: data.diagnosis_conclusion || '',
    repair_plan: data.repair_plan || '',
    materials: JSON.stringify(data.materials || []),
    repair_process: data.repair_process || '',
    repair_result: data.repair_result || '',
    attachments: JSON.stringify(data.attachments || []),
    remark: data.remark || ''
  })
}

// 提交维修结果
export function submitRepair(taskId, data) {
  return post('/api/mobile/repair/execute/submit', {
    task_id: taskId,
    diagnosis_cause: data.diagnosis_cause || '',
    diagnosis_conclusion: data.diagnosis_conclusion || '',
    repair_plan: data.repair_plan || '',
    materials: JSON.stringify(data.materials || []),
    repair_process: data.repair_process || '',
    repair_result: data.repair_result || '',
    attachments: JSON.stringify(data.attachments || []),
    remark: data.remark || ''
  })
}

// 上传附件图片（需 FormData）
export function uploadRepairImage(filePath) {
  return new Promise((resolve, reject) => {
    const token = uni.getStorageSync('access_token') || ''
    uni.uploadFile({
      url: (import.meta.env.DEV ? '' : uni.$base) + '/api/mobile/repair/upload',
      filePath,
      name: 'file',
      header: { 'Authorization': 'Bearer ' + token },
      success(res) {
        try { resolve(JSON.parse(res.data)) } catch (e) { reject(e) }
      },
      fail(err) { reject(err) }
    })
  })
}

// 获取维修记录详情
export function getRepairRecordDetail(recordId) {
  return get('/api/mobile/repair/record/detail', { record_id: recordId })
}
