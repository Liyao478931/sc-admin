<template>
  <view class="bp-page">
    <view class="bp-card">
      <view class="bp-row">
        <text class="bp-label">当前手机号</text>
        <text class="bp-value">{{ currentPhone || '未绑定' }}</text>
      </view>
      <view class="bp-row">
        <text class="bp-label">新手机号</text>
        <view class="bp-input-wrap">
          <u-input v-model="newPhone" type="number" maxlength="11" placeholder="请输入新手机号" border="none" :customStyle="{ height: '48px', fontSize: '15px' }" />
        </view>
      </view>
      <view class="bp-row">
        <text class="bp-label">验证码</text>
        <view class="bp-code-row">
          <u-input v-model="code" type="number" maxlength="6" placeholder="请输入验证码" border="none" :customStyle="{ height: '48px', fontSize: '15px' }" />
          <u-button size="small" :text="cd > 0 ? cd + 's' : '获取验证码'" :disabled="cd > 0" @click="sendCode" />
        </view>
      </view>
      <u-button type="primary" shape="circle" :text="submitting ? '绑定中...' : '确认绑定'" :loading="submitting" @click="doBind" />
    </view>
    <view class="bp-tips">绑定后可使用新手机号登录；验证码发送至新手机号。</view>
  </view>
</template>

<script setup>
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { get, post } from '@/utils/request.js'

const currentPhone = ref('')
const newPhone = ref('')
const code = ref('')
const cd = ref(0)
const submitting = ref(false)

onLoad(async () => {
  try {
    const r = await get('/api/user/profile')
    if (r.code === 0 && r.data) currentPhone.value = r.data.phone || r.data.user_phone || ''
  } catch (e) {}
})

function sendCode () {
  if (!/^1[3-9]\d{9}$/.test(newPhone.value)) { uni.showToast({ title: '请输入正确的新手机号', icon: 'none' }); return }
  post('/api/profile/change-phone-sms', { new_phone: newPhone.value })
    .then(r => {
      if (r.code === 0) {
        uni.showToast({ title: '验证码已发送', icon: 'success' })
        cd.value = 60
        const t = setInterval(() => { cd.value--; if (cd.value <= 0) clearInterval(t) }, 1000)
      } else {
        uni.showToast({ title: r.msg || '发送失败', icon: 'none' })
      }
    })
    .catch(() => uni.showToast({ title: '发送失败', icon: 'none' }))
}

async function doBind () {
  if (!/^1[3-9]\d{9}$/.test(newPhone.value)) { uni.showToast({ title: '请输入正确的新手机号', icon: 'none' }); return }
  if (!code.value) { uni.showToast({ title: '请输入验证码', icon: 'none' }); return }
  submitting.value = true
  try {
    const r = await post('/api/profile/change-phone', { new_phone: newPhone.value, code: code.value })
    if (r.code === 0) {
      uni.showToast({ title: '绑定成功', icon: 'success' })
      setTimeout(() => uni.navigateBack(), 800)
    } else {
      uni.showToast({ title: r.msg || '绑定失败', icon: 'none' })
    }
  } catch (e) {} finally { submitting.value = false }
}
</script>

<style scoped>
.bp-page { min-height: 100vh; background: #f5f6fa; padding: 24rpx; }
.bp-card { background: #fff; border-radius:20rpx; padding: 24rpx 24rpx 40rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.bp-row { display: flex; align-items: center; padding: 24rpx 0; border-bottom: 1rpx solid #EDF0F8; }
.bp-label { width: 180rpx; font-size: 26rpx; color: #4e5a6b; }
.bp-value { flex: 1; font-size: 26rpx; color: #1d2129; }
.bp-input-wrap { flex: 1; }
.bp-code-row { flex: 1; display: flex; align-items: center; gap: 16rpx; }
.bp-card > .u-button { margin-top: 40rpx; }
.bp-tips { font-size: 22rpx; color: #8a9aa8; margin-top: 20rpx; text-align: center; }
</style>
