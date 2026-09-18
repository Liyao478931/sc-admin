<template>
  <view class="att-page">
    <!-- 顶部导航 -->
    <u-navbar :title="companyName" :bg-color="'#ffffff'" placeholder>
      <template #right>
        <view class="att-nav-right" :style="{ paddingRight: capsuleRight + 'px' }" @click="goProfile">
          <u-avatar v-if="avatar" :src="avatar" size="36" />
          <u-avatar v-else :text="nameInitial" size="36" bg-color="linear-gradient(135deg, #4F46E5, #7C6FF0)" font-size="14" />
        </view>
      </template>
    </u-navbar>

    <!-- 考勤组信息 -->
    <view class="att-sub-nav">
      <view class="att-group-name">{{ groupName }}</view>
      <view class="att-apply" @click="goApply">申请</view>
    </view>

    <!-- 加载状态 -->
    <view v-if="loading" class="att-loading">
      <u-loading-icon mode="circle" size="30" color="#2979ff" />
      <text class="att-loading-text">加载中...</text>
    </view>

    <template v-else>
      <!-- 今日打卡进度卡片 -->
      <view class="progress-card">
        <view class="progress-title">今日打卡进度</view>
        <view class="progress-grid" :class="'cols-' + segments.length">
          <view v-for="seg in segments" :key="seg.seq" class="progress-item" :class="{ active: seg.seq === currentSegment, done: seg.status !== 3, miss: seg.status === 3 && seg.seq < currentSegment }">
            <text class="p-name">{{ seg.name }}</text>
            <text class="p-time">{{ seg.time || '--:--' }}</text>
            <view class="p-status">
              <u-icon v-if="seg.status === 0" name="checkmark-circle" size="18" color="#34c759" />
              <u-icon v-else-if="seg.status === 1 || seg.status === 2" name="error" size="18" color="#ff9800" />
              <u-icon v-else-if="seg.status === 3 && seg.seq < currentSegment" name="close-circle" size="18" color="#f44336" />
              <u-icon v-else name="minus-circle" size="18" color="#c0c4cc" />
            </view>
            <text class="p-label" :class="{ 'lbl-active': seg.seq === currentSegment }">{{ seg.status_label }}</text>
          </view>
        </view>
      </view>

      <!-- 打卡位置 -->
      <view class="loc-card">
        <view class="loc-head">
          <text class="loc-title">打卡位置</text>
          <view class="loc-refresh" @click="refreshLocation">
            <u-icon name="reload" size="14" color="#2979ff" />
            <text> 刷新定位</text>
          </view>
        </view>
        <view class="loc-status" :class="locClass">
          <u-icon name="map-fill" size="16" :color="locColor" />
          <text>{{ locText }}</text>
          <u-loading-icon v-if="locLoading" mode="circle" size="14" color="#9ca3af" />
        </view>
        <view v-if="nearestPoint" class="loc-distance">距离打卡点 {{ nearestPoint.distance }} 米（允许范围 {{ nearestPoint.radius }} 米）</view>
      </view>

      <!-- 当前应打卡提示 -->
      <view v-if="currentSegment > 0 && currentSegmentText" class="current-hint">
        <text>当前可打卡：{{ currentSegmentText }}</text>
      </view>

      <!-- 打卡按钮区域 -->
      <view class="punch-area">
        <view class="punch-btn" :class="{ disabled: !canPunchNow || punching }" @click="onPunch">
          <u-loading-icon v-if="punching" mode="circle" color="#ffffff" size="22" />
          <u-icon v-else name="scan" size="26" color="#ffffff" />
        </view>
        <text class="punch-btn-text">{{ punchBtnText }}</text>
        <text class="att-date">{{ dateText }}</text>
        <text class="att-time">{{ nowTime }}</text>
      </view>

      <!-- 外勤打卡入口 -->
      <view v-if="showFieldEntry" class="field-entry" @click="openFieldApply">
        <u-icon name="map" size="14" color="#2979ff" />
        <text> 外勤打卡申请</text>
      </view>

      <!-- 今日记录摘要 -->
      <view class="summary-card">
        <view class="summary-title">今日打卡记录</view>
        <view v-if="segments.length" class="summary-list">
          <view v-for="seg in segments" :key="seg.seq" class="summary-item">
            <text class="s-name">{{ seg.name }}</text>
            <text class="s-time">{{ seg.time || '--:--' }}</text>
            <u-tag v-if="seg.status_label !== '未打卡'" :text="seg.status_label" :type="seg.status === 0 ? 'success' : (seg.status === 3 ? 'error' : 'warning')" size="mini" />
          </view>
        </view>
      </view>

      <!-- 底部导航 -->
      <view class="att-tabbar">
        <view class="att-tab active" @click="goTab('index')">
          <u-icon name="clock" size="20" color="#2979ff" />
          <text>打卡</text>
        </view>
        <view class="att-tab" @click="goTab('statistics')">
          <u-icon name="grid" size="20" color="#9ca3af" />
          <text>统计</text>
        </view>
        <view class="att-tab" @click="goTab('settings')">
          <u-icon name="setting" size="20" color="#9ca3af" />
          <text>设置</text>
        </view>
      </view>
    </template>

    <!-- 人脸识别中弹窗 -->
    <u-overlay :show="faceVisible" opacity="0.5">
      <view class="att-face-box">
        <u-loading-icon mode="circle" size="48" color="#ffffff" />
        <text class="att-face-title">人脸识别中..</text>
        <text class="att-face-tip">请面向镜头，保持光线充足</text>
      </view>
    </u-overlay>

    <!-- 人脸识别失败重试弹窗 -->
    <u-popup :show="failVisible" mode="center" :round="14" :closeable="false">
      <view class="att-fail-box">
        <u-icon name="error" size="40" color="#F56C6C" />
        <text class="att-fail-title">{{ failMsg }}</text>
        <view class="att-fail-btns">
          <u-button type="primary" size="small" :text="'重试（' + (3 - failCount) + '）'" @click="retryFace" />
          <u-button size="small" text="取消" plain @click="failVisible = false" />
        </view>
      </view>
    </u-popup>

    <!-- 定位失败/不在范围弹窗 -->
    <u-popup :show="locFailVisible" mode="center" :round="14">
      <view class="att-fail-box">
        <u-icon name="map-fill" size="40" color="#FF9800" />
        <text class="att-fail-title">{{ locFailMsg }}</text>
        <view class="att-fail-btns">
          <u-button type="primary" size="small" text="知道了" @click="locFailVisible = false" />
        </view>
      </view>
    </u-popup>

    <!-- 外勤申请弹窗 -->
    <u-popup :show="fieldVisible" mode="center" :round="14">
      <view class="field-box">
        <text class="field-title">外勤打卡申请</text>
        <text class="field-sub">当前不在打卡范围内，可提交外勤申请</text>
        <view class="field-item">
          <text class="field-label">当前段</text>
          <text>{{ currentSegmentText || '-' }}</text>
        </view>
        <view class="field-item">
          <text class="field-label">外勤原因</text>
          <u-input v-model="fieldReason" placeholder="请填写外勤原因（必填）" border="none" maxlength="100" :customStyle="{ height: '48px', fontSize: '15px' }" />
        </view>
        <view class="att-fail-btns">
          <u-button size="small" text="取消" plain @click="fieldVisible = false" />
          <u-button type="primary" size="small" :loading="fieldSubmitting" text="提交申请" @click="doFieldApply" />
        </view>
      </view>
    </u-popup>

    <!-- 打卡成功遮罩 -->
    <u-overlay :show="successVisible" opacity="0.85">
      <view class="success-box">
        <u-icon name="checkmark-circle" size="64" color="#34c759" />
        <text class="success-title">打卡成功</text>
        <text class="success-sub">{{ successText }}</text>
        <text v-if="successScore !== null" class="success-score">人脸匹配分数：{{ successScore }}分</text>
      </view>
    </u-overlay>
  </view>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { onShow } from '@dcloudio/uni-app'
