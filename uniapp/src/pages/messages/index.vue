<template>
  <view class="msg-page">
    <!-- 顶部操作行 -->
    <view class="msg-toolbar">
      <view class="msg-toolbar-right">
        <view class="tool-btn" @click="subscribeNotify"><MIcon name="bell" :size="14" color="#409EFF" /><text class="tool-text" style="color:#409EFF;margin-left:4px">订阅通知</text></view>
        <view class="tool-btn" @click="goSearch"><MIcon name="search" :size="18" color="#8a9aa8" /></view>
        <view class="tool-btn" @click="readAll"><text class="tool-text">全部已读</text></view>
      </view>
    </view>

    <!-- 分类 Tab -->
    <scroll-view scroll-x class="msg-tabs" :show-scrollbar="false">
      <view class="msg-tab" :class="{ active: activeType === t.value }" v-for="t in tabs" :key="t.value" @click="switchTab(t.value)">
        <text>{{ t.label }}</text>
        <text v-if="t.value === 0 && unreadTotal > 0" class="tab-badge">{{ unreadTotal > 99 ? '99+' : unreadTotal }}</text>
      </view>
    </scroll-view>

    <!-- 消息列表 -->
    <scroll-view scroll-y class="msg-list" :refresher-enabled="true" :refresher-triggered="refreshing" @refresherrefresh="onRefresh" @scrolltolower="loadMore">
      <template v-if="groups.length">
        <view v-for="(g, gi) in groups" :key="gi">
          <view class="time-label">{{ g.label }}</view>
          <view class="msg-card" :class="{ unread: m.status === 0 }" v-for="m in g.list" :key="m.msg_id" @click="onMsgClick(m)">
            <view class="msg-icon" :style="iconStyle(m.msg_type)"><MIcon :name="iconText(m.msg_type)" :size="20" color="#ffffff" :weight="2" /></view>
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
      <view v-else-if="!loading" class="msg-empty">
        <MIcon name="inbox" :size="44" color="#c6d2e0" />
        <text class="empty-title">暂无消息</text>
        <text class="empty-desc">当前分类下没有消息</text>
      </view>
      <view v-if="loading && !list.length" class="msg-finished">加载中...</view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref, computed } from 'vue'
import { onShow, onHide } from '@dcloudio/uni-app'

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
function onRefresh() { refreshing.value = true; loadList(true) }
function loadMore() {
  if (!finished.value && !loading.value) { loadingMore.value = true; page.value++; loadList() }
}

async function onMsgClick(m) {
  // 未读 → 标记已读
  if (m.status === 0) {
    try { await api('/api/notification/read/' + m.msg_id, 'PUT') } catch (e) {}
    m.status = 1
    if (unreadTotal.value > 0) unreadTotal.value--
  }
  // 跳转或展示内容
  const link = m.link_url
  if (link && String(link).startsWith('/pages')) {
    uni.navigateTo({ url: link, fail: () => uni.showModal({ title: m.title || '消息', content: m.content || '', showCancel: false }) })
  } else if (link && String(link).startsWith('http')) {
    // #ifdef H5
    window.open(link)
    // #endif
    // #ifndef H5
    uni.showModal({ title: m.title || '消息', content: m.content || '', showCancel: false })
    // #endif
  } else {
    uni.showModal({ title: m.title || '消息', content: m.content || '', showCancel: false })
  }
}

// 微信订阅消息：请求授权并上报后端（一次性订阅）
async function subscribeNotify() {
  // #ifndef MP-WEIXIN
  uni.showToast({ title: '订阅通知仅微信小程序支持', icon: 'none' })
  return
  // #endif
  try {
    const cfg = await api('/api/public/subscribe/config', 'GET')
    const templates = (cfg && cfg.templates) || []
    if (!templates.length) {
      uni.showModal({ title: '订阅通知', content: '管理员尚未配置订阅消息模板，请联系系统管理员在微信公众平台申请并配置。', showCancel: false })
      return
    }
    uni.requestSubscribeMessage({
      tmplIds: templates.map(t => t.template_id),
      success: async (res) => {
        let accepted = 0
        for (const t of templates) {
          if (res[t.template_id] === 'accept') {
            try { await api('/api/subscribe/save', 'POST', { template_id: t.template_id, scene: t.scene }) } catch (e) {}
            accepted++
          }
        }
        if (accepted > 0) {
          uni.showToast({ title: '已订阅，业务通知将推送到微信', icon: 'success' })
        } else {
          uni.showToast({ title: '未授权任何通知', icon: 'none' })
        }
      },
      fail: () => uni.showToast({ title: '订阅请求失败', icon: 'none' })
    })
  } catch (e) {
    uni.showToast({ title: '订阅配置获取失败', icon: 'none' })
  }
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

onShow(() => {
  loadList(true)
  loadUnread()
  pollTimer = setInterval(loadUnread, 30000)
})
onHide(() => { if (pollTimer) { clearInterval(pollTimer); pollTimer = null } })
</script>

<style scoped>
.msg-page { height: 100vh; overflow: hidden; background: #F4F6FB; display: flex; flex-direction: column; }
.msg-toolbar { display: flex; align-items: center; justify-content: flex-end; padding: 12px 16px; padding-right: calc(16px + constant(safe-area-inset-right)); padding-right: calc(16px + env(safe-area-inset-right)); background: #fff; }
.msg-toolbar-right { display: flex; align-items: center; gap: 14px; }
.tool-btn { display: flex; align-items: center; }
.tool-icon { font-size: 18px; }
.tool-text { font-size: 13px; color: #8a9aa8; }
.msg-tabs { background: #fff; border-bottom: 1px solid #E7ECF4; white-space: nowrap; padding: 0 12px 10px; box-sizing: border-box; }
.msg-tab { display: inline-flex; align-items: center; padding: 6px 16px; margin-right: 8px; border-radius:124px; background: #EDF0F8; font-size: 14px; color: #8a9aa8; position: relative; }
.msg-tab.active { background: #EEF0FE; color: #4F46E5; font-weight: 600; }
.tab-badge { position: absolute; top: -4px; right: -2px; min-width: 16px; height: 16px; line-height: 16px; text-align: center; border-radius:22px; background: #ff6b6b; color: #fff; font-size: 10px; padding: 0 4px; box-sizing: border-box; }
.msg-list { flex: 1; min-height: 0; padding: 0 12px; box-sizing: border-box; }
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
