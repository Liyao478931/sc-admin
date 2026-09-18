<template>
  <view class="contact-page">
    <!-- 顶部导航 -->
    <view class="contact-nav">
      <view class="contact-nav-left">
        <text class="contact-nav-title">通讯录</text>
      </view>
    </view>
    <!-- 搜索 -->
    <view class="search-bar">
      <view class="search-input-wrap">
        <u-input v-model="keyword" placeholder="搜索姓名 / 部门 / 手机号" prefixIcon="search" border="none" confirm-type="search" :customStyle="{ height: '72rpx', fontSize: '26rpx' }" />
        <view v-if="keyword" class="clear-btn" @click="keyword = ''"><MIcon name="close" :size="12" color="#b0c0cc" /></view>
      </view>
    </view>

    <!-- 部门 Tab -->
    <scroll-view scroll-x class="dept-tabs" :show-scrollbar="false">
      <view class="dept-tab" :class="{ active: activeDept === 0 }" @click="switchDept(0)">
        <text>全部</text><text class="dept-count">{{ members.length }}</text>
      </view>
      <view class="dept-tab" :class="{ active: activeDept === d.id }" v-for="d in deptList" :key="d.id" @click="switchDept(d.id)">
        <text>{{ d.name }}</text><text class="dept-count">{{ d.user_count || 0 }}</text>
      </view>
    </scroll-view>

    <!-- 成员列表 -->
    <scroll-view scroll-y class="member-list" :refresher-enabled="true" :refresher-triggered="refreshing" @refresherrefresh="onRefresh">
      <view class="member-card" v-for="(m, i) in filteredMembers" :key="m.id" @click="goDetail(m)">
        <view class="member-avatar" :style="{ background: avatarColor(i) }">
          <image v-if="m.avatar" class="member-avatar-img" :src="m.avatar" mode="aspectFill" @error="m.avatar = ''" />
          <text v-else>{{ (m.real_name || m.username || '?').substring(0, 1) }}</text>
          <view class="status-dot" :class="m.status === 1 ? 'online' : 'offline'"></view>
          <!-- 未读消息 badge -->
          <view v-if="(unreadMap[m.id] || 0) > 0" class="unread-badge">{{ unreadMap[m.id] }}</view>
        </view>
        <view class="member-info">
          <view class="member-name-row">
            <text class="member-name">{{ m.real_name || m.username }}</text>
            <text class="member-pos-tag">{{ m.department_name || '员工' }}</text>
          </view>
          <text class="member-dept">{{ m.department_name || '未分配部门' }}</text>
        </view>
        <view class="member-actions">
          <view v-if="m.phone" class="action-btn" @click.stop="callPhone(m)"><u-icon name="phone" color="#4e5a6b" size="16" /></view>
          <view class="action-btn" @click.stop="goChat(m)"><u-icon name="chat" color="#4e5a6b" size="16" /></view>
        </view>
      </view>
      <u-empty v-if="!filteredMembers.length && !loading" text="未找到成员" description="当前部门暂无员工或请尝试其他关键词" mode="list" />
      <view v-if="loading" class="loading-text">加载中...</view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { onShow } from '@dcloudio/uni-app'

const deptList = ref([])
const deptTree = ref([])
const members = ref([])
const activeDept = ref(0)
const keyword = ref('')
const loading = ref(false)
const refreshing = ref(false)
const unreadMap = ref({})
let pollTimer = null

const filteredMembers = computed(() => {
  let list = members.value
  if (activeDept.value > 0) {
    // 显示该部门及其所有子部门成员
    const ids = collectDeptIds(deptTree.value, activeDept.value)
    list = list.filter(m => ids.has(Number(m.department_id)))
  }
  const kw = keyword.value.trim()
  if (kw) {
    list = list.filter(m =>
      (m.real_name || '').includes(kw) ||
      (m.username || '').includes(kw) ||
      (m.department_name || '').includes(kw) ||
      (m.phone || '').includes(kw)
    )
  }
  return list
})

