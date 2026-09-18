<template>
  <view class="accident-list-page">
    <!-- 状态 Tab -->
    <view class="tabs">
      <view v-for="tab in tabs" :key="tab.value" class="tab-item" :class="{ active: activeTab === tab.value }" @click="switchTab(tab.value)">
        {{ tab.label }}
      </view>
    </view>

    <!-- 列表 -->
    <scroll-view class="list-scroll" scroll-y :refresher-enabled="true" :refresher-triggered="refreshing" @refresherrefresh="onRefresh" @scrolltolower="loadMore">
      <view v-for="item in list" :key="item.id" class="card" @click="goDetail(item)">
        <view class="card-top">
          <text class="code">{{ item.accident_code }}</text>
          <text class="status-tag" :class="item.status">{{ item.status_text }}</text>
        </view>
        <view class="card-name">{{ item.accident_name }}</view>
        <view class="card-line">
          <text class="tag type">{{ item.type_text }}</text>
          <text class="tag level">{{ item.level_text }}</text>
          <text class="time">{{ item.happen_time }}</text>
        </view>
        <view class="card-arrow">›</view>
      </view>

      <view v-if="!list.length && !loading" class="empty">
        <text class="empty-text">暂无上报记录</text>
        <text class="empty-tip">发现事故请及时上报</text>
      </view>
      <view v-if="loading" class="loading">加载中...</view>
      <view v-if="finished && list.length" class="finished">没有更多了</view>
    </scroll-view>
  </view>
</template>

<script>
import { getMyAccidents } from '@/api/modules/safety.js'

export default {
  data() {
    return {
      tabs: [
        { label: '全部', value: '' },
        { label: '草稿', value: 'draft' },
        { label: '待调查', value: 'pending' },
        { label: '调查中', value: 'investigating' },
        { label: '已结案', value: 'closed' },
        { label: '已归档', value: 'archived' },
      ],
      activeTab: '',
      list: [], page: 1, limit: 10, total: 0, finished: false,
      loading: false, refreshing: false,
    }
  },
  onLoad() { this.loadList(true) },
  onShow() { if (this._loaded) this.loadList(true); this._loaded = true },
  methods: {
    async loadList(reset = false) {
      if (this.loading) return
      if (reset) { this.page = 1; this.finished = false }
      this.loading = true
      try {
        const r = await getMyAccidents(this.activeTab, this.page, this.limit)
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
    goDetail(item) {
      uni.navigateTo({ url: '/pages/sub/safety/accident-detail?accident_id=' + item.id })
    },
  },
}
</script>

<style scoped>
.accident-list-page { min-height: 100vh; background: #f5f6fa; }
.tabs { display: flex; background: #fff; padding: 16rpx 0; overflow-x: auto; }
.tab-item { flex-shrink: 0; padding: 16rpx 28rpx; font-size: 26rpx; color: #909399; }
.tab-item.active { color: #409EFF; font-weight: 600; border-bottom: 4rpx solid #409EFF; }
.list-scroll { height: calc(100vh - 100rpx); padding: 16rpx 24rpx; box-sizing: border-box; }
.card { background: #fff; border-radius:16rpx; padding: 24rpx; margin-bottom: 16rpx; position: relative; box-shadow: 0 2rpx 8rpx rgba(0,0,0,.05); }
.card-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 10rpx; }
.code { font-size: 24rpx; color: #909399; }
.status-tag { font-size: 22rpx; padding: 4rpx 14rpx; border-radius:8rpx; }
.status-tag.draft { background: #f4f4f5; color: #909399; }
.status-tag.pending { background: #fdf6ec; color: #E6A23C; }
.status-tag.investigating { background: #ecf5ff; color: #409EFF; }
.status-tag.closed { background: #f0f9eb; color: #67C23A; }
.status-tag.archived { background: #f4f4f5; color: #909399; }
.card-name { font-size: 30rpx; font-weight: 600; color: #303133; margin-bottom: 10rpx; }
.card-line { display: flex; align-items: center; gap: 12rpx; }
.tag { font-size: 22rpx; padding: 2rpx 12rpx; border-radius:6rpx; }
.tag.type { background: #ecf5ff; color: #409EFF; }
.tag.level { background: #fdf6ec; color: #E6A23C; }
.time { font-size: 22rpx; color: #909399; }
.card-arrow { position: absolute; right: 24rpx; top: 50%; transform: translateY(-50%); font-size: 36rpx; color: #c0c4cc; }
.empty { text-align: center; padding: 140rpx 0; }
.empty-text { display: block; color: #909399; font-size: 30rpx; }
.empty-tip { display: block; color: #c0c4cc; font-size: 24rpx; margin-top: 10rpx; }
.loading, .finished { text-align: center; color: #909399; font-size: 26rpx; padding: 24rpx; }
</style>
