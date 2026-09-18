<template>
  <view class="tl-page">
    <!-- 统计卡 -->
    <view class="tl-stats">
      <view class="tl-stat" :class="{ active: tab === 'confirm' }" @click="switchTab('confirm')">
        <text class="tl-stat-num">{{ todoCount.confirm || 0 }}</text>
        <text class="tl-stat-label">待确认考核</text>
      </view>
      <view class="tl-stat" :class="{ active: tab === 'appeal' }" @click="switchTab('appeal')">
        <text class="tl-stat-num">{{ todoCount.appeal || 0 }}</text>
        <text class="tl-stat-label">待处理申诉</text>
      </view>
    </view>

    <!-- 待确认列表 -->
    <view v-if="tab === 'confirm'" class="tl-list">
      <view v-if="loading" class="tl-status"><text>加载中...</text></view>
      <u-empty v-else-if="!confirmList.length" text="暂无待确认扣分" mode="list" />
      <view v-else>
        <view v-for="c in confirmList" :key="c.deduction_id" class="tl-card">
          <view class="tl-card-top">
            <text class="tl-emp">{{ c.employee_name }}</text>
            <text class="tl-dept">{{ c.department_name }}</text>
            <text class="tl-ind">{{ c.indicator_name }}</text>
            <text class="tl-score">-{{ c.deduct_score }} 分</text>
          </view>
          <text class="tl-reason">{{ c.reason }}</text>
          <text class="tl-time">{{ c.created_at }}</text>
          <view class="tl-actions">
            <u-button size="small" text="驳回" shape="circle" plain @click="openReject(c)" />
            <u-button size="small" type="primary" text="确认" shape="circle" @click="doConfirm(c)" />
          </view>
        </view>
      </view>
    </view>

    <!-- 待处理申诉 -->
    <view v-else class="tl-list">
      <view v-if="loading" class="tl-status"><text>加载中...</text></view>
      <u-empty v-else-if="!appealList.length" text="暂无待处理申诉" mode="list" />
      <view v-else>
        <view v-for="a in appealList" :key="a.appeal_id" class="tl-card">
          <view class="tl-card-top">
            <text class="tl-emp">{{ a.employee_name }}</text>
            <text class="tl-dept">{{ a.department_name }}</text>
            <text class="tl-ind">{{ a.indicator_name }}</text>
          </view>
          <text class="tl-reason">申诉：{{ a.appeal_reason }}</text>
          <text class="tl-time">{{ a.created_at }}</text>
          <view class="tl-tip"><MIcon name="alert" :size="14" color="#e74c5e" /><text style="margin-left:4px">申诉处理请在 PC 端「申诉处理中心」进行</text></view>
        </view>
      </view>
    </view>

    <!-- 驳回弹窗 -->
    <u-popup :show="rejectVisible" mode="bottom" round="20" @close="rejectVisible = false">
      <view class="tl-sheet">
        <view class="tl-sheet-title"><text>驳回扣分</text><view class="tl-sheet-close" @click="rejectVisible = false"><text>×</text></view></view>
        <text class="tl-reject-info">{{ rejectForm.employee_name }} · {{ rejectForm.indicator_name }} -{{ rejectForm.deduct_score }}分</text>
        <u-textarea v-model="rejectForm.reason" placeholder="请填写驳回理由（必填）" maxlength="200" :count="true" />
        <view class="tl-sheet-submit">
          <u-button type="error" text="确认驳回" shape="circle" @click="doReject" />
        </view>
      </view>
    </u-popup>
  </view>
</template>

<script setup>
import { ref } from 'vue'
import { onLoad, onShow } from '@dcloudio/uni-app'
import { getTodoList, confirmDeduction } from '@/api/assessment.js'

const tab = ref('confirm')
const todoCount = ref({ confirm: 0, appeal: 0 })
const confirmList = ref([])
const appealList = ref([])
const loading = ref(false)
const rejectVisible = ref(false)
const rejectForm = ref({ deduction_id: 0, employee_name: '', indicator_name: '', deduct_score: 0, reason: '' })

onLoad(() => load())
onShow(() => load())

async function load () {
  loading.value = true
  try {
    const r = await getTodoList({ type: tab.value })
    if (r.code === 0 && r.data) {
      todoCount.value = r.data.todo_count || { confirm: 0, appeal: 0 }
      confirmList.value = r.data.confirm_list || []
      appealList.value = r.data.appeal_list || []
    }
  } catch (e) {} finally { loading.value = false }
}

function switchTab (t) {
  tab.value = t
  load()
}

