<template>
  <view class="ma-page">
    <!-- 统计概览 -->
    <view class="ma-stats">
      <view class="ma-stat">
        <text class="ma-stat-num blue">{{ stats.total_quantity || 0 }}</text>
        <text class="ma-stat-label">总数量</text>
      </view>
      <view class="ma-stat">
        <text class="ma-stat-num green">{{ stats.total_types || 0 }}</text>
        <text class="ma-stat-label">总种类</text>
      </view>
      <view class="ma-stat">
        <text class="ma-stat-num orange">¥{{ formatMoney(stats.total_value) }}</text>
        <text class="ma-stat-label">总价值</text>
      </view>
    </view>

    <!-- 搜索筛选 -->
    <view class="ma-filter">
      <view class="ma-search-wrap">
        <u-icon name="search" color="#b0c0cc" size="15" />
        <u-input v-model="keyword" placeholder="搜索资产名称/编码" prefixIcon="search" border="none" confirm-type="search" :customStyle="{ height: '72rpx', fontSize: '26rpx' }" @confirm="onSearch" />
        <u-icon v-if="keyword" name="close-circle-fill" color="#c0cedc" size="15" @click="keyword = ''; onSearch()" />
      </view>
      <view class="ma-filter-btn" @click="filterOpen = true">
        <u-icon name="list-dot" color="#8a9aa8" size="16" />
      </view>
    </view>

    <!-- 列表 -->
    <scroll-view scroll-y class="ma-list" :refresher-enabled="true" :refresher-triggered="refreshing" @refresherrefresh="onRefresh" @scrolltolower="loadMore">
      <view v-if="loading && !list.length" class="ma-status"><text>加载中...</text></view>
      <view v-else-if="!list.length" class="ma-empty-wrap">
        <u-empty :text="isFiltered ? '未找到匹配资产' : '暂无资产'" :description="isFiltered ? '请调整搜索条件后重试。' : '您名下暂无资产，请从总仓领用或申请资产领用。'" mode="list" />
        <view class="ma-empty-actions">
          <u-button size="small" type="primary" :text="isFiltered ? '重置筛选' : '去领用'" shape="circle" @click="isFiltered ? resetFilter() : goApply()" />
        </view>
      </view>
      <view v-else class="ma-cards">
        <view v-for="a in list" :key="a.id" class="ma-card" @click="goDetail(a)">
          <view class="ma-card-header">
            <view class="ma-card-left">
              <text class="ma-tag" :class="'type-' + a.asset_type">{{ a.asset_type_label }}</text>
              <text class="ma-name">{{ a.asset_name }}</text>
              <text v-if="a.specification" class="ma-spec">{{ a.specification }}</text>
            </view>
            <text class="ma-status-tag" :class="'st-' + a.asset_status">{{ a.asset_status_label }}</text>
          </view>
          <view class="ma-card-body">
            <view class="ma-info">
              <text class="ma-code">编码：{{ a.asset_code || '-' }}</text>
              <text class="ma-qty">{{ a.quantity }} <text class="ma-unit">{{ a.unit }}</text></text>
              <text class="ma-date">入库：{{ formatDate(a.created_at) }}</text>
            </view>
          </view>
          <!-- 操作按钮：已报废不显示操作；调拨+退还（消耗合并到报工） -->
          <view v-if="Number(a.asset_status) !== 5" class="ma-actions" @click.stop>
            <view class="ma-action transfer" @click="goTransfer(a)"><u-icon name="rmb-circle" color="#409EFF" size="13" /><text>调拨</text></view>
            <view class="ma-action return" @click="goReturn(a)"><u-icon name="reload" color="#F56C6C" size="13" /><text>退还</text></view>
          </view>
          <view v-else class="ma-actions" @click.stop>
            <view class="ma-action disabled"><text>已报废，不可操作</text></view>
          </view>
        </view>
        <!-- 加载更多 -->
        <view v-if="list.length" class="ma-loadmore">
          <text v-if="loadingMore" class="ma-loadmore-text">加载中...</text>
          <text v-else-if="list.length >= total && total > 0" class="ma-loadmore-text">— 已加载全部 —</text>
        </view>
      </view>
    </scroll-view>

    <!-- 筛选面板 -->
    <u-popup :show="filterOpen" mode="bottom" round="24" @close="filterOpen = false">
      <view class="ma-sheet">
        <view class="ma-sheet-header">
          <text class="ma-sheet-title">筛选</text>
          <u-icon name="close" color="#b0c0cc" size="16" @click="filterOpen = false" />
        </view>
        <view class="ma-group">
          <text class="ma-group-label">资产类型</text>
          <view class="ma-options">
            <view v-for="t in typeOptions" :key="String(t.value)" class="ma-opt" :class="{ active: filter.asset_type === t.value }" @click="filter.asset_type = t.value">{{ t.label }}</view>
          </view>
        </view>
        <view class="ma-group">
          <text class="ma-group-label">资产状态</text>
          <view class="ma-options">
            <view v-for="s in statusOptions" :key="String(s.value)" class="ma-opt" :class="{ active: filter.asset_status === s.value }" @click="filter.asset_status = s.value">{{ s.label }}</view>
          </view>
        </view>
        <view class="ma-group">
          <text class="ma-group-label">排序方式</text>
          <view class="ma-options">
            <view v-for="s in sortOptions" :key="s.value" class="ma-opt" :class="{ active: filter.sort_field === s.value }" @click="filter.sort_field = s.value">{{ s.label }}</view>
          </view>
        </view>
        <view class="ma-sheet-actions">
          <view class="ma-sheet-btn reset" @click="resetFilter">重置</view>
          <view class="ma-sheet-btn confirm" @click="applyFilter">确认</view>
        </view>
      </view>
    </u-popup>
  </view>
