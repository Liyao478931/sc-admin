<template>
  <view class="profile-menu" :style="menuStyle">
    <view class="menu-item" v-for="(item, i) in (data.items || [])" :key="i" @click="$emit('navigate', item.path)">
      <text class="menu-icon">{{ item.icon }}</text>
      <text class="menu-title">{{ item.title }}</text>
      <text class="menu-arrow">›</text>
    </view>
  </view>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  data: { type: Object, default: () => ({}) },
  item: { type: Object, default: () => ({}) }
})
defineEmits(['navigate'])

const menuStyle = computed(() => ({
  background: '#fff',
  margin: '0 16px',
  borderRadius: (props.data?.radius || 12) + 'px',
  overflow: 'hidden'
}))
</script>

<style scoped>
.profile-menu { padding: 0; }
.menu-item { padding: 14px 16px; display: flex; align-items: center; border-bottom: 1px solid #F5F6FA; }
.menu-item:last-child { border-bottom: none; }
.menu-icon { font-size: 20px; width: 32px; }
.menu-title { font-size: 15px; color: #303133; flex: 1; }
.menu-arrow { color: #C0C4CC; font-size: 16px; }
</style>
