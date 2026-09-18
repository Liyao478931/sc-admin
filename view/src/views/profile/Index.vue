<template>
  <div class="profile-wrapper">
    <el-row :gutter="20">
      <!-- 左侧导航 -->
      <el-col :span="5">
        <el-card shadow="never" class="profile-sidebar">
          <div class="profile-avatar">
            <el-avatar :size="80" :src="user.avatar" style="background-color:#409eff;font-size:32px;">{{ user?.real_name?.[0] || user?.username?.[0] || '?' }}</el-avatar>
            <div class="profile-name">{{ user?.real_name || user?.username }}</div>
          </div>
          <el-menu :default-active="activeTab" @select="onMenuSelect" style="border:none;">
            <el-menu-item index="info"><i class="el-icon-user" />我的信息</el-menu-item>
            <el-menu-item index="password"><i class="el-icon-key" />修改密码</el-menu-item>
            <el-menu-item index="logs"><i class="el-icon-document" />登录日志</el-menu-item>
            <el-menu-item index="security"><i class="el-icon-shield" />安全设置</el-menu-item>
            <el-menu-item index="fido2"><i class="el-icon-unlock" />手机密钥</el-menu-item>
          </el-menu>
        </el-card>
      </el-col>
      <!-- 右侧内容 -->
      <el-col :span="19">
        <el-card shadow="never" style="min-height:500px;">

          <!-- 我的信息 -->
          <div v-if="activeTab==='info'">
            <h3>我的信息</h3>
            <el-row :gutter="40">
              <el-col :span="8" style="text-align:center;">
                <el-avatar :size="120" :src="user.avatar" style="background-color:#409eff;font-size:48px;margin-bottom:16px;">{{ user?.real_name?.[0] || '?' }}</el-avatar>
                <div>
                  <el-button size="small" :loading="avatarUploading" @click="handleUploadAvatar">更换头像</el-button>
                  <el-button size="small" @click="handleRemoveAvatar">移除</el-button>
                </div>
              </el-col>
              <el-col :span="16">
                <el-form label-width="100px" size="small">
                  <el-form-item label="真实姓名"><el-input v-model="user.real_name" @blur="saveProfile" /></el-form-item>
                  <el-form-item label="用户名"><span>{{ user.username }}</span></el-form-item>
                  <el-form-item label="手机号">
                    <div style="display:flex;gap:8px;align-items:center;">
                      <el-input v-model="user.phone" @blur="saveProfile" />
                      <el-button size="mini" type="primary" plain @click="openChangePhone">更换</el-button>
                    </div>
                  </el-form-item>
                  <el-form-item label="邮箱"><el-input v-model="user.email" @blur="saveProfile" /></el-form-item>
                  <el-form-item label="工号"><span>{{ user.employee_id || '-' }}</span></el-form-item>
                  <el-form-item label="用户类型"><el-tag size="mini">{{ {1:'后台用户',2:'员工',3:'两者皆是'}[user.user_type] }}</el-tag></el-form-item>
                  <el-form-item label="部门"><span>{{ user.department?.name || '-' }}</span></el-form-item>
                  <el-form-item label="岗位"><span>{{ user.position || '-' }}</span></el-form-item>
                  <el-form-item label="最后登录"><span>{{ user.last_login_at || '-' }}</span></el-form-item>
                </el-form>
              </el-col>
            </el-row>
          </div>

          <!-- 修改密码 -->
          <div v-if="activeTab==='password'">
            <h3>修改密码</h3>
            <el-steps :active="step" simple style="margin-bottom:20px;">
              <el-step title="验证身份" icon="el-icon-mobile-phone" />
              <el-step title="设置新密码" icon="el-icon-key" />
            </el-steps>

            <div v-if="step===0" style="max-width:400px;">
              <el-alert title="当前绑定手机号" type="info" :description="maskPhone(user?.phone||'未绑定')" show-icon style="margin-bottom:16px;" />
              <el-form label-width="100px" size="small">
                <el-form-item label="验证码">
                  <el-row :gutter="8">
                    <el-col :span="14"><el-input v-model="smsCode" placeholder="6位验证码" maxlength="6" /></el-col>
                    <el-col :span="10"><el-button :disabled="countdown>0" style="width:100%;" @click="sendSms">{{ countdown>0 ? `${countdown}s` : '获取验证码' }}</el-button></el-col>
                  </el-row>
                </el-form-item>
                <el-form-item><el-button type="primary" :loading="verifying" @click="verifySms">验证身份</el-button></el-form-item>
              </el-form>
            </div>

            <div v-if="step===1" style="max-width:400px;">
              <el-alert title="身份验证通过" type="success" description="请设置新密码" show-icon style="margin-bottom:16px;" />
              <el-form label-width="100px" size="small">
                <el-form-item label="新密码"><el-input v-model="pwdForm.password" type="password" show-password placeholder="6-20位" /></el-form-item>
                <el-form-item label="确认密码"><el-input v-model="pwdForm.confirm" type="password" show-password placeholder="再次输入" /></el-form-item>
                <el-form-item><el-button type="primary" :loading="changingPwd" @click="changePwd">确认修改</el-button></el-form-item>
              </el-form>
            </div>
          </div>

          <!-- 登录日志 -->
          <div v-if="activeTab==='logs'">
            <h3>登录日志</h3>
            <el-table :data="loginLogs" stripe size="small" v-loading="logLoading">
              <el-table-column prop="created_at" label="时间" width="170" />
              <el-table-column prop="ip" label="IP" width="140" />
              <el-table-column label="状态" width="80"><template slot-scope="{row}"><el-tag :type="row.response_code===0?'success':'danger'" size="mini">{{ row.response_code===0?'成功':'失败' }}</el-tag></template></el-table-column>
              <el-table-column prop="detail" label="描述" min-width="200" />
            </el-table>
            <el-pagination background :current-page="logPage" :page-size="20" :total="logTotal" layout="total,prev,pager,next" @current-change="p=>{logPage=p;fetchLogs()}" style="margin-top:12px;" />
          </div>

          <!-- 安全设置 -->
          <div v-if="activeTab==='security'">
            <h3>安全设置</h3>
            <el-form label-width="120px" size="small">
              <el-form-item label="最后登录时间"><span>{{ user.last_login_at || '-' }}</span></el-form-item>
              <el-form-item label="最后登录IP"><span>{{ user.last_login_ip || '-' }}</span></el-form-item>
              <el-form-item label="账号状态"><el-tag :type="user.status?'success':'danger'" size="mini">{{ user.status?'正常':'禁用' }}</el-tag></el-form-item>
              <el-form-item label="用户类型"><el-tag size="mini">{{ {1:'后台用户',2:'员工',3:'两者皆是'}[user.user_type] }}</el-tag></el-form-item>
            </el-form>
          </div>

        </el-card>
      </el-col>
    </el-row>
    <!-- 隐藏的文件选择器 -->
    <input ref="avatarFileInput" type="file" accept="image/jpeg,image/png,image/gif,image/webp" style="display:none" @change="onAvatarSelected" />

    <!-- 更换手机号弹窗 -->
    <el-dialog title="更换手机号" :visible.sync="changePhoneVisible" width="420px" top="15vh" @closed="resetChangePhone">
      <el-form label-width="90px" size="small">
        <el-form-item label="新手机号">
          <el-input v-model="newPhone" placeholder="请输入新手机号" maxlength="11" />
        </el-form-item>
        <el-form-item label="验证码">
          <el-row :gutter="8">
            <el-col :span="14"><el-input v-model="changeCode" placeholder="6位验证码" maxlength="6" /></el-col>
            <el-col :span="10"><el-button :disabled="phoneCd>0" style="width:100%;" @click="sendChangeSms">{{ phoneCd>0 ? `${phoneCd}s` : '获取验证码' }}</el-button></el-col>
          </el-row>
        </el-form-item>
      </el-form>
      <span slot="footer">
        <el-button size="small" @click="changePhoneVisible=false">取 消</el-button>
        <el-button size="small" type="primary" :loading="changingPhone" @click="doChangePhone">确认更换</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import { getProfile, updateProfile, uploadAvatar, removeAvatar, sendChangePwdSms, verifyChangePwdSms, changeProfilePassword, getLoginLogs, sendChangePhoneSms, changePhone } from '@/api/user'
