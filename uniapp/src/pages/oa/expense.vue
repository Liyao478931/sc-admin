<template>
  <view class="exp-page">
    <!-- 顶部导航 -->
    <view class="exp-nav" :style="{ paddingTop: statusBarHeight + 'px' }">
      <view class="exp-nav-left">
        <view class="exp-back" @click="goBack">
          <u-icon name="arrow-left" color="#1a2332" size="18"></u-icon>
          <text class="exp-back-text">返回</text>
        </view>
        <text class="exp-nav-title">费用报销</text>
      </view>
    </view>

    <!-- 滚动内容 -->
    <scroll-view class="exp-scroll" scroll-y :style="{ height: scrollHeight + 'px' }">
      <!-- 类型切换 -->
      <view class="exp-tabs">
        <view class="exp-tab" :class="{ active: mode === 'apply' }" @click="switchMode('apply')">发起报销</view>
        <view class="exp-tab" :class="{ active: mode === 'mine' }" @click="switchMode('mine')">我的报销</view>
      </view>

      <!-- ===== 发起报销 ===== -->
      <view v-if="mode === 'apply'" class="exp-form">
        <!-- 申请人信息 -->
        <view class="exp-info-card">
          <view class="exp-avatar">
            <image v-if="userInfo.avatar" :src="userInfo.avatar" mode="aspectFill" class="exp-avatar-img"></image>
            <text v-else>{{ nameInitial }}</text>
          </view>
          <view class="exp-info">
            <text class="exp-name">{{ userInfo.real_name || userInfo.name || '未登录' }}</text>
            <text class="exp-dept">{{ userInfo.department || '' }}{{ userInfo.position ? ' · ' + userInfo.position : '' }}</text>
          </view>
          <text class="exp-status-online">● 在职</text>
        </view>

        <!-- 报销科目 -->
        <view class="exp-form-group">
          <view class="exp-label">报销科目 <text class="exp-required">*</text></view>
          <picker mode="selector" :range="categoryOptions" @change="onCategoryChange">
            <view class="exp-input-wrap">
              <u-icon name="tags" color="#b0c0cc" size="16"></u-icon>
              <text class="exp-input-text" :class="{ placeholder: !form.category }">{{ form.category || '请选择报销科目' }}</text>
              <u-icon name="arrow-down" color="#b0c0cc" size="12"></u-icon>
            </view>
          </picker>
        </view>

        <!-- 报销金额 -->
        <view class="exp-form-group">
          <view class="exp-label">报销金额（元） <text class="exp-required">*</text></view>
          <view class="exp-input-wrap">
            <u-icon name="rmb-circle" color="#b0c0cc" size="16"></u-icon>
            <input class="exp-input" v-model="form.amount" type="digit" placeholder="请输入报销金额" />
          </view>
        </view>

        <!-- 报销事由 -->
        <view class="exp-form-group">
          <view class="exp-label">报销事由 <text class="exp-required">*</text></view>
          <view class="exp-textarea-wrap">
            <u-icon name="edit-pen" color="#b0c0cc" size="16"></u-icon>
            <textarea class="exp-textarea" v-model="form.purpose" placeholder="请详细说明报销内容与用途..." :maxlength="500" />
          </view>
        </view>

        <!-- 报销凭证 -->
        <view class="exp-form-group">
          <view class="exp-label">报销凭证 <text class="exp-optional">选填，最多5张</text></view>
          <view class="exp-vouchers">
            <view class="exp-voucher" v-for="(v, vi) in form.vouchers" :key="vi" @click="previewVoucher(v)">
              <image class="exp-voucher-img" :src="v" mode="aspectFill" />
              <view class="exp-voucher-del" @click.stop="removeVoucher(vi)">×</view>
            </view>
            <view class="exp-voucher-add" v-if="form.vouchers.length < 5" @click="chooseVoucher">
              <u-icon name="camera" :size="26" color="#b0c0cc"></u-icon>
              <text class="exp-voucher-add-text">上传凭证</text>
            </view>
          </view>
        </view>

        <!-- 审批流程提示 -->
        <view class="exp-flow-card">
          <view class="exp-flow-title">
            <u-icon name="list" color="#4F46E5" size="16"></u-icon>
            <text>审批流程</text>
          </view>
          <view class="exp-flow-step">
            <view class="exp-step-dot active">1</view>
            <view class="exp-step-info">
              <text class="exp-step-name">部门负责人审批</text>
              <text class="exp-step-desc">提交后自动进入审批流程</text>
            </view>
            <text class="exp-step-status active">进行中</text>
          </view>
          <view class="exp-flow-step">
            <view class="exp-step-dot waiting">2</view>
            <view class="exp-step-info">
              <text class="exp-step-name">财务审批</text>
              <text class="exp-step-desc">审批通过后由财务打款</text>
            </view>
            <text class="exp-step-status waiting">等待中</text>
          </view>
        </view>

        <!-- 提交按钮 -->
        <view class="exp-submit-section">
          <view class="exp-submit-btn ghost" @click="submitExp(false)">
            <text>存草稿</text>
          </view>
          <view class="exp-submit-btn" @click="submitExp(true)">
            <u-icon name="share-square" color="#fff" size="18"></u-icon>
            <text>提交审批</text>
          </view>
        </view>
      </view>

      <!-- ===== 我的报销 ===== -->
      <view v-else class="exp-mine">
        <!-- 状态筛选 -->
        <view class="exp-status-filter">
          <view class="exp-status-item" :class="{ active: statusFilter === '' }" @click="changeStatus('')">全部</view>
          <view class="exp-status-item" :class="{ active: statusFilter === 0 }" @click="changeStatus(0)">草稿</view>
          <view class="exp-status-item" :class="{ active: statusFilter === 1 }" @click="changeStatus(1)">审批中</view>
          <view class="exp-status-item" :class="{ active: statusFilter === 2 }" @click="changeStatus(2)">已通过</view>
          <view class="exp-status-item" :class="{ active: statusFilter === 3 }" @click="changeStatus(3)">已驳回</view>
        </view>

        <view v-if="mineList.length === 0 && !mineLoading" class="exp-empty">
          <u-icon name="file-text" color="#d5dce4" size="40"></u-icon>
          <text class="exp-empty-text">暂无报销记录</text>
        </view>

        <view class="exp-item" v-for="(item, i) in mineList" :key="i" @click="openDetail(item)">
          <view class="exp-item-top">
            <text class="exp-item-cat">{{ item.category }}</text>
            <text class="exp-item-amount">¥{{ Number(item.amount).toLocaleString() }}</text>
          </view>
          <view class="exp-item-desc">{{ item.purpose }}</view>
          <view class="exp-item-bottom">
            <text class="exp-item-no">{{ item.expense_no || ('单号待生成') }} · {{ item.department_name || '' }}</text>
            <view class="exp-item-tags">
              <text class="exp-tag" :class="'tag-' + item.status_tag">{{ item.status_text }}</text>
              <text v-if="item.status === 2" class="exp-tag" :class="item.pay_status === 1 ? 'tag-success' : 'tag-warn'">{{ item.pay_status_text }}</text>
            </view>
          </view>
        </view>

        <view v-if="mineList.length > 0 && hasMore" class="exp-load-more" @click="loadMine(true)">加载更多</view>
        <view v-if="mineList.length > 0 && !hasMore" class="exp-load-more">没有更多了</view>
      </view>
    </scroll-view>

    <!-- 详情弹层 -->
    <view v-if="detailVisible" class="exp-detail-mask" @click="detailVisible = false">
      <view class="exp-detail" @click.stop>
        <view class="exp-detail-head">
          <text class="exp-detail-title">报销详情</text>
          <u-icon name="close" color="#b0c0cc" size="18" @click="detailVisible = false"></u-icon>
        </view>
        <scroll-view class="exp-detail-body" scroll-y>
          <view class="exp-detail-row" v-for="(d, i) in detailRows" :key="i">
            <text class="exp-detail-label">{{ d.label }}</text>
            <text class="exp-detail-value" :class="{ strong: d.strong }">{{ d.value }}</text>
          </view>
          <view class="exp-detail-sub" v-if="detailVouchers.length">报销凭证</view>
          <view class="exp-detail-vouchers" v-if="detailVouchers.length">
            <image class="exp-detail-voucher" v-for="(v, vi) in detailVouchers" :key="vi" :src="v" mode="aspectFill" @click="previewDetailVoucher(vi)" />
          </view>
          <view class="exp-detail-sub">审批历程</view>
          <view v-if="detailHistories.length === 0" class="exp-history-empty">暂无审批记录</view>
          <view class="exp-history-item" v-for="(h, i) in detailHistories" :key="i">
            <view class="exp-history-dot" :class="{ done: h.status === 1 || h.status === 2, fail: h.status === 3 }"></view>
            <view class="exp-history-info">
              <text class="exp-history-action">{{ h.action_text || h.action || '审批操作' }}</text>
              <text class="exp-history-time">{{ h.time }}</text>
            </view>
          </view>
        </scroll-view>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { request } from '@/utils/request'

