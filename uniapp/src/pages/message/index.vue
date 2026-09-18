<template>
  <view class="msg-page">
    <!-- 顶部导航栏 -->
    <view class="msg-nav" :style="{ paddingTop: statusBarHeight + 'px' }">
      <view class="msg-nav-left">
        <text class="msg-nav-title">消息</text>
        <view class="msg-nav-actions">
          <view class="tool-btn" @click="onRefresh"><u-icon name="reload" color="#8a9aa8" size="18"></u-icon></view>
          <view class="tool-btn" @click="goSearch"><u-icon name="search" color="#8a9aa8" size="18"></u-icon></view>
          <view class="tool-btn" @click="readAll"><text class="tool-text">全部已读</text></view>
        </view>
      </view>
    </view>

    <!-- 分类标签栏 -->
    <scroll-view scroll-x class="msg-tabs" :show-scrollbar="false">
      <view class="msg-tabs-inner">
        <view
          v-for="t in tabs"
          :key="t.value"
          class="msg-tab"
          :class="{ active: activeTab === t.value }"
          @click="switchTab(t.value)"
        >
          <text>{{ t.label }}</text>
          <text v-if="t.count" class="msg-tab-badge">{{ t.count > 99 ? '99+' : t.count }}</text>
        </view>
      </view>
    </scroll-view>

    <!-- 消息列表 -->
    <scroll-view
      class="msg-list"
      scroll-y
      :style="{ height: listHeight + 'px' }"
      refresher-enabled
      :refresher-triggered="refreshing"
      @refresherrefresh="onRefresh"
      @scrolltolower="loadMore"
    >
      <!-- 加载中 -->
      <view v-if="loading" class="msg-loading">
        <u-loading-icon mode="circle" size="28" color="#4F46E5"></u-loading-icon>
        <text class="msg-loading-text">加载中...</text>
      </view>

      <!-- 空状态 -->
      <view v-else-if="filteredList.length === 0" class="msg-empty">
        <MIcon name="inbox" :size="48" color="#c6d2e0" />
        <text class="msg-empty-title">暂无消息</text>
        <text class="msg-empty-sub">当前没有新消息</text>
      </view>

      <!-- 消息列表 -->
      <template v-else>
        <view v-for="group in timeGroups" :key="group.label" class="msg-group">
          <text class="msg-group-label">{{ group.label }}</text>
          <view
            v-for="msg in group.list"
            :key="msg.id"
            class="msg-card"
            :class="{ unread: !msg.isRead }"
            @click="openDetail(msg)"
          >
            <view class="msg-card-top">
              <view class="msg-card-title-row">
                <text v-if="!msg.isRead" class="msg-unread-dot"></text>
                <text class="msg-card-title">{{ msg.title }}</text>
                <text v-if="msg.isUrgent" class="msg-urgent-tag">紧急</text>
              </view>
              <text class="msg-card-time">{{ formatTime(msg.time) }}</text>
            </view>
            <text class="msg-card-content">{{ msg.content }}</text>
          </view>
        </view>
        <!-- 加载更多 -->
        <view v-if="hasMore" class="msg-load-more" @click="loadMore">
          <text>加载更多</text>
        </view>
      </template>
    </scroll-view>

    <!-- 底部导航 -->
    <view class="msg-bottom-nav">
      <view class="bottom-tab" @click="goHome">
        <MIcon name="home" :size="22" color="currentColor" />
        <text class="tab-label">首页</text>
      </view>
      <view class="bottom-tab" @click="goContacts">
        <MIcon name="users" :size="22" color="currentColor" />
        <text class="tab-label">通讯录</text>
      </view>
      <view class="bottom-tab active" @click="goMessages">
        <MIcon name="chat" :size="22" color="currentColor" />
        <text class="tab-label">消息</text>
      </view>
      <view class="bottom-tab" @click="goProfile">
        <MIcon name="user" :size="22" color="currentColor" />
        <text class="tab-label">我的</text>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

