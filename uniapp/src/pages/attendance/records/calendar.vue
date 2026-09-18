<template>
  <view class="cal-page">

    <!-- 个人信息 -->
    <view class="user-card">
      <u-avatar v-if="avatar" :src="avatar" size="44" />
      <u-avatar v-else :text="nameInitial" size="44" bg-color="linear-gradient(135deg, #4F46E5, #7C6FF0)" font-size="16" />
      <view class="user-info">
        <text class="user-name">{{ userName }}</text>
        <text class="user-group">{{ groupName }}</text>
      </view>
    </view>

    <!-- 月份切换 -->
    <view class="month-bar">
      <view class="month-btn" @click="prevMonth"><u-icon name="arrow-left" size="18" color="#2979ff" /></view>
      <view class="month-text">{{ year }}年 {{ month }}月</view>
      <view class="month-btn" @click="nextMonth"><u-icon name="arrow-right" size="18" color="#2979ff" /></view>
      <view class="today-btn" @click="goToday">今天</view>
    </view>

    <!-- 状态摘要 -->
    <view v-if="summary" class="summary-card" :class="hasAbnormal ? 'sum-warn' : 'sum-ok'">
      <view class="sum-line">
        <u-icon :name="hasAbnormal ? 'error' : 'checkmark-circle'" size="18" :color="hasAbnormal ? '#ff9500' : '#34c759'" />
        <text class="sum-text">{{ hasAbnormal ? '当天存在异常' : '全天考勤正常' }}</text>
      </view>
      <view v-if="hasAbnormal" class="sum-detail">
        <text v-if="summary.late_days">迟到 {{ summary.late_days }} 天</text>
        <text v-if="summary.early_days">早退 {{ summary.early_days }} 天</text>
        <text v-if="summary.absent_days">缺卡 {{ summary.absent_days }} 天</text>
        <text v-if="summary.field_days">外勤 {{ summary.field_days }} 天</text>
        <text v-if="summary.error_days">异常 {{ summary.error_days }} 天</text>
      </view>
      <view class="sum-normal">
        <text>正常 {{ summary.normal_days }} 天 · 应出勤 {{ summary.total_days }} 天</text>
      </view>
    </view>

    <!-- 日历表头 -->
    <view class="cal-wrap">
      <view class="cal-header">
        <view v-for="w in weekNames" :key="w" class="cal-week">{{ w }}</view>
      </view>

      <!-- 日历网格 -->
      <view class="cal-grid">
        <view v-for="(cell, i) in calendarCells" :key="i" class="cal-cell" :class="cellCls(cell)" @click="onDateClick(cell)">
          <text class="cal-day">{{ cell.day }}</text>
          <view v-if="cell.status !== 'rest'" class="cal-dot" :style="{ background: dotColor(cell.status) }"></view>
        </view>
      </view>
    </view>

    <!-- 班次信息 -->
    <view v-if="shift" class="shift-card">
      <view class="shift-title">当日班次</view>
      <view class="shift-row">
        <text class="shift-label">班次名称</text>
        <text class="shift-value">{{ shift.shift_name }}</text>
      </view>
      <view class="shift-row">
        <text class="shift-label">考勤组</text>
        <text class="shift-value">{{ shift.group_name }}</text>
      </view>
      <view v-if="shift.segments && shift.segments.length" class="shift-row">
        <text class="shift-label">打卡时间</text>
        <text class="shift-value">{{ shift.segments.join('  ') }}</text>
      </view>
    </view>

    <!-- 日打卡详情弹窗 -->
    <u-popup :show="detailVisible" mode="center" :round="14" :closeable="true" @close="detailVisible = false">
      <view class="detail-box" v-if="detail">
        <view class="detail-head">
          <text class="detail-date">{{ detail.date }}</text>
          <text class="detail-week">{{ detail.weekday }}</text>
          <u-tag :text="detail.status_label" :type="detail.status === 'normal' ? 'success' : (detail.status === 'late' || detail.status === 'early' ? 'warning' : (detail.status === 'absent' || detail.status === 'error' ? 'error' : 'primary'))" size="mini" />
        </view>
        <view v-if="detail.segments && detail.segments.length" class="detail-segments">
          <view v-for="seg in detail.segments" :key="seg.seq" class="detail-seg">
            <text class="d-name">{{ seg.name }}</text>
            <text class="d-time">{{ seg.time }}</text>
            <u-tag :text="seg.status_label" :type="seg.status === 0 ? 'success' : (seg.status === 1 || seg.status === 2 ? 'warning' : (seg.status === 3 ? 'error' : 'primary'))" size="mini" />
            <text v-if="seg.location" class="d-loc">{{ seg.location }}</text>
          </view>
        </view>
        <u-empty v-else text="当日无打卡记录" mode="list" />
      </view>
    </u-popup>
  </view>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { getAttendanceStatistics, getDailyDetail } from '@/api/attendance'
