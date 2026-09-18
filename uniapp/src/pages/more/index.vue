<template>
  <view class="more-page">
    <!-- 顶部搜索 -->
    <view class="search-bar">
      <view class="search-wrap">
        <MIcon name="search" :size="18" color="#b0c0cc" />
        <u-input v-model="keyword" placeholder="搜索菜单..." prefixIcon="search" border="none" :customStyle="{ height: '72rpx', fontSize: '26rpx' }" />
        <view v-if="keyword" class="clear-btn" @click="keyword = ''"><MIcon name="close" :size="14" color="#b0c0cc" /></view>
      </view>
    </view>

    <!-- 全部功能网格 -->
    <view class="more-grid">
      <view class="more-item" v-for="(it, i) in filtered" :key="i" @click="go(it)">
        <view class="more-icon" :style="{ background: color(i) }">
          <image v-if="resolveIcon(it.icon).type === 'img'" :src="resolveIcon(it.icon).val" style="width:22px;height:22px" mode="aspectFit" />
          <MIcon v-else-if="resolveIcon(it.icon).type === 'mi'" :name="resolveIcon(it.icon).val" color="#fff" :size="22" :weight="2" />
          <u-icon v-else-if="resolveIcon(it.icon).type === 'ui'" :name="resolveIcon(it.icon).val" color="#fff" size="22" />
          <text v-else-if="resolveIcon(it.icon).val" style="font-size:22px;color:#fff">{{ resolveIcon(it.icon).val }}</text>
        </view>
        <text class="more-name">{{ it.name }}</text>
      </view>
      <view v-if="!filtered.length" class="more-empty">未找到相关菜单</view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { resolveIcon } from '@/utils/icon'

const list = ref([])
const keyword = ref('')
let curLocation = ''
const COLORS = ['#3d5a73', '#c97d5a', '#4a8f8f', '#8a7aa8', '#c99a3a', '#5a8faa', '#e07a5f', '#4F46E5']
function color(i) { return COLORS[i % COLORS.length] }

const filtered = computed(() => {
  const kw = keyword.value.trim()
  if (!kw) return list.value
  return list.value.filter(it => (it.name || '').includes(kw))
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

async function load() {
  try {
    // 按来源位置过滤（home=首页 / profile=我的页面），遵守 display_location
    const params = {}
    if (curLocation === 'home' || curLocation === 'profile') params.location = curLocation
    const r = await api('/api/app/functions', 'GET', params)
    list.value = (r && r.list) || []
  } catch (e) { list.value = [] }
}

function go(it) {
  const p = it.path ? (it.path.url || it.path.path || '') : ''
  if (p && p.startsWith('/pages')) uni.navigateTo({ url: p })
  else uni.showToast({ title: '「' + (it.name || '菜单') + '」暂未配置路径', icon: 'none' })
}

onLoad((options) => {
  curLocation = options?.location || ''
  load()
})
</script>

<style scoped>
.more-page { min-height: 100vh; background: #F4F6FB; }
.search-bar { padding: 12px 16px; background: #fff; }
.search-wrap { display: flex; align-items: center; background: #EDF0F8; border-radius:24px; padding: 0 14px; height: 38px; }
.search-icon { font-size: 14px; margin-right: 8px; }
.search-input { flex: 1; font-size: 14px; height: 38px; }
.clear-btn { width: 20px; height: 20px; border-radius:50%; background: #c0cedc; color: #fff; font-size: 11px; display: flex; align-items: center; justify-content: center; }
.more-grid { display: flex; flex-wrap: wrap; gap: 10px; padding: 16px; }
.more-item { width: calc(25% - 8px); display: flex; flex-direction: column; align-items: center; gap: 6px; background: #fff; border-radius:122px; padding: 16px 4px; box-sizing: border-box; box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06); transition: transform 0.2s ease; }
.more-item:active { background: #EDF0F8; transform: scale(0.96); }
.more-icon { width: 46px; height: 46px; border-radius:124px; display: flex; align-items: center; justify-content: center; font-size: 22px; color: #fff; }
.more-name { font-size: 12px; color: #1a2332; }
.more-empty { width: 100%; text-align: center; color: #b0c0cc; font-size: 13px; padding: 60px 0; }
</style>
