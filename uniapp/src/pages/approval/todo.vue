<template>
  <view class="at-page">
    <!-- 统计卡 -->
    <view class="at-stats">
      <view class="at-stat" @click="switchCard('')">
        <text class="at-stat-num">{{ stats.pending || 0 }}</text>
        <text class="at-stat-label">待审批</text>
      </view>
      <view class="at-stat" @click="switchCard('today')">
        <text class="at-stat-num">{{ stats.today || 0 }}</text>
        <text class="at-stat-label">今日待审</text>
      </view>
      <view class="at-stat" @click="switchCard('timeout')">
        <text class="at-stat-num">{{ stats.timeout || 0 }}</text>
        <text class="at-stat-label">已超时</text>
      </view>
      <view class="at-stat" @click="switchCard('mine')">
        <text class="at-stat-num">{{ stats.mine || 0 }}</text>
        <text class="at-stat-label">我发起的</text>
      </view>
    </view>

    <!-- 列表 -->
    <scroll-view scroll-y class="at-list" :refresher-enabled="true" :refresher-triggered="refreshing" @refresherrefresh="onRefresh" @scrolltolower="loadMore">
      <view v-if="loading && !list.length" class="at-status"><text>加载中...</text></view>
      <u-empty v-else-if="!list.length" text="暂无待审批任务" mode="list" />
      <view v-else class="at-cards">
        <view v-for="r in list" :key="r.id" class="at-card" @click="openApprove(r)">
          <view class="at-card-top">
            <text class="at-biz-tag">{{ r.business_name }}</text>
            <text v-if="r.is_proxy === 1" class="at-proxy">代理</text>
            <text v-if="r.timeout_status_label === '已超时'" class="at-timeout">已超时</text>
            <text class="at-mode">{{ r.approval_mode_label }}</text>
          </view>
          <view class="at-card-no">
            <u-icon name="order" color="#4F46E5" size="14" />
            <text class="at-no-text">{{ r.business_no }}</text>
          </view>
          <text class="at-title">{{ r.business_title }}</text>
          <view class="at-card-bottom">
            <text class="at-meta">申请人：{{ r.applicant_name }} · 节点：{{ r.current_node_name }}</text>
            <text class="at-time">{{ formatTime(r.submit_time) }}</text>
          </view>
        </view>
        <view v-if="list.length" class="at-loadmore">
          <text v-if="loadingMore" class="at-loadmore-text">加载中...</text>
          <text v-else-if="list.length >= total && total > 0" class="at-loadmore-text">— 已加载全部 —</text>
        </view>
      </view>
    </scroll-view>

    <!-- 审批弹窗 -->
    <u-popup :show="approveVisible" mode="bottom" round="24" @close="approveVisible = false">
      <view class="at-sheet">
        <view class="at-sheet-head">
          <text class="at-sheet-title">审批 - {{ curRow ? curRow.business_name : '' }}</text>
          <view class="at-sheet-close" @click="approveVisible = false"><u-icon name="close" color="#8a9aa8" size="16" /></view>
        </view>
        <scroll-view scroll-y class="at-sheet-body">
          <view class="at-detail">
            <view class="at-detail-item"><text class="at-detail-label">业务编号</text><text class="at-detail-value">{{ curRow.business_no }}</text></view>
            <view class="at-detail-item"><text class="at-detail-label">业务标题</text><text class="at-detail-value">{{ curRow.business_title }}</text></view>
            <view class="at-detail-item"><text class="at-detail-label">申请人</text><text class="at-detail-value">{{ curRow.applicant_name }}</text></view>
            <view class="at-detail-item"><text class="at-detail-label">申请时间</text><text class="at-detail-value">{{ curRow.submit_time }}</text></view>
            <view class="at-detail-item"><text class="at-detail-label">当前节点</text><text class="at-detail-value">{{ curRow.current_node_name }}</text></view>
            <view class="at-detail-item"><text class="at-detail-label">审批模式</text><text class="at-detail-value">{{ curRow.approval_mode_label }}</text></view>
            <view class="at-detail-item" v-if="curRow.urgent === 1 || curRow.urgent === 2"><text class="at-detail-label">紧急程度</text><text class="at-detail-value urgent">{{ curRow.urgent_label }}</text></view>
          </view>
          <!-- 业务摘要 -->
          <view v-if="detailData && detailData.bizSummary && detailData.bizSummary.length" class="at-detail">
            <view class="at-detail-item" v-for="(it, i) in detailData.bizSummary" :key="i">
              <text class="at-detail-label">{{ it.label }}</text><text class="at-detail-value">{{ it.value }}</text>
            </view>
          </view>
          <!-- 作业照片 -->
          <view v-if="detailData && detailData.bizPhotos && detailData.bizPhotos.length" class="at-photos">
            <text class="at-photos-label">作业照片（{{ detailData.bizPhotos.length }} 张）</text>
            <view class="at-photo-grid">
              <image v-for="(u, i) in detailData.bizPhotos" :key="i" :src="imgUrl(u)" mode="aspectFill" class="at-photo" @click="preview(i)" />
            </view>
          </view>
          <!-- 审批意见 -->
          <u-textarea v-model="approveComment" placeholder="请输入审批意见（驳回时必填）" maxlength="500" />
        </scroll-view>
        <!-- 更多操作：催办 / 转办 -->
        <view class="at-more-row">
          <view class="at-more-btn" @click="handleUrge"><MIcon name="clock" :size="15" color="#f59e0b" /><text>催办</text></view>
          <view class="at-more-btn" @click="openTransfer"><MIcon name="send" :size="15" color="#4F46E5" /><text>转办</text></view>
        </view>
        <view class="at-sheet-foot">
          <view class="at-foot-btn reject" :class="{ disabled: submitting }" @click="handleReject">驳 回</view>
          <view class="at-foot-btn approve" :class="{ disabled: submitting }" @click="handleApprove">通 过</view>
        </view>
      </view>
    </u-popup>

    <!-- 转办弹窗 -->
    <view v-if="transferVisible" class="tf-mask" @click="transferVisible = false">
      <view class="tf-sheet" @click.stop>
        <view class="tf-head">
          <text class="tf-title">转办给他人</text>
          <view class="tf-close" @click="transferVisible = false"><MIcon name="close" :size="16" color="#8a9aa8" /></view>
        </view>
        <view class="tf-search">
          <u-input v-model="transferKeyword" placeholder="搜索姓名/账号..." border="none" :customStyle="{ height: '38px', fontSize: '14px' }" @change="loadTransferOptions" />
        </view>
        <scroll-view scroll-y class="tf-list">
          <view v-for="u in transferUsers" :key="u.id" class="tf-user" :class="{selected: selectedUserId === u.id}" @click="selectedUserId = u.id">
            <view class="tf-user-main">
              <text class="tf-user-name">{{ u.name }}</text>
              <text class="tf-user-dept">{{ u.department_name || u.username }}</text>
            </view>
            <view class="tf-radio" :class="{on: selectedUserId === u.id}"></view>
          </view>
          <view v-if="!transferUsers.length" class="tf-empty">未找到可转办的用户</view>
        </scroll-view>
        <view class="tf-reason">
          <u-textarea v-model="transferReason" placeholder="转办原因（选填）" maxlength="200" />
        </view>
        <view class="tf-foot">
          <view class="tf-cancel" @click="transferVisible = false">取消</view>
          <view class="tf-submit" :class="{disabled: transferSubmitting || !selectedUserId}" @click="doTransfer">{{ transferSubmitting ? '提交中...' : '确认转办' }}</view>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'

