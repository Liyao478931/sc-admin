<template>
  <view class="archive-page">
    <view v-if="loading" class="loading">加载中...</view>

    <template v-else>
      <!-- 基本信息 -->
      <view class="info-card">
        <view class="info-header">
          <view class="avatar">
            <image v-if="user.avatar" :src="user.avatar" mode="aspectFill" class="avatar-img"></image>
            <text v-else class="avatar-text">{{ avatarText }}</text>
          </view>
          <view class="info">
            <text class="name">{{ user.name || '员工' }}</text>
            <view class="status" v-if="user.status == 1 || user.employee_status == 1">
              <view class="status-dot"></view><text>在职</text>
            </view>
          </view>
        </view>
      </view>

      <!-- 基本信息 -->
      <view class="section-title">基本信息</view>
      <view class="info-card">
        <view class="info-row"><text class="info-label">工号</text><text class="info-value">{{ user.employee_id || '-' }}</text></view>
        <view class="info-row"><text class="info-label">姓名</text><text class="info-value">{{ user.name || '-' }}</text></view>
        <view class="info-row"><text class="info-label">性别</text><text class="info-value">{{ genderText }}</text></view>
        <view class="info-row"><text class="info-label">出生日期</text><text class="info-value">{{ user.birthday || '-' }}</text></view>
        <view class="info-row"><text class="info-label">手机号</text><text class="info-value">{{ user.phone || '-' }}</text></view>
        <view class="info-row"><text class="info-label">邮箱</text><text class="info-value">{{ user.email || '-' }}</text></view>
        <view class="info-row"><text class="info-label">民族</text><text class="info-value">{{ user.nation || '-' }}</text></view>
        <view class="info-row"><text class="info-label">政治面貌</text><text class="info-value">{{ user.political_status || '-' }}</text></view>
        <view class="info-row"><text class="info-label">婚姻状况</text><text class="info-value">{{ user.marital_status || '-' }}</text></view>
        <view class="info-row"><text class="info-label">血型</text><text class="info-value">{{ user.blood_type || '-' }}</text></view>
        <view class="info-row"><text class="info-label">籍贯</text><text class="info-value">{{ user.domicile || '-' }}</text></view>
        <view class="info-row"><text class="info-label">家庭住址</text><text class="info-value">{{ user.address || '-' }}</text></view>
        <view class="info-row"><text class="info-label">身份证号</text><text class="info-value">{{ user.id_card ? maskIdCard(user.id_card) : '-' }}</text></view>
        <view class="info-row"><text class="info-label">银行卡号</text><text class="info-value">{{ user.bank_card ? maskBankCard(user.bank_card) : '-' }}</text></view>
      </view>

      <!-- 工作信息 -->
      <view class="section-title">工作信息</view>
      <view class="info-card">
        <view class="info-row"><text class="info-label">部门</text><text class="info-value">{{ user.department || '-' }}</text></view>
        <view class="info-row"><text class="info-label">岗位</text><text class="info-value">{{ user.position || '-' }}</text></view>
        <view class="info-row"><text class="info-label">直属领导ID</text><text class="info-value">{{ user.leader_id || '-' }}</text></view>
        <view class="info-row"><text class="info-label">入职日期</text><text class="info-value">{{ user.hire_date || '-' }}</text></view>
        <view class="info-row"><text class="info-label">入职天数</text><text class="info-value">{{ user.join_days || 0 }} 天</text></view>
      </view>

      <!-- 教育信息 -->
      <view class="section-title">教育信息</view>
      <view class="info-card">
        <view class="info-row"><text class="info-label">学历</text><text class="info-value">{{ user.education || '-' }}</text></view>
        <view class="info-row"><text class="info-label">毕业院校</text><text class="info-value">{{ user.graduate_school || '-' }}</text></view>
        <view class="info-row"><text class="info-label">专业</text><text class="info-value">{{ user.major || '-' }}</text></view>
      </view>

      <!-- 合同信息 -->
      <view class="section-title">合同信息</view>
      <view class="info-card">
        <view class="info-row"><text class="info-label">合同开始</text><text class="info-value">{{ user.contract_start_date || '-' }}</text></view>
        <view class="info-row"><text class="info-label">合同结束</text><text class="info-value">{{ user.contract_end_date || '-' }}</text></view>
        <view class="info-row"><text class="info-label">试用期结束</text><text class="info-value">{{ user.probation_end_date || '-' }}</text></view>
        <view class="info-row"><text class="info-label">试用期(月)</text><text class="info-value">{{ user.probation_months || '-' }}</text></view>
      </view>

      <!-- 紧急联系人 -->
      <view class="section-title">紧急联系人</view>
      <view class="info-card">
        <view class="info-row"><text class="info-label">联系人</text><text class="info-value">{{ user.emergency_contact || '-' }}</text></view>
        <view class="info-row"><text class="info-label">联系电话</text><text class="info-value">{{ user.emergency_phone || '-' }}</text></view>
      </view>
    </template>
  </view>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

