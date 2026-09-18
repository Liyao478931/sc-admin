<script>
import { useAuthStore } from './store/modules/auth.js'
import { get } from './utils/request.js'

export default {
  onLaunch() {
    console.log('App Launch')
    const authStore = useAuthStore()
    authStore.restoreLoginState()
    this.checkSystemUpdate()
    this.applyDarkMode()
    this.applyFontScale()
    this.loadIconFont()
  },
  onShow() {
    console.log('App Show')
  },
  onHide() {
    console.log('App Hide')
  },
  methods: {
    // 小程序端提前加载图标字体（本地字体，不依赖阿里CDN域名白名单）
    loadIconFont() {
      // #ifdef MP-WEIXIN
      try {
        if (typeof uni.loadFontFace === 'function') {
          uni.loadFontFace({
            global: true,
            family: 'uicon-iconfont',
            source: 'url("/static/fonts/uicon.ttf")',
            success: () => {},
            fail: () => {}
          })
        }
      } catch (e) {}
      // #endif
    },
    // 深色模式：H5 下给 html 根节点加 dark-mode class（全局 CSS 变量联动）
    // 字体大小：H5 下写入根 CSS 变量 --font-scale，聊天等阅读页即时生效
    applyFontScale() {
      // #ifdef H5
      try {
        const s = uni.getStorageSync('font_scale') || '1'
        document.documentElement.style.setProperty('--font-scale', String(s))
      } catch (e) {}
      // #endif
    },
    applyDarkMode() {
      // #ifdef H5
      try {
        if (uni.getStorageSync('dark_mode')) {
          document.documentElement.classList.add('dark-mode')
        }
      } catch (e) {}
      // #endif
    },
    // 检查系统是否有 aa 平台发布的新版本（读 sc 后端公开接口，免登录）
    async checkSystemUpdate() {
      try {
        const res = await get('/api/public/update-check')
        if (res && res.code === 0 && res.data && res.data.has_update) {
          const d = res.data
          const content = (d.changelog || d.title || '系统有新版本，请在 PC 端「系统维护 → 系统更新」页面执行更新。').slice(0, 300)
          uni.showModal({
            title: '系统有新版本 v' + d.new_version,
            content,
            showCancel: true,
            cancelText: '知道了',
            confirmText: '去更新',
            confirmColor: '#409EFF',
            success: (r) => {
              if (r.confirm) {
                // 引导用户到 PC 端系统更新页
                uni.showToast({ title: '请在电脑端登录系统后台 → 系统维护 → 系统更新 执行更新', icon: 'none', duration: 3000 })
              }
            }
          })
        }
      } catch (e) {
        // 静默失败（网络异常不打扰用户）
      }
    }
  }
}
</script>

<style lang="scss">
/* uView Plus 全局样式 */
@import "uview-plus/index.scss";

page {
  background-color: $uni-bg-color-grey;
  font-size: $uni-font-size-base;
  color: $uni-text-color;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
}

