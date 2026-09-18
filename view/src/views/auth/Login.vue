<template>
  <div v-show="configLoaded" class="login-container" :style="containerBg">
    <transition name="fade-in">
      <div v-show="configLoaded">
    <!-- 背景遮罩 -->
    <div v-if="cfg.bg_overlay_enabled" class="login-overlay" :style="overlayStyle"></div>
    <!-- 粒子Canvas（含鼠标跟随） -->
    <canvas v-if="cfg.bg_mode==='particle'" ref="loginParticle" class="login-particle" />
    <!-- 浮动气泡 -->
    <div class="bubbles">
      <span v-for="n in 8" :key="n" class="bubble" :style="bubbleStyle(n)" />
    </div>

    <!-- 登录卡片 -->
    <transition name="fade-up">
      <div class="login-card-wrapper" :style="cardPosStyle">
        <div class="login-card" :style="cardStyle">
          <div class="login-logo-area">
            <img v-if="cfg.logo_url" :src="cfg.logo_url" :style="{width:cfg.logo_width+'px',borderRadius:cfg.logo_mode==='circle'?'50%':'0'}" />
            <h2 v-else class="login-title" :style="{color:cfg.primary_color}">{{ cfg.system_name || cfg.title || '企业管理系统' }}</h2>
          </div>
          <p v-if="cfg.slogan" class="login-slogan">{{ cfg.slogan }}</p>

          <el-tabs v-model="activeTab" stretch>
            <!-- 密码登录 -->
            <el-tab-pane label="密码登录" name="pwd">
              <el-form ref="pwdForm" :model="pwdData" :rules="pwdRules" label-width="0" size="large" @keyup.enter.native="handlePwdLogin">
                  <el-form-item prop="username">
                  <el-input v-model="pwdData.username" prefix-icon="el-icon-user" placeholder="用户名" />
                </el-form-item>
                <el-form-item prop="password">
                  <el-input v-model="pwdData.password" prefix-icon="el-icon-lock" type="password" placeholder="密码" show-password @keyup.enter.native="handlePwdLogin" />
                </el-form-item>
                <!-- 登录验证码（安全策略 → 登录安全） -->
                <el-form-item prop="captcha">
                  <el-row :gutter="8">
                    <el-col :span="14"><el-input v-model="captcha.input" prefix-icon="el-icon-key" placeholder="验证码" maxlength="4" @keyup.enter.native="handlePwdLogin" /></el-col>
                    <el-col :span="10">
                      <div class="captcha-box" @click="loadCaptcha" title="点击刷新验证码">
                        <span>{{ captcha.expression || '加载中…' }}</span>
                        <i class="el-icon-refresh"></i>
                      </div>
                    </el-col>
                  </el-row>
                </el-form-item>
                <el-form-item v-if="cfg.remember_enabled">
                  <el-checkbox v-model="pwdData.remember">记住密码</el-checkbox>
                </el-form-item>
                <el-form-item>
                  <el-button type="primary" :loading="loading" style="width:100%;border:none;" :style="{background:cfg.primary_color}" @click="handlePwdLogin">{{ cfg.btn_text }}</el-button>
                </el-form-item>
                <div class="form-footer-left">
                  <el-button type="text" :style="{color:cfg.primary_color}" @click="openForgotDialog">忘记密码？</el-button>
                </div>
              </el-form>
            </el-tab-pane>

            <!-- 短信登录 -->
            <el-tab-pane v-if="cfg.sms_enabled" label="短信登录" name="sms">
              <el-form ref="smsForm" :model="smsData" :rules="smsRules" label-width="0" size="large" @keyup.enter.native="handleSmsLogin">
                  <el-form-item prop="phone">
                  <el-input v-model="smsData.phone" prefix-icon="el-icon-phone-outline" placeholder="手机号" maxlength="11" />
                </el-form-item>
                <el-form-item prop="code">
                  <el-row :gutter="8">
                    <el-col :span="14"><el-input v-model="smsData.code" prefix-icon="el-icon-key" placeholder="验证码" maxlength="6" /></el-col>
                    <el-col :span="10"><el-button :disabled="smsCountdown>0" style="width:100%;" @click="handleSendSms('login')">{{ smsCountdown>0?`${smsCountdown}s`:'获取验证码' }}</el-button></el-col>
                  </el-row>
                </el-form-item>
                <el-form-item>
                  <el-button type="primary" :loading="loading" style="width:100%;border:none;" :style="{background:cfg.primary_color}" @click="handleSmsLogin">{{ cfg.btn_text }}</el-button>
                </el-form-item>
              </el-form>
            </el-tab-pane>

            <!-- 注册入口（已停用） -->
            <el-tab-pane v-if="false" label="注册" name="reg">
              <el-form ref="regForm" :model="regData" :rules="regRules" label-width="0" size="large">
                  <el-form-item prop="username">
                  <el-input v-model="regData.username" prefix-icon="el-icon-user" placeholder="用户名" @keyup.enter="handleRegister" />
                </el-form-item>
                <el-form-item prop="password">
                  <el-input v-model="regData.password" prefix-icon="el-icon-lock" type="password" placeholder="密码" show-password @keyup.enter="handleRegister" />
                </el-form-item>
                <el-form-item prop="confirm">
                  <el-input v-model="regData.confirm" prefix-icon="el-icon-lock" type="password" placeholder="确认密码" show-password @keyup.enter="handleRegister" />
                </el-form-item>
                <el-form-item prop="phone">
                  <el-input v-model="regData.phone" prefix-icon="el-icon-phone-outline" placeholder="手机号" maxlength="11" @keyup.enter="handleRegister" />
                </el-form-item>
                <el-form-item>
                  <el-button type="primary" :loading="regLoading" style="width:100%;border:none;" :style="{background:cfg.primary_color}" @click="handleRegister">注册</el-button>
                </el-form-item>
              </el-form>
            </el-tab-pane>
          </el-tabs>

          <div class="login-footer" v-if="cfg.copyright">{{ cfg.copyright }}</div>
        </div>
      </div>
    </transition>

    <!-- 忘记密码弹窗 -->
    <el-dialog title="重置密码" :visible.sync="forgotDialogVisible" width="420px" top="8vh" :close-on-click-modal="false" @closed="onForgotDialogClosed">
      <el-form ref="forgotForm" :model="forgotData" :rules="forgotRules" label-width="80px" size="medium">
        <el-form-item label="手机号" prop="phone">
          <el-row :gutter="10">
            <el-col :span="14"><el-input v-model="forgotData.phone" placeholder="请输入手机号" maxlength="11" /></el-col>
            <el-col :span="10"><el-button :disabled="resetCountdown>0" style="width:100%;" @click="handleSendSms('reset')">{{ resetCountdown>0?`${resetCountdown}s`:'获取验证码' }}</el-button></el-col>
          </el-row>
        </el-form-item>
        <el-form-item label="验证码" prop="code"><el-input v-model="forgotData.code" placeholder="6位验证码" maxlength="6" @keyup.enter="handleForgotPassword" /></el-form-item>
        <el-form-item label="新密码" prop="password"><el-input v-model="forgotData.password" type="password" placeholder="6-20位" show-password @keyup.enter="handleForgotPassword" /></el-form-item>
        <el-form-item label="确认密码" prop="confirmPassword"><el-input v-model="forgotData.confirmPassword" type="password" placeholder="再次输入新密码" show-password @keyup.enter="handleForgotPassword" /></el-form-item>
      </el-form>
      <span slot="footer"><el-button @click="forgotDialogVisible=false">取 消</el-button><el-button type="primary" :loading="resetLoading" @click="handleResetPwd" :style="{background:cfg.primary_color,borderColor:cfg.primary_color}">确认重置</el-button></span>
    </el-dialog>

    <!-- FIDO2 硬件密钥验证弹窗 -->
    <el-dialog title="硬件密钥验证" :visible.sync="fido2DialogVisible" width="420px" top="10vh" :close-on-click-modal="false" :close-on-press-escape="false" :show-close="false">
      <div class="fido2-dialog">
        <i class="el-icon-key fido2-icon"></i>
        <p class="fido2-msg">请将鸿蒙手机通过 USB 连接到电脑，并在手机上完成指纹/人脸验证。</p>
        <p class="fido2-verifying" v-if="fido2Verifying">正在等待手机验证…</p>
        <p class="fido2-err" v-if="fido2Error">{{ fido2Error }}</p>
      </div>
      <span slot="footer">
        <el-button size="small" @click="cancelFido2">取消</el-button>
        <el-button size="small" type="primary" :loading="fido2Verifying" @click="runFido2Verify">重新验证</el-button>
      </span>
    </el-dialog>

    <!-- 选择认证方式 -->
    <el-dialog title="硬件密钥验证" :visible.sync="methodDialogVisible" width="420px" top="12vh" :close-on-click-modal="false">
      <div class="fido2-dialog">
        <p class="fido2-msg">请选择认证方式：</p>
        <el-button type="primary" size="large" style="width:100%;margin-bottom:10px;" @click="useYubiKey">
          <i class="el-icon-usb" /> YubiKey USB（插入密钥并触摸）
        </el-button>
      </div>
      <span slot="footer"><el-button size="small" @click="methodDialogVisible=false">取消</el-button></span>
    </el-dialog>

    <!-- 一个手机号绑定多个账号：选择登录账号 -->
    <el-dialog title="请选择登录账号" :visible.sync="smsChooseVisible" width="400px" top="20vh" :close-on-click-modal="false" append-to-body>
      <p style="font-size:13px;color:#909399;margin-bottom:12px;">该手机号绑定了多个账号，请选择要登录的账号：</p>
      <div style="display:flex;flex-direction:column;gap:10px;">
        <el-button v-for="u in smsCandidates" :key="u.id" size="medium" @click="chooseSmsUser(u)">
          {{ u.real_name || u.username }}<span v-if="u.real_name && u.real_name !== u.username" style="margin-left:8px;font-size:12px;color:#909399;">（{{ u.username }}）</span>
        </el-button>
      </div>
      <span slot="footer"><el-button size="small" @click="smsChooseVisible=false">取消</el-button></span>
    </el-dialog>

    </div></transition>
  </div>
