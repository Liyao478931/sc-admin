<template>
  <view class="wechat-page">
    <view v-if="loading" class="loading">加载中...</view>
    <template v-else>
      <view class="section-label">账号绑定</view>
      <view class="settings-card">
        <!-- 公众号微信 -->
        <view class="settings-item">
          <view class="left">
            <view class="icon-wrap" style="background:#07c160;"><u-icon name="weixin-fill" color="#fff" size="18" /></view>
            <view class="info">
              <text class="title">公众号微信</text>
              <text class="desc">微信公众号授权登录</text>
            </view>
          </view>
          <view class="right">
            <text class="value" :class="status.mp_bound ? 'bound' : 'unbound'">{{ status.mp_bound ? '已绑定' : '未绑定' }}</text>
            <u-button size="small" :type="status.mp_bound ? 'error' : 'primary'" :text="status.mp_bound ? '解绑' : '去绑定'" shape="circle" @click="handleMp" />
          </view>
        </view>
        <!-- 小程序微信 -->
        <view class="settings-item">
          <view class="left">
            <view class="icon-wrap" style="background:#2d8cff;"><u-icon name="weixin-circle-fill" color="#fff" size="18" /></view>
            <view class="info">
              <text class="title">小程序微信</text>
              <text class="desc">微信小程序授权登录</text>
            </view>
          </view>
          <view class="right">
            <text class="value" :class="status.mini_bound ? 'bound' : 'unbound'">{{ status.mini_bound ? '已绑定' : '未绑定' }}</text>
            <u-button size="small" :type="status.mini_bound ? 'error' : 'primary'" :text="status.mini_bound ? '解绑' : '去绑定'" shape="circle" @click="handleMini" />
          </view>
        </view>
      </view>

      <view class="tips">
        <text class="tips-text">提示：解绑微信后，将无法通过微信快速登录。解绑后可重新绑定。</text>
      </view>
    </template>
  </view>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { onLoad } from '@dcloudio/uni-app'

const loading = ref(true)
const status = ref({ mp_bound: false, mini_bound: false, any_bound: false })

function api(url, method = 'GET', data = {}) {
  const token = uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
  const header = { 'Content-Type': 'application/x-www-form-urlencoded' }
  if (token) header['Authorization'] = 'Bearer ' + token
  return new Promise((resolve, reject) => {
    uni.request({
      url: uni.$base + url,
      method,
      data,
      header,
      timeout: 10000,
      success: res => res.data?.code === 0 ? resolve(res.data.data) : reject(res.data || { msg: '请求失败' }),
      fail: () => reject({ msg: '网络异常' })
    })
  })
}

async function loadStatus() {
  // 未登录直接显示表单，不阻塞页面
  if (!uni.getStorageSync('access_token') && !uni.getStorageSync('token')) {
    loading.value = false
    return
  }
  try {
    const d = await api('/api/user/wechat/status')
    status.value = d || { mp_bound: false, mini_bound: false, any_bound: false }
  } catch (e) {
    // 接口失败不阻塞页面，保持默认未绑定状态
    status.value = { mp_bound: false, mini_bound: false, any_bound: false }
  } finally {
    loading.value = false
  }
}

async function unbind(platform) {
  const name = platform === 'mp' ? '公众号' : '小程序'
  uni.showModal({
    title: '解绑确认',
    content: `确定要解绑${name}微信吗？解绑后将无法通过${name}快速登录。`,
    confirmColor: '#EF4444',
    success: async (r) => {
      if (!r.confirm) return
      try {
        await api('/api/user/wechat/unbind', 'POST', { platform })
        uni.showToast({ title: '解绑成功', icon: 'success' })
        await loadStatus()
      } catch (e) {
        uni.showToast({ title: e?.msg || '解绑失败', icon: 'none' })
      }
    }
  })
}

function handleMp() {
  if (status.value.mp_bound) {
    unbind('mp')
  } else {
    bindMp()
  }
}

function handleMini() {
  if (status.value.mini_bound) {
    unbind('mini')
  } else {
    // 小程序端由 uni.login 绑定；H5 端提示
    // #ifdef MP-WEIXIN
    bindMini()
    // #endif
    // #ifndef MP-WEIXIN
    uni.showToast({ title: '请在微信小程序中使用', icon: 'none' })
    // #endif
  }
}

