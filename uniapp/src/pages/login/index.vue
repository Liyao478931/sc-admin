<template>
<view class="login-page" :style="{ background: bgColor, paddingTop: statusBarHeight + 'px' }">
  <!-- 背景图 -->
  <image v-if="bgType==='image' && bgImage" :src="bgImage" mode="aspectFill" class="bg-img" />
  <!-- 渐变背景 -->
  <view v-if="bgType==='gradient'" class="bg-gradient" :style="{ background: 'linear-gradient(' + gradientDirection + ',' + gradientStart + ',' + gradientEnd + ')' }"></view>
  <!-- 粒子背景 -->
  <canvas v-if="bgType==='particle'" class="particle-canvas" canvas-id="pc"></canvas>

  <!-- 卡片容器 -->
  <view class="card-wrap" :style="cardPosStyle">
    <view class="card" :style="cardStyle">

      <!-- ===== 品牌区 ===== -->
      <view class="brand">
        <view class="logo-wrap">
          <image v-if="logo" :src="logo" class="logo-img" mode="aspectFit" />
          <u-icon v-else name="grid-fill" color="#4F46E5" :size="30" />
        </view>
        <text class="bn" :style="bnStyle">{{ appName }}</text>
        <text class="bs" :style="{ color: sloganColor }">{{ slogan }}</text>
      </view>

      <!-- ===== 当前方式标题 ===== -->
      <view class="method-title">
        <u-icon :name="methodIcon" :color="accentColor" :size="14" />
        <text>{{ methodTitle }}</text>
      </view>

      <!-- ===== 密码登录 ===== -->
      <view v-show="tab === 'password'" class="login-panel">
        <view class="fld">
          <u-input v-model="username" placeholder="请输入工号或手机号" prefixIcon="account" border="none" :customStyle="inputStyle" />
        </view>
        <view class="fld">
          <u-input v-model="password" :type="see ? 'text' : 'password'" placeholder="请输入密码" prefixIcon="lock" border="none" :customStyle="inputStyle">
            <template #suffix>
              <u-icon :name="see ? 'eye-off' : 'eye'" size="18" color="#b0bcc8" @click="see = !see" />
            </template>
          </u-input>
        </view>
        <view class="fld cf">
          <u-input v-model="captchaCode" type="text" maxlength="4" placeholder="验证码计算结果" prefixIcon="info-circle" border="none" :customStyle="inputStyle" />
          <view class="captcha-box" @click="loadCaptcha"><text>{{ captchaExpr || '加载中...' }}</text><MIcon name="refresh" :size="13" color="#8a9aa8" /></view>
        </view>
        <view class="er" v-if="err">{{ err }}</view>
        <view class="form-options">
          <text class="forgot" @click="tab = 'sms'">忘记密码？</text>
        </view>
        <u-button :text="loading ? '登录中...' : btnText" type="primary" shape="circle" :loading="loading" :customStyle="btnCustom" @click="pwdLogin" />
        <view class="agree-row" @click="toggleAgree">
  <view class="agree-box" :class="{ 'agree-on': agreed }"><text v-if="agreed" class="agree-check">✓</text></view>
  <text class="agree-txt">我已阅读并同意 <text class="agree-link" @click.stop="showAgreement">《用户协议》</text> 和 <text class="agree-link" @click.stop="showPrivacy">《隐私政策》</text></text>
</view>
      </view>

      <!-- ===== 微信一键登录 ===== -->
      <view v-show="tab === 'wechat'" class="login-panel wechat-panel">
        <view class="wx-icon-big" @click="wechatLogin">
          <view class="wx-circle">
            <u-icon name="weixin-fill" color="#ffffff" size="30" />
          </view>
        </view>
        <text class="wx-hint">点击微信图标一键登录</text>
<view class="agree-row" @click="toggleAgree">
  <view class="agree-box" :class="{ 'agree-on': agreed }"><text v-if="agreed" class="agree-check">✓</text></view>
  <text class="agree-txt">我已阅读并同意 <text class="agree-link" @click.stop="showAgreement">《用户协议》</text> 和 <text class="agree-link" @click.stop="showPrivacy">《隐私政策》</text></text>
</view>
      </view>

      <!-- ===== 短信验证码登录 ===== -->
      <view v-show="tab === 'sms'" class="login-panel">
        <view class="fld">
          <u-input v-model="phone" type="number" maxlength="11" placeholder="请输入手机号" prefixIcon="phone" border="none" :customStyle="inputStyle" />
        </view>
        <view class="fld cf">
          <u-input v-model="code" type="number" maxlength="6" placeholder="请输入短信验证码" prefixIcon="info-circle" border="none" :customStyle="inputStyle" />
          <u-button :text="cd > 0 ? cd + 's' : '获取验证码'" size="small" color="#4a6fa5" shape="circle" :disabled="cd > 0" :customStyle="captchaBtnStyle" @click="sendCode" />
        </view>
        <view class="er" v-if="err">{{ err }}</view>
        <u-button :text="loading ? '登录中...' : btnText" type="primary" shape="circle" :loading="loading" :customStyle="btnCustom" @click="smsLogin" />
        <view class="agree-row" @click="toggleAgree">
  <view class="agree-box" :class="{ 'agree-on': agreed }"><text v-if="agreed" class="agree-check">✓</text></view>
  <text class="agree-txt">我已阅读并同意 <text class="agree-link" @click.stop="showAgreement">《用户协议》</text> 和 <text class="agree-link" @click.stop="showPrivacy">《隐私政策》</text></text>
