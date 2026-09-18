<template>
  <view class="ins-list-page">

    <!-- 状态 Tab -->
    <view class="tabs">
      <view v-for="tab in tabs" :key="tab.value" class="tab-item" :class="{active: activeTab === tab.value}" @click="switchTab(tab.value)">
        {{ tab.label }}
      </view>
    </view>

    <!-- 任务列表 -->
    <scroll-view class="ins-scroll" scroll-y :refresher-enabled="true" :refresher-triggered="refreshing" @refresherrefresh="onRefresh" @scrolltolower="loadMore">
      <view v-for="task in list" :key="task.id" class="ins-card" @click="openTask(task)">
        <view class="card-header">
          <text class="device-name">{{ task.device_name || '未知设备' }}</text>
          <text v-if="task.is_overdue" class="overdue-tag">逾期</text>
        </view>
        <view class="device-code">{{ task.device_code }}</view>
        <view class="card-info">
          <text class="task-code">{{ task.task_code }}</text>
          <text class="exec-date">计划：{{ task.plan_execute_date }}</text>
        </view>
        <view class="card-footer">
          <text class="status-text" :class="'st-' + task.status">{{ task.status_text }}</text>
          <text class="action-btn" :class="{completed: task.status === 'completed'}">{{ task.status === 'completed' ? '查看记录' : '去巡检' }}</text>
        </view>
      </view>

      <u-empty v-if="!list.length && !loading" text="暂无巡检任务" mode="list" />
      <view v-if="loading" class="loading">加载中...</view>
      <view v-if="finished && list.length" class="finished">没有更多了</view>
    </scroll-view>
  </view>
</template>

<script>
import { getInspectionTasks } from '../../../api/index.js'

export default {
  data() {
    return {
      tabs: [
        { label: '待巡检', value: 'pending' },
        { label: '巡检中', value: 'in_progress' },
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
        const r = await getInspectionTasks(this.activeTab, this.page, this.limit)
        const data = (r && r.data) || {}
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
        uni.navigateTo({ url: '/pages/sub/inspection/record-list' })
      } else {
        uni.navigateTo({ url: '/pages/sub/inspection/execute?task_id=' + task.id })
      }
    }
  }
}
</script>

<style scoped>
.ins-list-page { min-height: 100vh; background: #F4F6FB; }
.tabs { display: flex; gap: 8px; padding: 12px 16px; }
.tab-item { flex: 1; text-align: center; padding: 9px 0; background: #fff; border-radius: 22px; font-size: 14px; color: #6b7280; border: 1px solid #E7ECF4; }
.tab-item.active { background: linear-gradient(135deg, #4F46E5, #7c6cf0); color: #fff; border-color: transparent; box-shadow: 0 6rpx 18rpx rgba(79,70,229,0.25); }
.ins-scroll { height: calc(100vh - 110px); padding: 12px 16px; box-sizing: border-box; }
.ins-card { background: #fff; border-radius: 16px; padding: 14px 16px; margin-bottom: 10px; box-shadow: 0 4rpx 16rpx rgba(17,24,39,0.04); }
.card-header { display: flex; align-items: center; justify-content: space-between; }
.device-name { font-size: 16px; font-weight: 700; color: #1a2332; }
.overdue-tag { font-size: 11px; color: #e74c5e; background: #fdecea; padding: 2px 10px; border-radius: 20px; }
.device-code { font-size: 12px; color: #9ca3af; margin-top: 4px; }
.card-info { display: flex; align-items: center; justify-content: space-between; margin-top: 8px; }
.task-code { font-size: 12px; color: #4F46E5; background: #f0f4ff; padding: 2px 10px; border-radius: 20px; }
.exec-date { font-size: 12px; color: #9ca3af; }
.card-footer { display: flex; align-items: center; justify-content: space-between; margin-top: 10px; padding-top: 10px; border-top: 1px dashed #EEF2F7; }
.status-text { font-size: 13px; color: #9ca3af; }
.st-in_progress { color: #f59e0b; }
.st-completed { color: #34c759; }
.action-btn { font-size: 13px; font-weight: 600; color: #4F46E5; }
.action-btn.completed { color: #34c759; }
.loading, .finished { text-align: center; color: #b0c0cc; font-size: 12px; padding: 14px 0; }
</style>
