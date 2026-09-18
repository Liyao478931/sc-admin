<template>
  <view class="ah-page">
    <!-- 统计卡 -->
    <view class="ah-stats">
      <view class="ah-stat">
        <text class="ah-stat-num">{{ stats.total_count || 0 }}</text>
        <text class="ah-stat-label">本月审批</text>
      </view>
      <view class="ah-stat">
        <text class="ah-stat-num green">{{ stats.approved_count || 0 }}</text>
        <text class="ah-stat-label">已通过</text>
      </view>
      <view class="ah-stat">
        <text class="ah-stat-num red">{{ stats.rejected_count || 0 }}</text>
        <text class="ah-stat-label">已驳回</text>
      </view>
      <view class="ah-stat">
        <text class="ah-stat-num">{{ stats.avg_duration != null ? stats.avg_duration : '-' }}</text>
        <text class="ah-stat-label">平均时长(h)</text>
      </view>
    </view>

    <!-- 角色筛选 -->
    <view class="ah-tabs">
      <view v-for="t in roleTabs" :key="t.value" class="ah-tab" :class="{ active: roleTab === t.value }" @click="switchRole(t.value)">
        <text class="ah-tab-text">{{ t.label }}</text>
      </view>
    </view>
    <!-- 结果筛选 -->
    <view class="ah-tabs result">
      <view v-for="t in resultTabs" :key="t.value" class="ah-tab" :class="{ active: resultTab === t.value }" @click="switchResult(t.value)">
        <text class="ah-tab-text">{{ t.label }}</text>
      </view>
    </view>

    <!-- 列表 -->
    <scroll-view scroll-y class="ah-list" :refresher-enabled="true" :refresher-triggered="refreshing" @refresherrefresh="onRefresh" @scrolltolower="loadMore">
      <view v-if="loading && !list.length" class="ah-status"><text>加载中...</text></view>
      <u-empty v-else-if="!list.length" text="暂无审批历史" mode="list" />
      <view v-else class="ah-cards">
        <view v-for="r in list" :key="r.id" class="ah-card" @click="openDetail(r)">
          <view class="ah-card-top">
            <text class="ah-biz-tag">{{ r.business_name }}</text>
            <text class="ah-result-tag" :class="'rs-' + r.status">{{ r.result_label }}</text>
            <text class="ah-role">{{ r.my_role_label }}</text>
          </view>
          <view class="ah-card-no">
            <u-icon name="order" color="#4F46E5" size="14" />
            <text class="ah-no-text">{{ r.business_no }}</text>
          </view>
          <text class="ah-title">{{ r.business_title }}</text>
          <view class="ah-opinion" v-if="r.my_opinion && r.my_opinion !== '-'"><text class="ah-opinion-label">我的意见：</text><text class="ah-opinion-text">{{ r.my_opinion }}</text></view>
          <view class="ah-card-bottom">
            <text class="ah-meta">申请人：{{ r.applicant_name }}</text>
            <text class="ah-time">{{ formatTime(r.handle_time) }}</text>
          </view>
        </view>
        <view v-if="list.length" class="ah-loadmore">
          <text v-if="loadingMore" class="ah-loadmore-text">加载中...</text>
          <text v-else-if="list.length >= total && total > 0" class="ah-loadmore-text">— 已加载全部 —</text>
        </view>
      </view>
    </scroll-view>

    <!-- 详情弹窗（只读） -->
    <u-popup :show="detailVisible" mode="bottom" round="24" @close="detailVisible = false">
      <view class="ah-sheet">
        <view class="ah-sheet-head">
          <text class="ah-sheet-title">审批详情</text>
          <view class="ah-sheet-close" @click="detailVisible = false"><u-icon name="close" color="#8a9aa8" size="16" /></view>
        </view>
        <scroll-view scroll-y class="ah-sheet-body">
          <view v-if="detailData" class="ah-detail">
            <view class="ah-detail-item" v-for="(it, i) in detailData.bizSummary" :key="i">
              <text class="ah-detail-label">{{ it.label }}</text><text class="ah-detail-value">{{ it.value }}</text>
            </view>
          </view>
          <view v-if="detailData && detailData.bizPhotos && detailData.bizPhotos.length" class="ah-photos">
            <text class="ah-photos-label">作业照片（{{ detailData.bizPhotos.length }} 张）</text>
            <view class="ah-photo-grid">
              <image v-for="(u, i) in detailData.bizPhotos" :key="i" :src="imgUrl(u)" mode="aspectFill" class="ah-photo" @click="preview(i)" />
            </view>
          </view>
        </scroll-view>
      </view>
    </u-popup>
  </view>