</template>

<script>
import { login, register, sendSms, smsLogin, resetPassword, getCaptcha } from '@/api/auth'
import { getLoginSettings } from '@/api/settings'
import { setToken } from '@/utils/auth'
import { fido2LoginStart, fido2LoginComplete } from '@/api/webauthn'
import { getAssertion, isWebAuthnSupported, webauthnErrorText } from '@/utils/webauthn'

export default {
  name: 'Login',
  data() {
    const validatePhone = (rule, value, callback) => { if (!/^1[3-9]\d{9}$/.test(value)) callback(new Error('请输入正确的手机号')); else callback() }
    const validateCode = (rule, value, callback) => { if (!/^\d{6}$/.test(value)) callback(new Error('验证码为6位数字')); else callback() }
    const validatePwdLen = (rule, value, callback) => { if (value.length<6||value.length>20) callback(new Error('密码长度需6-20位')); else callback() }
    const validateConfirm = (rule, value, callback) => { if (value!==this.forgotData.password) callback(new Error('两次输入的密码不一致')); else callback() }
    return {
      cfg: { title:'数智管控平台 管理后台', slogan:'', copyright:'', btn_text:'登录', primary_color:'#409EFF', bg_mode:'gradient_animated', bg_solid_color:'#1a2a6c', bg_gradient_direction:'to bottom', bg_gradient_start:'#667eea', bg_gradient_end:'#764ba2', bg_animated_direction:'to left', bg_animated_start:'#1a2a6c', bg_animated_end:'#b21f1f', bg_animated_speed:3, bg_image_url:'', bg_image_fit:'cover', bg_particle_color:'#409EFF', bg_particle_count:150, bg_particle_distance:100, bg_particle_speed:2, bg_wave_colors:['#409EFF','#67C23A'], bg_wave_count:3, bg_wave_height:30, bg_wave_speed:3, bg_overlay_enabled:true, bg_overlay_color:'#000000', bg_overlay_opacity:40, logo_url:'', logo_width:120, logo_mode:'normal', card_position:'center', card_blur:10, card_radius:16, card_shadow:'medium', register_enabled:false, sms_enabled:true, remember_enabled:true },
      activeTab: 'pwd', loading: false, regLoading: false,
      smsCountdown: 0, smsTimer: null, resetCountdown: 0, resetTimer: null,
      pwdData: { username:'', password:'', remember:false },
      captcha: { id: '', expression: '', input: '' },
      pwdRules: { username:[{required:true,message:'请输入用户名',trigger:'blur'}], password:[{required:true,message:'请输入密码',trigger:'blur'}] },
      smsData: { phone:'', code:'' },
      smsCandidates: [], smsSelectToken: '', smsChooseVisible: false,
      smsRules: { phone:[{required:true,message:'请输入手机号',trigger:'blur'},{validator:validatePhone,trigger:'blur'}], code:[{required:true,message:'请输入验证码',trigger:'blur'},{validator:validateCode,trigger:'blur'}] },
      regData: { username:'', password:'', confirm:'', phone:'' },
      regRules: { username:[{required:true,message:'请输入用户名',trigger:'blur'}], password:[{required:true,message:'请输入密码',trigger:'blur'},{validator:validatePwdLen,trigger:'blur'}], confirm:[{required:true,message:'请确认密码',trigger:'blur'},{validator:validateConfirm,trigger:'blur'}], phone:[{required:true,message:'请输入手机号',trigger:'blur'},{validator:validatePhone,trigger:'blur'}] },
      forgotDialogVisible: false, resetLoading: false,
      forgotData: { phone:'', code:'', password:'', confirmPassword:'' },
      forgotRules: { phone:[{required:true,message:'请输入手机号',trigger:'blur'},{validator:validatePhone,trigger:'blur'}], code:[{required:true,message:'请输入验证码',trigger:'blur'},{validator:validateCode,trigger:'blur'}], password:[{required:true,message:'请输入新密码',trigger:'blur'},{validator:validatePwdLen,trigger:'blur'}], confirmPassword:[{required:true,message:'请确认新密码',trigger:'blur'},{validator:validateConfirm,trigger:'blur'}] },
      configLoaded: false,
      fido2DialogVisible: false, fido2Verifying: false, fido2Error: '', pwdUsername: '',
      methodDialogVisible: false,
    }
  },
  computed: {
    containerBg() {
      const c = this.cfg
      if (c.bg_mode === 'solid') return { background: c.bg_solid_color }
      if (c.bg_mode === 'gradient_static') {
        const d = c.bg_gradient_direction
        if (d === 'radial') return { background: `radial-gradient(circle, ${c.bg_gradient_start}, ${c.bg_gradient_end})` }
        return { background: `linear-gradient(${d}, ${c.bg_gradient_start}, ${c.bg_gradient_end})` }
      }
      if (c.bg_mode === 'gradient_animated') return { background: `linear-gradient(${c.bg_animated_direction}, ${c.bg_animated_start}, ${c.bg_animated_end})`, backgroundSize: '200% 200%', animation: `bgShift ${c.bg_animated_speed}s ease infinite` }
      if (c.bg_mode === 'image') return { backgroundImage: `url(${c.bg_image_url})`, backgroundSize: c.bg_image_fit, backgroundPosition: 'center', backgroundRepeat: 'no-repeat' }
      return { background: '#0a1929' }
    },
    overlayStyle() { return { background: this.cfg.bg_overlay_color, opacity: this.cfg.bg_overlay_opacity / 100 } },
    cardPosStyle() { return { justifyContent: { center:'center', left:'flex-start', right:'flex-end' }[this.cfg.card_position] || 'center' } },
    cardStyle() {
      const shadows = { none:'none', light:'0 2px 12px rgba(0,0,0,0.1)', medium:'0 8px 32px rgba(0,0,0,0.18)', heavy:'0 16px 48px rgba(0,0,0,0.3)' }
      return { borderRadius: this.cfg.card_radius + 'px', boxShadow: shadows[this.cfg.card_shadow] || shadows.medium, backdropFilter: `blur(${this.cfg.card_blur}px)`, WebkitBackdropFilter: `blur(${this.cfg.card_blur}px)` }
    },
    bubbleStyle() {
      return (n) => {
        const idx = (n - 1) % 8
        const sizes = [60,90,50,120,70,100,40,80], lefts = [5,20,40,60,75,85,50,10], delays = [0,1.5,3,0.8,2.2,4,1,3.5], durs = [8,11,9,13,10,12,7,10]
        return { width:sizes[idx]+'px', height:sizes[idx]+'px', left:lefts[idx]+'%', animationDelay:delays[idx]+'s', animationDuration:durs[idx]+'s' }
      }
    },
  },
  created() { this.loadConfig(); this.loadCaptcha() },
  mounted() {},
beforeDestroy() { this.clearTimers(); if (this.stopQRTimer) this.stopQRTimer(); if (this._particleCleanup) this._particleCleanup() },
watch: {
  'cfg.bg_mode'(v) { if (v === 'particle') this.$nextTick(() => this.initParticle()) },
},
  methods: {
    async loadConfig() {
      try { const r = await getLoginSettings(); if (r.data) { Object.assign(this.cfg, r.data); this.$nextTick(() => { if (this.cfg.bg_mode === 'particle') this.initParticle() }) } } catch (e) { this.$message.warning('配置加载失败，使用默认配置') } finally { this.configLoaded = true }
    },
    clearTimers() { clearInterval(this.smsTimer); clearInterval(this.resetTimer); this.smsTimer = null; this.resetTimer = null },
    async loadCaptcha() {
      try {
        const r = await getCaptcha()
        if (r.code === 0 && r.data) {
          this.captcha.id = r.data.captcha_id
          this.captcha.expression = r.data.expression
          this.captcha.input = ''
        }
      } catch (e) {}
    },
    async handlePwdLogin() { const valid = await this.$refs.pwdForm.validate().catch(()=>false); if (!valid) return; this.loading=true; try { const r=await login({ ...this.pwdData, captcha_id: this.captcha.id, captcha_code: this.captcha.input }); this.handleLoginResult(r) } catch(e){} this.loading=false; this.loadCaptcha() },
    handleLoginResult(r) {
      const d = r.data || {}
      if (d.require_fido2) {
        this.pwdUsername = this.pwdData.username
        this.fido2Error = ''
        // 显示"选择认证方式"：YubiKey USB
        this.methodDialogVisible = true
        return
      }
      if (d.require_bind) {
        this.$msgbox.alert(d.message || '该账号需绑定手机密钥才能登录', '需要绑定手机密钥', {
          confirmButtonText: '去绑定',
          callback: () => {
            this.$router.push({ path: '/settings/security/my-keys', query: d.step ? { step: d.step } : {} })
          }
        })
        return
      }
      this.loginSuccess(r)
    },
    async runFido2Verify () {
      this.fido2Verifying = true; this.fido2Error = ''
      try {
        const startRes = await fido2LoginStart({ username: this.pwdUsername })
        const assertion = await getAssertion(startRes.data)
        const verifyRes = await fido2LoginComplete({
          username: this.pwdUsername,
          credential_id: assertion.rawId,
          client_data_json: assertion.clientDataJSON,
          authenticator_data: assertion.authenticatorData,
          signature: assertion.signature
        })
        this.fido2DialogVisible = false
        this.loginSuccess(verifyRes)
      } catch (e) {
        this.fido2Error = webauthnErrorText(e)
      } finally {
        this.fido2Verifying = false
      }
    },
    cancelFido2 () { this.fido2DialogVisible = false; this.fido2Verifying = false; this.fido2Error = '' },
    // ---- 认证方式选择 ----
    useYubiKey () {
      this.methodDialogVisible = false
      if (!isWebAuthnSupported()) { this.$message.error('当前浏览器不支持 WebAuthn，请使用 Chrome/Edge 浏览器'); return }
      this.fido2DialogVisible = true
      this.fido2Error = ''
      this.runFido2Verify()
    },
    async handleSendSms(type) {
      let phone
      if (type==='login') { try { await this.$refs.smsForm.validateField('phone') } catch(e){ this.$message.warning('请先输入正确的手机号'); return }; phone=this.smsData.phone }
      else { if (!/^1[3-9]\d{9}$/.test(this.forgotData.phone)) { this.$message.warning('请先输入正确的手机号'); return }; phone=this.forgotData.phone }
      try { await sendSms({phone,type}); this.$message.success('验证码已发送'); this.startCountdown(type) } catch(e){}
    },
    startCountdown(type) {
      const dur=60; const key=type==='login'?'smsCountdown':'resetCountdown'; const timerKey=type==='login'?'smsTimer':'resetTimer'
      this[key]=dur; clearInterval(this[timerKey]); this[timerKey]=setInterval(()=>{ this[key]--; if(this[key]<=0){ clearInterval(this[timerKey]); this[timerKey]=null } },1000)
    },
    async handleSmsLogin() {
      const valid = await this.$refs.smsForm.validate().catch(() => false); if (!valid) return
      this.loading = true
      try {
        const r = await smsLogin(this.smsData)
        // 一个手机号绑定多个账号：返回候选，弹出选择
        if (r.data && r.data.multi && Array.isArray(r.data.candidates) && r.data.candidates.length) {
          this.smsCandidates = r.data.candidates
          this.smsSelectToken = r.data.select_token || ''
          this.smsChooseVisible = true
          this.loading = false
          return
        }
        this.loginSuccess(r, false)
      } catch (e) {}
      this.loading = false
    },
    async chooseSmsUser(u) {
      if (!u || !u.id) return
      this.loading = true
      try {
        const r = await smsLogin({ ...this.smsData, user_id: u.id, select_token: this.smsSelectToken })
        this.smsChooseVisible = false
        this.loginSuccess(r, false)
      } catch (e) {}
      this.loading = false
    },
    async handleRegister() {
      const valid=await this.$refs.regForm.validate().catch(()=>false); if(!valid)return
      if (this.regData.password!==this.regData.confirm) { this.$message.warning('两次密码不一致'); return }
      this.regLoading=true
      try{const r=await register({username:this.regData.username,password:this.regData.password,phone:this.regData.phone});this.$message.success('注册成功');this.activeTab='pwd'}catch(e){}
      this.regLoading=false
    },
    openForgotDialog() { this.forgotDialogVisible=true },
    onForgotDialogClosed() { clearInterval(this.resetTimer);this.resetTimer=null;this.resetCountdown=0; if(this.$refs.forgotForm) this.$refs.forgotForm.resetFields() },
    async handleResetPwd() { const valid=await this.$refs.forgotForm.validate().catch(()=>false); if(!valid)return; this.resetLoading=true; try{await resetPassword(this.forgotData);this.$message.success('密码重置成功，请重新登录');this.forgotDialogVisible=false;this.pwdData.password=''}catch(e){}this.resetLoading=false },
    loginSuccess(res, rememberOverride) {
      const remember = rememberOverride !== undefined ? rememberOverride : !!(this.pwdData && this.pwdData.remember)
      setToken(res.data.token, remember)
      this.$store.commit('user/SET_TOKEN', res.data.token)
      if (res.data.user) this.$store.commit('user/SET_USER', res.data.user)
      this.$store.dispatch('user/loadPermissions')
      this.$message.success('登录成功')
      // 安全策略：强制修改密码（首次登录 / 密码过期）
      if (res.data.must_change_password) {
        this.$alert(res.data.must_change_password_msg || '请修改初始密码', '需要修改密码', {
          confirmButtonText: '去修改',
          callback: () => this.$router.push('/profile')
        })
        return
      }
      this.$router.push('/dashboard')
    },
    // 粒子系统（带鼠标跟随 - 监听window级别鼠标事件）
    initParticle() {
      const canvas = this.$refs.loginParticle; if (!canvas) return
      const ctx = canvas.getContext('2d'); const c = this.cfg
      canvas.width = window.innerWidth; canvas.height = window.innerHeight

      let mouseX = null, mouseY = null
      const onMove = (e) => { mouseX = e.clientX; mouseY = e.clientY }
      const onLeave = () => { mouseX = null; mouseY = null }
      window.addEventListener('mousemove', onMove)
      document.addEventListener('mouseleave', onLeave)

      const baseSpeed = 2 / c.bg_particle_speed
      const particles = Array.from({length:c.bg_particle_count}, () => ({
        x: Math.random() * canvas.width, y: Math.random() * canvas.height,
        vx: (Math.random() - 0.5) * baseSpeed,
        vy: (Math.random() - 0.5) * baseSpeed,
        size: 2,
      }))

      const resize = () => { canvas.width = window.innerWidth; canvas.height = window.innerHeight }
      window.addEventListener('resize', resize)

      let running = true
      const animate = () => {
        if (!running) return
        ctx.clearRect(0, 0, canvas.width, canvas.height)
        for (const p of particles) {
          // 鼠标吸引
          if (mouseX !== null && mouseY !== null) {
            const dx = mouseX - p.x, dy = mouseY - p.y
            const dist = dx * dx + dy * dy
            if (dist < c.bg_particle_distance * c.bg_particle_distance && dist > 0) {
              const pull = (1 - Math.sqrt(dist) / c.bg_particle_distance) * 0.5
              p.vx += (dx / Math.sqrt(dist)) * pull
              p.vy += (dy / Math.sqrt(dist)) * pull
            }
          }
          const sp = Math.sqrt(p.vx * p.vx + p.vy * p.vy)
          if (sp > baseSpeed * 2) { p.vx = (p.vx / sp) * baseSpeed * 2; p.vy = (p.vy / sp) * baseSpeed * 2 }
          p.x += p.vx; p.y += p.vy
          if (p.x < 0 || p.x > canvas.width) { p.vx *= -0.9; p.x = Math.max(0, Math.min(canvas.width, p.x)) }
          if (p.y < 0 || p.y > canvas.height) { p.vy *= -0.9; p.y = Math.max(0, Math.min(canvas.height, p.y)) }
          ctx.beginPath(); ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2)
          ctx.fillStyle = c.bg_particle_color; ctx.fill()
        }
        for (let i = 0; i < particles.length; i++) {
          for (let j = i + 1; j < particles.length; j++) {
            const dx = particles[i].x - particles[j].x, dy = particles[i].y - particles[j].y
            const d = dx * dx + dy * dy
            if (d < c.bg_particle_distance * c.bg_particle_distance) {
              ctx.beginPath(); ctx.moveTo(particles[i].x, particles[i].y)
              ctx.lineTo(particles[j].x, particles[j].y)
              ctx.strokeStyle = c.bg_particle_color
              ctx.globalAlpha = 1 - Math.sqrt(d) / c.bg_particle_distance
              ctx.stroke(); ctx.globalAlpha = 1
            }
          }
        }
        this._particleFrame = requestAnimationFrame(animate)
      }
      this._particleCleanup = () => { running = false; cancelAnimationFrame(this._particleFrame); window.removeEventListener('resize', resize); window.removeEventListener('mousemove', onMove); document.removeEventListener('mouseleave', onLeave) }
      animate()
    },
  },
}
</script>

