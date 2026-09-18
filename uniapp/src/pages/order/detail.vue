<template>
  <view class="od-page">
    <!-- 加载/错误态 -->
    <view v-if="loading" class="od-status"><text class="od-status-text">加载中...</text></view>
    <view v-else-if="!order" class="od-status">
      <u-icon name="error-circle" color="#c0cedc" size="40" />
      <text class="od-status-text">工单不存在或已被删除</text>
      <view class="od-retry" @click="loadData">重试</view>
    </view>
    <template v-else>
      <!-- 工单头部状态区 -->
      <view class="od-head">
        <view class="od-head-no">
          <u-icon name="order" color="#4F46E5" size="18" />
          <text class="od-head-no-text">{{ order.order_no }}</text>
        </view>
        <view class="od-head-tags">
          <text class="od-tag" :class="'st-' + order.status">{{ statusText(order.status) }}</text>
          <text v-if="order.priority === 2 || order.priority === 3" class="od-tag" :class="'pr-' + order.priority">{{ priorityText(order.priority) }}</text>
        </view>
      </view>

      <!-- 工单基本信息 -->
      <view class="od-card">
        <view class="od-grid">
          <view class="od-cell full">
            <text class="od-label">产品名称</text>
            <text class="od-value strong">{{ order.product_name }}{{ order.product_spec ? '（' + order.product_spec + '）' : '' }}</text>
          </view>
          <view class="od-cell">
            <text class="od-label">计划批量</text>
            <text class="od-value strong blue">{{ order.plan_quantity }} 件</text>
          </view>
          <view class="od-cell">
            <text class="od-label">已完工</text>
            <text class="od-value strong">{{ displayCompleted }} 件</text>
          </view>
          <view class="od-cell">
            <text class="od-label">剩余</text>
            <text class="od-value strong">{{ remainQuantity }} 件</text>
          </view>
          <view class="od-cell">
            <text class="od-label">优先级</text>
            <text class="od-value strong">{{ priorityText(order.priority) }}</text>
          </view>
          <view class="od-cell">
            <text class="od-label">创建时间</text>
            <text class="od-value strong">{{ formatTime(order.created_at) }}</text>
          </view>
          <view class="od-cell">
            <text class="od-label">计划完工</text>
            <text class="od-value strong">{{ order.planned_end_date || '-' }}</text>
          </view>
          <view class="od-cell">
            <text class="od-label">负责人</text>
            <text class="od-value strong">{{ order.responsible_person_name || '-' }}</text>
          </view>
        </view>
      </view>

      <!-- 生产进度 -->
      <view class="od-card">
        <view class="od-card-head">
          <text class="od-card-title">生产进度</text>
          <text class="od-progress-num" :style="{ color: progressColor }">{{ progress }}%</text>
        </view>
        <view class="od-progress-track">
          <view class="od-progress-fill" :style="{ width: progress + '%', background: progressColor }"></view>
        </view>
        <!-- 状态时间线 -->
        <view class="od-timeline">
          <view v-for="(t, i) in order.timeline" :key="i" class="od-tl-item">
            <view class="od-tl-left">
              <view class="od-tl-dot" :style="{ background: tlColor(t.status) }"></view>
              <view v-if="i < order.timeline.length - 1" class="od-tl-line"></view>
            </view>
            <view class="od-tl-content">
              <view class="od-tl-row">
                <text class="od-tl-name">{{ t.status_label }}</text>
                <text class="od-tl-time">{{ formatTime(t.change_time) }}</text>
              </view>
              <text v-if="t.description" class="od-tl-desc">{{ t.description }}</text>
            </view>
          </view>
        </view>
      </view>

      <!-- 报工记录 -->
      <view class="od-card">
        <view class="od-card-head">
          <text class="od-card-title">报工记录</text>
          <text class="od-count">{{ reports.length }} 条</text>
        </view>
        <view v-if="reports.length" class="od-report-list">
          <view v-for="(r, i) in reports" :key="i" class="od-report-item">
            <view class="od-report-left">
              <text class="od-report-time">{{ r.report_date }} · {{ r.reporter_name }}</text>
              <text class="od-report-qty">合格 {{ r.quantity || 0 }} 件<text v-if="r.total_score" class="od-report-score"> · {{ r.total_score }} 分</text></text>
            </view>
            <text class="od-report-status" :class="'rs-' + r.status">{{ reportStatusText(r.status) }}</text>
          </view>
        </view>
        <view v-else class="od-empty">暂无报工记录</view>
      </view>

      <!-- 底部操作栏 -->
      <view class="od-footer">
        <view class="od-footer-btn" :class="footerBtn.class" @click="footerBtn.action">
          <u-icon v-if="footerBtn.icon" :name="footerBtn.icon" color="#fff" size="16" />
          <text>{{ footerBtn.text }}</text>
        </view>
      </view>
    </template>
  </view>
