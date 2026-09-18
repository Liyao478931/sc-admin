<template>
  <view class="ed-page">
    <!-- 头部 + 快速考核 -->
    <view class="ed-head">
      <view class="ed-head-info">
        <text class="ed-name">{{ data.employee_name || '员工' }}</text>
        <text class="ed-dept">{{ data.department_name || '' }} · {{ data.position || '' }}</text>
      </view>
      <view v-if="!isMine" class="ed-quick-btn" @click="goQuick"><MIcon name="zap" :size="14" color="#ffffff" /><text style="margin-left:4px">快速考核</text></view>
    </view>

    <!-- 统计卡片 -->
    <view class="ed-stats">
      <view class="ed-stat"><text class="ed-stat-num">{{ data.total_score || '—' }}</text><text class="ed-stat-label">本月得分</text></view>
      <view class="ed-stat"><text class="ed-stat-num">{{ data.grade || '—' }}</text><text class="ed-stat-label">等级</text></view>
      <view class="ed-stat"><text class="ed-stat-num">{{ data.deductions ? data.deductions.length : 0 }}</text><text class="ed-stat-label">扣分次数</text></view>
      <view class="ed-stat"><text class="ed-stat-num warn">{{ pendingCount }}</text><text class="ed-stat-label">待确认</text></view>
    </view>

    <!-- 近6月趋势 -->
    <view class="ed-section">
      <view class="ed-section-title"><MIcon name="trend" :size="15" color="#1d2129" /><text style="margin-left:4px">近 6 个月得分</text></view>
      <view v-if="trendMax" class="ed-trend">
        <view v-for="t in data.trend" :key="t.period" class="ed-trend-col">
          <view class="ed-trend-bar-wrap">
            <view class="ed-trend-bar" :style="{ height: (t.score / trendMax * 120) + 'rpx' }"></view>
          </view>
          <text class="ed-trend-label">{{ String(t.period).slice(5) }}月</text>
          <text class="ed-trend-score">{{ t.score || '—' }}</text>
        </view>
      </view>
    </view>

    <!-- 扣分明细 -->
    <view class="ed-section">
      <view class="ed-section-title"><MIcon name="file" :size="15" color="#1d2129" /><text style="margin-left:4px">扣分明细（{{ data.deductions ? data.deductions.length : 0 }} 条）</text></view>
      <u-empty v-if="!data.deductions || !data.deductions.length" text="本月暂无扣分" mode="list" />
      <view v-else>
        <view v-for="d in data.deductions" :key="d.id" class="ed-ded">
          <view class="ed-ded-top">
            <text class="ed-ded-name"><MIcon name="file" :size="14" color="#8a9aa8" /><text style="margin-left:4px">{{ d.indicator_name }}</text></text>
            <text class="ed-ded-score">-{{ d.deduct_score }} 分</text>
          </view>
          <text class="ed-ded-reason">{{ d.reason }}</text>
          <view class="ed-ded-meta">
            <text class="ed-ded-tag">{{ d.status_text }}</text>
            <text v-if="d.category" class="ed-ded-cat">{{ d.category }}</text>
            <text class="ed-ded-time">{{ d.data_source_detail || '' }}</text>
          </view>
        </view>
      </view>
    </view>

    <!-- 扣分分析 -->
    <view class="ed-section" v-if="data.analysis && data.analysis.length">
      <view class="ed-section-title"><MIcon name="chart" :size="15" color="#1d2129" /><text style="margin-left:4px">扣分分析</text></view>
      <view v-for="(a, i) in data.analysis" :key="i" class="ed-ana-row">
        <text class="ed-ana-cat">{{ a.category }}</text>
        <view class="ed-ana-bar"><view class="ed-ana-bar-inner" :style="{ width: a.percent + '%' }"></view></view>
        <text class="ed-ana-percent">{{ a.percent }}%</text>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { PAGE_PATHS } from '@/constants/pages'
import { getEmployeeDetail } from '@/api/assessment.js'

const data = ref({})
const empId = ref(0)
const isMine = ref(false)
const trendMax = computed(() => {
  const list = data.value.trend || []
  return list.length ? Math.max(...list.map(t => t.score), 60) : 60
})
const pendingCount = computed(() => (data.value.deductions || []).filter(d => d.status === 0).length)

