<template>
  <view class="st-page">
    <!-- 月度选择 -->
    <view class="st-month-bar">
      <u-icon name="arrow-left" size="18" color="#2979ff" @click="changeMonth(-1)" />
      <view class="st-month-text">{{ month }}</view>
      <u-icon name="arrow-right" size="18" color="#2979ff" @click="changeMonth(1)" />
    </view>

    <!-- 统计卡片 -->
    <view v-if="stat" class="st-cards">
      <view class="st-card">
        <text class="st-card-num ok">{{ stat.attend_days }}</text>
        <text class="st-card-label">出勤天数</text>
      </view>
      <view class="st-card">
        <text class="st-card-num warn">{{ stat.late }}</text>
        <text class="st-card-label">迟到次数</text>
      </view>
      <view class="st-card">
        <text class="st-card-num warn">{{ stat.early }}</text>
        <text class="st-card-label">早退次数</text>
      </view>
      <view class="st-card">
        <text class="st-card-num danger">{{ stat.miss }}</text>
        <text class="st-card-label">缺卡天数</text>
      </view>
    </view>

    <!-- 日历 -->
    <view v-if="calendar.length" class="st-calendar">
      <view class="st-calendar-title">{{ month }} 日历</view>
      <view class="st-calendar-header">
        <view class="st-cal-day">一</view>
        <view class="st-cal-day">二</view>
        <view class="st-cal-day">三</view>
        <view class="st-cal-day">四</view>
        <view class="st-cal-day">五</view>
        <view class="st-cal-day">六</view>
        <view class="st-cal-day">日</view>
      </view>
      <view class="st-calendar-body">
        <view
          v-for="(day, index) in calendar"
          :key="index"
          class="st-cal-day-box"
          :class="{
            'st-cal-other-month': day.isOtherMonth,
            'st-cal-today': day.isToday,
            'st-cal-workday': day.isWorkday && !day.isOtherMonth,
            'st-cal-restday': !day.isWorkday && !day.isOtherMonth
          }"
        >
          <text class="st-cal-day-num">{{ day.day }}</text>
          <view v-if="!day.isOtherMonth && day.status" class="st-cal-status">
            <view
              class="st-cal-status-dot"
              :class="'st-status-' + day.status"
            ></view>
          </view>
          <view v-if="!day.isOtherMonth && day.isRestday" class="st-cal-status">
            <text class="st-cal-status-text">休</text>
          </view>
        </view>
      </view>
    </view>

    <!-- 每日明细 -->
    <view class="st-daily">
      <view class="st-daily-title">每日打卡明细（{{ month }}）</view>
      <view v-if="daily.length" class="st-list">
        <view class="st-row" v-for="d in daily" :key="d.date">
          <view class="st-row-date">
            <text class="st-row-day">{{ dayOfMonth(d.date) }}</text>
            <text class="st-row-week">{{ weekText(d.date) }}</text>
          </view>
          <view class="st-row-times">
            <view class="st-time">
              <text>上班 {{ d.check_in || '--:--' }}</text>
              <u-tag v-if="d.check_in_result" :text="resultText(d.check_in_result)" :type="resultTagType(d.check_in_result)" size="mini" />
            </view>
            <view class="st-time">
              <text>下班 {{ d.check_out || '--:--' }}</text>
              <u-tag v-if="d.check_out_result" :text="resultText(d.check_out_result)" :type="resultTagType(d.check_out_result)" size="mini" />
            </view>
          </view>
          <view class="st-row-status" :class="'st-' + d.status">
            <text>{{ d.status_text }}</text>
          </view>
        </view>
      </view>
      <u-empty v-else text="本月暂无打卡记录" mode="list" />
    </view>
  </view>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { getAttendanceRecords } from '@/api/attendance'

const month = ref('')
const stat = ref(null)
const daily = ref([])
const calendar = ref([])

const pad = n => n < 10 ? '0' + n : '' + n

// 获取当月第一天是星期几（0=周日, 1=周一, ..., 6=周六）
function getFirstDayOfWeek(year, month) {
  const d = new Date(year, month - 1, 1)
  const day = d.getDay()
  // 将周日(0)转换为6，周一(1)转换为0，周二(2)转换为1，...，周六(6)转换为5
  return day === 0 ? 6 : day - 1
}

