<template>
  <view class="agree-page">
    <view class="agree-nav">
      <view class="agree-nav-back" @click="goBack">
        <MIcon name="close" :size="20" color="#1a2332" />
      </view>
      <text class="agree-nav-title">{{ title }}</text>
      <view class="agree-nav-space"></view>
    </view>
    <scroll-view scroll-y class="agree-content" :show-scrollbar="false">
      <rich-text v-if="content" class="agree-rich" :nodes="content"></rich-text>
      <view v-else class="agree-empty">
        <view class="agree-empty-icon"><MIcon name="file" :size="36" color="#c0cedc" /></view>
        <text class="agree-empty-text">暂无内容，请联系管理员配置</text>
      </view>
    </scroll-view>
  </view>
</template>

<script>
export default {
  data() {
    return {
      type: 'user',
      title: '用户协议',
      content: '',
      loading: false
    }
  },
  onLoad(options) {
    this.type = (options && options.type) || 'user'
    this.title = this.type === 'privacy' ? '隐私政策' : '用户协议'
    uni.setNavigationBarTitle({ title: this.title })
    this.loadContent()
  },
  methods: {
    goBack() {
      uni.reLaunch({ url: '/pages/login/index' })
    },
    async loadContent() {
      this.loading = true
      try {
        const res = await new Promise((resolve, reject) => {
          uni.request({
            url: uni.$base + '/api/mobile/agreement?type=' + this.type,
            method: 'GET',
            timeout: 10000,
            success: resolve,
            fail: reject
          })
        })
        if (res.data && res.data.code === 0 && res.data.data) {
          this.content = res.data.data.content || ''
          this.title = res.data.data.title || this.title
          uni.setNavigationBarTitle({ title: this.title })
        } else {
          this.content = ''
        }
      } catch (e) {
        this.content = ''
      }
      this.loading = false
    }
  }
}
</script>

<style scoped>
.agree-page { min-height: 100vh; background: #F4F6FB; display: flex; flex-direction: column; }
.agree-nav { display: flex; align-items: center; justify-content: space-between; padding: 12px 16px; background: #fff; }
.agree-nav-back { width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; border-radius: 8px; background: #F0F2F7; }
.agree-nav-title { font-size: 16px; font-weight: 600; color: #1a2332; }
.agree-nav-space { width: 32px; }
.agree-content { flex: 1; padding: 16px; box-sizing: border-box; }
.agree-rich {
  font-size: 15px;
  color: #3d4a5c;
  line-height: 1.9;
  font-family: -apple-system, BlinkMacSystemFont, "PingFang SC", "HarmonyOS Sans SC", "Microsoft YaHei", "Helvetica Neue", sans-serif;
  word-break: break-word;
}
.agree-empty { display: flex; flex-direction: column; align-items: center; padding: 100px 0; gap: 12px; }
.agree-empty-icon { width: 72px; height: 72px; border-radius: 24px; background: #EDF0F8; display: flex; align-items: center; justify-content: center; }
.agree-empty-text { font-size: 14px; color: #8a9aa8; }
</style>
