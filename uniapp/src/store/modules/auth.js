import { defineStore } from 'pinia'

export const useAuthStore = defineStore('auth', {
  state: () => ({
    token: '',
    userInfo: null
  }),
  actions: {
    setToken(token) {
      this.token = token
      uni.setStorageSync('token', token)
    },
    setUser(info) {
      this.userInfo = info
    },
    restoreLoginState() {
      const token = uni.getStorageSync('token')
      if (token) this.token = token
    },
    logout() {
      this.token = ''
      this.userInfo = null
      uni.removeStorageSync('token')
    }
  }
})
