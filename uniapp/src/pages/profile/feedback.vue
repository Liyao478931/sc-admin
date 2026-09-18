<template>
  <view class="feedback-page">
    <view class="form-card">
      <view class="form-item">
        <text class="form-label">反馈类型</text>
        <picker :range="typeOptions" @change="onTypeChange">
          <view class="picker-value" :class="{ placeholder: !type }">
            {{ type || '请选择类型' }}
          </view>
        </picker>
      </view>

      <view class="form-item">
        <text class="form-label">反馈内容</text>
        <u-textarea v-model="content" placeholder="请详细描述您的问题或建议..." :maxlength="500" />
      </view>

      <view class="form-item">
        <text class="form-label">图片上传（最多3张）</text>
        <view class="upload-grid">
          <view v-for="(img, i) in images" :key="i" class="upload-item">
            <image :src="img" mode="aspectFill" class="upload-img" @click="previewImage(i)"></image>
            <view class="upload-del" @click="removeImage(i)"><MIcon name="close" :size="12" color="#ffffff" /></view>
          </view>
          <view v-if="images.length < 3" class="upload-add" @click="addImage">
            <text class="upload-add-icon">+</text>
          </view>
        </view>
      </view>
    </view>

    <view v-if="error" class="error-text">{{ error }}</view>

    <u-button type="primary" shape="circle" :text="submitting ? '提交中...' : '提交反馈'" :loading="submitting" @click="handleSubmit" />
  </view>
</template>

<script setup>
import { ref } from 'vue'

const typeOptions = ['请选择类型', '建议', '报修', '投诉', '其他']
const type = ref('')
const content = ref('')
const images = ref([])
const error = ref('')
const submitting = ref(false)

function goBack() { uni.navigateBack() }

function onTypeChange(e) {
  const idx = Number(e.detail.value)
  type.value = typeOptions[idx] === '请选择类型' ? '' : typeOptions[idx]
}

function addImage() {
  if (images.value.length >= 3) { uni.showToast({ title: '最多上传3张图片', icon: 'none' }); return }
  uni.chooseImage({ count: 3 - images.value.length }).then(res => {
    if (!res.tempFilePaths?.length) return
    res.tempFilePaths.forEach(p => images.value.push(p))
  })
}

function removeImage(i) { images.value.splice(i, 1) }

function previewImage(i) {
  uni.previewImage({ current: images.value[i], urls: images.value })
}

async function uploadImage(filePath) {
  return new Promise((resolve) => {
    const token = uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
    uni.uploadFile({
      url: uni.$base + '/api/upload',
      filePath,
      name: 'file',
      header: { 'Authorization': 'Bearer ' + token },
      success: (r) => {
        const rd = JSON.parse(r.data || '{}')
        resolve(rd.code === 0 ? rd.data?.url : null)
      },
      fail: () => resolve(null)
    })
  })
}

async function handleSubmit() {
  error.value = ''
  if (!type.value) { error.value = '请选择反馈类型'; return }
  if (!content.value || content.value.trim().length < 10) { error.value = '反馈内容不能少于10个字符'; return }

  submitting.value = true
  try {
    // 先上传图片
    const uploaded = []
    for (const img of images.value) {
      const url = img.startsWith('http') || img.startsWith('/uploads') ? img : await uploadImage(img)
      if (url) uploaded.push(url)
    }

    const token = uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
    uni.request({
      url: uni.$base + '/api/feedback',
      method: 'POST',
      data: { type: type.value, content: content.value.trim(), images: uploaded },
      header: { 'Content-Type': 'application/x-www-form-urlencoded', 'Authorization': 'Bearer ' + token },
      success: (r) => {
        submitting.value = false
        if (r.data?.code === 0) {
          uni.showToast({ title: '反馈提交成功，感谢您的建议！', icon: 'none' })
          setTimeout(() => uni.navigateBack(), 1500)
        } else {
          error.value = r.data?.msg || '提交失败'
        }
      },
      fail: () => { submitting.value = false; error.value = '网络异常，请稍后重试' }
    })
  } catch (e) {
    submitting.value = false
    error.value = '图片上传失败，请重试'
  }
}
</script>

<style scoped>
.feedback-page { min-height: 100vh; background: #F5F6FA; }
.page-header { height: 44px; background: #fff; display: flex; align-items: center; justify-content: space-between; padding: 0 12px; border-bottom: 1px solid #E8ECF1; }
.header-back { width: 44px; height: 44px; display: flex; align-items: center; }
.header-arrow { font-size: 28px; color: #303133; }
.header-title { font-size: 16px; font-weight: 600; color: #303133; }
.header-placeholder { width: 44px; }

.form-card { background: #fff; margin: 12px 16px; border-radius:24px; padding: 0 16px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.form-item { padding: 14px 0; border-bottom: 1px solid #F5F6FA; }
.form-item:last-child { border-bottom: none; }
.form-label { font-size: 14px; color: #303133; margin-bottom: 8px; display: block; }
.picker-value { height: 40px; background: #F5F6FA; border-radius:24px; padding: 0 12px; display: flex; align-items: center; font-size: 15px; }
.picker-value.placeholder { color: #C0C4CC; }
.form-textarea { width: 100%; min-height: 100px; background: #F5F6FA; border-radius:24px; padding: 10px 12px; font-size: 15px; box-sizing: border-box; }
.ph { color: #C0C4CC; }

.upload-grid { display: flex; flex-wrap: wrap; gap: 10px; }
.upload-item { width: 80px; height: 80px; position: relative; }
.upload-img { width: 100%; height: 100%; border-radius:24px; }
.upload-del { position: absolute; top: -6px; right: -6px; width: 20px; height: 20px; background: rgba(0,0,0,0.6); color: #fff; border-radius:50%; display: flex; align-items: center; justify-content: center; font-size: 12px; }
.upload-add { width: 80px; height: 80px; background: #F5F6FA; border-radius:24px; border: 1px dashed #DCDFE6; display: flex; align-items: center; justify-content: center; }
.upload-add-icon { font-size: 28px; color: #C0C4CC; }

.error-text { color: #EF4444; font-size: 13px; padding: 8px 20px; }
.submit-btn { margin: 20px 16px; width: calc(100% - 32px); height: 44px; border-radius:24px; background: #4F46E5; color: #fff; font-size: 16px; border: none; display: flex; align-items: center; justify-content: center; }
.submit-btn[disabled] { opacity: 0.6; }
</style>
