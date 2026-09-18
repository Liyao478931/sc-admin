<template>
  <div class="dashboard">
    <LoginNotification />
    <el-card shadow="never">
      <h2>欢迎使用 数智管控平台 管理后台</h2>
      <p style="color: #666;">
        当前登录用户：
        <strong>{{ userInfo?.real_name || userInfo?.username || '未知' }}</strong>
      </p>
      <p style="color: #999; font-size: 14px;">
        请从左侧菜单选择功能开始操作。
      </p>
    </el-card>
  </div>
</template>

<script>
import { mapState } from 'vuex'
import LoginNotification from '@/components/LoginNotification.vue'

export default {
  name: 'Dashboard',
  components: { LoginNotification },
  computed: {
    ...mapState('user', ['userInfo'])
  }
}
</script>

<style scoped>
.dashboard {
  padding: 0;
}
.el-card {
  border-radius: 8px;
}
h2 {
  margin: 0 0 16px;
  font-size: 22px;
  color: #333;
}
</style>