onLoad(async (options) => {
  if (options && options.employee_id) empId.value = parseInt(options.employee_id)
  isMine.value = !!(options && options.mine)
  await load()
})

async function load () {
  try {
    const now = new Date()
    const r = await getEmployeeDetail(empId.value, { year: now.getFullYear(), month: now.getMonth() + 1 })
    if (r.code === 0) data.value = r.data || {}
    else uni.showToast({ title: r.msg || '加载失败', icon: 'none' })
  } catch (e) {}
}

function goQuick () {
  uni.navigateTo({ url: `${PAGE_PATHS.ASSESSMENT_QUICK}?employee_id=${empId.value}` })
}
</script>

<style scoped>
.ed-page { min-height: 100vh; background: #f5f6fa; padding: 20rpx 24rpx 60rpx; }
.ed-head { display: flex; justify-content: space-between; align-items: center; padding: 16rpx 8rpx 24rpx; }
.ed-name { font-size: 40rpx; font-weight: 700; color: #1d2129; }
.ed-dept { display: block; font-size: 24rpx; color: #8a9aa8; margin-top: 8rpx; }
.ed-quick-btn { background: #1e6fff; color: #fff; border-radius:32rpx; padding: 14rpx 28rpx; font-size: 26rpx; }
.ed-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16rpx; }
.ed-stat { background: #fff; border-radius:20rpx; padding: 24rpx 12rpx; text-align: center;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.ed-stat-num { display: block; font-size: 36rpx; font-weight: 700; color: #1e6fff; }
.ed-stat-num.warn { color: #f53f3f; }
.ed-stat-label { display: block; font-size: 22rpx; color: #8a9aa8; margin-top: 6rpx; }
.ed-section { background: #fff; border-radius:20rpx; padding: 24rpx; margin-top: 20rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.ed-section-title { font-size: 28rpx; font-weight: 600; color: #1d2129; margin-bottom: 16rpx; }
.ed-trend { display: flex; justify-content: space-around; align-items: flex-end; padding: 10rpx 0; }
.ed-trend-col { display: flex; flex-direction: column; align-items: center; }
.ed-trend-bar-wrap { height: 140rpx; display: flex; align-items: flex-end; }
.ed-trend-bar { width: 36rpx; background: #1e6fff; border-radius:8rpx 8rpx 0 0; min-height: 4rpx; }
.ed-trend-label { font-size: 20rpx; color: #8a9aa8; margin-top: 8rpx; }
.ed-trend-score { font-size: 20rpx; color: #1d2129; font-weight: 600; margin-top: 4rpx; }
.ed-ded { padding: 20rpx 0; border-bottom: 1rpx solid #EDF0F8; }
.ed-ded-top { display: flex; justify-content: space-between; align-items: center; }
.ed-ded-name { font-size: 28rpx; color: #1d2129; font-weight: 500; }
.ed-ded-score { font-size: 30rpx; font-weight: 700; color: #f53f3f; }
.ed-ded-reason { display: block; font-size: 24rpx; color: #4e5a6b; margin-top: 8rpx; }
.ed-ded-meta { display: flex; align-items: center; gap: 12rpx; margin-top: 8rpx; }
.ed-ded-tag { font-size: 20rpx; color: #1e6fff; background: #e8f3ff; padding: 2rpx 14rpx; border-radius:16rpx; }
.ed-ded-cat { font-size: 20rpx; color: #8a9aa8; }
.ed-ded-time { font-size: 20rpx; color: #b0c0cc; }
.ed-status { text-align: center; color: #8a9aa8; padding: 40rpx 0; font-size: 24rpx; }
.ed-ana-row { display: flex; align-items: center; gap: 16rpx; padding: 12rpx 0; }
.ed-ana-cat { width: 160rpx; font-size: 24rpx; color: #4e5a6b; }
.ed-ana-bar { flex: 1; height: 16rpx; background: #EDF0F8; border-radius:8rpx; overflow: hidden; }
.ed-ana-bar-inner { height: 100%; background: #ffb020; border-radius:8rpx; }
.ed-ana-percent { width: 80rpx; text-align: right; font-size: 24rpx; color: #4e5a6b; }
</style>