// 获取当月有多少天
function getDaysInMonth(year, month) {
  return new Date(year, month, 0).getDate()
}

// 生成日历
function generateCalendar() {
  const [y, m] = month.value.split('-').map(Number)
  const daysInMonth = getDaysInMonth(y, m)
  const firstDayOfWeek = getFirstDayOfWeek(y, m)
  
  // 本月日期数据
  const currentMonthDays = []
  for (let i = 1; i <= daysInMonth; i++) {
    currentMonthDays.push({
      day: i,
      date: `${y}-${pad(m)}-${pad(i)}`,
      isOtherMonth: false
    })
  }

  // 上月日期数据
  const prevMonthDays = []
  const prevMonth = new Date(y, m - 1, 0)
  const prevDaysInMonth = prevMonth.getDate()

  // 计算需要补位的天数
  const paddingDays = firstDayOfWeek

  // 从上月最后一天开始倒序填充
  for (let i = 1; i <= paddingDays; i++) {
    const day = prevDaysInMonth - paddingDays + i
    const d = new Date(y, m - 2, day)
    prevMonthDays.push({
      day: day,
      date: `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`,
      isOtherMonth: true
    })
  }
  
  // 下月日期数据
  const nextMonthDays = []
  const nextMonth = new Date(y, m, 1)
  const daysInNextMonth = new Date(y, m + 1, 0).getDate()
  
  // 计算需要填充的下月天数（总共42格，减去上月+本月的天数）
  const totalCells = 42
  const filledCells = prevMonthDays.length + currentMonthDays.length
  const nextPaddingDays = totalCells - filledCells
  
  for (let i = 1; i <= nextPaddingDays; i++) {
    const d = new Date(y, m, i)
    nextMonthDays.push({
      day: i,
      date: `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`,
      isOtherMonth: true
    })
  }
  
  // 合并所有日期
  calendar.value = [...prevMonthDays, ...currentMonthDays, ...nextMonthDays]
}

// 判断是否为工作日（周一至周五）
function isWorkday(dateStr) {
  const d = new Date(dateStr.replace(/-/g, '/'))
  const day = d.getDay()
  // 0=周日, 6=周六，周一至周五为工作日
  return day !== 0 && day !== 6
}

// 判断是否为休息日
function isRestday(dateStr) {
  return !isWorkday(dateStr)
}

// 匹配打卡状态
function matchStatus(day) {
  if (day.isOtherMonth) return null
  
  // 查找当天的打卡记录
  const record = daily.value.find(d => d.date === day.date)
  if (record) {
    return record.status
  }
  
  // 如果没有记录，判断是否为休息日
  if (isRestday(day.date)) {
    return 'restday'
  }
  
  // 工作日无记录，显示缺卡
  return 'miss'
}

// 获取状态文本
function getStatusText(status) {
  const statusMap = {
    'normal': '正常',
    'late': '迟到',
    'early': '早退',
    'miss': '缺卡',
    'restday': '休息日',
    'outside': '外勤'
  }
  return statusMap[status] || ''
}

// 获取状态点颜色
function getStatusDotColor(status) {
  const colorMap = {
    'normal': '#34c759',
    'late': '#ff9800',
    'early': '#ff9800',
    'miss': '#f44336',
    'restday': '#909399',
    'outside': '#2979ff'
  }
  return colorMap[status] || '#909399'
}

async function load() {
  try {
    const r = await getAttendanceRecords(month.value)
    if (r.code === 0 && r.data) {
      stat.value = r.data.stat || null
      daily.value = r.data.daily || []
      // 生成日历
      generateCalendar()
    }
  } catch (e) {
    uni.showToast({ title: '加载统计失败', icon: 'none' })
  }
}

function initMonth() {
  const now = new Date()
  month.value = now.getFullYear() + '-' + pad(now.getMonth() + 1)
}

function changeMonth(delta) {
  const [y, m] = month.value.split('-').map(Number)
  const d = new Date(y, m - 1 + delta, 1)
  month.value = d.getFullYear() + '-' + pad(d.getMonth() + 1)
  load()
}

