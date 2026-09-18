<template>
  <view class="my-training-page">
    <!-- 状态 Tab -->
    <view class="tabs">
      <view v-for="tab in tabs" :key="tab.value" class="tab-item" :class="{active: activeTab === tab.value}" @click="switchTab(tab.value)">
        {{ tab.label }}
      </view>
    </view>

    <!-- 培训列表 -->
    <scroll-view class="task-scroll" scroll-y :refresher-enabled="true" :refresher-triggered="refreshing" @refresherrefresh="onRefresh" @scrolltolower="loadMore">
      <view v-for="item in list" :key="item.id" class="train-card">
        <view class="card-header">
          <text class="train-name">{{ item.plan_name }}</text>
          <text class="mode-tag" :class="item.is_online === 1 ? 'online' : 'offline'">{{ item.mode_text }}</text>
        </view>
        <view class="card-info">
          <text class="type-text">{{ item.training_type_name }}</text>
          <text class="date-text">{{ item.training_date || '-' }}</text>
        </view>
        <view class="card-footer">
          <text class="status-text" :class="item.status === 'completed' ? 'done' : 'todo'">{{ item.status_text }}</text>
          <text v-if="item.status !== 'completed'" class="action-btn" @click="openDetail(item)">{{ item.is_online === 1 ? '继续学习' : '签到' }}</text>
          <text v-else class="action-btn done" @click="openDetail(item)">查看</text>
        </view>
      </view>

      <view v-if="!list.length && !loading" class="empty">
        <MIcon name="graduate" :size="44" color="#c6d2e0" />
        <text class="empty-text">暂无培训</text>
      </view>
      <view v-if="loading" class="loading">加载中...</view>
      <view v-if="finished && list.length" class="finished">没有更多了</view>
    </scroll-view>
  </view>
</template>

<script>
import { getMyTrainingList } from '../../../api/index.js'

export default {
  data() {
    return {
      tabs: [
        { label: '待执行', value: 'pending' },
        { label: '已完成', value: 'completed' }
      ],
      activeTab: 'pending',
      list: [], page: 1, limit: 10, total: 0, finished: false,
      loading: false, refreshing: false
    }
  },
  onLoad(options) {
    if (options.status) this.activeTab = options.status
    this.loadList(true)
  },
  onShow() {
    if (this._loaded) this.loadList(true)
    this._loaded = true
  },
  methods: {
    async loadList(reset = false) {
      if (this.loading) return
      if (reset) { this.page = 1; this.finished = false }
      this.loading = true
      try {
        const r = await getMyTrainingList(this.activeTab, this.page, this.limit)
        const data = r.data || {}
        if (reset) this.list = data.list || []
        else this.list = this.list.concat(data.list || [])
        this.total = data.total || 0
        if (this.list.length >= this.total) this.finished = true
      } catch (e) { uni.showToast({ title: '加载失败', icon: 'none' }) }
      this.loading = false
      this.refreshing = false
    },
    switchTab(tab) { this.activeTab = tab; this.loadList(true) },
    onRefresh() { this.refreshing = true; this.loadList(true) },
    loadMore() { if (!this.finished) { this.page++; this.loadList() } },
    openDetail(item) {
      uni.navigateTo({ url: '/pages/sub/safety/training-detail?record_id=' + item.id })
    }
  }
}
</script>

<style scoped>
.my-training-page { min-height: 100vh; background: #f5f6fa; }
.tabs { display: flex; background: #fff; padding: 16rpx 0; }
.tab-item { flex: 1; text-align: center; padding: 16rpx 0; font-size: 28rpx; color: #909399; }
.tab-item.active { color: #409EFF; font-weight: 600; border-bottom: 4rpx solid #409EFF; }
.task-scroll { height: calc(100vh - 120rpx); padding: 16rpx 24rpx; box-sizing: border-box; }
.train-card { background: #fff; border-radius:16rpx; padding: 24rpx; margin-bottom: 16rpx; box-shadow: 0 2rpx 8rpx rgba(0,0,0,.05); }
.card-header { display: flex; align-items: center; justify-content: space-between; }
.train-name { font-size: 32rpx; font-weight: 600; color: #303133; flex: 1; }
.mode-tag { font-size: 22rpx; padding: 4rpx 12rpx; border-radius:8rpx; }
.mode-tag.online { background: #ecf5ff; color: #409EFF; }
.mode-tag.offline { background: #f0f9eb; color: #67C23A; }
.card-info { display: flex; align-items: center; margin-top: 14rpx; }
.type-text { font-size: 24rpx; color: #606266; }
.date-text { font-size: 24rpx; color: #909399; margin-left: 16rpx; }
.card-footer { display: flex; align-items: center; justify-content: space-between; margin-top: 16rpx; }
.status-text { font-size: 26rpx; }
.status-text.done { color: #67C23A; }
.status-text.todo { color: #409EFF; }
.action-btn { font-size: 26rpx; color: #fff; background: #409EFF; padding: 8rpx 24rpx; border-radius:24rpx; }
.action-btn.done { background: #67C23A; }
.empty { text-align: center; padding: 120rpx 0; }
.empty-icon { font-size: 80rpx; display: block; }
.empty-text { color: #909399; font-size: 28rpx; }
.loading, .finished { text-align: center; color: #909399; font-size: 26rpx; padding: 24rpx; }
</style>
