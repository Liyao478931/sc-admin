<template>
  <view class="ap-page">
    <!-- 提示横幅 -->
    <view v-if="showBanner" class="ap-banner">
      <u-icon name="info-circle" color="#4F46E5" size="16" />
      <text class="ap-banner-text">领用申请：从总仓领用配件或固定资产，提交后需管理员审批。</text>
      <u-icon name="close" color="#b0c0cc" size="14" @click="showBanner = false" />
    </view>

    <!-- 类型切换 -->
    <view class="ap-tabs">
      <view class="ap-tab" :class="{ active: applyType === 1 }" @click="switchType(1)">配件领用</view>
      <view class="ap-tab" :class="{ active: applyType === 2 }" @click="switchType(2)">资产领用</view>
    </view>

    <!-- 表单 -->
    <view class="ap-form">
      <!-- 物品选择 -->
      <view class="ap-group">
        <text class="ap-label">{{ applyType === 1 ? '选择配件' : '选择资产' }} <text class="required">*</text></text>
        <view class="ap-select-box" @click="openSelector">
          <view v-if="selectedItem" class="ap-selected">
            <view class="ap-selected-left">
              <text class="ap-selected-name">{{ selectedItem.name }}<text v-if="selectedItem.spec" class="ap-selected-spec">（{{ selectedItem.spec }}）</text></text>
              <text class="ap-selected-meta">{{ applyType === 1 ? '编码：' + selectedItem.code + ' · 库存：' + selectedItem.stock + ' ' + selectedItem.unit : '编码：' + selectedItem.code }}</text>
            </view>
            <u-icon name="close-circle-fill" color="#c0cedc" size="16" @click.stop="clearSelection" />
          </view>
          <view v-else class="ap-empty-select">
            <text class="ap-empty-text">请点击选择领用物品</text>
            <u-icon name="arrow-right" color="#c0cedc" size="13" />
          </view>
        </view>
        <text class="ap-hint">{{ applyType === 1 ? '从总仓配件库中选择领用物品' : '从可领用资产中选择领用物品' }}</text>
      </view>

      <!-- 数量 -->
      <view class="ap-group">
        <text class="ap-label">领用数量 <text class="required">*</text></text>
        <view class="ap-qty-row">
          <view class="ap-qty-btn" @click="changeQty(-1)"><u-icon name="minus" color="#8a9aa8" size="13" /></view>
          <u-input v-model.number="quantity" type="number" border="none" :customStyle="{ height: '72rpx', fontSize: '28rpx' }" />
          <view class="ap-qty-btn" @click="changeQty(1)"><u-icon name="plus" color="#8a9aa8" size="13" /></view>
          <text class="ap-qty-unit">{{ selectedItem ? selectedItem.unit : (applyType === 1 ? '件' : '台') }}</text>
          <text class="ap-qty-hint">{{ qtyHint }}</text>
        </view>
      </view>

      <!-- 关联工单 -->
      <view class="ap-group">
        <text class="ap-label">关联工单 <text class="optional">（选填）</text></text>
        <view class="ap-select-box" @click="openWoSelector">
          <view v-if="selectedWorkOrder" class="ap-selected">
            <view class="ap-selected-left">
              <text class="ap-selected-name">{{ selectedWorkOrder.order_no }}</text>
              <text class="ap-selected-meta">产品：{{ selectedWorkOrder.product_name }}</text>
            </view>
            <u-icon name="close-circle-fill" color="#c0cedc" size="16" @click.stop="clearWorkOrder" />
          </view>
          <view v-else class="ap-empty-select">
            <text class="ap-empty-text">请选择关联工单</text>
            <u-icon name="arrow-right" color="#c0cedc" size="13" />
          </view>
        </view>
        <text class="ap-hint">关联工单后，领用记录将自动关联工单成本</text>
      </view>

      <!-- 用途说明 -->
      <view class="ap-group">
        <text class="ap-label">用途说明 <text class="required">*</text></text>
        <u-textarea v-model="purpose" placeholder="请详细说明领用用途，如：3号设备轴承更换" maxlength="500" />
      </view>

      <!-- 提交 -->
      <view class="ap-actions">
        <view class="ap-btn cancel" @click="handleCancel">取消</view>
        <view class="ap-btn submit" :class="{ disabled: submitting }" @click="handleSubmit">{{ submitting ? '提交中...' : '提交申请' }}</view>
      </view>
    </view>

    <!-- 物品选择器弹窗 -->
    <u-popup :show="selectorOpen" mode="bottom" round="24" @close="selectorOpen = false">
      <view class="ap-sheet">
        <view class="ap-sheet-head">
          <text class="ap-sheet-title">{{ applyType === 1 ? '选择配件' : '选择资产' }}</text>
          <u-icon name="close" color="#b0c0cc" size="16" @click="selectorOpen = false" />
        </view>
        <view class="ap-search">
          <u-icon name="search" color="#b0c0cc" size="15" />
          <u-input v-model="selectorKeyword" placeholder="搜索名称/编码" prefixIcon="search" border="none" :customStyle="{ height: '72rpx', fontSize: '26rpx' }" @input="loadSelectorList" />
        </view>
        <scroll-view scroll-y class="ap-list">
          <view v-for="it in selectorList" :key="it.id" class="ap-item" :class="{ active: tempSelected && tempSelected.id === it.id }" @click="tempSelected = it">
            <view class="ap-item-info">
              <text class="ap-item-name">{{ it.name }} <text class="ap-item-spec">{{ it.spec || '' }}</text></text>
              <text class="ap-item-desc">
                {{ applyType === 1 ? '编码：' + it.code + ' · 库存：' + it.stock + ' ' + it.unit : '编码：' + it.code }}
              </text>
            </view>
            <u-icon v-if="tempSelected && tempSelected.id === it.id" name="checkmark-circle-fill" color="#4F46E5" size="16" />
          </view>
          <view v-if="!selectorList.length" class="ap-empty">{{ applyType === 1 ? '暂无可用配件（需有库存）' : '暂无可用资产' }}</view>
        </scroll-view>
        <view class="ap-sheet-actions">
          <view class="ap-sheet-btn cancel" @click="selectorOpen = false">取消</view>
          <view class="ap-sheet-btn confirm" @click="confirmSelector">确认选择</view>
        </view>
      </view>
    </u-popup>

    <!-- 工单选择器弹窗 -->
    <u-popup :show="woOpen" mode="bottom" round="24" @close="woOpen = false">
      <view class="ap-sheet">
        <view class="ap-sheet-head">
          <text class="ap-sheet-title">选择工单</text>
          <u-icon name="close" color="#b0c0cc" size="16" @click="woOpen = false" />
        </view>
        <view class="ap-search">
          <u-icon name="search" color="#b0c0cc" size="15" />
          <u-input v-model="woKeyword" placeholder="搜索工单编号/产品名称" prefixIcon="search" border="none" :customStyle="{ height: '72rpx', fontSize: '26rpx' }" @input="loadWoList" />
        </view>
        <scroll-view scroll-y class="ap-list">
          <view v-for="w in woList" :key="w.id" class="ap-item" :class="{ active: tempWo && tempWo.id === w.id }" @click="tempWo = w">
            <view class="ap-item-info">
              <text class="ap-item-name">{{ w.order_no }}</text>
              <text class="ap-item-desc">产品：{{ w.product_name }}</text>
            </view>
            <u-icon v-if="tempWo && tempWo.id === w.id" name="checkmark-circle-fill" color="#4F46E5" size="16" />
          </view>
          <view v-if="!woList.length" class="ap-empty">暂无可用工单</view>
        </scroll-view>
        <view class="ap-sheet-actions">
          <view class="ap-sheet-btn cancel" @click="woOpen = false">取消</view>
          <view class="ap-sheet-btn confirm" @click="confirmWorkOrder">确认选择</view>
        </view>
      </view>
    </u-popup>

    <!-- 成功弹窗 -->
    <u-popup :show="successVisible" mode="center" round="24" @close="successVisible = false">
      <view class="ap-success-card">
        <u-icon name="checkmark-circle" color="#67C23A" size="56" />
        <text class="ap-success-title">提交成功！</text>
        <text class="ap-success-sub">领用申请已提交，请等待管理员审批</text>
        <view class="ap-success-detail">
          <view class="ap-success-row"><text class="ap-success-lb">申请单号</text><text>{{ successNo }}</text></view>
          <view class="ap-success-row"><text class="ap-success-lb">申请类型</text><text>{{ applyType === 1 ? '配件领用' : '资产领用' }}</text></view>
          <view class="ap-success-row"><text class="ap-success-lb">审批状态</text><text style="color:#E6A23C">待审批</text></view>
        </view>
        <view class="ap-success-btn" @click="closeSuccess">查看领用记录</view>
      </view>
    </u-popup>
  </view>
