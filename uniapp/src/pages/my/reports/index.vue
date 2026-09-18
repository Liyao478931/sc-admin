<template>
  <view class="mr-page">
    <!-- 统计卡片 -->
    <view class="mr-stats">
      <view class="mr-stat">
        <text class="mr-stat-num">{{ stats.total_count || 0 }}</text>
        <text class="mr-stat-label">总报工</text>
      </view>
      <view class="mr-stat">
        <text class="mr-stat-num">{{ stats.total_quantity || 0 }}</text>
        <text class="mr-stat-label">合格总数</text>
      </view>
      <view class="mr-stat">
        <text class="mr-stat-num">{{ stats.total_score || 0 }}</text>
        <text class="mr-stat-label">总工分</text>
      </view>
      <view class="mr-stat">
        <text class="mr-stat-num">{{ stats.pass_rate || 0 }}%</text>
        <text class="mr-stat-label">通过率</text>
      </view>
    </view>

    <!-- 状态筛选 Tab -->
    <view class="mr-tabs">
      <view v-for="t in tabs" :key="t.value" class="mr-tab" :class="{ active: currentTab === t.value }" @click="switchTab(t.value)">
        <text class="mr-tab-text">{{ t.label }}</text>
        <text class="mr-tab-badge" v-if="tabCount(t.value) > 0">{{ tabCount(t.value) }}</text>
        <view class="mr-tab-line" v-if="currentTab === t.value"></view>
      </view>
    </view>

    <!-- 列表 -->
    <scroll-view scroll-y class="mr-list" :refresher-enabled="true" :refresher-triggered="refreshing" @refresherrefresh="onRefresh" @scrolltolower="loadMore">
      <view v-if="loading && !list.length" class="mr-status"><text>加载中...</text></view>
      <view v-else-if="!list.length" class="mr-status">
        <u-icon name="empty-order" color="#d5dce4" size="44" />
        <text class="mr-empty-title">暂无报工记录</text>
        <text class="mr-empty-desc">当前筛选条件下没有报工记录</text>
      </view>
      <view v-else class="mr-cards">
        <view v-for="r in list" :key="r.id" class="mr-card" @click="goDetail(r)">
          <view class="mr-card-top">
            <view class="mr-card-no">
              <u-icon name="order" color="#4F46E5" size="14" />
              <text class="mr-card-no-text">{{ r.order_no || r.work_order_no }}</text>
            </view>
            <text class="mr-status-tag" :class="'st-' + r.status">{{ r.status_label }}</text>
          </view>
          <view class="mr-card-mid">
            <text class="mr-product">{{ r.product_name || '未知产品' }}</text>
            <text v-if="r.product_spec" class="mr-spec">{{ r.product_spec }}</text>
          </view>
          <view class="mr-card-bottom">
            <view class="mr-bottom-left">
              <text class="mr-qty">合格 {{ r.quantity || 0 }} 件</text>
              <text v-if="r.total_score" class="mr-score">{{ r.total_score }} 分</text>
            </view>
            <text class="mr-time">{{ formatTime(r.report_date) }}</text>
          </view>
          <!-- 草稿/已驳回操作：编辑 / 提交审核 -->
          <view v-if="Number(r.status) === 0 || Number(r.status) === 3" class="mr-actions" @click.stop>
            <view class="mr-action" @click="goEdit(r)"><u-icon name="edit-pen" color="#4F46E5" size="13" /><text>编辑</text></view>
            <view class="mr-action primary" @click="submitDraft(r)"><u-icon name="checkmark-circle" color="#fff" size="13" /><text>提交审核</text></view>
          </view>
        </view>
        <!-- 加载更多 -->
        <view v-if="list.length" class="mr-loadmore">
          <text v-if="loadingMore" class="mr-loadmore-text">加载中...</text>
          <text v-else-if="list.length >= total && total > 0" class="mr-loadmore-text">— 已加载全部 —</text>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref, computed } from 'vue'
import { onLoad } from '@dcloudio/uni-app'

const tabs = [
  { label: '全部', value: 0 },
  { label: '待审核', value: 1 },
  { label: '已通过', value: 2 },
  { label: '已驳回', value: 3 }
]

const list = ref([])
const total = ref(0)
const stats = ref({ total_count: 0, total_quantity: 0, total_score: 0, pass_rate: 0 })
const statusCounts = ref({ 0: 0, 1: 0, 2: 0, 3: 0, 4: 0 })
const currentTab = ref(0)
const page = ref(1)
const pageSize = 20
const loading = ref(false)
const loadingMore = ref(false)
const refreshing = ref(false)

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
function formatTime(t) {
  if (!t) return ''
  const s = String(t)
  return s.length > 10 ? s.slice(5, 16) : s
}
function tabCount(v) {
  if (v === 0) return statusCounts.value[1] + statusCounts.value[2] + statusCounts.value[3] + statusCounts.value[4]
  return statusCounts.value[v] || 0
}

