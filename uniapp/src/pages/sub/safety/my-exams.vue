<template>
  <view class="my-exams-page">
    <!-- 状态 Tab -->
    <view class="tabs">
      <view v-for="tab in tabs" :key="tab.value" class="tab-item" :class="{ active: activeTab === tab.value }" @click="switchTab(tab.value)">
        {{ tab.label }}
      </view>
    </view>

    <!-- 考试列表 -->
    <scroll-view class="exam-scroll" scroll-y :refresher-enabled="true" :refresher-triggered="refreshing" @refresherrefresh="onRefresh" @scrolltolower="loadMore">
      <view v-for="exam in list" :key="exam.id" class="exam-card" @click="openDetail(exam)">
        <view class="card-top">
          <text class="exam-name">{{ exam.exam_name }}</text>
          <text class="type-tag" :class="exam.exam_type === 'formal' ? 'formal' : 'practice'">{{ exam.type_text }}</text>
        </view>
        <view class="card-line">试卷：{{ exam.paper_name }}</view>
        <view class="card-line">时间：{{ exam.start_time }} ~ {{ exam.end_time }}</view>
        <view class="card-line">时长：{{ exam.duration_minutes }} 分钟　题量：{{ exam.total_questions || '-' }}</view>
        <view class="card-bottom">
          <text class="status-tag" :class="exam.status">{{ exam.status_text }}</text>
          <text v-if="exam.status === 'pending'" class="countdown">距开始 {{ countdownText(exam) }}</text>
          <text v-else-if="exam.my_status && exam.my_status.submitted" class="btn done" @click.stop="goResult(exam)">查看成绩</text>
          <text v-else-if="exam.status === 'in_progress'" class="btn start" @click.stop="goDetail(exam)">立即考试</text>
          <text v-else-if="exam.status === 'ended'" class="btn done" @click.stop="goResult(exam)">查看成绩</text>
        </view>
      </view>

      <view v-if="!list.length && !loading" class="empty">
        <text class="empty-text">暂无考试安排</text>
      </view>
      <view v-if="loading" class="loading">加载中...</view>
      <view v-if="finished && list.length" class="finished">没有更多了</view>
    </scroll-view>
  </view>
</template>

<script>
import { getMyExams } from '../../../api/modules/safety.js'

export default {
  data() {
    return {
      tabs: [
        { label: '全部', value: '' },
        { label: '待开始', value: 'pending' },
        { label: '进行中', value: 'in_progress' },
        { label: '已结束', value: 'ended' }
      ],
      activeTab: '',
      list: [], page: 1, limit: 10, total: 0, finished: false,
      loading: false, refreshing: false,
      now: Date.now(), timer: null
    }
  },
  onLoad(options) {
    if (options.status) this.activeTab = options.status
    this.loadList(true)
    // 待开始倒计时（每秒刷新）
    this.timer = setInterval(() => { this.now = Date.now() }, 1000)
  },
  onUnload() {
    if (this.timer) clearInterval(this.timer)
  },
  methods: {
    async loadList(reset = false) {
      if (this.loading) return
      if (reset) { this.page = 1; this.finished = false }
      this.loading = true
      try {
        const r = await getMyExams(this.activeTab, this.page, this.limit)
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
    countdownText(exam) {
      const diff = new Date(exam.start_time).getTime() - this.now
      if (diff <= 0) return '即将开始'
      const d = Math.floor(diff / 86400000)
      const h = Math.floor((diff % 86400000) / 3600000)
      const m = Math.floor((diff % 3600000) / 60000)
      const s = Math.floor((diff % 60000) / 1000)
      return d > 0 ? `${d}天${h}时` : `${h}时${m}分${s}秒`
    },
    openDetail(exam) {
      uni.navigateTo({ url: '/pages/sub/safety/exam-detail?exam_id=' + exam.id })
    },
    goDetail(exam) {
      uni.navigateTo({ url: '/pages/sub/safety/exam-detail?exam_id=' + exam.id })
    },
    goResult(exam) {
      uni.navigateTo({ url: '/pages/sub/safety/exam-result?exam_id=' + exam.id })
    }
  }
}
</script>

<style scoped>
.my-exams-page { min-height: 100vh; background: #f5f6fa; }
.tabs { display: flex; background: #fff; padding: 16rpx 0; }
.tab-item { flex: 1; text-align: center; padding: 16rpx 0; font-size: 28rpx; color: #909399; }
.tab-item.active { color: #409EFF; font-weight: 600; border-bottom: 4rpx solid #409EFF; }
.exam-scroll { height: calc(100vh - 110rpx); padding: 16rpx 24rpx; box-sizing: border-box; }
.exam-card { background: #fff; border-radius:16rpx; padding: 24rpx; margin-bottom: 16rpx; box-shadow: 0 2rpx 8rpx rgba(0,0,0,.05); }
.card-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 12rpx; }
.exam-name { font-size: 32rpx; font-weight: 600; color: #303133; flex: 1; }
.type-tag { font-size: 22rpx; padding: 4rpx 14rpx; border-radius:8rpx; margin-left: 12rpx; }
.type-tag.formal { background: #ecf5ff; color: #409EFF; }
.type-tag.practice { background: #f0f9eb; color: #67C23A; }
.card-line { font-size: 24rpx; color: #909399; margin-top: 6rpx; }
.card-bottom { display: flex; justify-content: space-between; align-items: center; margin-top: 16rpx; }
.status-tag { font-size: 22rpx; padding: 4rpx 14rpx; border-radius:8rpx; }
.status-tag.pending { background: #ecf5ff; color: #409EFF; }
.status-tag.in_progress { background: #f0f9eb; color: #67C23A; }
.status-tag.ended { background: #f4f4f5; color: #909399; }
.countdown { font-size: 24rpx; color: #E6A23C; }
.btn { font-size: 26rpx; padding: 10rpx 28rpx; border-radius:30rpx; }
.btn.start { background: #409EFF; color: #fff; }
.btn.done { background: #f4f4f5; color: #606266; }
.empty { text-align: center; padding: 120rpx 0; }
.empty-text { color: #909399; font-size: 30rpx; }
.loading, .finished { text-align: center; color: #909399; font-size: 26rpx; padding: 24rpx; }
</style>