// 状态栏高度
const statusBarHeight = ref(0)
const scrollHeight = ref(0)
// #ifdef MP-WEIXIN
try {
  const info = uni.getSystemInfoSync()
  const sb = info.statusBarHeight || 0
  statusBarHeight.value = sb
  if (typeof uni.getMenuButtonBoundingClientRect === 'function') {
    const m = uni.getMenuButtonBoundingClientRect()
    if (m && m.top) statusBarHeight.value = m.top
  }
  scrollHeight.value = info.windowHeight - 100 || 500
} catch (e) { statusBarHeight.value = 44; scrollHeight.value = 500 }
// #endif
// #ifndef MP-WEIXIN
onMounted(() => {
  uni.getSystemInfo({ success: (sys) => { scrollHeight.value = sys.windowHeight - 100 || 500 } })
  init()
})
// #endif
// #ifdef MP-WEIXIN
init()
// #endif

// 用户信息
const userInfo = ref({})
const nameInitial = computed(() => (userInfo.value.real_name || userInfo.value.name || '员').substring(0, 1))

// 模式：apply 发起 / mine 我的
const mode = ref('apply')
function switchMode(m) {
  mode.value = m
  if (m === 'mine') loadMine(false)
}

// 表单
const form = ref({ id: 0, category: '', amount: '', purpose: '', vouchers: [] })
const detailVouchers = ref([])
const categoryOptions = ref(['差旅费', '交通费', '餐饮费', '办公用品', '业务招待', '通讯费', '住宿费', '培训费', '维修费', '其他'])

