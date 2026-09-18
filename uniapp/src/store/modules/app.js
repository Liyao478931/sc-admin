import { defineStore } from 'pinia'

export const useAppStore = defineStore('app', {
  state: () => ({
    systemInfo: null,
    statusBarHeight: 0,
    navBarHeight: 0,
    isIPhoneX: false
  }),

  actions: {
    initSystemInfo() {
      try {
        const info = uni.getSystemInfoSync()
        this.systemInfo = info
        this.statusBarHeight = info.statusBarHeight || 20
        // #ifdef APP-PLUS || H5
        this.navBarHeight = this.statusBarHeight + 44
        // #endif
        // #ifdef MP-WEIXIN
        const menuButton = uni.getMenuButtonBoundingClientRect()
        this.navBarHeight = (menuButton.top - this.statusBarHeight) * 2 + menuButton.height + this.statusBarHeight
        // #endif
        this.isIPhoneX = info.safeAreaInsets && info.safeAreaInsets.bottom > 0
      } catch (e) {
        console.error('initSystemInfo error:', e)
      }
    }
  }
})
