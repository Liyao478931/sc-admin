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
      <RepairTaskCard v-for="task in list" :key="task.id" :order="task" @click="openTask(task)" />

<u-empty v-if="!list.length && !loading" text="暂无维修任务" mode="list" />
      <view v-if="loading" class="loading">加载中...</view>
      <view v-if="finished && list.length" class="finished">没有更多了</view>
    </scroll-view>
  </view>
</template>

<script>
import { getRepairTasks, getDeviceRepairTasks } from '../../../api/index.js'
import RepairTaskCard from './components/RepairTaskCard.vue'

export default {
  components: { RepairTaskCard },
  data() {
    return {
      tabs: [
        { label: '待维修', value: 'assigned' },
        { label: '维修中', value: 'repairing' },
        { label: '待验收', value: 'accepted' }
      ],
      activeTab: 'assigned',
      list: [], page: 1, limit: 10, total: 0, finished: false,
      loading: false, refreshing: false, scanDeviceCode: null
    }
  },
  onLoad(options) {
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
        if (this.scanDeviceCode) {
          // 扫码带设备编码：查该设备待维修工单
          const r = await getDeviceRepairTasks(this.scanDeviceCode)
          this.list = (r.data && r.data.list) || []
          this.total = this.list.length
          this.finished = true
          this.scanDeviceCode = null
        } else {
          const r = await getRepairTasks(this.activeTab, this.page, this.limit)
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
      uni.navigateTo({ url: '/pages/sub/repair/execute?task_id=' + task.id })
    },
    // 扫码入口：扫码 → 查设备待维修工单 → 一条直接进执行页，多条进列表筛选
    scanCode() {
      uni.scanCode({
        scanType: ['qrCode'],
        success: (res) => {
          let code = res.result || ''
          if (code.includes('/')) code = code.split('/').pop().split('?')[0]
          if (!code) { uni.showToast({ title: '二维码无效', icon: 'none' }); return }
          uni.showLoading({ title: '查询中' })
          getDeviceRepairTasks(code).then((r) => {
            uni.hideLoading()
            const list = (r.data && r.data.list) || []
            if (!list.length) { uni.showToast({ title: '该设备暂无待维修工单', icon: 'none' }); return }
            if (list.length === 1) {
              uni.navigateTo({ url: '/pages/sub/repair/execute?task_id=' + list[0].id })
            } else {
              uni.navigateTo({ url: '/pages/sub/repair/task-list?device_code=' + encodeURIComponent(code) })
            }
          }).catch(() => { uni.hideLoading(); uni.showToast({ title: '查询失败', icon: 'none' }) })
        },
        fail: () => uni.showToast({ title: '扫描失败，请重新扫描', icon: 'none' })
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
.empty { text-align: center; padding: 120rpx 0; }
.empty-icon { font-size: 80rpx; display: block; }
.empty-text { color: #909399; font-size: 28rpx; }
.loading, .finished { text-align: center; color: #909399; font-size: 26rpx; padding: 24rpx; }
</style>
