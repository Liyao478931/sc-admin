<template>
  <view class="wb-page">
    <!-- 顶部导航 -->
    <view class="wb-nav" :style="{ paddingRight: (16 + capsuleRight) + 'px' }">
      <view class="wb-nav-left">
        <text class="wb-nav-title">工作台</text>
        <view class="wb-nav-actions">
          <view class="wb-search" @click="goSearch">
            <u-icon name="search" color="#b0c0cc" size="14" />
            <text class="wb-search-placeholder">搜索...</text>
          </view>
          <view class="wb-btn wb-btn-scan" @click="scan"><u-icon name="scan" color="#fff" size="18" /></view>
        </view>
      </view>
    </view>

    <!-- 统计指标 -->
    <view class="wb-stats">
      <view class="wb-stat" @click="goStat(0)">
        <text class="wb-stat-num">{{ stats.today_output.value }}<text class="wb-stat-unit">{{ stats.today_output.unit }}</text></text>
        <text class="wb-stat-label"><u-icon name="bag" color="#4e5a6b" size="14" /> 今日产量</text>
      </view>
      <view class="wb-stat" @click="goStat(1)">
        <text class="wb-stat-num">{{ stats.active_orders.value }}</text>
        <text class="wb-stat-label"><u-icon name="order" color="#4e5a6b" size="14" /> 在制工单</text>
      </view>
      <view class="wb-stat" @click="goStat(2)">
        <text class="wb-stat-num">{{ stats.equipment_rate.value }}<text class="wb-stat-unit">%</text></text>
        <text class="wb-stat-label"><u-icon name="setting" color="#4e5a6b" size="14" /> 设备开机率</text>
      </view>
      <view class="wb-stat" @click="goStat(3)">
        <text class="wb-stat-num">{{ stats.order_completion_rate.value }}<text class="wb-stat-unit">%</text></text>
        <text class="wb-stat-label"><u-icon name="checkmark" color="#4e5a6b" size="14" /> 订单完成率</text>
      </view>
    </view>

    <!-- 快捷功能入口 -->
    <view class="wb-section">
      <view class="wb-section-title"><MIcon name="zap" :size="15" color="#f59e0b" /><text style="margin-left:4px">快捷功能</text></view>
      <view class="wb-quick">
        <view class="wb-quick-item" v-for="(it, i) in displayQuick" :key="i" @click="quickClick(it)">
          <view class="wb-quick-icon" :style="{ background: quickColor(i) }">
            <image v-if="resolveIcon(it.icon).type === 'img'" :src="resolveIcon(it.icon).val" style="width:20px;height:20px" mode="aspectFit" />
            <MIcon v-else-if="resolveIcon(it.icon).type === 'mi'" :name="resolveIcon(it.icon).val" color="#fff" :size="20" :weight="2" />
            <u-icon v-else-if="resolveIcon(it.icon).type === 'ui'" :name="resolveIcon(it.icon).val" color="#fff" size="20" />
            <text v-else-if="resolveIcon(it.icon).val" style="font-size:20px;color:#fff">{{ resolveIcon(it.icon).val }}</text>
          </view>
          <text class="wb-quick-name">{{ it.name }}</text>
        </view>
        <view v-if="hasMore" class="wb-quick-item wb-quick-more" @click="goMore">
          <view class="wb-quick-icon" :style="{ background: '#eef1f7', color: '#5b6472', fontSize: '22px', fontWeight: '600' }">
            <text style="line-height:1">…</text>
          </view>
          <text class="wb-quick-name">更多功能</text>
        </view>
      </view>
    </view>

    <!-- 待办工单 -->
    <view class="wb-section">
      <view class="wb-section-title"><text><u-icon name="list" color="#1d2129" size="15" /> 待办工单</text></view>
      <view v-if="todos.length" class="wb-todo" v-for="t in todos" :key="t.id" @click="goTodo(t)">
        <view class="wb-todo-bar" :style="{ background: priorityColor(t.priority) }"></view>
        <view class="wb-todo-info">
          <text class="wb-todo-no">{{ t.order_no || '工单' }}</text>
          <text class="wb-todo-name">{{ t.product_name || '' }}</text>
          <text class="wb-todo-meta">
            <text>批量 {{ t.plan_quantity || 0 }} 件</text>
            <text v-if="t.priority === 'high' || t.priority === '紧急' || t.priority === '3'" class="wb-tag wb-tag-urgent">紧急</text>
            <text v-if="t.status === 'inspection'" class="wb-tag wb-tag-blue">待检验</text>
            <text v-if="t.status === 'pending'" class="wb-tag wb-tag-gray">待上线</text>
          </text>
        </view>
        <view class="wb-todo-status">
          <text class="wb-todo-status-text" :style="{ color: statusColor(t.status) }">{{ statusText(t.status) }}</text>
          <text class="wb-todo-progress">{{ t.progress || 0 }}%</text>
        </view>
      </view>
      <u-empty v-else text="暂无待办工单" mode="list" />
    </view>
  </view>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { resolveIcon } from '@/utils/icon'

const props = defineProps({
  capsuleRight: { type: Number, default: 0 }
})