</template>

<script setup>
import { ref, computed } from 'vue'
import { onLoad } from '@dcloudio/uni-app'

const showBanner = ref(true)
const applyType = ref(1)
const selectedItem = ref(null)
const selectedWorkOrder = ref(null)
const quantity = ref(1)
const purpose = ref('')
const submitting = ref(false)

// 选择器
const selectorOpen = ref(false)
const selectorKeyword = ref('')
const selectorList = ref([])
const tempSelected = ref(null)
const woOpen = ref(false)
const woKeyword = ref('')
const woList = ref([])
const tempWo = ref(null)
const successVisible = ref(false)
const successNo = ref('')

const qtyHint = computed(() => {
  if (!selectedItem.value) return applyType.value === 1 ? '请选择领用物品' : '请选择领用资产'
  if (applyType.value === 1) return '可领用数量：' + (selectedItem.value.stock || 0) + ' ' + (selectedItem.value.unit || '件')
  return '资产领用数量默认为1'
})

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

async function switchType(t) {
  if (applyType.value === t) return
  applyType.value = t
  clearSelection()
  clearWorkOrder()
  quantity.value = 1
}

function changeQty(d) {
  const max = applyType.value === 1 ? Number(selectedItem.value?.stock || 99999) : 1
  quantity.value = Math.max(1, Math.min(max, (Number(quantity.value) || 1) + d))
}

