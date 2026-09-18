<template>
  <view class="wv-page">
    <web-view :src="viewUrl"></web-view>
  </view>
</template>

<script>
export default {
  data() {
    return { viewUrl: '' }
  },
  onLoad(options) {
    this.viewUrl = decodeURIComponent(options.url || '')
  }
}
</script>

<style scoped>
.wv-page { height: 100vh; }
</style>
