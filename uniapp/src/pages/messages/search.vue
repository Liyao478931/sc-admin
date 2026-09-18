<template>
  <view class="search-page">
    <!-- 搜索栏 -->
    <view class="search-bar">
      <view class="search-input-wrap">
        <u-input v-model="keyword" placeholder="搜索消息标题 / 内容" prefixIcon="search" border="none" confirm-type="search" :customStyle="{ height: '72rpx', fontSize: '26rpx' }" @confirm="doSearch" />
        <view v-if="keyword" class="clear-btn" @click="clearKeyword"><MIcon name="close" :size="14" color="#b0c0cc" /></view>
      </view>
      <view class="search-btn" @click="doSearch"><text>搜索</text></view>
    </view>

    <!-- 结果列表 -->
    <scroll-view scroll-y class="result-list">
      <template v-if="list.length">
        <view class="msg-card" :class="{ unread: m.status === 0 }" v-for="m in list" :key="m.msg_id" @click="onMsgClick(m)">
          <view class="msg-icon" :style="iconStyle(m.msg_type)"><text>{{ iconText(m.msg_type) }}</text></view>
          <view class="msg-body">
            <view class="msg-title-row">
              <text class="msg-title-text" :class="{ bold: m.status === 0 }">{{ m.title || '消息' }}</text>
              <text class="msg-time">{{ shortTime(m.send_time) }}</text>
            </view>
            <text class="msg-content">{{ m.content || '' }}</text>
          </view>
          <view v-if="m.status === 0" class="msg-dot"></view>
        </view>
        <view v-if="finished" class="msg-finished">没有更多了</view>
        <view v-if="loading" class="msg-finished">加载中...</view>
      </template>
      <view v-else-if="searched && !loading" class="msg-empty">
        <MIcon name="search" :size="44" color="#c6d2e0" />
        <text class="empty-title">未找到相关消息</text>
        <text class="empty-desc">换个关键词试试</text>
      </view>
      <view v-if="!searched && !loading && !list.length" class="msg-empty">
        <MIcon name="search" :size="44" color="#c6d2e0" />
        <text class="empty-title">搜索历史消息</text>
        <text class="empty-desc">输入关键词查找消息</text>
      </view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref } from 'vue'

const keyword = ref('')
const list = ref([])
const page = ref(1)
const limit = 20
const total = ref(0)
const finished = ref(false)
const loading = ref(false)
const searched = ref(false)

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

function shortTime(t) {
  if (!t) return ''
  const d = new Date(String(t).replace(/-/g, '/'))
  if (isNaN(d.getTime())) return ''
  const pad = n => n < 10 ? '0' + n : '' + n
  return pad(d.getMonth() + 1) + '/' + pad(d.getDate()) + ' ' + pad(d.getHours()) + ':' + pad(d.getMinutes())
}

function iconText(t) {
  return { 1: 'megaphone', 2: 'clipboard', 3: 'checkCircle', 4: 'shield', 5: 'book', 6: 'wrench' }[t] || 'mail'
}
function iconStyle(t) {
  const c = {
    1: 'linear-gradient(135deg,#4F46E5,#7C6FF0)',
    2: 'linear-gradient(135deg,#34d399,#059669)',
    3: 'linear-gradient(135deg,#fb923c,#ea580c)',
    4: 'linear-gradient(135deg,#fbbf24,#d97706)',
    5: 'linear-gradient(135deg,#38bdf8,#0284c7)',
    6: 'linear-gradient(135deg,#60a5fa,#2563eb)'
  }
  return { background: c[t] || 'linear-gradient(135deg,#94a3b8,#64748b)' }
}

async function doSearch() {
  const kw = keyword.value.trim()
  if (!kw) { uni.showToast({ title: '请输入搜索关键词', icon: 'none' }); return }
  page.value = 1
  finished.value = false
  searched.value = true
  loading.value = true
  try {
    const r = await api('/api/notification/list', 'GET', { keyword: kw, page: page.value, limit })
    const d = r || {}
    list.value = d.list || []
    total.value = d.total || 0
    if (list.value.length >= total.value) finished.value = true
  } catch (e) {
    uni.showToast({ title: '搜索失败', icon: 'none' })
  }
  loading.value = false
}

function clearKeyword() {
  keyword.value = ''
  list.value = []
  searched.value = false
}

async function onMsgClick(m) {
  if (m.status === 0) {
    try { await api('/api/notification/read/' + m.id, 'PUT') } catch (e) {}
    m.status = 1
  }
  const link = m.link_url
  if (link && String(link).startsWith('/pages')) {
    uni.navigateTo({ url: link, fail: () => uni.navigateTo({ url: '/pages/messages/detail?id=' + m.id }) })
  } else {
    uni.navigateTo({ url: '/pages/messages/detail?id=' + m.id })
  }
}
</script>

<style scoped>
.search-page { height: 100vh; overflow: hidden; background: #F4F6FB; display: flex; flex-direction: column; }
.search-bar { display: flex; align-items: center; gap: 10px; padding: 12px 16px; padding-right: calc(16px + constant(safe-area-inset-right)); padding-right: calc(16px + env(safe-area-inset-right)); background: #fff; }
.search-input-wrap { flex: 1; display: flex; align-items: center; background: #EDF0F8; border-radius:24px; padding: 0 14px; height: 38px; }
.search-input { flex: 1; font-size: 14px; height: 38px; }
.clear-btn { width: 20px; height: 20px; border-radius:50%; background: #c0cedc; color: #fff; font-size: 11px; display: flex; align-items: center; justify-content: center; }
.search-btn { flex-shrink: 0; color: #4F46E5; font-size: 15px; font-weight: 500; padding: 6px 10px; }
.result-list { flex: 1; min-height: 0; padding: 12px; box-sizing: border-box; }
.msg-card { display: flex; align-items: center; gap: 12px; background: #fff; border-radius:122px; padding: 14px 16px; margin-bottom: 8px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.msg-card.unread { background: #f0f6ff; border: 1px solid #d6e6ff; }
.msg-icon { width: 44px; height: 44px; border-radius:50%; display: flex; align-items: center; justify-content: center; font-size: 20px; flex-shrink: 0; }
.msg-body { flex: 1; min-width: 0; }
.msg-title-row { display: flex; align-items: center; justify-content: space-between; }
.msg-title-text { font-size: 14px; color: #1a2332; flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.msg-title-text.bold { font-weight: 700; }
.msg-time { font-size: 11px; color: #b0c0cc; margin-left: 8px; flex-shrink: 0; }
.msg-content { display: block; font-size: 13px; color: #8a9aa8; margin-top: 3px; overflow: hidden; text-overflow: ellipsis; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; }
.msg-dot { width: 8px; height: 8px; border-radius:50%; background: #ff6b6b; box-shadow: 0 0 6px rgba(255,107,107,0.5); flex-shrink: 0; }
.msg-finished { text-align: center; color: #b0c0cc; font-size: 12px; padding: 16px 0; }
.msg-empty { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 80px 0; }
.empty-icon { font-size: 56px; }
.empty-title { font-size: 16px; color: #8a9aa8; margin-top: 16px; font-weight: 500; }
.empty-desc { font-size: 13px; color: #b0c0cc; margin-top: 6px; }
</style>