import { getTodayAttendance, getAttendanceRule, validateLocation, submitCheckin, submitFieldCheckin } from '@/api/attendance'
import { get } from '@/utils/request'

// 胶囊右侧安全区域（避免头像按钮被遮挡）
const capsuleRight = ref(0)
// #ifdef MP-WEIXIN
try {
  const info = uni.getSystemInfoSync()
  if (typeof uni.getMenuButtonBoundingClientRect === 'function') {
    const m = uni.getMenuButtonBoundingClientRect()
    if (m && m.left) {
      capsuleRight.value = (info.screenWidth - m.left) + 10
    }
  }
} catch (e) {}
// #endif

const companyName = ref('企业考勤')
const groupName = ref('考勤组')
const avatar = ref('')
const nameInitial = ref('')

const loading = ref(true)
const nowTime = ref('')
const dateText = ref('')
let timeTimer = null

// 打卡数据（segments 驱动）
const segments = ref([])
const checkinCount = ref(2)
const currentSegment = ref(0)   // 当前应打卡段 seq
const canCheckin = ref(false)   // 当前是否可打卡
const checkinSequence = ref(0)

// 定位
const locText = ref('定位中...')
const locClass = ref('loc-pending')
const locLoading = ref(false)
const currentLoc = ref({ lat: 0, lng: 0 })
const inRange = ref(false)
const nearestPoint = ref(null)

