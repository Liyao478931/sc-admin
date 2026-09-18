<template>
  <div id="app">
    <router-view />
    <!-- 全局悬浮聊天入口（所有页面右下角） -->
    <FloatingChat />
  </div>
</template>

<script>
// 文件：admin/src/App.vue
import FloatingChat from './components/FloatingChat.vue'

export default {
  name: 'App',
  components: { FloatingChat },
  data () {
    return {}
  },
}
</script>

<style>
html, body, #app {
  margin: 0;
  padding: 0;
  height: 100%;
  font-family: 'Helvetica Neue', Helvetica, 'PingFang SC', 'Microsoft YaHei', Arial, sans-serif;
}
</style>
