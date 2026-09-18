<template>
  <div class="mykeys-page">
    <!-- 绑定状态 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">登录安全密钥（FIDO2）</span><span class="sec-desc">绑定当前电脑，登录时用 Windows Hello（PIN/指纹/人脸）或安全密钥验证</span></div>
      <div class="status-row">
        <span>绑定状态：</span>
        <el-tag size="mini" :type="status.fido2_enabled ? 'success' : 'info'">{{ status.fido2_enabled ? '已绑定' : '未绑定' }}</el-tag>
        <el-tag v-if="status.fido2_require" size="mini" type="warning" style="margin-left:8px;">账号强制启用</el-tag>
        <span v-if="status.fido2_require_reason" class="reason">原因：{{ status.fido2_require_reason }}</span>
      </div>
      <div v-if="!browserSupported" class="browser-warn">当前浏览器不支持 WebAuthn，请使用 Chrome / Edge 浏览器进行绑定与验证。</div>
      <div v-if="bindMode" class="bind-mode-tip">当前为待绑定会话：请完成安全密钥绑定后，返回登录页重新登录（绑定成功后账号即可正常登录）。</div>

      <div class="actions">
        <el-button type="primary" size="small" :loading="binding" :disabled="!browserSupported" @click="handleBind">
          {{ status.fido2_enabled ? '重新绑定' : '绑定电脑' }}
        </el-button>
        <el-button v-if="hasToken && !bindMode" size="small" :loading="qrLoading" @click="handleQRCodeBind">扫码绑定</el-button>
        <el-button v-if="status.fido2_enabled && !bindMode" size="small" :loading="unbinding" @click="handleUnbind">解绑电脑</el-button>
      </div>
      <div class="bind-tip">绑定流程：点击"绑定电脑" → 浏览器弹出密钥选择 → 在电脑上完成 PIN/指纹/人脸验证（Windows Hello）→ 绑定完成。换电脑后需在新电脑重新绑定。</div>
    </el-card>

    <!-- 已绑定凭证 -->
    <el-card shadow="never" class="sec-card">
      <div slot="header" class="sec-head"><span class="sec-title">已绑定设备</span></div>
      <el-table :data="status.credentials || []" size="small" stripe>
        <el-table-column prop="device_name" label="设备名称" width="140" />
        <el-table-column label="设备类型" width="120" align="center">
          <template slot-scope="s">
            <el-tag size="mini" :type="deviceTypeTag(s.row.device_type)">{{ deviceTypeText(s.row.device_type) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="transports" label="传输方式" width="110" />
        <el-table-column prop="aaguid" label="认证器GUID" min-width="180" show-overflow-tooltip />
        <el-table-column prop="last_used_at" label="最后使用" width="170" />
        <el-table-column prop="created_at" label="绑定时间" width="170" />
      </el-table>
    </el-card>

    <!-- 解绑确认弹窗 -->
    <el-dialog title="解绑电脑" :visible.sync="unbindVisible" width="420px" top="15vh">
      <p>解绑后该账号将不再使用本电脑的 Windows Hello 安全密钥登录。若账号为强制启用状态，解绑后将无法登录，需联系管理员。</p>
      <el-input v-model="unbindPassword" type="password" show-password placeholder="请输入登录密码确认" style="margin-top:10px;" @keyup.enter.native="doUnbind" />
      <span slot="footer">
        <el-button size="small" @click="unbindVisible=false">取 消</el-button>
        <el-button size="small" type="danger" :loading="unbinding" @click="doUnbind">确认解绑</el-button>
      </span>
    </el-dialog>

    <!-- 扫码绑定弹窗 -->
    <el-dialog title="扫码绑定" :visible.sync="qrVisible" width="420px" top="10vh" :close-on-click-modal="false" @close="stopQRPolling">
      <div style="text-align:center;padding:10px 0;">
        <img v-if="qrDataUri" :src="qrDataUri" style="width:260px;height:260px;" alt="绑定二维码" />
        <p style="margin-top:14px;font-size:13px;color:#606266;">请使用手机扫描二维码，在手机上完成指纹/人脸/PIN 验证后，本账号即完成绑定。</p>
        <p style="margin-top:10px;font-size:13px;color:#909399;">当前状态：{{ qrState || '等待手机扫码…' }}</p>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getFido2UserStatus, unbindFido2, fido2RegisterStart, fido2RegisterComplete, fido2QRCodeRegisterCreate, fido2QRCodeStatus } from '@/api/webauthn'
import { createCredential, isWebAuthnSupported, webauthnErrorText } from '@/utils/webauthn'
import { getToken } from '@/utils/auth'

export default {
  name: 'MyKeys',
  data () {
    return {
      status: { fido2_enabled: false, fido2_require: false, fido2_require_reason: '', credentials: [] },
      browserSupported: isWebAuthnSupported(),
      binding: false, unbinding: false, unbindVisible: false, unbindPassword: '',
      bindStep: '', hasToken: false, bindMode: false,
      // 扫码绑定
      qrVisible: false, qrDataUri: '', qrToken: '', qrState: '', qrLoading: false, qrPolling: null,
    }
  },
  created () {
    this.bindStep = (this.$route.query && this.$route.query.step) || ''
    this.hasToken = !!getToken()
    // 待绑定会话模式：未登录但携带登录页下发的一次性 step（强制未绑定用户自助绑定）
    this.bindMode = !this.hasToken && !!this.bindStep
    if (this.hasToken) this.loadStatus()
  },
  beforeDestroy () { this.stopQRPolling() },
  methods: {
    deviceTypeText (t) {
      return { yubikey: 'YubiKey', harmony_passkey: '本机认证器', other: '其他' }[t] || '其他'
    },
    deviceTypeTag (t) {
      return { yubikey: 'primary', harmony_passkey: 'success', other: 'info' }[t] || 'info'
    },
    async loadStatus () {
      try {
        const r = await getFido2UserStatus()
        if (r.code === 0) this.status = Object.assign(this.status, r.data || {})
      } catch (e) {}
    },
    async handleBind () {
      this.binding = true
      try {
        const startRes = await fido2RegisterStart(this.bindStep ? { step: this.bindStep } : {})
        const credential = await createCredential(startRes.data)
        const completePayload = {
          client_data_json: credential.clientDataJSON,
          attestation_object: credential.attestationObject,
          device_name: '本电脑',
          transports: (credential.transports && credential.transports.length ? credential.transports : ['internal']).join(',')
        }
        if (this.bindStep) completePayload.step = this.bindStep
        const r = await fido2RegisterComplete(completePayload)
        if (this.bindMode) {
          this.$message.success('安全密钥绑定成功，请重新登录')
          setTimeout(() => { this.$router.push('/login') }, 800)
        } else {
          this.$message.success(r.msg || '安全密钥绑定成功')
          this.loadStatus()
        }
      } catch (e) {
        this.$message.error(webauthnErrorText(e))
      } finally {
        this.binding = false
      }
    },
    handleUnbind () {
      this.unbindPassword = ''
      this.unbindVisible = true
    },
    // ---- 扫码绑定 ----
    async handleQRCodeBind () {
      if (this.qrLoading) return
      this.qrLoading = true
      this.qrDataUri = ''
      this.qrToken = ''
      this.qrState = ''
      try {
        const r = await fido2QRCodeRegisterCreate({})
        if (r.code === 0) {
          this.qrDataUri = r.data.qr_data_uri || ''
          this.qrToken = r.data.auth_token || ''
          this.qrVisible = true
          this.startQRPolling()
        } else {
          this.$message.error(r.msg || '生成绑定二维码失败')
        }
      } catch (e) {
        this.$message.error('生成绑定二维码失败')
      } finally {
        this.qrLoading = false
      }
    },
    startQRPolling () {
      this.stopQRPolling()
      this.qrPolling = setInterval(async () => {
        if (!this.qrToken) return
        try {
          const r = await fido2QRCodeStatus({ token: this.qrToken })
          if (r.code !== 0) return
          const st = r.data.status
          if (st === 'completed') {
            this.stopQRPolling()
            this.qrState = '绑定成功'
            this.$message.success('手机密钥绑定成功')
            this.qrVisible = false
            this.loadStatus()
          } else if (st === 'expired') {
            this.stopQRPolling()
            this.qrState = '二维码已过期'
            this.$message.warning('二维码已过期，请重新生成')
          } else {
            this.qrState = '等待手机扫码…'
          }
        } catch (e) { /* 忽略轮询瞬时错误 */ }
      }, 2000)
    },
    stopQRPolling () {
      if (this.qrPolling) { clearInterval(this.qrPolling); this.qrPolling = null }
    },
    async doUnbind () {
      if (!this.unbindPassword) { this.$message.warning('请输入登录密码'); return }
      this.unbinding = true
      try {
        const r = await unbindFido2({ password: this.unbindPassword })
        this.$message.success(r.msg || '已解绑')
        this.unbindVisible = false
        this.loadStatus()
      } catch (e) {} finally { this.unbinding = false }
    }
  }
}
</script>

<style scoped>
.mykeys-page { padding: 16px; background: #f0f2f5; min-height: 100%; }
.sec-card { margin-bottom: 16px; }
.sec-head { display: flex; align-items: baseline; gap: 12px; }
.sec-title { font-size: 15px; font-weight: 600; color: #303133; }
.sec-desc { font-size: 12px; color: #909399; }
.status-row { font-size: 14px; color: #303133; margin-bottom: 14px; }
.reason { margin-left: 10px; font-size: 13px; color: #E6A23C; }
.browser-warn { font-size: 13px; color: #F56C6C; margin-bottom: 12px; }
.bind-mode-tip { font-size: 13px; color: #E6A23C; margin-bottom: 12px; }
.actions { margin-bottom: 10px; }
.bind-tip { font-size: 12px; color: #909399; }
</style>