// 打卡流程
const punching = ref(false)
const faceVisible = ref(false)
const failVisible = ref(false)
const failMsg = ref('人脸识别失败，请重试')
const failCount = ref(0)
const locFailVisible = ref(false)
const locFailMsg = ref('')
const successVisible = ref(false)
const successText = ref('')
const successScore = ref(null)

// 外勤
const fieldVisible = ref(false)
const fieldReason = ref('')
const fieldSubmitting = ref(false)

const pad = n => n < 10 ? '0' + n : '' + n

function updateClock() {
  const d = new Date()
  nowTime.value = pad(d.getHours()) + ':' + pad(d.getMinutes()) + ':' + pad(d.getSeconds())
  const week = ['日', '一', '二', '三', '四', '五', '六'][d.getDay()]
  dateText.value = (d.getMonth() + 1) + '月' + d.getDate() + '日周' + week
}

// 当前应打卡段文本
const currentSegmentText = computed(() => {
  const seg = segments.value.find(s => s.seq === currentSegment.value)
  if (!seg) return ''
  const win = seg.standard_time ? `（${seg.standard_time} 前后）` : ''
  return seg.name + win
})

// 是否展示外勤入口（不在范围内且未全部打卡）
const showFieldEntry = computed(() => {
  return !inRange.value && segments.value.some(s => s.status === 3)
})

// 按钮文字
const punchBtnText = computed(() => {
  if (punching.value) return '打卡中...'
  if (segments.value.every(s => s.status !== 3)) return '今日已全部打卡'
  if (!currentSegment.value) return '未到打卡时间'
  if (!inRange.value && !locLoading.value) return showFieldEntry.value ? '外勤打卡申请' : '不在打卡范围'
  if (!canCheckin.value) return '未到打卡时间'
  return '人脸识别打卡'
})

// 是否可点击打卡按钮
const canPunchNow = computed(() => {
  if (punching.value) return false
  if (segments.value.every(s => s.status !== 3)) return false
  if (!currentSegment.value) return false
  if (!inRange.value) return false
  return canCheckin.value
})

// 定位颜色
const locColor = computed(() => {
  if (locClass.value === 'loc-ok') return '#34c759'
  if (locClass.value === 'loc-err') return '#f44336'
  return '#9ca3af'
})