function openSelector() {
  selectorOpen.value = true
  tempSelected.value = null
  selectorKeyword.value = ''
  loadSelectorList()
}
async function loadSelectorList() {
  try {
    if (applyType.value === 1) {
      const r = await api('/api/personal-assets/pick-apply/materials', 'GET', { keyword: selectorKeyword.value, limit: 50 })
      // 仅显示有库存的配件
      selectorList.value = (r || [])
        .filter(m => Number(m.stock_quantity) > 0)
        .map(m => ({ id: m.id, code: m.material_code, name: m.material_name, spec: m.specification, unit: m.unit, stock: m.stock_quantity }))
    } else {
      const r = await api('/api/personal-assets/asset-apply/archive-search', 'GET', { keyword: selectorKeyword.value, limit: 50 })
      selectorList.value = (r || [])
        .filter(a => Number(a.available_quantity) > 0)
        .map(a => ({ id: a.id, code: a.asset_no, name: a.asset_name, spec: a.specification, unit: a.unit, stock: a.available_quantity }))
    }
  } catch (e) {
    selectorList.value = []
    uni.showToast({ title: e.msg || '加载列表失败', icon: 'none' })
  }
}
function confirmSelector() {
  if (!tempSelected.value) { uni.showToast({ title: '请先选择物品', icon: 'none' }); return }
  selectedItem.value = tempSelected.value
  quantity.value = 1
  selectorOpen.value = false
}
function clearSelection() { selectedItem.value = null; quantity.value = 1 }

function openWoSelector() {
  woOpen.value = true
  tempWo.value = null
  woKeyword.value = ''
  loadWoList()
}
async function loadWoList() {
  try {
    const r = await api('/api/production/order/available-for-report', 'GET', {})
    woList.value = (r && r.list) || []
  } catch (e) { woList.value = [] }
}
function confirmWorkOrder() {
  if (!tempWo.value) { uni.showToast({ title: '请先选择工单', icon: 'none' }); return }
  selectedWorkOrder.value = tempWo.value
  woOpen.value = false
}
function clearWorkOrder() { selectedWorkOrder.value = null }