const user = ref({})
const loading = ref(true)
const avatarText = computed(() => (user.value.name || '员').substring(0, 1))

const genderText = computed(() => {
  const g = user.value.gender
  if (g == 1) return '男'
  if (g == 2) return '女'
  return '-'
})

function goBack() { uni.navigateBack() }

function maskIdCard(id) {
  if (!id || id.length < 8) return id || '-'
  return id.substring(0, 4) + '********' + id.substring(id.length - 4)
}

function maskBankCard(card) {
  if (!card || card.length < 8) return card || '-'
  return '**** **** **** ' + card.substring(card.length - 4)
}

onMounted(async () => {
  try {
    const token = uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
    const header = token ? { 'Authorization': 'Bearer ' + token } : {}
    uni.request({
      url: uni.$base + '/api/user/profile',
      header,
      success: (r) => {
        if (r.data?.code === 0 && r.data.data) user.value = r.data.data
      },
      complete: () => { loading.value = false }
    })
  } catch (e) { loading.value = false }
})
</script>

<style scoped>
.archive-page { min-height: 100vh; background: #F5F6FA; padding-bottom: 20px; }
.page-header { height: 44px; background: #fff; display: flex; align-items: center; justify-content: space-between; padding: 0 12px; border-bottom: 1px solid #E8ECF1; position: sticky; top: 0; z-index: 10; }
.header-back { width: 44px; height: 44px; display: flex; align-items: center; }
.header-arrow { font-size: 28px; color: #303133; }
.header-title { font-size: 16px; font-weight: 600; color: #303133; }
.header-placeholder { width: 44px; }
.loading { text-align: center; padding: 60px; color: #999; }

.info-card { background: #fff; margin: 0 16px 4px; border-radius:24px; padding: 16px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.info-header { display: flex; align-items: center; gap: 14px; }
.avatar { width: 64px; height: 64px; border-radius:50%; background: linear-gradient(135deg, #4F46E5, #7C6FF0); display: flex; align-items: center; justify-content: center; overflow: hidden; }
.avatar-img { width: 100%; height: 100%; }
.avatar-text { font-size: 26px; color: #fff; font-weight: 600; }
.info { flex: 1; }
.name { font-size: 18px; font-weight: 600; color: #1A1A2E; display: block; }
.status { display: flex; align-items: center; gap: 4px; margin-top: 6px; font-size: 12px; color: #34D399; }
.status-dot { width: 6px; height: 6px; border-radius:50%; background: #34D399; }

.section-title { padding: 12px 16px 6px; font-size: 13px; color: #999; }
.info-row { display: flex; padding: 10px 0; border-bottom: 1px solid #F5F6FA; }
.info-row:last-child { border-bottom: none; }
.info-label { width: 100px; color: #999; font-size: 14px; flex-shrink: 0; }
.info-value { flex: 1; color: #303133; font-size: 14px; word-break: break-all; }
</style>
