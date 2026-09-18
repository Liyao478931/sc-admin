<template>
  <view class="task-card" @click="onClick">
    <view class="card-header">
      <text class="device-name">{{ task.device_name || '未知设备' }}</text>
      <text v-if="task.is_overdue" class="overdue-tag">逾期</text>
    </view>
    <view class="device-code">{{ task.device_code }}</view>
    <view class="card-info">
      <text class="level-tag">{{ task.level_name }}</text>
      <text class="exec-date">计划：{{ task.plan_execute_date }}</text>
    </view>
    <view class="card-footer">
      <text class="status-text" :class="'st-' + task.status">{{ task.status_text }}</text>
      <text class="action-btn" :class="{completed: task.status === 'completed'}">{{ task.status === 'completed' ? '查看详情' : '去执行' }}</text>
    </view>
  </view>
</template>

<script>
export default {
  name: 'MaintenanceTaskCard',
  props: {
    task: { type: Object, default: () => ({}) }
  },
  methods: {
    onClick() { this.$emit('click', this.task) }
  }
}
</script>

<style scoped>
.task-card { background: #fff; border-radius:16rpx; padding: 24rpx; margin-bottom: 16rpx; box-shadow: 0 2rpx 8rpx rgba(0,0,0,.05); }
.card-header { display: flex; align-items: center; justify-content: space-between; }
.device-name { font-size: 32rpx; font-weight: 600; color: #303133; }
.overdue-tag { background: #F56C6C; color: #fff; font-size: 22rpx; padding: 4rpx 12rpx; border-radius:8rpx; }
.device-code { font-size: 24rpx; color: #909399; margin-top: 8rpx; }
.card-info { display: flex; align-items: center; margin-top: 16rpx; }
.level-tag { background: #ecf5ff; color: #409EFF; font-size: 24rpx; padding: 4rpx 12rpx; border-radius:8rpx; }
.exec-date { font-size: 24rpx; color: #606266; margin-left: 16rpx; }
.card-footer { display: flex; align-items: center; justify-content: space-between; margin-top: 16rpx; }
.status-text { font-size: 26rpx; }
.st-pending { color: #409EFF; }
.st-in_progress { color: #E6A23C; }
.st-completed { color: #67C23A; }
.st-overdue { color: #F56C6C; }
.action-btn { font-size: 26rpx; color: #fff; background: #409EFF; padding: 8rpx 24rpx; border-radius:24rpx; }
.action-btn.completed { background: #67C23A; }
</style>
