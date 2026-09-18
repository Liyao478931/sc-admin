<template>
  <view class="preview-page">
    <web-view :src="previewUrl"></web-view>
  </view>
</template>

<script>
export default {
  data() {
    return { previewUrl: '' }
  },
  onLoad(options) {
    this.previewUrl = decodeURIComponent(options.url || '')
  }
}
</script>

<style scoped>
.preview-page { height: 100vh; }
</style>
