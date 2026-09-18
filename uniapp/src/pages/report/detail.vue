<template>
  <view class="rd-page">
    <view v-if="loading" class="rd-status"><text>加载中...</text></view>
    <view v-else-if="!report" class="rd-status">
      <u-icon name="error-circle" color="#c0cedc" size="40" />
      <text class="rd-empty-text">报工记录不存在</text>
    </view>
    <template v-else>
      <!-- 头部 -->
      <view class="rd-head">
        <view class="rd-head-no">
          <u-icon name="order" color="#4F46E5" size="18" />
          <text class="rd-no">{{ report.order_no }}</text>
        </view>
        <text class="rd-status-tag" :class="'st-' + report.status">{{ report.status_label }}</text>
      </view>

      <!-- 工单/产品 -->
      <view class="rd-card">
        <view class="rd-card-title">工单信息</view>
        <view class="rd-row"><text class="rd-label">产品名称</text><text class="rd-value strong">{{ report.product_name || '-' }}{{ report.product_spec ? '（' + report.product_spec + '）' : '' }}</text></view>
        <view class="rd-row"><text class="rd-label">工单编号</text><text class="rd-value">{{ report.order_no }}</text></view>
        <view class="rd-row"><text class="rd-label">报工人</text><text class="rd-value">{{ report.reporter_name }}</text></view>
        <view class="rd-row"><text class="rd-label">报工日期</text><text class="rd-value">{{ report.report_date }}</text></view>
        <view class="rd-row"><text class="rd-label">报工模式</text><text class="rd-value">{{ report.report_type_label || (report.report_type === 1 ? '个人报工' : '团队协作') }}</text></view>
      </view>

      <!-- 报工明细 -->
      <view class="rd-card">
        <view class="rd-card-title">报工明细</view>
        <view class="rd-row"><text class="rd-label">完成数量</text><text class="rd-value strong blue">{{ report.quantity || 0 }} 件</text></view>
        <view class="rd-row"><text class="rd-label">总工分</text><text class="rd-value strong blue">{{ report.total_score || 0 }} 分</text></view>
        <view class="rd-row" v-if="report.duration"><text class="rd-label">设备时长</text><text class="rd-value">{{ report.duration }} 小时</text></view>
        <view class="rd-row" v-if="report.task_type_label"><text class="rd-label">任务类型</text><text class="rd-value">{{ report.task_type_label }}</text></view>
        <view class="rd-row" v-if="report.workstation_name"><text class="rd-label">关联工位</text><text class="rd-value">{{ report.workstation_name }}</text></view>
        <view class="rd-row" v-if="report.process_name"><text class="rd-label">关联工序</text><text class="rd-value">{{ report.process_name }}</text></view>
        <view class="rd-row" v-if="report.device_name"><text class="rd-label">关联设备</text><text class="rd-value">{{ report.device_name }}{{ report.device_code ? '（' + report.device_code + '）' : '' }}</text></view>
        <view class="rd-row" v-if="report.task_description"><text class="rd-label">任务描述</text><text class="rd-value">{{ report.task_description }}</text></view>
        <view class="rd-row" v-if="report.remark"><text class="rd-label">备注</text><text class="rd-value">{{ report.remark }}</text></view>
      </view>

      <!-- 团队成员分配 -->
      <view v-if="report.items && report.items.length" class="rd-card">
        <view class="rd-card-title">成员分配</view>
        <view v-for="(it, i) in report.items" :key="i" class="rd-member">
          <text class="rd-member-name">{{ it.worker_name }}</text>
          <text class="rd-member-score">{{ it.allocated_score }} 分</text>
        </view>
      </view>

      <!-- 材料 -->
      <view v-if="report.materials && report.materials.length" class="rd-card">
        <view class="rd-card-title">材料配件</view>
        <view v-for="(m, i) in report.materials" :key="i" class="rd-member">
          <text class="rd-member-name">{{ m.material_code }} - {{ m.material_name }}</text>
          <text class="rd-member-score">{{ m.quantity }} {{ m.unit }}</text>
        </view>
      </view>

      <!-- 照片 -->
      <view v-if="report.photos && report.photos.length" class="rd-card">
        <view class="rd-card-title">作业照片</view>
        <view class="rd-photo-grid">
          <image v-for="(u, i) in report.photos" :key="i" :src="imgUrl(u)" mode="aspectFill" class="rd-photo" @click="preview(i)" />
        </view>
      </view>

      <!-- 审核信息 -->
      <view v-if="report.status === 1 || report.status === 2 || report.status === 3" class="rd-card">
        <view class="rd-card-title">审核信息</view>
        <view class="rd-row"><text class="rd-label">审核状态</text><text class="rd-value strong" :class="{ green: report.status === 2, red: report.status === 3 }">{{ report.status_label }}</text></view>
        <view class="rd-row" v-if="report.auditor_name"><text class="rd-label">审核人</text><text class="rd-value">{{ report.auditor_name }}</text></view>
        <view class="rd-row" v-if="report.audit_time"><text class="rd-label">审核时间</text><text class="rd-value">{{ formatTime(report.audit_time) }}</text></view>
        <view class="rd-row" v-if="report.audit_remark"><text class="rd-label">审核意见</text><text class="rd-value">{{ report.audit_remark }}</text></view>
      </view>
    </template>
  </view>