function dayOfMonth(dateStr) {
  return String(parseInt(dateStr.slice(-2), 10))
}

function weekText(dateStr) {
  const week = ['日', '一', '二', '三', '四', '五', '六']
  const d = new Date(dateStr.replace(/-/g, '/'))
  return '周' + week[d.getDay()]
}

function resultText(r) {
  return { normal: '正常', late: '迟到', early: '早退', miss: '缺卡' }[r] || ''
}

function resultTagType(r) {
  return { normal: 'success', late: 'warning', early: 'warning', miss: 'error' }[r] || 'info'
}

onMounted(() => {
  initMonth()
  load()
})
</script>

<style scoped>
.st-page { min-height: 100vh; background: #f5f6fa; padding-bottom: 40px; }
.st-month-bar { display: flex; align-items: center; justify-content: center; gap: 24px; padding: 8px 0 4px; }
.st-month-text { font-size: 15px; font-weight: 600; color: #37474f; }
.st-cards { display: flex; gap: 8px; padding: 10px 16px 0; }
.st-card { flex: 1; background: #fff; border-radius:24px; padding: 14px 6px; display: flex; flex-direction: column; align-items: center; gap: 6px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.st-card-num { font-size: 20px; font-weight: 700; }
.st-card-num.ok { color: #34c759; }
.st-card-num.warn { color: #ff9800; }
.st-card-num.danger { color: #f44336; }
.st-card-label { font-size: 11px; color: #8a9aa8; }

/* 日历样式 */
.st-calendar { margin: 16px; background: #fff; border-radius:24px; padding: 14px 16px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.st-calendar-title { font-size: 13px; font-weight: 600; color: #37474f; margin-bottom: 10px; }
.st-calendar-header { display: grid; grid-template-columns: repeat(7, 1fr); gap: 4px; margin-bottom: 8px; }
.st-cal-day { font-size: 11px; color: #8a9aa8; text-align: center; }
.st-calendar-body { display: grid; grid-template-columns: repeat(7, 1fr); gap: 4px; }
.st-cal-day-box { aspect-ratio: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; border-radius:24px; position: relative; }
.st-cal-day-num { font-size: 14px; font-weight: 500; }
.st-cal-other-month .st-cal-day-num { color: #c0c0c0; }
.st-cal-today .st-cal-day-num { font-weight: 700; }
.st-cal-today { border: 2px solid #2979ff; }
.st-cal-workday .st-cal-day-num { color: #37474f; }
.st-cal-restday .st-cal-day-num { color: #c0c0c0; }
.st-cal-status { margin-top: 2px; }
.st-cal-status-dot { width: 6px; height: 6px; border-radius:50%; }
.st-status-normal .st-cal-status-dot { background: #34c759; }
.st-status-late .st-cal-status-dot { background: #ff9800; }
.st-status-miss .st-cal-status-dot { background: #f44336; }
.st-status-outside .st-cal-status-dot { background: #2979ff; }
.st-cal-status-text { font-size: 10px; color: #c0c0c0; }

/* 每日明细 */
.st-daily { margin: 16px; background: #fff; border-radius:24px; padding: 14px 16px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.st-daily-title { font-size: 13px; font-weight: 600; color: #37474f; margin-bottom: 10px; }
.st-list { }
.st-row { display: flex; align-items: center; gap: 12px; padding: 10px 0; border-bottom: 1px solid #f5f6fa; }
.st-row:last-child { border-bottom: none; }
.st-row-date { width: 56px; display: flex; flex-direction: column; align-items: center; gap: 2px; }
.st-row-day { font-size: 16px; font-weight: 600; color: #37474f; }
.st-row-week { font-size: 11px; color: #b0c0cc; }
.st-row-times { flex: 1; display: flex; flex-direction: column; gap: 4px; }
.st-time { font-size: 13px; color: #37474f; display: flex; align-items: center; gap: 4px; }
.st-row-status { font-size: 12px; }
.st-normal { color: #34c759; }
.st-warning { color: #ff9800; }
.st-miss { color: #f44336; }
</style>