async function handleSubmit() {
  if (!selectedItem.value) { uni.showToast({ title: '请选择领用物品', icon: 'none' }); return }
  if (!quantity.value || quantity.value <= 0) { uni.showToast({ title: '请输入有效的领用数量', icon: 'none' }); return }
  if (applyType.value === 1 && quantity.value > Number(selectedItem.value.stock || 0)) {
    uni.showToast({ title: '领用数量不能超过库存（' + selectedItem.value.stock + '件）', icon: 'none' }); return
  }
  if (!purpose.value) { uni.showToast({ title: '请填写用途说明', icon: 'none' }); return }
  submitting.value = true
  try {
    let res
    if (applyType.value === 1) {
      res = await api('/api/personal-assets/pick-apply/create', 'POST', {
        material_id: selectedItem.value.id,
        apply_quantity: quantity.value,
        work_order_no: selectedWorkOrder.value ? selectedWorkOrder.value.order_no : '',
        purpose: purpose.value,
        remark: '',
        action: 'submit'
      })
    } else {
      res = await api('/api/personal-assets/asset-apply/submit', 'POST', {
        asset_archive_id: selectedItem.value.id,
        apply_quantity: quantity.value,
        purpose: purpose.value,
        remark: '',
        action: 'submit'
      })
    }
    successNo.value = res.apply_no || ''
    successVisible.value = true
  } catch (e) {
    uni.showToast({ title: e.msg || '提交失败', icon: 'none' })
  }
  submitting.value = false
}

function handleCancel() {
  uni.showModal({
    title: '提示',
    content: '确认取消吗？已填写的信息将丢失。',
    success: (r) => { if (r.confirm) uni.navigateBack() }
  })
}
function closeSuccess() {
  successVisible.value = false
  uni.navigateTo({ url: '/pages/approval/todo' })
}

onLoad(() => {})
</script>

