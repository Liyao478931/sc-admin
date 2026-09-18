<template>
  <view class="record-page">
    <!-- 记录信息卡片 -->
    <view class="record-card">
      <view class="record-head">
        <text class="order-no">工单：{{ detail.order_code }}</text>
        <text class="accept-tag" :class="'a-' + detail.status">{{ acceptText }}</text>
      </view>
      <view class="device-name">{{ detail.device_name }}</view>
      <view class="device-code">{{ detail.device_code }}</view>
      <view class="meta">维修人员：{{ detail.assignee_name || '-' }}</view>
      <view class="meta">完成时间：{{ detail.execute_end_time || '-' }}</view>
    </view>

    <!-- Tab 切换 -->
    <view class="tabs">
      <view v-for="t in tabs" :key="t.key" class="tab" :class="{active: activeTab === t.key}" @click="activeTab = t.key">{{ t.label }}</view>
    </view>

    <view class="content">
      <!-- 故障诊断 -->
      <view v-if="activeTab === 'diagnosis'" class="blocks">
        <view class="block"><view class="block-title">故障原因分析</view><view class="block-text">{{ detail.diagnosis_cause || '-' }}</view></view>
        <view class="block"><view class="block-title">诊断结论</view><view class="block-text">{{ detail.diagnosis_conclusion || '-' }}</view></view>
      </view>

      <!-- 维修方案 -->
      <view v-else-if="activeTab === 'plan'" class="blocks">
        <view class="block"><view class="block-title">维修方案</view><view class="block-text">{{ detail.repair_plan || '-' }}</view></view>
        <view class="block">
          <view class="block-title">备件清单</view>
          <view v-for="(m, i) in detail.materials || []" :key="i" class="material-row">
            {{ m.name }}<text v-if="m.spec">（{{ m.spec }}）</text> × {{ m.quantity }}
          </view>
          <view v-if="!(detail.materials || []).length" class="m-empty">无备件记录</view>
        </view>
      </view>

      <!-- 维修过程 -->
      <view v-else-if="activeTab === 'process'" class="blocks">
        <view class="block"><view class="block-title">维修记录</view><view class="block-text">{{ detail.repair_process || '-' }}</view></view>
        <view class="block"><view class="block-title">维修结果</view><view class="block-text">{{ detail.repair_result === 'fixed' ? '已修复' : '无法修复' }}</view></view>
        <view class="block"><view class="block-title">维修时长</view><view class="block-text">{{ durationText }}</view></view>
        <view class="block"><view class="block-title">附件</view>
          <view v-if="(detail.attachments || []).length" class="attach-grid">
            <image v-for="(img, i) in detail.attachments" :key="i" :src="img" mode="aspectFill" @click="preview(i)" />
          </view>
          <view v-else class="m-empty">无附件</view>
        </view>
      </view>

      <!-- 验收信息 -->
      <view v-else-if="activeTab === 'accept'" class="blocks">
        <view class="block"><view class="block-title">验收状态</view><view class="block-text">{{ acceptText }}</view></view>
        <view class="block"><view class="block-title">验收人</view><view class="block-text">{{ detail.acceptor_name || '-' }}</view></view>
        <view class="block"><view class="block-title">验收时间</view><view class="block-text">{{ detail.accept_time || '-' }}</view></view>
        <view class="block"><view class="block-title">验收意见</view><view class="block-text">{{ detail.accept_remark || '-' }}</view></view>
      </view>
    </view>
  </view>
</template>

<script>
import { getRepairRecordDetail } from '../../../api/index.js'

export default {
  data() {
    return {
      recordId: 0,
      detail: {},
      activeTab: 'diagnosis',
      tabs: [
        { key: 'diagnosis', label: '故障诊断' },
        { key: 'plan', label: '维修方案' },
        { key: 'process', label: '维修过程' },
        { key: 'accept', label: '验收信息' }
      ]
    }
  },
  computed: {
    acceptText() {
      const map = { accepted: '待验收', approved: '已验收', rejected: '已驳回' }
      return map[this.detail.status] || this.detail.status || '-'
    },
    durationText() {
      const d = parseInt(this.detail.duration || 0)
      const h = Math.floor(d / 60), m = d % 60
      return h + '小时' + m + '分钟'
    }
  },
  onLoad(options) {
    this.recordId = parseInt(options.record_id || 0)
    this.loadDetail()
  },
  methods: {
    async loadDetail() {
      if (!this.recordId) { uni.showToast({ title: '参数错误', icon: 'none' }); return }
      uni.showLoading({ title: '加载中' })
      try {
        const r = await getRepairRecordDetail(this.recordId)
        uni.hideLoading()
        if (r.code === 0) this.detail = r.data
        else uni.showToast({ title: r.msg || '加载失败', icon: 'none' })
      } catch (e) { uni.hideLoading(); uni.showToast({ title: '加载失败', icon: 'none' }) }
    },
    preview(i) { uni.previewImage({ urls: this.detail.attachments, current: i }) }
  }
}
</script>

<style scoped>
.record-page { min-height: 100vh; background: #f5f6fa; }
.record-card { background: #fff; margin: 16rpx 24rpx; border-radius:16rpx; padding: 24rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.record-head { display: flex; align-items: center; justify-content: space-between; }
.order-no { font-size: 26rpx; color: #909399; }
.accept-tag { font-size: 24rpx; padding: 4rpx 16rpx; border-radius:8rpx; color: #fff; }
.a-accepted { background: #E6A23C; }
.a-approved { background: #67C23A; }
.a-rejected { background: #F56C6C; }
.device-name { font-size: 34rpx; font-weight: 600; margin-top: 12rpx; }
.device-code { font-size: 24rpx; color: #909399; margin-top: 8rpx; }
.meta { font-size: 26rpx; color: #606266; margin-top: 8rpx; }
.tabs { display: flex; background: #fff; padding: 16rpx 0; }
.tab { flex: 1; text-align: center; padding: 16rpx 0; font-size: 28rpx; color: #909399; }
.tab.active { color: #409EFF; font-weight: 600; border-bottom: 4rpx solid #409EFF; }
.content { padding: 16rpx 24rpx; }
.block { background: #fff; border-radius:16rpx; padding: 24rpx; margin-bottom: 16rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.block-title { font-size: 28rpx; font-weight: 600; color: #409EFF; margin-bottom: 12rpx; }
.block-text { font-size: 28rpx; color: #303133; line-height: 1.7; }
.material-row { font-size: 28rpx; color: #303133; padding: 8rpx 0; }
.m-empty { font-size: 26rpx; color: #909399; }
.attach-grid { display: flex; flex-wrap: wrap; }
.attach-grid image { width: 160rpx; height: 160rpx; border-radius:8rpx; margin: 0 16rpx 16rpx 0; }
</style>