/* ===== 现代主题增强（v2）===== */
/* 品牌渐变背景 */
.grad-bg {
  background: linear-gradient(135deg, #4F46E5 0%, #7C6FF0 100%);
}
/* 现代卡片：大圆角 + 柔和阴影 */
.modern-card {
  background: #FFFFFF;
  border-radius: $uni-border-radius-lg;
  box-shadow: $uni-shadow-card;
}
/* 主色文字/按钮 */
.text-primary { color: $uni-color-primary; }
/* 全局过渡动效 */
page view, page button, page text {
  transition: all 0.2s ease;
}
/* 列表/页面平滑滚动 */
page {
  scroll-behavior: smooth;
}

/* 全局：所有页面内容顶到头，消除原生导航栏下方多余间距（排除登录页） */
page > view[class$="-page"] {
  padding-top: 0 !important;
  margin-top: 0 !important;
}

/* 登录页特殊处理：覆盖 uview-plus 的全局样式，保留 paddingTop 用于状态栏占位 */
page > view.login-page {
  padding-top: 0 !important;
}

/* 强制登录页保留内联样式的 paddingTop */
uni-page-body > uni-view.login-page {
  padding-top: 0 !important;
}

/* ===== 全局组件现代化（v2.1）===== */
/* 主按钮：品牌渐变 + 大圆角 + 柔和阴影 */
.u-button--primary {
  background: linear-gradient(135deg, #4F46E5 0%, #7C6FF0 100%) !important;
  border: none !important;
  border-radius: 16rpx !important;
  box-shadow: 0 8rpx 20rpx rgba(79,70,229,0.22) !important;
  transition: transform 0.15s ease, box-shadow 0.15s ease !important;
}
.u-button--primary:active {
  transform: scale(0.97) !important;
  box-shadow: 0 4rpx 12rpx rgba(79,70,229,0.18) !important;
}
.u-button--primary.u-button--plain {
  background: #EEF0FE !important;
  color: #4F46E5 !important;
  box-shadow: none !important;
}
/* 标签：大圆角 */
.u-tag { border-radius: 12rpx !important; }
/* 输入框容器：圆角 + 浅底 */
.u-input__content { border-radius: 16rpx !important; }
/* 弹窗圆角 */
.u-popup__content { border-radius: 24rpx 24rpx 0 0 !important; }
/* 单元格圆角 */
.u-cell { border-radius: 16rpx !important; }

/* ===== 深色模式全局主题（v2.3）===== */
/* CSS 变量：浅色默认值定义在 page 上，html.dark-mode 覆盖 */
page, uni-page-body {
  --bg-color: #F4F6FB;
  --card-color: #FFFFFF;
  --text-main: #1a2332;
  --text-sub: #9aabba;
  --text-mute: #8a9aa8;
  --divider-color: #F4F6FB;
  --active-bg: #EDF0F8;
  --accent: #3d5a73;
}
html.dark-mode page, html.dark-mode uni-page-body {
  --bg-color: #14161B;
  --card-color: #1F242D;
  --text-main: #E7ECF3;
  --text-sub: #8A94A6;
  --text-mute: #6E7A8C;
  --divider-color: #2A303B;
  --active-bg: #2A303B;
  --accent: #7FB0D9;
}
html.dark-mode page, html.dark-mode uni-page-body {
  background-color: var(--bg-color) !important;
}
/* 深色模式下的通用列表/输入/弹层兜底 */
html.dark-mode uni-switch .uni-switch-input {
  background-color: #3A4150 !important;
}
/* ===== 深色模式全局兜底（v2.4）===== */
/* 页面最外层容器（以 -page 结尾，scoped 背景覆盖 uni-page-body） */
html.dark-mode [class$="-page"] {
  background: var(--bg-color) !important;
}
/* 原生导航栏 */
html.dark-mode uni-page-head {
  background: var(--card-color) !important;
}
html.dark-mode uni-page-head .uni-page-head__title,
html.dark-mode uni-page-head .uni-page-head__btn {
  color: var(--text-main) !important;
}
/* 底部 tabBar */
html.dark-mode uni-tabbar,
html.dark-mode .uni-tabbar {
  background: var(--card-color) !important;
}
html.dark-mode uni-tabbar .uni-tabbar__label {
  color: var(--text-sub) !important;
}
html.dark-mode uni-tabbar .uni-tabbar__label.uni-tabbar__label--active {
  color: #4F46E5 !important;
}
/* 弹层/弹出框 */
html.dark-mode uni-popup,
html.dark-mode uni-popup .uni-popup,
html.dark-mode .uni-popup__wrapper,
html.dark-mode uni-modal .uni-modal,
html.dark-mode uni-modal .uni-modal__bd {
  background: var(--card-color) !important;
  color: var(--text-main) !important;
}
html.dark-mode uni-modal .uni-modal__title {
  color: var(--text-main) !important;
}
html.dark-mode uni-modal .uni-modal__btn {
  color: var(--text-main) !important;
}
/* 输入框 */
html.dark-mode uni-input,
html.dark-mode uni-textarea,
html.dark-mode .uni-input-input,
html.dark-mode .uni-textarea-textarea {
  color: var(--text-main) !important;
}
/* ===== 深色模式文字与卡片兜底（v2.5）===== */
/* 常见浅底容器 → 深色卡片（兼容列表/卡片/面板/盒子/单元格） */
html.dark-mode [class$="-card"],
html.dark-mode [class$="-panel"],
html.dark-mode [class$="-box"],
html.dark-mode [class$="-cell"],
html.dark-mode [class$="-item"] {
  background: var(--card-color) !important;
}
/* 页面内主文字统一提亮（可读性优先；次级色/品牌色文字会被统一为主色，接受降级） */
html.dark-mode uni-view,
html.dark-mode uni-text {
  color: var(--text-main) !important;
}
/* 白字还原（按钮/图标上的白色文字保持白色，避免在彩色底上变浅色后看不清） */
html.dark-mode .icon-wrap,
html.dark-mode [class$="-icon"] {
  color: #fff !important;
}
html.dark-mode .text-white,
html.dark-mode .white-text,
html.dark-mode .btn-white {
  color: #fff !important;
}
/* 登录页排除：保持品牌渐变与白色内容不被兜底破坏 */
html.dark-mode .login-page uni-view,
html.dark-mode .login-page uni-text {
  color: inherit !important;
}
html.dark-mode .login-page {
  background: inherit !important;
}
/* ===== 深色模式实测白卡补丁（v2.6）===== */
/* 工作台/首页 */
html.dark-mode .wb-nav,
html.dark-mode .wb-stat,
html.dark-mode .wb-quick-item,
html.dark-mode .wb-todo,
/* 我的/首页 */
html.dark-mode .diy2-nav,
html.dark-mode .uc-card,
html.dark-mode .fn-center,
html.dark-mode .fn-toggle,
html.dark-mode .settings-entry,
/* 考勤 */
html.dark-mode .progress-card,
html.dark-mode .loc-card,
html.dark-mode .summary-card,
html.dark-mode .att-tabbar,
/* 消息 */
html.dark-mode .msg-toolbar,
/* 自定义底部导航 */
html.dark-mode .custom-tabbar {
  background: var(--card-color) !important;
}
/* uview-plus 导航栏与常用组件 */
html.dark-mode .u-navbar__inner {
  background: var(--card-color) !important;
}
html.dark-mode .u-cell {
  background: var(--card-color) !important;
}
html.dark-mode .u-cell__title-text,
html.dark-mode .u-cell__value-text {
  color: var(--text-main) !important;
}
html.dark-mode .u-popup__content,
html.dark-mode .u-datetime-picker,
html.dark-mode .u-action-sheet {
  background: var(--card-color) !important;
}
html.dark-mode .u-popup__content uni-text,
html.dark-mode .u-action-sheet uni-text {
  color: var(--text-main) !important;
}
/* ===== 深色模式白卡补丁 v2.7（业务页实测）===== */
html.dark-mode .oa-nav,
html.dark-mode .oa-apply-nav,
html.dark-mode .oa-datetime-date,
html.dark-mode .detail-header,
html.dark-mode .detail-body,
html.dark-mode .search-bar,
html.dark-mode .contact-nav,
html.dark-mode .chat-input-bar,
html.dark-mode .cd-btn,
html.dark-mode .card,
html.dark-mode .report-card,
html.dark-mode .salary-card {
  background: var(--card-color) !important;
}
/* uview 输入框/文本域（白底 → 深色） */
html.dark-mode .u-input,
html.dark-mode .u-textarea,
html.dark-mode .u-input__content,
html.dark-mode .u-textarea__field {
  background: var(--card-color) !important;
  color: var(--text-main) !important;
}
html.dark-mode .u-input__content__field-wrapper uni-text,
html.dark-mode .u-input__content__field-wrapper uni-input,
html.dark-mode .u-textarea__field uni-textarea,
html.dark-mode .u-textarea__field uni-text {
  color: var(--text-main) !important;
}
html.dark-mode .u-input__placeholder,
html.dark-mode .u-textarea__placeholder {
  color: var(--text-mute) !important;
}
/* 按钮：次级白底按钮 → 深色卡片，主文字提亮 */
html.dark-mode .u-button--primary--plain,
html.dark-mode .u-button--error--plain,
html.dark-mode .u-button--success--plain,
html.dark-mode .u-button--warning--plain {
  background: var(--card-color) !important;
}
html.dark-mode .submit-btn,
html.dark-mode .ghost {
  background: var(--card-color) !important;
  color: var(--text-main) !important;
}
/* ===== 深色模式白卡补丁 v2.8 ===== */
html.dark-mode .ah-tabs,
html.dark-mode .about-header,
html.dark-mode .help-list,
html.dark-mode .my-tabbar,
html.dark-mode .at-tabbar,
html.dark-mode .tab-item {
  background: var(--card-color) !important;
}
html.dark-mode .ah-tabs uni-text,
html.dark-mode .ah-tabs .result uni-text {
  color: var(--text-main) !important;
}
/* ===== 深色模式白卡补丁 v2.9（通用容器） ===== */
html.dark-mode .section,
html.dark-mode .bottom-bar,
html.dark-mode .tabs,
html.dark-mode .block,
html.dark-mode .content-card,
html.dark-mode .list-card,
html.dark-mode .item-card {
  background: var(--card-color) !important;
}
html.dark-mode .bottom-bar uni-text,
html.dark-mode .tabs uni-text {
  color: var(--text-main) !important;
}
/* ===== 深色模式白卡补丁 v2.10 ===== */
html.dark-mode .ma-filter,
html.dark-mode .tf-section,
html.dark-mode .rt-section,
html.dark-mode .ap-tab,
html.dark-mode .ap-form,
html.dark-mode .mr-tabs {
  background: var(--card-color) !important;
}
/* icon-wrap 白底图标块 → 深色卡（设置页彩色内联背景在深色下统一为深色卡 + 白图标） */
html.dark-mode .icon-wrap {
  background: var(--card-color) !important;
}
</style>