async function loadToday() {
  try {
    const r = await getTodayAttendance()
    if (r.code === 0 && r.data) {
      const d = r.data
      companyName.value = d.company_name || '企业考勤'
      groupName.value = d.group_name || '考勤组'
      segments.value = d.segments || []
      checkinCount.value = d.checkin_count || 2
      currentSegment.value = d.current_segment || 0
      canCheckin.value = !!d.can_checkin
      checkinSequence.value = d.checkin_sequence || 0

      // 检查是否所有打卡段都已打卡完成
      const allDone = segments.value.length > 0 && segments.value.every(s => s.status === 0 || s.status === 1 || s.status === 2)
      if (allDone) {
        canCheckin.value = false
      }
    }
  } catch (e) {
    uni.showToast({ title: '加载考勤状态失败', icon: 'none' })
  }

  // 检查是否需要自动打卡（当前时间在打卡窗口内）
  checkAutoPunch()
}

/**
 * 检查是否需要自动打卡
 */
function checkAutoPunch() {
  // 如果所有打卡段都已完成，不处理
  if (segments.value.length > 0 && segments.value.every(s => s.status === 0 || s.status === 1 || s.status === 2)) {
    return
  }

  // 如果当前打卡段已缺卡，不处理
  const currentSeg = segments.value.find(s => s.seq === currentSegment.value)
  if (currentSeg && currentSeg.status === 3) {
    return
  }

  // 检查当前时间是否在打卡窗口内
  const now = new Date()
  const currentTime = `${pad(now.getHours())}:${pad(now.getMinutes())}`

  if (currentSeg && currentSeg.standard_time) {
    // 标准时间格式：08:00-09:00
    const [start, end] = currentSeg.standard_time.split('-').map(t => t.trim())
    if (currentTime >= start && currentTime <= end) {
      // 在打卡窗口内，延迟2秒后自动打卡
      setTimeout(() => {
        if (inRange.value && canCheckin.value && !punching.value) {
          onPunch()
        }
      }, 2000)
    }
  }
}

async function loadProfile() {
  try {
    const r = await get('/api/user/profile')
    if (r && r.data) {
      avatar.value = r.data.avatar || ''
      nameInitial.value = (r.data.name || r.data.real_name || r.data.username || '?').charAt(0)
    }
  } catch (e) {}
}

async function refreshLocation() {
  locLoading.value = true
  locText.value = '定位中...'
  locClass.value = 'loc-pending'
  try {
    const loc = await getLocationWithFallback()
    currentLoc.value = { lat: loc.latitude, lng: loc.longitude }
    const r = await validateLocation(loc.latitude, loc.longitude)
    if (r.code === 0 && r.data) {
      const d = r.data
      inRange.value = !!d.is_in_range
      nearestPoint.value = d.nearest_point ? { ...d.nearest_point, distance: d.distance || 0 } : null
      if (d.is_in_range) {
        locText.value = '已进入考勤范围：' + (d.point_name || '打卡点')
        locClass.value = 'loc-ok'
      } else {
        locText.value = '不在考勤范围内' + (d.point_name ? '（最近：' + d.point_name + '）' : '')
        locClass.value = 'loc-err'
      }
    }
  } catch (e) {
    locText.value = '定位失败，请检查GPS权限'
    locClass.value = 'loc-err'
  } finally {
    locLoading.value = false
  }
}

/**
 * 获取定位（带超时与回退）：微信浏览器直接 IP 定位
 */