import { get } from '@/utils/request'

const year = ref(new Date().getFullYear())
const month = ref(new Date().getMonth() + 1)
const summary = ref(null)
const calendar = ref([])
const shift = ref(null)
const userName = ref('')
const groupName = ref('')
const avatar = ref('')
const nameInitial = ref('')

const detailVisible = ref(false)
const detail = ref(null)

const weekNames = ['一', '二', '三', '四', '五', '六', '日']

const hasAbnormal = computed(() => {
  if (!summary.value) return false
  return (summary.value.late_days || 0) + (summary.value.early_days || 0) + (summary.value.absent_days || 0) + (summary.value.field_days || 0) + (summary.value.error_days || 0) > 0
})

// 生成日历单元格（补齐前后月份）
const calendarCells = computed(() => {
  const cells = []
  const firstDay = new Date(year.value, month.value - 1, 1).getDay() // 0=周日
  const offset = (firstDay + 6) % 7 // 周一开头
  const daysInMonth = new Date(year.value, month.value, 0).getDate()
  const daysInPrev = new Date(year.value, month.value - 1, 0).getDate()

  const calMap = {}
  for (const c of calendar.value) calMap[c.date] = c

  // 上月补位
  for (let i = offset - 1; i >= 0; i--) {
    const day = daysInPrev - i
    cells.push({ day, isCurrentMonth: false, date: '', status: 'rest', isPrev: true })
  }
  // 本月
  for (let d = 1; d <= daysInMonth; d++) {
    const dateStr = `${year.value}-${String(month.value).padStart(2, '0')}-${String(d).padStart(2, '0')}`
    const c = calMap[dateStr] || { status: 'rest', status_label: '', color: 'gray', is_today: false }
    cells.push({ day: d, isCurrentMonth: true, date: dateStr, status: c.status, status_label: c.status_label, color: c.color, is_today: c.is_today })
  }
  // 下月补位
  let next = 1
  while (cells.length % 7 !== 0) {
    cells.push({ day: next++, isCurrentMonth: false, date: '', status: 'rest', isNext: true })
  }
  return cells
})

function cellCls (cell) {
  return {
    'is-other': !cell.isCurrentMonth,
    'is-today': cell.is_today
  }
}

function dotColor (status) {
  return { normal: '#34c759', late: '#ff9500', early: '#ff9500', absent: '#ff3b30', field: '#007aff', error: '#ff3b30' }[status] || '#c0cedc'
}

async function loadData () {
  try {
    const r = await getAttendanceStatistics(year.value, month.value)
    if (r.code === 0 && r.data) {
      const d = r.data
      year.value = d.year || year.value
      month.value = d.month || month.value
      summary.value = d.summary || null
      calendar.value = d.calendar || []
      shift.value = d.shift || null
      userName.value = d.user_name || ''
      groupName.value = d.group_name || ''
    }
  } catch (e) {
    uni.showToast({ title: '加载失败', icon: 'none' })
  }
}

async function loadProfile () {
  try {
    const r = await get('/api/user/profile')
    if (r && r.data) {
      avatar.value = r.data.avatar || ''
      nameInitial.value = (r.data.name || r.data.real_name || r.data.username || '?').charAt(0)
    }
  } catch (e) {}
}