</template>

<script setup>
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'

const roleTabs = [
  { label: '全部', value: '' },
  { label: '我审批的', value: '1' },
  { label: '我申请的', value: '2' }
]
const resultTabs = [
  { label: '全部结果', value: '' },
  { label: '已通过', value: '2' },
  { label: '已驳回', value: '3' }
]

const list = ref([])
const total = ref(0)
const stats = ref({ total_count: 0, approved_count: 0, rejected_count: 0, avg_duration: null })
const roleTab = ref('')
const resultTab = ref('')
const page = ref(1)
const pageSize = 15
const loading = ref(false)
const loadingMore = ref(false)
const refreshing = ref(false)
const detailVisible = ref(false)
const detailData = ref(null)

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
function imgUrl(val) {
  if (!val) return ''
  if (val.startsWith('http://') || val.startsWith('https://')) return val
  if (val.startsWith('/')) return uni.$base + val
  return val
}
function formatTime(t) {
  if (!t || t === '-') return '-'
  const s = String(t).replace('T', ' ')
  return s.length > 16 ? s.slice(0, 16) : s
}

async function loadList(reset = false) {
  if (reset) { page.value = 1; list.value = [] }
  loading.value = true
  try {
    const params = { page: page.value, pageSize }
    if (roleTab.value) params.role = roleTab.value
    if (resultTab.value) params.result = resultTab.value
    const r = await api('/api/approval/history', 'GET', params)
    list.value = reset ? ((r && r.list) || []) : list.value.concat((r && r.list) || [])
    total.value = (r && r.total) || 0
    stats.value = (r && r.stats) || { total_count: 0, approved_count: 0, rejected_count: 0, avg_duration: null }
  } catch (e) {} finally { loading.value = false }
}
async function switchRole(v) { roleTab.value = roleTab.value === v ? '' : v; await loadList(true) }
async function switchResult(v) { resultTab.value = resultTab.value === v ? '' : v; await loadList(true) }
async function onRefresh() { refreshing.value = true; await loadList(true); refreshing.value = false }
async function loadMore() {
  if (loading.value || loadingMore.value || list.value.length >= total.value) return
  loadingMore.value = true
  page.value += 1
  await loadList()
  loadingMore.value = false
}

async function openDetail(r) {
  detailVisible.value = true
  detailData.value = null
  try {
    detailData.value = await api('/api/approval/detail/' + r.id)
  } catch (e) { detailData.value = null }
}
function preview(idx) {
  uni.previewImage({ urls: (detailData.value.bizPhotos || []).map(imgUrl), current: idx })
}

onLoad(() => { loadList(true) })
</script>

