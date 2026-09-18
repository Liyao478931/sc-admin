<template>
  <view class="exam-detail-page">
    <view v-if="exam" class="detail-body">
      <!-- 考试信息卡片 -->
      <view class="info-card">
        <view class="info-title">{{ exam.exam_name }}</view>
        <view class="info-row"><text class="label">试卷名称</text><text class="value">{{ exam.paper_name || '-' }}</text></view>
        <view class="info-row"><text class="label">考试类型</text><text class="value">{{ exam.type_text }}</text></view>
        <view class="info-row"><text class="label">题量</text><text class="value">{{ exam.total_questions || 0 }} 题</text></view>
        <view class="info-row"><text class="label">总分</text><text class="value">{{ exam.total_score || 0 }} 分</text></view>
        <view class="info-row"><text class="label">及格分数</text><text class="value">{{ exam.pass_score || 0 }} 分</text></view>
        <view class="info-row"><text class="label">考试时长</text><text class="value">{{ exam.duration_minutes }} 分钟</text></view>
        <view class="info-row"><text class="label">考试时间</text><text class="value">{{ exam.start_time }} ~ {{ exam.end_time }}</text></view>
      </view>

      <!-- 考试须知 -->
      <view class="notice-card">
        <view class="notice-title">考试须知</view>
        <view class="notice-item">1. 考试开始后不可退出，交卷后方可退出。</view>
        <view class="notice-item">2. 倒计时结束后将自动交卷。</view>
        <view class="notice-item">3. 请确保网络稳定，答案将实时自动保存。</view>
        <view v-if="exam.exam_notice" class="notice-item custom">{{ exam.exam_notice }}</view>
      </view>
    </view>

    <!-- 底部操作 -->
    <view class="bottom-bar">
      <view v-if="exam.status === 'pending'" class="pending-area">
        <text class="pending-text">距开始 {{ countdownText }}</text>
        <view class="btn disabled">考试未开始</view>
      </view>
      <view v-else-if="exam.submitted" class="pending-area">
        <view class="btn done" @click="goResult">查看成绩</view>
      </view>
      <view v-else-if="exam.status === 'in_progress'" class="pending-area">
        <view class="btn start" @click="startExam">开始考试</view>
      </view>
      <view v-else class="pending-area">
        <view class="btn done" @click="goResult">查看成绩</view>
      </view>
    </view>
  </view>
</template>

<script>
import { getExamDetail } from '../../../api/modules/safety.js'

export default {
  data() {
    return { examId: 0, exam: null, now: Date.now(), timer: null, starting: false }
  },
  computed: {
    countdownText() {
      if (!this.exam) return ''
      const diff = new Date(this.exam.start_time).getTime() - this.now
      if (diff <= 0) return '即将开始'
      const h = Math.floor(diff / 3600000)
      const m = Math.floor((diff % 3600000) / 60000)
      const s = Math.floor((diff % 60000) / 1000)
      return `${h} 时 ${m} 分 ${s} 秒`
    }
  },
  onLoad(options) {
    this.examId = Number(options.exam_id || 0)
    this.load()
    this.timer = setInterval(() => { this.now = Date.now() }, 1000)
  },
  onUnload() {
    if (this.timer) clearInterval(this.timer)
  },
  methods: {
    async load() {
      try {
        const r = await getExamDetail(this.examId)
        if (r.code === 0) this.exam = r.data
      } catch (e) { uni.showToast({ title: '加载失败', icon: 'none' }) }
    },
    startExam() {
      if (this.starting) return
      this.starting = true
      // 实名考试：先完成身份证后6位 + 人脸识别验证，验证通过后自动进入答题页
      uni.navigateTo({ url: '/pages/sub/safety/exam-verify?exam_id=' + this.examId })
      this.starting = false
    },
    goResult() {
      uni.redirectTo({ url: '/pages/sub/safety/exam-result?exam_id=' + this.examId })
    }
  }
}
</script>

<style scoped>
.exam-detail-page { min-height: 100vh; background: #f5f6fa; padding-bottom: 140rpx; box-sizing: border-box; }
.detail-body { padding: 24rpx; }
.info-card, .notice-card { background: #fff; border-radius:16rpx; padding: 28rpx; margin-bottom: 20rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.info-title { font-size: 34rpx; font-weight: 600; color: #303133; margin-bottom: 20rpx; }
.info-row { display: flex; justify-content: space-between; padding: 12rpx 0; border-bottom: 1rpx solid #f2f3f5; }
.info-row:last-child { border-bottom: none; }
.label { font-size: 26rpx; color: #909399; }
.value { font-size: 26rpx; color: #303133; text-align: right; }
.notice-title { font-size: 30rpx; font-weight: 600; color: #303133; margin-bottom: 16rpx; }
.notice-item { font-size: 26rpx; color: #606266; line-height: 1.8; }
.notice-item.custom { color: #E6A23C; }
.bottom-bar { position: fixed; left: 0; right: 0; bottom: 0; background: #fff; padding: 20rpx 24rpx calc(20rpx + env(safe-area-inset-bottom)); box-shadow: 0 -2rpx 12rpx rgba(0,0,0,.05); }
.pending-area { display: flex; flex-direction: column; align-items: center; }
.pending-text { font-size: 26rpx; color: #E6A23C; margin-bottom: 16rpx; }
.btn { width: 100%; text-align: center; font-size: 30rpx; padding: 22rpx 0; border-radius:40rpx; }
.btn.start { background: #409EFF; color: #fff; }
.btn.done { background: #f4f4f5; color: #606266; }
.btn.disabled { background: #f4f4f5; color: #c0c4cc; }
</style>
