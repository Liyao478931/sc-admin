<template>
  <view class="ad-page">
    <!-- 顶部渐变标题栏 -->
    <view class="ad-header">
      <view class="ad-header-top">
        <view class="ad-header-left" @click="goBack">
          <MIcon name="chevron-left" :size="22" color="#ffffff" />
        </view>
        <text class="ad-header-title">公告详情</text>
        <view class="ad-header-right"></view>
      </view>
    </view>

    <scroll-view scroll-y class="ad-scroll">
      <view v-if="loading" class="ad-loading">加载中...</view>
      <view v-else-if="!detail" class="ad-loading">
        <MIcon name="megaphone" :size="44" color="#c6d2e0" />
        <text class="ad-empty">公告不存在或已下架</text>
      </view>
      <view v-else class="ad-card">
        <view class="ad-title">{{ detail.title }}</view>
        <view class="ad-meta">
          <text class="ad-cat" :class="'cat-' + detail.category_color">{{ detail.category_text }}</text>
          <text class="ad-time">{{ detail.published_at_text }}</text>
          <text v-if="detail.publisher_name" class="ad-author">发布：{{ detail.publisher_name }}</text>
        </view>
        <view class="ad-divider"></view>
        <rich-text class="ad-content" :nodes="detail.content || ''"></rich-text>
        <view class="ad-footer">— 数智管控平台 —</view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { request } from '@/utils/request'

const detail = ref(null)
const loading = ref(true)

async function load(id) {
  loading.value = true
  try {
    const r = await request({ url: '/api/mobile/announcement/detail', method: 'GET', data: { id } })
    detail.value = r.data || null
  } catch (e) {
    detail.value = null
  } finally {
    loading.value = false
  }
}

function goBack() {
  uni.navigateBack({ fail: () => uni.reLaunch({ url: '/pages/announcement/index' }) })
}

onLoad((opt) => load(opt.id))
</script>

<style scoped>
.ad-page { min-height: 100vh; background: #f3f5f9; display: flex; flex-direction: column; }
.ad-header { background: linear-gradient(135deg, #4F46E5 0%, #7C3AED 100%); padding: 24rpx 30rpx 30rpx; }
.ad-header-top { display: flex; align-items: center; }
.ad-header-left { width: 60rpx; height: 60rpx; display: flex; align-items: center; }
.ad-header-title { flex: 1; text-align: center; font-size: 34rpx; font-weight: 600; color: #fff; }
.ad-header-right { width: 60rpx; }
.ad-scroll { flex: 1; padding: 24rpx; }
.ad-loading { text-align: center; padding: 100rpx 0; color: #8a9aa8; }
.ad-empty { display: block; margin-top: 16rpx; font-size: 28rpx; color: #5b6472; }
.ad-card { background: #fff; border-radius: 24rpx; padding: 40rpx 32rpx; box-shadow: 0 6rpx 18rpx rgba(80,80,140,0.06); }
.ad-title { font-size: 36rpx; font-weight: 600; color: #1f2733; line-height: 1.5; }
.ad-meta { display: flex; align-items: center; margin-top: 20rpx; flex-wrap: wrap; }
.ad-cat { padding: 4rpx 16rpx; border-radius: 8rpx; font-size: 22rpx; color: #4F46E5; background: rgba(79,70,229,0.1); margin-right: 16rpx; }
.ad-cat.cat-danger { color: #F56C6C; background: rgba(245,108,108,0.1); }
.ad-cat.cat-warning { color: #E6A23C; background: rgba(230,162,60,0.12); }
.ad-cat.cat-info { color: #409EFF; background: rgba(64,158,255,0.1); }
.ad-time { font-size: 24rpx; color: #a0aab8; }
.ad-author { font-size: 24rpx; color: #a0aab8; margin-left: 16rpx; }
.ad-divider { height: 1px; background: #eef1f6; margin: 30rpx 0; }
.ad-content { font-size: 30rpx; color: #3a4254; line-height: 1.8; word-break: break-all; }
.ad-footer { text-align: center; color: #c0cedc; font-size: 24rpx; margin-top: 50rpx; }
</style>
