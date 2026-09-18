<template>
  <view class="set-page">

    <!-- 打卡提醒 -->
    <view class="set-section">
      <view class="set-title">打卡提醒</view>
      <u-cell-group :border="false">
        <u-cell title="上班打卡提醒" :border="false">
          <template #right-icon>
            <u-switch v-model="remindOn" size="22" active-color="#2979ff" @change="toggleRemind" />
          </template>
        </u-cell>
        <u-cell title="下班打卡提醒" :border="false">
          <template #right-icon>
            <u-switch v-model="remindOff" size="22" active-color="#2979ff" @change="toggleRemindOff" />
          </template>
        </u-cell>
      </u-cell-group>
    </view>

    <!-- 打卡点列表 -->
    <view class="set-section">
      <view class="set-title">打卡点列表</view>
      <view v-if="points.length" class="set-point" v-for="p in points" :key="p.id">
        <view class="set-point-info">
          <text class="set-point-name">{{ p.point_name }}</text>
          <text class="set-point-addr">{{ p.address || '未填写地址' }}</text>
          <text class="set-point-meta">半径 {{ p.radius }} 米 · 打卡时间 {{ timeText(p.start_time) }} - {{ timeText(p.end_time) }}</text>
        </view>
        <u-tag :text="p.status === 1 ? '启用' : '停用'" :type="p.status === 1 ? 'success' : 'info'" size="mini" />
      </view>
      <u-empty v-else text="暂无可用的打卡点" mode="list" />
    </view>

    <!-- 退出登录 -->
    <view class="set-section">
      <u-button type="error" text="退出登录" plain @click="logout" />
    </view>
  </view>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { getAttendancePoints } from '@/api/attendance'

const remindOn = ref(true)
const remindOff = ref(true)
const points = ref([])

function timeText(t) {
  return t ? String(t).slice(0, 5) : '--:--'
}

function toggleRemind(e) {
  remindOn.value = !!e
  uni.setStorageSync('att_remind_on', remindOn.value ? '1' : '0')
  uni.showToast({ title: remindOn.value ? '已开启上班提醒' : '已关闭上班提醒', icon: 'none' })
}

function toggleRemindOff(e) {
  remindOff.value = !!e
  uni.setStorageSync('att_remind_off', remindOff.value ? '1' : '0')
  uni.showToast({ title: remindOff.value ? '已开启下班提醒' : '已关闭下班提醒', icon: 'none' })
}

function logout() {
  uni.showModal({
    title: '退出登录',
    content: '确定要退出当前账号吗？',
    success: (res) => {
      if (res.confirm) {
        uni.removeStorageSync('access_token')
        uni.removeStorageSync('token')
        uni.removeStorageSync('userInfo')
        uni.reLaunch({ url: '/pages/login/index' })
      }
    }
  })
}

onMounted(async () => {
  remindOn.value = uni.getStorageSync('att_remind_on') !== '0'
  remindOff.value = uni.getStorageSync('att_remind_off') !== '0'
  try {
    const r = await getAttendancePoints()
    if (r.code === 0 && r.data) points.value = r.data.list || []
  } catch (e) {}
})
</script>

<style scoped>
.set-page { min-height: 100vh; background: #f5f6fa; }
.set-section { margin: 0 16px; background: #fff; border-radius:24px; padding: 14px 16px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.set-section:first-child { margin-top: 8px; }
.set-title { font-size: 13px; font-weight: 600; color: #37474f; margin-bottom: 10px; }
.set-point { display: flex; align-items: center; justify-content: space-between; gap: 10px; padding: 12px 0; border-bottom: 1px solid #f5f6fa; }
.set-point:last-child { border-bottom: none; }
.set-point-info { flex: 1; display: flex; flex-direction: column; gap: 4px; }
.set-point-name { font-size: 14px; font-weight: 600; color: #37474f; }
.set-point-addr { font-size: 12px; color: #8a9aa8; }
.set-point-meta { font-size: 11px; color: #b0c0cc; }
</style>
