<template>
  <view class="td-page">
    <!-- 月份筛选 -->
    <view class="td-head">
      <picker mode="date" fields="month" :value="month" @change="onMonthChange">
        <view class="td-month-picker">
          <text class="td-month-text">{{ monthLabel }}</text>
          <u-icon name="arrow-down" color="#8a9aa8" size="14" />
        </view>
      </picker>
    </view>

    <!-- 统计卡片 -->
    <view class="td-stats">
      <view class="td-stat"><text class="td-stat-num">{{ data.total_employees || 0 }}</text><text class="td-stat-label">总人数</text></view>
      <view class="td-stat"><text class="td-stat-num">{{ data.avg_score || 0 }}</text><text class="td-stat-label">平均分</text></view>
      <view class="td-stat"><text class="td-stat-num">{{ data.max_deduction_count || 0 }}</text><text class="td-stat-label">扣分最多</text><text class="td-stat-sub">{{ data.max_deduction_employee || '—' }}</text></view>
      <view class="td-stat"><text class="td-stat-num warn">{{ data.pending_count || 0 }}</text><text class="td-stat-label">待确认</text></view>
    </view>

    <!-- 员工排名 -->
    <view class="td-section">
      <view class="td-section-title"><MIcon name="users" :size="15" color="#1d2129" /><text style="margin-left:4px">员工排名（按得分）</text></view>
      <view v-if="loading" class="td-status"><text>加载中...</text></view>
      <u-empty v-else-if="!data.ranking || !data.ranking.length" text="暂无考核数据" mode="list" />
      <view v-else>
        <view v-for="(r, i) in data.ranking" :key="r.employee_id" class="td-rank-row" @click="goEmployee(r.employee_id)">
          <text class="td-rank-no" :class="'rank-' + (i + 1)">{{ i < 3 ? ['01','02','03'][i] : i + 1 }}</text>
          <view class="td-rank-info">
            <text class="td-rank-name">{{ r.employee_name }}</text>
            <text class="td-rank-meta">{{ r.score }} 分 · {{ r.grade || '—' }} · 扣 {{ r.deduction_count }} 次</text>
          </view>
          <text class="td-rank-score">{{ r.score }}</text>
        </view>
      </view>
    </view>

    <!-- 高频扣分 -->
    <view class="td-section">
      <view class="td-section-title"><MIcon name="chart" :size="15" color="#1d2129" /><text style="margin-left:4px">高频扣分项 TOP{{ data.top_deductions ? data.top_deductions.length : 0 }}</text></view>
      <u-empty v-if="!data.top_deductions || !data.top_deductions.length" text="暂无扣分数据" mode="list" />
      <view v-else>
        <view v-for="(t, i) in data.top_deductions" :key="i" class="td-top-row">
          <view class="td-top-info"><text class="td-top-name">{{ t.indicator_name }}</text><text class="td-top-count">{{ t.count }} 次</text></view>
          <view class="td-top-bar"><view class="td-top-bar-inner" :style="{ width: (t.count / maxTop * 100) + '%' }"></view></view>
        </view>
      </view>
    </view>

    <!-- 需关注员工 -->
    <view class="td-section" v-if="data.warnings && data.warnings.length">
      <view class="td-section-title"><MIcon name="alert" :size="15" color="#e74c5e" /><text style="margin-left:4px">需关注员工（{{ data.warnings.length }} 人）</text></view>
      <view v-for="(w, i) in data.warnings" :key="i" class="td-warn-row" @click="goEmployee(w.employee_id)">
        <text class="td-warn-name">{{ w.employee_name }}</text>
        <text class="td-warn-reason">{{ w.reason }}</text>
        <text class="td-warn-view">查看 ›</text>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { PAGE_PATHS } from '@/constants/pages'
import { getTeamOverview } from '@/api/assessment.js'

const now = new Date()
const month = ref(`${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`)
const monthLabel = computed(() => {
  const [y, m] = month.value.split('-')
  return `${y}年${parseInt(m)}月`
})
const data = ref({})
const loading = ref(false)
const maxTop = computed(() => {
  const list = data.value.top_deductions || []
  return list.length ? Math.max(...list.map(t => t.count), 1) : 1
})

onLoad(() => load())

async function load () {
  loading.value = true
  try {
    const [y, m] = month.value.split('-')
    const r = await getTeamOverview({ year: parseInt(y), month: parseInt(m) })
    if (r.code === 0) data.value = r.data || {}
  } catch (e) {} finally { loading.value = false }
}

function onMonthChange (e) {
  month.value = e.detail.value
  load()
}

function goEmployee (id) {
  uni.navigateTo({ url: `${PAGE_PATHS.ASSESSMENT_EMPLOYEE}?employee_id=${id}` })
}
</script>

<style scoped>
.td-page { min-height: 100vh; background: #f5f6fa; padding: 20rpx 24rpx 60rpx; }
.td-head { display: flex; justify-content: flex-end; margin-bottom: 20rpx; }
.td-month-picker { background: #fff; border-radius:32rpx; padding: 12rpx 28rpx; display: flex; align-items: center; gap: 8rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.td-month-text { font-size: 26rpx; color: #1d2129; }
.td-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16rpx; }
.td-stat { background: #fff; border-radius:20rpx; padding: 24rpx 12rpx; text-align: center;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.td-stat-num { display: block; font-size: 36rpx; font-weight: 700; color: #1e6fff; }
.td-stat-num.warn { color: #f53f3f; }
.td-stat-label { display: block; font-size: 22rpx; color: #8a9aa8; margin-top: 6rpx; }
.td-stat-sub { display: block; font-size: 20rpx; color: #b0c0cc; margin-top: 4rpx; overflow: hidden; white-space: nowrap; }
.td-section { background: #fff; border-radius:20rpx; padding: 24rpx; margin-top: 20rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.td-section-title { font-size: 28rpx; font-weight: 600; color: #1d2129; margin-bottom: 16rpx; }
.td-rank-row { display: flex; align-items: center; padding: 18rpx 8rpx; border-bottom: 1rpx solid #EDF0F8; }
.td-rank-no { width: 60rpx; font-size: 28rpx; text-align: center; }
.td-rank-info { flex: 1; }
.td-rank-name { font-size: 28rpx; color: #1d2129; font-weight: 500; }
.td-rank-meta { display: block; font-size: 22rpx; color: #8a9aa8; margin-top: 4rpx; }
.td-rank-score { font-size: 30rpx; font-weight: 700; color: #1e6fff; }
.td-status { text-align: center; color: #8a9aa8; padding: 40rpx 0; font-size: 24rpx; }
.td-top-row { margin-bottom: 20rpx; }
.td-top-info { display: flex; justify-content: space-between; margin-bottom: 8rpx; }
.td-top-name { font-size: 24rpx; color: #4e5a6b; }
.td-top-count { font-size: 22rpx; color: #8a9aa8; }
.td-top-bar { height: 16rpx; background: #EDF0F8; border-radius:8rpx; overflow: hidden; }
.td-top-bar-inner { height: 100%; background: #1e6fff; border-radius:8rpx; }
.td-warn-row { display: flex; align-items: center; gap: 12rpx; padding: 16rpx 0; border-bottom: 1rpx solid #EDF0F8; }
.td-warn-name { font-size: 26rpx; font-weight: 600; color: #f53f3f; }
.td-warn-reason { flex: 1; font-size: 22rpx; color: #4e5a6b; }
.td-warn-view { font-size: 22rpx; color: #1e6fff; }
</style>