const list = ref([])
const total = ref(0)
const stats = ref({ pending: 0, today: 0, timeout: 0, mine: 0 })
const page = ref(1)
const pageSize = 15
const loading = ref(false)
const loadingMore = ref(false)
const refreshing = ref(false)
const cardStatus = ref('')
// 审批
const approveVisible = ref(false)
const curRow = ref(null)
const detailData = ref(null)
const approveComment = ref('')
const submitting = ref(false)
// 转办
const transferVisible = ref(false)
const transferKeyword = ref('')
const transferUsers = ref([])
const selectedUserId = ref(0)
const transferReason = ref('')
const transferSubmitting = ref(false)

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
function imgUrl(val) {
  if (!val) return ''
  if (val.startsWith('http://') || val.startsWith('https://')) return val
  if (val.startsWith('/')) return uni.$base + val
  return val
}
function formatTime(t) {
  if (!t) return ''
  const s = String(t).replace('T', ' ')
  return s.length > 16 ? s.slice(0, 16) : s
}

async function loadList(reset = false) {
  if (reset) { page.value = 1; list.value = [] }
  loading.value = true
  try {
    const params = { page: page.value, pageSize }
    if (cardStatus.value) params.status = cardStatus.value
    const r = await api('/api/approval/my-tasks', 'GET', params)
    list.value = reset ? ((r && r.list) || []) : list.value.concat((r && r.list) || [])
    total.value = (r && r.total) || 0
    stats.value = (r && r.stats) || { pending: 0, today: 0, timeout: 0, mine: 0 }
  } catch (e) {} finally { loading.value = false }
}
async function switchCard(k) {
  cardStatus.value = cardStatus.value === k ? '' : k
  await loadList(true)
}
async function onRefresh() {
  refreshing.value = true
  await loadList(true)
  refreshing.value = false
}
async function loadMore() {
  if (loading.value || loadingMore.value || list.value.length >= total.value) return
  loadingMore.value = true
  page.value += 1
  await loadList()
  loadingMore.value = false
}

