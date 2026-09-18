<template>
  <view class="ma-page">
    <!-- 月份切换 -->
    <picker mode="date" fields="month" :value="month" @change="onMonthChange">
      <view class="ma-month"><text>{{ monthLabel }}</text><u-icon name="arrow-down" color="#8a9aa8" size="14" /></view>
    </picker>

    <view v-if="!overview" class="ma-empty"><u-empty text="本月暂无考核数据" mode="list" /></view>
    <template v-else>
      <!-- 统计卡片 -->
      <view class="ma-stats">
        <view class="ma-stat"><text class="ma-stat-num">{{ overview.total_score || '—' }}</text><text class="ma-stat-label">本月得分</text><text v-if="overview.compare_last_month" class="ma-stat-sub" :class="overview.compare_last_month >= 0 ? 'up' : 'down'">{{ overview.compare_last_month >= 0 ? '▲' : '▼' }} {{ Math.abs(overview.compare_last_month) }}</text></view>
        <view class="ma-stat"><text class="ma-stat-num">{{ overview.grade || '—' }}</text><text class="ma-stat-label">{{ overview.grade_text || '等级' }}</text></view>
        <view class="ma-stat"><text class="ma-stat-num">{{ overview.deduction_count || 0 }}</text><text class="ma-stat-label">扣分项数</text></view>
        <view class="ma-stat"><text class="ma-stat-num warn">{{ overview.pending_count || 0 }}</text><text class="ma-stat-label">待确认</text></view>
      </view>

      <!-- 近6月趋势 -->
      <view class="ma-section" v-if="trendMax > 0">
        <view class="ma-section-title"><MIcon name="trend" :size="15" color="#1d2129" /><text style="margin-left:4px">近 6 个月得分趋势</text></view>
        <view class="ma-trend">
          <view v-for="(s, i) in overview.trend.scores" :key="i" class="ma-trend-col">
            <view class="ma-trend-bar-wrap"><view class="ma-trend-bar" :style="{ height: (s / trendMax * 110) + 'rpx' }"></view></view>
            <text class="ma-trend-label">{{ overview.trend.months[i] }}</text>
            <text class="ma-trend-score">{{ s || '—' }}</text>
          </view>
        </view>
      </view>

      <!-- 扣分明细 -->
      <view class="ma-section">
        <view class="ma-section-title">
          <MIcon name="file" :size="15" color="#1d2129" /><text style="margin-left:4px">扣分明细</text>
          <view class="ma-tabs">
            <text v-for="t in statusTabs" :key="t.value" class="ma-tab" :class="{ active: statusFilter === t.value }" @click="switchStatus(t.value)">{{ t.label }}</text>
          </view>
        </view>
        <view v-if="!deductions.length" class="ma-empty-tip"><text>暂无扣分记录</text></view>
        <view v-else>
          <view v-for="d in deductions" :key="d.id" class="ma-ded" @click="goDetail(d.id)">
            <view class="ma-ded-top">
              <text class="ma-ded-name"><MIcon name="file" :size="14" color="#8a9aa8" /><text style="margin-left:4px">{{ d.indicator_name }}</text></text>
              <text class="ma-ded-score">-{{ d.deduct_score }} 分</text>
            </view>
            <text class="ma-ded-reason">{{ d.reason }}</text>
            <view class="ma-ded-meta">
              <text class="ma-ded-status" :class="'s' + d.status">{{ d.status_text }}</text>
              <text v-if="d.source_detail" class="ma-ded-source">{{ d.source_detail }}</text>
              <text v-if="d.can_appeal" class="ma-ded-act" @click.stop="goAppeal(d.id)">申诉</text>
            </view>
          </view>
        </view>
      </view>
    </template>
  </view>
</template>

<script setup>
import { ref, computed } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { getMyAssessmentOverview, getMyAssessmentDeductions } from '@/api/assessment.js'

const now = new Date()
const month = ref(`${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`)
const monthLabel = computed(() => { const [y, m] = month.value.split('-'); return `${y}年${parseInt(m)}月` })
const overview = ref(null)
const deductions = ref([])
const statusFilter = ref('')
const statusTabs = [{ label: '全部', value: '' }, { label: '待确认', value: '0' }, { label: '已确认', value: '1' }]
const trendMax = computed(() => {
  const list = (overview.value && overview.value.trend && overview.value.trend.scores) || []
  return list.length ? Math.max(...list.map(s => s), 60) : 60
})

onLoad(() => load())