<style scoped>
.login-container { position:relative; display:flex; justify-content:center; align-items:center; height:100vh; overflow:hidden; }
.login-overlay { position:absolute; inset:0; z-index:1; pointer-events:none; }
.login-particle { position:absolute; inset:0; width:100%; height:100%; z-index:1; }
.bubbles { position:absolute; inset:0; pointer-events:none; z-index:2; }
.bubble { position:absolute; bottom:-120px; border-radius:50%; background:rgba(255,255,255,0.12); animation:floatUp linear infinite; }
@keyframes floatUp { 0%{transform:translateY(0) scale(1);opacity:0.6} 50%{opacity:0.3} 100%{transform:translateY(-110vh) scale(0.6);opacity:0} }
@keyframes bgShift { 0%{background-position:0% 50%} 50%{background-position:100% 50%} 100%{background-position:0% 50%} }
.login-card-wrapper { position:relative; z-index:3; display:flex; align-items:center; width:100%; height:100%; padding:0 40px; }
.login-card { width:420px; padding:40px; background:rgba(255,255,255,0.7); border:1px solid rgba(255,255,255,0.3); }
.login-logo-area { text-align:center; margin-bottom:8px; }
.login-title { margin:0 0 30px; color:#333; font-size:24px; font-weight:600; text-align:center; }
.login-slogan { font-size:13px; color:#999; text-align:center; margin:4px 0 16px; }
.login-footer { margin-top:16px; font-size:11px; color:#aaa; text-align:center; }
.fade-up-enter-active { animation:fadeInUp 0.6s ease; }
.fade-in-enter-active { transition: opacity 0.3s ease; }
.fade-in-enter, .fade-in-leave-to { opacity: 0; }
@keyframes fadeInUp { from{opacity:0;transform:translateY(30px)} to{opacity:1;transform:translateY(0)} }
.form-footer-left { text-align:left; margin-top:-10px; }
/* 登录验证码 */
.captcha-box {
  display: flex; align-items: center; justify-content: space-between; gap: 4px;
  height: 40px; padding: 0 12px;
  border: 1px solid #dcdfe6; border-radius: 4px;
  background: #f7f8fa; color: #303133; font-size: 15px; font-weight: 600;
  cursor: pointer; user-select: none; letter-spacing: 1px;
}
.captcha-box i { color: #909399; font-size: 14px; }
.captcha-box:hover { border-color: #409eff; }
.fido2-dialog { text-align:center; padding:10px 0; }
.fido2-icon { font-size:48px; color:#409EFF; margin-bottom:12px; }
.fido2-msg { font-size:14px; color:#303133; line-height:1.7; }
.fido2-verifying { font-size:13px; color:#409EFF; margin-top:10px; }
.fido2-err { font-size:13px; color:#F56C6C; margin-top:10px; }
.login-card ::v-deep .el-tabs__item { font-size:15px; }
</style>