async function openApprove(r) {
  curRow.value = r
  detailData.value = null
  approveComment.value = ''
  approveVisible.value = true
  try {
    detailData.value = await api('/api/approval/detail/' + r.id)
  } catch (e) { detailData.value = null }
}
function preview(idx) {
  uni.previewImage({ urls: (detailData.value.bizPhotos || []).map(imgUrl), current: idx })
}

async function handleApprove() {
  if (submitting.value) return
  uni.showModal({
    title: '审批通过',
    content: `确认通过「${curRow.value.business_no}」吗？`,
    success: async (res) => {
      if (!res.confirm) return
      submitting.value = true
      try {
        await api('/api/approval/approve/' + curRow.value.id, 'POST', { comment: approveComment.value })
        uni.showToast({ title: '审批已通过', icon: 'success' })
        approveVisible.value = false
        await loadList(true)
      } catch (e) {
        uni.showToast({ title: e.msg || '审批失败', icon: 'none' })
      }
      submitting.value = false
    }
  })
}
async function handleReject() {
  if (submitting.value) return
  if (!approveComment.value.trim()) { uni.showToast({ title: '驳回时必须填写审批意见', icon: 'none' }); return }
  uni.showModal({
    title: '审批驳回',
    content: `确认驳回「${curRow.value.business_no}」吗？`,
    success: async (res) => {
      if (!res.confirm) return
      submitting.value = true
      try {
        await api('/api/approval/reject/' + curRow.value.id, 'POST', { comment: approveComment.value })
        uni.showToast({ title: '已驳回', icon: 'success' })
        approveVisible.value = false
        await loadList(true)
      } catch (e) {
        uni.showToast({ title: e.msg || '驳回失败', icon: 'none' })
      }
      submitting.value = false
    }
  })
}

// 催办
async function handleUrge() {
  if (!curRow.value) return
  uni.showModal({
    title: '催办提醒',
    content: `确认向当前审批人发送催办提醒吗？（24小时内仅可催办一次）`,
    success: async (res) => {
      if (!res.confirm) return
      try {
        await api('/api/approval/urge/' + curRow.value.id, 'POST', {})
        uni.showToast({ title: '催办通知已发送', icon: 'success' })
      } catch (e) {
        uni.showToast({ title: e.msg || '催办失败', icon: 'none' })
      }
    }
  })
}

