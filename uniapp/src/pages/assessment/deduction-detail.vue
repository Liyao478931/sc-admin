<template>
  <view class="dd-page">
    <view v-if="!detail" class="dd-empty"><u-empty text="加载中..." mode="list" /></view>
    <template v-else>
      <!-- 核心信息卡 -->
      <view class="dd-card">
        <view class="dd-row"><text class="dd-label">考核指标</text><text class="dd-value">{{ detail.indicator_name }}</text></view>
        <view class="dd-row"><text class="dd-label">扣分分值</text><text class="dd-value score">-{{ detail.deduct_score }} 分</text></view>
        <view class="dd-row"><text class="dd-label">当前状态</text><text class="dd-status" :class="'s' + detail.status">{{ detail.status_text }}</text></view>
      </view>

      <!-- 详细信息 -->
      <view class="dd-card">
        <view class="dd-row"><text class="dd-label">扣分原因</text><text class="dd-value">{{ detail.reason }}</text></view>
        <view class="dd-row"><text class="dd-label">数据来源</text><text class="dd-value">{{ detail.source_type_text }} {{ detail.source_detail }}</text></view>
        <view class="dd-row"><text class="dd-label">考核周期</text><text class="dd-value">{{ periodText }}</text></view>
        <view class="dd-row"><text class="dd-label">扣分时间</text><text class="dd-value">{{ detail.created_at }}</text></view>
      </view>

      <!-- 附件 -->
      <view class="dd-card" v-if="detail.attachments && detail.attachments.length">
        <view class="dd-label">附件</view>
        <view class="dd-photos">
          <image v-for="(a, i) in detail.attachments" :key="i" :src="imgUrl(a)" mode="aspectFill" class="dd-photo" @click="preview(i)" />
        </view>
      </view>

      <!-- 状态提示 -->
      <view v-if="detail.status === 1" class="dd-tip ok"><MIcon name="check" :size="14" color="#059669" /><text style="margin-left:4px">已确认</text></view>
      <view v-else-if="detail.status === 2" class="dd-tip info">申诉处理中，请等待</view>
      <view v-else-if="detail.status === 3" class="dd-tip reject">申诉已驳回</view>

      <!-- 底部操作 -->
      <view v-if="detail.can_confirm || detail.can_appeal" class="dd-actions">
        <u-button v-if="detail.can_confirm" type="primary" text="确认扣分" shape="circle" @click="doConfirm" />
        <u-button v-if="detail.can_appeal" type="warning" text="发起申诉" shape="circle" @click="goAppeal" />
      </view>
    </template>
  </view>
</template>

<script setup>
import { ref, computed } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { getDeductionDetail, confirmMyDeduction } from '@/api/assessment.js'

const detail = ref(null)
const periodText = computed(() => {
  const p = detail.value && detail.value.period
  if (!p) return ''
  const [y, m] = p.split('-')
  return `${y}年${parseInt(m)}月`
})

onLoad((options) => {
  const id = options && options.id ? parseInt(options.id) : 0
  if (id) load(id)
})

async function load (id) {
  try {
    const r = await getDeductionDetail(id)
    if (r.code === 0) detail.value = r.data
    else uni.showToast({ title: r.msg || '加载失败', icon: 'none' })
  } catch (e) {}
}

function doConfirm () {
  uni.showModal({
    title: '确认扣分',
    content: `确认该条扣分（${detail.value.indicator_name} -${detail.value.deduct_score}分）吗？`,
    success: async (res) => {
      if (!res.confirm) return
      try {
        const r = await confirmMyDeduction(detail.value.id)
        if (r.code === 0) {
          uni.showToast({ title: '已确认', icon: 'success' })
          setTimeout(() => uni.navigateBack(), 800)
        } else uni.showToast({ title: r.msg || '操作失败', icon: 'none' })
      } catch (e) { uni.showToast({ title: '操作失败', icon: 'none' }) }
    }
  })
}

function goAppeal () {
  uni.navigateTo({ url: `/pages/assessment/appeal-submit?deduction_id=${detail.value.id}` })
}

function imgUrl (u) {
  return u && /^https?:/.test(u) ? u : uni.$base + u
}

function preview (i) {
  uni.previewImage({ urls: detail.value.attachments.map(a => imgUrl(a)), current: imgUrl(detail.value.attachments[i]) })
}
</script>

<style scoped>
.dd-page { min-height: 100vh; background: #f5f6fa; padding: 20rpx 24rpx 60rpx; }
.dd-empty { padding: 80rpx 0; }
.dd-card { background: #fff; border-radius:20rpx; padding: 24rpx; margin-bottom: 20rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.dd-row { display: flex; align-items: center; padding: 14rpx 0; border-bottom: 1rpx solid #F4F6FB; }
.dd-label { width: 180rpx; font-size: 26rpx; color: #8a9aa8; flex-shrink: 0; }
.dd-value { flex: 1; font-size: 27rpx; color: #1d2129; }
.dd-value.score { color: #f53f3f; font-weight: 700; }
.dd-status { font-size: 22rpx; padding: 4rpx 18rpx; border-radius:20rpx; }
.dd-status.s0 { background: #fdf6ec; color: #ffb020; }
.dd-status.s1 { background: #eaf7ec; color: #00b42a; }
.dd-status.s2 { background: #e8f3ff; color: #1e6fff; }
.dd-status.s3 { background: #fef0f0; color: #f53f3f; }
.dd-photos { display: flex; gap: 16rpx; flex-wrap: wrap; margin-top: 12rpx; }
.dd-photo { width: 160rpx; height: 160rpx; border-radius:12rpx; }
.dd-tip { text-align: center; font-size: 26rpx; padding: 20rpx; border-radius:16rpx; margin-top: 10rpx; }
.dd-tip.ok { background: #eaf7ec; color: #00b42a; }
.dd-tip.info { background: #e8f3ff; color: #1e6fff; }
.dd-tip.reject { background: #fef0f0; color: #f53f3f; }
.dd-actions { display: flex; gap: 20rpx; margin-top: 30rpx; }
</style>
