<template>
  <view class="about-page">
    <view class="about-header">
      <view class="about-back" @click="goBack"><MIcon name="close" :size="20" color="#1a2332" /></view>
      <text class="about-header-title">关于</text>
      <view class="about-header-space"></view>
    </view>

    <view class="about-content">
      <view class="app-logo">
        <text class="app-logo-text">华</text>
        <view class="app-logo-badge">
          <MIcon name="sparkles" :size="14" color="#4F46E5" />
        </view>
      </view>
      <text class="app-name">数智管控平台</text>
      <text class="app-desc">山西大运华能装备制造有限公司</text>

      <view class="version-card">
        <view class="version-row">
          <text class="version-label">当前版本</text>
          <text class="version-value">{{ appVersion }}</text>
        </view>
        <view class="version-row" v-if="buildTime">
          <text class="version-label">构建时间</text>
          <text class="version-value">{{ buildTime }}</text>
        </view>
      </view>
    </view>

    <view class="about-footer">
      <text class="footer-line">Copyright © 2026 山西大运华能装备制造有限公司</text>
      <text class="footer-line">数智管控平台 · 企业数字化管理</text>
    </view>
  </view>
</template>

<script setup>
import { ref } from 'vue'

const appVersion = ref('v1.76.80')
const buildTime = ref('')

function getToken() {
  return uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
}

function goBack() { uni.navigateBack({ fail: () => uni.reLaunch({ url: '/pages/profile/settings' }) }) }

async function loadVersion() {
  try {
    const res = await new Promise((resolve, reject) => {
      uni.request({
        url: uni.$base + '/api/mobile/version',
        method: 'GET',
        timeout: 8000,
        success: resolve,
        fail: reject
      })
    })
    if (res.data && res.data.code === 0 && res.data.data) {
      if (res.data.data.version) appVersion.value = res.data.data.version
      if (res.data.data.buildTime) buildTime.value = res.data.data.buildTime
    }
  } catch (e) {}
}

loadVersion()
</script>

<style scoped>
.about-page { min-height: 100vh; background: #F4F6FB; display: flex; flex-direction: column; font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", "HarmonyOS Sans SC", "Microsoft YaHei", sans-serif; }
.about-header { display: flex; align-items: center; justify-content: space-between; padding: 12px 16px; background: #fff; }
.about-back { width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; border-radius: 8px; background: #F0F2F7; }
.about-header-title { font-size: 16px; font-weight: 600; color: #1a2332; }
.about-header-space { width: 32px; }

.about-content { flex: 1; display: flex; flex-direction: column; align-items: center; padding-top: 60px; }
.app-logo { width: 88px; height: 88px; border-radius: 26px; background: linear-gradient(135deg, #4F46E5, #7C6FF0); display: flex; align-items: center; justify-content: center; margin-bottom: 18px; position: relative; box-shadow: 0 8px 24px rgba(79, 70, 229, 0.25); }
.app-logo-text { font-size: 44px; color: #fff; font-weight: 700; }
.app-logo-badge { position: absolute; right: -4px; bottom: -4px; width: 26px; height: 26px; border-radius: 50%; background: #fff; display: flex; align-items: center; justify-content: center; box-shadow: 0 2px 8px rgba(0,0,0,0.12); }
.app-name { font-size: 22px; font-weight: 700; color: #1a2332; margin-bottom: 8px; letter-spacing: 0.5px; }
.app-desc { font-size: 13px; color: #8a9aa8; margin-bottom: 40px; }

.version-card { width: 88%; background: #fff; border-radius: 16px; padding: 6px 20px; box-shadow: 0 2px 10px rgba(0,0,0,0.04); }
.version-row { display: flex; align-items: center; justify-content: space-between; padding: 14px 0; border-bottom: 1px solid #F4F6FB; }
.version-row:last-child { border-bottom: none; }
.version-label { font-size: 14px; color: #8a9aa8; }
.version-value { font-size: 14px; color: #1a2332; font-weight: 600; }

.about-footer { text-align: center; padding: 24px 0 40px; }
.footer-line { display: block; font-size: 12px; color: #B0BCC9; line-height: 1.8; }
</style>
