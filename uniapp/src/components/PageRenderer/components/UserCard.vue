<template>
  <view class="uc-card" :style="cardStyle" @click="handleCardClick">
    <!-- 装饰光晕 -->
    <view class="uc-glow" :style="{ display: config.showGlow !== false ? 'block' : 'none' }"></view>
    <!-- 装饰圆点 -->
    <template v-if="config.showDecoration !== false">
      <view class="uc-dot uc-dot-1"></view>
      <view class="uc-dot uc-dot-2"></view>
      <view class="uc-dot uc-dot-3"></view>
    </template>

    <view class="uc-top">
      <!-- 头像 -->
      <view v-if="config.showAvatar !== false" class="uc-avatar-wrap" :style="{ width: avatarSize + 'px', height: avatarSize + 'px', borderRadius: '50%', border: config.avatarBorder !== false ? '3px solid rgba(255,255,255,0.3)' : 'none', boxShadow: '0 0 20px rgba(102,126,234,0.3)' }" @click.stop="handleAvatarClick">
        <image v-if="user.avatar" :src="user.avatar" mode="aspectFill" class="uc-avatar-img" style="width:100%;height:100%;border-radius:50%"></image>
        <text v-else class="uc-avatar-initial" :style="{ fontSize: avatarSize * 0.4 + 'px' }">{{ avatarInitial }}</text>
        <!-- 上传蒙层 -->
        <view v-if="config.allowUpload !== false" class="uc-avatar-mask" :class="{ 'uc-avatar-mask-active': uploading }">
          <view v-if="uploading" class="uc-uploading">
            <view class="uc-loading-ring"></view>
          </view>
          <MIcon v-else class="uc-upload-hint" name="edit" :size="16" color="#8a9aa8" />
        </view>
      </view>

      <!-- 信息区 -->
      <view class="uc-info" style="flex:1">
        <view class="uc-name-row">
          <text v-if="config.showName !== false" class="uc-name" :style="{ fontSize: nameSize + 'px', color: nameColor, fontWeight: config.nameBold !== false ? '700' : 'normal' }">{{ user.name || '员工' }}</text>
          <view v-if="config.showStatus !== false" class="uc-status" :style="{ borderColor: statusColor }">
            <view class="uc-status-dot" :style="{ background: statusColor }"></view>
            <text class="uc-status-text" :style="{ color: statusColor }">{{ user.status == 1 ? '在职' : '离职' }}</text>
          </view>
        </view>
        <text v-if="config.showDept !== false" class="uc-dept" :style="{ fontSize: subSize + 'px', color: subColor }">{{ user.department || '' }}{{ config.showPosition !== false && user.position ? ' · ' + user.position : '' }}</text>
        <text v-if="config.showEmployeeId !== false" class="uc-empid" :style="{ fontSize: subSize - 1 + 'px', color: subColor }">工号：{{ user.employee_id || '' }}</text>
      </view>
    </view>

    <!-- 统计区 -->
    <view v-if="config.showStats !== false" class="uc-stats">
      <view class="uc-stat">
        <text class="uc-stat-num" :style="{ color: statNumberColor }">{{ user.join_days || 0 }}</text>
        <text class="uc-stat-label" :style="{ color: statLabelColor }">入职天数</text>
      </view>
      <view class="uc-stat">
        <text class="uc-stat-num" :style="{ color: statNumberColor }">{{ attendanceRate || 0 }}%</text>
        <text class="uc-stat-label" :style="{ color: statLabelColor }">出勤率</text>
      </view>
      <view class="uc-stat">
        <text class="uc-stat-num" :style="{ color: statNumberColor }">{{ todoCount || 0 }}</text>
        <text class="uc-stat-label" :style="{ color: statLabelColor }">待办</text>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

const props = defineProps({
  data: { type: Object, default: () => ({}) },
  item: { type: Object, default: () => ({}) }
})
const emit = defineEmits(['navigate'])

const user = ref({})
const attendanceRate = ref(0)
const todoCount = ref(0)
const uploading = ref(false)

// 配置合并：style + data
const config = computed(() => ({
  ...(props.data || {}),
  ...(props.item?.style || {})
}))

const avatarSize = computed(() => config.value.avatarSize || 72)
const nameSize = computed(() => config.value.nameSize || 20)
const nameColor = computed(() => config.value.nameColor || '#FFFFFF')
const subSize = computed(() => config.value.subSize || 13)
const subColor = computed(() => config.value.subColor || 'rgba(255,255,255,0.7)')
const statNumberColor = computed(() => config.value.statNumberColor || '#FCD34D')
const statLabelColor = computed(() => config.value.statLabelColor || 'rgba(255,255,255,0.5)')
const statusColor = computed(() => config.value.statusColor || '#34D399')

const avatarInitial = computed(() => (user.value.name || '员').substring(0, 1))

const cardStyle = computed(() => {
  const c = config.value
  return {
    background: 'linear-gradient(135deg,' + (c.bgStart || '#4F46E5') + ',' + (c.bgEnd || '#7C6FF0') + ')',
    borderRadius: (c.radius || 20) + 'px',
    padding: (c.padding || 24) + 'px ' + (c.padding || 24) + 'px ' + (c.padding || 24) + 'px',
    boxShadow: '0 24px 32px rgba(102,126,234,0.25)',
  }
})

