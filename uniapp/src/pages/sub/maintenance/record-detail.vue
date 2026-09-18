<template>
  <view class="record-detail-page">
    <!-- 记录信息卡片 -->
    <view class="record-info-card">
      <view class="info-row"><text class="info-label">设备</text><text class="info-value">{{ detail.device_name }}</text></view>
      <view class="info-row"><text class="info-label">编码</text><text class="info-value gray">{{ detail.device_code }}</text></view>
      <view class="info-row"><text class="info-label">等级</text><text class="info-value level">{{ detail.level_name }}</text></view>
      <view class="info-row"><text class="info-label">执行人</text><text class="info-value">{{ detail.executor_name }}</text></view>
      <view class="info-row"><text class="info-label">执行日期</text><text class="info-value">{{ detail.execute_end_time || detail.create_time }}</text></view>
      <view class="info-row"><text class="info-label">验收状态</text><text class="info-value status" :class="statusClass">{{ statusText }}</text></view>
    </view>

    <!-- Tab 切换 -->
    <view class="tabs">
      <view v-for="tab in tabs" :key="tab.value" class="tab-item" :class="{active: activeTab === tab.value}" @click="activeTab = tab.value">
        {{ tab.label }}
      </view>
    </view>

    <!-- 保养项目 -->
    <view v-if="activeTab === 'items'" class="content">
      <view v-for="(item, idx) in detail.items || []" :key="idx" class="item-card">
        <view class="item-header">
          <text class="item-name">{{ item.item_name }}</text>
          <view v-if="item.result === 'normal'" class="result normal" style="display:flex;align-items:center"><MIcon name="check" :size="13" color="#059669" /><text style="margin-left:4px">正常</text></view>
          <view v-else class="result abnormal" style="display:flex;align-items:center"><MIcon name="xmark" :size="13" color="#e74c5e" /><text style="margin-left:4px">异常</text></view>
        </view>
        <view v-if="item.result === 'abnormal' && item.description" class="abnormal-desc">异常描述：{{ item.description }}</view>
        <image v-if="item.result === 'abnormal' && item.photo" :src="item.photo" class="abnormal-img" mode="aspectFill" @click="previewImage(item.photo)" />
      </view>
    </view>

    <!-- 耗材使用 -->
    <view v-else-if="activeTab === 'materials'" class="content">
      <view v-for="(m, idx) in detail.materials || []" :key="idx" class="material-row">
        <text>{{ m.material_name }} <text class="gray">{{ m.specification }}</text></text>
        <text>× {{ m.quantity }}{{ m.unit }}</text>
      </view>
      <view v-if="!(detail.materials || []).length" class="empty-text">暂无耗材记录</view>
    </view>

    <!-- 附件信息 -->
    <view v-else class="content">
      <view class="attachment-grid">
        <image v-for="(img, idx) in detail.attachments || []" :key="idx" :src="img" class="attachment-img" mode="aspectFill" @click="previewImage(img)" />
      </view>
      <view v-if="!(detail.attachments || []).length" class="empty-text">暂无附件</view>
    </view>
  </view>
</template>

<script>
import { getMaintenanceRecordDetail } from '../../../api/index.js'

export default {
  data() {
    return {
      recordId: 0,
      detail: {},
      activeTab: 'items',
      tabs: [
        { label: '保养项目', value: 'items' },
        { label: '耗材使用', value: 'materials' },
        { label: '附件信息', value: 'attachments' }
      ]
    }
  },
  computed: {
    statusText() {
      const s = this.detail.status || ''
      return { pending: '待验收', passed: '已通过', rejected: '已驳回' }[s] || s
    },
    statusClass() {
      const s = this.detail.status || ''
      return { pending: 'st-pending', passed: 'st-passed', rejected: 'st-rejected' }[s] || ''
    }
  },
  onLoad(options) {
    this.recordId = Number(options.record_id || 0)
    this.loadDetail()
  },
  methods: {
    async loadDetail() {
      try {
        const r = await getMaintenanceRecordDetail(this.recordId)
        if (r.code === 0) this.detail = r.data
        else uni.showToast({ title: r.msg || '加载失败', icon: 'none' })
      } catch (e) { uni.showToast({ title: '加载失败', icon: 'none' }) }
    },
    previewImage(url) { uni.previewImage({ urls: [url], current: url }) }
  }
}
</script>

<style scoped>
.record-detail-page { min-height: 100vh; background: #f5f6fa; }
.record-info-card { background: #fff; padding: 24rpx; margin: 16rpx; border-radius:16rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.info-row { display: flex; margin-bottom: 12rpx; }
.info-label { width: 140rpx; color: #909399; font-size: 28rpx; }
.info-value { color: #303133; font-size: 28rpx; }
.info-value.gray { color: #909399; }
.info-value.level { color: #409EFF; }
.info-value.status.st-pending { color: #E6A23C; }
.info-value.status.st-passed { color: #67C23A; }
.info-value.status.st-rejected { color: #F56C6C; }
.tabs { display: flex; background: #fff; padding: 16rpx 0; }
.tab-item { flex: 1; text-align: center; padding: 16rpx 0; font-size: 28rpx; color: #909399; }
.tab-item.active { color: #409EFF; font-weight: 600; border-bottom: 4rpx solid #409EFF; }
.content { padding: 16rpx; }
.item-card { background: #fff; border-radius:12rpx; padding: 20rpx; margin-bottom: 16rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.item-header { display: flex; align-items: center; justify-content: space-between; }
.item-name { font-size: 28rpx; font-weight: 600; }
.result { font-size: 26rpx; }
.result.normal { color: #67C23A; }
.result.abnormal { color: #F56C6C; }
.abnormal-desc { font-size: 24rpx; color: #606266; margin-top: 8rpx; }
.abnormal-img { width: 200rpx; height: 150rpx; border-radius:8rpx; margin-top: 8rpx; }
.material-row { display: flex; align-items: center; justify-content: space-between; background: #fff; padding: 16rpx 20rpx; border-radius:12rpx; margin-bottom: 12rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.gray { color: #909399; font-size: 24rpx; }
.empty-text { text-align: center; color: #909399; font-size: 28rpx; padding: 60rpx 0; }
.attachment-grid { display: flex; flex-wrap: wrap; gap: 12rpx; background: #fff; padding: 16rpx; border-radius:12rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.attachment-img { width: 200rpx; height: 200rpx; border-radius:8rpx; }
</style>