</template>

<script setup>
import { ref } from 'vue'
import { onLoad } from '@dcloudio/uni-app'

const report = ref(null)
const loading = ref(true)
let reportId = 0

function getToken() {
  return uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
}
function api(url, method, data) {
  return new Promise((resolve, reject) => {
    uni.request({
      url: uni.$base + url,
      method: method || 'GET',
      data: data || {},
      header: { 'Content-Type': 'application/x-www-form-urlencoded', 'Authorization': 'Bearer ' + getToken() },
      success: (r) => r.data?.code === 0 ? resolve(r.data.data) : reject(r.data || { msg: '请求失败' }),
      fail: () => reject({ msg: '网络异常，请稍后重试' })
    })
  })
}
function imgUrl(val) {
  if (!val) return ''
  if (val.startsWith('http://') || val.startsWith('https://')) return val
  if (val.startsWith('/')) return uni.$base + val
  return val
}
function formatTime(t) {
  if (!t) return ''
  const s = String(t).replace('T', ' ')
  return s.length > 16 ? s.slice(0, 16) : s
}

async function load() {
  loading.value = true
  try {
    report.value = await api('/api/production/report/detail/' + reportId)
  } catch (e) {
    report.value = null
  }
  loading.value = false
}
function preview(idx) {
  uni.previewImage({ urls: (report.value.photos || []).map(imgUrl), current: idx })
}

onLoad((options) => {
  reportId = Number(options?.id || 0)
  load()
})
</script>

<style scoped>
.rd-page { min-height: 100vh; background: #F4F6FB; padding: 12px 16px 30px; box-sizing: border-box; }
.rd-status { display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 60vh; gap: 12px; color: #b0c0cc; }
.rd-empty-text { font-size: 14px; color: #b0c0cc; }

.rd-head { display: flex; align-items: center; justify-content: space-between; background: rgba(255,255,255,0.95); border: 1px solid #E7ECF4; border-radius:122px; padding: 16px 20px; margin-bottom: 12px; }
.rd-head-no { display: flex; align-items: center; gap: 8px; }
.rd-no { font-size: 18px; font-weight: 700; color: #1a2332; }
.rd-status-tag { font-size: 12px; font-weight: 700; padding: 4px 14px; border-radius:30px; }
.rd-status-tag.st-0 { background: #f3f4f6; color: #6b7280; }
.rd-status-tag.st-1 { background: #fef3e2; color: #f59e0b; }
.rd-status-tag.st-2 { background: #f0f9eb; color: #34c759; }
.rd-status-tag.st-3 { background: #fdecea; color: #e74c5e; }
.rd-status-tag.st-4 { background: #f3f4f6; color: #6b7280; }

.rd-card { background: rgba(255,255,255,0.95); border: 1px solid #E7ECF4; border-radius:122px; padding: 16px 18px; margin-bottom: 12px; }
.rd-card-title { font-size: 14px; font-weight: 700; color: #1a2332; margin-bottom: 12px; }
.rd-row { display: flex; align-items: flex-start; padding: 6px 0; }
.rd-label { width: 84px; flex-shrink: 0; font-size: 13px; color: #9ca3af; }
.rd-value { flex: 1; font-size: 14px; color: #1a2332; }
.rd-value.strong { font-weight: 600; }
.rd-value.blue { color: #4F46E5; }
.rd-value.green { color: #34c759; }
.rd-value.red { color: #e74c5e; }

.rd-member { display: flex; align-items: center; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #F4F6FB; }
.rd-member:last-child { border-bottom: none; }
.rd-member-name { font-size: 14px; color: #1a2332; }
.rd-member-score { font-size: 14px; font-weight: 700; color: #4F46E5; }

.rd-photo-grid { display: flex; flex-wrap: wrap; gap: 10px; }
.rd-photo { width: 84px; height: 84px; border-radius:24px; }
</style>
