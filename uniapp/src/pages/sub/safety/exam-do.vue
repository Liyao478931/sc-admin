<template>
  <view class="exam-do-page">
    <!-- 顶部信息栏 -->
    <view class="top-bar">
      <view class="top-left">{{ examName }}</view>
      <view class="top-progress">第 {{ currentIndex + 1 }} / {{ questions.length }} 题</view>
      <view class="top-time" :class="{ urgent: remaining <= 300 }">{{ timeText }}</view>
    </view>

    <!-- 题目内容 -->
    <scroll-view class="question-scroll" scroll-y v-if="current">
      <view class="question-card">
        <view class="q-head">
          <text class="q-type">{{ current.type_text }}</text>
          <view class="q-mark" :class="{ marked: marked[current.id] }" @click="toggleMark(current.id)" style="display:flex;align-items:center"><MIcon name="star" :size="14" :color="marked[current.id] ? '#E6A23C' : '#909399'" /><text style="margin-left:4px">标记</text></view>
        </view>
        <view class="q-text">{{ current.question_text }}</view>
        <view v-if="current.question_type !== 'judge'" class="option-list">
          <view v-for="opt in current.options" :key="opt.label" class="option-item"
            :class="{ selected: isSelected(current.id, opt.label) }" @click="selectOption(current.id, opt.label, current.question_type)">
            <text class="option-label">{{ opt.label }}</text>
            <text class="option-text">{{ opt.text }}</text>
          </view>
        </view>
        <view v-else class="option-list">
          <view class="option-item" :class="{ selected: answers[current.id] === '正确' }" @click="selectOption(current.id, '正确', 'judge')">
            <text class="option-label">对</text><text class="option-text">正确</text>
          </view>
          <view class="option-item" :class="{ selected: answers[current.id] === '错误' }" @click="selectOption(current.id, '错误', 'judge')">
            <text class="option-label">错</text><text class="option-text">错误</text>
          </view>
        </view>
      </view>
    </scroll-view>
    <view v-else-if="!loading" class="empty">暂无题目</view>

    <!-- 底部操作栏 -->
    <view class="bottom-bar">
      <view class="btn prev" @click="prev">上一题</view>
      <view class="btn card" @click="cardVisible = true">答题卡</view>
      <view class="btn next" @click="next">下一题</view>
      <view class="btn submit" @click="confirmSubmit">交卷</view>
    </view>

    <!-- 答题卡弹窗 -->
    <view v-if="cardVisible" class="mask" @click="cardVisible = false">
      <view class="sheet" @click.stop>
        <view class="sheet-title">答题卡（已答 {{ answeredNum }} / {{ questions.length }}）</view>
        <scroll-view class="grid-scroll" scroll-y>
          <view class="grid">
            <view v-for="(q, i) in questions" :key="q.id" class="cell"
              :class="{ answered: isAnswered(q.id), marked: marked[q.id] }" @click="jumpTo(i)">
              {{ i + 1 }}
            </view>
          </view>
        </scroll-view>
        <view class="legend">
          <text class="lg"><text class="dot answered"></text>已答</text>
          <text class="lg"><text class="dot"></text>未答</text>
          <text class="lg"><text class="dot marked"></text>标记</text>
        </view>
        <view class="btn confirm" @click="cardVisible = false">关闭</view>
      </view>
    </view>
  </view>
</template>

<script>
import { useSafetyStore } from '@/store/modules/safety.js'
import { startExam, getExamQuestions, saveExamAnswer, submitExam, getExamDetail } from '@/api/modules/safety.js'

