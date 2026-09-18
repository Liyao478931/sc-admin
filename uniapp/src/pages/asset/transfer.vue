<template>
  <view class="tf-page">
    <!-- 资产信息 -->
    <view class="tf-section">
      <text class="tf-label">调拨资产</text>
      <view class="tf-asset-box">
        <view class="tf-asset-left">
          <text class="tf-asset-name">{{ asset.asset_name || '加载中...' }}</text>
          <text class="tf-asset-spec">{{ asset.specification || '' }}</text>
        </view>
        <text class="tf-asset-qty">{{ asset.quantity || 0 }} {{ asset.unit }}</text>
      </view>
      <text class="tf-hint">编码：{{ asset.asset_code || '-' }}</text>
    </view>

    <!-- 调拨对象 -->
    <view class="tf-section">
      <text class="tf-label">调拨对象 <text class="required">*</text></text>
      <view class="tf-search" @click="empPickerOpen = true">
        <u-icon name="search" color="#b0c0cc" size="15" />
        <text class="tf-search-text" :class="{ placeholder: !targetUser.user_id }">{{ targetUser.name || '搜索选择员工' }}</text>
        <u-icon name="arrow-right" color="#c0cedc" size="13" />
      </view>
      <text class="tf-hint">将资产调拨给指定员工，待对方确认后完成调拨</text>
    </view>

    <!-- 调拨数量 -->
    <view class="tf-section">
      <text class="tf-label">调拨数量 <text class="required">*</text></text>
      <view class="tf-qty-row">
        <view class="tf-qty-btn" @click="changeQty(-1)"><u-icon name="minus" color="#8a9aa8" size="13" /></view>
        <u-input v-model.number="quantity" type="number" border="none" :customStyle="{ height: '72rpx', fontSize: '28rpx' }" />
        <view class="tf-qty-btn" @click="changeQty(1)"><u-icon name="plus" color="#8a9aa8" size="13" /></view>
        <text class="tf-hint">可调拨：{{ asset.quantity || 0 }} {{ asset.unit }}</text>
      </view>
    </view>

    <!-- 调拨说明 -->
    <view class="tf-section">
      <text class="tf-label">调拨说明</text>
      <u-textarea v-model="remark" placeholder="选填，如：协助维修使用" maxlength="200" />
    </view>

    <!-- 提交 -->
    <view class="tf-actions">
      <view class="tf-btn cancel" @click="uni.navigateBack()">取消</view>
      <view class="tf-btn submit" :class="{ disabled: submitting }" @click="submitTransfer">{{ submitting ? '提交中...' : '确认调拨' }}</view>
    </view>

    <!-- 员工选择弹窗 -->
    <u-popup :show="empPickerOpen" mode="bottom" round="24" @close="empPickerOpen = false">
      <view class="tf-sheet">
        <view class="tf-sheet-head">
          <text class="tf-sheet-title">选择调拨对象</text>
          <u-icon name="close" color="#b0c0cc" size="16" @click="empPickerOpen = false" />
        </view>
        <view class="tf-search-input">
          <u-icon name="search" color="#b0c0cc" size="15" />
          <u-input v-model="empKeyword" placeholder="搜索员工姓名/工号" prefixIcon="search" border="none" :customStyle="{ height: '72rpx', fontSize: '26rpx' }" @input="loadEmployees" />
        </view>
        <scroll-view scroll-y class="tf-emp-list">
          <view v-for="e in empList" :key="e.user_id" class="tf-emp-item" :class="{ active: targetUser.user_id === e.user_id }" @click="pickEmp(e)">
            <view class="tf-emp-info">
              <text class="tf-emp-name">{{ e.name }}</text>
              <text class="tf-emp-meta">{{ e.employee_id || '-' }}</text>
            </view>
            <u-icon v-if="targetUser.user_id === e.user_id" name="checkmark-circle-fill" color="#4F46E5" size="16" />
          </view>
          <view v-if="!empList.length" class="tf-emp-empty">暂无匹配员工</view>
        </scroll-view>
      </view>
    </u-popup>
  </view>
</template>

<script setup>
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'