// 转办
async function openTransfer() {
  if (!curRow.value) return
  transferKeyword.value = ''
  selectedUserId.value = 0
  transferReason.value = ''
  transferVisible.value = true
  await loadTransferOptions()
}
async function loadTransferOptions() {
  try {
    const r = await api('/api/mobile/approval/transfer-options', 'GET', { keyword: transferKeyword.value })
    transferUsers.value = (r && r.list) || []
  } catch (e) {
    transferUsers.value = []
  }
}
async function doTransfer() {
  if (transferSubmitting.value || !selectedUserId.value || !curRow.value) return
  uni.showModal({
    title: '确认转办',
    content: `确认将「${curRow.value.business_no}」转办给该用户吗？转办后由对方处理。`,
    success: async (res) => {
      if (!res.confirm) return
      transferSubmitting.value = true
      try {
        await api('/api/approval/transfer/' + curRow.value.id, 'POST', {
          target_user_id: selectedUserId.value,
          reason: transferReason.value
        })
        uni.showToast({ title: '转办成功', icon: 'success' })
        transferVisible.value = false
        approveVisible.value = false
        await loadList(true)
      } catch (e) {
        uni.showToast({ title: e.msg || '转办失败', icon: 'none' })
      }
      transferSubmitting.value = false
    }
  })
}

onLoad(() => { loadList(true) })
</script>