export default {
  setup() {
    const safetyStore = useSafetyStore()
    return { safetyStore }
  },
  data() {
    return {
      examId: 0, examName: '考试', examType: 'formal', endTime: '',
      loading: true, cardVisible: false, submitting: false,
    remaining: 0, timer: null, startTs: 0,
    // 切屏/截屏防作弊
    switchCount: 0, switchWarnLimit: 3, switchAutoLimit: 5,
    captureCount: 0, keyHandler: null
    }
  },
  computed: {
    questions() { return this.safetyStore.examQuestions },
    currentIndex() { return this.safetyStore.currentIndex },
    current() { return this.safetyStore.examQuestions[this.safetyStore.currentIndex] || null },
    answers() { return this.safetyStore.examAnswers },
    marked() { return this.safetyStore.examMarked },
    answeredNum() { return this.safetyStore.answeredCount() },
    timeText() {
      if (this.examType === 'practice') return '不限时'
      const m = Math.floor(this.remaining / 60)
      const s = this.remaining % 60
      return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
    }
  },
  async onLoad(options) {
    this.examId = Number(options.exam_id || 0)
    this.startTs = Date.now()
    try {
      // 开始考试（需已通过实名验证；此处幂等放行）
      const st = await startExam(this.examId)
      if (st.code !== 0) {
        uni.showToast({ title: (st.msg || '请先完成实名验证') + '，请返回重新验证', icon: 'none' })
        setTimeout(() => uni.navigateBack({ delta: 1 }), 1200)
        this.loading = false
        return
      }
      const r = await getExamQuestions(this.examId)
      if (r.code === 0) {
        const data = r.data || {}
        this.safetyStore.initExam(data.questions || [], data.saved_answers || {})
        this.examName = this.questions[0] ? '考试' : '考试'
        // 考试名称从详情获取（简单场景直接展示）
        this.initTimer(data)
      }
    } catch (e) {
      uni.showToast({ title: e.message || '加载失败', icon: 'none' })
      setTimeout(() => uni.navigateBack(), 1200)
    }
    this.loading = false
    // H5 防截屏键盘监听
    this.setupAntiCapture()
  },
  onUnload() {
    if (this.timer) clearInterval(this.timer)
    // 移除 H5 防截屏键盘监听
    if (this.keyHandler && typeof window !== 'undefined') window.removeEventListener('keydown', this.keyHandler)
  },
  // 小程序端：监听用户截屏
  onUserCaptureScreen() {
    if (this.examType === 'formal' && !this.submitting) this.recordCapture()
  },
  // H5 端：拦截截屏/打印快捷键（Ctrl+P / Ctrl+S / PrtSc）
  setupAntiCapture() {
    if (typeof window === 'undefined') return
    this.keyHandler = (e) => {
      const k = e.key || ''
      if ((e.ctrlKey && (k === 'p' || k === 'P' || k === 's' || k === 'S')) || k === 'PrintScreen' || e.keyCode === 44) {
        e.preventDefault()
        if (this.examType === 'formal' && !this.submitting) this.recordCapture()
        uni.showToast({ title: '考试中禁止截屏/打印', icon: 'none' })
      }
    }
    window.addEventListener('keydown', this.keyHandler)
  },
  // 切屏检测：页面隐藏（切标签/切App/切后台）记录违规
  onHide() {
    if (this.examType === 'formal' && !this.submitting) this.recordSwitch()
  },
  methods: {
    initTimer(data) {
      // 从详情接口补充考试信息（类型/结束时间/名称）
      this.loadExamInfo()
      this.remaining = 0
      this.timer = setInterval(() => { this.tick() }, 1000)
    },
    async loadExamInfo() {
      try {
        const r = await getExamDetail(this.examId)
        if (r.code === 0) {
          this.examName = r.data.exam_name || '考试'
          this.examType = r.data.exam_type || 'formal'
          this.endTime = r.data.end_time || ''
          if (this.examType === 'formal' && this.endTime) {
            this.remaining = Math.max(0, Math.floor((new Date(this.endTime).getTime() - Date.now()) / 1000))
          }
        }
      } catch (e) {}
    },
    tick() {
      if (this.examType === 'practice') return
      if (this.remaining > 0) {
        this.remaining--
        if (this.remaining <= 0) this.autoSubmit()
      }
    },
    isSelected(qid, label) {
      const v = this.answers[qid] || ''
      return v.split(',').includes(label)
    },
    isAnswered(qid) {
      return !!(this.answers[qid] || '') !== false && (this.answers[qid] || '') !== ''
    },
    selectOption(qid, label, type) {
      if (type === 'multiple') {
        const arr = (this.answers[qid] || '').split(',').filter(Boolean)
        const idx = arr.indexOf(label)
        if (idx > -1) arr.splice(idx, 1)
        else arr.push(label)
        const val = arr.join(',')
        this.safetyStore.setExamAnswer(qid, val)
        this.saveAnswer(qid, val)
      } else {
        this.safetyStore.setExamAnswer(qid, label)
        this.saveAnswer(qid, label)
      }
    },
    saveAnswer(qid, val) {
      saveExamAnswer(this.examId, qid, val).catch(() => {})
    },
    toggleMark(qid) {
      this.safetyStore.toggleExamMark(qid)
    },
    prev() { this.safetyStore.goExamQuestion(this.currentIndex - 1) },
    next() { this.safetyStore.goExamQuestion(this.currentIndex + 1) },
    jumpTo(i) { this.safetyStore.goExamQuestion(i); this.cardVisible = false },
    confirmSubmit() {
      const total = this.questions.length
      const answered = this.answeredNum
      uni.showModal({
        title: '确认交卷',
        content: `已答 ${answered} 题，未答 ${total - answered} 题，交卷后不可修改。`,
        confirmText: '交卷',
        success: (res) => { if (res.confirm) this.doSubmit() }
      })
    },
    recordCapture() {
      this.captureCount++
      uni.showToast({ title: `已检测到截屏操作（${this.captureCount} 次），已记录违规`, icon: 'none' })
    },
    recordSwitch() {
      this.switchCount++
      if (this.switchCount >= this.switchAutoLimit) {
        uni.showModal({
          title: '违规提示',
          content: `检测到 ${this.switchCount} 次切换屏幕，已自动交卷！`,
          showCancel: false,
          success: () => this.doSubmit()
        })
      } else if (this.switchCount >= this.switchWarnLimit) {
        uni.showToast({ title: `已记录 ${this.switchCount} 次切屏，再切屏将自动交卷`, icon: 'none' })
      } else {
        uni.showToast({ title: '考试中请勿切换屏幕', icon: 'none' })
      }
    },
    autoSubmit() {
      uni.showToast({ title: '时间到，自动交卷', icon: 'none' })
      this.doSubmit()
    },
    async doSubmit() {
      if (this.submitting) return
      this.submitting = true
      uni.showLoading({ title: '交卷中...' })
      try {
        const list = Object.keys(this.answers).map((qid) => ({
          question_id: Number(qid),
          selected: this.answers[qid] || ''
        }))
        const duration = Math.floor((Date.now() - this.startTs) / 1000)
        const r = await submitExam(this.examId, list, duration, this.switchCount, this.captureCount)
        uni.hideLoading()
        if (r.code === 0) {
          this.safetyStore.setExamResult(r.data)
          uni.redirectTo({ url: '/pages/sub/safety/exam-result?exam_id=' + this.examId })
        }
      } catch (e) {
        uni.hideLoading()
        uni.showToast({ title: e.message || '交卷失败', icon: 'none' })
      }
      this.submitting = false
    }
  }
}
</script>