/** 收集目标部门及其全部子部门的 id 集合 */
function collectDeptIds(nodes, targetId) {
  const ids = new Set()
  function walk(list, inside) {
    (list || []).forEach(n => {
      const hit = Number(n.id) === Number(targetId)
      if (inside || hit) ids.add(Number(n.id))
      if (n.children && n.children.length) walk(n.children, inside || hit)
    })
  }
  walk(nodes, false)
  return ids
}

const AVATAR_COLORS = ['#3d5a73', '#c97d5a', '#4a8f8f', '#8a7aa8', '#c99a3a', '#5a8faa', '#e07a5f', '#4F46E5']
function avatarColor(i) { return AVATAR_COLORS[i % AVATAR_COLORS.length] }

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

function flattenDepts(nodes, arr) {
  (nodes || []).forEach(n => {
    // 只显示非一级部门（跳过 parent_id=0 的根/公司层级）
    if (n && n.id && Number(n.parent_id) !== 0) arr.push(n)
    if (n && n.children && n.children.length) flattenDepts(n.children, arr)
  })
  return arr
}

async function loadData() {
  loading.value = true
  try {
    let deptRes, memberRes
    if (getToken()) {
      const r = await Promise.all([
        api('/api/organization/departments/tree'),
        api('/api/organization/members/all')
      ])
      deptRes = r[0]
      memberRes = r[1]
    } else {
      const r = await api('/api/mobile/contacts/public')
      deptRes = r.departments || []
      memberRes = (r.members || []).map(m => ({ ...m, phone: '' }))
    }
    const tree = Array.isArray(deptRes) ? deptRes : (deptRes && deptRes.list ? deptRes.list : [])
    deptTree.value = tree
    deptList.value = flattenDepts(tree, [])
    members.value = Array.isArray(memberRes) ? memberRes : []
  } catch (e) {
    uni.showToast({ title: '加载失败', icon: 'none' })
  }
  loading.value = false
  refreshing.value = false
}

async function loadUnread() {
  try {
    const r = await api('/api/mobile/contacts/chats')
    const list = Array.isArray(r?.list) ? r.list : []
    const map = {}
    list.forEach(item => {
      if (item?.peer_id && (item?.unread_count || 0) > 0) {
        map[item.peer_id] = item.unread_count
      }
    })
    unreadMap.value = map
  } catch (e) {
    // 未读拉取失败静默（不影响通讯录列表展示）
  }
}

function switchDept(id) {
  if (activeDept.value === id) return
  activeDept.value = id
}
function onRefresh() { refreshing.value = true; loadData() }

function callPhone(m) {
  const phone = m.phone
  if (!phone) { uni.showToast({ title: '暂无手机号', icon: 'none' }); return }
  // #ifdef H5
  window.location.href = 'tel:' + phone
  // #endif
  // #ifndef H5
  uni.makePhoneCall({ phoneNumber: phone, fail: () => {} })
  // #endif
}

function goChat(m) {
  if (!getToken()) {
    uni.showToast({ title: '请先登录', icon: 'none' })
    setTimeout(() => {
      const redirect = encodeURIComponent('/pages/diy/index?type=contacts')
      uni.navigateTo({ url: '/pages/login/index?redirect=' + redirect })
    }, 800)
    return
  }
  const name = m.real_name || m.username || '同事'
  uni.navigateTo({ url: '/pages/contacts/chat?peer_id=' + m.id + '&name=' + encodeURIComponent(name) })
}

function goDetail(m) {
  const p = encodeURIComponent(JSON.stringify({
    id: m.id, name: m.real_name || m.username || '', username: m.username || '',
    phone: m.phone || '', email: m.email || '', avatar: m.avatar || '', department: m.department_name || '',
    status: m.status
  }))
  uni.navigateTo({ url: '/pages/contacts/detail?d=' + p })
}