function getLocationWithFallback() {
  return new Promise((resolve, reject) => {
    let settled = false
    const done = (fn, val) => { if (!settled) { settled = true; fn(val) } }

    // #ifdef H5
    try {
      const ua = (navigator.userAgent || '').toLowerCase()
      const isWechat = /micromessenger|wxwork/.test(ua)
      if (isWechat) {
        ipLocation()
        return
      }
    } catch (e) {}
    // #endif

    const timer = setTimeout(() => { ipLocation() }, 8000)

    uni.getLocation({
      type: 'gcj02',
      success: (loc) => { clearTimeout(timer); done(resolve, { latitude: loc.latitude, longitude: loc.longitude, source: 'gps' }) },
      fail: () => { clearTimeout(timer); ipLocation() }
    })

    function ipLocation() {
      const token = uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
      uni.request({
        url: uni.$base + '/api/mobile/attendance/ip-location',
        method: 'GET',
        timeout: 10000,
        header: token ? { 'Authorization': 'Bearer ' + token } : {},
        success: (r) => {
          const d = r.data
          if (d && d.code === 0 && d.data && d.data.location) {
            done(resolve, { latitude: d.data.location.lat, longitude: d.data.location.lng, source: 'ip' })
          } else {
            done(reject, new Error('IP定位失败'))
          }
        },
        fail: () => done(reject, new Error('IP定位失败'))
      })
    }
  })
}

async function onPunch() {
  // 不在范围 → 外勤
  if (!inRange.value) {
    if (showFieldEntry.value) { openFieldApply() } else { locFailMsg.value = '不在打卡范围内，请移动至打卡点附近'; locFailVisible.value = true }
    return
  }
  if (!canPunchNow.value) {
    uni.showToast({ title: '当前不在打卡时间段', icon: 'none' })
    return
  }
  if (punching.value) return
  punching.value = true

  // 跳转全自动人脸采集页（携带打卡参数 + 位置）
  faceVisible.value = false
  uni.navigateTo({
    url: '/pages/attendance/face-capture?point_id=' + (nearestPoint.value ? nearestPoint.value.id : 0) +
      '&sequence=' + currentSegment.value +
      '&lat=' + (currentLoc.value.lat || 0) +
      '&lng=' + (currentLoc.value.lng || 0)
  })
  punching.value = false
}

/**
 * 采集页自动打卡成功后回调（face-capture.vue 提交成功后调用）
 */
function onCheckinDone() {
  loadToday()
  refreshLocation()
}

function fileToBase64(filePath) {
  return new Promise((resolve, reject) => {
    try {
      uni.getFileSystemManager().readFile({ filePath, encoding: 'base64', success: r => resolve(r.data), fail: reject })
    } catch (e) { reject(e) }
  })
}

function retryFace() {
  failVisible.value = false
  onPunch()
}

function openFieldApply() {
  fieldReason.value = ''
  fieldVisible.value = true
}

async function doFieldApply() {
  if (!fieldReason.value.trim()) { uni.showToast({ title: '请填写外勤原因', icon: 'none' }); return }
  fieldSubmitting.value = true
  // 跳转人脸采集页（外勤也需人脸验证，field=1）
  faceVisible.value = false
  uni.navigateTo({ url: '/pages/attendance/face-capture?field=1&sequence=' + (currentSegment.value || 1) + '&reason=' + encodeURIComponent(fieldReason.value.trim()) })
  fieldSubmitting.value = false
}

/**
 * 人脸采集页返回回调（外勤模式：提交外勤打卡）
 */
async function onFieldFaceCaptured(base64) {
  if (!base64) return
  fieldSubmitting.value = true
  try {
    const r = await submitFieldCheckin({
      check_sequence: currentSegment.value || 1,
      latitude: currentLoc.value.lat || 0,
      longitude: currentLoc.value.lng || 0,
      reason: fieldReason.value.trim(),
      face_image: base64
    })
    fieldVisible.value = false
    if (r.code === 0) {
      uni.showToast({ title: r.msg || '外勤申请已提交', icon: 'success' })
      await loadToday()
    } else {
      uni.showToast({ title: r.msg || '提交失败', icon: 'none' })
    }
  } catch (e) {
    uni.showToast({ title: '网络异常', icon: 'none' })
  } finally {
    fieldSubmitting.value = false
  }
}

/**
 * 统一人脸采集回调（face-capture.vue 采集成功后调用）
 * 根据当前是否外勤模式分流：正常打卡 / 外勤申请
 */