const userInfo = ref({})
const stats = ref({
  today_output: { value: 0, unit: '件' },
  active_orders: { value: 0 },
  equipment_rate: { value: 0, unit: '%' },
  order_completion_rate: { value: 0, unit: '%' }
})
const quickEntries = ref([])
const QUICK_MAX = 7
const quickAll = computed(() => quickEntries.value.filter(q => !(q.name || '').includes('更多')))
const displayQuick = computed(() => quickAll.value.slice(0, QUICK_MAX))
const hasMore = computed(() => quickAll.value.length > QUICK_MAX)
function goMore() { uni.navigateTo({ url: '/pages/more/index?location=home' }) }
const todos = ref([])
const unread = ref(0)
let pollTimer = null

const greeting = computed(() => {
  const h = new Date().getHours()
  if (h >= 6 && h < 12) return '上午好'
  if (h >= 12 && h < 14) return '中午好'
  if (h >= 14 && h < 18) return '下午好'
  if (h >= 18 && h < 22) return '晚上好'
  return '夜深了'
})

const QUICK_COLORS = ['#3d5a73', '#c97d5a', '#4a8f8f', '#8a7aa8', '#c99a3a', '#5a8faa', '#e07a5f', '#4F46E5']
function quickColor(i) { return QUICK_COLORS[i % QUICK_COLORS.length] }

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

async function loadAll() {
  try {
    const [userRes, statRes, quickRes, todoRes, unreadRes] = await Promise.all([
      api('/api/user/profile').catch(() => null),
      api('/api/dashboard/statistics').catch(() => null),
      api('/api/app/functions', 'GET', { location: 'home' }).catch(() => null),
      api('/api/dashboard/todo-tasks', 'GET', { limit: 3 }).catch(() => null),
      api('/api/notification/unread-count').catch(() => null)
    ])
    if (userRes) userInfo.value = userRes
    if (statRes) stats.value = Object.assign({}, stats.value, statRes)
    if (quickRes) {
      const list = (quickRes.list || []).filter(q => q.path !== null)
      // 末尾追加「更多功能」（携带 location=home，更多功能页按首页位置过滤）
      if (!list.some(q => (q.name || '').includes('更多'))) {
        list.push({ id: 0, name: '更多功能', icon: 'more-dot-fill', path: { url: '/pages/more/index?location=home' } })
      }
      quickEntries.value = list
    }
    if (todoRes) todos.value = (todoRes.list || [])
    if (unreadRes) unread.value = (unreadRes.count || 0)
  } catch (e) {}
}

function scan() {
  // #ifdef H5
  uni.showToast({ title: '请在微信小程序中使用扫码', icon: 'none' })
  // #endif
  // #ifndef H5
  uni.scanCode({
    success: (res) => {
      const result = (res.result || '').trim()
      if (!result) {
        uni.showToast({ title: '二维码内容为空', icon: 'none' })
        return
      }
      // 识别并跳转设备/物料/产品 H5 页面
      let url = ''
      try {
        // 如果是完整 URL（设备/物料/产品 H5 页面）
        if (/^https?:\/\//i.test(result)) {
          url = result
        } else {
          // 纯编码：尝试按规则拼 H5 地址
          // 设备编码：字母+数字，如 SC-2024-001
          // 物料编码：字母+数字，如 MAT-2024-001
          // 产品编码：字母+数字，如 PRO-2024-001
          if (/^\w{2,}-\d{4}-\d{3,}$/i.test(result)) {
            if (/^SC-/i.test(result)) {
              url = uni.$base + '/m/device/' + encodeURIComponent(result)
            } else if (/^MAT-/i.test(result)) {
              url = uni.$base + '/m/material/' + encodeURIComponent(result)
            } else if (/^PRO-/i.test(result)) {
              url = uni.$base + '/m/product/' + encodeURIComponent(result)
            } else {
              url = uni.$base + '/m/device/' + encodeURIComponent(result)
            }
          } else {
            // 无法识别：打开设备页兜底
            url = uni.$base + '/m/device/' + encodeURIComponent(result)
          }
        }
      } catch (e) {
        uni.showToast({ title: '二维码解析失败', icon: 'none' })
        return
      }
      if (url) {
        uni.navigateTo({ url: '/pages/sub/webview/index?url=' + encodeURIComponent(url) })
      }
    },
    fail: () => {}
  })
  // #endif
}

function goSearch() { uni.navigateTo({ url: '/pages/search/index' }) }
function goMessages() { uni.navigateTo({ url: '/pages/messages/index' }) }
function goStat(i) {
  // 统计详情统一跳转数据驾驶舱（产量/工单/设备/订单统计均在驾驶舱展示）
  uni.navigateTo({ url: '/pages/sub/cockpit/index' })
}
function goTodo(t) { uni.navigateTo({ url: '/pages/order/detail?id=' + (t.id || t.work_order_id || 0) }) }

function quickClick(it) {
  const p = it.path ? (it.path.url || it.path.path || '') : ''
  if (p && p.startsWith('/pages')) uni.navigateTo({ url: p })
  else uni.showToast({ title: '「' + (it.name || '功能') + '」暂未配置路径', icon: 'none' })
}

