<template>
  <view class="password-page">
    <view class="form-card">
      <view class="form-item">
        <text class="form-label">手机号</text>
        <view class="sms-row">
          <u-input v-model="phone" type="number" maxlength="11" placeholder="请输入手机号" border="none" :customStyle="{ height: '48px', fontSize: '15px' }" />
          <u-button size="small" :text="countdown > 0 ? countdown + 's' : '获取验证码'" :disabled="countdown > 0" @click="sendCode" />
        </view>
      </view>
      <view class="form-item">
        <text class="form-label">验证码</text>
        <u-input v-model="smsCode" type="number" maxlength="6" placeholder="请输入手机验证码" border="none" :customStyle="{ height: '48px', fontSize: '15px' }" />
      </view>
      <view class="form-item">
        <text class="form-label">原密码</text>
        <u-input v-model="oldPassword" type="password" placeholder="请输入原密码" border="none" :customStyle="{ height: '48px', fontSize: '15px' }" />
      </view>
      <view class="form-item">
        <text class="form-label">新密码</text>
        <u-input v-model="newPassword" type="password" placeholder="请输入新密码（至少6位）" border="none" :customStyle="{ height: '48px', fontSize: '15px' }" />
      </view>
      <view class="form-item">
        <text class="form-label">确认新密码</text>
        <u-input v-model="confirmPassword" type="password" placeholder="请再次输入新密码" border="none" :customStyle="{ height: '48px', fontSize: '15px' }" />
      </view>
    </view>

    <view v-if="error" class="error-text">{{ error }}</view>

    <u-button type="primary" shape="circle" :text="submitting ? '修改中...' : '确认修改'" :loading="submitting" @click="handleSubmit" />
  </view>
</template>

<script setup>
import { ref, onUnmounted } from 'vue'

const phone = ref('')
const smsCode = ref('')
const oldPassword = ref('')
const newPassword = ref('')
const confirmPassword = ref('')
const error = ref('')
const submitting = ref(false)
const countdown = ref(0)
let timer = null

function goBack() { uni.navigateBack() }

function getToken() {
  return uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
}

function api(url, method, data) {
  return new Promise((resolve, reject) => {
    uni.request({
      url: uni.$base + url,
      method: method || 'POST',
      data: data || {},
      header: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Bearer ' + getToken()
      },
      success: (r) => r.data?.code === 0 ? resolve(r.data) : reject(r.data || { msg: '请求失败' }),
      fail: () => reject({ msg: '网络异常，请稍后重试' })
    })
  })
}

function startCountdown() {
  countdown.value = 60
  timer = setInterval(() => {
    countdown.value--
    if (countdown.value <= 0) { clearInterval(timer); timer = null }
  }, 1000)
}

async function sendCode() {
  if (!/^1[3-9]\d{9}$/.test(phone.value)) { error.value = '请输入正确的手机号'; return }
  error.value = ''
  try {
    const res = await api('/api/user/password/sms', 'POST', { phone: phone.value })
    startCountdown()
    uni.showToast({ title: '验证码已发送', icon: 'success' })
  } catch (e) {
    error.value = e.msg || '验证码发送失败'
  }
}

async function handleSubmit() {
  error.value = ''
  if (!/^1[3-9]\d{9}$/.test(phone.value)) { error.value = '请输入正确的手机号'; return }
  if (!smsCode.value || smsCode.value.length !== 6) { error.value = '请输入6位验证码'; return }
  if (!oldPassword.value) { error.value = '请输入原密码'; return }
  if (!newPassword.value || newPassword.value.length < 6) { error.value = '新密码不能少于6位'; return }
  if (newPassword.value !== confirmPassword.value) { error.value = '两次输入的新密码不一致'; return }

  submitting.value = true
  try {
    await api('/api/user/password', 'POST', {
      phone: phone.value,
      sms_code: smsCode.value,
      old_password: oldPassword.value,
      new_password: newPassword.value
    })
    uni.showToast({ title: '密码修改成功', icon: 'success' })
    setTimeout(() => uni.navigateBack(), 1500)
  } catch (e) {
    error.value = e.msg || '修改失败'
  }
  submitting.value = false
}

onUnmounted(() => { if (timer) clearInterval(timer) })
</script>

<style scoped>
.password-page { min-height: 100vh; background: #F5F6FA; }
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
.form-input { height: 40px; background: #F5F6FA; border-radius:24px; padding: 0 12px; font-size: 15px; }
.ph { color: #C0C4CC; }

.sms-row { display: flex; gap: 8px; }
.sms-input { flex: 1; }
.sms-btn { height: 40px; padding: 0 16px; background: #4F46E5; color: #fff; border: none; border-radius:24px; font-size: 14px; flex-shrink: 0; display: flex; align-items: center; justify-content: center; }
.sms-btn[disabled] { opacity: 0.5; }

.error-text { color: #EF4444; font-size: 13px; padding: 8px 20px; }
.submit-btn { margin: 20px 16px; width: calc(100% - 32px); height: 44px; border-radius:24px; background: #4F46E5; color: #fff; font-size: 16px; border: none; display: flex; align-items: center; justify-content: center; }
.submit-btn[disabled] { opacity: 0.6; }
</style>