onMounted(() => {
  loadData()
  loadUnread()
  pollTimer = setInterval(loadData, 60000)
})
onShow(() => {
  loadUnread()
})
onUnmounted(() => { if (pollTimer) { clearInterval(pollTimer); pollTimer = null } })
</script>

<style scoped>
.contact-page { min-height: 100vh; background: #F4F6FB; display: flex; flex-direction: column; }
.contact-nav { padding: 10px 16px 8px; background: #fff; }
.contact-nav-left { display: flex; align-items: center; gap: 10px; }
.contact-nav-title { font-size: 18px; font-weight: 700; color: #1a2332; }
.search-bar { padding: 0 16px 10px; background: #fff; }
.search-input-wrap { display: flex; align-items: center; background: #EDF0F8; border-radius:24px; padding: 0 14px; height: 38px; }
.search-icon { font-size: 14px; margin-right: 8px; }
.search-input { flex: 1; font-size: 14px; height: 38px; }
.clear-btn { width: 20px; height: 20px; border-radius:50%; background: #c0cedc; color: #fff; font-size: 11px; display: flex; align-items: center; justify-content: center; }
.dept-tabs { background: #fff; border-bottom: 1px solid #EDF0F8; white-space: nowrap; padding: 0 12px 10px; box-sizing: border-box; }
.dept-tab { display: inline-flex; align-items: center; padding: 6px 16px; margin-right: 8px; border-radius:124px; background: #EDF0F8; font-size: 13px; color: #8a9aa8; }
.dept-tab.active { background: #4F46E5; color: #fff; font-weight: 500; }
.dept-count { font-size: 11px; margin-left: 6px; opacity: 0.8; }
.member-list { flex: 1; height: 0; padding: 12px; box-sizing: border-box; }
.member-card { display: flex; align-items: center; gap: 12px; background: #fff; border-radius:24rpx; padding: 12px 16px; margin-bottom: 8px; box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06); }
.member-card:active { background: #EDF0F8; }
.member-avatar-img { width: 100%; height: 100%; border-radius: 50%; display: block; background: #e8edf3; }
.member-avatar { width: 44px; height: 44px; border-radius:50%; display: flex; align-items: center; justify-content: center; color: #fff; font-size: 18px; font-weight: 600; position: relative; flex-shrink: 0; }
.status-dot { position: absolute; bottom: 1px; right: 1px; width: 11px; height: 11px; border-radius:50%; border: 2px solid #fff; }
.status-dot.online { background: #34c759; }
.status-dot.offline { background: #c0cedc; }
.unread-badge { position: absolute; top: -4px; right: -4px; min-width: 16px; height: 16px; padding: 0 4px; border-radius:24px; background: #ff3b30; color: #fff; font-size: 10px; font-weight: 600; display: flex; align-items: center; justify-content: center; border: 1.5px solid #fff; z-index: 2; }
.member-info { flex: 1; min-width: 0; }
.member-name-row { display: flex; align-items: center; gap: 8px; }
.member-name { font-size: 15px; font-weight: 600; color: #1a2332; }
.member-pos-tag { font-size: 10px; color: #4F46E5; background: #EEF0FE; padding: 2px 8px; border-radius:22px; }
.member-dept { display: block; font-size: 13px; color: #8a9aa8; margin-top: 2px; }
.member-actions { display: flex; gap: 8px; flex-shrink: 0; }
.action-btn { width: 34px; height: 34px; border-radius:50%; background: #EDF0F8; display: flex; align-items: center; justify-content: center; font-size: 15px; }
.action-btn:active { background: #e4e8ec; }
.empty { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 80px 0; }
.empty-icon { font-size: 56px; }
.empty-title { font-size: 16px; color: #8a9aa8; margin-top: 16px; font-weight: 500; }
.empty-desc { font-size: 13px; color: #b0c0cc; margin-top: 6px; }
.loading-text { text-align: center; color: #b0c0cc; font-size: 12px; padding: 16px 0; }
</style>
