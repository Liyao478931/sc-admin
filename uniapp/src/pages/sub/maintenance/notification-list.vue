<template>
  <view class="notification-page">
    <scroll-view scroll-y class="notify-scroll" :refresher-enabled="true" :refresher-triggered="refreshing" @refresherrefresh="onRefresh" @scrolltolower="loadMore">
      <!-- 顶部操作 -->
      <view class="notify-top-bar"><view class="nav-clear" @click="markAll">全部已读</view></view>
      <view v-for="n in list" :key="n.id" class="notify-item" :class="{unread: !n.is_read}" @click="markRead(n)">
        <view class="notify-title">
          <text class="dot" v-if="!n.is_read"></text>
          <text class="title-text">{{ n.title }}</text>
          <text class="type-tag">{{ typeText(n.notify_type) }}</text>
        </view>
        <view class="notify-content">{{ n.content }}</view>
        <view class="notify-time">{{ n.create_time }}</view>
      </view>
<u-empty v-if="!list.length && !loading" text="暂无通知" mode="list" />
      <view v-if="loading" class="loading">加载中...</view>
      <view v-if="finished && list.length" class="finished">没有更多了</view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref } from 'vue'
import { onLoad, onShow } from '@dcloudio/uni-app'
import { getMaintenanceNotifications, markNotificationRead, getNotificationUnreadCount } from '../../../api/index.js'

const list = ref([])
const page = ref(1)
const limit = 10
const total = ref(0)
const finished = ref(false)
const loading = ref(false)
const refreshing = ref(false)

function typeText(t) {
  return { task_assign: '分配', remind: '提醒', overdue: '逾期', verify_result: '验收' }[t] || t
}

async function loadList(reset = false) {
  if (loading.value) return
  if (reset) { page.value = 1; finished.value = false }
  loading.value = true
  try {
    const r = await getMaintenanceNotifications(page.value, limit)
    const data = r.data || {}
    if (reset) list.value = data.list || []
    else list.value = list.value.concat(data.list || [])
    total.value = data.total || 0
    if (list.value.length >= total.value) finished.value = true
  } catch (e) { uni.showToast({ title: '加载失败', icon: 'none' }) }
  loading.value = false
  refreshing.value = false
}

async function markRead(n) {
  if (n.is_read) return
  await markNotificationRead(n.id)
  n.is_read = 1
}

async function markAll() {
  await markNotificationRead(0, 1)
  list.value.forEach(n => { n.is_read = 1 })
  uni.showToast({ title: '已全部已读', icon: 'success' })
}

function onRefresh() { refreshing.value = true; loadList(true) }
function loadMore() { if (!finished.value) { page.value++; loadList() } }

onLoad(() => loadList(true))
onShow(() => { getNotificationUnreadCount() })
</script>

<style scoped>
.notification-page { min-height: 100vh; background: #f5f6fa; }
.notify-top-bar { padding: 8px 24px; background: #fff; border-bottom: 1rpx solid #eee; }
.nav-clear { font-size: 26rpx; color: #409EFF; text-align: right; }
.notify-scroll { height: calc(100vh - 120rpx); padding: 16rpx 24rpx; box-sizing: border-box; }
.notify-item { background: #fff; border-radius:16rpx; padding: 24rpx; margin-bottom: 16rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.notify-item.unread { border-left: 6rpx solid #409EFF; }
.notify-title { display: flex; align-items: center; }
.dot { width: 14rpx; height: 14rpx; background: #F56C6C; border-radius:50%; margin-right: 8rpx; }
.title-text { font-size: 30rpx; font-weight: 600; flex: 1; }
.type-tag { font-size: 22rpx; color: #409EFF; background: #ecf5ff; padding: 4rpx 12rpx; border-radius:8rpx; }
.notify-content { font-size: 26rpx; color: #606266; margin-top: 12rpx; line-height: 1.5; }
.notify-time { font-size: 22rpx; color: #909399; margin-top: 12rpx; }
.empty { text-align: center; padding: 120rpx 0; }
.empty-icon { font-size: 80rpx; display: block; }
.empty-text { color: #909399; font-size: 28rpx; }
.loading, .finished { text-align: center; color: #909399; font-size: 26rpx; padding: 24rpx; }
</style>
