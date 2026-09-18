<template>
  <view class="oa-apply-page">
    <!-- 顶部导航 -->
    <view class="oa-apply-nav" :style="{ paddingTop: statusBarHeight + 'px' }">
      <view class="oa-apply-nav-left">
        <view class="oa-apply-back" @click="goBack">
          <u-icon name="arrow-left" color="#1a2332" size="18"></u-icon>
          <text class="oa-apply-back-text">返回</text>
        </view>
        <text class="oa-apply-nav-title">假勤申请</text>
      </view>
    </view>

    <!-- 滚动内容 -->
    <scroll-view class="oa-apply-scroll" scroll-y :style="{ height: scrollHeight + 'px' }">
      <view class="oa-apply-form">
        <!-- 申请人信息 -->
        <view class="oa-info-card">
          <view class="oa-avatar">
            <image v-if="userInfo.avatar" :src="userInfo.avatar" mode="aspectFill" class="oa-avatar-img"></image>
            <text v-else>{{ nameInitial }}</text>
          </view>
          <view class="oa-info">
            <text class="oa-name">{{ userInfo.real_name || userInfo.name || '未登录' }}</text>
            <text class="oa-dept">{{ userInfo.department || '' }}{{ userInfo.position ? ' · ' + userInfo.position : '' }}</text>
          </view>
          <text class="oa-status-online">● 在职</text>
        </view>

        <!-- 假勤类型 -->
        <view class="oa-form-group">
          <view class="oa-label">假勤类型 <text class="oa-required">*</text></view>
          <view class="oa-radio-group">
            <view
              v-for="t in leaveTypes"
              :key="t.value"
              class="oa-radio-item"
              :class="{ active: leaveType === t.value }"
              @click="selectType(t.value)"
            >
              <text>{{ t.label }}</text>
            </view>
          </view>
        </view>

        <!-- 开始时间 -->
        <view class="oa-form-group">
          <view class="oa-label">开始时间 <text class="oa-required">*</text></view>
          <view class="oa-datetime-selector">
            <picker mode="date" :value="startDate" :end="endDate || undefined" @change="onStartDate">
              <view class="oa-datetime-date">
                <text :class="{ placeholder: !startDate }">{{ startDate || '请选择日期' }}</text>
              </view>
            </picker>
            <!-- 加班：选时间点；其他：选上午/下午 -->
            <picker v-if="isOvertime" mode="time" :value="startTime" @change="onStartTime">
              <view class="oa-datetime-period">
                <text :class="{ placeholder: !startTime }">{{ startTime || '时间' }}</text>
                <u-icon name="arrow-down" color="#b0c0cc" size="12"></u-icon>
              </view>
            </picker>
            <view v-else class="oa-datetime-period" @click="toggleStartPeriod">
              <text>{{ startPeriod }}</text>
              <u-icon name="arrow-down" color="#b0c0cc" size="12"></u-icon>
            </view>
          </view>
        </view>

        <!-- 结束时间 -->
        <view class="oa-form-group">
          <view class="oa-label">结束时间 <text class="oa-required">*</text></view>
          <view class="oa-datetime-selector">
            <picker mode="date" :value="endDate" :start="startDate" @change="onEndDate">
              <view class="oa-datetime-date">
                <text :class="{ placeholder: !endDate }">{{ endDate || '请选择日期' }}</text>
              </view>
            </picker>
            <!-- 加班：选时间点；其他：选上午/下午 -->
            <picker v-if="isOvertime" mode="time" :value="endTime" @change="onEndTime">
              <view class="oa-datetime-period">
                <text :class="{ placeholder: !endTime }">{{ endTime || '时间' }}</text>
                <u-icon name="arrow-down" color="#b0c0cc" size="12"></u-icon>
              </view>
            </picker>
            <view v-else class="oa-datetime-period" @click="toggleEndPeriod">
              <text>{{ endPeriod }}</text>
              <u-icon name="arrow-down" color="#b0c0cc" size="12"></u-icon>
            </view>
          </view>
        </view>

        <!-- 申请天数 -->
        <view class="oa-form-group" v-if="!isOvertime">
          <view class="oa-label">申请天数 <text class="oa-required">*</text></view>
          <view class="oa-input-wrap">
            <u-icon name="grid" color="#b0c0cc" size="16"></u-icon>
            <u-input v-model="leaveDays" type="number" placeholder="选择日期后自动计算" border="none" disabled :customStyle="{ height: '48px', fontSize: '15px', color: '#1a2332' }" />
            <text class="oa-input-unit">天</text>
          </view>
        </view>

        <!-- 申请事由 -->
        <view class="oa-form-group">
          <view class="oa-label">申请事由 <text class="oa-required">*</text></view>
          <view class="oa-input-wrap oa-textarea-wrap">
            <u-icon name="edit-pen" color="#b0c0cc" size="16"></u-icon>
            <u-textarea v-model="reason" placeholder="请详细描述申请原因..." />
          </view>
        </view>

        <!-- 附件上传 -->
        <view class="oa-form-group">
          <view class="oa-label">附件 <text class="oa-hint">选填</text></view>
          <view class="oa-upload-wrap" @click="chooseAttachment">
            <view v-for="(att, i) in attachments" :key="i" class="oa-upload-file">
              <u-icon name="file-text" color="#4F46E5" size="16"></u-icon>
              <text class="oa-upload-file-name">{{ att.file_name }}</text>
              <view class="oa-upload-file-del" @click.stop="removeAttachment(i)"><MIcon name="close" :size="12" color="#ffffff" /></view>
            </view>
            <view class="oa-upload-btn">
              <u-icon name="plus" color="#4F46E5" size="20"></u-icon>
              <text class="oa-upload-btn-text">上传附件</text>
            </view>
          </view>
          <text class="oa-upload-tip">支持 jpg/png/gif/pdf/docx，单个不超过 5MB</text>
        </view>

        <!-- 紧急联系人 -->
        <view class="oa-form-group">
          <view class="oa-label">紧急联系人 <text class="oa-hint">选填</text></view>
          <view class="oa-input-wrap">
            <u-icon name="account" color="#b0c0cc" size="16"></u-icon>
            <u-input v-model="contactName" type="text" placeholder="请输入紧急联系人姓名" border="none" :customStyle="{ height: '48px', fontSize: '15px' }" />
          </view>
        </view>

        <!-- 联系电话 -->
        <view class="oa-form-group">
          <view class="oa-label">联系电话 <text class="oa-hint">选填</text></view>
          <view class="oa-input-wrap">
            <u-icon name="phone" color="#b0c0cc" size="16"></u-icon>
            <u-input v-model="contactPhone" type="number" placeholder="请输入紧急联系电话" border="none" :customStyle="{ height: '48px', fontSize: '15px' }" />
          </view>
        </view>

        <!-- 审批流程 -->
        <view class="oa-flow-card">
          <view class="oa-flow-title">
            <u-icon name="list" color="#4F46E5" size="16"></u-icon>
            <text>审批流程</text>
          </view>
          <view class="oa-flow-step">
            <view class="oa-step-dot done"><u-icon name="checkmark" color="#fff" size="12"></u-icon></view>
            <view class="oa-step-info">
              <text class="oa-step-name">提交申请</text>
              <text class="oa-step-desc">{{ userInfo.real_name || userInfo.name || '' }}</text>
            </view>
            <text class="oa-step-status done">待提交</text>
          </view>
          <view class="oa-flow-step">
            <view class="oa-step-dot active">2</view>
            <view class="oa-step-info">
              <text class="oa-step-name">部门主管审批</text>
              <text class="oa-step-desc">提交后自动进入审批流程</text>
            </view>
            <text class="oa-step-status active">进行中</text>
          </view>
          <view class="oa-flow-step">
            <view class="oa-step-dot waiting">3</view>
            <view class="oa-step-info">
              <text class="oa-step-name">人事部备案</text>
              <text class="oa-step-desc">审批通过后自动完成</text>
            </view>
            <text class="oa-step-status waiting">等待中</text>
          </view>
        </view>

        <!-- 提交按钮 -->
        <view class="oa-submit-section">
          <view class="oa-submit-btn" @click="submitApply">
            <u-icon name="share-square" color="#fff" size="18"></u-icon>
            <text>提交申请</text>
          </view>
        </view>
      </view>
    </scroll-view>
  </view>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { request } from '@/utils/request'

