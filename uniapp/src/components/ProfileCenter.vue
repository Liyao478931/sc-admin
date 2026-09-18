<template>
  <view class="profile-page">
    <!-- 顶部导航 -->
    <view class="profile-nav">
      <text class="profile-nav-title">我的</text>
    </view>

    <!-- 用户信息卡片 -->
    <view class="profile-card">
      <view class="profile-header">
        <view class="profile-avatar">
          <image v-if="userInfo.avatar" :src="userInfo.avatar" mode="aspectFill" class="avatar-img" />
          <text v-else class="avatar-text">{{ (userInfo.real_name || userInfo.username || '?').charAt(0) }}</text>
        </view>
        <view class="profile-info">
          <text class="profile-name">{{ userInfo.real_name || userInfo.username || '未登录' }}</text>
          <text class="profile-dept">{{ userInfo.department || '员工' }}</text>
        </view>
      </view>
    </view>

    <!-- 功能菜单 -->
    <view class="profile-menu">
      <view class="menu-item" v-for="(item, index) in menuItems" :key="index" @click="menuClick(item)">
        <view class="menu-icon" :style="{ background: item.color }">
          <text>{{ item.icon }}</text>
        </view>
        <text class="menu-text">{{ item.name }}</text>
        <u-icon name="arrow-right" color="#c0c4cc" size="14" />
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { get } from '@/utils/request'

const userInfo = ref({})
const menuItems = ref([
  { name: '个人档案', icon: 'account', color: '#4F46E5', path: '/pages/profile/archive' },
  { name: '修改密码', icon: 'lock', color: '#7C3AED', path: '/pages/profile/password' },
  { name: '微信绑定', icon: 'chat', color: '#059669', path: '/pages/profile/wechat' },
  { name: '意见反馈', icon: 'edit-pen', color: '#DC2626', path: '/pages/profile/feedback' },
  { name: '使用帮助', icon: 'question', color: '#D97706', path: '/pages/profile/help' },
  { name: '关于系统', icon: 'info', color: '#6B7280', path: '/pages/profile/about' }
])

async function loadProfile () {
  try {
    const r = await get('/api/user/profile')
    if (r && r.data) {
      userInfo.value = r.data
    }
  } catch (e) {}
}

function menuClick (item) {
  uni.navigateTo({ url: item.path })
}

onMounted(() => {
  loadProfile()
})
</script>

<style scoped>
.profile-page { min-height: 100vh; background: #F4F6FB; }
.profile-nav { display: flex; align-items: center; justify-content: center; padding: 10px 16px 8px; background: transparent; }
.profile-nav-title { font-size: 18px; font-weight: 700; color: #1a2332; }
.profile-card { margin: 0 16px 12px; background: linear-gradient(135deg, #4F46E5 0%, #7C6FF0 100%); border-radius:24rpx; padding: 20px; box-shadow: 0 12rpx 32rpx rgba(79,70,229,0.25); }
.profile-header { display: flex; align-items: center; gap: 14px; }
.profile-avatar { width: 64px; height: 64px; border-radius:50%; background: rgba(255,255,255,0.3); display: flex; align-items: center; justify-content: center; overflow: hidden; border: 3px solid rgba(255,255,255,0.5); }
.avatar-img { width: 100%; height: 100%; }
.avatar-text { color: #fff; font-size: 28px; font-weight: 700; }
.profile-info { flex: 1; }
.profile-name { font-size: 18px; font-weight: 700; color: #fff; display: block; }
.profile-dept { font-size: 13px; color: rgba(255,255,255,0.8); margin-top: 4px; display: block; }
.profile-menu { margin: 0 16px; background: #fff; border-radius:24rpx; overflow: hidden; box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06); }
.menu-item { display: flex; align-items: center; gap: 12px; padding: 16px; border-bottom: 1px solid #f5f6fa; }
.menu-item:last-child { border-bottom: none; }
.menu-icon { width: 40px; height: 40px; border-radius:24px; display: flex; align-items: center; justify-content: center; font-size: 18px; flex-shrink: 0; }
.menu-text { flex: 1; font-size: 15px; color: #1a2332; }
</style>
