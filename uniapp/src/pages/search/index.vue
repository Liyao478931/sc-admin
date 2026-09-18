<template>
  <view class="search-page">
    <!-- 搜索栏 -->
    <view class="search-bar">
      <view class="search-wrap">
        <MIcon name="search" :size="18" color="#b0c0cc" />
        <u-input v-model="keyword" placeholder="搜索工单、产品、客户..." prefixIcon="search" border="none" confirm-type="search" :customStyle="{ height: '72rpx', fontSize: '26rpx' }" @confirm="doSearch" />
        <view v-if="keyword" class="clear-btn" @click="clearKeyword"><MIcon name="close" :size="14" color="#b0c0cc" /></view>
      </view>
      <view class="search-btn" @click="doSearch"><text>搜索</text></view>
    </view>

    <!-- 结果 -->
    <scroll-view scroll-y class="result-list">
      <template v-if="searched">
        <view v-if="orders.length || products.length || customers.length">
          <!-- 工单 -->
          <view v-if="orders.length" class="group">
            <view class="group-title"><MIcon name="clipboard" :size="15" color="#1d2129" /><text style="margin-left:4px">工单（{{ orders.length }}）</text></view>
            <view class="result-item" v-for="o in orders" :key="o.id" @click="toast(o.order_no + ' · ' + (o.product_name || ''))">
              <text class="ri-title">{{ o.order_no || '工单' }}</text>
              <text class="ri-desc">{{ o.product_name || '' }}</text>
            </view>
          </view>
          <!-- 产品 -->
          <view v-if="products.length" class="group">
            <view class="group-title"><MIcon name="box" :size="15" color="#1d2129" /><text style="margin-left:4px">产品（{{ products.length }}）</text></view>
            <view class="result-item" v-for="p in products" :key="p.id" @click="toast(p.product_name)">
              <text class="ri-title">{{ p.product_name || '产品' }}</text>
              <text class="ri-desc">{{ p.product_code || '' }}</text>
            </view>
          </view>
          <!-- 客户 -->
          <view v-if="customers.length" class="group">
            <view class="group-title"><MIcon name="building" :size="15" color="#1d2129" /><text style="margin-left:4px">客户（{{ customers.length }}）</text></view>
            <view class="result-item" v-for="c in customers" :key="c.id" @click="toast(c.customer_name)">
              <text class="ri-title">{{ c.customer_name || '客户' }}</text>
              <text class="ri-desc">{{ c.contact_person || '' }}</text>
            </view>
          </view>
        </view>
        <view v-else class="empty">
          <MIcon name="search" :size="44" color="#c6d2e0" />
          <text class="empty-title">未找到相关结果</text>
        </view>
      </template>
      <view v-else class="empty">
        <MIcon name="search" :size="44" color="#c6d2e0" />
        <text class="empty-title">搜索工单、产品、客户</text>
        <text class="empty-desc">输入关键词开始搜索</text>
      </view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref } from 'vue'

const keyword = ref('')
const orders = ref([])
const products = ref([])
const customers = ref([])
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

async function doSearch() {
  const kw = keyword.value.trim()
  if (!kw) { uni.showToast({ title: '请输入搜索关键词', icon: 'none' }); return }
  searched.value = true
  uni.showLoading({ title: '搜索中...' })
  try {
    const r = await api('/api/search/global', 'GET', { keyword: kw })
    orders.value = (r && r.orders) || []
    products.value = (r && r.products) || []
    customers.value = (r && r.customers) || []
  } catch (e) {
    orders.value = []; products.value = []; customers.value = []
  }
  uni.hideLoading()
}

function clearKeyword() { keyword.value = ''; searched.value = false; orders.value = []; products.value = []; customers.value = [] }
function toast(t) { uni.showToast({ title: t || '暂无详情', icon: 'none' }) }
</script>

<style scoped>
.search-page { min-height: 100vh; background: #F4F6FB; }
.search-bar { display: flex; align-items: center; gap: 10px; padding: 12px 16px; padding-right: calc(16px + constant(safe-area-inset-right)); padding-right: calc(16px + env(safe-area-inset-right)); background: #fff; }
.search-wrap { flex: 1; display: flex; align-items: center; background: #EDF0F8; border-radius:24px; padding: 0 14px; height: 38px; }
.search-icon { font-size: 14px; margin-right: 8px; }
.search-input { flex: 1; font-size: 14px; height: 38px; }
.clear-btn { width: 20px; height: 20px; border-radius:50%; background: #c0cedc; color: #fff; font-size: 11px; display: flex; align-items: center; justify-content: center; }
.search-btn { flex-shrink: 0; color: #4F46E5; font-size: 15px; font-weight: 500; padding: 6px 10px; }
.result-list { padding: 12px 16px; box-sizing: border-box; }
.group { margin-bottom: 14px; }
.group-title { font-size: 14px; font-weight: 600; color: #1a2332; padding: 4px 0 8px; }
.result-item { background: #fff; border-radius:24px; padding: 12px 16px; margin-bottom: 8px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.result-item:active { background: #EDF0F8; }
.ri-title { display: block; font-size: 14px; font-weight: 500; color: #1a2332; }
.ri-desc { display: block; font-size: 12px; color: #8a9aa8; margin-top: 2px; }
.empty { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 80px 0; }
.empty-icon { font-size: 56px; }
.empty-title { font-size: 16px; color: #8a9aa8; margin-top: 16px; font-weight: 500; }
.empty-desc { font-size: 13px; color: #b0c0cc; margin-top: 6px; }
</style>