</template>

<script setup>
import { ref, computed } from 'vue'
import { onLoad, onPullDownRefresh } from '@dcloudio/uni-app'

const order = ref(null)
const reports = ref([])
const loading = ref(true)
let orderId = 0

// ===== 映射 =====
const STATUS = { 0: '待派工', 1: '已派工', 2: '进行中', 3: '待检验', 4: '已完成', 5: '已关闭' }
const PRIORITY = { 1: '普通', 2: '紧急', 3: '特急' }
const REPORT_STATUS = { 0: '草稿', 1: '待审核', 2: '已通过', 3: '已驳回' }

function statusText(s) { return STATUS[s] || (s ?? '') }
function priorityText(p) { return PRIORITY[p] || (p ?? '') }
function reportStatusText(s) { return REPORT_STATUS[s] || (s ?? '') }

function formatTime(t) {
  if (!t) return ''
  const s = String(t).replace('T', ' ')
  return s.length > 16 ? s.slice(0, 16) : s
}

// 待审核报工数量（报工已提交未审核，计入进度展示）
const pendingQty = computed(() => reports.value
  .filter(r => Number(r.status) === 1)
  .reduce((s, r) => s + Number(r.quantity || 0), 0))
// 已完工展示 = 工单已完成数量（审核通过计入） + 待审核报工数量
const displayCompleted = computed(() => Number(order.value?.completed_quantity || 0) + pendingQty.value)
const remainQuantity = computed(() => Math.max(0, (order.value?.plan_quantity || 0) - displayCompleted.value))
const progress = computed(() => {
  const plan = Number(order.value?.plan_quantity || 0)
  if (plan <= 0) return 0
  return Math.min(100, Math.round((displayCompleted.value / plan) * 100))
})
const progressColor = computed(() => {
  const p = progress.value
  if (p <= 30) return '#f59e0b'
  if (p <= 70) return '#4F46E5'
  return '#34c759'
})
function tlColor(status) {
  return { created: '#9ca3af', dispatched: '#4F46E5', processing: '#4F46E5', done: '#34c759', cancelled: '#9ca3af' }[status] || '#9ca3af'
}

// ===== 底部按钮 =====
const footerBtn = computed(() => {
  const s = Number(order.value?.status)
  if (s === 1 || s === 2) {
    return { text: '去报工', icon: 'share-square', class: 'go', action: goReport }
  }
  if (s === 3) return { text: '待检验', icon: '', class: 'inspection disabled', action: () => {} }
  if (s === 4 || s === 5) return { text: '已完结', icon: '', class: 'done disabled', action: () => {} }
  return { text: '待派工', icon: '', class: 'pending disabled', action: () => {} }
})

// ===== 数据 =====
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

async function loadData() {
  loading.value = true
  if (!orderId) { loading.value = false; return }
  try {
    const [d, r] = await Promise.all([
      api('/api/production/order/detail/' + orderId).catch(() => null),
      api('/api/production/report/list', 'GET', { work_order_id: orderId, page: 1, pageSize: 50 }).catch(() => null)
    ])
    order.value = d || null
    reports.value = (r && r.list) || []
  } catch (e) {
    order.value = null
  }
  loading.value = false
}

function goReport() {
  uni.navigateTo({ url: '/pages/report/index?order_id=' + orderId })
}

onLoad((options) => {
  orderId = Number(options?.id || options?.order_id || 0)
  loadData()
})

onPullDownRefresh(async () => {
  await loadData()
  uni.stopPullDownRefresh()
})
</script>

