<template>
  <div class="login-config-page">
    <div class="page-header">
      <h2>登录配置</h2>
      <el-button v-if="hasPerm('loginconfig:save')" type="primary" :loading="saving" @click="handleSave">保存配置</el-button>
    </div>
    <div class="page-body">
      <!-- 小程序 -->
      <el-card shadow="never" class="config-card">
        <div slot="header"><span>小程序登录配置</span></div>
        <el-form label-width="180px" size="small">
          <el-form-item label="启用微信一键登录">
            <el-switch v-model="cfg.login_method_mini_enabled" :active-value="'1'" :inactive-value="'0'" @change="onSwitchChange('mini')" />
          </el-form-item>
          <el-form-item label="启用验证码登录">
            <el-switch v-model="cfg.login_method_mini_sms" :active-value="'1'" :inactive-value="'0'" @change="onSwitchChange('mini')" />
          </el-form-item>
          <el-form-item label="启用账号密码登录">
            <el-switch v-model="cfg.login_method_mini_password" :active-value="'1'" :inactive-value="'0'" @change="onSwitchChange('mini')" />
          </el-form-item>
          <el-form-item label="默认登录方式">
            <el-select v-model="cfg.login_method_mini_default" style="width:200px" :disabled="miniEnabledList.length===0">
              <el-option v-for="opt in miniEnabledList" :key="opt.value" :label="opt.label" :value="opt.value" />
              <el-option v-if="miniEnabledList.length===0" label="无可用的登录方式" value="" disabled />
            </el-select>
          </el-form-item>
          <div class="card-tip">微信 API 配置已在基础服务中完成，无需重复填写</div>
        </el-form>
      </el-card>
      <!-- 公众号 -->
      <el-card shadow="never" class="config-card">
        <div slot="header"><span>公众号登录配置</span></div>
        <el-form label-width="180px" size="small">
          <el-form-item label="启用微信网页授权登录">
            <el-switch v-model="cfg.login_method_mp_enabled" :active-value="'1'" :inactive-value="'0'" @change="onSwitchChange('mp')" />
          </el-form-item>
          <el-form-item label="启用验证码登录">
            <el-switch v-model="cfg.login_method_mp_sms" :active-value="'1'" :inactive-value="'0'" @change="onSwitchChange('mp')" />
          </el-form-item>
          <el-form-item label="启用账号密码登录">
            <el-switch v-model="cfg.login_method_mp_password" :active-value="'1'" :inactive-value="'0'" @change="onSwitchChange('mp')" />
          </el-form-item>
          <el-form-item label="默认登录方式">
            <el-select v-model="cfg.login_method_mp_default" style="width:200px" :disabled="mpEnabledList.length===0">
              <el-option v-for="opt in mpEnabledList" :key="opt.value" :label="opt.label" :value="opt.value" />
              <el-option v-if="mpEnabledList.length===0" label="无可用的登录方式" value="" disabled />
            </el-select>
          </el-form-item>
          <div class="card-tip">微信 API 配置已在基础服务中完成，无需重复填写</div>
        </el-form>
      </el-card>
      <!-- H5 -->
      <el-card shadow="never" class="config-card">
        <div slot="header"><span>H5 登录配置</span></div>
        <el-form label-width="180px" size="small">
          <el-form-item label="启用验证码登录">
            <el-switch v-model="cfg.login_method_h5_sms" :active-value="'1'" :inactive-value="'0'" @change="onSwitchChange('h5')" />
          </el-form-item>
          <el-form-item label="启用账号密码登录">
            <el-switch v-model="cfg.login_method_h5_password" :active-value="'1'" :inactive-value="'0'" @change="onSwitchChange('h5')" />
          </el-form-item>
          <el-form-item label="启用微信网页授权登录（公众号内有效）">
            <el-switch v-model="cfg.login_method_h5_wechat" :active-value="'1'" :inactive-value="'0'" @change="onSwitchChange('h5')" />
          </el-form-item>
          <el-form-item label="默认登录方式">
            <el-select v-model="cfg.login_method_h5_default" style="width:200px" :disabled="h5EnabledList.length===0">
              <el-option v-for="opt in h5EnabledList" :key="opt.value" :label="opt.label" :value="opt.value" />
              <el-option v-if="h5EnabledList.length===0" label="无可用的登录方式" value="" disabled />
            </el-select>
          </el-form-item>
          <div class="card-tip">微信登录入口仅在公众号内打开时显示</div>
        </el-form>
      </el-card>
      <!-- 企业微信 -->
      <el-card shadow="never" class="config-card">
        <div slot="header"><span>企业微信登录配置</span></div>
        <el-form label-width="180px" size="small">
          <el-form-item label="启用企业微信一键登录">
            <el-switch v-model="cfg.login_method_wxwork_enabled" :active-value="'1'" :inactive-value="'0'" @change="onSwitchChange('wxwork')" />
          </el-form-item>
          <el-form-item label="启用企业微信扫码登录">
            <el-switch v-model="cfg.login_method_wxwork_qrcode" :active-value="'1'" :inactive-value="'0'" @change="onSwitchChange('wxwork')" />
          </el-form-item>
          <el-form-item label="默认登录方式">
            <el-select v-model="cfg.login_method_wxwork_default" style="width:200px" :disabled="wxworkEnabledList.length===0">
              <el-option v-for="opt in wxworkEnabledList" :key="opt.value" :label="opt.label" :value="opt.value" />
              <el-option v-if="wxworkEnabledList.length===0" label="无可用的登录方式" value="" disabled />
            </el-select>
          </el-form-item>
          <div class="card-tip">企业微信 API 配置已在基础服务中完成，无需重复填写</div>
        </el-form>
      </el-card>
    </div>
  </div>
