<template>
  <view v-if="visible" class="dialog-mask" @click="close">
    <view class="dialog" @click.stop>
      <view class="dialog-title">添加耗材</view>
      <input v-model="keyword" class="search-input" placeholder="搜索耗材名称" @input="onSearch" />
      <scroll-view scroll-y class="material-list">
        <view v-for="m in materials" :key="m.id" class="material-option">
          <view class="material-info" @click="confirm(m, 1)">
            <view>{{ m.material_name }} <text class="gray">{{ m.specification }}</text></view>
            <view class="gray">库存 {{ m.stock }}{{ m.unit }}</view>
          </view>
          <view class="quantity-row">
            <view class="qty-btn" @click="changeQty(m, -1)">-</view>
            <text class="qty-num">{{ m.quantity }}</text>
            <view class="qty-btn" @click="changeQty(m, 1)">+</view>
            <view class="confirm-btn" @click="confirm(m)">添加</view>
          </view>
        </view>
        <view v-if="!materials.length" class="empty-text">无匹配耗材</view>
      </scroll-view>
      <view class="dialog-footer"><view class="dialog-cancel" @click="close">取消</view></view>
    </view>
  </view>
</template>

<script>
import { getMaintenanceMaterials } from '../../../../api/index.js'

export default {
  name: 'MaterialPicker',
  props: {
    visible: { type: Boolean, default: false }
  },
  data() {
    return {
      keyword: '',
      materials: []
    }
  },
  watch: {
    visible(v) { if (v) { this.keyword = ''; this.load() } }
  },
  methods: {
    async load() {
      try { const r = await getMaintenanceMaterials(this.keyword); if (r.code === 0) {
        this.materials = (r.data || []).map(m => ({ ...m, quantity: 1 }))
      } } catch (e) {}
    },
    onSearch() { this.load() },
    changeQty(m, delta) { m.quantity = Math.max(1, m.quantity + delta) },
    confirm(m) {
      this.$emit('select', { material_name: m.material_name, specification: m.specification, unit: m.unit, quantity: m.quantity, id: m.id })
      this.close()
    },
    close() { this.$emit('close') }
  }
}
</script>

<style scoped>
.dialog-mask { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,.5); display: flex; align-items: flex-end; z-index: 100; }
.dialog { width: 100%; background: #fff; border-radius:20rpx 20rpx 0 0; max-height: 65vh; padding: 24rpx; box-sizing: border-box;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.dialog-title { font-size: 32rpx; font-weight: 600; margin-bottom: 16rpx; }
.search-input { border: 1rpx solid #eee; border-radius:8rpx; padding: 12rpx 16rpx; font-size: 26rpx; margin-bottom: 12rpx; }
.material-list { max-height: 44vh; }
.material-option { padding: 16rpx 0; border-bottom: 1rpx solid #f0f0f0; }
.material-info { font-size: 28rpx; }
.gray { color: #909399; font-size: 24rpx; }
.quantity-row { display: flex; align-items: center; margin-top: 8rpx; }
.qty-btn { width: 48rpx; height: 48rpx; background: #f0f0f0; text-align: center; line-height: 48rpx; border-radius:8rpx; }
.qty-num { width: 60rpx; text-align: center; font-size: 26rpx; }
.confirm-btn { margin-left: auto; background: #409EFF; color: #fff; padding: 8rpx 24rpx; border-radius:24rpx; font-size: 26rpx; }
.empty-text { text-align: center; color: #909399; padding: 40rpx 0; }
.dialog-footer { padding-top: 16rpx; }
.dialog-cancel { text-align: center; color: #909399; padding: 20rpx; }
</style>