async function onFaceCaptured(base64) {
  if (!base64) return
  // 若外勤弹窗开启中 → 走外勤
  if (fieldVisible.value) {
    await onFieldFaceCaptured(base64)
    return
  }
  punching.value = true
  faceVisible.value = true
  try {
    const r = await submitCheckin({
      point_id: nearestPoint.value ? nearestPoint.value.id : 0,
      check_sequence: currentSegment.value,
      latitude: currentLoc.value.lat,
      longitude: currentLoc.value.lng,
      face_image: base64,
      location_address: nearestPoint.value ? nearestPoint.value.point_name : ''
    })
    faceVisible.value = false
    if (r.code === 0) {
      const d = r.data || {}
      successText.value = (d.check_status_label || '正常') + ' · ' + (d.check_time ? String(d.check_time).slice(11, 16) : '')
      successScore.value = d.score !== undefined && d.score !== null ? d.score : null
      successVisible.value = true
      setTimeout(() => { successVisible.value = false }, 2000)
      await loadToday()
      refreshLocation()
    } else {
      failCount.value++
      failMsg.value = failCount.value >= 3 ? '人脸识别多次失败，请联系管理员' : (r.msg || '人脸识别失败，请重试')
      failVisible.value = true
    }
  } catch (e) {
    faceVisible.value = false
    failCount.value++
    failMsg.value = '人脸识别失败，请重试'
    failVisible.value = true
  } finally {
    punching.value = false
  }
}

function goProfile() { uni.navigateTo({ url: '/pages/profile/index' }) }
function goApply() { uni.navigateTo({ url: '/pages/oa/apply' }) }
function goTab(t) {
  if (t === 'index') return
  if (t === 'statistics') { uni.navigateTo({ url: '/pages/attendance/records/calendar' }); return }
  if (t === 'records') { uni.navigateTo({ url: '/pages/attendance/records/calendar' }); return }
  uni.navigateTo({ url: '/pages/attendance/' + t })
}

onShow(() => {
  loadToday()
  loadProfile()
  refreshLocation()
  // 每次页面显示时重新检查自动打卡
  setTimeout(checkAutoPunch, 1000)
})

onMounted(() => {
  loading.value = false
  updateClock()
  timeTimer = setInterval(updateClock, 1000)
})

onUnmounted(() => {
  if (timeTimer) { clearInterval(timeTimer); timeTimer = null }
})
</script>

