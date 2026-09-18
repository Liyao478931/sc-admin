// 考核管理移动端 API（员工版 + 管理者版）
import { get, post } from '../utils/request.js'

// ===== 员工版 =====
export function getMyAssessmentOverview(data) { return get('/api/assessment/mobile/my-overview', data) }
export function getMyAssessmentDeductions(data) { return get('/api/assessment/mobile/my-deductions', data) }
export function getDeductionDetail(id) { return get('/api/assessment/mobile/deduction/' + id) }
export function confirmMyDeduction(id) { return post('/api/assessment/tasks/deduction/confirm', { deduction_ids: [id] }) }
export function submitAppeal(data) { return post('/api/assessment/appeals', data) }
export function getMyAppeals(data) { return get('/api/assessment/appeals/my-list', data) }

// ===== 管理者版 =====
// 管辖员工列表（搜索/最近考核）
export function getManageableEmployees(data) { return get('/api/assessment/mobile/manageable-employees', data) }
// 可用考核指标（按大类 + 常用）
export function getAvailableIndicators(data) { return get('/api/assessment/mobile/available-indicators', data) }
// 团队考核总览
export function getTeamOverview(data) { return get('/api/assessment/mobile/team-overview', data) }
// 员工考核详情（管理视角）
export function getEmployeeDetail(id, data) { return get('/api/assessment/mobile/employee-detail/' + id, data) }
// 待办列表（待确认/待申诉）
export function getTodoList(data) { return get('/api/assessment/mobile/todo-list', data) }
// 快速考核扣分
export function quickDeduct(data) { return post('/api/assessment/mobile/quick-deduct', data) }
// 管理者确认/驳回扣分
export function confirmDeduction(data) { return post('/api/assessment/mobile/confirm-deduction', data) }
