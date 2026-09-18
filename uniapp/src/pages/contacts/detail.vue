<template>
  <view class="cd-page">
    <view class="cd-header">
      <view class="cd-avatar" :style="{ background: avatarColor }">
        <image v-if="u.avatar" class="cd-avatar-img" :src="u.avatar" mode="aspectFill" />
        <text v-else>{{ (u.name || '?').substring(0, 1) }}</text>
        <view class="cd-status" :class="u.status === 1 ? 'online' : 'offline'"></view>
      </view>
      <text class="cd-name">{{ u.name || '员工' }}</text>
      <text class="cd-pos-tag">{{ u.department || '员工' }}</text>
      <text class="cd-dept">{{ u.department || '未分配部门' }}</text>
    </view>

    <view class="cd-grid">
      <view class="cd-item">
        <text class="cd-label">工号</text>
        <text class="cd-value">{{ u.username || '-' }}</text>
      </view>
      <view class="cd-item">
        <text class="cd-label">状态</text>
        <text class="cd-value" :style="{ color: u.status === 1 ? '#34c759' : '#c0cedc' }">{{ u.status === 1 ? '在职' : '离职' }}</text>
      </view>
      <view class="cd-item">
        <text class="cd-label">手机</text>
        <text class="cd-value">{{ maskPhone(u.phone) || '-' }}</text>
      </view>
      <view class="cd-item">
        <text class="cd-label">邮箱</text>
        <text class="cd-value">{{ u.email || '-' }}</text>
      </view>
    </view>

    <view class="cd-actions">
      <view class="cd-btn secondary" @click="call"><MIcon name="phone" :size="15" color="#4F46E5" /><text style="margin-left:4px">打电话</text></view>
      <view class="cd-btn primary" @click="chat"><MIcon name="chat" :size="15" color="#ffffff" /><text style="margin-left:4px">发消息</text></view>
    </view>
  </view>
</template>

<script setup>
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'

const u = ref({})
const avatarColor = ref('#3d5a73')
const AVATAR_COLORS = ['#3d5a73', '#c97d5a', '#4a8f8f', '#8a7aa8', '#c99a3a', '#5a8faa', '#e07a5f', '#4F46E5']

function maskPhone(p) {
  return p ? p.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2') : ''
}

function call() {
  if (!u.value.phone) { uni.showToast({ title: '暂无手机号', icon: 'none' }); return }
  // #ifdef H5
  window.location.href = 'tel:' + u.value.phone
  // #endif
  // #ifndef H5
  uni.makePhoneCall({ phoneNumber: u.value.phone, fail: () => {} })
  // #endif
}

function chat() {
  const id = u.value.id
  const name = u.value.name || '同事'
  if (!id) { uni.showToast({ title: '联系人信息缺失', icon: 'none' }); return }
  uni.navigateTo({ url: '/pages/contacts/chat?peer_id=' + id + '&name=' + encodeURIComponent(name) })
}

onLoad((o) => {
  try {
    const d = JSON.parse(decodeURIComponent(o.d || '{}'))
    u.value = d || {}
    avatarColor.value = AVATAR_COLORS[Math.floor(Math.random() * AVATAR_COLORS.length)]
  } catch (e) {}
})
</script>

<style scoped>
.cd-page { min-height: 100vh; background: #F4F6FB; padding: 20px 16px 30px; box-sizing: border-box; }
.cd-header { display: flex; flex-direction: column; align-items: center; padding: 20px 0; }
.cd-avatar-img { width: 100%; height: 100%; border-radius: 50%; display: block; }
.cd-avatar { width: 80px; height: 80px; border-radius:50%; display: flex; align-items: center; justify-content: center; color: #fff; font-size: 32px; font-weight: 600; position: relative; }
.cd-status { position: absolute; bottom: 2px; right: 2px; width: 18px; height: 18px; border-radius:50%; border: 3px solid #fff; }
.cd-status.online { background: #34c759; }
.cd-status.offline { background: #c0cedc; }
.cd-name { font-size: 20px; font-weight: 700; color: #1a2332; margin-top: 12px; }
.cd-pos-tag { font-size: 12px; color: #4F46E5; background: #EEF0FE; padding: 3px 14px; border-radius:30px; margin-top: 6px; }
.cd-dept { font-size: 14px; color: #8a9aa8; margin-top: 6px; }
.cd-grid { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 16px; }
.cd-item { flex: 1 1 45%; background: #fff; border-radius:124px; padding: 14px 16px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.cd-label { display: block; font-size: 12px; color: #9aabba; }
.cd-value { display: block; font-size: 14px; color: #1a2332; margin-top: 4px; word-break: break-all; }
.cd-actions { display: flex; gap: 10px; margin-top: 24px; }
.cd-btn { flex: 1; padding: 14px 16px; border-radius:124px; font-size: 15px; font-weight: 500; display: flex; align-items: center; justify-content: center; }
.cd-btn:active { transform: scale(0.96); }
.cd-btn.primary { background: linear-gradient(135deg, #4F46E5, #7C6FF0); color: #fff; box-shadow: 0 4px 16px rgba(110,142,251,0.15); }
.cd-btn.secondary { background: #fff; color: #8a9aa8; border: 1px solid #E7ECF4; }
</style>