<style scoped>
.att-page { min-height: 100vh; background: #f5f6fa; padding-bottom: 90px; box-sizing: border-box; }
.att-nav-right { margin-right: 12px; }
.att-sub-nav { display: flex; align-items: center; justify-content: space-between; padding: 6px 16px 4px; }
.att-group-name { font-size: 12px; color: #8a9aa8; }
.att-apply { font-size: 13px; color: #2979ff; }
.att-loading { display: flex; flex-direction: column; align-items: center; gap: 10px; padding: 80px 0; }
.att-loading-text { color: #b0c0cc; font-size: 13px; }

.progress-card { margin: 10px 16px 0; background: #fff; border-radius:24px; padding: 14px 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); }
.progress-title { font-size: 14px; font-weight: 600; color: #37474f; margin-bottom: 12px; }
.progress-grid { display: flex; gap: 8px; }
.progress-grid.cols-1 .progress-item { width: 100%; }
.progress-grid.cols-2 .progress-item { width: 48%; }
.progress-grid.cols-4 .progress-item { width: 23%; }
.progress-item { display: flex; flex-direction: column; align-items: center; gap: 4px; background: #F4F6FB; border-radius:22px; padding: 10px 6px; border: 2px solid transparent; }
.progress-item.active { border-color: #2979ff; background: #eef4ff; }
.progress-item.done { background: #f0f9f0; }
.progress-item.miss { background: #fff5f5; }
.p-name { font-size: 12px; color: #606266; }
.p-time { font-size: 15px; font-weight: 700; color: #1a2332; }
.p-label { font-size: 11px; color: #909399; }
.p-label.lbl-active { color: #2979ff; font-weight: 600; }

.loc-card { margin: 12px 16px 0; background: #fff; border-radius:24px; padding: 14px 16px; box-shadow: 0 2px 8px rgba(0,0,0,0.04); }
.loc-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.loc-title { font-size: 14px; font-weight: 600; color: #37474f; }
.loc-refresh { display: flex; align-items: center; font-size: 12px; color: #2979ff; }
.loc-status { display: flex; align-items: center; gap: 6px; font-size: 13px; }
.loc-ok { color: #34c759; }
.loc-err { color: #f44336; }
.loc-pending { color: #9ca3af; }
.loc-distance { font-size: 12px; color: #909399; margin-top: 6px; }

.current-hint { text-align: center; font-size: 13px; color: #2979ff; margin-top: 14px; }

.punch-area { display: flex; flex-direction: column; align-items: center; margin-top: 18px; }
.punch-btn { width: 76px; height: 76px; border-radius:50%; background: linear-gradient(135deg, #2979ff, #1565c0); display: flex; align-items: center; justify-content: center; box-shadow: 0 8px 20px rgba(41,121,255,0.3); }
.punch-btn.disabled { background: #c0c4cc; box-shadow: none; }
.punch-btn-text { font-size: 15px; font-weight: 600; color: #1a2332; margin-top: 10px; }
.att-date { font-size: 13px; color: #8a9aa8; margin-top: 8px; }
.att-time { font-size: 12px; color: #b0c0cc; margin-top: 2px; }

.field-entry { display: flex; align-items: center; justify-content: center; gap: 4px; margin-top: 14px; font-size: 13px; color: #2979ff; }

.summary-card { margin: 16px 16px 0; background: #fff; border-radius:24px; padding: 14px 16px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.summary-title { font-size: 13px; font-weight: 600; color: #37474f; margin-bottom: 8px; }
.summary-item { display: flex; align-items: center; gap: 8px; padding: 7px 0; border-bottom: 1px solid #f5f6fa; }
.summary-item:last-child { border-bottom: none; }
.s-name { width: 70px; font-size: 13px; color: #8a9aa8; }
.s-time { flex: 1; font-size: 14px; color: #37474f; }

.att-tabbar { position: fixed; left: 0; right: 0; bottom: 0; display: flex; background: #fff; border-top: 1px solid #EDF0F8; padding-bottom: env(safe-area-inset-bottom); z-index: 10; }
.att-tab { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 2px; padding: 10px 0 8px; font-size: 11px; color: #9ca3af; }
.att-tab.active { color: #2979ff; }

.att-face-box { display: flex; flex-direction: column; align-items: center; gap: 14px; margin-top: 40vh; }
.att-face-title { font-size: 16px; color: #fff; }
.att-face-tip { font-size: 12px; color: rgba(255,255,255,0.7); }

.att-fail-box { width: 280px; padding: 28px 20px; display: flex; flex-direction: column; align-items: center; gap: 14px; }
.att-fail-title { font-size: 14px; color: #37474f; text-align: center; line-height: 1.6; }
.att-fail-btns { display: flex; gap: 12px; margin-top: 6px; }

.field-box { width: 300px; padding: 24px 20px; display: flex; flex-direction: column; gap: 10px; }
.field-title { font-size: 16px; font-weight: 600; color: #1a2332; text-align: center; }
.field-sub { font-size: 12px; color: #909399; text-align: center; margin-bottom: 6px; }
.field-item { display: flex; align-items: center; gap: 10px; font-size: 13px; color: #37474f; }
.field-label { width: 60px; color: #909399; flex-shrink: 0; }
.field-input { flex: 1; background: #F4F6FB; border-radius:24px; padding: 8px 10px; font-size: 13px; }

.success-box { display: flex; flex-direction: column; align-items: center; gap: 12px; margin-top: 36vh; }
.success-title { font-size: 22px; font-weight: 700; color: #fff; }
.success-sub { font-size: 15px; color: rgba(255,255,255,0.9); }
.success-score { font-size: 13px; color: rgba(255,255,255,0.7); }
</style>