// 状态栏高度
const statusBarHeight = ref(0)
const scrollHeight = ref(0)
// #ifdef MP-WEIXIN
try {
  const info = uni.getSystemInfoSync()
  const sb = info.statusBarHeight || 0
  statusBarHeight.value = sb
  if (typeof uni.getMenuButtonBoundingClientRect === 'function') {
    const m = uni.getMenuButtonBoundingClientRect()
    if (m && m.top) statusBarHeight.value = m.top
  }
  scrollHeight.value = info.windowHeight - 100 || 500
} catch (e) { statusBarHeight.value = 44; scrollHeight.value = 500 }
// #endif
// #ifndef MP-WEIXIN
onMounted(() => {
  uni.getSystemInfo({ success: (sys) => { scrollHeight.value = sys.windowHeight - 100 || 500 } })
  loadUserInfo()
})
// #endif
// #ifdef MP-WEIXIN
loadUserInfo()
// #endif

// 用户信息
const userInfo = ref({})
const nameInitial = computed(() => (userInfo.value.real_name || userInfo.value.name || '员').substring(0, 1))

// 假勤类型（与 admin 端一致）
const leaveTypes = [
  { label: '年假', value: 1 },
  { label: '事假', value: 2 },
  { label: '病假', value: 3 },
  { label: '调休', value: 4 },
  { label: '加班', value: 5 },
  { label: '出差', value: 6 },
  { label: '婚假', value: 7 },
  { label: '丧假', value: 8 },
  { label: '产假', value: 9 },
  { label: '其他', value: 10 }
]
const leaveType = ref(1)