</template>

<script setup>
import { ref, computed } from 'vue'
import { onLoad } from '@dcloudio/uni-app'

const typeOptions = [
  { label: '全部', value: '' },
  { label: '配件', value: 1 },
  { label: '固定资产', value: 2 },
  { label: '工具', value: 3 }
]
const statusOptions = [
  { label: '全部', value: '' },
  { label: '正常', value: 1 },
  { label: '维修中', value: 2 },
  { label: '闲置', value: 3 },
  { label: '待报废', value: 4 },
  { label: '已报废', value: 5 }
]
const sortOptions = [
  { label: '入库时间', value: 'created_at' },
  { label: '按名称', value: 'asset_name' },
  { label: '按数量', value: 'quantity' }
]

const list = ref([])
const total = ref(0)
const stats = ref({ total_quantity: 0, total_types: 0, total_value: 0 })
const keyword = ref('')
const filter = ref({ asset_type: '', asset_status: '', sort_field: 'created_at' })
const filterOpen = ref(false)
const page = ref(1)
const pageSize = 20
const loading = ref(false)
const loadingMore = ref(false)
const refreshing = ref(false)
const isFiltered = computed(() => !!keyword.value || !!filter.value.asset_type || !!filter.value.asset_status)

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
function formatDate(t) {
  return t ? String(t).slice(0, 10) : '-'
}
function formatMoney(v) {
  const n = Number(v || 0)
  if (n >= 10000) return (n / 10000).toFixed(1) + '万'
  return n.toLocaleString('zh-CN', { maximumFractionDigits: 0 })
}
function buildParams() {
  const p = { page: page.value, limit: pageSize }
  if (keyword.value) p.keyword = keyword.value
  if (filter.value.asset_type !== '') p.asset_type = filter.value.asset_type
  if (filter.value.asset_status !== '') p.asset_status = filter.value.asset_status
  if (filter.value.sort_field) { p.sort_field = filter.value.sort_field; p.sort_order = filter.value.sort_field === 'created_at' ? 'desc' : 'asc' }
  return p
}
async function loadList(reset = false) {
  if (reset) { page.value = 1; list.value = [] }
  loading.value = true
  try {
    const r = await api('/api/personal-assets/my-list', 'GET', buildParams())
    list.value = reset ? ((r && r.list) || []) : list.value.concat((r && r.list) || [])
    total.value = (r && r.total) || 0
    if (r && r.statistics) stats.value = r.statistics
  } catch (e) {} finally { loading.value = false }
}
async function onSearch() { await loadList(true) }
async function applyFilter() {
  filterOpen.value = false
  await loadList(true)
}
async function resetFilter() {
  keyword.value = ''
  filter.value = { asset_type: '', asset_status: '', sort_field: 'created_at' }
  filterOpen.value = false
  await loadList(true)
}
async function onRefresh() {
  refreshing.value = true
  await loadList(true)
  refreshing.value = false
}
async function loadMore() {
  if (loading.value || loadingMore.value || list.value.length >= total.value) return
  loadingMore.value = true
  page.value += 1
  await loadList()
  loadingMore.value = false
}
function goDetail(a) {
  uni.navigateTo({ url: '/pages/asset/detail?id=' + a.id })
}
function goTransfer(a) {
  uni.navigateTo({ url: '/pages/asset/transfer?asset_id=' + a.id })
}
function goReturn(a) {
  uni.navigateTo({ url: '/pages/asset/return?asset_id=' + a.id })
}
function goApply() {
  uni.navigateTo({ url: '/pages/asset/apply' })
}