const asset = ref({})
const targetUser = ref({})
const quantity = ref(1)
const remark = ref('')
const submitting = ref(false)
const empPickerOpen = ref(false)
const empKeyword = ref('')
const empList = ref([])

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
function changeQty(d) {
  quantity.value = Math.max(1, Math.min(Number(asset.value.quantity || 1), (Number(quantity.value) || 1) + d))
}
async function loadEmployees() {
  try {
    const r = await api('/api/personal-assets/employee-options', 'GET', { keyword: empKeyword.value })
    empList.value = r || []
  } catch (e) { empList.value = [] }
}
function pickEmp(e) {
  targetUser.value = e
  empPickerOpen.value = false
}
async function submitTransfer() {
  if (!targetUser.value.user_id) { uni.showToast({ title: '请选择调拨对象', icon: 'none' }); return }
  if (!quantity.value || quantity.value <= 0) { uni.showToast({ title: '请输入有效的调拨数量', icon: 'none' }); return }
  if (quantity.value > Number(asset.value.quantity)) { uni.showToast({ title: '调拨数量不能超过可用数量', icon: 'none' }); return }
  submitting.value = true
  try {
    await api('/api/personal-assets/transfer-create', 'POST', {
      asset_id: asset.value.id,
      target_user_id: targetUser.value.user_id,
      quantity: quantity.value,
      remark: remark.value
    })
    uni.showToast({ title: '调拨已发起，等待对方确认', icon: 'success' })
    setTimeout(() => uni.navigateBack(), 1200)
  } catch (e) {
    uni.showToast({ title: e.msg || '调拨失败', icon: 'none' })
  }
  submitting.value = false
}

onLoad(async (options) => {
  const assetId = Number(options.asset_id || 0)
  if (!assetId) { uni.showToast({ title: '参数错误', icon: 'none' }); return }
  try {
    const r = await api('/api/personal-assets/detail/' + assetId)
    asset.value = r || {}
  } catch (e) {
    uni.showToast({ title: '资产加载失败', icon: 'none' })
  }
})
</script>

<style scoped>
.tf-page { min-height: 100vh; background: #F4F6FB; padding: 16px; box-sizing: border-box; }
.tf-section { background: #fff; border-radius:124px; padding: 16px; margin-bottom: 12px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.tf-label { font-size: 14px; font-weight: 600; color: #1a2332; margin-bottom: 10px; display: block; }
.required { color: #F56C6C; }
.tf-asset-box { display: flex; align-items: center; justify-content: space-between; background: rgba(110,142,251,0.04); border: 1px solid rgba(110,142,251,0.08); border-radius:24px; padding: 12px 16px; }
.tf-asset-name { font-size: 15px; font-weight: 600; color: #1a2332; }
.tf-asset-spec { font-size: 13px; color: #8a9aa8; margin-left: 6px; }
.tf-asset-qty { font-size: 15px; font-weight: 600; color: #409EFF; }
.tf-hint { font-size: 12px; color: #b0c0cc; margin-top: 6px; display: block; }
.tf-search { display: flex; align-items: center; gap: 8px; background: #f5f6fa; border-radius:24px; padding: 12px 14px; }
.tf-search-text { flex: 1; font-size: 14px; color: #1a2332; }
.tf-search-text.placeholder { color: #b0c0cc; }
.tf-qty-row { display: flex; align-items: center; gap: 8px; }
.tf-qty-btn { width: 40px; height: 40px; border-radius:22px; background: #f5f6fa; display: flex; align-items: center; justify-content: center; }
.tf-qty-input { flex: 1; text-align: center; font-size: 18px; font-weight: 700; background: #f5f6fa; border-radius:22px; padding: 8px; }
.tf-textarea { width: 100%; min-height: 80px; background: #f5f6fa; border-radius:24px; padding: 12px 14px; font-size: 14px; box-sizing: border-box; }
.tf-actions { display: flex; gap: 12px; margin-top: 8px; }
.tf-btn { flex: 1; text-align: center; padding: 14px; border-radius:124px; font-size: 16px; font-weight: 600; }
.tf-btn.cancel { background: #f5f6fa; color: #8a9aa8; }
.tf-btn.submit { background: linear-gradient(135deg, #4F46E5, #7C6FF0); color: #fff; }
.tf-btn.disabled { opacity: 0.6; }
.tf-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.3); z-index: 100; display: flex; align-items: flex-end; }
.tf-sheet { width: 100%; background: #fff; border-radius:224px 224px 0 0; padding: 20px 20px 32px; max-height: 70vh; display: flex; flex-direction: column;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.tf-sheet-head { display: flex; align-items: center; justify-content: space-between; padding-bottom: 12px; }
.tf-sheet-title { font-size: 17px; font-weight: 700; color: #1a2332; }
.tf-search-input { display: flex; align-items: center; gap: 6px; background: #f5f6fa; border-radius:24px; padding: 10px 14px; margin-bottom: 10px; }
.tf-search-field { flex: 1; font-size: 14px; }
.tf-emp-list { max-height: 45vh; }
.tf-emp-item { display: flex; align-items: center; justify-content: space-between; padding: 13px 16px; border-bottom: 1px solid #F4F6FB; }
.tf-emp-item.active { background: #f0f4ff; }
.tf-emp-name { font-size: 15px; font-weight: 600; color: #1a2332; }
.tf-emp-meta { font-size: 12px; color: #9ca3af; margin-left: 8px; }
.tf-emp-empty { text-align: center; color: #b0c0cc; padding: 40px 0; font-size: 13px; }
</style>