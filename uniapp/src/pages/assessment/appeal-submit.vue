<template>
  <view class="as-page">
    <!-- 扣分信息 -->
    <view class="as-card" v-if="deduction">
      <view class="as-row"><text class="as-label">考核月份</text><text class="as-value">{{ periodText }}</text></view>
      <view class="as-row"><text class="as-label">扣分指标</text><text class="as-value">{{ deduction.indicator_name }}</text></view>
      <view class="as-row"><text class="as-label">扣分分值</text><text class="as-value score">-{{ deduction.deduct_score }} 分</text></view>
      <view class="as-row"><text class="as-label">扣分原因</text><text class="as-value">{{ deduction.reason }}</text></view>
    </view>

    <!-- 申诉理由 -->
    <view class="as-card">
      <view class="as-label">申诉理由 <text class="req">*</text></view>
      <u-textarea v-model="reason" placeholder="请详细描述申诉理由（至少10字）" maxlength="500" :count="true" />
      <view v-if="error" class="as-error">{{ error }}</view>
    </view>

    <!-- 上传证据 -->
    <view class="as-card">
      <view class="as-label">上传证据（选填，最多 9 张）</view>
      <view class="as-photos">
        <view v-for="(p, i) in photos" :key="i" class="as-photo">
          <image :src="p" mode="aspectFill" class="as-photo-img" @click="preview(i)" />
          <view class="as-photo-del" @click="photos.splice(i, 1)"><text>×</text></view>
        </view>
        <view v-if="photos.length < 9" class="as-photo-add" @click="chooseImage"><MIcon name="camera" :size="18" color="#4F46E5" /><text class="as-add-text">上传</text></view>
      </view>
      <view class="as-tips">
        <text>· 每个扣分最多可申诉 2 次</text>
        <text>· 考核结束后 3 天内可申诉</text>
        <text>· 提交后 HR 将在 3 个工作日内处理</text>
      </view>
    </view>

    <u-button type="primary" shape="circle" :text="submitting ? '提交中...' : '提交申诉'" :loading="submitting" @click="doSubmit" />
  </view>
</template>

<script setup>
import { ref, computed } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { getDeductionDetail, submitAppeal } from '@/api/assessment.js'

const deduction = ref(null)
const reason = ref('')
const photos = ref([])
const error = ref('')
const submitting = ref(false)
const periodText = computed(() => {
  const p = deduction.value && deduction.value.period
  if (!p) return ''
  const [y, m] = p.split('-')
  return `${y}年${parseInt(m)}月`
})

onLoad(async (options) => {
  const id = options && options.deduction_id ? parseInt(options.deduction_id) : 0
  if (!id) return
  try {
    const r = await getDeductionDetail(id)
    if (r.code === 0) deduction.value = r.data
  } catch (e) {}
})

function chooseImage () {
  uni.chooseImage({
    count: 9 - photos.value.length,
    sizeType: ['compressed'],
    sourceType: ['album', 'camera'],
    success: (res) => {
      res.tempFilePaths.forEach(path => uploadImage(path))
    }
  })
}

function uploadImage (path) {
  uni.uploadFile({
    url: uni.$base + '/api/assessment/mobile/upload',
    filePath: path,
    name: 'file',
    success: (res) => {
      try {
        const data = JSON.parse(res.data)
        if (data.code === 0 && data.data && data.data.url) photos.value.push(data.data.url)
        else uni.showToast({ title: data.msg || '上传失败', icon: 'none' })
      } catch (e) { uni.showToast({ title: '上传失败', icon: 'none' }) }
    },
    fail: () => uni.showToast({ title: '上传失败', icon: 'none' })
  })
}

function preview (i) {
  uni.previewImage({ urls: photos.value, current: photos.value[i] })
}

async function doSubmit () {
  error.value = ''
  if (!reason.value.trim() || reason.value.trim().length < 10) { error.value = '申诉理由至少10个字'; return }
  if (!deduction.value) { uni.showToast({ title: '扣分信息缺失', icon: 'none' }); return }
  submitting.value = true
  try {
    const r = await submitAppeal({
      deduction_id: deduction.value.id,
      appeal_reason: reason.value.trim(),
      attachments: photos.value
    })
    if (r.code === 0) {
      uni.showToast({ title: '申诉已提交', icon: 'success' })
      setTimeout(() => uni.navigateBack(), 800)
    } else {
      error.value = r.msg || '提交失败'
    }
  } catch (e) { error.value = '提交失败，请重试' } finally { submitting.value = false }
}
</script>

<style scoped>
.as-page { min-height: 100vh; background: #f5f6fa; padding: 20rpx 24rpx 60rpx; }
.as-card { background: #fff; border-radius:20rpx; padding: 24rpx; margin-bottom: 20rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.as-row { display: flex; padding: 12rpx 0; }
.as-label { font-size: 26rpx; color: #4e5a6b; font-weight: 500; margin-bottom: 12rpx; display: block; }
.as-row .as-label { width: 180rpx; flex-shrink: 0; margin-bottom: 0; color: #8a9aa8; font-weight: 400; }
.as-value { flex: 1; font-size: 26rpx; color: #1d2129; }
.as-value.score { color: #f53f3f; font-weight: 700; }
.req { color: #f53f3f; }
.as-error { font-size: 24rpx; color: #f53f3f; margin-top: 10rpx; }
.as-photos { display: flex; gap: 16rpx; flex-wrap: wrap; margin-top: 12rpx; }
.as-photo { position: relative; }
.as-photo-img { width: 140rpx; height: 140rpx; border-radius:12rpx; }
.as-photo-del { position: absolute; top: -12rpx; right: -12rpx; width: 36rpx; height: 36rpx; border-radius:50%; background: #f53f3f; color: #fff; display: flex; align-items: center; justify-content: center; font-size: 24rpx; }
.as-photo-add { width: 140rpx; height: 140rpx; border-radius:12rpx; background: #f7f9fc; border: 2rpx dashed #d5dce4; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 6rpx; }
.as-add-text { font-size: 20rpx; color: #8a9aa8; }
.as-tips { margin-top: 16rpx; }
.as-tips text { display: block; font-size: 22rpx; color: #8a9aa8; line-height: 1.8; }
</style>