// 是否加班类型（加班选择时间点，其他选上午/下午）
const isOvertime = computed(() => leaveType.value === 5)

// 表单
const startDate = ref('')
const endDate = ref('')
const startPeriod = ref('上午')
const endPeriod = ref('上午')
const startTime = ref('')
const endTime = ref('')
const leaveDays = ref('')
const reason = ref('')
const contactName = ref('')
const contactPhone = ref('')
const attachments = ref([])

// 选择假勤类型
function selectType(val) {
  leaveType.value = val
  calcDays()
}

// 选择附件
function chooseAttachment() {
  uni.chooseImage({
    count: 9,
    success: (res) => {
      const files = res.tempFilePaths || []
      if (!files.length) return
      files.forEach(path => uploadAttachment(path))
    }
  })
}

// 上传附件
function uploadAttachment(filePath) {
  uni.showLoading({ title: '上传中...' })
  const token = uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
  uni.uploadFile({
    url: (import.meta.env.DEV ? '' : uni.$base) + '/api/hr/attendance/leave/upload',
    filePath,
    name: 'file',
    header: { 'Authorization': 'Bearer ' + token },
    success: (r) => {
      uni.hideLoading()
      try {
        const rd = JSON.parse(r.data || '{}')
        if (rd.code === 0 && rd.data) {
          attachments.value.push({
            attachment_type: 1,
            file_name: rd.data.name || '附件',
            file_path: rd.data.url || '',
            file_size: rd.data.size || 0,
            remark: ''
          })
          uni.showToast({ title: '上传成功', icon: 'success' })
        } else {
          uni.showToast({ title: rd.msg || '上传失败', icon: 'none' })
        }
      } catch (e) { uni.showToast({ title: '上传失败', icon: 'none' }) }
    },
    fail: () => { uni.hideLoading(); uni.showToast({ title: '上传失败', icon: 'none' }) }
  })
}

// 移除附件
function removeAttachment(i) { attachments.value.splice(i, 1) }

// 加载用户信息（含紧急联系人）
async function loadUserInfo() {
  try {
    const r = await request({ url: '/api/user/profile', method: 'GET' })
    if (r.code === 0 && r.data) {
      const d = r.data
      userInfo.value = {
        name: d.name || d.username || '',
        real_name: d.real_name || d.name || '',
        avatar: d.avatar || '',
        department: d.department || '',
        position: d.position || ''
      }
      // 紧急联系人：优先从档案同步
      const ec = d.emergency_contacts && d.emergency_contacts.length ? d.emergency_contacts[0] : null
      if (ec) {
        contactName.value = ec.name || ''
        contactPhone.value = ec.phone || ''
      }
      // 默认开始日期为今天
      const now = new Date()
      startDate.value = formatDate(now)
    }
  } catch (e) {}
}

