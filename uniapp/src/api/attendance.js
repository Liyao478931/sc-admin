/**
 * 考勤打卡 API 封装
 * 路由前缀：/api/mobile/attendance
 */
import { get, post } from '@/utils/request'

/** 今日打卡状态（含多段 segments） */
export const getTodayAttendance = () => get('/api/mobile/attendance/today')

/** 获取打卡规则（含段定义/时间窗口） */
export const getAttendanceRule = () => get('/api/mobile/attendance/rule')

/** 打卡点列表（按距离排序） */
export const getAttendancePoints = (lat, lng) => get('/api/mobile/attendance/points', { latitude: lat, longitude: lng })

/** 位置校验 */
export const validateLocation = (lat, lng) => post('/api/mobile/attendance/validate-location', { latitude: lat, longitude: lng })

/** 时间校验 */
export const validateTime = (checkSequence, checkTime) => post('/api/mobile/attendance/validate-time', { check_sequence: checkSequence, check_time: checkTime })

/** 提交打卡（check_sequence 1-4） */
export const submitCheckin = (data) => post('/api/mobile/attendance/checkin', data)

/** 外勤打卡申请 */
export const submitFieldCheckin = (data) => post('/api/mobile/attendance/field-checkin', data)

/** 我的打卡记录（月度统计+明细） */
export const getAttendanceRecords = (month) => get('/api/mobile/attendance/records', { month })

/** 月度打卡统计（日历视图） */
export const getAttendanceStatistics = (year, month) => get('/api/mobile/attendance/statistics', { year, month })

/** 日打卡详情 */
export const getDailyDetail = (date) => get('/api/mobile/attendance/daily-detail', { date })