<style scoped>
.od-page { min-height: 100vh; background: #F4F6FB; padding: 12px 16px 96px; box-sizing: border-box; }
.od-status { display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 60vh; gap: 12px; color: #b0c0cc; }
.od-status-text { font-size: 14px; color: #b0c0cc; }
.od-retry { margin-top: 8px; padding: 10px 32px; background: #4F46E5; color: #fff; border-radius:224px; font-size: 14px; }

/* 头部 */
.od-head { display: flex; align-items: center; justify-content: space-between; gap: 10px; background: rgba(255,255,255,0.9); padding: 16px 20px; border-bottom: 1px solid #E7ECF4; border-radius:122px; margin-bottom: 12px; }
.od-head-no { display: flex; align-items: center; gap: 8px; flex: 1; min-width: 0; }
.od-head-no-text { font-size: 18px; font-weight: 700; color: #1a2332; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.od-head-tags { display: flex; align-items: center; gap: 6px; flex-shrink: 0; }

/* 标签 */
.od-tag { font-size: 12px; font-weight: 700; padding: 4px 14px; border-radius:30px; }
.od-tag.st-0 { background: #f3f4f6; color: #6b7280; }
.od-tag.st-1 { background: #EEF0FE; color: #4F46E5; }
.od-tag.st-2 { background: #EEF0FE; color: #4F46E5; }
.od-tag.st-3 { background: #fef3e2; color: #f59e0b; }
.od-tag.st-4 { background: #f0f9eb; color: #34c759; }
.od-tag.st-5 { background: #f3f4f6; color: #6b7280; }
.od-tag.pr-2 { background: #fef3e2; color: #f59e0b; font-size: 11px; padding: 3px 10px; }
.od-tag.pr-3 { background: #fdecea; color: #e74c5e; font-size: 11px; padding: 3px 10px; }

/* 卡片 */
.od-card { background: rgba(255,255,255,0.95); border-radius:122px; padding: 16px 18px; border: 1px solid #E7ECF4; box-shadow: 0 1px 4px rgba(0,0,0,0.02); margin-bottom: 12px; }
.od-card-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; }
.od-card-title { font-size: 14px; font-weight: 700; color: #1a2332; }
.od-count { font-size: 12px; color: #9ca3af; }
.od-progress-num { font-size: 14px; font-weight: 700; }

/* 基本信息网格 */
.od-grid { display: flex; flex-wrap: wrap; }
.od-cell { width: 50%; box-sizing: border-box; margin-bottom: 12px; padding-right: 8px; }
.od-cell.full { width: 100%; }
.od-label { display: block; font-size: 12px; color: #9ca3af; margin-bottom: 3px; }
.od-value { display: block; font-size: 15px; font-weight: 600; color: #1a2332; }
.od-value.strong { font-weight: 700; }
.od-value.blue { color: #4F46E5; }

/* 进度条 */
.od-progress-track { height: 8px; border-radius:24px; background: #E7ECF4; overflow: hidden; }
.od-progress-fill { height: 100%; border-radius:24px; transition: width .3s; }

/* 时间线 */
.od-timeline { margin-top: 16px; }
.od-tl-item { display: flex; }
.od-tl-left { display: flex; flex-direction: column; align-items: center; width: 18px; flex-shrink: 0; }
.od-tl-dot { width: 10px; height: 10px; border-radius:50%; margin-top: 4px; }
.od-tl-line { width: 2px; flex: 1; background: #e5e9f0; min-height: 20px; margin: 4px 0; }
.od-tl-content { flex: 1; min-width: 0; padding: 0 0 16px 8px; }
.od-tl-row { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.od-tl-name { font-size: 14px; color: #1a2332; font-weight: 500; }
.od-tl-time { font-size: 12px; color: #9ca3af; }
.od-tl-desc { display: block; font-size: 12px; color: #9ca3af; margin-top: 2px; }

/* 报工记录 */
.od-report-item { display: flex; align-items: center; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #F4F6FB; }
.od-report-item:last-child { border-bottom: none; }
.od-report-left { display: flex; flex-direction: column; }
.od-report-time { font-size: 13px; color: #9ca3af; }
.od-report-qty { font-size: 15px; font-weight: 700; color: #1a2332; margin-top: 2px; }
.od-report-score { font-size: 12px; font-weight: 400; color: #8a9aa8; }
.od-report-status { font-size: 12px; font-weight: 700; padding: 2px 10px; border-radius:30px; flex-shrink: 0; }
.od-report-status.rs-0 { background: #f3f4f6; color: #6b7280; }
.od-report-status.rs-1 { background: #fef3e2; color: #f59e0b; }
.od-report-status.rs-2 { background: #f0f9eb; color: #34c759; }
.od-report-status.rs-3 { background: #fdecea; color: #e74c5e; }
.od-empty { text-align: center; color: #b0c0cc; font-size: 14px; padding: 24px 0; }

/* 底部操作栏 */
.od-footer { position: fixed; left: 0; right: 0; bottom: 0; background: rgba(255,255,255,0.96); border-top: 1px solid #E7ECF4; padding: 12px 20px calc(12px + env(safe-area-inset-bottom)); box-sizing: border-box; }
.od-footer-btn { display: flex; align-items: center; justify-content: center; gap: 6px; width: 100%; padding: 14px; border-radius:124px; font-size: 16px; font-weight: 700; }
.od-footer-btn.go { background: linear-gradient(135deg, #4F46E5, #7C6FF0); color: #fff; box-shadow: 0 4px 16px rgba(110,142,251,0.25); }
.od-footer-btn.disabled { color: #b0c0cc; }
.od-footer-btn.pending, .od-footer-btn.done { background: #f3f4f6; }
.od-footer-btn.inspection { background: #fef3e2; color: #f59e0b; }
</style>