</view>
      </view>

      <!-- ===== 绑定手机号 ===== -->
      <view v-show="tab === 'bind'" class="login-panel">
        <text class="bind-title">绑定手机号</text>
        <view class="fld">
          <u-input v-model="bindPhone" type="number" maxlength="11" placeholder="绑定手机号" prefixIcon="phone" border="none" :customStyle="inputStyle" />
        </view>
        <view class="fld cf">
          <u-input v-model="bindCode" type="number" maxlength="6" placeholder="验证码" prefixIcon="info-circle" border="none" :customStyle="inputStyle" />
          <u-button :text="bindCd > 0 ? bindCd + 's' : '获取验证码'" size="small" color="#4a6fa5" shape="circle" :disabled="bindCd > 0" :customStyle="captchaBtnStyle" @click="sendBindCode" />
        </view>
        <view class="er" v-if="err">{{ err }}</view>
        <u-button :text="loading ? '绑定中...' : '绑定并登录'" type="primary" shape="circle" :loading="loading" :customStyle="btnCustom" @click="doBind" />
<view class="agree-row" @click="toggleAgree">
  <view class="agree-box" :class="{ 'agree-on': agreed }"><text v-if="agreed" class="agree-check">✓</text></view>
  <text class="agree-txt">我已阅读并同意 <text class="agree-link" @click.stop="showAgreement">《用户协议》</text> 和 <text class="agree-link" @click.stop="showPrivacy">《隐私政策》</text></text>
</view>
      </view>

    </view>
  </view>

  <!-- ===== 分割线 + 其他方式 ===== -->
  <view v-if="tabs.length > 1" class="divider">
    <view class="line"></view>
    <text class="text">其他方式</text>
    <view class="line"></view>
  </view>
  <view v-if="tabs.length > 1" class="social-login">
    <view v-for="m in tabs" :key="m.key" class="social-btn" :class="{ active: tab === m.key }" @click="switchTab(m.key)">
      <view class="icon-wrap"><u-icon :name="iconMap[m.key]" :color="colorMap[m.key]" size="20" /></view>
      <text class="label">{{ m.label }}</text>
    </view>
  </view>

  <!-- ===== 底部版权 ===== -->
  <view class="ft">{{ copyright }}</view>
</view>
</template>

