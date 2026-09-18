<template>
  <!-- 维修任务卡片 -->
  <view class="repair-card" @click="$emit('click')">
    <view class="card-header">
      <text class="device-name">{{ order.device_name || '未知设备' }}</text>
      <text class="urgency-tag" :class="'u-' + order.emergency_level">{{ order.emergency_text || '普通' }}</text>
    </view>
    <view class="device-code">{{ order.device_code }}</view>
    <view class="card-info">
      <text class="order-no">单号：{{ order.order_code }}</text>
      <text class="fault-tag">{{ order.fault_type || '故障' }}</text>
    </view>
    <view class="card-footer">
      <text class="report-time">报修：{{ order.report_time }}</text>
      <text class="status-text" :class="'st-' + order.status">{{ order.status_text }}</text>
      <text class="action-btn">去维修</text>
    </view>
  </view>
</template>

<script>
export default {
  name: 'RepairTaskCard',
  props: {
    order: { type: Object, default: () => ({}) }
  }
}
</script>

<style scoped>
.repair-card { background: #fff; border-radius:16rpx; padding: 24rpx; margin-bottom: 16rpx; box-shadow: 0 2rpx 8rpx rgba(0,0,0,.05); }
.card-header { display: flex; align-items: center; justify-content: space-between; }
.device-name { font-size: 32rpx; font-weight: 600; color: #303133; max-width: 420rpx; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.urgency-tag { font-size: 22rpx; color: #fff; padding: 4rpx 14rpx; border-radius:8rpx; }
.u-critical { background: #F56C6C; }
.u-urgent { background: #E6A23C; }
.u-normal { background: #909399; }
.device-code { font-size: 24rpx; color: #909399; margin-top: 8rpx; }
.card-info { display: flex; align-items: center; margin-top: 16rpx; }
.order-no { font-size: 24rpx; color: #606266; }
.fault-tag { background: #fef0f0; color: #F56C6C; font-size: 22rpx; padding: 4rpx 12rpx; border-radius:8rpx; margin-left: 16rpx; }
.card-footer { display: flex; align-items: center; justify-content: space-between; margin-top: 16rpx; }
.report-time { font-size: 24rpx; color: #909399; }
.status-text { font-size: 24rpx; }
.st-assigned { color: #409EFF; }
.st-repairing { color: #E6A23C; }
.st-accepted { color: #67C23A; }
.action-btn { font-size: 26rpx; color: #fff; background: #409EFF; padding: 8rpx 28rpx; border-radius:24rpx; }
</style>
