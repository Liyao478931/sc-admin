// 安全检查执行 API 封装
// 文件路径：src/api/modules/safety.js
import { get, post, BASE_URL } from '../../utils/request.js'

// 获取当前员工检查任务列表
export function getSafetyTasks(status = '', page = 1, limit = 10) {
  return get('/api/mobile/safety/tasks', { status, page, limit })
}

// 获取任务执行详情（含检查项目）
export function getSafetyTaskDetail(taskId) {
  return get('/api/mobile/safety/task/detail', { task_id: taskId })
}

// 开始执行任务
export function startSafetyTask(taskId) {
  return post('/api/mobile/safety/task/start', { task_id: taskId })
}

// 暂存检查结果
export function draftSafetyTask(taskId, items, summary) {
  return post('/api/mobile/safety/task/draft', {
    task_id: taskId,
    items: JSON.stringify(items || []),
    summary: summary || ''
  })
}

// 提交检查结果（生成问题记录和隐患记录）
export function submitSafetyTask(taskId, items, summary, issues) {
  return post('/api/mobile/safety/task/submit', {
    task_id: taskId,
    items: JSON.stringify(items || []),
    summary: summary || '',
    issues: JSON.stringify(issues || [])
  })
}

// 获取已完成的检查记录详情
export function getSafetyRecordDetail(recordId) {
  return get('/api/mobile/safety/record/detail', { record_id: recordId })
}

// ===== 我的培训 =====
// 我的培训列表
export function getMyTrainingList(status = '', page = 1, limit = 10) {
  return get('/api/mobile/safety/training/my-list', { status, page, limit })
}
// 培训详情（含课件与进度/签到状态）
export function getTrainingDetail(recordId) {
  return get('/api/mobile/safety/training/detail', { record_id: recordId })
}
// 更新课件观看进度（线上）
export function updateWatchProgress(recordId, coursewareId, data) {
  return post('/api/mobile/safety/training/watch-progress', {
    record_id: recordId,
    courseware_id: coursewareId,
    watch_duration: data.watch_duration || 0,
    total_duration: data.total_duration || 0,
    watch_percent: data.watch_percent || 0
  })
}
// 完成线上培训
export function completeOnlineTraining(recordId) {
  return post('/api/mobile/safety/training/complete-online', { record_id: recordId })
}
// 线下培训签到（含GPS）
export function offlineCheckin(recordId, lat, lng, address) {
  return post('/api/mobile/safety/training/checkin', { record_id: recordId, lat, lng, address: address || '' })
}

// ===== 我的证书 =====
// 我的证书列表
export function getMyCertificates(status = '', page = 1, limit = 10) {
  return get('/api/mobile/safety/certificates', { status, page, limit })
}
// 证书详情
export function getCertificateDetail(certId) {
  return get('/api/mobile/safety/certificate/detail', { certificate_id: certId })
}
// 下载证书（返回证书数据，前端 canvas 绘制导出）
export function downloadCertificate(certId) {
  return get('/api/mobile/safety/certificate/download', { certificate_id: certId })
}
// 检查证书状态
export function checkCertificateStatus() {
  return get('/api/mobile/safety/certificate/check-status')
}

// ===== 在线考试 =====
// 我的考试列表（status: ''全部/pending待开始/in_progress进行中/ended已结束）
export function getMyExams(status = '', page = 1, limit = 10) {
  return get('/api/mobile/safety/exam/my-list', { status, page, limit })
}
// 考试详情（考试须知）
export function getExamDetail(examId) {
  return get('/api/mobile/safety/exam/detail', { exam_id: examId })
}
// 开始考试（记录开始时间，创建进行中答卷）
export function startExam(examId) {
  return post('/api/mobile/safety/exam/start', { exam_id: examId })
}
// 获取题目（不含答案，含已保存答案回显）
export function getExamQuestions(examId) {
  return get('/api/mobile/safety/exam/questions', { exam_id: examId })
}
// 保存单题答案（实时保存）
export function saveExamAnswer(examId, questionId, answer) {
  return post('/api/mobile/safety/exam/save-answer', { exam_id: examId, question_id: questionId, answer })
}
// 交卷（自动判卷，携带切屏/截屏违规次数）
export function submitExam(examId, answers, durationSeconds, switchCount, captureCount) {
  return post('/api/mobile/safety/exam/submit', { exam_id: examId, answers, duration_seconds: durationSeconds, switch_count: switchCount || 0, capture_count: captureCount || 0 })
}
// 成绩详情（含错题）
export function getExamResult(examId) {
  return get('/api/mobile/safety/exam/result', { exam_id: examId })
}

// ===== 事故上报 =====
export function getAccidentTypes() { return get('/api/mobile/safety/accident/types') }
export function getAccidentLevels() { return get('/api/mobile/safety/accident/levels') }
export function getAccidentDepartments() { return get('/api/mobile/safety/accident/departments') }
export function reportAccident(data) { return post('/api/mobile/safety/accident/report', data) }
export function draftAccident(data) { return post('/api/mobile/safety/accident/draft', data) }
export function getMyAccidents(status = '', page = 1, limit = 10) { return get('/api/mobile/safety/accident/my-list', { status, page, limit }) }
export function getMyAccidentDetail(accidentId) { return get('/api/mobile/safety/accident/detail', { accident_id: accidentId }) }
export function uploadAccidentImage(filePath) {
  return new Promise((resolve, reject) => {
    uni.uploadFile({
      url: BASE_URL + '/api/mobile/safety/accident/upload-image',
      filePath, name: 'file',
      header: { Authorization: 'Bearer ' + (uni.getStorageSync('access_token') || '') },
      success: (res) => { try { resolve(JSON.parse(res.data)) } catch (e) { reject(e) } },
      fail: reject,
    })
  })
}