<style scoped>
.ah-page { min-height: 100vh; background: #F4F6FB; display: flex; flex-direction: column; }
.ah-stats { display: flex; gap: 8px; padding: 12px 16px; }
.ah-stat { flex: 1; background: rgba(255,255,255,0.9); border: 1px solid #E7ECF4; border-radius:24px; padding: 10px 4px; display: flex; flex-direction: column; align-items: center; }
.ah-stat-num { font-size: 18px; font-weight: 700; color: #1a2332; }
.ah-stat-num.green { color: #34c759; }
.ah-stat-num.red { color: #e74c5e; }
.ah-stat-label { font-size: 10px; color: #9ca3af; margin-top: 3px; }
.ah-tabs { display: flex; background: #fff; padding: 6px 16px; }
.ah-tabs.result { border-top: 1px solid #EDF0F8; }
.ah-tab { padding: 6px 18px; margin-right: 8px; border-radius:24px; background: #F4F6FB; }
.ah-tab.active { background: #4F46E5; }
.ah-tab-text { font-size: 13px; color: #606266; }
.ah-tab.active .ah-tab-text { color: #fff; font-weight: 600; }
.ah-list { flex: 1; height: 0; padding: 12px 16px; box-sizing: border-box; }
.ah-status { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 60px 0; gap: 8px; color: #b0c0cc; }
.ah-empty-text { font-size: 14px; color: #b0c0cc; }
.ah-card { background: rgba(255,255,255,0.95); border: 1px solid #E7ECF4; border-radius:124px; padding: 14px 16px; padding-right: calc(16px + constant(safe-area-inset-right)); padding-right: calc(16px + env(safe-area-inset-right)); margin-bottom: 8px; }
.ah-card-top { display: flex; align-items: center; gap: 8px; }
.ah-biz-tag { font-size: 11px; font-weight: 600; color: #4F46E5; background: #f0f4ff; padding: 2px 10px; border-radius:24px; }
.ah-result-tag { font-size: 11px; font-weight: 600; padding: 2px 10px; border-radius:24px; }
.ah-result-tag.rs-2 { background: #f0f9eb; color: #34c759; }
.ah-result-tag.rs-3 { background: #fdecea; color: #e74c5e; }
.ah-result-tag.rs-4 { background: #f3f4f6; color: #6b7280; }
.ah-role { font-size: 11px; color: #9ca3af; margin-left: auto; }
.ah-card-no { display: flex; align-items: center; gap: 6px; margin-top: 8px; }
.ah-no-text { font-size: 14px; font-weight: 700; color: #1a2332; }
.ah-title { display: block; font-size: 13px; color: #4a5568; margin-top: 4px; }
.ah-opinion { margin-top: 6px; background: #f8fafc; border-radius:24px; padding: 6px 10px; }
.ah-opinion-label { font-size: 12px; color: #9ca3af; }
.ah-opinion-text { font-size: 12px; color: #4a5568; }
.ah-card-bottom { display: flex; align-items: center; justify-content: space-between; margin-top: 8px; }
.ah-meta { font-size: 12px; color: #9ca3af; }
.ah-time { font-size: 12px; color: #b0c0cc; }
.ah-loadmore { text-align: center; padding: 14px 0 20px; }
.ah-loadmore-text { font-size: 12px; color: #b0c0cc; }
/* 详情弹窗 */
.ah-mask { position: fixed; inset: 0; background: rgba(0,0,0,0.4); z-index: 100; display: flex; align-items: flex-end; }
.ah-sheet { width: 100%; background: #fff; border-radius:224px 224px 0 0; max-height: 80vh; display: flex; flex-direction: column;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.ah-sheet-head { display: flex; align-items: center; justify-content: space-between; padding: 18px 20px 10px; border-bottom: 1px solid #EDF0F8; }
.ah-sheet-title { font-size: 16px; font-weight: 700; color: #1a2332; }
.ah-sheet-close { width: 28px; height: 28px; border-radius:50%; background: #EDF0F8; display: flex; align-items: center; justify-content: center; }
.ah-sheet-body { flex: 1; max-height: 60vh; padding: 12px 20px; box-sizing: border-box; }
.ah-detail { background: #f8fafc; border-radius:24px; padding: 10px 14px; margin-bottom: 10px; }
.ah-detail-item { display: flex; align-items: flex-start; padding: 5px 0; }
.ah-detail-label { width: 70px; flex-shrink: 0; font-size: 12px; color: #9ca3af; }
.ah-detail-value { flex: 1; font-size: 13px; color: #1a2332; }
.ah-photos-label { display: block; font-size: 13px; font-weight: 600; color: #1a2332; margin-bottom: 8px; }
.ah-photo-grid { display: flex; flex-wrap: wrap; gap: 8px; }
.ah-photo { width: 80px; height: 80px; border-radius:24px; }
</style>
