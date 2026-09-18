<template>
  <view class="ann-page">
    <!-- 顶部渐变标题栏 -->
    <view class="ann-header">
      <view class="ann-header-top">
        <view class="ann-header-left" @click="goBack">
          <MIcon name="chevron-left" :size="22" color="#ffffff" />
        </view>
        <text class="ann-header-title">公告中心</text>
        <view class="ann-header-right"></view>
      </view>
      <view class="ann-header-sub">
        <text class="ann-sub-title">企业资讯 · 通知 · 活动</text>
      </view>
    </view>

    <!-- 分类筛选 -->
    <scroll-view scroll-x class="ann-tabs">
      <view v-for="t in tabs" :key="t.value" class="ann-tab" :class="{ active: activeTab === t.value }" @click="switchTab(t.value)">
        <text>{{ t.label }}</text>
      </view>
    </scroll-view>

    <!-- 列表 -->
    <scroll-view scroll-y class="ann-list" :refresher-enabled="true" :refresher-triggered="refreshing" @refresherrefresh="onRefresh" @scrolltolower="loadMore">
      <view v-if="loading && !list.length" class="ann-status"><text>加载中...</text></view>
      <view v-else-if="!list.length" class="ann-empty">
        <MIcon name="megaphone" :size="44" color="#c6d2e0" />
        <text class="ann-empty-text">暂无公告</text>
        <text class="ann-empty-tip">新的通知发布后将在这里展示</text>
      </view>
      <view v-else class="ann-cards">
        <view v-for="a in list" :key="a.id" class="ann-card" :class="'cat-' + a.category" @click="goDetail(a)">
          <view class="ann-card-left">
            <view class="ann-cat-badge" :class="'badge-' + a.category_color">
              <text>{{ a.category_text }}</text>
            </view>
          </view>
          <view class="ann-card-mid">
            <view class="ann-title-row">
              <text v-if="a.is_top == 1" class="ann-top-tag">置顶</text>
              <text class="ann-title">{{ a.title }}</text>
            </view>
            <view class="ann-meta">
              <text class="ann-time">{{ a.published_at_text }}</text>
              <text v-if="a.publisher_name" class="ann-author">{{ a.publisher_name }}</text>
            </view>
          </view>
          <view class="ann-card-right">
            <MIcon name="chevron-right" :size="16" color="#c0cedc" />
          </view>
        </view>
      </view>
      <view v-if="finished && list.length" class="ann-finished">没有更多了</view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref } from 'vue'
import { onLoad, onPullDownRefresh } from '@dcloudio/uni-app'
import { request } from '@/utils/request'

const tabs = [
  { label: '全部', value: '' },
  { label: '通知', value: 'notice' },
  { label: '紧急', value: 'urgent' },
  { label: '活动', value: 'activity' },
]
const activeTab = ref('')
const list = ref([])
const loading = ref(false)
const refreshing = ref(false)
const finished = ref(false)
const page = ref(1)
const pageSize = 10

async function load(append = false) {
  if (loading.value) return
  loading.value = true
  try {
    const r = await request({ url: '/api/mobile/announcement/list', method: 'GET', data: { page: page.value, limit: pageSize, category: activeTab.value } })
    const data = r.data || {}
    const rows = data.list || []
    list.value = append ? list.value.concat(rows) : rows
    finished.value = list.value.length >= (data.total || 0)
  } catch (e) {
    uni.showToast({ title: '公告加载失败', icon: 'none' })
  } finally {
    loading.value = false
    refreshing.value = false
  }
}

function switchTab(v) {
  if (activeTab.value === v) return
  activeTab.value = v
  page.value = 1
  finished.value = false
  load()
}

function onRefresh() {
  page.value = 1
  load()
}

function loadMore() {
  if (finished.value || loading.value) return
  page.value += 1
  load(true)
}

function goDetail(a) {
  uni.navigateTo({ url: '/pages/announcement/detail?id=' + a.id })
}

