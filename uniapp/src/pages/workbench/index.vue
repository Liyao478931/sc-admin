<template>
  <view class="redirect-page"></view>
</template>

<script setup>
// 旧页面重定向到 DIY 工作台入口
import { onLoad } from '@dcloudio/uni-app'
import { redirectTo } from '@/utils/navigate'
import { DIY_PATHS } from '@/constants/pages'

onLoad(() => {
  redirectTo(DIY_PATHS.HOME, { from: 'legacy' })
})
</script>

<style scoped>
.redirect-page { min-height: 100vh; background: #f5f6fa; }
</style>
