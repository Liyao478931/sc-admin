<template>
  <view class="salary-page">
    <!-- 顶部栏 -->
    <view class="topbar">
      <view class="back" @click="goBack"><MIcon name="arrowRight" :size="20" color="#ffffff" style="transform: rotate(180deg)" /></view>
      <text class="topbar-title">我的工资条</text>
      <view class="topbar-right" />
    </view>

    <!-- 年度汇总卡 -->
    <view class="summary-card">
      <view class="summary-glow" />
      <view class="summary-head">
        <view class="summary-label"><MIcon name="wallet" :size="15" color="rgba(255,255,255,.85)" /><text style="margin-left:6px">年度实发合计</text></view>
        <view class="summary-count">{{ list.length }} 条</view>
      </view>
      <view class="summary-num">¥{{ netTotal.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) }}</view>
      <view class="summary-foot">
        <view class="sf-item">
          <text class="sf-label">累计月份</text>
          <text class="sf-val">{{ monthCount }} 个月</text>
        </view>
        <view class="sf-divider" />
        <view class="sf-item">
          <text class="sf-label">月均实发</text>
          <text class="sf-val">¥{{ avgNet.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) }}</text>
        </view>
      </view>
    </view>

    <!-- 列表 -->
    <view class="list-wrap">
      <view class="list-title"><MIcon name="clipboard" :size="16" color="#1d2129" /><text style="margin-left:6px">工资条记录</text></view>
      <view v-if="list.length === 0 && !loading" class="empty">
        <MIcon name="file" :size="40" color="#c0c8d4" />
        <text class="empty-text">暂无工资条数据</text>
      </view>
      <view v-for="s in list" :key="s.id" class="slip-item" @click="openDetail(s)">
        <view class="slip-month">
          <text class="sm-y">{{ monthYear(s.calc_month) }}</text>
          <text class="sm-no">#{{ s.slip_no }}</text>
        </view>
        <view class="slip-money">
          <view class="sm-line"><text class="sm-lab">应发</text><text class="sm-gross">¥{{ fmt(s.gross_salary) }}</text></view>
          <view class="sm-line"><text class="sm-lab">实发</text><text class="sm-net">¥{{ fmt(s.net_salary) }}</text></view>
        </view>
        <view class="slip-right">
          <view class="status-badge" :class="'st-' + s.status">{{ s.status_label }}</view>
          <MIcon name="chevronRight" :size="16" color="#b0c0cc" />
        </view>
      </view>
    </view>

    <!-- 详情弹层 -->
    <view v-if="showDetail" class="mask" @click="closeDetail" />
    <view class="detail-panel" :class="{ open: showDetail }">
      <view v-if="detail" class="detail-body">
        <view class="detail-head">
          <view>
            <view class="dh-month">{{ monthYear(detail.calc_month) }}</view>
            <view class="dh-sub">{{ detail.company_name }} · {{ detail.department_name || '' }} {{ detail.rank_name || '' }}</view>
          </view>
          <view class="status-badge" :class="'st-' + detail.status">{{ detail.status_label }}</view>
        </view>
        <view class="dh-net">
          <text class="dhn-label">实发工资</text>
          <text class="dhn-num">¥{{ fmt(detail.net_salary) }}</text>
        </view>
        <view class="detail-rows">
          <view class="d-row"><text class="dr-lab">基本工资</text><text class="dr-val">¥{{ fmt(detail.base_salary) }}</text></view>
          <view class="d-row" v-if="detail.piecework_wage"><text class="dr-lab">计件工资</text><text class="dr-val">¥{{ fmt(detail.piecework_wage) }}</text></view>
          <view class="d-row" v-for="(a, i) in allowances" :key="'a' + i"><text class="dr-lab">{{ a.name }}</text><text class="dr-val">¥{{ fmt(a.amount) }}</text></view>
          <view class="d-row total-in" v-if="detail.allowance_total"><text class="dr-lab">津贴合计</text><text class="dr-val">¥{{ fmt(detail.allowance_total) }}</text></view>
          <view class="d-row" v-for="(d, i) in deductions" :key="'d' + i"><text class="dr-lab">{{ d.name }}</text><text class="dr-val minus">-¥{{ fmt(d.amount) }}</text></view>
          <view class="d-row total-out" v-if="detail.deduction_total"><text class="dr-lab">扣款合计</text><text class="dr-val minus">-¥{{ fmt(detail.deduction_total) }}</text></view>
          <view class="d-row total"><text class="dr-lab">应发工资</text><text class="dr-val">¥{{ fmt(detail.gross_salary) }}</text></view>
          <view class="d-row net"><text class="dr-lab">实发工资</text><text class="dr-val">¥{{ fmt(detail.net_salary) }}</text></view>
        </view>
        <button v-if="detail.status === 2" class="sign-btn" @click="sign">确认签收</button>
        <view v-else-if="detail.status === 3" class="signed-tip"><MIcon name="check" :size="14" color="#059669" /><text style="margin-left:4px">已于 {{ detail.signed_at }} 签收</text></view>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed } from 'vue'
