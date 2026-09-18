<template>
  <view class="ad-page">
    <view v-if="loading" class="ad-loading">加载中...</view>
    <template v-else-if="detail.id">
      <!-- 基本信息 -->
      <view class="ad-section">
        <view class="ad-header">
          <view class="ad-header-left">
            <text class="ad-name">{{ detail.asset_name }}</text>
            <text class="ad-spec">{{ detail.specification || '-' }}</text>
            <text class="ad-code">编码：{{ detail.asset_code || '-' }}</text>
          </view>
        </view>
        <view class="ad-tags">
          <text class="ad-tag" :class="'type-' + detail.asset_type">{{ detail.asset_type_label }}</text>
          <text class="ad-tag" :class="'st-' + detail.asset_status">{{ detail.asset_status_label }}</text>
        </view>
      </view>

      <!-- 数量信息 -->
      <view class="ad-section">
        <text class="ad-sec-title">数量信息</text>
        <view class="ad-grid">
          <view class="ad-item"><text class="ad-lb">当前数量</text><text class="ad-val blue">{{ detail.quantity }} {{ detail.unit }}</text></view>
          <view class="ad-item"><text class="ad-lb">初始数量</text><text class="ad-val">{{ detail.initial_quantity }}</text></view>
        </view>
      </view>

      <!-- 来源信息 -->
      <view class="ad-section">
        <text class="ad-sec-title">来源信息</text>
        <view class="ad-grid">
          <view class="ad-item"><text class="ad-lb">来源类型</text><text class="ad-val">{{ detail.source_type_label }}</text></view>
          <view class="ad-item"><text class="ad-lb">来源单号</text><text class="ad-val">{{ detail.source_no || '-' }}</text></view>
          <view class="ad-item"><text class="ad-lb">入库时间</text><text class="ad-val">{{ String(detail.created_at).slice(0, 10) }}</text></view>
          <view class="ad-item"><text class="ad-lb">存放位置</text><text class="ad-val">{{ detail.location || '未设置' }}</text></view>
        </view>
      </view>

      <!-- 采购信息（如有） -->
      <view v-if="detail.supplier_name || detail.purchase_order_no" class="ad-section">
        <text class="ad-sec-title">采购信息</text>
        <view class="ad-grid">
          <view class="ad-item"><text class="ad-lb">供应商</text><text class="ad-val">{{ detail.supplier_name || '-' }}</text></view>
          <view class="ad-item"><text class="ad-lb">采购单号</text><text class="ad-val">{{ detail.purchase_order_no || '-' }}</text></view>
          <view v-if="detail.warranty_end_date" class="ad-item"><text class="ad-lb">保修截止</text><text class="ad-val">{{ detail.warranty_end_date }}</text></view>
        </view>
      </view>

      <!-- 资产价值（固定资产） -->
      <view v-if="Number(detail.asset_type) === 2" class="ad-section">
        <text class="ad-sec-title">资产价值</text>
        <view class="ad-grid">
          <view class="ad-item"><text class="ad-lb">原值</text><text class="ad-val">¥{{ formatMoney(detail.original_value) }}</text></view>
          <view v-if="detail.asset_status_label" class="ad-item"><text class="ad-lb">当前状态</text><text class="ad-val">{{ detail.asset_status_label }}</text></view>
        </view>
      </view>

      <view v-if="detail.remark" class="ad-section">
        <text class="ad-sec-title">备注</text>
        <text class="ad-remark">{{ detail.remark }}</text>
      </view>

      <!-- 操作按钮 -->
      <view v-if="Number(detail.asset_status) !== 5" class="ad-actions">
        <view class="ad-action transfer" @click="goTransfer"><u-icon name="rmb-circle" color="#409EFF" size="14" /><text>调拨</text></view>
        <view class="ad-action return" @click="goReturn"><u-icon name="reload" color="#F56C6C" size="14" /><text>退还</text></view>
      </view>
      <view v-else class="ad-scrap-tip">该资产已报废，不可操作</view>
    </template>
    <view v-else class="ad-loading">资产不存在</view>
  </view>
