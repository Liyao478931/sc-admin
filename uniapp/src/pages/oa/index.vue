<template>
  <view class="oa-page">
    <!-- 顶部导航栏 -->
    <view class="oa-nav" :style="{ paddingTop: statusBarHeight + 'px' }">
      <view class="oa-nav-left">
        <view class="oa-back" @click="goBack">
          <u-icon name="arrow-left" color="#1a2332" size="18"></u-icon>
          <text class="oa-back-text">返回</text>
        </view>
        <text class="oa-nav-title">OA审批</text>
      </view>
    </view>

    <!-- 滚动内容 -->
    <scroll-view class="oa-scroll" scroll-y :style="{ height: scrollHeight + 'px' }">
      <!-- 统计卡片 -->
      <view class="oa-stats">
        <view class="oa-stats-grid">
          <view class="oa-stat-card" @click="goStat('pending')">
            <text class="oa-stat-num">{{ stats.pending }}</text>
            <text class="oa-stat-label">待审批</text>
          </view>
          <view class="oa-stat-card" @click="goStat('approved')">
            <text class="oa-stat-num">{{ stats.approved }}</text>
            <text class="oa-stat-label">已通过</text>
          </view>
          <view class="oa-stat-card" @click="goStat('rejected')">
            <text class="oa-stat-num">{{ stats.rejected }}</text>
            <text class="oa-stat-label">已驳回</text>
          </view>
          <view class="oa-stat-card" @click="goStat('mine')">
            <text class="oa-stat-num">{{ stats.mine }}</text>
            <text class="oa-stat-label">我发起的</text>
          </view>
        </view>
      </view>

      <!-- 快速申请入口 -->
      <view class="oa-quick">
        <view class="oa-section-header">
          <view class="oa-section-title">
            <u-icon name="plus-circle" color="#4F46E5" size="16"></u-icon>
            <text>快速申请</text>
          </view>
        </view>
        <view class="oa-quick-grid">
          <view class="oa-quick-item" v-for="(q, i) in quickItems" :key="i" @click="quickClick(q)">
            <view class="oa-quick-icon" :style="{ background: quickColor(i) }">
              <u-icon :name="q.icon" color="#fff" size="20"></u-icon>
            </view>
            <text class="oa-quick-title">{{ q.title }}</text>
          </view>
        </view>
      </view>

      <!-- 我的申请列表 -->
      <view class="oa-list">
        <view class="oa-section-header">
          <view class="oa-section-title">
            <u-icon name="list" color="#4F46E5" size="16"></u-icon>
            <text>我的申请</text>
          </view>
          <text class="oa-section-more" @click="goAll">全部</text><MIcon name="chevronRight" :size="14" color="#8a9aa8" />
        </view>
        <view class="oa-approval-item" v-for="(item, i) in approvalList" :key="i" @click="openDetail(item)">
          <view class="oa-approval-icon" :style="{ background: approvalColor(item.type) }">
            <u-icon :name="approvalIcon(item.type)" color="#fff" size="18"></u-icon>
          </view>
          <view class="oa-approval-info">
            <text class="oa-approval-title">{{ item.title }}</text>
            <view class="oa-approval-desc">
              <text>{{ item.desc }}</text>
              <text v-if="item.urgent" class="oa-tag oa-tag-urgent">紧急</text>
              <text v-else class="oa-tag oa-tag-normal">正常</text>
            </view>
          </view>
          <view class="oa-approval-right">
            <text class="oa-approval-status" :class="'status-' + item.status">{{ statusText(item.status) }}</text>
            <text class="oa-approval-time">{{ item.time }}</text>
          </view>
        </view>
      </view>
    </scroll-view>

    <!-- 底部导航 -->
    <view class="oa-bottom-nav">
      <view class="oa-tab" @click="goHome">
        <u-icon name="home" color="#b0c0cc" size="22"></u-icon>
        <text class="oa-tab-label">首页</text>
      </view>
      <view class="oa-tab" @click="goContacts">
        <u-icon name="account" color="#b0c0cc" size="22"></u-icon>
        <text class="oa-tab-label">通讯录</text>
      </view>
      <view class="oa-tab" @click="goMessages">
        <u-icon name="chat" color="#b0c0cc" size="22"></u-icon>
        <text class="oa-tab-label">消息</text>
      </view>
      <view class="oa-tab active" @click="goProfile">
        <u-icon name="account-fill" color="#4F46E5" size="22"></u-icon>
        <text class="oa-tab-label">我的</text>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { request } from '@/utils/request'