function formatDate(d) {
  return d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2)
}

function onStartDate(e) {
  startDate.value = e.detail.value
  // 结束日期早于开始日期时自动修正
  if (endDate.value && endDate.value < startDate.value) {
    endDate.value = startDate.value
    uni.showToast({ title: '已自动调整结束日期', icon: 'none' })
  }
  calcDays()
}
function onEndDate(e) {
  endDate.value = e.detail.value
  if (endDate.value < startDate.value) {
    endDate.value = startDate.value
    uni.showToast({ title: '结束日期不能早于开始日期', icon: 'none' })
  }
  calcDays()
}
function toggleStartPeriod() { startPeriod.value = startPeriod.value === '上午' ? '下午' : '上午'; calcDays() }
function toggleEndPeriod() { endPeriod.value = endPeriod.value === '上午' ? '下午' : '上午'; calcDays() }
function onStartTime(e) { startTime.value = e.detail.value }
function onEndTime(e) { endTime.value = e.detail.value }

// 根据日期自动计算请假天数（支持 0.5 / 1.5 / 4.5 等半天）
function calcDays() {
  if (!startDate.value || !endDate.value) return
  if (isOvertime.value) {
    // 加班：不自动计算天数，保持可编辑（按小时计算由管理员处理）
    return
  }
  const s = new Date(startDate.value.replace(/-/g, '/'))
  const e = new Date(endDate.value.replace(/-/g, '/'))
  if (isNaN(s.getTime()) || isNaN(e.getTime())) return
  if (startDate.value === endDate.value) {
    // 同一天：上午+下午=1天，仅一个时段=0.5天
    leaveDays.value = startPeriod.value === endPeriod.value ? '0.5' : '1'
  } else {
    // 跨天：整天数 - 开始日下午减0.5 - 结束日上午减0.5
    const base = Math.round((e - s) / 86400000) + 1
    let days = base
    if (startPeriod.value === '下午') days -= 0.5
    if (endPeriod.value === '上午') days -= 0.5
    leaveDays.value = String(days)
  }
}

// 提交申请
async function submitApply() {
  // 校验
  if (!leaveType.value) { uni.showToast({ title: '请选择假勤类型', icon: 'none' }); return }
  if (!startDate.value || !endDate.value) { uni.showToast({ title: '请选择日期', icon: 'none' }); return }
  if (isOvertime.value) {
    if (!startTime.value || !endTime.value) { uni.showToast({ title: '请选择加班时间', icon: 'none' }); return }
    if (endTime.value <= startTime.value) { uni.showToast({ title: '结束时间需晚于开始时间', icon: 'none' }); return }
  } else {
    if (!leaveDays.value || parseFloat(leaveDays.value) <= 0) { uni.showToast({ title: '请输入有效的天数', icon: 'none' }); return }
  }
  if (!reason.value.trim()) { uni.showToast({ title: '请填写申请事由', icon: 'none' }); return }

  uni.showLoading({ title: '提交中...' })
  try {
    // 保存假勤申请
    const saveRes = await request({
      url: '/api/hr/attendance/leave/save',
      method: 'POST',
      data: {
        leave_type: leaveType.value,
        start_date: startDate.value,
        end_date: endDate.value,
        start_time: isOvertime.value ? startTime.value : (startPeriod.value === '上午' ? '09:00' : '13:00'),
        end_time: isOvertime.value ? endTime.value : (endPeriod.value === '上午' ? '12:00' : '18:00'),
        total_days: parseFloat(leaveDays.value) || 0,
        reason: reason.value.trim(),
        emergency_contact_name: contactName.value,
        emergency_contact_phone: contactPhone.value,
        attachments: attachments.value.map(a => ({ attachment_type: a.attachment_type || 1, file_name: a.file_name, file_path: a.file_path, file_size: a.file_size || 0, remark: '' })),
        status: 0
      }
    })
    if (saveRes.code === 0 && saveRes.data && saveRes.data.id) {
      // 提交审批（联动统一审批）
      const submitRes = await request({
        url: '/api/hr/attendance/leave/submit/' + saveRes.data.id,
        method: 'POST'
      })
      if (submitRes.code === 0) {
        uni.hideLoading()
        uni.showToast({ title: '申请已提交', icon: 'none' })
        setTimeout(() => { goBack() }, 1500)
      } else {
        uni.hideLoading()
        uni.showToast({ title: submitRes.msg || '提交审批失败', icon: 'none' })
      }
    } else {
      uni.hideLoading()
      uni.showToast({ title: saveRes.msg || '保存失败', icon: 'none' })
    }
  } catch (e) {
    uni.hideLoading()
    uni.showToast({ title: '网络异常，请重试', icon: 'none' })
  }
}