<style scoped>
.at-page { min-height: 100vh; background: #F4F6FB; display: flex; flex-direction: column; }
.at-stats { display: flex; gap: 8px; padding: 12px 16px; }
.at-stat { flex: 1; background: rgba(255,255,255,0.9); border: 1px solid #E7ECF4; border-radius:24px; padding: 10px 4px; display: flex; flex-direction: column; align-items: center; }
.at-stat-num { font-size: 18px; font-weight: 700; color: #1a2332; }
.at-stat-label { font-size: 10px; color: #9ca3af; margin-top: 3px; }
.at-list { flex: 1; height: 0; padding: 12px 16px; box-sizing: border-box; }
.at-status { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 60px 0; gap: 8px; color: #b0c0cc; }
.at-empty-text { font-size: 14px; color: #b0c0cc; }
.at-card { background: rgba(255,255,255,0.95); border: 1px solid #E7ECF4; border-radius:124px; padding: 14px 16px; padding-right: calc(16px + constant(safe-area-inset-right)); padding-right: calc(16px + env(safe-area-inset-right)); margin-bottom: 8px; }
.at-card-top { display: flex; align-items: center; gap: 8px; }
.at-biz-tag { font-size: 11px; font-weight: 600; color: #4F46E5; background: #f0f4ff; padding: 2px 10px; border-radius:24px; }
.at-proxy { font-size: 11px; color: #f59e0b; background: #fef3e2; padding: 2px 10px; border-radius:24px; }
.at-timeout { font-size: 11px; color: #e74c5e; background: #fdecea; padding: 2px 10px; border-radius:24px; }
.at-mode { font-size: 11px; color: #9ca3af; margin-left: auto; }
.at-card-no { display: flex; align-items: center; gap: 6px; margin-top: 8px; }
.at-no-text { font-size: 14px; font-weight: 700; color: #1a2332; }
.at-title { display: block; font-size: 13px; color: #4a5568; margin-top: 4px; }
.at-card-bottom { display: flex; align-items: center; justify-content: space-between; margin-top: 8px; }
.at-meta { font-size: 12px; color: #9ca3af; }
.at-time { font-size: 12px; color: #b0c0cc; }
.at-loadmore { text-align: center; padding: 14px 0 20px; }
.at-loadmore-text { font-size: 12px; color: #b0c0cc; }
/* 审批弹窗 */
.at-mask { position: fixed; inset: 0; background: rgba(0,0,0,0.4); z-index: 100; display: flex; align-items: flex-end; }
.at-sheet { width: 100%; background: #fff; border-radius:224px 224px 0 0; max-height: 88vh; display: flex; flex-direction: column; box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06); }
.at-sheet-head { display: flex; align-items: center; justify-content: space-between; padding: 18px 20px 10px; border-bottom: 1px solid #EDF0F8; }
.at-sheet-title { font-size: 16px; font-weight: 700; color: #1a2332; }
.at-sheet-close { width: 28px; height: 28px; border-radius:50%; background: #EDF0F8; display: flex; align-items: center; justify-content: center; }
.at-sheet-body { flex: 1; max-height: 58vh; padding: 12px 20px; box-sizing: border-box; }
.at-detail { background: #f8fafc; border-radius:24px; padding: 10px 14px; margin-bottom: 10px; }
.at-detail-item { display: flex; align-items: flex-start; padding: 5px 0; }
.at-detail-label { width: 70px; flex-shrink: 0; font-size: 12px; color: #9ca3af; }
.at-detail-value { flex: 1; font-size: 13px; color: #1a2332; }
.at-detail-value.urgent { color: #e74c5e; font-weight: 600; }
.at-photos-label { display: block; font-size: 13px; font-weight: 600; color: #1a2332; margin-bottom: 8px; }
.at-photo-grid { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 10px; }
.at-photo { width: 80px; height: 80px; border-radius:24px; }
.at-comment { width: 100%; height: 80px; background: #f8fafc; border-radius:24px; padding: 12px 14px; font-size: 14px; color: #1a2332; box-sizing: border-box; }
.at-more-row { display: flex; gap: 10px; padding: 4px 20px 10px; }
.at-more-btn { flex: 1; display: flex; align-items: center; justify-content: center; gap: 6px; padding: 10px; border-radius: 20px; background: #f4f6fb; border: 1px solid #E7ECF4; font-size: 13px; color: #4a5568; }
.at-more-icon { font-size: 15px; }
.at-sheet-foot { display: flex; gap: 10px; padding: 4px 20px calc(16px + env(safe-area-inset-bottom)); border-top: 1px solid #EDF0F8; }
.at-foot-btn { flex: 1; text-align: center; padding: 13px; border-radius:24px; font-size: 15px; font-weight: 700; }
.at-foot-btn.approve { background: linear-gradient(135deg, #34c759, #2ea84c); color: #fff; }
.at-foot-btn.reject { background: #fff; color: #e74c5e; border: 1px solid #fbc4c4; }
.at-foot-btn.disabled { opacity: 0.6; }
/* 转办弹窗 */
.tf-mask { position: fixed; inset: 0; background: rgba(0,0,0,0.45); z-index: 200; display: flex; align-items: flex-end; }
.tf-sheet { width: 100%; background: #fff; border-radius: 24px 24px 0 0; padding: 18px 20px calc(18px + env(safe-area-inset-bottom)); box-sizing: border-box; max-height: 78vh; display: flex; flex-direction: column; }
.tf-head { display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px; }
.tf-title { font-size: 17px; font-weight: 700; color: #1a2332; }
.tf-close { width: 28px; height: 28px; border-radius: 50%; background: #EDF0F8; color: #8a9aa8; display: flex; align-items: center; justify-content: center; font-size: 14px; }
.tf-search { background: #f4f6fb; border-radius: 20px; padding: 0 14px; margin-bottom: 10px; }
.tf-list { flex: 1; max-height: 42vh; }
.tf-user { display: flex; align-items: center; justify-content: space-between; padding: 12px 6px; border-bottom: 1px solid #f1f4f9; }
.tf-user-main { display: flex; flex-direction: column; }
.tf-user-name { font-size: 15px; font-weight: 600; color: #1a2332; }
.tf-user-dept { font-size: 12px; color: #9ca3af; margin-top: 2px; }
.tf-radio { width: 20px; height: 20px; border-radius: 50%; border: 2px solid #d5dde8; }
.tf-radio.on { border-color: #4F46E5; background: #4F46E5; box-shadow: inset 0 0 0 4px #fff; }
.tf-empty { text-align: center; color: #b0c0cc; font-size: 13px; padding: 30px 0; }
.tf-reason { margin: 8px 0; }
.tf-foot { display: flex; gap: 10px; margin-top: 6px; }
.tf-cancel { flex: 1; text-align: center; padding: 13px; border-radius: 24px; font-size: 15px; color: #4a5568; background: #f4f6fb; }
.tf-submit { flex: 2; text-align: center; padding: 13px; border-radius: 24px; font-size: 15px; font-weight: 700; color: #fff; background: linear-gradient(135deg, #4F46E5, #7c6cf0); }
.tf-submit.disabled { opacity: 0.6; }
</style>