// 状态栏高度
const statusBarHeight = ref(0)
const scrollHeight = ref(0)
// #ifdef MP-WEIXIN
try {
  const info = uni.getSystemInfoSync()
  const sb = info.statusBarHeight || 0
  statusBarHeight.value = sb
  if (typeof uni.getMenuButtonBoundingClientRect === 'function') {
    const m = uni.getMenuButtonBoundingClientRect()
    if (m && m.top) statusBarHeight.value = m.top
  }
  scrollHeight.value = info.windowHeight - 100 || 500
} catch (e) { statusBarHeight.value = 44; scrollHeight.value = 500 }
// #endif
// #ifndef MP-WEIXIN
onMounted(() => {
  uni.getSystemInfo({ success: (sys) => { scrollHeight.value = sys.windowHeight - 100 || 500 } })
  loadData()
})
// #endif
// #ifdef MP-WEIXIN
loadData()
// #endif

// 统计数据
const stats = ref({ pending: 0, approved: 0, rejected: 0, mine: 0 })

// 快速申请（从后端动态获取）
const quickItems = ref([])

// 我的申请列表（从后端动态获取）
const approvalList = ref([])

// 加载数据
async function loadData() {
  try {
    // 获取OA审批功能列表（快速申请入口）
    const fnRes = await request({ url: '/api/app/functions', method: 'GET', data: { location: 'oa' } })
    if (fnRes.code === 0 && fnRes.data && Array.isArray(fnRes.data.list)) {
      const fnList = fnRes.data.list.filter(q => q.path !== null)
      if (fnList.length > 0) {
        quickItems.value = fnList.slice(0, 8).map(q => ({
          title: q.name || '',
          icon: q.icon || '',
          link: q.path ? (q.path.url || q.path.path || '') : ''
        }))
      }
    }
    // 获取统一审批"我发起的"数据（仅显示请假审批）
    const approvalRes = await request({ url: '/api/approval/my-tasks', method: 'GET', data: { status: 'mine', page: 1, pageSize: 20 } })
    if (approvalRes.code === 0 && approvalRes.data && Array.isArray(approvalRes.data.list)) {
      // 只保留请假类型（biz_type='leave'）
      const leaveList = approvalRes.data.list.filter(r => (r.biz_type || r.business_type) === 'leave')
      approvalList.value = leaveList.map(r => ({
        id: r.id,
        type: 'leave',
        title: r.business_title || r.business_name || '请假申请',
        desc: (r.applicant_name || '') + ' · ' + (r.business_no || ''),
        urgent: r.urgent === 1 || r.urgent === 2 || false,
        status: r.status === 2 ? 'approved' : (r.status === 3 ? 'rejected' : (r.status === 4 ? 'cancelled' : 'pending')),
        time: r.submit_time ? formatTime(r.submit_time) : ''
      }))
    }
  } catch (e) {}
}

function formatTime(t) {
  if (!t) return ''
  const s = String(t).replace('T', ' ')
  return s.length > 16 ? s.slice(5, 16) : s.slice(5)
}

// 颜色
const QUICK_COLORS = ['#4F46E5', '#34c796', '#fbaa50', '#fb8a6e', '#50c8ff', '#8a7aa8', '#fb6e8c', '#7a9a8a']
function quickColor(i) { return QUICK_COLORS[i % QUICK_COLORS.length] }

const APPROVAL_COLORS = { leave: '#4F46E5', travel: '#fbaa50', purchase: '#fb8a6e', reimburse: '#50c8ff', overtime: '#8a7aa8' }
function approvalColor(type) { return APPROVAL_COLORS[type] || '#4F46E5' }

const APPROVAL_ICONS = { leave: 'calendar', travel: 'plane', purchase: 'shopping-cart', reimburse: 'file-text', overtime: 'clock' }
function approvalIcon(type) { return APPROVAL_ICONS[type] || 'calendar' }

function statusText(status) {
  const map = { pending: '待审批', approved: '已通过', rejected: '已驳回', processing: '审批中', draft: '草稿', cancelled: '已撤销' }
  return map[status] || status || '待审批'
}

// 事件
function goBack() { uni.navigateBack() }
function goStat(type) { uni.showToast({ title: '查看' + statusText(type), icon: 'none' }) }
function quickClick(q) {
  if (q.link) uni.navigateTo({ url: q.link })
  else uni.showToast({ title: q.title, icon: 'none' })
}
function openDetail(item) { uni.showToast({ title: '查看审批详情', icon: 'none' }) }
function goAll() { uni.showToast({ title: '查看全部待审批', icon: 'none' }) }
function goHome() { uni.reLaunch({ url: '/pages/diy/index?type=home' }) }
function goContacts() { uni.reLaunch({ url: '/pages/diy/index?type=contacts' }) }
function goMessages() { uni.reLaunch({ url: '/pages/diy/index?type=messages' }) }
function goProfile() { uni.reLaunch({ url: '/pages/diy/index?type=profile' }) }
</script>

