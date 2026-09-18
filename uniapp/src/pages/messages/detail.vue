<template>
  <view class="detail-page">
    <view v-if="loading" class="loading">加载中...</view>
    <template v-else>
      <!-- 消息头部 -->
      <view class="detail-header">
        <view class="type-icon" :style="iconStyle(msg.msg_type)"><text>{{ iconText(msg.msg_type) }}</text></view>
        <view class="msg-title">{{ msg.title || '消息详情' }}</view>
        <view class="msg-meta">
          <text>{{ msg.from_user_name || '系统' }}</text>
          <text class="dot">·</text>
          <text>{{ msg.send_time || '' }}</text>
          <text class="dot">·</text>
          <text class="type-text">{{ msg.msg_type_text || '' }}</text>
        </view>
      </view>

      <!-- 消息正文 -->
      <view class="detail-body">
        <text class="content-text">{{ msg.content || '' }}</text>
      </view>

      <!-- 相关链接 -->
      <view v-if="msg.link_url" class="detail-attachment">
        <view class="attach-item" @click="goDetail">
          <MIcon name="link" :size="14" color="#4F46E5" />
          <view class="attach-info">
            <text class="attach-name">相关链接</text>
            <text class="attach-size">{{ msg.link_url }}</text>
          </view>
          <text class="attach-arrow">›</text>
        </view>
      </view>

      <!-- 操作按钮 -->
      <view class="detail-actions">
        <view class="btn btn-secondary" @click="markRead"><MIcon name="check" :size="15" color="#4e5a6b" /><text style="margin-left:4px">{{ msg.status === 1 ? '已读' : '标记已读' }}</text></view>
        <view class="btn btn-primary" @click="goDetail"><MIcon name="arrowRight" :size="15" color="#ffffff" /><text style="margin-left:4px">查看详情</text></view>
      </view>
    </template>
  </view>
</template>

<script setup>
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'

const msg = ref({})
const id = ref(0)
const loading = ref(true)

function getToken() {
  return uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
}
function api(url, method, data) {
  return new Promise((resolve, reject) => {
    uni.request({
      url: uni.$base + url,
      method: method || 'GET',
      data: data || {},
      header: { 'Content-Type': 'application/x-www-form-urlencoded', 'Authorization': 'Bearer ' + getToken() },
      success: (r) => r.data?.code === 0 ? resolve(r.data.data) : reject(r.data || { msg: '请求失败' }),
      fail: () => reject({ msg: '网络异常，请稍后重试' })
    })
  })
}

function iconText(t) {
  return { 1: 'megaphone', 2: 'clipboard', 3: 'checkCircle', 4: 'shield', 5: 'book', 6: 'wrench' }[t] || 'mail'
}
function iconStyle(t) {
  const c = {
    1: 'linear-gradient(135deg,#4F46E5,#7C6FF0)',
    2: 'linear-gradient(135deg,#34c796,#2d9b7a)',
    3: 'linear-gradient(135deg,#fb8a6e,#f06a4a)',
    4: 'linear-gradient(135deg,#fbaa50,#f58b2a)',
    5: 'linear-gradient(135deg,#50c8ff,#2d8cff)',
    6: 'linear-gradient(135deg,#60a5fa,#2563eb)'
  }
  return { background: c[t] || 'linear-gradient(135deg,#94a3b8,#64748b)' }
}

async function loadDetail() {
  try {
    const r = await api('/api/notification/detail/' + id.value)
    msg.value = r || {}
  } catch (e) {
    uni.showToast({ title: '加载失败', icon: 'none' })
  }
  loading.value = false
}

function markRead() {
  if (msg.value.status === 1) return
  api('/api/notification/read/' + msg.value.id, 'PUT').then(() => {
    msg.value.status = 1
    uni.showToast({ title: '已标记为已读', icon: 'success' })
  }).catch(() => {})
}

function goDetail() {
  const link = msg.value.link_url
  if (!link) { uni.showToast({ title: '暂无详情', icon: 'none' }); return }
  const l = String(link)
  if (l.startsWith('/pages')) {
    uni.navigateTo({ url: l, fail: () => uni.showToast({ title: '页面不存在', icon: 'none' }) })
  } else if (/^https?:\/\//.test(l)) {
    // #ifdef H5
    window.open(l)
    // #endif
    // #ifndef H5
    uni.showToast({ title: '请在浏览器打开链接', icon: 'none' })
    // #endif
  } else if (l.startsWith('/')) {
    // 相对路径：H5 直接跳转
    // #ifdef H5
    window.location.href = l
    // #endif
    // #ifndef H5
    uni.showToast({ title: '请在浏览器打开', icon: 'none' })
    // #endif
  } else {
    uni.showToast({ title: '暂无详情', icon: 'none' })
  }
}

onLoad((o) => {
  id.value = o.id || ''
  if (id.value) loadDetail()
  else { loading.value = false; uni.showToast({ title: '参数错误', icon: 'none' }) }
})
</script>

<style scoped>
.detail-page { min-height: 100vh; background: #F4F6FB; padding: 16px 16px 30px; box-sizing: border-box; }
.loading { text-align: center; padding: 80px 0; color: #999; }
.detail-header { background: #fff; border-radius:124px; padding: 20px; margin-bottom: 16px; box-shadow: 0 2px 12px rgba(0,0,0,0.01); }
.type-icon { width: 52px; height: 52px; border-radius:122px; display: flex; align-items: center; justify-content: center; font-size: 24px; color: #fff; margin-bottom: 12px; }
.msg-title { font-size: 18px; font-weight: 600; color: #1a2332; margin-bottom: 6px; }
.msg-meta { display: flex; align-items: center; gap: 10px; font-size: 13px; color: #8a9aa8; flex-wrap: wrap; }
.msg-meta .dot { color: #d5dce4; }
.msg-meta .type-text { color: #4F46E5; font-weight: 500; }
.detail-body { background: #fff; border-radius:124px; padding: 20px; margin-bottom: 16px; box-shadow: 0 2px 12px rgba(0,0,0,0.01); }
.content-text { font-size: 15px; line-height: 1.8; color: #2a3a4a; white-space: pre-wrap; word-break: break-word; }
.detail-attachment { background: #fff; border-radius:124px; padding: 12px 20px; margin-bottom: 16px; box-shadow: 0 2px 12px rgba(0,0,0,0.01); }
.attach-item { display: flex; align-items: center; gap: 12px; padding: 10px 12px; background: rgba(0,0,0,0.01); border-radius:24px; }
.attach-icon { font-size: 20px; width: 32px; text-align: center; }
.attach-info { flex: 1; min-width: 0; }
.attach-name { display: block; font-size: 14px; color: #1a2332; }
.attach-size { display: block; font-size: 12px; color: #b0c0cc; margin-top: 2px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.attach-arrow { color: #c0cedc; font-size: 16px; }
.detail-actions { display: flex; gap: 10px; padding: 4px 0 12px; }
.btn { flex: 1; padding: 14px 16px; border-radius:124px; font-size: 15px; font-weight: 500; display: flex; align-items: center; justify-content: center; gap: 8px; }
.btn:active { transform: scale(0.96); }
.btn-primary { background: linear-gradient(135deg, #4F46E5, #7C6FF0); color: #fff; box-shadow: 0 4px 16px rgba(110,142,251,0.15); }
.btn-secondary { background: #F4F6FB; color: #8a9aa8; border: 1px solid #E7ECF4; }
</style>