function prevMonth () {
  if (month.value === 1) { month.value = 12; year.value-- } else { month.value-- }
  loadData()
}

function nextMonth () {
  if (month.value === 12) { month.value = 1; year.value++ } else { month.value++ }
  loadData()
}

function goToday () {
  year.value = new Date().getFullYear()
  month.value = new Date().getMonth() + 1
  loadData()
}

async function onDateClick (cell) {
  if (!cell.isCurrentMonth || !cell.date) return
  try {
    const r = await getDailyDetail(cell.date)
    if (r.code === 0) { detail.value = r.data || null; detailVisible.value = true }
  } catch (e) {}
}

onMounted(() => {
  loadData()
  loadProfile()
})
</script>

<style scoped>
.cal-page { min-height: 100vh; background: #f5f6fa; padding-bottom: 40px; }
.user-card { display: flex; align-items: center; gap: 12px; margin: 6px 16px 0; background: #fff; border-radius:24px; padding: 14px 16px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.user-info { display: flex; flex-direction: column; gap: 2px; }
.user-name { font-size: 16px; font-weight: 600; color: #1a2332; }
.user-group { font-size: 12px; color: #8a9aa8; }

.month-bar { display: flex; align-items: center; justify-content: center; gap: 16px; padding: 14px 0 4px; }
.month-btn { width: 32px; height: 32px; border-radius:24px; background: #fff; display: flex; align-items: center; justify-content: center; }
.month-text { font-size: 16px; font-weight: 600; color: #1a2332; min-width: 100px; text-align: center; }
.today-btn { font-size: 13px; color: #2979ff; margin-left: 8px; }

.summary-card { margin: 10px 16px; border-radius:24px; padding: 12px 16px; }
.sum-ok { background: #e8f5e9; }
.sum-warn { background: #fff8e1; }
.sum-line { display: flex; align-items: center; gap: 6px; }
.sum-text { font-size: 14px; font-weight: 600; color: #1a2332; }
.sum-detail { display: flex; gap: 12px; margin-top: 6px; font-size: 12px; color: #e65100; }
.sum-normal { margin-top: 4px; font-size: 12px; color: #8a9aa8; }

.cal-wrap { margin: 4px 16px; background: #fff; border-radius:24px; padding: 12px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.cal-header { display: flex; margin-bottom: 8px; }
.cal-week { flex: 1; text-align: center; font-size: 12px; color: #8a9aa8; }
.cal-grid { display: flex; flex-wrap: wrap; }
.cal-cell { width: 14.28%; height: 48px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 4px; border-radius:24px; }
.cal-cell.is-other .cal-day { color: #d0d7de; }
.cal-cell.is-today .cal-day { color: #2979ff; font-weight: 700; }
.cal-cell.is-today { border: 1px solid #2979ff; }
.cal-day { font-size: 15px; color: #37474f; }
.cal-dot { width: 8px; height: 8px; border-radius:50%; }

.shift-card { margin: 12px 16px; background: #fff; border-radius:24px; padding: 14px 16px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.shift-title { font-size: 13px; font-weight: 600; color: #37474f; margin-bottom: 10px; }
.shift-row { display: flex; gap: 10px; padding: 5px 0; font-size: 13px; }
.shift-label { width: 70px; color: #8a9aa8; flex-shrink: 0; }
.shift-value { color: #37474f; }

.detail-box { width: 300px; padding: 22px 20px; }
.detail-head { display: flex; align-items: center; gap: 10px; margin-bottom: 14px; }
.detail-date { font-size: 18px; font-weight: 700; color: #1a2332; }
.detail-week { font-size: 13px; color: #8a9aa8; }
.detail-segments { display: flex; flex-direction: column; gap: 8px; }
.detail-seg { display: flex; align-items: center; gap: 8px; background: #F4F6FB; border-radius:24px; padding: 8px 10px; font-size: 13px; flex-wrap: wrap; }
.d-name { width: 60px; color: #606266; }
.d-time { font-weight: 600; color: #1a2332; }
.d-loc { width: 100%; font-size: 11px; color: #909399; margin-top: 2px; }
</style>
