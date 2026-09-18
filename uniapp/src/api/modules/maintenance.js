// 设备保养执行 API 封装
import { get, post } from '../../utils/request.js'

// 获取当前员工保养任务列表
export function getMaintenanceTasks(status = '', page = 1, limit = 10) {
  return get('/api/mobile/maintenance/tasks', { status, page, limit })
}

// 获取任务详情（含保养项目）
export function getMaintenanceTaskDetail(taskId) {
  return get('/api/mobile/maintenance/task/detail', { task_id: taskId })
}

// 扫码获取设备待执行任务
export function getDeviceMaintenanceTasks(deviceCode) {
  return get('/api/mobile/maintenance/device-tasks', { device_code: deviceCode })
}

// 开始执行任务
export function startMaintenanceTask(taskId) {
  return post('/api/mobile/maintenance/execute/start', { task_id: taskId })
}

// 暂存保养结果
export function draftMaintenance(taskId, data) {
  return post('/api/mobile/maintenance/execute/draft', {
    task_id: taskId,
    items: JSON.stringify(data.items || []),
    materials: JSON.stringify(data.materials || []),
    remark: data.remark || ''
  })
}

// 提交保养结果
export function submitMaintenance(taskId, data) {
  return post('/api/mobile/maintenance/execute/submit', {
    task_id: taskId,
    items: JSON.stringify(data.items || []),
    materials: JSON.stringify(data.materials || []),
    attachments: JSON.stringify(data.attachments || []),
    remark: data.remark || ''
  })
}

// 上传附件图片（需 FormData）
export function uploadMaintenanceImage(filePath) {
  return new Promise((resolve, reject) => {
    const token = uni.getStorageSync('access_token') || ''
    uni.uploadFile({
      url: (import.meta.env.DEV ? '' : uni.$base) + '/api/mobile/maintenance/upload',
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

// 获取耗材列表
export function getMaintenanceMaterials(keyword = '') {
  return get('/api/mobile/maintenance/materials', { keyword })
}

// 获取保养记录详情
export function getMaintenanceRecordDetail(recordId) {
  return get('/api/mobile/maintenance/record/detail', { record_id: recordId })
}

// 获取保养通知列表
export function getMaintenanceNotifications(page = 1, limit = 10) {
  return get('/api/mobile/maintenance/notifications', { page, limit })
}

// 标记通知已读（id=0 且 all=1 时全部已读）
export function markNotificationRead(id = 0, all = 0) {
  return post('/api/mobile/maintenance/notification/read', { id, all })
}

// 获取未读通知数量
export function getNotificationUnreadCount() {
  return get('/api/mobile/maintenance/notification/unread-count')
}