</template>

<script>
import { getLoginMethods, saveLoginMethods } from '@/api/app'

const METHOD_LABELS = {
  wechat: '微信网页授权登录', sms: '验证码登录', password: '账号密码登录',
  wxwork: '企业微信一键登录', wxwork_qrcode: '企业微信扫码登录',
}

export default {
  name: 'LoginConfig',
  data() {
    return {
      saving: false,
      cfg: {
        login_method_mini_enabled: '1', login_method_mini_sms: '1', login_method_mini_password: '1', login_method_mini_default: 'wechat',
        login_method_mp_enabled: '1', login_method_mp_sms: '1', login_method_mp_password: '0', login_method_mp_default: 'wechat',
        login_method_h5_sms: '1', login_method_h5_password: '0', login_method_h5_wechat: '1', login_method_h5_default: 'sms',
        login_method_wxwork_enabled: '1', login_method_wxwork_qrcode: '1', login_method_wxwork_default: 'wxwork',
      }
    }
  },
  computed: {
    miniEnabledList() {
      const list = []
      if (this.cfg.login_method_mini_enabled === '1') list.push({ value: 'wechat', label: METHOD_LABELS.wechat })
      if (this.cfg.login_method_mini_sms === '1') list.push({ value: 'sms', label: METHOD_LABELS.sms })
      if (this.cfg.login_method_mini_password === '1') list.push({ value: 'password', label: METHOD_LABELS.password })
      return list
    },
    mpEnabledList() {
      const list = []
      if (this.cfg.login_method_mp_enabled === '1') list.push({ value: 'wechat', label: METHOD_LABELS.wechat })
      if (this.cfg.login_method_mp_sms === '1') list.push({ value: 'sms', label: METHOD_LABELS.sms })
      if (this.cfg.login_method_mp_password === '1') list.push({ value: 'password', label: METHOD_LABELS.password })
      return list
    },
    h5EnabledList() {
      const list = []
      if (this.cfg.login_method_h5_sms === '1') list.push({ value: 'sms', label: METHOD_LABELS.sms })
      if (this.cfg.login_method_h5_password === '1') list.push({ value: 'password', label: METHOD_LABELS.password })
      if (this.cfg.login_method_h5_wechat === '1') list.push({ value: 'wechat', label: METHOD_LABELS.wechat })
      return list
    },
    wxworkEnabledList() {
      const list = []
      if (this.cfg.login_method_wxwork_enabled === '1') list.push({ value: 'wxwork', label: METHOD_LABELS.wxwork })
      if (this.cfg.login_method_wxwork_qrcode === '1') list.push({ value: 'wxwork_qrcode', label: METHOD_LABELS.wxwork_qrcode })
      return list
    },
  },
  created() { this.load() },
  methods: {
    // 权限判断：按钮权限控制
    hasPerm(code) { const p = this.$store.state.user && this.$store.state.user.permissions ? this.$store.state.user.permissions : []; return p.indexOf(code) > -1 },
    async load() {
      try { const r = await getLoginMethods(); if (r.code === 0 && r.data) Object.assign(this.cfg, r.data); this.fixAll() } catch (e) {}
    },
    fixAll() {
      this.fixDefault('mini', this.miniEnabledList)
      this.fixDefault('mp', this.mpEnabledList)
      this.fixDefault('h5', this.h5EnabledList)
      this.fixDefault('wxwork', this.wxworkEnabledList)
    },
    fixDefault(platform, list) {
      const key = `login_method_${platform}_default`
      if (list.length === 0) { this.cfg[key] = ''; return }
      if (!list.some(o => o.value === this.cfg[key])) this.cfg[key] = list[0].value
    },
    onSwitchChange(platform) {
      this.$nextTick(() => this.fixAll())
    },
    async handleSave() {
      this.saving = true
      try { const r = await saveLoginMethods(this.cfg); if (r.code === 0) this.$message.success('配置已保存'); else this.$message.error(r.msg) } catch (e) { this.$message.error('保存失败') }
      this.saving = false
    },
  }
}
</script>

<style scoped>
.login-config-page { padding: 0; background: #f0f2f5; min-height: 100vh; }
.page-header { height: 56px; background: #fff; border-bottom: 1px solid #EBEEF5; padding: 0 24px; display: flex; align-items: center; justify-content: space-between; }
.page-header h2 { font-size: 20px; font-weight: bold; color: #303133; margin: 0; }
.page-body { padding: 24px; max-width: 800px; }
.config-card { margin-bottom: 16px; }
.config-card .card-tip { font-size: 12px; color: #909399; padding: 8px 0 0 180px; }
</style>
