<template>
  <view class="my-certificates-page">
    <!-- 状态 Tab -->
    <view class="tabs">
      <view v-for="tab in tabs" :key="tab.value" class="tab-item" :class="{active: activeTab === tab.value}" @click="switchTab(tab.value)">
        {{ tab.label }}
      </view>
    </view>

    <!-- 证书列表 -->
    <scroll-view class="cert-scroll" scroll-y :refresher-enabled="true" :refresher-triggered="refreshing" @refresherrefresh="onRefresh" @scrolltolower="loadMore">
      <view v-for="cert in list" :key="cert.id" class="cert-card" @click="openDetail(cert)">
        <view class="card-left">
          <MIcon v-if="cert.status === 'valid'" name="medal" :size="30" color="#4F46E5" />
          <MIcon v-else name="medal" :size="30" color="#c6d2e0" />
        </view>
        <view class="card-mid">
          <view class="cert-name">{{ cert.certificate_name }}</view>
          <view class="cert-line">培训：{{ cert.training_name }}</view>
          <view class="cert-line">颁发：{{ cert.issue_date }}　截止：{{ cert.expire_date || '长期有效' }}</view>
        </view>
        <view class="card-right">
          <text v-if="cert.status === 'expired'" class="status-tag expired">过期</text>
          <text v-else-if="cert.expiring_soon" class="status-tag soon">即将过期</text>
          <text v-else class="status-tag valid">有效</text>
          <text class="arrow">›</text>
        </view>
      </view>

      <view v-if="!list.length && !loading" class="empty">
        <MIcon name="medal" :size="44" color="#c6d2e0" />
        <text class="empty-text">暂无培训证书</text>
        <text class="empty-tip">完成培训后将自动获得证书</text>
      </view>
      <view v-if="loading" class="loading">加载中...</view>
      <view v-if="finished && list.length" class="finished">没有更多了</view>
    </scroll-view>
  </view>
</template>

<script>
import { getMyCertificates, checkCertificateStatus } from '../../../api/index.js'

export default {
  data() {
    return {
      tabs: [
        { label: '全部', value: '' },
        { label: '有效', value: 'valid' },
        { label: '过期', value: 'expired' }
      ],
      activeTab: '',
      list: [], page: 1, limit: 10, total: 0, finished: false,
      loading: false, refreshing: false
    }
  },
  onLoad(options) {
    if (options.status) this.activeTab = options.status
    this.loadList(true)
  },
  onShow() {
    if (this._loaded) this.loadList(true)
    this._loaded = true
  },
  methods: {
    async loadList(reset = false) {
      if (this.loading) return
      if (reset) { this.page = 1; this.finished = false }
      this.loading = true
      try {
        // 进入时检查证书状态
        checkCertificateStatus().catch(() => {})
        const r = await getMyCertificates(this.activeTab, this.page, this.limit)
        const data = r.data || {}
        if (reset) this.list = data.list || []
        else this.list = this.list.concat(data.list || [])
        this.total = data.total || 0
        if (this.list.length >= this.total) this.finished = true
      } catch (e) { uni.showToast({ title: '加载失败', icon: 'none' }) }
      this.loading = false
      this.refreshing = false
    },
    switchTab(tab) { this.activeTab = tab; this.loadList(true) },
    onRefresh() { this.refreshing = true; this.loadList(true) },
    loadMore() { if (!this.finished) { this.page++; this.loadList() } },
    openDetail(cert) {
      uni.navigateTo({ url: '/pages/sub/safety/certificate-detail?id=' + cert.id })
    }
  }
}
</script>

<style scoped>
.my-certificates-page { min-height: 100vh; background: #f5f6fa; }
.tabs { display: flex; background: #fff; padding: 16rpx 0; }
.tab-item { flex: 1; text-align: center; padding: 16rpx 0; font-size: 28rpx; color: #909399; }
.tab-item.active { color: #409EFF; font-weight: 600; border-bottom: 4rpx solid #409EFF; }
.cert-scroll { height: calc(100vh - 120rpx); padding: 16rpx 24rpx; box-sizing: border-box; }
.cert-card { display: flex; align-items: center; background: #fff; border-radius:16rpx; padding: 24rpx; margin-bottom: 16rpx; box-shadow: 0 2rpx 8rpx rgba(0,0,0,.05); }
.card-left { width: 80rpx; }
.cert-icon { width: 64rpx; height: 64rpx; }
.card-mid { flex: 1; min-width: 0; }
.cert-name { font-size: 30rpx; font-weight: 600; color: #303133; }
.cert-line { font-size: 24rpx; color: #909399; margin-top: 8rpx; }
.card-right { text-align: center; margin-left: 12rpx; }
.status-tag { display: inline-block; font-size: 22rpx; padding: 4rpx 14rpx; border-radius:8rpx; }
.status-tag.valid { background: #f0f9eb; color: #67C23A; }
.status-tag.expired { background: #fef0f0; color: #F56C6C; }
.status-tag.soon { background: #fdf6ec; color: #E6A23C; }
.arrow { display: block; color: #c0c4cc; font-size: 32rpx; margin-top: 10rpx; }
.empty { text-align: center; padding: 120rpx 0; }
.empty-icon { font-size: 80rpx; display: block; }
.empty-text { color: #909399; font-size: 30rpx; display: block; margin-top: 12rpx; }
.empty-tip { color: #c0c4cc; font-size: 24rpx; display: block; margin-top: 8rpx; }
.loading, .finished { text-align: center; color: #909399; font-size: 26rpx; padding: 24rpx; }
</style>