async function loadStats() {
  try {
    const r = await api('/api/production/report/my-statistics', 'GET', { status: currentTab.value })
    stats.value = r || {}
  } catch (e) {}
}
async function loadList(reset = false) {
  if (reset) {
    page.value = 1
    list.value = []
  }
  loading.value = true
  try {
    const r = await api('/api/production/report/my-list', 'GET', { status: currentTab.value, page: page.value, pageSize })
    list.value = reset ? ((r && r.list) || []) : list.value.concat((r && r.list) || [])
    total.value = (r && r.total) || 0
    statusCounts.value = (r && r.status_counts) || { 0: 0, 1: 0, 2: 0, 3: 0, 4: 0 }
  } catch (e) {} finally { loading.value = false }
}
async function switchTab(v) {
  if (currentTab.value === v) return
  currentTab.value = v
  await Promise.all([loadStats(), loadList(true)])
}
async function onRefresh() {
  refreshing.value = true
  await Promise.all([loadStats(), loadList(true)])
  refreshing.value = false
}
async function loadMore() {
  if (loading.value || loadingMore.value || list.value.length >= total.value) return
  loadingMore.value = true
  page.value += 1
  await loadList()
  loadingMore.value = false
}
function goDetail(r) {
  uni.navigateTo({ url: '/pages/report/detail?id=' + r.id })
}
// 编辑草稿：跳报工页并带 report_id（自动回填）
function goEdit(r) {
  uni.navigateTo({ url: '/pages/report/index?report_id=' + r.id })
}
// 提交审核（仅草稿）
function submitDraft(r) {
  uni.showModal({
    title: '提交审核',
    content: `确认提交报工「${r.order_no || r.work_order_no}」进入审核流程吗？`,
    success: async (res) => {
      if (!res.confirm) return
      try {
        await api('/api/production/report/submit/' + r.id, 'POST')
        uni.showToast({ title: '已提交审核！', icon: 'success' })
        await Promise.all([loadStats(), loadList(true)])
      } catch (e) {
        uni.showToast({ title: e.msg || '提交失败', icon: 'none' })
      }
    }
  })
}

onLoad(() => {
  loadStats()
  loadList(true)
})
</script>

<style scoped>
.mr-page { min-height: 100vh; background: #F4F6FB; display: flex; flex-direction: column; }
.mr-stats { display: flex; gap: 8px; padding: 12px 16px; }
.mr-stat { flex: 1; background: rgba(255,255,255,0.9); border: 1px solid #E7ECF4; border-radius:24px; padding: 10px 4px; display: flex; flex-direction: column; align-items: center; box-shadow: 0 1px 4px rgba(0,0,0,0.02); }
.mr-stat-num { font-size: 18px; font-weight: 700; color: #1a2332; }
.mr-stat-label { font-size: 10px; color: #9ca3af; margin-top: 3px; }

.mr-tabs { display: flex; background: #fff; padding: 8px 16px 0; border-bottom: 1px solid #E7ECF4; }
.mr-tab { position: relative; flex: 1; display: flex; align-items: center; justify-content: center; gap: 4px; padding: 6px 0 10px; }
.mr-tab-text { font-size: 14px; color: #9ca3af; }
.mr-tab.active .mr-tab-text { color: #4F46E5; font-weight: 600; }
.mr-tab-badge { font-size: 10px; color: #b0c0cc; background: #EDF0F8; border-radius:24px; padding: 0 6px; line-height: 16px; }
.mr-tab-line { position: absolute; bottom: 0; left: 50%; transform: translateX(-50%); width: 24px; height: 2px; background: #4F46E5; border-radius:2px; }

.mr-list { flex: 1; height: 0; padding: 12px 16px; box-sizing: border-box; }
.mr-status { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 60px 0; gap: 8px; color: #b0c0cc; }
.mr-empty-title { font-size: 16px; color: #2c3e50; font-weight: 500; }
.mr-empty-desc { font-size: 13px; color: #9ca3af; }

.mr-card { background: rgba(255,255,255,0.95); border: 1px solid #E7ECF4; border-radius:124px; padding: 14px 16px; margin-bottom: 8px; box-shadow: 0 1px 4px rgba(0,0,0,0.02); }
.mr-card-top { display: flex; align-items: center; justify-content: space-between; }
.mr-card-no { display: flex; align-items: center; gap: 6px; }
.mr-card-no-text { font-size: 14px; font-weight: 700; color: #1a2332; }
.mr-status-tag { font-size: 11px; font-weight: 700; padding: 2px 10px; border-radius:30px; }
.mr-status-tag.st-0 { background: #f3f4f6; color: #6b7280; }
.mr-status-tag.st-1 { background: #fef3e2; color: #f59e0b; }
.mr-status-tag.st-2 { background: #f0f9eb; color: #34c759; }
.mr-status-tag.st-3 { background: #fdecea; color: #e74c5e; }
.mr-status-tag.st-4 { background: #f3f4f6; color: #6b7280; }
.mr-card-mid { margin-top: 8px; }
.mr-product { font-size: 15px; font-weight: 700; color: #1a2332; }
.mr-spec { font-size: 13px; color: #9ca3af; margin-left: 6px; }
.mr-card-bottom { display: flex; align-items: flex-end; justify-content: space-between; margin-top: 8px; }
.mr-bottom-left { display: flex; align-items: baseline; gap: 10px; }
.mr-qty { font-size: 14px; font-weight: 700; color: #4F46E5; }
.mr-score { font-size: 13px; color: #8a9aa8; }
.mr-time { font-size: 12px; color: #9ca3af; }
.mr-loadmore { text-align: center; padding: 14px 0 20px; }
.mr-loadmore-text { font-size: 12px; color: #b0c0cc; }
.mr-actions { display: flex; gap: 8px; margin-top: 10px; padding-top: 10px; border-top: 1px solid #F4F6FB; }
.mr-action { display: flex; align-items: center; gap: 4px; flex: 1; justify-content: center; padding: 8px; border-radius:22px; background: #f0f4ff; color: #4F46E5; font-size: 13px; font-weight: 600; }
.mr-action.primary { background: linear-gradient(135deg, #4F46E5, #7C6FF0); color: #fff; }
</style>
