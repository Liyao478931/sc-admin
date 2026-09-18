<template>
  <view class="safety-task-page">
    <!-- 状态 Tab：全部 / 待执行 / 逾期 -->
    <view class="tabs">
      <view v-for="tab in tabs" :key="tab.value" class="tab-item" :class="{active: activeTab === tab.value}" @click="switchTab(tab.value)">
        {{ tab.label }}
      </view>
    </view>

    <!-- 任务列表 -->
    <scroll-view class="task-scroll" scroll-y :refresher-enabled="true" :refresher-triggered="refreshing" @refresherrefresh="onRefresh" @scrolltolower="loadMore">
      <view v-for="task in list" :key="task.id" class="task-card" @click="openTask(task)">
        <view class="card-header">
          <text class="task-code">{{ task.task_code }}</text>
          <text v-if="task.is_overdue" class="overdue-tag">逾期</text>
        </view>
        <view class="plan-name">{{ task.plan_name || '检查计划' }}</view>
        <view class="card-info">
          <text class="type-tag">{{ task.inspection_type_name || '检查' }}</text>
          <text class="area-text">{{ task.area || '—' }}</text>
        </view>
        <view class="card-footer">
          <text class="exec-date">计划：{{ task.plan_execute_date }}</text>
          <text class="action-btn">去执行</text>
        </view>
      </view>

      <view v-if="!list.length && !loading" class="empty">
        <MIcon name="clipboard" :size="44" color="#c6d2e0" />
        <text class="empty-text">暂无检查任务</text>
      </view>
      <view v-if="loading" class="loading">加载中...</view>
      <view v-if="finished && list.length" class="finished">没有更多了</view>
    </scroll-view>
  </view>
</template>

<script>
import { getSafetyTasks } from '../../../api/index.js'

export default {
  data() {
    return {
      tabs: [
        { label: '全部', value: 'all' },
        { label: '待执行', value: 'pending' },
        { label: '逾期', value: 'overdue' },
        { label: '已完成', value: 'completed' }
      ],
      activeTab: 'all',
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
    goBack() { uni.navigateBack({ fail: () => uni.switchTab({ url: '/pages/workbench/index' }) }) },
    async loadList(reset = false) {
      if (this.loading) return
      if (reset) { this.page = 1; this.finished = false }
      this.loading = true
      try {
        const status = this.activeTab === 'all' ? '' : this.activeTab
        const r = await getSafetyTasks(status, this.page, this.limit)
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
    openTask(task) {
      if (task.status === 'completed') {
        // 查看已完成任务的检查记录详情
        uni.navigateTo({ url: '/pages/sub/safety/record-detail?record_id=' + task.id })
      } else {
        uni.navigateTo({ url: '/pages/sub/safety/execute?task_id=' + task.id })
      }
    }
  }
}
</script>

<style scoped>
.safety-task-page { min-height: 100vh; background: #f5f6fa; }
.tabs { display: flex; background: #fff; padding: 16rpx 0; }
.tab-item { flex: 1; text-align: center; padding: 16rpx 0; font-size: 28rpx; color: #909399; }
.tab-item.active { color: #409EFF; font-weight: 600; border-bottom: 4rpx solid #409EFF; }
.task-scroll { height: calc(100vh - 120rpx); padding: 16rpx 24rpx; box-sizing: border-box; }
.task-card { background: #fff; border-radius:16rpx; padding: 24rpx; margin-bottom: 16rpx; box-shadow: 0 2rpx 8rpx rgba(0,0,0,.05); }
.card-header { display: flex; align-items: center; justify-content: space-between; }
.task-code { font-size: 26rpx; color: #409EFF; font-weight: 600; }
.overdue-tag { background: #F56C6C; color: #fff; font-size: 22rpx; padding: 4rpx 12rpx; border-radius:8rpx; }
.plan-name { font-size: 32rpx; font-weight: 600; color: #303133; margin-top: 12rpx; }
.card-info { display: flex; align-items: center; margin-top: 16rpx; }
.type-tag { background: #ecf5ff; color: #409EFF; font-size: 24rpx; padding: 4rpx 12rpx; border-radius:8rpx; }
.area-text { font-size: 24rpx; color: #606266; margin-left: 16rpx; }
.card-footer { display: flex; align-items: center; justify-content: space-between; margin-top: 16rpx; }
.exec-date { font-size: 24rpx; color: #909399; }
.action-btn { font-size: 26rpx; color: #fff; background: #409EFF; padding: 8rpx 24rpx; border-radius:24rpx; }
.empty { text-align: center; padding: 120rpx 0; }
.empty-icon { font-size: 80rpx; display: block; }
.empty-text { color: #909399; font-size: 28rpx; }
.loading, .finished { text-align: center; color: #909399; font-size: 26rpx; padding: 24rpx; }
</style>
