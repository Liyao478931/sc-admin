<template>
  <view class="rt-page">
    <!-- 资产信息 -->
    <view class="rt-section">
      <text class="rt-label">退还资产</text>
      <view class="rt-asset-box">
        <view class="rt-asset-left">
          <text class="rt-asset-name">{{ asset.asset_name || '加载中...' }}</text>
          <text class="rt-asset-spec">{{ asset.specification || '' }}</text>
        </view>
        <text class="rt-asset-qty">{{ asset.quantity || 0 }} {{ asset.unit }}</text>
      </view>
      <text class="rt-hint">编码：{{ asset.asset_code || '-' }}</text>
    </view>

    <!-- 退还数量 -->
    <view class="rt-section">
      <text class="rt-label">退还数量 <text class="required">*</text></text>
      <view class="rt-qty-row">
        <view class="rt-qty-btn" @click="changeQty(-1)"><u-icon name="minus" color="#8a9aa8" size="13" /></view>
        <u-input v-model.number="quantity" type="number" border="none" :customStyle="{ height: '72rpx', fontSize: '28rpx' }" />
        <view class="rt-qty-btn" @click="changeQty(1)"><u-icon name="plus" color="#8a9aa8" size="13" /></view>
        <text class="rt-hint">可退还：{{ asset.quantity || 0 }} {{ asset.unit }}</text>
      </view>
    </view>

    <!-- 退还原因 -->
    <view class="rt-section">
      <text class="rt-label">退还原因 <text class="required">*</text></text>
      <u-textarea v-model="reason" placeholder="请说明退还原因（必填）" maxlength="200" />
    </view>

    <!-- 提示 -->
    <view class="rt-tip-box">
      <u-icon name="info-circle" color="#4F46E5" size="15" />
      <text>提交后将由资产管理员审批，审批通过后资产将退还至总仓库。</text>
    </view>

    <!-- 提交 -->
    <view class="rt-actions">
      <view class="rt-btn cancel" @click="uni.navigateBack()">取消</view>
      <view class="rt-btn submit" :class="{ disabled: submitting }" @click="submitReturn">{{ submitting ? '提交中...' : '提交申请' }}</view>
    </view>
  </view>
</template>

<script setup>
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'

const asset = ref({})
const quantity = ref(1)
const reason = ref('')
const submitting = ref(false)

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
async function submitReturn() {
  if (!quantity.value || quantity.value <= 0) { uni.showToast({ title: '请输入有效的退还数量', icon: 'none' }); return }
  if (quantity.value > Number(asset.value.quantity)) { uni.showToast({ title: '退还数量不能超过可用数量', icon: 'none' }); return }
  if (!reason.value) { uni.showToast({ title: '请填写退还原因', icon: 'none' }); return }
  submitting.value = true
  try {
    await api('/api/personal-assets/return-submit', 'POST', {
      asset_id: asset.value.id,
      return_quantity: quantity.value,
      reason: reason.value,
      photo: ''
    })
    uni.showToast({ title: '申请已提交，等待管理员审批', icon: 'success' })
    setTimeout(() => uni.navigateBack(), 1200)
  } catch (e) {
    uni.showToast({ title: e.msg || '提交失败', icon: 'none' })
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
.rt-page { min-height: 100vh; background: #F4F6FB; padding: 16px; box-sizing: border-box; }
.rt-section { background: #fff; border-radius:124px; padding: 16px; margin-bottom: 12px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.rt-label { font-size: 14px; font-weight: 600; color: #1a2332; margin-bottom: 10px; display: block; }
.required { color: #F56C6C; }
.rt-asset-box { display: flex; align-items: center; justify-content: space-between; background: rgba(110,142,251,0.04); border: 1px solid rgba(110,142,251,0.08); border-radius:24px; padding: 12px 16px; }
.rt-asset-name { font-size: 15px; font-weight: 600; color: #1a2332; }
.rt-asset-spec { font-size: 13px; color: #8a9aa8; margin-left: 6px; }
.rt-asset-qty { font-size: 15px; font-weight: 600; color: #409EFF; }
.rt-hint { font-size: 12px; color: #b0c0cc; margin-top: 6px; display: block; }
.rt-qty-row { display: flex; align-items: center; gap: 8px; }
.rt-qty-btn { width: 40px; height: 40px; border-radius:22px; background: #f5f6fa; display: flex; align-items: center; justify-content: center; }
.rt-qty-input { flex: 1; text-align: center; font-size: 18px; font-weight: 700; background: #f5f6fa; border-radius:22px; padding: 8px; }
.rt-textarea { width: 100%; min-height: 80px; background: #f5f6fa; border-radius:24px; padding: 12px 14px; font-size: 14px; box-sizing: border-box; }
.rt-tip-box { display: flex; align-items: flex-start; gap: 8px; background: #ecf5ff; border: 1px solid #d9ecff; border-radius:24px; padding: 12px 14px; margin-bottom: 12px; font-size: 13px; color: #5a6b7f; }
.rt-actions { display: flex; gap: 12px; margin-top: 8px; }
.rt-btn { flex: 1; text-align: center; padding: 14px; border-radius:124px; font-size: 16px; font-weight: 600; }
.rt-btn.cancel { background: #f5f6fa; color: #8a9aa8; }
.rt-btn.submit { background: linear-gradient(135deg, #4F46E5, #7C6FF0); color: #fff; }
.rt-btn.disabled { opacity: 0.6; }
</style>