function goBack() { uni.navigateBack() }
</script>

<style scoped>
.oa-apply-page { min-height: 100vh; background: #F4F6FB; display: flex; flex-direction: column; }

/* 顶部导航 */
.oa-apply-nav { padding: 10px 16px 8px; background: #fff; }
.oa-apply-nav-left { display: flex; align-items: center; gap: 10px; }
.oa-apply-back { display: flex; align-items: center; gap: 4px; padding: 4px 8px; border-radius:24px; cursor: pointer; }
.oa-apply-back-text { font-size: 14px; font-weight: 500; color: #1a2332; }
.oa-apply-nav-title { font-size: 17px; font-weight: 600; color: #1a2332; flex: 1; text-align: center; margin-right: 44px; }

/* 滚动内容 */
.oa-apply-scroll { flex: 1; overflow-y: auto; }
.oa-apply-form { padding: 16px 16px 8px; }

/* 申请人信息 */
.oa-info-card { background: rgba(255,255,255,0.55); backdrop-filter: blur(8px); border-radius:122px; padding: 16px 18px; border: 1px solid rgba(255,255,255,0.4); margin-bottom: 16px; display: flex; align-items: center; gap: 14px; }
.oa-avatar { width: 48px; height: 48px; border-radius:50%; background: linear-gradient(135deg, #4F46E5, #7C6FF0); display: flex; align-items: center; justify-content: center; font-size: 18px; font-weight: 600; color: #fff; flex-shrink: 0; overflow: hidden; }
.oa-avatar-img { width: 100%; height: 100%; }
.oa-info { flex: 1; min-width: 0; }
.oa-name { font-size: 16px; font-weight: 600; color: #1a2332; display: block; }
.oa-dept { font-size: 13px; color: #8a9aa8; margin-top: 2px; display: block; }
.oa-status-online { font-size: 12px; color: #34c759; font-weight: 500; flex-shrink: 0; }

/* 表单组 */
.oa-form-group { margin-bottom: 16px; }
.oa-label { font-size: 14px; font-weight: 500; color: #1a2332; margin-bottom: 8px; display: flex; align-items: center; gap: 4px; }
.oa-required { color: #fb6e8c; font-size: 16px; }
.oa-hint { font-size: 12px; font-weight: 400; color: #b0c0cc; margin-left: auto; }

/* 输入框 */
.oa-input-wrap { background: rgba(255,255,255,0.5); border-radius:124px; padding: 0 16px; border: 1px solid rgba(255,255,255,0.3); display: flex; align-items: center; gap: 10px; min-height: 48px; }
.oa-input { flex: 1; padding: 14px 0; font-size: 15px; color: #1a2332; border: none; background: transparent; }
.oa-input-text { flex: 1; padding: 14px 0; font-size: 15px; color: #1a2332; }
.oa-input-text.placeholder { color: #c0cedc; }
.oa-input-unit { color: #b0c0cc; font-size: 14px; flex-shrink: 0; }
.oa-textarea-wrap { align-items: flex-start; }
.oa-textarea { flex: 1; min-height: 80px; padding: 14px 0; font-size: 15px; color: #1a2332; border: none; background: transparent; }

/* 附件上传 */
.oa-upload-wrap { display: flex; flex-wrap: wrap; gap: 8px; background: rgba(255,255,255,0.5); border-radius:124px; padding: 12px; border: 1px dashed rgba(110,142,251,0.3); }
.oa-upload-file { display: flex; align-items: center; gap: 6px; background: rgba(110,142,251,0.06); border-radius:24px; padding: 6px 10px; }
.oa-upload-file-name { font-size: 12px; color: #4a5a6a; max-width: 120px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.oa-upload-file-del { font-size: 12px; color: #fb6e8c; cursor: pointer; }
.oa-upload-btn { display: flex; align-items: center; gap: 6px; padding: 6px 14px; border: 1px solid rgba(110,142,251,0.2); border-radius:24px; cursor: pointer; }
.oa-upload-btn-text { font-size: 13px; color: #4F46E5; }
.oa-upload-tip { display: block; font-size: 11px; color: #b0c0cc; margin-top: 6px; }

/* 日期行 */
.oa-date-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }

/* 日期+时段选择器 */
.oa-datetime-selector { display: flex; align-items: center; border: 1px solid #e8ecf0; border-radius:24px; overflow: hidden; background: #fafbfc; }
.oa-datetime-date { flex: 1; padding: 12px 12px; cursor: pointer; font-size: 14px; color: #1a2332; text-align: center; border-right: 1px solid #e8ecf0; background: #fff; }
.oa-datetime-date .placeholder { color: #b0c0cc; }
.oa-datetime-period { padding: 12px; cursor: pointer; font-size: 14px; color: #1a2332; text-align: center; background: #F4F6FB; display: flex; align-items: center; gap: 4px; }

/* 单选组 */
.oa-radio-group { display: flex; gap: 10px; flex-wrap: wrap; }
.oa-radio-item { display: flex; align-items: center; padding: 8px 14px; background: rgba(255,255,255,0.4); border-radius:30px; border: 1px solid rgba(255,255,255,0.3); font-size: 14px; color: #1a2332; cursor: pointer; transition: 0.2s; }
.oa-radio-item.active { background: rgba(110,142,251,0.08); border-color: rgba(110,142,251,0.2); color: #4F46E5; font-weight: 500; }

/* 审批流程 */
.oa-flow-card { background: rgba(255,255,255,0.55); backdrop-filter: blur(8px); border-radius:122px; padding: 16px 18px; border: 1px solid rgba(255,255,255,0.4); margin-bottom: 16px; }
.oa-flow-title { font-size: 14px; font-weight: 500; color: #1a2332; margin-bottom: 12px; display: flex; align-items: center; gap: 8px; }
.oa-flow-step { display: flex; align-items: center; gap: 12px; padding: 6px 0; position: relative; }
.oa-flow-step:not(:last-child)::after { content: ''; position: absolute; left: 14px; top: 34px; width: 2px; height: 20px; background: #d5dce4; }
.oa-step-dot { width: 28px; height: 28px; border-radius:50%; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 600; color: #fff; flex-shrink: 0; position: relative; z-index: 1; }
.oa-step-dot.done { background: #34c759; }
.oa-step-dot.active { background: #4F46E5; }
.oa-step-dot.waiting { background: #d5dce4; }
.oa-step-info { flex: 1; }
.oa-step-name { font-size: 14px; font-weight: 500; color: #1a2332; display: block; }
.oa-step-desc { font-size: 12px; color: #9aabba; margin-top: 1px; display: block; }
.oa-step-status { font-size: 12px; font-weight: 500; }
.oa-step-status.done { color: #34c759; }
.oa-step-status.active { color: #4F46E5; }
.oa-step-status.waiting { color: #b0c0cc; }

/* 提交按钮 */
.oa-submit-section { padding: 4px 0 8px; }
.oa-submit-btn { width: 100%; padding: 16px; border-radius:122px; background: linear-gradient(135deg, #4F46E5, #7C6FF0); color: #fff; font-size: 16px; font-weight: 600; cursor: pointer; box-shadow: 0 4px 16px rgba(110,142,251,0.15); display: flex; align-items: center; justify-content: center; gap: 10px; }
.oa-submit-btn:active { transform: scale(0.97); }
</style>