<style scoped>
.ap-page { min-height: 100vh; background: #F4F6FB; padding: 16px; box-sizing: border-box; }
.ap-banner { display: flex; align-items: flex-start; gap: 8px; background: #ecf5ff; border: 1px solid #d9ecff; border-radius:24px; padding: 10px 14px; margin-bottom: 14px; }
.ap-banner-text { flex: 1; font-size: 13px; color: #5a7a9a; line-height: 1.5; }
.ap-tabs { display: flex; background: rgba(0,0,0,0.03); border-radius:24px; padding: 4px; margin-bottom: 16px; border: 1px solid rgba(0,0,0,0.04); }
.ap-tab { flex: 1; padding: 10px 0; text-align: center; border-radius:22px; font-size: 14px; font-weight: 500; color: #8a9aa8; }
.ap-tab.active { background: #fff; color: #1a2332; box-shadow: 0 2px 8px rgba(0,0,0,0.04); }
.ap-form { background: #fff; border-radius:124px; padding: 16px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.ap-group { margin-bottom: 18px; }
.ap-label { font-size: 14px; font-weight: 600; color: #1a2332; margin-bottom: 8px; display: block; }
.required { color: #F56C6C; }
.optional { font-size: 12px; font-weight: 400; color: #b0c0cc; }
.ap-select-box { background: rgba(110,142,251,0.04); border: 1px solid rgba(110,142,251,0.08); border-radius:24px; padding: 12px 14px; display: flex; align-items: center; justify-content: space-between; min-height: 52px; }
.ap-selected { display: flex; align-items: center; justify-content: space-between; flex: 1; }
.ap-selected-left { display: flex; flex-direction: column; }
.ap-selected-name { font-size: 15px; font-weight: 600; color: #1a2332; }
.ap-selected-spec { font-size: 12px; color: #8a9aa8; font-weight: 400; }
.ap-selected-meta { font-size: 12px; color: #8a9aa8; margin-top: 2px; }
.ap-empty-select { display: flex; align-items: center; justify-content: space-between; flex: 1; }
.ap-empty-text { color: #b0c0cc; font-size: 14px; }
.ap-hint { font-size: 12px; color: #b0c0cc; margin-top: 6px; display: block; }
.ap-qty-row { display: flex; align-items: center; gap: 8px; }
.ap-qty-btn { width: 40px; height: 40px; border-radius:22px; background: #f5f6fa; display: flex; align-items: center; justify-content: center; }
.ap-qty-input { flex: 1; text-align: center; font-size: 18px; font-weight: 700; background: #f5f6fa; border-radius:22px; padding: 8px; }
.ap-qty-unit { font-size: 14px; color: #8a9aa8; }
.ap-qty-hint { font-size: 13px; color: #b0c0cc; margin-left: auto; }
.ap-textarea { width: 100%; min-height: 80px; background: #f5f6fa; border-radius:24px; padding: 12px 14px; font-size: 14px; box-sizing: border-box; }
.ap-actions { display: flex; gap: 12px; margin-top: 8px; }
.ap-btn { flex: 1; text-align: center; padding: 14px; border-radius:124px; font-size: 16px; font-weight: 600; }
.ap-btn.cancel { background: #f5f6fa; color: #8a9aa8; }
.ap-btn.submit { background: linear-gradient(135deg, #4F46E5, #7C6FF0); color: #fff; }
.ap-btn.disabled { opacity: 0.6; }

.ap-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.3); z-index: 100; display: flex; align-items: flex-end; }
.ap-sheet { width: 100%; background: #fff; border-radius:224px 224px 0 0; padding: 20px 20px 32px; max-height: 70vh; display: flex; flex-direction: column;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.ap-sheet-head { display: flex; align-items: center; justify-content: space-between; padding-bottom: 12px; border-bottom: 1px solid #EDF0F8; }
.ap-sheet-title { font-size: 17px; font-weight: 700; color: #1a2332; }
.ap-search { display: flex; align-items: center; gap: 6px; background: #f5f6fa; border-radius:24px; padding: 10px 14px; margin: 12px 0 10px; }
.ap-search-input { flex: 1; font-size: 14px; }
.ap-list { max-height: 45vh; }
.ap-item { display: flex; align-items: center; justify-content: space-between; padding: 12px 14px; border-radius:24px; margin-bottom: 4px; }
.ap-item.active { background: #f0f4ff; }
.ap-item-info { flex: 1; min-width: 0; }
.ap-item-name { font-size: 14px; font-weight: 600; color: #1a2332; }
.ap-item-spec { font-size: 12px; color: #8a9aa8; font-weight: 400; }
.ap-item-desc { font-size: 12px; color: #8a9aa8; margin-top: 2px; display: block; }
.ap-empty { text-align: center; color: #b0c0cc; padding: 40px 0; font-size: 13px; }
.ap-sheet-actions { display: flex; gap: 10px; padding-top: 12px; border-top: 1px solid #EDF0F8; margin-top: 12px; }
.ap-sheet-btn { flex: 1; text-align: center; padding: 12px; border-radius:24px; font-size: 15px; font-weight: 600; }
.ap-sheet-btn.cancel { background: #f5f6fa; color: #8a9aa8; }
.ap-sheet-btn.confirm { background: linear-gradient(135deg, #4F46E5, #7C6FF0); color: #fff; }

.ap-success-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.3); z-index: 200; display: flex; align-items: center; justify-content: center; }
.ap-success-card { background: #fff; border-radius:224px; padding: 32px 28px; width: 300px; display: flex; flex-direction: column; align-items: center;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.ap-success-title { font-size: 20px; font-weight: 700; color: #1a2332; margin-top: 10px; }
.ap-success-sub { font-size: 14px; color: #8a9aa8; margin-top: 4px; }
.ap-success-detail { width: 100%; background: #fafbfc; border-radius:24px; padding: 12px 16px; margin: 16px 0 20px; }
.ap-success-row { display: flex; justify-content: space-between; font-size: 13px; padding: 4px 0; color: #4a5a6a; }
.ap-success-lb { color: #b0c0cc; }
.ap-success-btn { width: 100%; text-align: center; padding: 12px; border-radius:24px; background: linear-gradient(135deg, #4F46E5, #7C6FF0); color: #fff; font-size: 15px; font-weight: 600; }
</style>