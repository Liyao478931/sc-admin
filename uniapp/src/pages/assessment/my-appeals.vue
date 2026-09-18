<template>
  <view class="ap-page">
    <!-- 状态筛选 -->
    <view class="ap-tabs">
      <text v-for="t in statusTabs" :key="t.value" class="ap-tab" :class="{ active: statusFilter === t.value }" @click="switchStatus(t.value)">{{ t.label }}</text>
    </view>

    <view v-if="!list.length" class="ap-empty"><u-empty text="暂无申诉记录" mode="list" /></view>
    <view v-else class="ap-list">
      <view v-for="a in list" :key="a.id" class="ap-card">
        <view class="ap-top">
          <text class="ap-name"><MIcon name="scale" :size="14" color="#8a9aa8" /><text style="margin-left:4px">{{ a.indicator_name }}</text></text>
          <text class="ap-status" :class="'s' + a.status">{{ a.status_text }}</text>
        </view>
        <text class="ap-reason">申诉理由：{{ a.appeal_reason }}</text>
        <view v-if="a.handler_reply" class="ap-reply">处理意见：{{ a.handler_reply }}</view>
        <view class="ap-meta">
          <text>提交：{{ a.created_at }}</text>
          <text v-if="a.handled_at">处理：{{ a.handled_at }}</text>
        </view>
      </view>
      <view class="ap-total">共 {{ list.length }} 条</view>
    </view>
  </view>
</template>

<script setup>
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { getMyAppeals } from '@/api/assessment.js'

const list = ref([])
const statusFilter = ref('')
const statusTabs = [{ label: '全部', value: '' }, { label: '待处理', value: '0' }, { label: '已通过', value: '1' }, { label: '已驳回', value: '2' }]

onLoad(() => load())

async function load () {
  const params = {}
  if (statusFilter.value !== '') params.status = parseInt(statusFilter.value)
  try {
    const r = await getMyAppeals(params)
    if (r.code === 0) list.value = r.data.list || []
  } catch (e) {}
}

function switchStatus (v) { statusFilter.value = v; load() }
</script>

<style scoped>
.ap-page { min-height: 100vh; background: #f5f6fa; padding: 20rpx 24rpx 60rpx; }
.ap-tabs { display: flex; gap: 12rpx; margin-bottom: 20rpx; flex-wrap: wrap; }
.ap-tab { font-size: 24rpx; color: #4e5a6b; padding: 10rpx 28rpx; border-radius:28rpx; background: #fff; }
.ap-tab.active { background: #1e6fff; color: #fff; }
.ap-empty { padding: 80rpx 0; }
.ap-card { background: #fff; border-radius:20rpx; padding: 24rpx; margin-bottom: 20rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.ap-top { display: flex; justify-content: space-between; align-items: center; }
.ap-name { font-size: 28rpx; font-weight: 600; color: #1d2129; }
.ap-status { font-size: 22rpx; padding: 4rpx 18rpx; border-radius:20rpx; }
.ap-status.s0 { background: #fdf6ec; color: #ffb020; }
.ap-status.s1 { background: #eaf7ec; color: #00b42a; }
.ap-status.s2 { background: #fef0f0; color: #f53f3f; }
.ap-reason { display: block; font-size: 24rpx; color: #4e5a6b; margin-top: 14rpx; line-height: 1.6; }
.ap-reply { display: block; font-size: 23rpx; color: #1e6fff; background: #f0f7ff; border-radius:10rpx; padding: 12rpx; margin-top: 12rpx; line-height: 1.6; }
.ap-meta { display: flex; gap: 20rpx; flex-wrap: wrap; font-size: 20rpx; color: #b0c0cc; margin-top: 12rpx; }
.ap-total { text-align: center; font-size: 22rpx; color: #8a9aa8; padding: 10rpx 0; }
</style>