<script>
export default {
  data() {
    return {
      tab: 'password',
      username: '',
      password: '',
      phone: '',
      code: '',
      captchaId: '',
      captchaExpr: '',
      captchaCode: '',
      loading: false,
      err: '',
      cd: 0,
      see: false,
      agreed: false,
      timer: null,
      wxLoading: false,
      wxOpenid: '',
      bindPhone: '',
      bindCode: '',
      bindCd: 0,
      bindTimer: null,
      // 后台配置
      logo: '', appName: '企业管理系统', appNameColor: '#1a2a3a', slogan: '高效 · 安全 · 智能', sloganColor: 'rgba(26,42,58,0.5)',
      brandGradient: '0', welcomeTitle: '登录工业控制平台', highlightWord: '工业控制平台',
      highlightStart: '#4a6fa5', highlightEnd: '#3a5a8a',
      statusText: '系统运行中', statusDotColor: '#4a6fa5',
      statusBarHeight: 0,
      bgColor: '#f5f5f5', bgType: 'gradient', bgImage: '', bgImageFit: 'cover',
      gradientDirection: 'to bottom', gradientStart: '#f0f4f9', gradientEnd: '#e6ecf5',
      particleColor: '#00b4ff', particleCount: '100', particleSpeed: '0.4', particleDistance: '80',
      cardEnabled: '1', cardPosition: 'center', cardWidth: '420', cardBg: '#ffffff',
      cardOpacity: '1', cardRadius: '32', cardShadow: 'medium', cardBlur: '0',
      btnText: '登 录', btnBg: '#4a6fa5', btnBorder: 'transparent', btnColor: '#ffffff',
      btnRadius: '14', btnHeight: '52', btnBlur: '0', btnGlow: '0', btnGlowColor: '#4a6fa5',
      inputBg: '#f7f9fb', inputBorder: 'transparent', inputColor: '#1a2a3a', labelColor: '#6a7e8a',
      methods: [], copyright: '', pr: false, redirect: '',
      defaultConfig: {
        logo: '', appName: '企业管理系统', appNameColor: '#1a2a3a', slogan: '高效 · 安全 · 智能', sloganColor: 'rgba(26,42,58,0.5)',
        brandGradient: '0', welcomeTitle: '登录工业控制平台', highlightWord: '工业控制平台',
        highlightStart: '#4a6fa5', highlightEnd: '#3a5a8a', statusText: '系统运行中', statusDotColor: '#4a6fa5',
        bgColor: '#f5f5f5', bgType: 'gradient', bgImage: '', gradientDirection: 'to bottom', gradientStart: '#f0f4f9', gradientEnd: '#e6ecf5',
        particleColor: '#00b4ff', particleCount: '80', particleSpeed: '0.4', particleDistance: '80',
        cardEnabled: '1', cardPosition: 'center', cardWidth: '420', cardBg: '#ffffff', cardOpacity: '1', cardRadius: '32', cardShadow: 'medium', cardBlur: '0',
        btnText: '登 录', btnBg: '#4a6fa5', btnBorder: 'transparent', btnColor: '#ffffff', btnRadius: '14', btnHeight: '52', btnBlur: '0', btnGlow: '0', btnGlowColor: '#4a6fa5',
        inputBg: '#f7f9fb', inputBorder: 'transparent', inputColor: '#1a2a3a', labelColor: '#6a7e8a'
      }
    }
  },
  computed: {
    hasWechat() { return this.methods.includes('wechat') },
    tabs() {
      const map = { password: '密码', sms: '短信', wechat: '微信' }
      return (this.methods && this.methods.length ? this.methods : ['password']).map(key => ({ key, label: map[key] || key }))
    },
    iconMap() { return { password: 'lock', sms: 'phone', wechat: 'weixin-fill' } },
    colorMap() { return { password: '#4a6fa5', sms: '#f39c12', wechat: '#07c160' } },
    methodTitle() {
      const map = { password: '密码登录', sms: '短信验证码登录', wechat: '微信一键登录', bind: '绑定手机号' }
      return map[this.tab] || '登录'
    },
    methodIcon() { return this.iconMap[this.tab] || 'lock' },
    accentColor() { return this.btnBg || '#4a6fa5' },
    bnStyle() {
      if (this.brandGradient === '1') return { backgroundImage: 'linear-gradient(135deg,' + this.highlightStart + ',' + this.highlightEnd + ')', WebkitBackgroundClip: 'text', WebkitTextFillColor: 'transparent', backgroundClip: 'text' }
      return { color: this.appNameColor }
    },
    cardPosStyle() {
      if (this.cardPosition === 'left') return { alignItems: 'flex-start' }
      if (this.cardPosition === 'right') return { alignItems: 'flex-end' }
      return { alignItems: 'center' }
    },
    cardStyle() {
      if (this.cardEnabled !== '1') return {}
      const shadowMap = { none: 'none', light: '0 4px 16px rgba(0,0,0,0.06)', medium: '0 8px 30px rgba(0,0,0,0.08)', heavy: '0 16px 48px rgba(0,0,0,0.14)' }
      return {
        width: '100%', maxWidth: '100%',
        background: this.cardBg,
        borderRadius: parseInt(this.cardRadius) + 'px',
        padding: '32px 24px 28px',
        boxShadow: shadowMap[this.cardShadow] || shadowMap.medium,
        backdropFilter: this.cardBlur === '1' ? 'blur(12px)' : 'none'
      }
    },
    inputStyle() {
      return { background: this.inputBg, borderRadius: '14px', height: '50px', fontSize: '15px', color: this.inputColor, padding: '0 12px' }
    },
    btnCustom() {
      return {
        height: '50px', borderRadius: '14px', background: this.btnBg, color: this.btnColor,
        fontSize: '16px', fontWeight: '600', letterSpacing: '1px', boxShadow: '0 4px 16px rgba(74,111,165,0.14)'
      }
    },
    captchaBtnStyle() { return { height: '38px', borderRadius: '10px' } }
  },
  watch: {
    bgType(v) { if (v === 'particle') this.$nextTick(() => this.initParticle()); else this.pr = false }
  },
  onLoad() {
    // 小程序自定义导航：顶部安全占位（状态栏 + 胶囊按钮高度）
    // #ifdef MP-WEIXIN
    try {
      const info = uni.getSystemInfoSync()
      const sb = info.statusBarHeight || 0
      let inset = sb
      if (typeof uni.getMenuButtonBoundingClientRect === 'function') {
        const m = uni.getMenuButtonBoundingClientRect()
        inset = (m && m.bottom) ? (m.bottom + 4) : (sb + 44)
      }
      this.statusBarHeight = inset
    } catch (e) { this.statusBarHeight = 44 }
    // #endif
    const hasToken = uni.getStorageSync('access_token') || uni.getStorageSync('token')
    const rd0 = this.getUrlParam('redirect')
    if (hasToken && !rd0) {
      // 校验本地 token 是否仍有效：有效才直接进首页；失效则清除残留并显示登录表单
      this.verifyTokenAndRedirect()
      return
    } else if (hasToken && rd0) {
      // 有 redirect 时进入登录页：校验 token 有效性，有效则按 redirect 跳转
      this.verifyTokenAndRedirect()
      return
    }
    this.init()
    this.loadCaptcha()
    // 登录成功后的跳转目标（DIY 页权限跳转携带 redirect，getUrlParam 已解码）
    const rd = this.getUrlParam('redirect')
    if (rd) this.redirect = rd
    // #ifdef H5
    const bindOpenid = this.getUrlParam('bind_openid')
    if (bindOpenid) { this.wxOpenid = bindOpenid; this.tab = 'bind'; this.err = '该微信未绑定员工，请输入手机号绑定后登录' }
    const urlToken = this.getUrlParam('token')
    if (urlToken) { uni.setStorageSync('token', urlToken); uni.setStorageSync('access_token', urlToken); this.goAfterLogin(); return }
    const code = this.getUrlParam('code')
    if (code) {
      uni.request({
        url: uni.$base + '/api/mobile/wechat/mp-login', method: 'POST', data: { code }, header: { 'Content-Type': 'application/x-www-form-urlencoded' },
        success: (res) => {
          if (res.data && res.data.code === 0 && res.data.data && res.data.data.token) {
            uni.setStorageSync('token', res.data.data.token); uni.setStorageSync('access_token', res.data.data.token)
            this.goAfterLogin()
          } else if (res.data && res.data.code === 1001) {
            this.wxOpenid = res.data.data?.openid || res.data.openid || ''; this.tab = 'bind'; this.err = '请绑定手机号'
          } else { this.err = (res.data && res.data.msg) || '微信登录失败' }
        },
        fail: () => { this.err = '网络异常，请重试' }
      })
    }
    // #endif
  },
  onUnload() { this.pr = false; if (this.timer) clearInterval(this.timer); if (this.bindTimer) clearInterval(this.bindTimer); if (this.animId) cancelAnimationFrame(this.animId) },
  // 小程序分享（页面级，确保可转发）
  // #ifdef MP-WEIXIN
  onShareAppMessage() {
    return { title: '企业管理系统', path: '/pages/login/index' }
  },
  onShareTimeline() {
    return { title: '企业管理系统' }
  },
  // #endif
  onHide() { if (this.pr) this.pr = false },
  onShow() {
    if (this.bgType === 'particle') { this.pr = true; this.initParticle() }
    // 回到登录页时验证码未加载则补加载（覆盖从其他页返回场景）
    if (this.tab === 'password' && !this.captchaExpr) this.loadCaptcha()
  },
  methods: {
    getUrlParam(name) {
      // #ifdef H5
      const hashIndex = window.location.href.indexOf('#')
      const searchPart = window.location.search
      const hashPart = hashIndex >= 0 ? window.location.href.slice(hashIndex + 1) : ''
      const combined = (searchPart ? searchPart.slice(1) : '') + (hashPart.indexOf('?') >= 0 ? '&' + hashPart.split('?')[1] : '')
      const reg = new RegExp('(^|&)' + name + '=([^&]*)(&|$)')
      const r = combined.match(reg)
      if (r != null) return decodeURIComponent(r[2])
      return null
      // #endif
      // #ifndef H5
      return null
      // #endif
    },
    /** 登录成功后的统一跳转：优先 redirect（DIY 权限跳转），否则默认首页 */
    goAfterLogin() {
      const target = this.redirect && this.redirect.startsWith('/pages') ? this.redirect : '/pages/diy/index?type=home'
      uni.reLaunch({ url: target })
    },
    /**
     * 校验本地 token 有效性：
     *  - 有效：按 redirect 或首页跳转（自动登录）
     *  - 失效/过期：清除残留 token，留在登录页展示表单
     */
    verifyTokenAndRedirect() {
      const token = uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
      if (!token) { this.init(); this.loadCaptcha(); return }
      const self = this
      uni.request({
        url: uni.$base + '/api/user/profile', method: 'GET',
        header: { 'Content-Type': 'application/x-www-form-urlencoded', 'Authorization': 'Bearer ' + token }, timeout: 8000,
        success: (r) => {
          // 有效：code===0 且有用户数据
          if (r.data && r.data.code === 0 && r.data.data) {
            self.goAfterLogin()
            return
          }
          // 失效：清除残留，显示登录表单
          uni.removeStorageSync('access_token')
          uni.removeStorageSync('token')
          uni.removeStorageSync('userInfo')
          self.init()
          self.loadCaptcha()
        },
        fail: () => {
          // 网络异常时不阻塞：清除本地残留（避免死循环），显示登录表单
          uni.removeStorageSync('access_token')
          uni.removeStorageSync('token')
          uni.removeStorageSync('userInfo')
          self.init()
          self.loadCaptcha()
        }
      })
    },
    init() {
      // 平台标识：小程序传 mini（后端据此返回微信登录方式）
      let platform = ''
      try {
        const sys = uni.getSystemInfoSync()
        if (sys && (sys.uniPlatform === 'mp-weixin' || sys.platform === 'devtools')) platform = 'mini'
      } catch (e) {}
      Promise.all([
        this.fetchConfig('/api/app/login-page-config'),
        this.fetchConfig('/api/app/login-methods' + (platform ? '?platform=' + platform : '')),
        this.fetchConfig('/api/settings/footer-config')
      ]).then(([pageConfig, methodsRes, footerRes]) => {
        if (pageConfig) this.applyConfig(pageConfig)
        if (methodsRes) this.applyMethods(methodsRes)
        if (footerRes) this.applyFooter(footerRes)
      }).catch(() => { this.applyDefaultConfig() })
    },
    fetchConfig(url) {
      return new Promise((resolve) => {
        uni.request({ url: uni.$base + url, timeout: 10000, success: (res) => { resolve(res.data && res.data.code === 0 && res.data.data ? res.data.data : null) }, fail: () => resolve(null) })
      })
    },
    applyConfig(c) {
      if (!c) return
      const map = {
        logo: 'login_page_logo', appName: 'login_page_system_name', appNameColor: 'login_page_system_name_color',
        slogan: 'login_page_subtitle', sloganColor: 'login_page_subtitle_color', brandGradient: 'login_page_brand_gradient',
        welcomeTitle: 'login_page_welcome_title', highlightWord: 'login_page_highlight_word',
        highlightStart: 'login_page_highlight_start', highlightEnd: 'login_page_highlight_end',
        statusText: 'login_page_status_text', statusDotColor: 'login_page_status_dot',
        bgColor: 'login_page_bg_color', bgType: 'login_page_bg_type', bgImage: 'login_page_bg_image',
        gradientDirection: 'login_page_gradient_direction', gradientStart: 'login_page_gradient_start', gradientEnd: 'login_page_gradient_end',
        particleColor: 'login_page_particle_color', particleCount: 'login_page_particle_count', particleSpeed: 'login_page_particle_speed', particleDistance: 'login_page_particle_distance',
        cardEnabled: 'login_page_card_enabled', cardPosition: 'login_page_card_position', cardWidth: 'login_page_card_width',
        cardBg: 'login_page_card_bg', cardOpacity: 'login_page_card_opacity', cardRadius: 'login_page_card_radius',
        cardShadow: 'login_page_card_shadow', cardBlur: 'login_page_card_blur',
        btnText: 'login_page_btn_text', btnBg: 'login_page_btn_bg', btnBorder: 'login_page_btn_border', btnColor: 'login_page_btn_color',
        btnRadius: 'login_page_btn_radius', btnHeight: 'login_page_btn_height', btnBlur: 'login_page_btn_blur', btnGlow: 'login_page_btn_glow', btnGlowColor: 'login_page_btn_glow_color',
        inputBg: 'login_page_input_bg', inputBorder: 'login_page_input_border', inputColor: 'login_page_input_color', labelColor: 'login_page_label_color'
      }
      for (const key in map) { if (c[map[key]] !== undefined && c[map[key]] !== null) this[key] = c[map[key]] }
    },
    applyDefaultConfig() { const c = this.defaultConfig; for (const key in c) this[key] = c[key] },
    applyMethods(r) {
      if (r && r.methods) {
        this.methods = r.methods
        if (this.tab !== 'bind') this.tab = r.default || this.methods[0] || 'password'
      }
    },
    applyFooter(f) {
      if (!f) return
      const parts = []
      if (f.copyright) parts.push(f.copyright)
      if (f.show_icp && f.icp) parts.push(f.icp)
      if (f.show_police && f.police) parts.push(f.police)
      this.copyright = parts.join('\n')
    },
    switchTab(key) { if (this.tab !== 'bind') this.tab = key },
    loadCaptcha() {
      const self = this
      uni.request({
        url: uni.$base + '/api/auth/captcha', method: 'GET', timeout: 10000,
        success: (r) => { if (r.data && r.data.code === 0 && r.data.data) { self.captchaId = r.data.data.captcha_id; self.captchaExpr = r.data.data.expression; self.captchaCode = '' } else { self.captchaExpr = '' } },
        fail: () => { self.captchaExpr = '' }
      })
    },
    pwdLogin() {
      if (!this.username || !this.password) { this.err = '请输入用户名和密码'; return }
      if (!this.agreed) { this.err = '请先阅读并同意用户协议和隐私政策'; return }
      this.loading = true; this.err = ''
      const self = this
      uni.request({
        url: uni.$base + '/api/auth/login', method: 'POST',
        data: { username: this.username, password: this.password, captcha_id: this.captchaId, captcha_code: this.captchaCode },
        header: { 'Content-Type': 'application/x-www-form-urlencoded' }, timeout: 10000,
        success: (r) => {
          self.loading = false
          if (r.data && r.data.code === 0 && r.data.data && r.data.data.token) {
            uni.setStorageSync('token', r.data.data.token); uni.setStorageSync('access_token', r.data.data.token)
            this.goAfterLogin()
          } else { self.err = (r.data && r.data.msg) || '登录失败' }
        },
        fail: () => { self.loading = false; self.err = '网络异常' }
      })
    },
    sendCode() {
      if (!/^1\d{10}$/.test(this.phone)) { this.err = '请输入正确手机号'; return }
      this.err = ''
      const self = this
      uni.request({
        url: uni.$base + '/api/mobile/send-sms', method: 'POST',
        data: { phone: this.phone, type: 'login' },
        header: { 'Content-Type': 'application/x-www-form-urlencoded' }, timeout: 10000,
        success: () => { self.cd = 60; self.timer = setInterval(() => { if (--self.cd <= 0) { clearInterval(self.timer); self.timer = null } }, 1000) },
        fail: () => { self.err = '发送失败' }
      })
    },
    smsLogin() {
      if (!/^1\d{10}$/.test(this.phone) || !/^\d{6}$/.test(this.code)) { this.err = '请输入正确信息'; return }
      if (!this.agreed) { this.err = '请先阅读并同意用户协议和隐私政策'; return }
      this.loading = true; this.err = ''
      const self = this
      uni.request({
        url: uni.$base + '/api/mobile/login', method: 'POST',
        data: { phone: this.phone, code: this.code },
        header: { 'Content-Type': 'application/x-www-form-urlencoded' }, timeout: 10000,
        success: (r) => {
          self.loading = false
          if (r.data && r.data.code === 0 && r.data.data && r.data.data.token) {
            uni.setStorageSync('token', r.data.data.token); uni.setStorageSync('access_token', r.data.data.token)
            this.goAfterLogin()
          } else { self.err = (r.data && r.data.msg) || '登录失败' }
        },
        fail: () => { self.loading = false; self.err = '网络异常' }
      })
    },
    toggleAgree() { this.agreed = !this.agreed },
    showAgreement() { window.location.hash = '#/pages/agreement/index?type=user' },
    showPrivacy() { window.location.hash = '#/pages/agreement/index?type=privacy' },
    wechatLogin() {
      if (!this.agreed) { this.err = '请先阅读并同意用户协议和隐私政策'; return }
      if (this.wxLoading) return
      this.wxLoading = true; this.err = ''
      const self = this
      // #ifdef MP-WEIXIN
      // 小程序：直接调起微信授权登录（AppID 由 manifest 配置，后端 mini-login 换 openid）
      uni.login({
        provider: 'weixin',
        success: (loginRes) => {
          uni.request({
            url: uni.$base + '/api/mobile/wechat/mini-login', method: 'POST',
            data: { code: loginRes.code },
            header: { 'Content-Type': 'application/x-www-form-urlencoded' },
            success: (res) => {
              self.wxLoading = false
              if (res.data && res.data.code === 0 && res.data.data && res.data.data.token) {
                uni.setStorageSync('token', res.data.data.token); uni.setStorageSync('access_token', res.data.data.token)
                this.goAfterLogin()
              } else if (res.data && res.data.code === 1001) {
                // 需要绑定手机号：保存 openid 并切到绑定表单
                self.wxOpenid = (res.data.data && res.data.data.openid) || ''
                self.tab = 'bind'
                self.err = '该微信未绑定员工，请输入手机号绑定后登录'
              } else {
                self.err = (res.data && res.data.msg) || '微信登录失败'
                uni.showModal({ title: '微信登录', content: self.err, showCancel: false })
              }
            },
            fail: () => { self.wxLoading = false; self.err = '微信登录接口请求失败'; uni.showModal({ title: '微信登录', content: '微信登录接口请求失败，请稍后重试', showCancel: false }) }
          })
        },
        fail: (err) => { self.wxLoading = false; self.err = '微信授权失败：' + (err.errMsg || '未知错误'); uni.showModal({ title: '微信登录', content: '微信授权失败：' + (err.errMsg || '未知错误'), showCancel: false }) }
      })
      return
      // #endif
      // #ifdef H5
      const isWechat = /MicroMessenger/i.test(navigator.userAgent)
      if (!isWechat) { uni.showModal({ title: '提示', content: '请在微信内置浏览器中打开此页面，或使用密码/短信登录', showCancel: false, success: () => { self.wxLoading = false } }); return }
      // #endif
      // 平台标识：小程序传 mini（后端返回微信登录配置）
      let pf = ''
      // #ifdef MP-WEIXIN
      pf = 'mini'
      // #endif
      uni.request({
        url: uni.$base + '/api/app/login-methods' + (pf ? '?platform=' + pf : ''),
        success: (r) => {
          if (r.data && r.data.code === 0 && r.data.data) {
            const d = r.data.data
            if (d.wechat && d.wechat.app_id) {
              // #ifdef H5
              uni.request({
                url: uni.$base + '/api/mobile/wechat/oauth-url', data: { mode: 'login', state: '/h5/#/pages/workbench/index' },
                success: (r2) => { self.wxLoading = false; if (r2.data && r2.data.code === 0 && r2.data.data && r2.data.data.url) window.location.href = r2.data.data.url; else self.err = (r2.data && r2.data.msg) || '获取微信授权链接失败' },
                fail: () => { self.wxLoading = false; self.err = '网络异常，请重试' }
              })
              // #endif
              // #ifdef MP-WEIXIN
              uni.login({ provider: 'weixin', success: (loginRes) => { uni.request({ url: uni.$base + '/api/mobile/wechat/mini-login', method: 'POST', data: { code: loginRes.code }, header: { 'Content-Type': 'application/x-www-form-urlencoded' }, success: (res) => { self.wxLoading = false; if (res.data && res.data.code === 0 && res.data.data && res.data.data.token) { uni.setStorageSync('token', res.data.data.token); uni.setStorageSync('access_token', res.data.data.token); this.goAfterLogin() } else { self.err = (res.data && res.data.msg) || '微信登录失败' } }, fail: () => { self.wxLoading = false; self.err = '微信登录接口请求失败' } }) }, fail: (err) => { self.wxLoading = false; self.err = '微信授权失败：' + (err.errMsg || '未知错误') } })
              // #endif
              // #ifdef APP-PLUS
              uni.showModal({ title: '提示', content: 'App端微信登录功能开发中，请使用密码或短信登录', showCancel: false, success: () => { self.wxLoading = false } })
              // #endif
            } else { self.wxLoading = false; self.err = '微信登录暂未配置，请在后台配置 AppID' }
          } else { self.wxLoading = false; self.err = '获取登录配置失败' }
        },
        fail: () => { self.wxLoading = false; self.err = '网络异常，无法获取配置' }
      })
    },
    sendBindCode() {
      if (!/^1\d{10}$/.test(this.bindPhone)) { this.err = '请输入正确手机号'; return }
      this.err = ''
      const self = this
      uni.request({
        url: uni.$base + '/api/mobile/send-sms', method: 'POST',
        data: { phone: this.bindPhone, type: 'bind' },
        header: { 'Content-Type': 'application/x-www-form-urlencoded' }, timeout: 10000,
        success: () => { self.bindCd = 60; self.bindTimer = setInterval(() => { if (--self.bindCd <= 0) { clearInterval(self.bindTimer); self.bindTimer = null } }, 1000) },
        fail: () => { self.err = '发送失败' }
      })
    },
    doBind() {
      if (!this.agreed) { this.err = '请先阅读并同意用户协议和隐私政策'; return }
      if (!/^1\d{10}$/.test(this.bindPhone)) { this.err = '请输入正确手机号'; return }
      if (!/^\d{6}$/.test(this.bindCode)) { this.err = '请输入6位验证码'; return }
      if (!this.wxOpenid) { this.err = '微信信息缺失，请重新登录'; return }
      this.loading = true; this.err = ''
      const self = this
      // 平台：小程序=1（wx_mini_openid），公众号/H5=2（wechat_oa_openid）
      let pf = 2
      // #ifdef MP-WEIXIN
      pf = 1
      // #endif
      uni.request({
        url: uni.$base + '/api/mobile/wechat/bind', method: 'POST',
        data: { openid: this.wxOpenid, phone: this.bindPhone, code: this.bindCode, platform: pf },
        header: { 'Content-Type': 'application/x-www-form-urlencoded' }, timeout: 10000,
        success: (r) => {
          self.loading = false
          if (r.data && r.data.code === 0 && r.data.data && r.data.data.token) {
            uni.setStorageSync('token', r.data.data.token); uni.setStorageSync('access_token', r.data.data.token)
            this.goAfterLogin()
          } else { self.err = (r.data && r.data.msg) || '绑定失败' }
        },
        fail: () => { self.loading = false; self.err = '网络异常' }
      })
    },
    initParticle() {
      if (!this.pr) this.pr = true
      const ctx = uni.createCanvasContext('pc', this)
      const sysInfo = uni.getSystemInfoSync()
      const width = sysInfo.screenWidth, height = sysInfo.screenHeight
      const canvas = document ? document.getElementById('pc') : null
      if (canvas) { canvas.width = width; canvas.height = height; canvas.style.width = width + 'px'; canvas.style.height = height + 'px' }
      const count = parseInt(this.particleCount) || (width < 375 ? 60 : 80)
      const speed = parseFloat(this.particleSpeed) || 0.4
      const dist = parseInt(this.particleDistance) || 80
      const color = this.particleColor || '#00b4ff'
      let particles = []
      for (let i = 0; i < count; i++) particles.push({ x: Math.random() * width, y: Math.random() * height, vx: (Math.random() - 0.5) * speed, vy: (Math.random() - 0.5) * speed })
      const draw = () => {
        if (!this.pr) return
        ctx.clearRect(0, 0, width, height)
        for (const p of particles) {
          p.x += p.vx; p.y += p.vy
          if (p.x < 0 || p.x > width) p.vx *= -1
          if (p.y < 0 || p.y > height) p.vy *= -1
          ctx.beginPath(); ctx.arc(p.x, p.y, 1.5, 0, Math.PI * 2); ctx.setFillStyle(color); ctx.globalAlpha = 0.4; ctx.fill(); ctx.globalAlpha = 1
        }
        for (let i = 0; i < particles.length; i++) {
          for (let j = i + 1; j < particles.length; j++) {
            const dx = particles[i].x - particles[j].x, dy = particles[i].y - particles[j].y
            const d = Math.sqrt(dx * dx + dy * dy)
            if (d < dist) { ctx.beginPath(); ctx.moveTo(particles[i].x, particles[i].y); ctx.lineTo(particles[j].x, particles[j].y); ctx.setStrokeStyle(color); ctx.globalAlpha = 0.15 * (1 - d / dist); ctx.stroke(); ctx.globalAlpha = 1 }
          }
        }
        ctx.draw()
        this.animId = requestAnimationFrame(draw)
      }
      draw()
    }
  }
}
</script>