function doConfirm (c) {
  uni.showModal({
    title: '确认扣分',
    content: `确认 ${c.employee_name} 的扣分（${c.indicator_name} -${c.deduct_score}分）生效？`,
    success: async (res) => {
      if (!res.confirm) return
      try {
        const r = await confirmDeduction({ deduction_id: c.deduction_id, action: 'confirm' })
        if (r.code === 0) { uni.showToast({ title: '已确认', icon: 'success' }); load() }
        else uni.showToast({ title: r.msg || '操作失败', icon: 'none' })
      } catch (e) { uni.showToast({ title: '操作失败', icon: 'none' }) }
    }
  })
}

function openReject (c) {
  rejectForm.value = { deduction_id: c.deduction_id, employee_name: c.employee_name, indicator_name: c.indicator_name, deduct_score: c.deduct_score, reason: '' }
  rejectVisible.value = true
}

async function doReject () {
  if (!rejectForm.value.reason.trim()) { uni.showToast({ title: '请填写驳回理由', icon: 'none' }); return }
  try {
    const r = await confirmDeduction({ deduction_id: rejectForm.value.deduction_id, action: 'reject', reject_reason: rejectForm.value.reason.trim() })
    if (r.code === 0) { uni.showToast({ title: '已驳回', icon: 'success' }); rejectVisible.value = false; load() }
    else uni.showToast({ title: r.msg || '操作失败', icon: 'none' })
  } catch (e) { uni.showToast({ title: '操作失败', icon: 'none' }) }
}
</script>

<style scoped>
.tl-page { min-height: 100vh; background: #f5f6fa; padding: 20rpx 24rpx 60rpx; }
.tl-stats { display: grid; grid-template-columns: 1fr 1fr; gap: 16rpx; }
.tl-stat { background: #fff; border-radius:20rpx; padding: 24rpx; text-align: center;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.tl-stat.active { background: #1e6fff; }
.tl-stat.active .tl-stat-num, .tl-stat.active .tl-stat-label { color: #fff; }
.tl-stat-num { display: block; font-size: 36rpx; font-weight: 700; color: #1e6fff; }
.tl-stat-label { display: block; font-size: 22rpx; color: #8a9aa8; margin-top: 6rpx; }
.tl-list { margin-top: 20rpx; }
.tl-card { background: #fff; border-radius:20rpx; padding: 24rpx; margin-bottom: 20rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.tl-card-top { display: flex; align-items: center; gap: 12rpx; flex-wrap: wrap; }
.tl-emp { font-size: 30rpx; font-weight: 700; color: #1d2129; }
.tl-dept { font-size: 22rpx; color: #8a9aa8; }
.tl-ind { font-size: 24rpx; color: #1e6fff; background: #e8f3ff; padding: 4rpx 16rpx; border-radius:20rpx; }
.tl-score { font-size: 28rpx; font-weight: 700; color: #f53f3f; margin-left: auto; }
.tl-reason { display: block; font-size: 26rpx; color: #4e5a6b; margin-top: 14rpx; }
.tl-time { display: block; font-size: 20rpx; color: #b0c0cc; margin-top: 8rpx; }
.tl-actions { display: flex; justify-content: flex-end; gap: 16rpx; margin-top: 16rpx; }
.tl-btn { padding: 12rpx 36rpx; border-radius:32rpx; font-size: 26rpx; }
.tl-btn.reject { background: #fff; color: #4e5a6b; border: 2rpx solid #d5dce4; }
.tl-btn.confirm { background: #1e6fff; color: #fff; }
.tl-tip { font-size: 22rpx; color: #ffb020; margin-top: 12rpx; }
.tl-status { text-align: center; color: #8a9aa8; padding: 60rpx 0; font-size: 24rpx; }
.tl-mask { position: fixed; inset: 0; background: rgba(0,0,0,.5); display: flex; align-items: flex-end; z-index: 10; }
.tl-sheet { padding: 30rpx 30rpx 60rpx; }
.tl-sheet-submit { margin-top: 24rpx; }
.tl-sheet-title { display: flex; justify-content: space-between; align-items: center; font-size: 30rpx; font-weight: 600; color: #1d2129; }
.tl-sheet-close { font-size: 36rpx; color: #8a9aa8; }
.tl-reject-info { display: block; font-size: 24rpx; color: #4e5a6b; margin: 20rpx 0; }
.tl-reject-input { width: 100%; min-height: 140rpx; background: #f7f9fc; border-radius:16rpx; padding: 20rpx; font-size: 26rpx; }
.tl-submit { margin-top: 24rpx; background: #f53f3f; color: #fff; text-align: center; padding: 22rpx; border-radius:44rpx; font-size: 28rpx; font-weight: 600; }
</style>