<style scoped>
.oa-page { min-height: 100vh; background: #F4F6FB; display: flex; flex-direction: column; }

/* 顶部导航 */
.oa-nav { padding: 10px 16px 8px; background: #fff; }
.oa-nav-left { display: flex; align-items: center; gap: 10px; }
.oa-back { display: flex; align-items: center; gap: 4px; padding: 4px 8px; border-radius:24px; cursor: pointer; }
.oa-back-text { font-size: 14px; font-weight: 500; color: #1a2332; }
.oa-nav-title { font-size: 17px; font-weight: 600; color: #1a2332; flex: 1; text-align: center; margin-right: 44px; }

/* 滚动内容 */
.oa-scroll { flex: 1; overflow-y: auto; }

/* 统计卡片 */
.oa-stats { padding: 16px 16px 8px; }
.oa-stats-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; }
.oa-stat-card { background: rgba(255,255,255,0.55); backdrop-filter: blur(8px); border-radius:124px; padding: 14px 4px 12px; text-align: center; border: 1px solid rgba(255,255,255,0.4); transition: 0.2s; cursor: pointer; }
.oa-stat-card:active { transform: scale(0.95); }
.oa-stat-num { font-size: 20px; font-weight: 700; color: #1a2332; display: block; }
.oa-stat-label { font-size: 10px; color: #9aabba; margin-top: 3px; display: block; }

/* 快速申请 */
.oa-quick { padding: 8px 16px; }
.oa-section-header { display: flex; align-items: center; justify-content: space-between; padding: 0 4px 12px; }
.oa-section-title { display: flex; align-items: center; gap: 6px; font-size: 15px; font-weight: 600; color: #1a2332; }
.oa-section-more { font-size: 12px; color: #b0c0cc; cursor: pointer; }
.oa-quick-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; }
.oa-quick-item { background: rgba(255,255,255,0.55); backdrop-filter: blur(8px); border-radius:122px; padding: 14px 4px 12px; text-align: center; cursor: pointer; border: 1px solid rgba(255,255,255,0.4); transition: 0.25s; }
.oa-quick-item:active { transform: scale(0.95); }
.oa-quick-icon { width: 44px; height: 44px; border-radius:124px; display: flex; align-items: center; justify-content: center; margin: 0 auto 6px; }
.oa-quick-title { font-size: 11px; font-weight: 500; color: #3a4a5a; }

/* 审批列表 */
.oa-list { padding: 8px 16px 16px; }
.oa-approval-item { display: flex; align-items: center; gap: 12px; background: rgba(255,255,255,0.55); backdrop-filter: blur(8px); border-radius:122px; padding: 14px 16px; border: 1px solid rgba(255,255,255,0.4); cursor: pointer; transition: 0.25s; margin-bottom: 8px; }
.oa-approval-item:active { transform: scale(0.98); }
.oa-approval-icon { width: 44px; height: 44px; border-radius:124px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.oa-approval-info { flex: 1; min-width: 0; }
.oa-approval-title { font-size: 14px; font-weight: 500; color: #1a2332; display: block; }
.oa-approval-desc { font-size: 12px; color: #9aabba; margin-top: 2px; display: flex; align-items: center; gap: 8px; }
.oa-tag { font-size: 10px; padding: 0 8px; border-radius:30px; line-height: 18px; font-weight: 500; }
.oa-tag-urgent { background: rgba(251,110,140,0.08); color: #fb6e8c; }
.oa-tag-normal { background: rgba(110,142,251,0.08); color: #4F46E5; }
.oa-approval-right { text-align: right; flex-shrink: 0; }
.oa-approval-status { font-size: 11px; font-weight: 500; display: block; }
.status-pending { color: #fbaa50; }
.status-approved { color: #34c759; }
.status-rejected { color: #fb6e8c; }
.oa-approval-time { font-size: 11px; color: #b0c0cc; display: block; margin-top: 2px; }

/* 底部导航 */
.oa-bottom-nav { display: flex; background: rgba(255,255,255,0.5); backdrop-filter: blur(30px); -webkit-backdrop-filter: blur(30px); border-top: 1px solid rgba(255,255,255,0.4); padding: 6px 12px 14px; border-radius:322px 322px 0 0; }
.oa-tab { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 2px; font-size: 10px; color: #b0c0cc; cursor: pointer; padding: 4px 0; }
.oa-tab.active { color: #4F46E5; font-weight: 500; }
.oa-tab-label { display: block; }
</style>