onLoad(() => { loadList(true) })
</script>

<style scoped>
.ma-page { min-height: 100vh; background: #F4F6FB; display: flex; flex-direction: column; }
.ma-stats { display: flex; gap: 8px; padding: 12px 16px; }
.ma-stat { flex: 1; background: rgba(255,255,255,0.9); border: 1px solid #E7ECF4; border-radius:24px; padding: 12px 4px; display: flex; flex-direction: column; align-items: center; box-shadow: 0 1px 4px rgba(0,0,0,0.02); }
.ma-stat-num { font-size: 19px; font-weight: 700; }
.ma-stat-num.blue { color: #409EFF; }
.ma-stat-num.green { color: #67C23A; }
.ma-stat-num.orange { color: #E6A23C; font-size: 15px; }
.ma-stat-label { font-size: 10px; color: #9ca3af; margin-top: 3px; }

.ma-filter { display: flex; align-items: center; gap: 10px; padding: 10px 16px; background: #fff; border-bottom: 1px solid #E7ECF4; }
.ma-search-wrap { flex: 1; display: flex; align-items: center; gap: 6px; background: #f5f6fa; border-radius:30px; padding: 8px 14px; }
.ma-search-input { flex: 1; font-size: 14px; color: #1a2332; }
.ma-filter-btn { width: 36px; height: 36px; border-radius:50%; background: #f5f6fa; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }

.ma-list { flex: 1; height: 0; padding: 12px 16px; box-sizing: border-box; }
.ma-status { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 60px 0; gap: 8px; color: #b0c0cc; }
.ma-empty-title { font-size: 16px; color: #2c3e50; font-weight: 500; }
.ma-empty-desc { font-size: 13px; color: #9ca3af; }
.ma-empty-btn { margin-top: 6px; padding: 10px 32px; border-radius:30px; background: linear-gradient(135deg, #4F46E5, #7C6FF0); color: #fff; font-size: 14px; font-weight: 500; }
.ma-empty-btn.ghost { background: #f5f6fa; color: #8a9aa8; }

.ma-card { background: rgba(255,255,255,0.95); border: 1px solid #E7ECF4; border-radius:122px; padding: 14px 16px; margin-bottom: 10px; box-shadow: 0 1px 4px rgba(0,0,0,0.02); }
.ma-card-header { display: flex; align-items: center; justify-content: space-between; }
.ma-card-left { display: flex; align-items: center; gap: 8px; flex: 1; min-width: 0; }
.ma-tag { font-size: 10px; font-weight: 500; padding: 0 10px; border-radius:30px; line-height: 20px; flex-shrink: 0; }
.ma-tag.type-1 { background: #FFF3E0; color: #E65100; }
.ma-tag.type-2 { background: #E3F2FD; color: #0D47A1; }
.ma-tag.type-3 { background: #F3E5F5; color: #6A1B9A; }
.ma-name { font-size: 15px; font-weight: 600; color: #1a2332; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.ma-spec { font-size: 13px; color: #8a9aa8; flex-shrink: 0; }
.ma-status-tag { font-size: 10px; font-weight: 500; padding: 0 10px; border-radius:30px; line-height: 20px; flex-shrink: 0; }
.ma-status-tag.st-1 { background: #E8F5E9; color: #2E7D32; }
.ma-status-tag.st-2 { background: #FFF3E0; color: #E65100; }
.ma-status-tag.st-3 { background: #F3E5F5; color: #6A1B9A; }
.ma-status-tag.st-4 { background: #FFEBEE; color: #C62828; }
.ma-status-tag.st-5 { background: #E0E0E0; color: #757575; }
.ma-card-body { margin-top: 8px; }
.ma-info { display: flex; align-items: center; gap: 14px; flex-wrap: wrap; }
.ma-code { font-size: 12px; color: #b0c0cc; }
.ma-qty { font-size: 14px; font-weight: 700; color: #409EFF; }
.ma-unit { font-weight: 400; color: #8a9aa8; }
.ma-date { font-size: 12px; color: #b0c0cc; }
.ma-actions { display: flex; gap: 8px; margin-top: 10px; padding-top: 10px; border-top: 1px solid #F4F6FB; }
.ma-action { display: flex; align-items: center; gap: 4px; flex: 1; justify-content: center; padding: 8px; border-radius:30px; font-size: 13px; font-weight: 600; }
.ma-action.transfer { background: rgba(64,158,255,0.08); color: #409EFF; border: 1px solid rgba(64,158,255,0.15); }
.ma-action.return { background: rgba(245,108,108,0.08); color: #F56C6C; border: 1px solid rgba(245,108,108,0.15); }
.ma-action.disabled { background: #f5f5f5; color: #b0b0b0; }
.ma-loadmore { text-align: center; padding: 14px 0 20px; }
.ma-loadmore-text { font-size: 12px; color: #b0c0cc; }

.ma-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.3); z-index: 100; display: flex; align-items: flex-end; }
.ma-sheet { width: 100%; background: #fff; border-radius:224px 224px 0 0; padding: 20px 20px 32px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.ma-sheet-header { display: flex; align-items: center; justify-content: space-between; padding-bottom: 14px; border-bottom: 1px solid #EDF0F8; }
.ma-sheet-title { font-size: 17px; font-weight: 700; color: #1a2332; }
.ma-group { margin-top: 16px; }
.ma-group-label { font-size: 14px; font-weight: 600; color: #1a2332; margin-bottom: 8px; display: block; }
.ma-options { display: flex; flex-wrap: wrap; gap: 8px; }
.ma-opt { padding: 6px 16px; border-radius:30px; border: 1px solid #e8ecf1; background: #fafbfc; font-size: 13px; color: #8a9aa8; }
.ma-opt.active { background: rgba(110,142,251,0.08); color: #4F46E5; border-color: rgba(110,142,251,0.2); }
.ma-sheet-actions { display: flex; gap: 10px; margin-top: 20px; }
.ma-sheet-btn { flex: 1; text-align: center; padding: 12px; border-radius:124px; font-size: 15px; font-weight: 600; }
.ma-sheet-btn.reset { background: #f5f6fa; color: #8a9aa8; }
.ma-sheet-btn.confirm { background: linear-gradient(135deg, #4F46E5, #7C6FF0); color: #fff; }
</style>