function goBack() {
  uni.navigateBack({ fail: () => uni.reLaunch({ url: '/pages/diy/index?type=home' }) })
}

onLoad(() => load())
</script>

<style scoped>
.ann-page { min-height: 100vh; background: #f3f5f9; display: flex; flex-direction: column; }
.ann-header { background: linear-gradient(135deg, #4F46E5 0%, #7C3AED 100%); padding: 24rpx 30rpx 40rpx; }
.ann-header-top { display: flex; align-items: center; }
.ann-header-left { width: 60rpx; height: 60rpx; display: flex; align-items: center; }
.ann-header-title { flex: 1; text-align: center; font-size: 34rpx; font-weight: 600; color: #fff; }
.ann-header-right { width: 60rpx; }
.ann-header-sub { text-align: center; margin-top: 10rpx; }
.ann-sub-title { font-size: 24rpx; color: rgba(255,255,255,0.75); }
.ann-tabs { display: flex; white-space: nowrap; background: #fff; padding: 20rpx 24rpx 0; box-shadow: 0 4rpx 12rpx rgba(80,80,140,0.06); }
.ann-tab { display: inline-flex; padding: 12rpx 30rpx; margin-right: 16rpx; border-radius: 999rpx; background: #f1f3f8; color: #5b6472; font-size: 26rpx; transition: all .2s; }
.ann-tab.active { background: linear-gradient(135deg, #4F46E5, #7C3AED); color: #fff; font-weight: 600; box-shadow: 0 6rpx 14rpx rgba(79,70,229,0.3); }
.ann-list { flex: 1; padding: 20rpx 24rpx; }
.ann-status, .ann-empty { text-align: center; padding: 100rpx 0; color: #8a9aa8; }
.ann-empty-text { display: block; margin-top: 16rpx; font-size: 30rpx; color: #5b6472; font-weight: 500; }
.ann-empty-tip { display: block; margin-top: 8rpx; font-size: 24rpx; color: #a0aab8; }
.ann-cards { display: flex; flex-direction: column; }
.ann-card { display: flex; align-items: center; background: #fff; border-radius: 20rpx; padding: 26rpx 24rpx; margin-bottom: 18rpx; box-shadow: 0 4rpx 14rpx rgba(80,80,140,0.05); border-left: 6rpx solid #4F46E5; }
.ann-card.cat-urgent { border-left-color: #F56C6C; }
.ann-card.cat-activity { border-left-color: #E6A23C; }
.ann-card.cat-notice { border-left-color: #409EFF; }
.ann-card-left { margin-right: 20rpx; }
.ann-cat-badge { padding: 6rpx 16rpx; border-radius: 8rpx; font-size: 22rpx; color: #4F46E5; background: rgba(79,70,229,0.1); }
.ann-cat-badge.badge-danger { color: #F56C6C; background: rgba(245,108,108,0.1); }
.ann-cat-badge.badge-warning { color: #E6A23C; background: rgba(230,162,60,0.12); }
.ann-cat-badge.badge-info { color: #409EFF; background: rgba(64,158,255,0.1); }
.ann-card-mid { flex: 1; min-width: 0; }
.ann-title-row { display: flex; align-items: center; }
.ann-top-tag { background: linear-gradient(135deg, #F56C6C, #E64340); color: #fff; font-size: 20rpx; padding: 2rpx 12rpx; border-radius: 6rpx; margin-right: 10rpx; }
.ann-title { font-size: 30rpx; font-weight: 500; color: #2b3242; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.ann-meta { display: flex; align-items: center; margin-top: 12rpx; }
.ann-time { font-size: 24rpx; color: #a0aab8; }
.ann-author { margin-left: 16rpx; font-size: 22rpx; color: #b6c0cc; }
.ann-card-right { margin-left: 12rpx; }
.ann-finished { text-align: center; color: #a0aab8; font-size: 24rpx; padding: 24rpx 0 40rpx; }
</style>
