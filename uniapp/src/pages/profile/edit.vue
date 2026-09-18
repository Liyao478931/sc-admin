<template>
  <view class="edit-page">
    <!-- 头像 -->
    <view class="avatar-section" @click="chooseAvatar">
      <image v-if="form.avatar" :src="form.avatar" mode="aspectFill" class="avatar-img"></image>
      <text v-else class="avatar-text">{{ (form.name || '员').substring(0,1) }}</text>
      <view class="avatar-edit"><u-icon name="camera" color="#fff" size="18" /></view>
    </view>

    <!-- 绑定员工档案（未关联时显示） -->
    <view v-if="showBind" class="bind-card">
      <view class="bind-title">绑定我的员工档案</view>
      <view class="bind-desc">未检测到与您账号关联的员工档案，请输入工号完成绑定（工号可在后台个人档案查看）。</view>
      <view class="bind-row">
        <u-input v-model="bindEmployeeId" placeholder="请输入工号，如 EMP00010" border="none" :customStyle="{ height: '48px', fontSize: '15px' }" />
        <u-button size="small" :text="binding ? '绑定中...' : '绑定'" type="primary" :disabled="binding" @click="handleBind" />
      </view>
    </view>

    <!-- 组织信息（只读） -->
    <view class="readonly-card">
      <view class="readonly-item" v-if="profile.employee_id"><text class="ro-label">工号</text><text class="ro-value">{{ profile.employee_id }}</text></view>
      <view class="readonly-item" v-if="profile.department_name"><text class="ro-label">部门</text><text class="ro-value">{{ profile.department_name }}</text></view>
      <view class="readonly-item" v-if="profile.hire_date"><text class="ro-label">入职日期</text><text class="ro-value">{{ profile.hire_date }}</text></view>
    </view>

    <!-- 个人资料（可编辑） -->
    <view class="section-title">个人资料</view>
    <view class="form-card">
      <view class="form-item">
        <text class="form-label">姓名</text>
        <u-input v-model="form.name" placeholder="请输入姓名" border="none" :customStyle="{ height: '48px', fontSize: '15px' }" />
      </view>
      <view class="form-item">
        <text class="form-label">性别</text>
        <picker :range="genderOptions" @change="(e)=>onPick(e, 'gender', genderOptions)">
          <view class="picker-value" :class="{ placeholder: !form.gender }">{{ form.gender || '请选择性别' }}</view>
        </picker>
      </view>
      <view class="form-item">
        <text class="form-label">生日</text>
        <picker mode="date" :value="form.birthday" @change="onBirthdayChange">
          <view class="picker-value" :class="{ placeholder: !form.birthday }">{{ form.birthday || '请选择生日' }}</view>
        </picker>
      </view>
      <view class="form-item">
        <text class="form-label">手机号</text>
        <u-input v-model="form.phone" type="number" maxlength="11" placeholder="请输入手机号" border="none" :customStyle="{ height: '48px', fontSize: '15px' }" />
      </view>
      <view class="form-item">
        <text class="form-label">邮箱</text>
        <u-input v-model="form.email" placeholder="请输入邮箱" border="none" :customStyle="{ height: '48px', fontSize: '15px' }" />
      </view>
      <view class="form-item">
        <text class="form-label">民族</text>
        <u-input v-model="form.nation" placeholder="请输入民族" border="none" :customStyle="{ height: '48px', fontSize: '15px' }" />
      </view>
      <view class="form-item">
        <text class="form-label">血型</text>
        <picker :range="bloodOptions" @change="(e)=>onPick(e, 'blood_type', bloodOptions)">
          <view class="picker-value" :class="{ placeholder: !form.blood_type }">{{ form.blood_type || '请选择血型' }}</view>
        </picker>
      </view>
      <view class="form-item">
        <text class="form-label">政治面貌</text>
        <picker :range="politicalOptions" @change="(e)=>onPick(e, 'political_status', politicalOptions)">
          <view class="picker-value" :class="{ placeholder: !form.political_status }">{{ form.political_status || '请选择政治面貌' }}</view>
        </picker>
      </view>
      <view class="form-item">
        <text class="form-label">婚姻状况</text>
        <picker :range="maritalOptions" @change="(e)=>onPick(e, 'marital_status', maritalOptions)">
          <view class="picker-value" :class="{ placeholder: !form.marital_status }">{{ form.marital_status || '请选择婚姻状况' }}</view>
        </picker>
      </view>
      <view class="form-item">
        <text class="form-label">户籍地址</text>
        <u-input v-model="form.domicile" placeholder="请输入户籍地址" border="none" :customStyle="{ height: '48px', fontSize: '15px' }" />
      </view>
      <view class="form-item">
        <text class="form-label">家庭住址</text>
        <u-input v-model="form.address" placeholder="请输入家庭住址" border="none" :customStyle="{ height: '48px', fontSize: '15px' }" />
      </view>
    </view>

    <!-- 学历信息 -->
    <view class="section-title">学历信息</view>
    <view class="form-card">
      <view class="form-item">
        <text class="form-label">学历</text>
        <picker :range="eduOptions" @change="(e)=>onPick(e, 'education', eduOptions)">
          <view class="picker-value" :class="{ placeholder: !form.education }">{{ form.education || '请选择学历' }}</view>
        </picker>
      </view>
      <view class="form-item">
        <text class="form-label">毕业院校</text>
        <u-input v-model="form.school" placeholder="请输入毕业院校" border="none" :customStyle="{ height: '48px', fontSize: '15px' }" />
      </view>
      <view class="form-item">
        <text class="form-label">专业</text>
        <u-input v-model="form.major" placeholder="请输入专业" border="none" :customStyle="{ height: '48px', fontSize: '15px' }" />
      </view>
      <view class="form-item">
        <text class="form-label">毕业时间</text>
        <picker mode="date" :value="form.graduation_date" @change="onGradDateChange">
          <view class="picker-value" :class="{ placeholder: !form.graduation_date }">{{ form.graduation_date || '请选择毕业时间' }}</view>
        </picker>
      </view>
    </view>

    <view class="tip-text">身份证号、银行卡号等敏感信息由管理员维护，如需修改请联系管理员。</view>

    <u-button type="primary" shape="circle" :text="saving ? '保存中...' : '保存'" :loading="saving" @click="handleSave" />
  </view>
