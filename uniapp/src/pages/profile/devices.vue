<template>
  <view class="devices-page">
    <view v-if="loading" class="state-box">
      <u-loading-icon mode="circle" size="28" color="#4F46E5"></u-loading-icon>
      <text class="state-text">加载中...</text>
    </view>
    <view v-else-if="list.length === 0" class="state-box">
      <MIcon name="gear" :size="48" color="#c6d2e0" />
      <text class="state-text">暂无登录设备记录</text>
    </view>
    <template v-else>
      <view class="section-label">当前设备</view>
      <view class="device-card current" v-for="d in list.filter(x => x.is_current)" :key="d.id">
        <view class="device-left">
          <view class="device-icon" style="background:linear-gradient(135deg,#4F46E5,#7C6FF0);">
            <MIcon name="gear" color="#fff" :size="22" />
          </view>
          <view class="device-info">
            <view class="device-name-row">
              <text class="device-name">{{ d.device_name }}</text>
              <text class="tag-current">当前</text>
            </view>
            <text class="device-sub">{{ d.os }} · {{ d.browser }}</text>
            <text class="device-sub">{{ d.ip }} {{ d.location ? '· ' + d.location : '' }}</text>
            <text class="device-sub">最近活跃：{{ d.last_active_time || d.login_time }}</text>
          </view>
        </view>
      </view>

      <view class="section-label">其他设备</view>
      <view class="device-card" v-for="d in list.filter(x => !x.is_current)" :key="d.id">
        <view class="device-left">
          <view class="device-icon" :style="{ background: d.status === 1 ? 'linear-gradient(135deg,#3d5a73,#5a8faa)' : 'linear-gradient(135deg,#c0cedc,#9aabba)' }">
            <MIcon name="gear" color="#fff" :size="22" />
          </view>
          <view class="device-info">
            <view class="device-name-row">
              <text class="device-name">{{ d.device_name }}</text>
              <text class="tag-status" :class="{ offline: d.status !== 1 }">{{ d.status === 1 ? '在线' : '已退出' }}</text>
            </view>
            <text class="device-sub">{{ d.os }} · {{ d.browser }}</text>
            <text class="device-sub">{{ d.ip }} {{ d.location ? '· ' + d.location : '' }}</text>
            <text class="device-sub">登录时间：{{ d.login_time }}</text>
          </view>
        </view>
        <view v-if="d.status === 1" class="device-right" @click="kick(d)">
          <text class="kick-btn">退出</text>
        </view>
      </view>
    </template>
  </view>
</template>

<script setup>
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import MIcon from '@/components/MIcon.vue'

const list = ref([])
const loading = ref(false)

function getToken() {
  return uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
}

function api(url, method, data) {
  return new Promise((resolve, reject) => {
    uni.request({
      url: uni.$base + url,
      method: method || 'GET',
      data: data || {},
      header: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Bearer ' + getToken()
      },
      success: (r) => r.data?.code === 0 ? resolve(r.data) : reject(r.data || { msg: '请求失败' }),
      fail: () => reject({ msg: '网络异常，请稍后重试' })
    })
  })
}

async function load() {
  loading.value = true
  try {
    const r = await api('/api/mobile/devices/list')
    list.value = r.data?.list || []
  } catch (e) {
    uni.showToast({ title: e.msg || '加载失败', icon: 'none' })
  }
  loading.value = false
}

function kick(d) {
  uni.showModal({
    title: '退出设备',
    content: '确定将「' + d.device_name + '」退出登录吗？该设备将无法继续访问。',
    confirmColor: '#e74c5e',
    success: async (r) => {
      if (!r.confirm) return
      try {
        await api('/api/mobile/devices/logout', 'POST', { device_key: d.device_key })
        uni.showToast({ title: '已退出该设备', icon: 'success' })
        load()
      } catch (e) {
        uni.showToast({ title: e.msg || '操作失败', icon: 'none' })
      }
    }
  })
}

onLoad(() => load())
</script>

<style scoped>
.devices-page { min-height: 100vh; background: var(--bg-color, #F4F6FB); padding: 16px 16px 30px; box-sizing: border-box; }
.state-box { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 80px 0; gap: 12px; }
.state-text { font-size: 13px; color: #9aabba; }
.section-label { font-size: 12px; color: var(--text-sub, #9aabba); font-weight: 500; padding: 0 4px 10px; letter-spacing: 0.3px; }
.device-card { display: flex; align-items: center; justify-content: space-between; background: var(--card-color, #fff); border-radius: 16px; padding: 16px; margin-bottom: 12px; box-shadow: 0 1px 4px rgba(0,0,0,0.04); border: 1px solid var(--divider-color, rgba(0,0,0,0.04)); }
.device-card.current { border-color: rgba(79,70,229,0.35); }
.device-left { display: flex; align-items: center; gap: 14px; flex: 1; min-width: 0; }
.device-icon { width: 46px; height: 46px; border-radius: 13px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.device-info { display: flex; flex-direction: column; min-width: 0; }
.device-name-row { display: flex; align-items: center; gap: 8px; }
.device-name { font-size: 15px; font-weight: 600; color: var(--text-main, #1a2332); }
.tag-current { font-size: 11px; color: #4F46E5; background: #EEF0FE; border-radius: 6px; padding: 2px 8px; }
.tag-status { font-size: 11px; color: #07c160; background: #E6F9EF; border-radius: 6px; padding: 2px 8px; }
.tag-status.offline { color: #9aabba; background: #F1F4F8; }
.device-sub { font-size: 12px; color: var(--text-sub, #9aabba); margin-top: 2px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.device-right { flex-shrink: 0; margin-left: 10px; }
.kick-btn { font-size: 13px; color: #e74c5e; border: 1px solid rgba(231,76,94,0.4); border-radius: 14px; padding: 6px 16px; }
.kick-btn:active { background: #fff0f1; }
</style>