function onCategoryChange(e) {
  form.value.category = categoryOptions.value[Number(e.detail.value)] || ''
}

// 我的报销列表
const mineList = ref([])
const mineLoading = ref(false)
const statusFilter = ref('')
const page = ref(1)
const pageSize = 15
const total = ref(0)
const hasMore = computed(() => mineList.value.length < total.value)

function changeStatus(s) {
  statusFilter.value = s
  loadMine(false)
}

async function loadMine(append) {
  mineLoading.value = true
  try {
    if (!append) { page.value = 1 }
    const r = await request({
      url: '/api/expense/my',
      method: 'GET',
      data: { status: statusFilter.value, page: page.value, pageSize }
    })
    if (r.code === 0 && r.data) {
      total.value = r.data.total || 0
      const list = r.data.list || []
      if (append) mineList.value = mineList.value.concat(list)
      else mineList.value = list
      page.value += 1
    }
  } catch (e) {} finally { mineLoading.value = false }
}

// ===== 凭证上传 =====
function chooseVoucher() {
  if (form.value.vouchers.length >= 5) { uni.showToast({ title: '最多上传5张凭证', icon: 'none' }); return }
  uni.chooseImage({
    count: 5 - form.value.vouchers.length,
    sizeType: ['compressed'],
    success: (res) => {
      const files = res.tempFilePaths || []
      if (files.length) uploadVouchers(files)
    }
  })
}
async function uploadVouchers(files) {
  uni.showLoading({ title: '上传中...' })
  for (const fp of files) {
    try {
      const url = await uploadOne(fp)
      form.value.vouchers.push(url)
    } catch (e) {
      uni.showToast({ title: e.message || '上传失败', icon: 'none' })
    }
  }
  uni.hideLoading()
}
function uploadOne(filePath) {
  return new Promise((resolve, reject) => {
    uni.uploadFile({
      url: (uni.$base || '') + '/api/upload',
      filePath,
      name: 'file',
      header: { 'Authorization': 'Bearer ' + (uni.getStorageSync('access_token') || '') },
      success: (res) => {
        try {
          const d = JSON.parse(res.data)
          if (d.code === 0 && d.data && d.data.url) resolve(d.data.url)
          else reject(new Error(d.msg || '上传失败'))
        } catch (e) { reject(new Error('上传响应异常')) }
      },
      fail: () => reject(new Error('网络异常，请重试'))
    })
  })
}
function previewVoucher(url) {
  uni.previewImage({ urls: form.value.vouchers, current: url })
}
function removeVoucher(i) { form.value.vouchers.splice(i, 1) }
function previewDetailVoucher(i) {
  uni.previewImage({ urls: detailVouchers.value, current: detailVouchers.value[i] })
}