import { request } from '@/utils/request'

const list = ref([])
const loading = ref(false)
const detail = ref(null)
const showDetail = ref(false)

const netTotal = computed(() => list.value.reduce((s, x) => s + (parseFloat(x.net_salary) || 0), 0))
const monthCount = computed(() => list.value.length)
const avgNet = computed(() => (monthCount.value ? netTotal.value / monthCount.value : 0))

const allowances = computed(() => (Array.isArray(detail.value?.allowance_json) ? detail.value.allowance_json : []))
const deductions = computed(() => (Array.isArray(detail.value?.deduction_json) ? detail.value.deduction_json : []))

function fmt(v) {
  const n = parseFloat(v) || 0
  return n.toLocaleString('zh-CN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
}
function monthYear(m) {
  if (!m) return ''
  const p = String(m).split('-')
  return p.length > 1 ? p[0] + '年' + p[1] + '月' : m
}
function goBack() { uni.navigateBack() }

async function loadList() {
  loading.value = true
  try {
    const res = await request({ url: '/api/hr/salary/slip/mobile/list', method: 'GET', data: { page: 1, pageSize: 50 } })
    if (res.code === 0 && res.data && Array.isArray(res.data.list)) {
      list.value = res.data.list
    }
  } catch (e) {}
  loading.value = false
}

async function openDetail(s) {
  try {
    const res = await request({ url: '/api/hr/salary/slip/mobile/detail/' + s.id, method: 'GET' })
    if (res.code === 0 && res.data) {
      detail.value = res.data
      showDetail.value = true
    } else {
      uni.showToast({ title: res.msg || '加载失败', icon: 'none' })
    }
  } catch (e) {}
}

function closeDetail() { showDetail.value = false }

async function sign() {
  try {
    const res = await request({ url: '/api/hr/salary/slip/sign/' + detail.value.id, method: 'POST' })
    if (res.code === 0) {
      uni.showToast({ title: '签收成功', icon: 'success' })
      detail.value.status = 3
      detail.value.signed_at = new Date().toLocaleString('zh-CN')
      detail.value.status_label = '已签收'
      loadList()
    } else {
      uni.showToast({ title: res.msg || '签收失败', icon: 'none' })
    }
  } catch (e) {}
}

loadList()
</script>

<style scoped>
.salary-page { min-height: 100vh; background: #f5f7fb; }
.topbar { display: flex; align-items: center; justify-content: space-between; padding: 0 24rpx; height: 88rpx; background: linear-gradient(135deg, #4F46E5, #7c6ff0); }
.back { width: 56rpx; height: 56rpx; display: flex; align-items: center; justify-content: center; }
.topbar-title { font-size: 32rpx; font-weight: 600; color: #fff; }
.topbar-right { width: 56rpx; }

.summary-card { position: relative; margin: 24rpx; padding: 32rpx 32rpx 28rpx; border-radius: 24rpx; background: linear-gradient(135deg, #4F46E5 0%, #6d5ff0 60%, #8b7bff 100%); color: #fff; overflow: hidden; box-shadow: 0 12rpx 32rpx rgba(79, 70, 229, .35); }
.summary-glow { position: absolute; right: -60rpx; top: -60rpx; width: 240rpx; height: 240rpx; border-radius: 50%; background: rgba(255, 255, 255, .12); }
.summary-head { display: flex; align-items: center; justify-content: space-between; }
.summary-label { display: flex; align-items: center; font-size: 26rpx; color: rgba(255,255,255,.9); }
.summary-count { font-size: 24rpx; color: rgba(255,255,255,.8); background: rgba(255,255,255,.16); padding: 6rpx 18rpx; border-radius: 24rpx; }
.summary-num { font-size: 56rpx; font-weight: 700; margin: 16rpx 0 20rpx; letter-spacing: 1rpx; }
.summary-foot { display: flex; align-items: center; background: rgba(255,255,255,.14); border-radius: 16rpx; padding: 18rpx 0; }
.sf-item { flex: 1; display: flex; flex-direction: column; align-items: center; }
.sf-label { font-size: 22rpx; color: rgba(255,255,255,.75); margin-bottom: 6rpx; }
.sf-val { font-size: 28rpx; font-weight: 600; }
.sf-divider { width: 2rpx; height: 44rpx; background: rgba(255,255,255,.25); }

.list-wrap { margin: 8rpx 24rpx 40rpx; }
.list-title { display: flex; align-items: center; font-size: 28rpx; font-weight: 600; color: #1d2129; margin: 16rpx 4rpx 20rpx; }
.empty { display: flex; flex-direction: column; align-items: center; padding: 80rpx 0; }
.empty-text { margin-top: 16rpx; font-size: 26rpx; color: #8a9aa8; }

.slip-item { display: flex; align-items: center; background: #fff; border-radius: 20rpx; padding: 26rpx 24rpx; margin-bottom: 20rpx; box-shadow: 0 4rpx 16rpx rgba(31, 41, 55, .05); }
.slip-month { width: 170rpx; display: flex; flex-direction: column; }
.sm-y { font-size: 28rpx; font-weight: 700; color: #1d2129; }
.sm-no { font-size: 20rpx; color: #8a9aa8; margin-top: 6rpx; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 160rpx; }
.slip-money { flex: 1; }
.sm-line { display: flex; align-items: center; margin: 4rpx 0; }
.sm-lab { font-size: 22rpx; color: #8a9aa8; width: 56rpx; }
.sm-gross { font-size: 24rpx; color: #4e5a6b; font-weight: 500; }
.sm-net { font-size: 30rpx; color: #1d2129; font-weight: 700; }
.slip-right { display: flex; align-items: center; }
.status-badge { font-size: 20rpx; padding: 6rpx 16rpx; border-radius: 20rpx; margin-right: 8rpx; }
.st-1 { background: #eef2ff; color: #4F46E5; }
.st-2 { background: #fff7e6; color: #d48806; }
.st-3 { background: #e6f7ef; color: #059669; }

.mask { position: fixed; inset: 0; background: rgba(0,0,0,.45); z-index: 90; transition: opacity .25s; }
.detail-panel { position: fixed; left: 0; right: 0; bottom: 0; background: #f7f8fb; border-radius: 32rpx 32rpx 0 0; z-index: 91; transform: translateY(105%); transition: transform .28s ease; max-height: 82vh; }
.detail-panel.open { transform: translateY(0); }
.detail-body { padding: 36rpx 32rpx calc(36rpx + env(safe-area-inset-bottom)); }
.detail-head { display: flex; align-items: flex-start; justify-content: space-between; }
.dh-month { font-size: 34rpx; font-weight: 700; color: #1d2129; }
.dh-sub { font-size: 22rpx; color: #8a9aa8; margin-top: 8rpx; }
.dh-net { background: #fff; border-radius: 20rpx; padding: 28rpx 24rpx; margin: 24rpx 0; display: flex; align-items: baseline; justify-content: space-between; box-shadow: 0 4rpx 16rpx rgba(31,41,55,.05); }
.dhn-label { font-size: 24rpx; color: #8a9aa8; }
.dhn-num { font-size: 44rpx; font-weight: 700; color: #4F46E5; }
.detail-rows { background: #fff; border-radius: 20rpx; padding: 8rpx 24rpx; box-shadow: 0 4rpx 16rpx rgba(31,41,55,.05); }
.d-row { display: flex; align-items: center; justify-content: space-between; padding: 24rpx 0; border-bottom: 2rpx solid #f2f4f8; font-size: 28rpx; }
.d-row:last-child { border-bottom: none; }
.dr-lab { color: #4e5a6b; }
.dr-val { color: #1d2129; font-weight: 500; }
.dr-val.minus { color: #e74c5e; }
.d-row.total { border-top: 2rpx dashed #e4e7ed; }
.d-row.total .dr-val { font-weight: 700; }
.d-row.net .dr-lab, .d-row.net .dr-val { font-weight: 700; color: #4F46E5; font-size: 30rpx; }
.sign-btn { margin-top: 32rpx; background: linear-gradient(135deg, #4F46E5, #6d5ff0); color: #fff; font-size: 30rpx; font-weight: 600; border-radius: 44rpx; height: 88rpx; line-height: 88rpx; border: none; }
.sign-btn::after { border: none; }
.signed-tip { display: flex; align-items: center; justify-content: center; margin-top: 32rpx; font-size: 24rpx; color: #059669; }
</style>
