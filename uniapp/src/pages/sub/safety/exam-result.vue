<template>
  <view class="exam-result-page">
    <view v-if="result" class="result-body">
      <!-- 成绩展示 -->
      <view class="score-card">
        <view class="score-num" :class="{ pass: result.is_pass == 1, fail: result.is_pass != 1 }">{{ result.score }}</view>
        <view class="score-label">得分（满分 {{ result.total_score }}）</view>
        <view class="score-tag" :class="result.is_pass == 1 ? 'pass' : 'fail'">
          {{ result.is_pass == 1 ? '合格' : '不合格' }}
        </view>
        <view class="score-sub">及格分 {{ result.pass_score }}　交卷 {{ result.submit_time }}</view>
      </view>

      <!-- 统计信息 -->
      <view class="stat-card">
        <view class="stat-item"><view class="stat-num">{{ stat.total }}</view><view class="stat-label">总题数</view></view>
        <view class="stat-item"><view class="stat-num" style="color:#67C23A;">{{ stat.correct }}</view><view class="stat-label">答对题数</view></view>
        <view class="stat-item"><view class="stat-num" style="color:#F56C6C;">{{ stat.wrong }}</view><view class="stat-label">答错题数</view></view>
        <view class="stat-item"><view class="stat-num">{{ stat.rate }}%</view><view class="stat-label">正确率</view></view>
      </view>

      <!-- 错题回顾（折叠） -->
      <view class="wrong-card">
        <view class="wrong-head" @click="showWrong = !showWrong">
          <text class="wrong-title">错题回顾（{{ wrongList.length }} 题）</text>
          <text class="wrong-arrow">{{ showWrong ? '收起' : '展开' }}</text>
        </view>
        <view v-if="showWrong">
          <view v-for="(w, i) in wrongList" :key="i" class="wrong-item">
            <view class="w-head">
              <text class="w-type">{{ typeText(w.question_type) }}</text>
              <text class="w-no">第 {{ i + 1 }} 题</text>
            </view>
            <view class="w-text">{{ w.question_text }}</view>
            <view class="w-answer wrong">考生答案：{{ w.selected || '（未作答）' }}</view>
            <view class="w-answer right">正确答案：{{ w.answer }}</view>
            <view v-if="w.analysis" class="w-analysis">解析：{{ w.analysis }}</view>
          </view>
          <view v-if="!wrongList.length" class="no-wrong">全部答对，无错题</view>
        </view>
      </view>
    </view>
    <view v-else-if="loading" class="loading">加载中...</view>

    <!-- 操作按钮 -->
    <view class="bottom-bar">
      <view class="btn back" @click="goList">返回考试列表</view>
      <view v-if="result && result.exam_type === 'practice'" class="btn retry" @click="retry">重新考试</view>
      <view v-if="result && result.can_retake" class="btn retry" @click="retry">补考（剩余 {{ result.retake_remaining }} 次）</view>
    </view>
  </view>
</template>

<script>
import { getExamResult } from '@/api/modules/safety.js'
import { useSafetyStore } from '@/store/modules/safety.js'

export default {
  setup() {
    const safetyStore = useSafetyStore()
    return { safetyStore }
  },
  data() {
    return { examId: 0, result: null, loading: true, showWrong: false }
  },
  computed: {
    stat() { return (this.result && this.result.stat) || { total: 0, correct: 0, wrong: 0, rate: 0 } },
    wrongList() { return (this.result && this.result.wrong_questions) || [] }
  },
  onLoad(options) {
    this.examId = Number(options.exam_id || 0)
    // 优先用交卷时暂存的结果，否则重新拉取
    if (this.safetyStore.examResult && this.safetyStore.examResult.exam_id === this.examId) {
      this.result = this.safetyStore.examResult
      this.loading = false
    } else {
      this.load()
    }
  },
  methods: {
    typeText(t) { return { single: '单选题', multiple: '多选题', judge: '判断题' }[t] || t },
    async load() {
      try {
        const r = await getExamResult(this.examId)
        if (r.code === 0) {
          this.result = r.data
          this.safetyStore.setExamResult(r.data)
        }
      } catch (e) { uni.showToast({ title: e.message || '加载失败', icon: 'none' }) }
      this.loading = false
    },
    goList() {
      uni.reLaunch({ url: '/pages/sub/safety/my-exams' })
    },
    retry() {
      this.safetyStore.resetExam()
      // 实名考试：重考/补考同样需要重新完成身份证 + 人脸验证
      uni.navigateTo({ url: '/pages/sub/safety/exam-verify?exam_id=' + this.examId })
    }
  }
}
</script>

<style scoped>
.exam-result-page { min-height: 100vh; background: #f5f6fa; padding-bottom: 150rpx; box-sizing: border-box; }
.result-body { padding: 24rpx; }
.score-card { background: #fff; border-radius:16rpx; padding: 40rpx; text-align: center; margin-bottom: 20rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.score-num { font-size: 110rpx; font-weight: 700; line-height: 1.2; }
.score-num.pass { color: #67C23A; }
.score-num.fail { color: #F56C6C; }
.score-label { font-size: 26rpx; color: #909399; margin-top: 8rpx; }
.score-tag { display: inline-block; font-size: 28rpx; padding: 10rpx 40rpx; border-radius:40rpx; margin-top: 20rpx; }
.score-tag.pass { background: #f0f9eb; color: #67C23A; }
.score-tag.fail { background: #fef0f0; color: #F56C6C; }
.score-sub { font-size: 24rpx; color: #909399; margin-top: 16rpx; }
.stat-card { display: flex; background: #fff; border-radius:16rpx; padding: 24rpx 0; margin-bottom: 20rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.stat-item { flex: 1; text-align: center; }
.stat-num { font-size: 40rpx; font-weight: 600; color: #303133; }
.stat-label { font-size: 24rpx; color: #909399; margin-top: 6rpx; }
.wrong-card { background: #fff; border-radius:16rpx; padding: 24rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.wrong-head { display: flex; justify-content: space-between; align-items: center; }
.wrong-title { font-size: 30rpx; font-weight: 600; color: #303133; }
.wrong-arrow { font-size: 26rpx; color: #409EFF; }
.wrong-item { border-top: 1rpx solid #f2f3f5; padding: 20rpx 0; }
.w-head { display: flex; justify-content: space-between; margin-bottom: 10rpx; }
.w-type { font-size: 22rpx; color: #F56C6C; background: #fef0f0; padding: 2rpx 12rpx; border-radius:6rpx; }
.w-no { font-size: 22rpx; color: #909399; }
.w-text { font-size: 28rpx; color: #303133; line-height: 1.6; margin-bottom: 10rpx; }
.w-answer { font-size: 26rpx; margin-top: 6rpx; }
.w-answer.wrong { color: #F56C6C; }
.w-answer.right { color: #67C23A; }
.w-analysis { font-size: 24rpx; color: #909399; margin-top: 8rpx; }
.no-wrong { text-align: center; color: #67C23A; font-size: 28rpx; padding: 30rpx 0; }
.loading { text-align: center; padding: 200rpx 0; color: #909399; }
.bottom-bar { position: fixed; left: 0; right: 0; bottom: 0; display: flex; background: #fff; padding: 20rpx 24rpx calc(20rpx + env(safe-area-inset-bottom)); }
.btn { flex: 1; text-align: center; font-size: 30rpx; padding: 22rpx 0; border-radius:40rpx; margin: 0 10rpx; }
.btn.back { background: #f4f4f5; color: #606266; }
.btn.retry { background: #409EFF; color: #fff; }
</style>