// 状态栏高度
const statusBarHeight = ref(0)
// #ifdef MP-WEIXIN
try {
  const info = uni.getSystemInfoSync()
  const sb = info.statusBarHeight || 0
  statusBarHeight.value = sb
  if (typeof uni.getMenuButtonBoundingClientRect === 'function') {
    const m = uni.getMenuButtonBoundingClientRect()
    if (m && m.top) statusBarHeight.value = m.top
  }
} catch (e) { statusBarHeight.value = 44 }
// #endif

// 分类Tab
const tabs = [
  { label: '全部', value: 0, count: 0 },
  { label: '系统', value: 1, count: 0 },
  { label: '任务', value: 2, count: 0 },
  { label: '审批', value: 3, count: 0 },
  { label: '团队', value: 4, count: 0 }
]
const activeTab = ref(0)
function switchTab(val) { activeTab.value = val }

// 消息列表
const loading = ref(true)
const refreshing = ref(false)
const hasMore = ref(true)
const page = ref(1)
const allMessages = ref([])

// 列表高度（扣除导航栏、标签栏、底部导航）
const listHeight = ref(0)
// #ifdef MP-WEIXIN
try {
  const sys = uni.getSystemInfoSync()
  listHeight.value = sys.windowHeight || sys.screenHeight || 600
} catch (e) { listHeight.value = 600 }
// #endif
// #ifndef MP-WEIXIN
onMounted(() => {
  uni.getSystemInfo({ success: (sys) => { listHeight.value = sys.windowHeight - 100 || 500 } })
})
// #endif

// 模拟数据
const mockMessages = [
  { id: 1, type: 'system', title: '异地登录提醒', content: '您的账号于 2026-08-19 07:31:24 从新 IP 地址 192.168.1.100 登录，如非本人操作请立即修改密码。', time: '2026-08-19 07:31:24', isRead: false, isUrgent: true },
  { id: 2, type: 'system', title: '系统已更新至 v1.72.0', content: '系统已更新至 v1.72.0（考勤打卡模块优化、人脸识别准确率提升、新增外勤打卡功能）', time: '2026-08-19 06:17:00', isRead: false, isUrgent: false },
  { id: 3, type: 'system', title: '系统已更新至 v1.71.0', content: '系统已更新至 v1.71.0，修复了已知问题并优化了性能。', time: '2026-08-19 05:12:00', isRead: true, isUrgent: false },
  { id: 4, type: 'system', title: '登录失败提醒', content: '您的账号在 2026-08-19 02:25:18 尝试登录失败，如非本人操作请忽略。', time: '2026-08-19 02:25:18', isRead: false, isUrgent: true },
  { id: 5, type: 'system', title: '系统已更新至 v1.70.0', content: '系统已更新至 v1.70.0，新增安全检查模块与在线考试功能。', time: '2026-08-19 01:39:00', isRead: true, isUrgent: false },
  { id: 6, type: 'system', title: '权限变更提醒', content: '您的角色权限已于 2026-08-18 23:15:00 更新，新增设备保养模块操作权限。', time: '2026-08-18 23:15:00', isRead: false, isUrgent: false },
  { id: 7, type: 'task', title: '保养任务提醒', content: '设备 #A-0032 月度保养任务即将到期，请尽快完成。', time: '2026-08-18 14:00:00', isRead: true, isUrgent: false },
  { id: 8, type: 'approval', title: '审批待办提醒', content: '您有一条维修工单审批待处理，请及时查看。', time: '2026-08-18 10:30:00', isRead: false, isUrgent: false },
  { id: 9, type: 'team', title: '团队消息', content: '生产部 2026-08-18 周例会纪要已发布，请查阅。', time: '2026-08-18 09:00:00', isRead: true, isUrgent: false },
  { id: 10, type: 'system', title: '系统维护通知', content: '系统将于 2026-08-20 02:00-04:00 进行例行维护，届时可能影响正常使用。', time: '2026-08-17 16:00:00', isRead: true, isUrgent: false },
  { id: 11, type: 'task', title: '安全检查任务', content: '2026年8月安全检查任务已分配，请登录系统查看。', time: '2026-08-17 08:00:00', isRead: true, isUrgent: false },
  { id: 12, type: 'system', title: '账号安全提醒', content: '您的账号已连续使用 90 天，建议定期修改密码以保障账号安全。', time: '2026-08-16 10:00:00', isRead: true, isUrgent: false }
]

