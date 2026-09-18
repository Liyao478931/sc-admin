<template>
  <view class="ins-rec-page">
    <scroll-view scroll-y class="rec-scroll" :refresher-enabled="true" :refresher-triggered="refreshing" @refresherrefresh="onRefresh" @scrolltolower="loadMore">
      <view v-for="rec in list" :key="rec.id" class="rec-card" @click="openRecord(rec)">
        <view class="rec-head">
          <text class="rec-code">{{ rec.record_code }}</text>
          <text class="rec-result" :class="{abnormal: rec.result === 'abnormal'}">{{ rec.result_text }}</text>
        </view>
        <view class="rec-device">{{ rec.device_name || '未知设备' }} <text class="rec-gray">{{ rec.device_code }}</text></view>
        <view class="rec-info">
          <text class="rec-time">{{ rec.execute_time }}</text>
          <text class="rec-audit" :class="'au-' + rec.audit_status">{{ rec.audit_status_text }}</text>
        </view>
        <view v-if="rec.abnormal_count > 0" class="rec-warn">异常 {{ rec.abnormal_count }}/{{ rec.total_count }} 项</view>
      </view>

      <u-empty v-if="!list.length && !loading" text="暂无巡检记录" mode="list" />
      <view v-if="loading" class="loading">加载中...</view>
      <view v-if="finished && list.length" class="finished">没有更多了</view>
    </scroll-view>
  </view>
</template>

<script>
import { getInspectionRecords } from '../../../api/index.js'

export default {
  data() {
    return {
      list: [], page: 1, limit: 10, total: 0, finished: false,
      loading: false, refreshing: false
    }
  },
  onLoad() { this.loadList(true) },
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
        const r = await getInspectionRecords(this.page, this.limit)
        const data = (r && r.data) || {}
        if (reset) this.list = data.list || []
        else this.list = this.list.concat(data.list || [])
        this.total = data.total || 0
        if (this.list.length >= this.total) this.finished = true
      } catch (e) { uni.showToast({ title: '加载失败', icon: 'none' }) }
      this.loading = false
      this.refreshing = false
    },
    onRefresh() { this.refreshing = true; this.loadList(true) },
    loadMore() { if (!this.finished) { this.page++; this.loadList() } },
    openRecord(rec) {
      uni.navigateTo({ url: '/pages/sub/inspection/record-detail?record_id=' + rec.id })
    }
  }
}
</script>

<style scoped>
.ins-rec-page { min-height: 100vh; background: #F4F6FB; }
.rec-scroll { height: 100vh; padding: 12px 16px; box-sizing: border-box; }
.rec-card { background: #fff; border-radius: 16px; padding: 14px 16px; margin-bottom: 10px; box-shadow: 0 4rpx 16rpx rgba(17,24,39,0.04); }
.rec-head { display: flex; align-items: center; justify-content: space-between; }
.rec-code { font-size: 14px; font-weight: 700; color: #1a2332; }
.rec-result { font-size: 12px; font-weight: 600; color: #1f9d55; background: #eafaf0; padding: 2px 12px; border-radius: 20px; }
.rec-result.abnormal { color: #e74c5e; background: #fdecea; }
.rec-device { font-size: 14px; color: #4a5568; margin-top: 8px; }
.rec-gray { font-size: 12px; color: #9ca3af; margin-left: 6px; }
.rec-info { display: flex; align-items: center; justify-content: space-between; margin-top: 8px; }
.rec-time { font-size: 12px; color: #9ca3af; }
.rec-audit { font-size: 12px; color: #f59e0b; background: #fef3e2; padding: 2px 10px; border-radius: 20px; }
.rec-audit.au-approved { color: #1f9d55; background: #eafaf0; }
.rec-audit.au-rejected { color: #e74c5e; background: #fdecea; }
.rec-warn { margin-top: 8px; font-size: 12px; color: #e74c5e; }
.loading, .finished { text-align: center; color: #b0c0cc; font-size: 12px; padding: 14px 0; }
</style>
