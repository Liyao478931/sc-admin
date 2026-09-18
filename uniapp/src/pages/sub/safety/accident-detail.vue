<template>
  <view class="accident-detail-page">
    <scroll-view class="detail-scroll" scroll-y v-if="detail">
      <!-- 状态进度条 -->
      <view class="progress-card">
        <view class="progress-title">处理进度</view>
        <view class="progress-steps">
          <view v-for="(s, i) in steps" :key="s.value" class="step" :class="{ done: stepIndex >= i, current: stepIndex === i }">
            <view class="step-dot"></view>
            <view class="step-label">{{ s.label }}</view>
          </view>
        </view>
        <view class="progress-msg">{{ statusMsg }}</view>
      </view>

      <!-- 事故信息 -->
      <view class="info-card">
        <view class="card-title">事故信息</view>
        <view class="row"><text class="label">事故编号</text><text class="value">{{ detail.accident_code }}</text></view>
        <view class="row"><text class="label">事故名称</text><text class="value">{{ detail.accident_name }}</text></view>
        <view class="row"><text class="label">事故类型</text><text class="value">{{ detail.type_text }}</text></view>
        <view class="row"><text class="label">事故等级</text><text class="value">{{ detail.level_text }}</text></view>
        <view class="row"><text class="label">发生时间</text><text class="value">{{ detail.happen_time }}</text></view>
        <view class="row"><text class="label">发生地点</text><text class="value">{{ detail.happen_location }}</text></view>
        <view class="row"><text class="label">发生部门</text><text class="value">{{ detail.happen_department_name || '-' }}</text></view>
      </view>

      <!-- 事故经过 -->
      <view class="info-card">
        <view class="card-title">事故经过</view>
        <view class="text">{{ detail.accident_process }}</view>
      </view>

      <!-- 伤亡损失 -->
      <view class="info-card">
        <view class="card-title">伤亡与损失</view>
        <view class="text">死亡 {{ detail.death_count }} 人，重伤 {{ detail.serious_injury_count }} 人，轻伤 {{ detail.minor_injury_count }} 人</view>
        <view class="text">直接经济损失 {{ detail.economic_loss }} 万元</view>
      </view>

      <!-- 现场照片 -->
      <view v-if="detail.attachments && detail.attachments.length" class="info-card">
        <view class="card-title">现场照片</view>
        <view class="img-grid">
          <image v-for="(a, i) in detail.attachments" :key="i" :src="a.url" class="img" mode="aspectFill" @click="preview(i)" />
        </view>
      </view>

      <!-- 备注 -->
      <view v-if="detail.remark" class="info-card">
        <view class="card-title">备注</view>
        <view class="text">{{ detail.remark }}</view>
      </view>
    </scroll-view>
    <view v-else-if="loading" class="loading">加载中...</view>

    <!-- 底部状态提示 -->
    <view class="bottom-bar" v-if="detail">
      <view class="status-tip" :class="detail.status">{{ statusMsg }}</view>
      <view class="contact-btn" @click="contactSafety">联系安全部门</view>
    </view>
  </view>
</template>

<script>
import { getMyAccidentDetail } from '@/api/modules/safety.js'

export default {
  data() {
    return { accidentId: 0, detail: null, loading: true }
  },
  computed: {
    steps() {
      return [
        { label: '上报', value: 'draft' },
        { label: '待调查', value: 'pending' },
        { label: '调查中', value: 'investigating' },
        { label: '已结案', value: 'closed' },
        { label: '已归档', value: 'archived' },
      ]
    },
    stepIndex() {
      const map = { draft: 0, pending: 1, investigating: 2, closed: 3, archived: 4 }
      return map[this.detail && this.detail.status] || 0
    },
    statusMsg() {
      const s = this.detail && this.detail.status
      return {
        draft: '草稿，待补充提交',
        pending: '正在等待安全部门处理',
        investigating: '安全部门正在调查中',
        closed: '事故已调查结案',
        archived: '事故已归档',
      }[s] || ''
    },
  },
  onLoad(options) {
    this.accidentId = Number(options.accident_id || 0)
    this.load()
  },
  methods: {
    async load() {
      try {
        const r = await getMyAccidentDetail(this.accidentId)
        if (r.code === 0) this.detail = r.data
      } catch (e) { uni.showToast({ title: e.message || '加载失败', icon: 'none' }) }
      this.loading = false
    },
    preview(i) {
      const urls = (this.detail.attachments || []).map(a => a.url)
      uni.previewImage({ urls, current: urls[i] })
    },
    contactSafety() {
      const phone = this.detail && this.detail.safety_phone
      if (!phone) { uni.showToast({ title: '未配置安全部门联系电话', icon: 'none' }); return }
      uni.makePhoneCall({ phoneNumber: phone, fail: () => {} })
    },
  },
}
</script>

<style scoped>
.accident-detail-page { min-height: 100vh; background: #f5f6fa; padding-bottom: 120rpx; box-sizing: border-box; }
.detail-scroll { padding: 24rpx; box-sizing: border-box; }
.progress-card, .info-card { background: #fff; border-radius:16rpx; padding: 24rpx; margin-bottom: 20rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.progress-title, .card-title { font-size: 30rpx; font-weight: 600; color: #303133; margin-bottom: 20rpx; }
.progress-steps { display: flex; justify-content: space-between; }
.step { flex: 1; text-align: center; position: relative; }
.step-dot { width: 20rpx; height: 20rpx; border-radius:50%; background: #e4e7ed; margin: 0 auto 8rpx; }
.step.done .step-dot { background: #67C23A; }
.step.current .step-dot { background: #409EFF; }
.step-label { font-size: 22rpx; color: #909399; }
.step.done .step-label { color: #67C23A; }
.step.current .step-label { color: #409EFF; font-weight: 600; }
.progress-msg { margin-top: 20rpx; font-size: 26rpx; color: #E6A23C; text-align: center; }
.row { display: flex; justify-content: space-between; padding: 14rpx 0; border-bottom: 1rpx solid #f2f3f5; }
.row:last-child { border-bottom: none; }
.label { font-size: 26rpx; color: #909399; }
.value { font-size: 26rpx; color: #303133; text-align: right; max-width: 60%; }
.text { font-size: 26rpx; color: #606266; line-height: 1.8; }
.img-grid { display: flex; flex-wrap: wrap; gap: 14rpx; }
.img { width: 170rpx; height: 170rpx; border-radius:10rpx; }
.loading { text-align: center; padding: 200rpx 0; color: #909399; }
.bottom-bar { position: fixed; left: 0; right: 0; bottom: 0; background: #fff; padding: 20rpx 24rpx calc(20rpx + env(safe-area-inset-bottom)); }
.status-tip { text-align: center; font-size: 28rpx; padding: 20rpx 0; border-radius:40rpx; }
.contact-btn { margin-top: 12rpx; text-align: center; font-size: 28rpx; padding: 18rpx 0; border-radius:40rpx; background: #409EFF; color: #fff; }
.status-tip.draft, .status-tip.pending { background: #fdf6ec; color: #E6A23C; }
.status-tip.investigating { background: #ecf5ff; color: #409EFF; }
.status-tip.closed, .status-tip.archived { background: #f0f9eb; color: #67C23A; }
</style>