// 按类型筛选
const filteredList = computed(() => {
  if (activeTab.value === 0) return allMessages.value
  const typeMap = { 1: 'system', 2: 'task', 3: 'approval', 4: 'team' }
  return allMessages.value.filter(m => m.type === typeMap[activeTab.value])
})

// 时间分组
const timeGroups = computed(() => {
  const groups = { 今天: [], 昨天: [], 更早: [] }
  const today = new Date().toDateString()
  const yesterday = new Date(Date.now() - 86400000).toDateString()
  filteredList.value.forEach(msg => {
    const d = new Date(msg.time).toDateString()
    if (d === today) groups['今天'].push(msg)
    else if (d === yesterday) groups['昨天'].push(msg)
    else groups['更早'].push(msg)
  })
  return Object.entries(groups)
    .filter(([, list]) => list.length > 0)
    .map(([label, list]) => ({ label, list }))
})

// 时间格式化
function formatTime(timeStr) {
  const d = new Date(timeStr)
  const now = new Date()
  const today = now.toDateString()
  if (d.toDateString() === today) {
    return ('0' + d.getHours()).slice(-2) + ':' + ('0' + d.getMinutes()).slice(-2)
  }
  const yesterday = new Date(now - 86400000).toDateString()
  if (d.toDateString() === yesterday) return '昨天'
  return ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2)
}

// 加载数据
function loadData() {
  loading.value = true
  setTimeout(() => {
    allMessages.value = mockMessages
    // 更新tab角标
    const typeMap = { system: 1, task: 2, approval: 3, team: 4 }
    const unreadByType = { 0: 0, 1: 0, 2: 0, 3: 0, 4: 0 }
    mockMessages.forEach(m => {
      if (!m.isRead) {
        unreadByType[0]++
        unreadByType[typeMap[m.type]]++
      }
    })
    tabs.forEach(t => { t.count = unreadByType[t.value] || 0 })
    loading.value = false
    refreshing.value = false
  }, 300)
}

// 下拉刷新
function onRefresh() {
  refreshing.value = true
  page.value = 1
  loadData()
}

// 加载更多
function loadMore() {
  if (!hasMore.value) return
  hasMore.value = false
}

// 打开详情
function openDetail(msg) {
  if (!msg.isRead) {
    msg.isRead = true
    // 更新角标
    const typeMap = { system: 1, task: 2, approval: 3, team: 4 }
    tabs[0].count = Math.max(0, tabs[0].count - 1)
    const ti = typeMap[msg.type]
    if (tabs[ti]) tabs[ti].count = Math.max(0, tabs[ti].count - 1)
  }
  uni.navigateTo({ url: '/pages/messages/detail?id=' + msg.id })
}

// 全部已读
function readAll() {
  allMessages.value.forEach(m => { m.isRead = true })
  tabs.forEach(t => { t.count = 0 })
  uni.showToast({ title: '已全部标记为已读', icon: 'success' })
}

// 导航
function goHome() { uni.reLaunch({ url: '/pages/diy/index?type=home' }) }
function goContacts() { uni.reLaunch({ url: '/pages/diy/index?type=contacts' }) }
function goMessages() { /* 当前页 */ }
function goProfile() { uni.reLaunch({ url: '/pages/diy/index?type=profile' }) }
function goSearch() { uni.navigateTo({ url: '/pages/messages/search' }) }

onMounted(() => { loadData() })
</script>