async function load () {
  const [y, m] = month.value.split('-')
  const params = { year: parseInt(y), month: parseInt(m) }
  try {
    const r = await getMyAssessmentOverview(params)
    if (r.code === 0) overview.value = r.data
  } catch (e) {}
  await loadDeductions()
}

async function loadDeductions () {
  const [y, m] = month.value.split('-')
  const params = { year: parseInt(y), month: parseInt(m) }
  if (statusFilter.value !== '') params.status = parseInt(statusFilter.value)
  try {
    const r = await getMyAssessmentDeductions(params)
    if (r.code === 0) deductions.value = r.data.list || []
  } catch (e) {}
}

function onMonthChange (e) { month.value = e.detail.value; load() }
function switchStatus (v) { statusFilter.value = v; loadDeductions() }
function goDetail (id) { uni.navigateTo({ url: `/pages/assessment/deduction-detail?id=${id}` }) }
function goAppeal (id) { uni.navigateTo({ url: `/pages/assessment/appeal-submit?deduction_id=${id}` }) }
</script>

<style scoped>
.ma-page { min-height: 100vh; background: #f5f6fa; padding: 20rpx 24rpx 60rpx; }
.ma-month { display: flex; align-items: center; gap: 8rpx; background: #fff; border-radius:32rpx; padding: 12rpx 28rpx; font-size: 26rpx; color: #1d2129; margin-bottom: 20rpx; width: fit-content;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.ma-empty { padding: 80rpx 0; }
.ma-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16rpx; }
.ma-stat { background: #fff; border-radius:20rpx; padding: 24rpx 10rpx; text-align: center;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.ma-stat-num { display: block; font-size: 36rpx; font-weight: 700; color: #1e6fff; }
.ma-stat-num.warn { color: #f53f3f; }
.ma-stat-label { display: block; font-size: 22rpx; color: #8a9aa8; margin-top: 6rpx; }
.ma-stat-sub { display: block; font-size: 20rpx; margin-top: 4rpx; }
.ma-stat-sub.up { color: #00b42a; }
.ma-stat-sub.down { color: #f53f3f; }
.ma-section { background: #fff; border-radius:20rpx; padding: 24rpx; margin-top: 20rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.ma-section-title { display: flex; justify-content: space-between; align-items: center; font-size: 28rpx; font-weight: 600; color: #1d2129; margin-bottom: 16rpx; }
.ma-tabs { display: flex; gap: 8rpx; }
.ma-tab { font-size: 22rpx; color: #8a9aa8; padding: 6rpx 20rpx; border-radius:24rpx; background: #f5f6fa; }
.ma-tab.active { background: #1e6fff; color: #fff; }
.ma-trend { display: flex; justify-content: space-around; align-items: flex-end; padding: 10rpx 0; }
.ma-trend-col { display: flex; flex-direction: column; align-items: center; }
.ma-trend-bar-wrap { height: 130rpx; display: flex; align-items: flex-end; }
.ma-trend-bar { width: 36rpx; background: #1e6fff; border-radius:8rpx 8rpx 0 0; min-height: 4rpx; }
.ma-trend-label { font-size: 20rpx; color: #8a9aa8; margin-top: 8rpx; }
.ma-trend-score { font-size: 20rpx; color: #1d2129; font-weight: 600; margin-top: 4rpx; }
.ma-empty-tip { text-align: center; color: #8a9aa8; padding: 40rpx 0; font-size: 24rpx; }
.ma-ded { padding: 20rpx 0; border-bottom: 1rpx solid #EDF0F8; }
.ma-ded-top { display: flex; justify-content: space-between; align-items: center; }
.ma-ded-name { font-size: 28rpx; color: #1d2129; font-weight: 500; }
.ma-ded-score { font-size: 30rpx; font-weight: 700; color: #f53f3f; }
.ma-ded-reason { display: block; font-size: 24rpx; color: #4e5a6b; margin-top: 8rpx; }
.ma-ded-meta { display: flex; align-items: center; gap: 14rpx; margin-top: 8rpx; }
.ma-ded-status { font-size: 20rpx; padding: 2rpx 14rpx; border-radius:16rpx; }
.ma-ded-status.s0 { background: #fdf6ec; color: #ffb020; }
.ma-ded-status.s1 { background: #eaf7ec; color: #00b42a; }
.ma-ded-status.s2 { background: #e8f3ff; color: #1e6fff; }
.ma-ded-status.s3 { background: #fef0f0; color: #f53f3f; }
.ma-ded-source { font-size: 20rpx; color: #b0c0cc; flex: 1; }
.ma-ded-act { font-size: 22rpx; color: #1e6fff; }
</style>
