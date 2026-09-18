<template>
  <view class="msg-page">
    <!-- 顶部导航 -->
    <view class="msg-nav" :style="{ paddingRight: (16 + capsuleRight) + 'px' }">
      <view class="msg-nav-left">
        <text class="msg-nav-title">消息</text>
        <view class="msg-nav-actions">
          <view class="tool-btn" @click="refresh"><u-icon name="reload" color="#8a9aa8" size="20"></u-icon></view>
          <view class="tool-btn" @click="goSearch"><u-icon name="search" color="#8a9aa8" size="20"></u-icon></view>
          <view class="tool-btn" @click="readAll"><text class="tool-text">全部已读</text></view>
        </view>
      </view>
    </view>

    <!-- 分类 Tab -->
    <scroll-view scroll-x class="msg-tabs" :show-scrollbar="false">
      <view class="msg-tab" :class="{ active: activeType === t.value }" v-for="t in tabs" :key="t.value" @click="switchTab(t.value)">
        <text>{{ t.label }}</text>
        <text v-if="t.value === 0 && unreadTotal > 0" class="tab-badge">{{ unreadTotal > 99 ? '99+' : unreadTotal }}</text>
      </view>
    </scroll-view>

    <!-- 未登录占位 -->
    <view v-if="!isLogin" class="msg-login-tip">
      <view class="msg-login-icon"><MIcon name="lock" :size="38" color="#c0cedc" /></view>
      <text class="msg-login-text">登录后查看消息</text>
      <view class="msg-login-btn" @click="goLogin">去登录</view>
    </view>
    <!-- 消息列表 -->
    <scroll-view v-else scroll-y class="msg-list" :refresher-enabled="true" :refresher-triggered="refreshing" @refresherrefresh="onRefresh" @scrolltolower="loadMore">
      <template v-if="groups.length">
        <view v-for="(g, gi) in groups" :key="gi">
          <view class="time-label">{{ g.label }}</view>
          <view class="msg-card" :class="{ unread: m.status === 0 }" v-for="m in g.list" :key="m.msg_id" @click="onMsgClick(m)">
            <view class="msg-icon" :style="iconStyle(m.msg_type)"><u-icon :name="iconText(m.msg_type)" color="#fff" size="18" /></view>
            <view class="msg-body">
              <view class="msg-title-row">
                <text class="msg-title-text" :class="{ bold: m.status === 0 }">{{ m.title || '消息' }}</text>
                <text class="msg-time">{{ fmtTime(m.send_time).time }}</text>
              </view>
              <text class="msg-content">{{ m.content || '' }}</text>
            </view>
            <view v-if="m.status === 0" class="msg-dot"></view>
          </view>
        </view>
        <view v-if="finished && list.length" class="msg-finished">没有更多了</view>
        <view v-if="loadingMore" class="msg-finished">加载中...</view>
      </template>
      <u-empty v-else-if="!loading" text="暂无消息" description="当前分类下没有消息" mode="list" />
      <view v-if="loading && !list.length" class="msg-finished">加载中...</view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  capsuleRight: { type: Number, default: 0 }
})

const tabs = [
  { label: '全部', value: 0 }, { label: '系统', value: 1 }, { label: '任务', value: 2 },
  { label: '审批', value: 3 }, { label: '预警', value: 4 }, { label: '培训', value: 5 }, { label: '工单', value: 6 }
]
const activeType = ref(0)
const list = ref([])
const page = ref(1)
const limit = 15
const total = ref(0)
const finished = ref(false)
const loading = ref(false)
const loadingMore = ref(false)
const refreshing = ref(false)
const unreadTotal = ref(0)
const isLogin = computed(() => !!getToken())
function goLogin() {
  const redirect = encodeURIComponent('/pages/diy/index?type=messages')
  uni.navigateTo({ url: '/pages/login/index?redirect=' + redirect })
}
let pollTimer = null

const groups = computed(() => {
  const map = {}
  list.value.forEach(m => {
    const g = fmtTime(m.send_time).group
    if (!map[g]) map[g] = []
    map[g].push(m)
  })
  return ['今天', '昨天', '更早'].filter(k => map[k]).map(k => ({ label: k, list: map[k] }))
})

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

function pad(n) { return n < 10 ? '0' + n : '' + n }
function fmtTime(t) {
  if (!t) return { group: '更早', time: '' }
  const d = new Date(String(t).replace(/-/g, '/'))
  if (isNaN(d.getTime())) return { group: '更早', time: '' }
  const now = new Date()
  const startToday = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  const dStart = new Date(d.getFullYear(), d.getMonth(), d.getDate())
  const diff = Math.floor((startToday - dStart) / 86400000)
  if (diff <= 0) return { group: '今天', time: pad(d.getHours()) + ':' + pad(d.getMinutes()) }
  if (diff === 1) return { group: '昨天', time: '昨天' }
  if (diff <= 7) return { group: '更早', time: diff + '天前' }
  return { group: '更早', time: (d.getMonth() + 1) + '/' + d.getDate() }
}

