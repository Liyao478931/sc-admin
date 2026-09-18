<template>
  <view class="safety-record-page">
    <!-- 记录信息卡片 -->
    <view class="record-info-card">
      <view class="info-row"><text class="info-label">任务编号</text><text class="info-value">{{ detail.task_code }}</text></view>
      <view class="info-row"><text class="info-label">计划名称</text><text class="info-value">{{ detail.plan_name }}</text></view>
      <view class="info-row"><text class="info-label">检查类型</text><text class="info-value level">{{ detail.inspection_type_name }}</text></view>
      <view class="info-row"><text class="info-label">检查区域</text><text class="info-value">{{ detail.area || '—' }}</text></view>
      <view class="info-row"><text class="info-label">执行人</text><text class="info-value">{{ detail.executor_name || '我' }}</text></view>
      <view class="info-row"><text class="info-label">完成时间</text><text class="info-value">{{ detail.actual_execute_date || detail.execute_end_time || '—' }}</text></view>
    </view>

    <!-- Tab 切换 -->
    <view class="tabs">
      <view v-for="tab in tabs" :key="tab.value" class="tab-item" :class="{active: activeTab === tab.value}" @click="activeTab = tab.value">
        {{ tab.label }}
      </view>
    </view>

    <!-- 检查项目 -->
    <view v-if="activeTab === 'items'" class="content">
      <view v-for="(item, idx) in detail.result || []" :key="idx" class="item-card">
        <view class="item-header">
          <text class="item-name">{{ item.item_name }}</text>
          <text class="result" :class="'r-' + item.result">{{ resultText(item.result) }}</text>
        </view>
        <view v-if="item.result === 'unqualified' && item.remark" class="item-remark">问题：{{ item.remark }}</view>
      </view>
      <view v-if="!(detail.result || []).length" class="empty-text">暂无检查项目数据</view>
    </view>

    <!-- 问题记录 -->
    <view v-else-if="activeTab === 'issues'" class="content">
      <view v-for="(issue, idx) in detail.issues || []" :key="idx" class="issue-card">
        <view class="issue-head">
          <text class="issue-name">{{ issue.item_name }}</text>
          <text class="severity" :class="'sev-' + issue.severity">{{ issue.severity_text }}</text>
        </view>
        <view class="issue-desc">{{ issue.issue_description }}</view>
        <view v-if="issue.suggest" class="issue-suggest">整改建议：{{ issue.suggest }}</view>
        <view v-if="issue.hazard_id" class="hazard-tag">已转隐患</view>
      </view>
      <view v-if="!(detail.issues || []).length" class="empty-text">暂无问题记录</view>
    </view>

    <!-- 检查总结 -->
    <view v-else class="content">
      <view class="summary-card">
        <text class="summary-text">{{ detail.summary || '暂无检查总结' }}</text>
      </view>
    </view>
  </view>
</template>

<script>
import { getSafetyRecordDetail } from '../../../api/index.js'

export default {
  data() {
    return {
      recordId: 0,
      detail: {},
      activeTab: 'items',
      tabs: [
        { label: '检查项目', value: 'items' },
        { label: '问题记录', value: 'issues' },
        { label: '检查总结', value: 'summary' }
      ]
    }
  },
  onLoad(options) {
    this.recordId = Number(options.record_id || 0)
    this.loadDetail()
  },
  methods: {
    async loadDetail() {
      try {
        const r = await getSafetyRecordDetail(this.recordId)
        if (r.code === 0) this.detail = r.data
        else uni.showToast({ title: r.msg || '加载失败', icon: 'none' })
      } catch (e) { uni.showToast({ title: '加载失败', icon: 'none' }) }
    },
    resultText(v) {
      return { qualified: '合格', unqualified: '不合格', na: '不适用' }[v] || v || '—'
    }
  }
}
</script>

<style scoped>
.safety-record-page { min-height: 100vh; background: #f5f6fa; }
.record-info-card { background: #fff; padding: 24rpx; margin: 16rpx; border-radius:16rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.info-row { display: flex; margin-bottom: 12rpx; }
.info-label { width: 150rpx; color: #909399; font-size: 28rpx; }
.info-value { color: #303133; font-size: 28rpx; flex: 1; }
.info-value.level { color: #409EFF; }
.tabs { display: flex; background: #fff; padding: 16rpx 0; }
.tab-item { flex: 1; text-align: center; padding: 16rpx 0; font-size: 28rpx; color: #909399; }
.tab-item.active { color: #409EFF; font-weight: 600; border-bottom: 4rpx solid #409EFF; }
.content { padding: 16rpx; }
.item-card { background: #fff; border-radius:12rpx; padding: 20rpx; margin-bottom: 16rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.item-header { display: flex; align-items: center; justify-content: space-between; }
.item-name { font-size: 28rpx; font-weight: 600; }
.result { font-size: 26rpx; }
.r-qualified { color: #67C23A; }
.r-unqualified { color: #F56C6C; }
.r-na { color: #909399; }
.item-remark { font-size: 24rpx; color: #606266; margin-top: 8rpx; }
.issue-card { background: #fff; border-radius:12rpx; padding: 20rpx; margin-bottom: 16rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.issue-head { display: flex; align-items: center; justify-content: space-between; }
.issue-name { font-size: 28rpx; font-weight: 600; }
.severity { font-size: 24rpx; padding: 4rpx 14rpx; border-radius:8rpx; }
.sev-minor { background: #f4f4f5; color: #909399; }
.sev-major { background: #fdf6ec; color: #E6A23C; }
.sev-critical { background: #fef0f0; color: #F56C6C; }
.issue-desc { font-size: 26rpx; color: #303133; margin-top: 12rpx; line-height: 1.6; }
.issue-suggest { font-size: 24rpx; color: #606266; margin-top: 8rpx; }
.hazard-tag { display: inline-block; background: #fef0f0; color: #F56C6C; font-size: 22rpx; padding: 4rpx 14rpx; border-radius:8rpx; margin-top: 12rpx; }
.summary-card { background: #fff; border-radius:12rpx; padding: 24rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.summary-text { font-size: 28rpx; color: #303133; line-height: 1.8; }
.empty-text { text-align: center; color: #909399; font-size: 28rpx; padding: 60rpx 0; }
</style>