</template>

<script setup>
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'

const genderOptions = ['男', '女']
const bloodOptions = ['A', 'B', 'AB', 'O', '其他']
const politicalOptions = ['群众', '共青团员', '中共党员', '其他']
const maritalOptions = ['未婚', '已婚', '离异', '其他']
const eduOptions = ['高中及以下', '大专', '本科', '硕士', '博士', '其他']

const form = ref({ avatar: '', name: '', gender: '', birthday: '', phone: '', email: '', blood_type: '', nation: '', political_status: '', marital_status: '', domicile: '', address: '', education: '', school: '', major: '', graduation_date: '' })
const profile = ref({})
const saving = ref(false)
const showBind = ref(false)
const bindEmployeeId = ref('')
const binding = ref(false)

function getToken() {
  return uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
}

function api(url, method, data) {
  return new Promise((resolve, reject) => {
    uni.request({
      url: uni.$base + url,
      method: method || 'GET',
      data: data || {},
      header: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Bearer ' + getToken()
      },
      success: (r) => r.data?.code === 0 ? resolve(r.data) : reject(r.data || { msg: '请求失败' }),
      fail: () => reject({ msg: '网络异常，请稍后重试' })
    })
  })
}

async function loadProfile() {
  try {
    const res = await api('/api/profile', 'GET')
    const d = res.data || {}
    const p = d.profile || {}
    const edu = (p.educations && p.educations[0]) || {}
    profile.value = {
      employee_id: p.employee_id || '',
      department_name: (d.department && (d.department.name || d.department.department_name)) || p.department_name || '',
      hire_date: p.hire_date || ''
    }
    form.value = {
      avatar: d.avatar || '',
      name: p.name || d.real_name || '',
      gender: p.gender || '',
      birthday: p.birthday || d.birthday || '',
      phone: p.phone || d.phone || '',
      email: p.email || d.email || '',
      blood_type: p.blood_type || '',
      nation: p.nation || '',
      political_status: p.political_status || '',
      marital_status: p.marital_status || '',
      domicile: p.domicile || '',
      address: p.address || '',
      education: edu.education || '',
      school: edu.school || '',
      major: edu.major || '',
      graduation_date: edu.graduation_date || ''
    }
    // 未关联档案时显示绑定入口
    if (!d.profile) showBind.value = true
  } catch (e) {}
}

async function handleBind() {
  const empId = bindEmployeeId.value.trim()
  if (!empId) { uni.showToast({ title: '请输入工号', icon: 'none' }); return }
  binding.value = true
  try {
    await api('/api/mobile/profile/bind', 'POST', { employee_id: empId })
    uni.showToast({ title: '绑定成功', icon: 'success' })
    showBind.value = false
    await loadProfile()
  } catch (e) {
    uni.showToast({ title: e.msg || '绑定失败', icon: 'none' })
  }
  binding.value = false
}

