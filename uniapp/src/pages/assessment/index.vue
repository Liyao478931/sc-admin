<template>
  <view class="asm-page">
    <!-- 顶部 -->
    <view class="asm-head">
      <text class="asm-title">考核管理</text>
      <text class="asm-sub">随时随地对员工进行考核管理</text>
    </view>

    <!-- 快捷入口 -->
    <view class="asm-grid">
      <view class="asm-card" @click="goQuick">
        <view class="asm-card-icon quick"><MIcon name="zap" :size="26" color="#ffffff" /></view>
        <text class="asm-card-name">快速考核</text>
        <text class="asm-card-desc">现场巡查即时扣分</text>
      </view>
      <view class="asm-card" @click="goTeam">
        <view class="asm-card-icon team"><MIcon name="users" :size="26" color="#ffffff" /></view>
        <text class="asm-card-name">团队看板</text>
        <text class="asm-card-desc">团队考核总览排名</text>
      </view>
      <view class="asm-card" @click="goTodo">
        <view class="asm-card-icon todo"><MIcon name="clock" :size="26" color="#ffffff" /></view>
        <text class="asm-card-name">待办审批</text>
        <text class="asm-card-desc">待确认/待申诉</text>
      </view>
      <view class="asm-card" @click="goMy">
        <view class="asm-card-icon my"><MIcon name="clipboard" :size="26" color="#ffffff" /></view>
        <text class="asm-card-name">我的考核</text>
        <text class="asm-card-desc">查看本人考核情况</text>
      </view>
    </view>

    <!-- 待办提醒 -->
    <view class="asm-section" @click="goTodo">
      <view class="asm-section-title">
        <view style="display:flex;align-items:center"><MIcon name="clock" :size="15" color="#1d2129" /><text style="margin-left:4px">待办提醒</text></view>
        <text v-if="todoTotal > 0" class="asm-badge">{{ todoTotal }} 项</text>
      </view>
      <view v-if="todoCount.confirm > 0" class="asm-todo-row">
        <text class="asm-todo-dot confirm"></text>
        <text class="asm-todo-text">{{ todoCount.confirm }} 条扣分待确认</text>
      </view>
      <view v-if="todoCount.appeal > 0" class="asm-todo-row">
        <text class="asm-todo-dot appeal"></text>
        <text class="asm-todo-text">{{ todoCount.appeal }} 条申诉待处理</text>
      </view>
      <view v-if="todoTotal === 0" class="asm-todo-empty">
        <MIcon name="sparkles" :size="16" color="#f59e0b" /><text style="margin-left:4px">暂无待办，全部已处理</text>
      </view>
    </view>

    <!-- 我的考核概览 -->
    <view class="asm-section" v-if="myOverview && myOverview.exists">
      <view class="asm-section-title"><MIcon name="clipboard" :size="15" color="#1d2129" /><text style="margin-left:4px">我的考核（{{ myOverview.period }}）</text></view>
      <view class="asm-my-stats">
        <view class="asm-my-item"><text class="asm-my-num">{{ myOverview.total_score || '—' }}</text><text class="asm-my-label">本月得分</text></view>
        <view class="asm-my-item"><text class="asm-my-num">{{ myOverview.grade || '—' }}</text><text class="asm-my-label">等级</text></view>
        <view class="asm-my-item"><text class="asm-my-num">{{ myOverview.deduction_count || 0 }}</text><text class="asm-my-label">扣分项</text></view>
        <view class="asm-my-item"><text class="asm-my-num warn">{{ myOverview.pending_count || 0 }}</text><text class="asm-my-label">待确认</text></view>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { PAGE_PATHS } from '@/constants/pages'
import { getTodoList, getMyAssessmentOverview } from '@/api/assessment.js'

const todoCount = ref({ confirm: 0, appeal: 0 })
const todoTotal = ref(0)
const myOverview = ref(null)

onLoad(() => {
  loadTodo()
  loadMyOverview()
})

async function loadTodo () {
  try {
    const r = await getTodoList({})
    if (r.code === 0 && r.data) {
      todoCount.value = r.data.todo_count || { confirm: 0, appeal: 0 }
      todoTotal.value = (todoCount.value.confirm || 0) + (todoCount.value.appeal || 0)
    }
  } catch (e) {}
}

async function loadMyOverview () {
  try {
    const now = new Date()
    const r = await getMyAssessmentOverview({ year: now.getFullYear(), month: now.getMonth() + 1 })
    if (r.code === 0 && r.data) myOverview.value = r.data
  } catch (e) {}
}

function goQuick () { uni.navigateTo({ url: PAGE_PATHS.ASSESSMENT_QUICK }) }
function goTeam () { uni.navigateTo({ url: PAGE_PATHS.ASSESSMENT_TEAM }) }
function goTodo () { uni.navigateTo({ url: PAGE_PATHS.ASSESSMENT_TODO }) }
function goMy () { uni.navigateTo({ url: '/pages/assessment/employee-detail?employee_id=0&mine=1' }) }
</script>

<style scoped>
.asm-page { min-height: 100vh; background: #f5f6fa; padding: 20rpx 24rpx 40rpx; }
.asm-head { padding: 24rpx 8rpx 20rpx; }
.asm-title { font-size: 40rpx; font-weight: 700; color: #1d2129; }
.asm-sub { display: block; font-size: 24rpx; color: #8a9aa8; margin-top: 8rpx; }
.asm-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20rpx; margin-top: 8rpx; }
.asm-card { background: #fff; border-radius:20rpx; padding: 28rpx 24rpx; box-shadow: 0 4rpx 16rpx rgba(0,0,0,.04); }
.asm-card-icon { width: 76rpx; height: 76rpx; border-radius:18rpx; display: flex; align-items: center; justify-content: center; font-size: 40rpx; margin-bottom: 16rpx; }
.asm-card-icon.quick { background: #e8f3ff; }
.asm-card-icon.team { background: #eaf7ec; }
.asm-card-icon.todo { background: #fdf6ec; }
.asm-card-icon.my { background: #f0ecfb; }
.asm-card-name { font-size: 30rpx; font-weight: 600; color: #1d2129; }
.asm-card-desc { display: block; font-size: 22rpx; color: #8a9aa8; margin-top: 6rpx; }
.asm-section { background: #fff; border-radius:20rpx; padding: 24rpx; margin-top: 24rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.asm-section-title { display: flex; justify-content: space-between; align-items: center; font-size: 28rpx; font-weight: 600; color: #1d2129; margin-bottom: 16rpx; }
.asm-badge { background: #ffb020; color: #fff; font-size: 22rpx; padding: 4rpx 16rpx; border-radius:20rpx; }
.asm-todo-row { display: flex; align-items: center; padding: 14rpx 0; }
.asm-todo-dot { width: 14rpx; height: 14rpx; border-radius:50%; margin-right: 16rpx; }
.asm-todo-dot.confirm { background: #ffb020; }
.asm-todo-dot.appeal { background: #f53f3f; }
.asm-todo-text { font-size: 26rpx; color: #4e5a6b; }
.asm-todo-empty { font-size: 24rpx; color: #8a9aa8; padding: 10rpx 0; }
.asm-my-stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12rpx; }
.asm-my-item { text-align: center; background: #f7f9fc; border-radius:16rpx; padding: 20rpx 8rpx; }
.asm-my-num { display: block; font-size: 36rpx; font-weight: 700; color: #1e6fff; }
.asm-my-num.warn { color: #f53f3f; }
.asm-my-label { display: block; font-size: 22rpx; color: #8a9aa8; margin-top: 6rpx; }
</style>