<style lang="scss" scoped>
.login-page { position: relative; min-height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: center; overflow: hidden; }
.bg-img { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; }
.bg-gradient { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; }
.particle-canvas { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: 0; }

.card-wrap { width: 100%; max-width: 420px; padding: 20px; position: relative; z-index: 2; display: flex; flex-direction: column; box-sizing: border-box; }
.card { box-sizing: border-box; position: relative; overflow: hidden; }
.card::before { content: ''; position: absolute; top: -60px; right: -60px; width: 160px; height: 160px; background: linear-gradient(135deg, #4F46E5, #7C6FF0); border-radius:50%; opacity: 0.06; }
.card::after { content: ''; position: absolute; bottom: -80px; left: -80px; width: 200px; height: 200px; background: linear-gradient(135deg, #4F46E5, #7C6FF0); border-radius:50%; opacity: 0.05; }

.brand { text-align: center; margin-bottom: 24px; position: relative; z-index: 2; }
.logo-wrap { width: 64px; height: 64px; border-radius:24px; background: transparent; display: flex; align-items: center; justify-content: center; margin: 0 auto 12px; box-shadow: none; }
.logo-img { width: 100%; height: 100%; border-radius:24px; }
.bn { display: block; font-size: 20px; font-weight: 700; color: #1a2a3a; }
.bs { display: block; font-size: 13px; margin-top: 4px; }

.method-title { text-align: center; font-size: 15px; font-weight: 600; color: #1a2a3a; margin-bottom: 18px; display: flex; align-items: center; justify-content: center; gap: 6px; position: relative; z-index: 2; }
.login-panel { position: relative; z-index: 2; }
.fld { margin-bottom: 14px; position: relative; }
.fld ::v-deep .u-input { border-radius:124px; }
.fld ::v-deep .u-input__content { border-radius:124px; }
.cf { display: flex; align-items: center; }
.cf ::v-deep .u-input { flex: 1; margin-right: 10px; }
.er { color: #f56c6c; font-size: 13px; margin-bottom: 8px; }
.form-options { display: flex; align-items: center; justify-content: flex-end; margin: 2px 0 18px; }
.remember { display: flex; align-items: center; }
.forgot { font-size: 13px; color: #9aabb8; }
.agree-row { display: flex; align-items: flex-start; margin-top: 12px; }
.agree-box { width: 16px; height: 16px; border-radius: 4px; border: 1px solid #c8d0dc; background: #fff; display: flex; align-items: center; justify-content: center; flex-shrink: 0; margin-top: 1px; }
.agree-on { background: #4a6fa5; border-color: #4a6fa5; }
.agree-check { font-size: 12px; color: #fff; line-height: 1; }
.agree-txt { font-size: 12px; color: #9aabb8; margin-left: 4px; }
.agree-link { color: #4a6fa5; }

.wechat-panel { text-align: center; padding: 20px 0 10px; }
.wx-icon-big { display: flex; justify-content: center; cursor: pointer; }
.wx-circle { width: 56px; height: 56px; border-radius:50%; background: linear-gradient(145deg, #07c160, #06ad56); display: flex; align-items: center; justify-content: center; box-shadow: 0 6px 18px rgba(7, 193, 96, 0.3); transition: transform 0.25s; }
.wx-circle:active { transform: scale(0.95); }
.wx-hint { display: block; font-size: 12px; color: #b0bcc8; margin-top: 14px; }
.bind-title { display: block; text-align: center; font-size: 16px; font-weight: 600; color: #1a2a3a; margin-bottom: 16px; }

.divider { display: flex; align-items: center; gap: 14px; margin: 20px 0 14px; width: 100%; max-width: 420px; padding: 0 20px; box-sizing: border-box; position: relative; z-index: 2; }
.divider .line { flex: 1; height: 1px; background: rgba(0,0,0,0.08); }
.divider .text { font-size: 12px; color: #9aabb8; white-space: nowrap; }

.social-login { display: flex; justify-content: center; gap: 28px; width: 100%; max-width: 420px; position: relative; z-index: 2; }
.social-btn { display: flex; flex-direction: column; align-items: center; gap: 5px; padding: 4px 10px; }
.social-btn .icon-wrap { width: 46px; height: 46px; border-radius:50%; border: 1.5px solid rgba(0,0,0,0.08); background: #fff; display: flex; align-items: center; justify-content: center; transition: all 0.25s; }
.social-btn.active .icon-wrap { border-color: #4a6fa5; background: #f5f8fc; box-shadow: 0 0 0 3px rgba(74,111,165,0.06); }
.social-btn .label { font-size: 11px; color: #b0bcc8; white-space: normal; text-align: center; line-height: 1.3; }
.social-btn.active .label { color: #4a6fa5; font-weight: 500; }
.captcha-box { display: flex; align-items: center; gap: 6px; background: #f5f8fc; border-radius:24px; padding: 6px 10px; font-size: 14px; font-weight: 600; color: #4a6fa5; flex-shrink: 0; }
.captcha-refresh { font-size: 14px; }

.ft { text-align: center; margin-top: 22px; font-size: 11px; color: #9aabb8; position: relative; z-index: 2; padding: 0 20px; box-sizing: border-box; white-space: pre-line; }
</style>