function chooseAvatar() {
  uni.chooseImage({ count: 1, success: (res) => {
    if (!res.tempFilePaths?.length) return
    uni.uploadFile({
      url: uni.$base + '/api/profile/avatar',
      filePath: res.tempFilePaths[0],
      name: 'avatar',
      header: { 'Authorization': 'Bearer ' + getToken() },
      success: (r) => {
        try {
          const rd = JSON.parse(r.data || '{}')
          if (rd.code === 0 && rd.data?.url) {
            form.value.avatar = rd.data.url
            uni.showToast({ title: '头像已更新', icon: 'success' })
          } else {
            uni.showToast({ title: rd.msg || '上传失败', icon: 'none' })
          }
        } catch (e) { uni.showToast({ title: '上传失败', icon: 'none' }) }
      },
      fail: () => uni.showToast({ title: '上传失败', icon: 'none' })
    })
  } })
}

function onPick(e, key, options) { form.value[key] = options[Number(e.detail.value)] }
function onBirthdayChange(e) { form.value.birthday = e.detail.value }
function onGradDateChange(e) { form.value.graduation_date = e.detail.value }

async function handleSave() {
  if (!form.value.name) { uni.showToast({ title: '请输入姓名', icon: 'none' }); return }
  if (!/^1[3-9]\d{9}$/.test(form.value.phone)) { uni.showToast({ title: '请输入正确的手机号', icon: 'none' }); return }
  saving.value = true
  try {
    await api('/api/mobile/profile/detail', 'PUT', {
      name: form.value.name,
      gender: form.value.gender,
      birthday: form.value.birthday,
      phone: form.value.phone,
      email: form.value.email,
      blood_type: form.value.blood_type,
      nation: form.value.nation,
      political_status: form.value.political_status,
      marital_status: form.value.marital_status,
      domicile: form.value.domicile,
      address: form.value.address,
      education: form.value.education,
      school: form.value.school,
      major: form.value.major,
      graduation_date: form.value.graduation_date
    })
    uni.showToast({ title: '保存成功', icon: 'success' })
    setTimeout(() => uni.navigateBack(), 800)
  } catch (e) {
    uni.showToast({ title: e.msg || '保存失败', icon: 'none' })
  }
  saving.value = false
}

onLoad(loadProfile)
</script>

<style scoped>
.edit-page { min-height: 100vh; background: #f5f6fa; padding-bottom: 40px; }
.avatar-section { display: flex; justify-content: center; padding: 30px 0 10px; position: relative; }
.avatar-img { width: 80px; height: 80px; border-radius:50%; background: #e8ecf1; }
.avatar-text { width: 80px; height: 80px; border-radius:50%; background: #3d5a73; color: #fff; font-size: 32px; font-weight: 600; display: flex; align-items: center; justify-content: center; }
.avatar-edit { position: absolute; bottom: 4px; right: calc(50% - 54px); width: 26px; height: 26px; border-radius:50%; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; font-size: 13px; }
.readonly-card { background: #fff; margin: 12px 16px 4px; border-radius:24px; padding: 4px 16px; display: flex; flex-wrap: wrap;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.readonly-item { display: flex; align-items: center; padding: 10px 0; margin-right: 24px; }
.ro-label { font-size: 13px; color: #909399; }
.ro-value { font-size: 13px; color: #303133; margin-left: 6px; font-weight: 500; }
.section-title { padding: 16px 20px 6px; font-size: 14px; color: #909399; }
.form-card { background: #fff; margin: 0 16px; border-radius:24px; padding: 0 16px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.form-item { padding: 12px 0; border-bottom: 1px solid #f5f6fa; display: flex; align-items: center; }
.form-item:last-child { border-bottom: none; }
.form-label { font-size: 14px; color: #303133; width: 90px; flex-shrink: 0; }
.form-input { flex: 1; height: 40px; font-size: 15px; }
.picker-value { flex: 1; height: 40px; line-height: 40px; font-size: 15px; }
.picker-value.placeholder { color: #c0c4cc; }
.tip-text { margin: 16px; font-size: 12px; color: #b0b8c4; line-height: 1.6; }
.submit-btn { margin: 10px 16px; width: calc(100% - 32px); height: 44px; border-radius:24px; background: #4f46e5; color: #fff; font-size: 16px; border: none; display: flex; align-items: center; justify-content: center; }
.submit-btn[disabled] { opacity: 0.6; }
/* 绑定档案 */
.bind-card { background: #fff; margin: 12px 16px; border-radius:24px; padding: 16px; border: 1px dashed #4f46e5;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.bind-title { font-size: 15px; font-weight: 600; color: #1a2332; }
.bind-desc { font-size: 12px; color: #909399; margin-top: 6px; line-height: 1.6; }
.bind-row { display: flex; align-items: center; gap: 10px; margin-top: 12px; }
.bind-input { flex: 1; height: 40px; background: #f5f6fa; border-radius:24px; padding: 0 12px; font-size: 14px; }
.bind-btn { flex-shrink: 0; height: 40px; padding: 0 22px; background: #4f46e5; color: #fff; border: none; border-radius:24px; font-size: 14px; display: flex; align-items: center; justify-content: center; }
.bind-btn[disabled] { opacity: 0.6; }
</style>