</template>

<script setup>
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'

const detail = ref({})
const loading = ref(false)

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
function formatMoney(v) {
  return Number(v || 0).toLocaleString('zh-CN', { maximumFractionDigits: 2 })
}
function goTransfer() {
  uni.navigateTo({ url: '/pages/asset/transfer?asset_id=' + detail.value.id })
}
function goReturn() {
  uni.navigateTo({ url: '/pages/asset/return?asset_id=' + detail.value.id })
}

onLoad(async (options) => {
  const id = Number(options.id || 0)
  if (!id) return
  loading.value = true
  try {
    const r = await api('/api/personal-assets/detail/' + id)
    detail.value = r || {}
  } catch (e) {
    uni.showToast({ title: e.msg || '加载失败', icon: 'none' })
  }
  loading.value = false
})
</script>

<style scoped>
.ad-page { min-height: 100vh; background: #F4F6FB; padding: 16px; box-sizing: border-box; }
.ad-loading { text-align: center; color: #b0c0cc; padding: 60px 0; font-size: 14px; }
.ad-section { background: #fff; border-radius:124px; padding: 16px; margin-bottom: 12px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.ad-header { display: flex; justify-content: space-between; align-items: flex-start; }
.ad-name { font-size: 20px; font-weight: 700; color: #1a2332; display: block; }
.ad-spec { font-size: 14px; color: #8a9aa8; display: block; margin-top: 2px; }
.ad-code { font-size: 13px; color: #b0c0cc; display: block; margin-top: 4px; }
.ad-tags { display: flex; gap: 6px; margin-top: 12px; }
.ad-tag { font-size: 11px; font-weight: 500; padding: 2px 14px; border-radius:30px; line-height: 24px; }
.ad-tag.type-1 { background: #FFF3E0; color: #E65100; }
.ad-tag.type-2 { background: #E3F2FD; color: #0D47A1; }
.ad-tag.type-3 { background: #F3E5F5; color: #6A1B9A; }
.ad-tag.st-1 { background: #E8F5E9; color: #2E7D32; }
.ad-tag.st-2 { background: #FFF3E0; color: #E65100; }
.ad-tag.st-3 { background: #F3E5F5; color: #6A1B9A; }
.ad-tag.st-4 { background: #FFEBEE; color: #C62828; }
.ad-tag.st-5 { background: #E0E0E0; color: #757575; }
.ad-sec-title { font-size: 14px; font-weight: 600; color: #1a2332; margin-bottom: 10px; display: block; }
.ad-grid { display: flex; flex-wrap: wrap; gap: 12px; }
.ad-item { flex: 1 1 45%; display: flex; align-items: center; gap: 8px; background: #fafbfc; border-radius:22px; padding: 10px 12px; }
.ad-lb { font-size: 11px; color: #b0c0cc; flex-shrink: 0; }
.ad-val { font-size: 14px; font-weight: 600; color: #1a2332; }
.ad-val.blue { color: #409EFF; }
.ad-remark { font-size: 13px; color: #4a5a6a; line-height: 1.7; }
.ad-actions { display: flex; gap: 10px; margin-top: 4px; }
.ad-action { flex: 1; display: flex; align-items: center; justify-content: center; gap: 6px; padding: 14px; border-radius:124px; font-size: 15px; font-weight: 600; }
.ad-action.transfer { background: rgba(64,158,255,0.08); color: #409EFF; border: 1px solid rgba(64,158,255,0.15); }
.ad-action.return { background: rgba(245,108,108,0.08); color: #F56C6C; border: 1px solid rgba(245,108,108,0.15); }
.ad-scrap-tip { text-align: center; color: #b0c0cc; font-size: 13px; padding: 8px 0; }
</style>