function toFullUrl(val) {
  if (!val) return ''
  if (val.startsWith('http://') || val.startsWith('https://') || val.startsWith('data:')) return val
  if (val.startsWith('/')) return uni.$base + val
  return val
}

function calculateJoinDays(hireDate) {
  if (!hireDate) return 0
  const hire = new Date(String(hireDate).replace(/-/g, '/'))
  if (isNaN(hire.getTime())) return 0
  const diff = Math.floor((Date.now() - hire.getTime()) / 86400000)
  return Math.max(0, diff)
}

async function loadUserData() {
  try {
    const token = uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
    const header = token ? { 'Authorization': 'Bearer ' + token } : {}
    
    function api(url) {
      return new Promise(r => uni.request({ url, header, success: res => r(res.data), fail: () => r(null) }))
    }
    
    const [profileRes, attendanceRes, todoRes] = await Promise.all([
      api(uni.$base + '/api/user/profile'),
      api(uni.$base + '/api/attendance/stats'),
      api(uni.$base + '/api/todos/count')
    ])

    if (profileRes?.code === 0 && profileRes.data) {
      user.value = profileRes.data
      user.value.join_days = calculateJoinDays(profileRes.data.hire_date)
    }
    if (attendanceRes?.code === 0 && attendanceRes.data?.attendanceRate !== undefined) {
      attendanceRate.value = attendanceRes.data.attendanceRate
    }
    if (todoRes?.code === 0 && todoRes.data?.count !== undefined) {
      todoCount.value = todoRes.data.count
    }
  } catch (e) {
    console.error('加载用户信息失败', e)
  }
}

function handleAvatarClick() {
  if (config.value.allowUpload === false) return
  if (uploading.value) return
  
  uni.chooseImage({ count: 1 }).then(res => {
    if (!res.tempFilePaths?.length) return
    uploading.value = true
    
    uni.uploadFile({
      url: uni.$base + '/api/user/avatar',
      filePath: res.tempFilePaths[0],
      name: 'file',
      header: { 'Authorization': 'Bearer ' + (uni.getStorageSync('access_token') || uni.getStorageSync('token') || '') },
      success: (r) => {
        const rd = JSON.parse(r.data || '{}')
        if (rd.code === 0 && rd.data?.url) {
          user.value.avatar = toFullUrl(rd.data.url)
          uni.showToast({ title: '头像更新成功', icon: 'success' })
        } else {
          uni.showToast({ title: rd.msg || '头像上传失败', icon: 'none' })
        }
      },
      fail: () => uni.showToast({ title: '头像上传失败', icon: 'none' }),
      complete: () => { uploading.value = false }
    })
  })
}

function handleCardClick() {
  const link = props.item?.link || config.value.cardLink
  if (link) emit('navigate', link)
}

onMounted(loadUserData)
</script>

<style scoped>
.uc-card {
  position: relative;
  overflow: hidden;
  margin: 16px;
}
.uc-glow {
  position: absolute;
  top: -60px;
  right: -40px;
  width: 200px;
  height: 200px;
  border-radius:50%;
  background: radial-gradient(ellipse, rgba(252,211,77,0.15), transparent 70%);
  pointer-events: none;
}
.uc-dot {
  position: absolute;
  border-radius:50%;
  background: rgba(255,255,255,0.04);
  pointer-events: none;
}
.uc-dot-1 { bottom: -30px; left: 10%; width: 80px; height: 80px; }
.uc-dot-2 { bottom: -15px; left: 30%; width: 50px; height: 50px; }
.uc-dot-3 { bottom: -40px; left: 55%; width: 100px; height: 100px; }
.uc-top {
  display: flex;
  gap: 16px;
  align-items: center;
  position: relative;
  z-index: 2;
}
.uc-avatar-wrap {
  flex-shrink: 0;
  overflow: hidden;
  position: relative;
  background: rgba(255,255,255,0.15);
  display: flex;
  align-items: center;
  justify-content: center;
}
.uc-avatar-img { display: block; }
.uc-avatar-initial { color: #fff; font-weight: 600; }
.uc-avatar-mask {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(0,0,0,0.3);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.2s;
}
.uc-avatar-mask-active { opacity: 1; }
.uc-upload-hint { color: #fff; font-size: 20px; }
.uc-loading-ring {
  width: 22px;
  height: 22px;
  border: 2px solid rgba(255,255,255,0.3);
  border-top-color: #fff;
  border-radius:50%;
  animation: uc-spin 0.8s linear infinite;
}
@keyframes uc-spin { to { transform: rotate(360deg); } }
.uc-name-row {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 6px;
}
.uc-name { display: block; }
.uc-status {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 2px 8px;
  border-radius:22px;
  border: 1px solid;
  background: rgba(255,255,255,0.08);
}
.uc-status-dot { width: 6px; height: 6px; border-radius:50%; }
.uc-status-text { font-size: 11px; font-weight: 500; }
.uc-dept { display: block; margin-bottom: 2px; }
.uc-empid { display: block; opacity: 0.8; }
.uc-stats {
  display: flex;
  margin-top: 18px;
  padding-top: 16px;
  border-top: 1px solid rgba(255,255,255,0.12);
  position: relative;
  z-index: 2;
}
.uc-stat { flex: 1; text-align: center; }
.uc-stat-num {
  font-size: 22px;
  font-weight: 700;
  display: block;
}
.uc-stat-label {
  font-size: 11px;
  display: block;
  margin-top: 2px;
}
</style>
