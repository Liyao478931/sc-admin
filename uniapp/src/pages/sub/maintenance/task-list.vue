<template>
  <view class="task-list-page">

    <!-- 状态 Tab -->
    <view class="tabs">
      <view v-for="tab in tabs" :key="tab.value" class="tab-item" :class="{active: activeTab === tab.value}" @click="switchTab(tab.value)">
        {{ tab.label }}
      </view>
    </view>

    <!-- 任务列表 -->
    <scroll-view class="task-scroll" scroll-y :refresher-enabled="true" :refresher-triggered="refreshing" @refresherrefresh="onRefresh" @scrolltolower="loadMore">
      <view v-for="task in list" :key="task.id" class="task-card" @click="openTask(task)">
        <view class="card-header">
          <text class="device-name">{{ task.device_name || '未知设备' }}</text>
          <text v-if="task.is_overdue" class="overdue-tag">逾期</text>
        </view>
        <view class="device-code">{{ task.device_code }}</view>
        <view class="card-info">
          <text class="level-tag">{{ task.level_name }}</text>
          <text class="exec-date">计划：{{ task.plan_execute_date }}</text>
        </view>
        <view class="card-footer">
          <text class="status-text" :class="'st-' + task.status">{{ task.status_text }}</text>
          <text class="action-btn" :class="{completed: task.status === 'completed'}">{{ task.status === 'completed' ? '查看详情' : '去执行' }}</text>
        </view>
      </view>

<u-empty v-if="!list.length && !loading" text="暂无保养任务" mode="list" />
      <view v-if="loading" class="loading">加载中...</view>
      <view v-if="finished && list.length" class="finished">没有更多了</view>
    </scroll-view>
  </view>
</template>

<script>
import { getMaintenanceTasks, getDeviceMaintenanceTasks } from '../../../api/index.js'

export default {
  data() {
    return {
      tabs: [
        { label: '待执行', value: 'pending' },
        { label: '进行中', value: 'in_progress' },
        { label: '已完成', value: 'completed' }
      ],
      activeTab: 'pending',
      list: [], page: 1, limit: 10, total: 0, finished: false,
      loading: false, refreshing: false, scanDeviceCode: null
    }
  },
  onLoad(options) {
    // 支持扫码后携带 device_code 进入
    if (options.device_code) this.scanDeviceCode = options.device_code
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
        // 扫码带设备编码时查该设备任务
        if (this.scanDeviceCode) {
          const r = await getDeviceMaintenanceTasks(this.scanDeviceCode)
          this.list = (r.data && r.data.list) || []
          this.total = this.list.length
          this.finished = true
          this.scanDeviceCode = null
        } else {
          const r = await getMaintenanceTasks(this.activeTab, this.page, this.limit)
          const data = r.data || {}
          if (reset) this.list = data.list || []
          else this.list = this.list.concat(data.list || [])
          this.total = data.total || 0
          if (this.list.length >= this.total) this.finished = true
        }
      } catch (e) { uni.showToast({ title: '加载失败', icon: 'none' }) }
      this.loading = false
      this.refreshing = false
    },
    switchTab(tab) { this.activeTab = tab; this.loadList(true) },
    onRefresh() { this.refreshing = true; this.loadList(true) },
    loadMore() { if (!this.finished) { this.page++; this.loadList() } },
    openTask(task) {
      if (task.status === 'completed') {
        uni.showToast({ title: '请从记录列表查看详情', icon: 'none' })
      } else {
        uni.navigateTo({ url: '/pages/sub/maintenance/execute?task_id=' + task.id })
      }
    },
    scanCode() {
      uni.scanCode({
        scanType: ['qrCode', 'barCode'],
        success: (res) => {
          const code = res.result || ''
          // 解析设备编码：二维码可能是 URL 或纯编码，提取最后一段
          let deviceCode = code
          if (code.includes('/')) deviceCode = code.split('/').pop().split('?')[0]
          if (!deviceCode) { uni.showToast({ title: '二维码无效', icon: 'none' }); return }
          this.scanDeviceCode = deviceCode
          this.loadList(true)
        },
        fail: () => uni.showToast({ title: '扫描失败', icon: 'none' })
      })
    }
  }
}
</script>

<style scoped>
.task-list-page { min-height: 100vh; background: #f5f6fa; }
.tabs { display: flex; background: #fff; padding: 12rpx 0; }
.tab-item { flex: 1; text-align: center; padding: 16rpx 0; font-size: 28rpx; color: #909399; }
.tab-item.active { color: #409EFF; font-weight: 600; border-bottom: 4rpx solid #409EFF; }
.task-scroll { height: calc(100vh - 176rpx); padding: 16rpx 24rpx; box-sizing: border-box; }
.task-card { background: #fff; border-radius:16rpx; padding: 24rpx; margin-bottom: 16rpx; box-shadow: 0 2rpx 8rpx rgba(0,0,0,.05); }
.card-header { display: flex; align-items: center; justify-content: space-between; }
.device-name { font-size: 32rpx; font-weight: 600; color: #303133; }
.overdue-tag { background: #F56C6C; color: #fff; font-size: 22rpx; padding: 4rpx 12rpx; border-radius:8rpx; }
.device-code { font-size: 24rpx; color: #909399; margin-top: 8rpx; }
.card-info { display: flex; align-items: center; margin-top: 16rpx; }
.level-tag { background: #ecf5ff; color: #409EFF; font-size: 24rpx; padding: 4rpx 12rpx; border-radius:8rpx; }
.exec-date { font-size: 24rpx; color: #606266; margin-left: 16rpx; }
.card-footer { display: flex; align-items: center; justify-content: space-between; margin-top: 16rpx; }
.status-text { font-size: 26rpx; }
.st-pending { color: #409EFF; }
.st-in_progress { color: #E6A23C; }
.st-completed { color: #67C23A; }
.st-overdue { color: #F56C6C; }
.action-btn { font-size: 26rpx; color: #fff; background: #409EFF; padding: 8rpx 24rpx; border-radius:24rpx; }
.action-btn.completed { background: #67C23A; }
.empty { text-align: center; padding: 120rpx 0; }
.empty-icon { font-size: 80rpx; display: block; }
.empty-text { color: #909399; font-size: 28rpx; }
.loading, .finished { text-align: center; color: #909399; font-size: 26rpx; padding: 24rpx; }
</style>