// 提交
async function submitExp(submit) {
  if (!form.value.category) { uni.showToast({ title: '请选择报销科目', icon: 'none' }); return }
  const amount = parseFloat(form.value.amount)
  if (!amount || amount <= 0) { uni.showToast({ title: '请输入有效金额', icon: 'none' }); return }
  if (!form.value.purpose.trim()) { uni.showToast({ title: '请填写报销事由', icon: 'none' }); return }

  uni.showLoading({ title: submit ? '提交中...' : '保存中...' })
  try {
    const r = await request({
      url: '/api/expense/submit',
      method: 'POST',
      data: {
        id: form.value.id,
        category: form.value.category,
        amount,
        purpose: form.value.purpose.trim(),
        vouchers: form.value.vouchers,
        submit: submit ? 1 : 0
      }
    })
    uni.hideLoading()
    if (r.code === 0) {
      uni.showToast({ title: r.msg || (submit ? '已提交审批' : '已保存草稿'), icon: 'none' })
      form.value = { id: 0, category: '', amount: '', purpose: '', vouchers: [] }
      if (submit) {
        setTimeout(() => { switchMode('mine'); loadMine(false) }, 1200)
      }
    } else {
      uni.showToast({ title: r.msg || '提交失败', icon: 'none' })
    }
  } catch (e) {
    uni.hideLoading()
    uni.showToast({ title: '网络异常，请重试', icon: 'none' })
  }
}

// 详情
const detailVisible = ref(false)
const detailRows = ref([])
const detailHistories = ref([])

async function openDetail(item) {
  uni.showLoading({ title: '加载中...' })
  try {
    const r = await request({ url: '/api/expense/detail/' + item.id, method: 'GET' })
    uni.hideLoading()
    if (r.code === 0 && r.data) {
      const d = r.data.detail || {}
      detailRows.value = [
        { label: '报销单号', value: d.expense_no || '-', strong: true },
        { label: '申请人', value: d.applicant_name || '-' },
        { label: '部门', value: d.department_name || '-' },
        { label: '报销科目', value: d.category || '-' },
        { label: '报销金额', value: '¥' + Number(d.amount).toLocaleString(), strong: true },
        { label: '报销事由', value: d.purpose || '-' },
        { label: '状态', value: d.status_text || '-' },
        { label: '打款状态', value: d.pay_status_text || '-' },
        { label: '打款方式', value: d.pay_method_text || '-' },
        { label: '申请时间', value: d.created_at || '-' }
      ]
      detailVouchers.value = (d.vouchers && Array.isArray(d.vouchers)) ? d.vouchers : []
      detailHistories.value = r.data.histories || []
      detailVisible.value = true
    } else {
      uni.showToast({ title: r.msg || '加载失败', icon: 'none' })
    }
  } catch (e) {
    uni.hideLoading()
    uni.showToast({ title: '网络异常', icon: 'none' })
  }
}