function priorityColor(p) {
  if (p === 'high' || p === '紧急' || p === '3') return '#e74c5e'
  if (p === 'medium' || p === '中等' || p === '2') return '#f59e0b'
  return '#34c759'
}
function statusText(s) {
  return { processing: '进行中', inspection: '待检验', pending: '待上线', done: '已完成' }[s] || (s || '待处理')
}
function statusColor(s) {
  return { processing: '#f59e0b', inspection: '#4F46E5', pending: '#9ca3af', done: '#34c759' }[s] || '#8a9aa8'
}

onMounted(() => {
  loadAll()
  pollTimer = setInterval(() => {
    api('/api/notification/unread-count').then(r => { unread.value = (r && r.count) || 0 }).catch(() => {})
  }, 30000)
})
onUnmounted(() => { if (pollTimer) { clearInterval(pollTimer); pollTimer = null } })
</script>

<style scoped>
.wb-page { min-height: 100vh; background: #F4F6FB; display: flex; flex-direction: column; }
.wb-nav { padding: 10px 16px 8px; background: #fff; }
.wb-nav-left { display: flex; align-items: center; gap: 10px; }
.wb-nav-title { font-size: 18px; font-weight: 700; color: #1a2332; flex-shrink: 0; }
.wb-nav-actions { display: flex; align-items: center; gap: 8px; flex: 1; }
.wb-btn { position: relative; width: 38px; height: 38px; border-radius:50%; background: #fff;
  box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
  display: flex; align-items: center; justify-content: center; font-size: 17px; flex-shrink: 0; }
.wb-btn-scan { background: linear-gradient(135deg, #4F46E5, #7C6FF0); border: none; color: #fff; box-shadow: 0 6px 16px rgba(79,70,229,0.35); }
.wb-search { max-width: 200px; flex: 1; min-width: 0; display: flex; align-items: center; gap: 8px; background: #EDF0F8; border-radius:24px; padding: 0 12px; height: 34px; }
.wb-search-icon { font-size: 14px; }
.wb-search-placeholder { font-size: 14px; color: #b0c0cc; }
.wb-stats { display: flex; gap: 8px; padding: 14px 16px 0; }
.wb-stat { flex: 1; background: #fff; border-radius:20rpx; box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06); padding: 14px 6px; display: flex; flex-direction: column; align-items: center; }
.wb-stat:active { background: #EDF0F8; }
.wb-stat-num { font-size: 20px; font-weight: 700; color: #4F46E5; }
.wb-stat-unit { font-size: 11px; font-weight: 400; color: #b0c0cc; margin-left: 2px; }
.wb-stat-label { font-size: 10px; color: #8a9aa8; margin-top: 6px; }
.wb-section { padding: 14px 16px 0; }
.wb-section-title { font-size: 14px; font-weight: 600; color: #1a2332; padding: 0 4px 10px; }
.wb-quick { display: flex; flex-wrap: wrap; gap: 8px; }
.wb-quick-item { width: calc(25% - 6px); display: flex; flex-direction: column; align-items: center; gap: 6px; background: #fff; border-radius:24rpx; box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06); padding: 14px 6px; box-sizing: border-box; }
.wb-quick-item:active { background: #EDF0F8; }
.wb-quick-icon { width: 40px; height: 40px; border-radius:124px; display: flex; align-items: center; justify-content: center; font-size: 20px; color: #fff; }
.wb-quick-name { font-size: 11px; color: #1a2332; }
.wb-quick-more .wb-quick-icon { border: 1.5rpx dashed #c9d0dc; }
.wb-quick-more:active { background: #EDF0F8; }
.wb-todo { display: flex; align-items: center; gap: 10px; background: #fff; border-radius:24rpx; box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06); padding: 14px 16px; margin-bottom: 8px; }
.wb-todo-bar { width: 4px; height: 32px; border-radius:24px; flex-shrink: 0; }
.wb-todo-info { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.wb-todo-no { font-size: 14px; font-weight: 600; color: #1a2332; }
.wb-todo-name { font-size: 12px; color: #8a9aa8; margin-top: 2px; }
.wb-todo-meta { font-size: 11px; color: #b0c0cc; margin-top: 2px; display: flex; align-items: center; gap: 8px; }
.wb-tag { font-size: 10px; padding: 0 8px; border-radius:30px; line-height: 18px; }
.wb-tag-urgent { background: rgba(251,110,140,0.1); color: #fb6e8c; }
.wb-tag-blue { background: rgba(79,70,229,0.08); color: #4F46E5; }
.wb-tag-gray { background: rgba(0,0,0,0.04); color: #9ca3af; }
.wb-todo-status { display: flex; flex-direction: column; align-items: flex-end; gap: 4px; }
.wb-todo-status-text { font-size: 11px; font-weight: 500; }
.wb-todo-progress { font-size: 11px; color: #b0c0cc; }
.wb-empty { text-align: center; color: #b0c0cc; font-size: 13px; padding: 24px 0; background: rgba(255,255,255,0.6); border-radius:122px; }
</style>
