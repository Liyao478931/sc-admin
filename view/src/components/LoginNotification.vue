<template>
  <transition name="slide-fade">
    <div v-if="visible" class="login-notification">
      <div class="notification-card">
        <div class="notification-header">
          <i class="el-icon-shield" style="color:#409eff;font-size:18px;" />
          <span style="flex:1;margin-left:8px;font-weight:bold;font-size:14px;">登录通知</span>
          <el-button type="text" size="mini" style="color:#999;" @click="close">
            <i class="el-icon-close" />
          </el-button>
        </div>
        <div class="notification-body">
          <div class="welcome-text">欢迎回来，{{ info.real_name || '用户' }}！</div>
          <div class="info-item">
            <i class="el-icon-time" /><span>登录时间：{{ info.login_time }}</span>
          </div>
          <div class="info-item">
            <i class="el-icon-place" /><span>登录IP：{{ info.ip }}<em style="color:#999;margin-left:4px;">{{ info.location ? '('+info.location+')' : '' }}</em></span>
          </div>
          <div class="info-item">
            <i class="el-icon-monitor" /><span>登录设备：{{ info.device || info.user_agent?.slice(0,50) || '未知' }}</span>
          </div>
          <div class="info-item">
            <i class="el-icon-key" /><span>登录方式：{{ info.login_type === 'sms' ? '短信验证码' : '密码登录' }}</span>
          </div>
        </div>
        <div class="notification-footer">
          <span class="auto-close">{{ countdown }}秒后自动关闭</span>
          <el-button size="mini" type="primary" plain @click="close">知道了</el-button>
        </div>
      </div>
    </div>
  </transition>
</template>

<script>
import { getLoginInfo } from '@/api/auth'

export default {
  name: 'LoginNotification',
  data() {
    return {
      visible: false,
      info: {},
      countdown: 3,
      timer: null
    }
  },
  created() {
    this.fetchLoginInfo()
  },
  beforeDestroy() {
    clearInterval(this.timer)
  },
  methods: {
    async fetchLoginInfo() {
      try {
        const res = await getLoginInfo()
        if (res.data && res.data.login_time) {
          // 对比上次显示的时间戳，不同则说明是新一次登录
          const lastShown = sessionStorage.getItem('login_notification_time')
          if (res.data.login_time === lastShown) return
          this.info = res.data
          setTimeout(() => {
            this.visible = true
            this.startCountdown()
          }, 500)
        }
      } catch (e) { /* 忽略错误 */ }
    },
    startCountdown() {
      this.countdown = 3
      this.timer = setInterval(() => {
        this.countdown--
        if (this.countdown <= 0) this.close()
      }, 1000)
    },
    close() {
      this.visible = false
      clearInterval(this.timer)
      // 记录本次登录时间戳，下次相同时间不重复弹
      if (this.info.login_time) {
        sessionStorage.setItem('login_notification_time', this.info.login_time)
      }
    }
  }
}
</script>

<style scoped>
.login-notification {
  position: fixed;
  bottom: 20px;
  right: 20px;
  z-index: 10000;
}
.notification-card {
  width: 380px;
  background: #fff;
  border-radius: 8px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.15);
  border-left: 4px solid #409eff;
  overflow: hidden;
}
.notification-header {
  display: flex;
  align-items: center;
  padding: 14px 16px 0;
}
.notification-body {
  padding: 12px 16px;
}
.welcome-text {
  font-size: 15px;
  font-weight: bold;
  color: #333;
  margin-bottom: 10px;
}
.info-item {
  display: flex;
  align-items: flex-start;
  gap: 6px;
  font-size: 13px;
  color: #555;
  margin-bottom: 6px;
  line-height: 1.6;
}
.info-item i {
  margin-top: 3px;
  color: #409eff;
  width: 16px;
}
.notification-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 16px;
  background: #f8f9fa;
  border-top: 1px solid #f0f0f0;
}
.auto-close {
  font-size: 12px;
  color: #999;
}
/* 动画 */
.slide-fade-enter-active {
  animation: slideIn 0.5s ease;
}
.slide-fade-leave-active {
  animation: slideOut 0.5s ease;
}
@keyframes slideIn {
  from { opacity: 0; transform: translateY(30px); }
  to { opacity: 1; transform: translateY(0); }
}
@keyframes slideOut {
  from { opacity: 1; transform: translateY(0); }
  to { opacity: 0; transform: translateY(30px); }
}
</style>