// 初始化
async function init() {
  try {
    const r = await request({ url: '/api/user/profile', method: 'GET' })
    if (r.code === 0 && r.data) {
      const d = r.data
      userInfo.value = {
        name: d.name || d.username || '',
        real_name: d.real_name || d.name || '',
        avatar: d.avatar || '',
        department: d.department || '',
        position: d.position || ''
      }
    }
  } catch (e) {}
  try {
    const c = await request({ url: '/api/expense/categories', method: 'GET' })
    if (c.code === 0 && c.data && Array.isArray(c.data.list) && c.data.list.length) {
      categoryOptions.value = c.data.list
    }
  } catch (e) {}
}

function goBack() { uni.navigateBack() }
</script>

<style scoped>
.exp-page { min-height: 100vh; background: #F4F6FB; display: flex; flex-direction: column; }
.exp-nav { padding: 10px 16px 8px; background: #fff; }
.exp-nav-left { display: flex; align-items: center; gap: 10px; }
.exp-back { display: flex; align-items: center; gap: 4px; padding: 4px 8px; border-radius: 24px; cursor: pointer; }
.exp-back-text { font-size: 14px; font-weight: 500; color: #1a2332; }
.exp-nav-title { font-size: 17px; font-weight: 600; color: #1a2332; flex: 1; text-align: center; margin-right: 44px; }
.exp-scroll { flex: 1; overflow-y: auto; }

/* 类型切换 */
.exp-tabs { display: flex; background: #fff; padding: 8px 16px 0; gap: 24px; border-bottom: 1px solid #f0f2f5; }
.exp-tab { font-size: 15px; color: #8a9aa8; padding: 8px 2px 10px; position: relative; cursor: pointer; }
.exp-tab.active { color: #4F46E5; font-weight: 600; }
.exp-tab.active::after { content: ''; position: absolute; left: 0; right: 0; bottom: 0; height: 3px; border-radius: 3px; background: #4F46E5; }

/* 发起报销 */
.exp-form { padding: 16px 16px 8px; }
.exp-info-card { background: #fff; border-radius: 16px; padding: 16px 18px; margin-bottom: 16px; display: flex; align-items: center; gap: 14px; box-shadow: 0 1px 4px rgba(0,0,0,.04); }
.exp-avatar { width: 48px; height: 48px; border-radius: 50%; background: linear-gradient(135deg, #4F46E5, #7C6FF0); display: flex; align-items: center; justify-content: center; font-size: 18px; font-weight: 600; color: #fff; flex-shrink: 0; overflow: hidden; }
.exp-avatar-img { width: 100%; height: 100%; }
.exp-info { flex: 1; min-width: 0; }
.exp-name { font-size: 16px; font-weight: 600; color: #1a2332; display: block; }
.exp-dept { font-size: 13px; color: #8a9aa8; margin-top: 2px; display: block; }
.exp-status-online { font-size: 12px; color: #34c759; font-weight: 500; flex-shrink: 0; }

.exp-form-group { margin-bottom: 16px; }
.exp-label { font-size: 14px; font-weight: 500; color: #1a2332; margin-bottom: 8px; display: flex; align-items: center; gap: 4px; }
.exp-required { color: #fb6e8c; font-size: 16px; }
.exp-input-wrap { background: #fff; border-radius: 12px; padding: 0 16px; border: 1px solid #eef0f3; display: flex; align-items: center; gap: 10px; min-height: 48px; box-shadow: 0 1px 4px rgba(0,0,0,.03); }
.exp-input { flex: 1; padding: 14px 0; font-size: 15px; color: #1a2332; border: none; background: transparent; }
.exp-input-text { flex: 1; padding: 14px 0; font-size: 15px; color: #1a2332; }
.exp-input-text.placeholder { color: #c0cedc; }
.exp-textarea-wrap { display: flex; align-items: flex-start; gap: 10px; background: #fff; border-radius: 12px; padding: 12px 16px; border: 1px solid #eef0f3; box-shadow: 0 1px 4px rgba(0,0,0,.03); }
.exp-textarea { flex: 1; min-height: 80px; font-size: 15px; color: #1a2332; border: none; background: transparent; }

/* 审批流程 */
.exp-flow-card { background: #fff; border-radius: 16px; padding: 16px 18px; margin-bottom: 16px; box-shadow: 0 1px 4px rgba(0,0,0,.04); }
.exp-flow-title { font-size: 14px; font-weight: 500; color: #1a2332; margin-bottom: 12px; display: flex; align-items: center; gap: 8px; }
.exp-flow-step { display: flex; align-items: center; gap: 12px; padding: 6px 0; position: relative; }
.exp-flow-step:not(:last-child)::after { content: ''; position: absolute; left: 14px; top: 34px; width: 2px; height: 20px; background: #d5dce4; }
.exp-step-dot { width: 28px; height: 28px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 600; color: #fff; flex-shrink: 0; position: relative; z-index: 1; }
.exp-step-dot.done { background: #34c759; }
.exp-step-dot.active { background: #4F46E5; }
.exp-step-dot.waiting { background: #d5dce4; }
.exp-step-info { flex: 1; }
.exp-step-name { font-size: 14px; font-weight: 500; color: #1a2332; display: block; }
.exp-step-desc { font-size: 12px; color: #9aabba; margin-top: 1px; display: block; }
.exp-step-status { font-size: 12px; font-weight: 500; }
.exp-step-status.done { color: #34c759; }
.exp-step-status.active { color: #4F46E5; }
.exp-step-status.waiting { color: #b0c0cc; }

/* 提交按钮 */
.exp-submit-section { display: flex; gap: 12px; padding: 4px 0 8px; }
.exp-submit-btn { flex: 1; padding: 16px; border-radius: 12px; background: linear-gradient(135deg, #4F46E5, #7C6FF0); color: #fff; font-size: 16px; font-weight: 600; cursor: pointer; box-shadow: 0 4px 16px rgba(110,142,251,0.15); display: flex; align-items: center; justify-content: center; gap: 10px; }
.exp-submit-btn.ghost { background: #fff; color: #4F46E5; border: 1px solid rgba(110,142,251,0.3); box-shadow: none; }
.exp-submit-btn:active { transform: scale(0.97); }

/* 我的报销 */
.exp-mine { padding: 12px 16px 16px; }
.exp-status-filter { display: flex; gap: 8px; margin-bottom: 12px; flex-wrap: wrap; }
.exp-status-item { padding: 6px 14px; border-radius: 30px; background: #fff; font-size: 13px; color: #4a5a6a; cursor: pointer; border: 1px solid #eef0f3; }
.exp-status-item.active { background: rgba(110,142,251,0.08); border-color: rgba(110,142,251,0.3); color: #4F46E5; font-weight: 500; }
.exp-empty { text-align: center; padding: 60px 0; color: #b0c0cc; }
.exp-empty-text { display: block; margin-top: 10px; font-size: 13px; }
.exp-item { background: #fff; border-radius: 14px; padding: 14px 16px; margin-bottom: 10px; box-shadow: 0 1px 4px rgba(0,0,0,.04); cursor: pointer; }
.exp-item-top { display: flex; justify-content: space-between; align-items: center; }
.exp-item-cat { font-size: 15px; font-weight: 600; color: #1a2332; }
.exp-item-amount { font-size: 16px; font-weight: 700; color: #4F46E5; }
.exp-item-desc { font-size: 13px; color: #5a6a7a; margin: 6px 0 8px; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.exp-item-bottom { display: flex; justify-content: space-between; align-items: center; }
.exp-item-no { font-size: 11px; color: #b0c0cc; }
.exp-item-tags { display: flex; gap: 6px; }
.exp-tag { font-size: 10px; padding: 1px 8px; border-radius: 30px; font-weight: 500; }
.exp-tag.tag-info { background: #f2f4f7; color: #8a9aa8; }
.exp-tag.tag-warning { background: rgba(251,170,80,0.1); color: #fbaa50; }
.exp-tag.tag-success { background: rgba(52,199,89,0.1); color: #34c759; }
.exp-tag.tag-danger { background: rgba(251,110,140,0.1); color: #fb6e8c; }
.exp-tag.tag-warn { background: rgba(251,170,80,0.1); color: #fbaa50; }
.exp-load-more { text-align: center; color: #b0c0cc; font-size: 13px; padding: 12px 0; }

/* 详情弹层 */
.exp-detail-mask { position: fixed; left: 0; top: 0; right: 0; bottom: 0; background: rgba(0,0,0,.45); z-index: 999; display: flex; align-items: flex-end; }
.exp-detail { width: 100%; background: #fff; border-radius: 20px 20px 0 0; max-height: 80vh; display: flex; flex-direction: column; }
.exp-detail-head { display: flex; justify-content: space-between; align-items: center; padding: 16px 18px 10px; }
.exp-detail-title { font-size: 16px; font-weight: 600; color: #1a2332; }
.exp-detail-body { padding: 0 18px 24px; max-height: 60vh; }
.exp-detail-row { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #f5f6f8; }
.exp-detail-label { font-size: 13px; color: #8a9aa8; flex-shrink: 0; }
.exp-detail-value { font-size: 13px; color: #1a2332; text-align: right; flex: 1; margin-left: 16px; word-break: break-all; }
.exp-detail-value.strong { font-weight: 600; color: #4F46E5; }
.exp-optional { font-size: 11px; color: #b0c0cc; font-weight: 400; }
.exp-vouchers { display: flex; flex-wrap: wrap; gap: 10px; }
.exp-voucher { width: 74px; height: 74px; border-radius: 10px; overflow: hidden; position: relative; background: #f5f6f8; }
.exp-voucher-img { width: 100%; height: 100%; display: block; }
.exp-voucher-del { position: absolute; top: 0; right: 0; width: 20px; height: 20px; background: rgba(0,0,0,.55); color: #fff; font-size: 13px; display: flex; align-items: center; justify-content: center; border-radius: 0 0 0 8px; }
.exp-voucher-add { width: 74px; height: 74px; border: 1px dashed #d0d8e4; border-radius: 10px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 4px; background: #f8fafc; }
.exp-voucher-add-text { font-size: 10px; color: #b0c0cc; }
.exp-detail-vouchers { display: flex; flex-wrap: wrap; gap: 8px; }
.exp-detail-voucher { width: 72px; height: 72px; border-radius: 8px; background: #f5f6f8; }
.exp-detail-sub { font-size: 14px; font-weight: 600; color: #1a2332; margin: 16px 0 8px; }
.exp-history-empty { font-size: 13px; color: #b0c0cc; text-align: center; padding: 16px 0; }
.exp-history-item { display: flex; gap: 12px; padding: 8px 0; }
.exp-history-dot { width: 10px; height: 10px; border-radius: 50%; background: #d5dce4; margin-top: 5px; flex-shrink: 0; }
.exp-history-dot.done { background: #34c759; }
.exp-history-dot.fail { background: #fb6e8c; }
.exp-history-info { flex: 1; }
.exp-history-action { font-size: 13px; color: #1a2332; display: block; }
.exp-history-time { font-size: 11px; color: #b0c0cc; margin-top: 2px; display: block; }
</style>