// 公众号网页授权绑定（H5 场景）
function bindMp() {
  uni.showLoading({ title: '跳转微信授权...' })
  const token = uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
  uni.request({
    url: uni.$base + '/api/mobile/wechat/oauth-url',
    data: { mode: 'bind', state: '/h5/#/pages/profile/wechat', token: token },
    success: (res) => {
      uni.hideLoading()
      if (res.data?.code === 0 && res.data?.data?.url) {
        // 后端 oauth-url 已把 token 拼进回调 URL 的 state 参数，微信回调后原样回传
        window.location.href = res.data.data.url
      } else {
        uni.showToast({ title: '获取授权链接失败', icon: 'none' })
      }
    },
    fail: () => { uni.hideLoading(); uni.showToast({ title: '网络异常', icon: 'none' }) }
  })
}

// 小程序绑定（需要登录态 + code）
function bindMini() {
  const token = uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
  if (!token) { uni.showToast({ title: '请先登录', icon: 'none' }); return }
  uni.login({
    provider: 'weixin',
    success: (loginRes) => {
      uni.request({
        url: uni.$base + '/api/mobile/wechat/mini-login',
        method: 'POST',
        data: { code: loginRes.code },
        header: { 'Content-Type': 'application/x-www-form-urlencoded', 'Authorization': 'Bearer ' + token },
        success: (r) => {
          if (r.data?.code === 0) {
            uni.showToast({ title: '小程序绑定成功', icon: 'success' })
            loadStatus()
          } else {
            uni.showToast({ title: r.data?.msg || '绑定失败', icon: 'none' })
          }
        },
        fail: () => uni.showToast({ title: '绑定失败', icon: 'none' })
      })
    },
    fail: () => uni.showToast({ title: '微信登录失败', icon: 'none' })
  })
}

onMounted(loadStatus)

// 处理微信 OAuth 绑定回调后的结果（err 参数由后端重定向 URL 携带）
onLoad((options) => {
  const err = options?.err || ''
  if (!err) return
  setTimeout(() => {
    if (err === 'bind_ok') {
      uni.showToast({ title: '微信绑定成功', icon: 'success' })
      loadStatus()
    } else if (err === 'not_login') {
      uni.showToast({ title: '请先登录', icon: 'none' })
    } else if (err === 'bound_elsewhere') {
      uni.showToast({ title: '该微信已被其他用户绑定', icon: 'none' })
    } else if (err === 'not_found') {
      uni.showToast({ title: '用户不存在', icon: 'none' })
    } else {
      uni.showToast({ title: '绑定失败', icon: 'none' })
    }
  }, 300)
})
</script>

<style scoped>
.wechat-page { min-height: 100vh; background: #F4F6FB; padding: 16px 16px 30px; box-sizing: border-box; }
.section-label { font-size: 12px; color: #9aabba; font-weight: 500; padding: 0 4px 10px; letter-spacing: 0.3px; }
.settings-card { background: #fff; border-radius:122px; overflow: hidden; margin-bottom: 16px; box-shadow: 0 1px 4px rgba(0,0,0,0.02); border: 1px solid rgba(0,0,0,0.02); }
.settings-item { display: flex; align-items: center; padding: 14px 18px; border-bottom: 1px solid #F4F6FB; }
.settings-item:last-child { border-bottom: none; }
.settings-item .left { display: flex; align-items: center; gap: 14px; flex: 1; min-width: 0; }
.settings-item .left .icon-wrap { width: 36px; height: 36px; border-radius:22px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; font-size: 16px; color: #fff; }
.settings-item .left .info { display: flex; flex-direction: column; }
.settings-item .left .info .title { font-size: 15px; font-weight: 500; color: #1a2332; }
.settings-item .left .info .desc { font-size: 12px; color: #9aabba; margin-top: 1px; }
.settings-item .right { display: flex; align-items: center; gap: 10px; flex-shrink: 0; }
.settings-item .right .value { font-size: 14px; color: #8a9aa8; }
.settings-item .right .value.bound { color: #3d5a73; font-weight: 500; }
.settings-item .right .value.unbound { color: #c97d5a; font-weight: 500; }
.btn { padding: 6px 16px; border-radius:122px; font-size: 13px; flex-shrink: 0; }
.btn-primary { background: #07c160; color: #fff; }
.btn-danger { background: #fef0f0; color: #e74c5e; border: 1px solid #fbc4c4; }
.tips { padding: 4px 16px; }
.tips-text { font-size: 12px; color: #b0b8c4; line-height: 1.6; }
.loading { text-align: center; padding: 60px; color: #999; }
</style>