function iconText(t) {
  return { 1: 'bell', 2: 'list', 3: 'checkmark', 4: 'lock', 5: 'folder', 6: 'setting' }[t] || 'email'
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

async function loadList(reset = false) {
  if (loading.value) return
  if (reset) { page.value = 1; finished.value = false }
  loading.value = true
  try {
    const r = await api('/api/notification/list', 'GET', { msg_type: activeType.value, page: page.value, limit })
    const d = r || {}
    const items = d.list || []
    if (reset) list.value = items
    else list.value = list.value.concat(items)
    total.value = d.total || 0
    if (list.value.length >= total.value) finished.value = true
  } catch (e) {
    uni.showToast({ title: '加载失败', icon: 'none' })
  }
  loading.value = false
  refreshing.value = false
  loadingMore.value = false
}

async function loadUnread() {
  try {
    const r = await api('/api/notification/unread-count')
    unreadTotal.value = (r && r.count) || 0
  } catch (e) {}
}

function switchTab(t) {
  if (activeType.value === t) return
  activeType.value = t
  list.value = []
  loadList(true)
}
function refresh() {
  uni.showToast({ title: '刷新中', icon: 'none' })
  loadList(true)
  loadUnread()
}
function onRefresh() { refreshing.value = true; loadList(true) }
function loadMore() {
  if (!finished.value && !loading.value) { loadingMore.value = true; page.value++; loadList() }
}

async function onMsgClick(m) {
  // 未读 → 标记已读（按主键 id）
  if (m.status === 0) {
    try { await api('/api/notification/read/' + m.id, 'PUT') } catch (e) {}
    m.status = 1
    if (unreadTotal.value > 0) unreadTotal.value--
  }
  // 优先跳转业务链接，否则进入消息详情页
  const link = m.link_url
  if (link && String(link).startsWith('/pages')) {
    uni.navigateTo({ url: link, fail: () => goDetail(m) })
  } else {
    goDetail(m)
  }
}

function goDetail(m) {
  uni.navigateTo({ url: '/pages/messages/detail?id=' + m.id })
}

function readAll() {
  uni.showModal({
    title: '提示',
    content: '确认将所有消息标记为已读吗？',
    success: async (r) => {
      if (!r.confirm) return
      try {
        await api('/api/notification/read-all', 'PUT')
        list.value.forEach(m => { m.status = 1 })
        unreadTotal.value = 0
        uni.showToast({ title: '已全部标记为已读', icon: 'success' })
      } catch (e) {
        uni.showToast({ title: '操作失败', icon: 'none' })
      }
    }
  })
}

function goSearch() { uni.navigateTo({ url: '/pages/messages/search' }) }

onMounted(() => {
  if (!getToken()) return
  loadList(true)
  loadUnread()
  pollTimer = setInterval(loadUnread, 30000)
})
onUnmounted(() => { if (pollTimer) { clearInterval(pollTimer); pollTimer = null } })
</script>

<style scoped>
.msg-page { min-height: 100vh; background: #F4F6FB; display: flex; flex-direction: column; }
.msg-login-tip { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 120px 0 80px; gap: 14px; }
.msg-login-icon { width: 72px; height: 72px; border-radius: 24px; background: #EDF0F8; display: flex; align-items: center; justify-content: center; }
.msg-login-text { font-size: 15px; color: #8a9aa8; }
.msg-login-btn { margin-top: 8px; background: linear-gradient(135deg,#4F46E5,#7C6FF0); color: #fff; font-size: 14px; padding: 10px 36px; border-radius: 24px; }
.msg-nav { padding: 10px 16px 8px; background: #fff; }
.msg-nav-left { display: flex; align-items: center; gap: 10px; }
.msg-nav-title { font-size: 17px; font-weight: 600; color: #1a2332; flex-shrink: 0; }
.msg-nav-actions { display: flex; align-items: center; gap: 10px; }
.tool-btn { display: flex; align-items: center; }
.tool-text { font-size: 13px; color: #8a9aa8; }
.msg-tabs { background: #fff; border-bottom: 1px solid #E7ECF4; white-space: nowrap; padding: 0 12px 10px; box-sizing: border-box; }
.msg-tab { display: inline-flex; align-items: center; padding: 6px 16px; margin-right: 8px; border-radius:124px; background: #EDF0F8; font-size: 14px; color: #8a9aa8; position: relative; }
.msg-tab.active { background: #EEF0FE; color: #4F46E5; font-weight: 600; }
.tab-badge { position: absolute; top: -4px; right: -2px; min-width: 16px; height: 16px; line-height: 16px; text-align: center; border-radius:22px; background: #ff6b6b; color: #fff; font-size: 10px; padding: 0 4px; box-sizing: border-box; }
.msg-list { flex: 1; height: 0; padding: 0 12px; box-sizing: border-box; }
.time-label { font-size: 12px; color: #9aabba; padding: 14px 4px 8px; }
.msg-card { display: flex; align-items: center; gap: 12px; background: #fff; border-radius:24rpx; box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06); padding: 14px 16px; margin-bottom: 8px; }
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