<style scoped>
.msg-page { min-height: 100vh; background: #F4F6FB; display: flex; flex-direction: column; height: 100vh; }

/* 顶部导航栏 */
.msg-nav { padding: 10px 16px 8px; background: #fff; }
.msg-nav-left { display: flex; align-items: center; gap: 10px; }
.msg-nav-title { font-size: 17px; font-weight: 600; color: #1a2332; flex-shrink: 0; }
.msg-nav-actions { display: flex; align-items: center; gap: 10px; }
.tool-btn { display: flex; align-items: center; }
.tool-text { font-size: 13px; color: #8a9aa8; }

/* 分类标签 */
.msg-tabs { background: #fff; border-bottom: 1px solid #EDF0F8; white-space: nowrap; padding: 0 12px 10px; box-sizing: border-box; }
.msg-tabs-inner { display: inline-flex; gap: 8px; }
.msg-tab { display: inline-flex; align-items: center; padding: 6px 16px; border-radius:124px; background: #EDF0F8; font-size: 14px; color: #8a9aa8; position: relative; }
.msg-tab.active { background: #EEF0FE; color: #4F46E5; font-weight: 600; }
.msg-tab-badge { position: absolute; top: -4px; right: -2px; min-width: 16px; height: 16px; line-height: 16px; text-align: center; border-radius:22px; background: #fb6e8c; color: #fff; font-size: 10px; padding: 0 4px; box-sizing: border-box; }

/* 消息列表 */
.msg-list { overflow-y: auto; padding: 0 12px; box-sizing: border-box; }

/* 加载中 */
.msg-loading { display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 40vh; gap: 10px; }
.msg-loading-text { font-size: 13px; color: #8a9aa8; }

/* 空状态 */
.msg-empty { display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 50vh; }
.msg-empty-icon { font-size: 48px; margin-bottom: 12px; }
.msg-empty-title { font-size: 16px; color: #333; font-weight: 600; }
.msg-empty-sub { font-size: 13px; color: #999; margin-top: 6px; }

/* 时间分组 */
.msg-group { padding-top: 16px; }
.msg-group-label { display: block; font-size: 12px; color: #8a9aa8; padding: 0 4px 8px; }

/* 消息卡片 */
.msg-card { background: rgba(255,255,255,0.55); backdrop-filter: blur(10px); -webkit-backdrop-filter: blur(10px); border: 1px solid rgba(255,255,255,0.3); border-radius:122px; padding: 14px 16px; margin-bottom: 8px; cursor: pointer; transition: 0.2s; }
.msg-card:active { transform: scale(0.98); background: rgba(255,255,255,0.8); }
.msg-card.unread { background: rgba(255,255,255,0.7); border-color: rgba(110,142,251,0.2); }
.msg-card-top { display: flex; align-items: flex-start; justify-content: space-between; margin-bottom: 6px; }
.msg-card-title-row { display: flex; align-items: center; gap: 6px; flex: 1; min-width: 0; }
.msg-card-title { font-size: 15px; font-weight: 600; color: #1a2332; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.msg-unread-dot { width: 8px; height: 8px; border-radius:50%; background: #fb6e8c; flex-shrink: 0; }
.msg-urgent-tag { font-size: 10px; color: #fff; background: #fb6e8c; padding: 1px 8px; border-radius:30px; flex-shrink: 0; }
.msg-card-time { font-size: 11px; color: #b0c0cc; flex-shrink: 0; margin-left: 8px; }
.msg-card-content { font-size: 13px; color: #8a9aa8; line-height: 1.5; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }

/* 加载更多 */
.msg-load-more { text-align: center; padding: 16px 0; font-size: 13px; color: #8a9aa8; }

/* 底部导航 */
.msg-bottom-nav { display: flex; background: rgba(255,255,255,0.5); backdrop-filter: blur(30px); -webkit-backdrop-filter: blur(30px); border-top: 1px solid rgba(255,255,255,0.4); padding: 6px 12px 14px; border-radius:322px 322px 0 0; }
.bottom-tab { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 2px; font-size: 10px; color: #b0c0cc; cursor: pointer; padding: 4px 0; }
.bottom-tab.active { color: #4F46E5; font-weight: 500; }
.bottom-tab .tab-icon { font-size: 22px; }
.bottom-tab:active { transform: scale(0.92); }
</style>