import { removeToken } from '@/utils/auth'

export default {
  name: 'Profile',
  data() {
    return {
      user: {},
      activeTab: 'info',
      // 修改密码
      step: 0, smsCode: '', countdown: 0, timer: null, verifyToken: '',
      verifying: false, changingPwd: false,
      pwdForm: { password: '', confirm: '' },
      // 登录日志
      loginLogs: [], logLoading: false, logPage: 1, logTotal: 0,
      // 更换手机号
      changePhoneVisible: false, newPhone: '', changeCode: '', phoneCd: 0, phoneTimer: null, changingPhone: false,
      // 头像
      avatarUploading: false,
    }
  },
  created() { this.fetchProfile() },
  beforeDestroy() { clearInterval(this.timer); clearInterval(this.phoneTimer) },
  methods: {
    onMenuSelect(index) {
      // 手机密钥为独立页面，点击跳转
      if (index === 'fido2') {
        this.$router.push('/settings/security/my-keys')
        return
      }
      this.activeTab = index
    },
    async fetchProfile() {
      try { const r = await getProfile(); this.user = r.data || {} } catch (e) { /* */ }
    },
    maskPhone(p) { return p && p.length === 11 ? p.slice(0, 3) + '****' + p.slice(7) : p },
    async saveProfile() {
      try { await updateProfile({ real_name: this.user.real_name, phone: this.user.phone, email: this.user.email }); this.$message.success('已保存') } catch (e) { /* */ }
    },
    // ---- 头像 ----
    handleUploadAvatar() {
      if (this.avatarUploading) return
      this.$refs.avatarFileInput.click()
    },
    async onAvatarSelected(e) {
      const file = e.target.files?.[0]
      if (!file) return
      // 校验格式和大小
      const validTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp']
      if (!validTypes.includes(file.type)) { this.$message.error('仅支持 jpg/png/gif/webp 格式'); return }
      if (file.size > 2 * 1024 * 1024) { this.$message.error('文件大小不能超过2MB'); return }

      this.avatarUploading = true
      const formData = new FormData()
      formData.append('avatar', file)
      try {
        const r = await uploadAvatar(formData)
        this.user.avatar = r.data.avatar
        this.$message.success('头像已更新')
      } catch (e) { /* */ }
      this.avatarUploading = false
      // 清空 input 以便重复选择同一文件
      e.target.value = ''
    },
    async handleRemoveAvatar() {
      try { await removeAvatar(); this.user.avatar = ''; this.$message.success('头像已移除') } catch (e) { /* */ }
    },
    // ---- 短信 ----
    async sendSms() {
      try {
        await sendChangePwdSms(); this.$message.success('验证码已发送')
        this.countdown = 60; this.timer = setInterval(() => { this.countdown--; if (this.countdown <= 0) clearInterval(this.timer) }, 1000)
      } catch (e) { /* */ }
    },
    async verifySms() {
      if (!/^\d{6}$/.test(this.smsCode)) { this.$message.warning('请输入6位验证码'); return }
      this.verifying = true
      try { const r = await verifyChangePwdSms(this.smsCode); this.verifyToken = r.data.verify_token; this.step = 1 } catch (e) { /* */ }
      this.verifying = false
    },
    async changePwd() {
      const { password, confirm } = this.pwdForm
      if (password.length < 6 || password !== confirm) { this.$message.warning('请正确输入密码'); return }
      this.changingPwd = true
      try {
        await changeProfilePassword({ verify_token: this.verifyToken, password, confirm_password: confirm })
        this.$message.success('密码修改成功，请重新登录')
        removeToken(); setTimeout(() => this.$router.push('/login'), 1500)
      } catch (e) { /* */ }
      this.changingPwd = false
    },
    // ---- 更换手机号 ----
    openChangePhone() {
      this.newPhone = ''; this.changeCode = ''; this.changePhoneVisible = true
    },
    resetChangePhone() {
      this.newPhone = ''; this.changeCode = ''
      if (this.phoneTimer) { clearInterval(this.phoneTimer); this.phoneTimer = null }
      this.phoneCd = 0
    },
    async sendChangeSms() {
      if (!/^1[3-9]\d{9}$/.test(this.newPhone)) { this.$message.warning('请输入正确的手机号'); return }
      try {
        await sendChangePhoneSms(this.newPhone); this.$message.success('验证码已发送')
        this.phoneCd = 60
        this.phoneTimer = setInterval(() => { this.phoneCd--; if (this.phoneCd <= 0) clearInterval(this.phoneTimer) }, 1000)
      } catch (e) { /* */ }
    },
    async doChangePhone() {
      if (!/^1[3-9]\d{9}$/.test(this.newPhone)) { this.$message.warning('请输入正确的手机号'); return }
      if (!/^\d{6}$/.test(this.changeCode)) { this.$message.warning('请输入6位验证码'); return }
      this.changingPhone = true
      try {
        await changePhone({ new_phone: this.newPhone, code: this.changeCode })
        this.$message.success('手机号更换成功')
        this.changePhoneVisible = false
        this.user.phone = this.newPhone
        if (this.phoneTimer) { clearInterval(this.phoneTimer); this.phoneTimer = null }
        this.phoneCd = 0
      } catch (e) { /* */ }
      this.changingPhone = false
    },
    // ---- 登录日志 ----
    async fetchLogs() {
      this.logLoading = true
      try { const r = await getLoginLogs({ page: this.logPage, limit: 20 }); this.loginLogs = r.data.list; this.logTotal = r.data.total } catch (e) { /* */ }
      this.logLoading = false
    }
  },
  watch: {
    activeTab(n) { if (n === 'logs') this.fetchLogs() }
  }
}
</script>
<style scoped>
.profile-wrapper { padding: 0; }
.profile-sidebar { text-align: center; }
.profile-avatar { padding: 20px 0 0; }
.profile-name { margin: 12px 0; font-size: 16px; font-weight: bold; color: #333; }
</style>