<style scoped>
.exam-do-page { min-height: 100vh; background: #f5f6fa; display: flex; flex-direction: column; user-select: none; -webkit-touch-callout: none; }
.top-bar { display: flex; align-items: center; justify-content: space-between; background: #fff; padding: 20rpx 24rpx; box-shadow: 0 2rpx 8rpx rgba(0,0,0,.05); }
.top-left { font-size: 26rpx; color: #303133; flex: 1; overflow: hidden; white-space: nowrap; text-overflow: ellipsis; }
.top-progress { font-size: 24rpx; color: #909399; margin: 0 16rpx; }
.top-time { font-size: 30rpx; font-weight: 600; color: #409EFF; }
.top-time.urgent { color: #F56C6C; }
.question-scroll { flex: 1; padding: 24rpx; box-sizing: border-box; }
.question-card { background: #fff; border-radius:16rpx; padding: 28rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.q-head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16rpx; }
.q-type { font-size: 24rpx; color: #409EFF; background: #ecf5ff; padding: 4rpx 14rpx; border-radius:8rpx; }
.q-mark { font-size: 24rpx; color: #909399; }
.q-mark.marked { color: #E6A23C; }
.q-text { font-size: 32rpx; color: #303133; line-height: 1.7; margin-bottom: 24rpx; }
.option-list { display: flex; flex-direction: column; }
.option-item { display: flex; align-items: flex-start; padding: 22rpx 20rpx; border: 2rpx solid #e4e7ed; border-radius:12rpx; margin-bottom: 16rpx; }
.option-item.selected { border-color: #409EFF; background: #ecf5ff; }
.option-label { width: 48rpx; font-size: 28rpx; font-weight: 600; color: #409EFF; }
.option-text { flex: 1; font-size: 28rpx; color: #303133; }
.bottom-bar { display: flex; align-items: center; padding: 16rpx 24rpx calc(16rpx + env(safe-area-inset-bottom)); background: #fff; }
.btn { flex: 1; text-align: center; font-size: 26rpx; padding: 20rpx 0; border-radius:36rpx; margin: 0 8rpx; }
.btn.prev, .btn.next { background: #f4f4f5; color: #606266; }
.btn.card { background: #ecf5ff; color: #409EFF; }
.btn.submit { background: #409EFF; color: #fff; }
.btn.confirm { background: #409EFF; color: #fff; width: 100%; margin-top: 20rpx; }
.mask { position: fixed; inset: 0; background: rgba(0,0,0,.4); z-index: 100; display: flex; align-items: flex-end; }
.sheet { width: 100%; background: #fff; border-radius:24rpx 24rpx 0 0; padding: 30rpx 30rpx calc(30rpx + env(safe-area-inset-bottom)); max-height: 75vh; overflow: hidden; box-sizing: border-box;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.sheet-title { font-size: 30rpx; font-weight: 600; text-align: center; margin-bottom: 24rpx; }
.grid-scroll { max-height: 50vh; }
.grid { display: flex; flex-wrap: wrap; }
.cell { width: 14%; margin: 2%; height: 76rpx; line-height: 76rpx; text-align: center; border-radius:12rpx; background: #f4f4f5; color: #606266; font-size: 28rpx; }
.cell.answered { background: #f0f9eb; color: #67C23A; }
.cell.marked { background: #fdf6ec; color: #E6A23C; }
.legend { display: flex; justify-content: center; margin: 20rpx 0; }
.lg { font-size: 24rpx; color: #909399; margin: 0 16rpx; display: flex; align-items: center; }
.dot { width: 20rpx; height: 20rpx; border-radius:50%; background: #f4f4f5; margin-right: 8rpx; display: inline-block; }
.dot.answered { background: #67C23A; }
.dot.marked { background: #E6A23C; }
.empty { text-align: center; padding: 200rpx 0; color: #909399; }
</style>
