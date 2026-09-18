<template>
  <view class="report-page">
    <!-- 报工模式 -->
    <view class="card">
      <view class="card-title">报工模式</view>
      <view class="mode-row">
        <view class="mode-item" :class="{ active: reportType === 1 }" @click="reportType = 1">
          <u-icon name="account" :color="reportType === 1 ? '#4F46E5' : '#8a9aa8'" size="22" />
          <text class="mode-name" :class="{ active: reportType === 1 }">个人报工</text>
        </view>
        <view class="mode-item" :class="{ active: reportType === 2 }" @click="reportType = 2">
          <u-icon name="man-add" :color="reportType === 2 ? '#4F46E5' : '#8a9aa8'" size="22" />
          <text class="mode-name" :class="{ active: reportType === 2 }">团队协作</text>
        </view>
      </view>
    </view>

    <!-- 关联工单 -->
    <view class="card">
      <view class="card-title">关联工单 <text class="req">*</text></view>
      <view class="pick-row" @click="openOrderPicker">
        <view class="pick-left">
          <u-icon name="order" color="#4F46E5" size="18" />
          <text class="pick-text" :class="{ placeholder: !currentOrder }">
            {{ currentOrder ? (currentOrder.order_no + ' - ' + (currentOrder.product_name || '')) : '请选择进行中的工单' }}
          </text>
        </view>
        <u-icon name="arrow-right" color="#c0cedc" size="14" />
      </view>
      <view v-if="currentOrder" class="order-meta">
        <text>产品：{{ currentOrder.product_name }}{{ currentOrder.product_spec ? '（' + currentOrder.product_spec + '）' : '' }}</text>
        <text>计划批量：{{ currentOrder.plan_quantity }} 件 · 已完工：{{ currentOrder.completed_quantity }}</text>
      </view>
    </view>

    <!-- 关联工位 / 工序 / 设备 -->
    <view class="card">
      <view class="card-title">关联工位 / 工序 / 设备</view>
      <view class="pick-row" @click="openWorkstationPicker">
        <view class="pick-left">
          <u-icon name="home" color="#4F46E5" size="18" />
          <text class="pick-text" :class="{ placeholder: !form.workstation_id }">
            {{ form.workstation_name || '选择工位（联动可做工序）' }}
          </text>
        </view>
        <u-icon name="arrow-right" color="#c0cedc" size="14" />
      </view>
      <view v-if="form.workstation_id && !availableProcesses.length" class="warn-tip">该工位暂未配置可做工序，请先到工位管理中配置工序</view>

      <view class="pick-row" :class="{ disabled: !form.workstation_id }" @click="openProcessPicker">
        <view class="pick-left">
          <u-icon name="edit-pen" color="#4F46E5" size="18" />
          <text class="pick-text" :class="{ placeholder: !form.process_id }">
            {{ form.process_name || '选择工序（自动带出工分定额）' }}
          </text>
        </view>
        <u-icon name="arrow-right" color="#c0cedc" size="14" />
      </view>

      <view class="pick-row" :class="{ disabled: !form.workstation_id || !deviceList.length }" @click="openDevicePicker">
        <view class="pick-left">
          <u-icon name="server-man" color="#4F46E5" size="18" />
          <text class="pick-text" :class="{ placeholder: !form.device_id }">
            {{ form.device_name ? (form.device_name + '（' + form.device_code + '）') : '选择设备' }}
          </text>
        </view>
        <u-icon name="arrow-right" color="#c0cedc" size="14" />
      </view>
      <view v-if="form.workstation_id && !deviceList.length" class="warn-tip">该工位未关联设备，请先到工位管理中配置设备</view>
    </view>

    <!-- 任务信息 -->
    <view class="card">
      <view class="card-title">任务信息</view>
      <view class="field">
        <text class="field-label">任务类型 <text class="req">*</text></text>
        <view class="task-tags">
          <view v-for="(t, v) in taskOptions" :key="v" class="task-tag" :class="{ active: form.task_type === Number(v) }" @click="form.task_type = Number(v)">{{ t }}</view>
        </view>
      </view>
      <view class="field">
        <text class="field-label">任务描述 <text class="req">*</text></text>
        <u-textarea v-model="form.task_description" placeholder="请描述本次完成的工作内容" maxlength="500" />
      </view>
      <view class="field-row">
        <view class="field half">
          <text class="field-label">完成数量 <text class="req">*</text></text>
          <view class="num-row">
            <view class="num-btn" @click="changeQty(-1)"><u-icon name="minus" color="#8a9aa8" size="14" /></view>
            <u-input v-model.number="form.quantity" type="number" border="none" :customStyle="{ height: '72rpx', fontSize: '28rpx' }" @input="onQuantityChange" />
            <view class="num-btn" @click="changeQty(1)"><u-icon name="plus" color="#8a9aa8" size="14" /></view>
          </view>
        </view>
        <view class="field half">
          <text class="field-label">设备时长(小时) <text class="req">*</text></text>
          <view class="num-row">
            <view class="num-btn" @click="changeDuration(-0.5)"><u-icon name="minus" color="#8a9aa8" size="14" /></view>
            <u-input v-model.number="form.duration" type="number" border="none" :customStyle="{ height: '72rpx', fontSize: '28rpx' }" />
            <view class="num-btn" @click="changeDuration(0.5)"><u-icon name="plus" color="#8a9aa8" size="14" /></view>
          </view>
        </view>
      </view>
      <view class="field">
        <text class="field-label">获取工分 <text class="req">*</text></text>
        <view class="score-row">
          <u-input v-model.number="form.total_score" type="number" border="none" :customStyle="{ height: '72rpx', fontSize: '28rpx' }" />
          <text class="score-tip">{{ scoreFormula || '选择工序后自动计算（定额 × 数量）' }}</text>
        </view>
      </view>
      <view class="field">
        <text class="field-label">报工日期 <text class="req">*</text></text>
        <picker mode="date" :value="form.report_date" @change="e => form.report_date = e.detail.value">
          <view class="pick-row inner">
            <view class="pick-left">
              <u-icon name="calendar" color="#4F46E5" size="18" />
              <text class="pick-text">{{ form.report_date }}</text>
            </view>
            <u-icon name="arrow-right" color="#c0cedc" size="14" />
          </view>
        </picker>
      </view>
      <view class="field">
        <text class="field-label">备注</text>
        <u-textarea v-model="form.remark" placeholder="备注（可选），如设备异常、质量问题等..." maxlength="500" />
      </view>
    </view>

    <!-- 团队协作：工分分配 -->
    <view v-if="reportType === 2" class="card">
      <view class="card-title">工分分配 <text class="add-link" @click="memberPickerOpen = true"><u-icon name="plus-circle" color="#4F46E5" size="16" /> 添加成员</text></view>
      <view v-if="form.items.length" class="member-list">
        <view v-for="(m, i) in form.items" :key="i" class="member-item">
          <view class="member-left">
            <text class="member-name">{{ m.worker_name }}</text>
            <text class="member-alloc">分配：{{ m.allocated_score }} 分</text>
          </view>
          <view class="member-right">
            <view class="num-btn small" @click="changeMemberScore(i, -0.5)"><u-icon name="minus" color="#8a9aa8" size="12" /></view>
            <u-input v-model.number="m.allocated_score" type="number" border="none" :customStyle="{ height: '72rpx', fontSize: '28rpx' }" />
            <view class="num-btn small" @click="changeMemberScore(i, 0.5)"><u-icon name="plus" color="#8a9aa8" size="12" /></view>
            <view class="del-btn" @click="removeMember(i)"><u-icon name="trash" color="#e74c5e" size="16" /></view>
          </view>
        </view>
      </view>
      <view v-else class="empty-tip">团队协作请至少添加一名成员</view>
      <view class="alloc-stat">
        已分配：<text class="strong" :class="{ err: balanceErr }">{{ allocatedSum }}</text> 分 / 总工分：<text class="strong">{{ form.total_score }}</text> 分
        <text v-if="balanceErr" class="balance-warn">{{ balanceErr }}</text>
      </view>
    </view>

    <!-- 材料配件使用 -->
    <view class="card">
      <view class="card-title">材料配件使用 <text class="add-link" @click="materialPickerOpen = true"><u-icon name="plus-circle" color="#4F46E5" size="16" /> 添加材料</text></view>
      <view v-if="form.materials.length" class="material-list">
        <view v-for="(mt, i) in form.materials" :key="i" class="material-item">
          <view class="material-left">
            <text class="material-code">{{ mt.material_name }}</text>
            <text class="material-name">{{ mt.specification || '-' }}</text>
          </view>
          <view class="material-right">
            <text class="material-qty">{{ mt.quantity }} {{ mt.unit }}</text>
            <view class="del-btn" @click="removeMaterial(i)"><u-icon name="trash" color="#e74c5e" size="16" /></view>
          </view>
        </view>
      </view>
      <view v-else class="empty-tip">暂无材料配件</view>
    </view>

    <!-- 作业照片 -->
    <view class="card">
      <view class="card-title">作业照片 <text class="add-link" @click="choosePhotos"><u-icon name="camera" color="#4F46E5" size="16" /> 上传照片</text></view>
      <view v-if="form.photos.length" class="photo-grid">
        <view v-for="(u, idx) in form.photos" :key="idx" class="photo-item">
          <image :src="imgUrl(u)" mode="aspectFill" class="photo-img" @click="previewPhoto(idx)" />
          <view class="photo-del" @click="removePhoto(u)"><u-icon name="close" color="#fff" size="12" /></view>
        </view>
      </view>
      <view v-else class="empty-tip">支持 jpg/png/gif/webp，≤5MB，可多张</view>
    </view>

    <!-- 提交 -->
    <view class="btn-row">
      <view class="submit-btn ghost" :class="{ disabled: saving }" @click="handleSave">
        <u-icon name="file-text" color="#4F46E5" size="18" />
        <text>{{ saving ? '保存中...' : '保存草稿' }}</text>
      </view>
      <view class="submit-btn" :class="{ disabled: saving || submitting }" @click="handleSaveAndSubmit">
        <u-icon name="checkmark" color="#fff" size="18" />
        <text>{{ submitting ? '提交中...' : '提交审核' }}</text>
      </view>
    </view>

    <!-- 工单选择弹窗 -->
    <view v-if="orderPickerOpen" class="mask" @click="orderPickerOpen = false">
      <view class="sheet" @click.stop>
        <view class="sheet-head">
          <text class="sheet-title">选择工单</text>
          <view class="sheet-close" @click="orderPickerOpen = false"><u-icon name="close" color="#8a9aa8" size="16" /></view>
        </view>
        <scroll-view scroll-y class="sheet-list">
          <view v-for="o in orderList" :key="o.id" class="sheet-item" :class="{ active: currentOrder && currentOrder.id === o.id }" @click="pickOrder(o)">
            <view class="si-info">
              <text class="si-no">{{ o.order_no }}</text>
              <text class="si-desc">{{ o.product_name }}{{ o.product_spec ? '（' + o.product_spec + '）' : '' }} · 批量 {{ o.plan_quantity }} · 已完工 {{ o.completed_quantity }}</text>
            </view>
            <u-icon v-if="currentOrder && currentOrder.id === o.id" name="checkmark-circle-fill" color="#4F46E5" size="18" />
          </view>
          <view v-if="!orderList.length" class="sheet-empty">暂无待报工工单</view>
        </scroll-view>
      </view>
    </view>

    <!-- 工位选择弹窗 -->
    <view v-if="wsPickerOpen" class="mask" @click="wsPickerOpen = false">
      <view class="sheet" @click.stop>
        <view class="sheet-head">
          <text class="sheet-title">选择工位</text>
          <view class="sheet-close" @click="wsPickerOpen = false"><u-icon name="close" color="#8a9aa8" size="16" /></view>
        </view>
        <scroll-view scroll-y class="sheet-list">
          <view v-for="w in workstationList" :key="w.id" class="sheet-item" :class="{ active: form.workstation_id === w.id }" @click="pickWorkstation(w)">
            <view class="si-info">
              <text class="si-no">{{ w.workstation_name }}</text>
              <text class="si-desc">{{ w.workstation_code }} · 可做 {{ w.process_count || 0 }} 道工序</text>
            </view>
            <u-icon v-if="form.workstation_id === w.id" name="checkmark-circle-fill" color="#4F46E5" size="18" />
          </view>
          <view v-if="!workstationList.length" class="sheet-empty">暂无工位数据</view>
        </scroll-view>
      </view>
    </view>

    <!-- 工序选择弹窗 -->
    <view v-if="processPickerOpen" class="mask" @click="processPickerOpen = false">
      <view class="sheet" @click.stop>
        <view class="sheet-head">
          <text class="sheet-title">选择工序</text>
          <view class="sheet-close" @click="processPickerOpen = false"><u-icon name="close" color="#8a9aa8" size="16" /></view>
        </view>
        <scroll-view scroll-y class="sheet-list">
          <view v-for="(g, gi) in processGroups" :key="gi">
            <text class="sheet-group">{{ g }}</text>
            <view v-for="p in availableProcesses.filter(x => x.process_group === g)" :key="p.process_id" class="sheet-item" :class="{ active: form.process_id === p.process_id }" @click="pickProcess(p)">
              <view class="si-info">
                <text class="si-no">{{ p.process_name }}</text>
                <text class="si-desc">{{ Number(p.standard_score) }} 分</text>
              </view>
              <u-icon v-if="form.process_id === p.process_id" name="checkmark-circle-fill" color="#4F46E5" size="18" />
            </view>
          </view>
          <view v-if="!availableProcesses.length" class="sheet-empty">该工位暂未配置工序</view>
        </scroll-view>
      </view>
    </view>

    <!-- 设备选择弹窗 -->
    <view v-if="devicePickerOpen" class="mask" @click="devicePickerOpen = false">
      <view class="sheet" @click.stop>
        <view class="sheet-head">
          <text class="sheet-title">选择设备</text>
          <view class="sheet-close" @click="devicePickerOpen = false"><u-icon name="close" color="#8a9aa8" size="16" /></view>
        </view>
        <scroll-view scroll-y class="sheet-list">
          <view v-for="d in deviceList" :key="d.id" class="sheet-item" :class="{ active: form.device_id === d.device_id }" @click="pickDevice(d)">
            <view class="si-info">
              <text class="si-no">{{ d.device_name }}</text>
              <text class="si-desc">{{ d.device_code }}{{ d.model ? ' · ' + d.model : '' }}{{ d.is_primary === 1 ? ' · 主设备' : '' }}</text>
            </view>
            <u-icon v-if="form.device_id === d.device_id" name="checkmark-circle-fill" color="#4F46E5" size="18" />
          </view>
          <view v-if="!deviceList.length" class="sheet-empty">该工位未关联设备</view>
        </scroll-view>
      </view>
    </view>

    <!-- 成员选择弹窗 -->
    <view v-if="memberPickerOpen" class="mask" @click="memberPickerOpen = false">
      <view class="sheet" @click.stop>
        <view class="sheet-head">
          <text class="sheet-title">选择成员（可多选）</text>
          <view class="sheet-close" @click="memberPickerOpen = false"><u-icon name="close" color="#8a9aa8" size="16" /></view>
        </view>
        <scroll-view scroll-y class="sheet-list">
          <view v-for="u in userList" :key="u.id" class="sheet-item" :class="{ active: selectedMemberIds.has(u.id) }" @click="toggleMember(u)">
            <view class="si-info">
              <text class="si-no">{{ u.real_name || u.username }}</text>
              <text class="si-desc">{{ u.department_name || '' }}</text>
            </view>
            <u-icon v-if="selectedMemberIds.has(u.id)" name="checkmark-circle-fill" color="#4F46E5" size="18" />
          </view>
          <view v-if="!userList.length" class="sheet-empty">暂无成员</view>
        </scroll-view>
        <view class="sheet-foot">
          <view class="foot-btn" @click="memberPickerOpen = false">取消</view>
          <view class="foot-btn primary" @click="confirmAddMembers">添加</view>
        </view>
      </view>
    </view>

    <!-- 材料选择弹窗 -->
    <view v-if="materialPickerOpen" class="mask" @click="materialPickerOpen = false">
      <view class="sheet" @click.stop>
        <view class="sheet-head">
          <text class="sheet-title">选择材料（我的资产配件）</text>
          <view class="sheet-close" @click="materialPickerOpen = false"><u-icon name="close" color="#8a9aa8" size="16" /></view>
        </view>
        <view class="sheet-search">
          <u-icon name="search" color="#b0c0cc" size="15" />
          <u-input v-model="materialKeyword" placeholder="搜索配件名称/编码" prefixIcon="search" border="none" confirm-type="search" :customStyle="{ height: '72rpx', fontSize: '26rpx' }" @confirm="materialKeyword = $event.detail.value" />
          <u-icon v-if="materialKeyword" name="close-circle-fill" color="#c0cedc" size="15" @click="materialKeyword = ''" />
        </view>
        <scroll-view scroll-y class="sheet-list">
          <view v-for="m in filteredMaterialList" :key="m.id" class="sheet-item" :class="{ active: pendingMaterial && pendingMaterial.id === m.id }" @click="selectMaterial(m)">
            <view class="si-info">
              <text class="si-no">{{ m.asset_name }}（{{ m.specification || '-' }}）</text>
              <text class="si-desc">可用：{{ m.quantity }} {{ m.unit }}{{ m.location ? ' · ' + (m.location || '') : '' }}</text>
            </view>
            <u-icon v-if="pendingMaterial && pendingMaterial.id === m.id" name="checkmark-circle-fill" color="#4F46E5" size="18" />
          </view>
          <view v-if="!filteredMaterialList.length" class="sheet-empty">{{ materialKeyword ? '未找到匹配配件' : '您名下暂无配件，请先领用' }}</view>
        </scroll-view>
        <view v-if="pendingMaterial" class="material-qty-bar">
          <text class="mqlabel">{{ pendingMaterial.asset_name }} 使用数量（最大 {{ pendingMaterial.quantity }}）：</text>
          <view class="num-row inline">
            <view class="num-btn small" @click="changeMaterialQty(-0.5)"><u-icon name="minus" color="#8a9aa8" size="12" /></view>
            <u-input v-model.number="materialQty" type="number" border="none" :customStyle="{ height: '72rpx', fontSize: '28rpx' }" />
            <view class="num-btn small" @click="changeMaterialQty(0.5)"><u-icon name="plus" color="#8a9aa8" size="12" /></view>
          </view>
        </view>
        <view class="sheet-foot">
          <view class="foot-btn" @click="materialPickerOpen = false">取消</view>
          <view class="foot-btn primary" @click="confirmAddMaterial">添加</view>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { onLoad } from '@dcloudio/uni-app'

// ===== 基础数据 =====
const taskOptions = { 1: '拆解', 2: '焊接', 3: '维修', 4: '组装', 5: '喷漆', 6: '质检', 7: '其他' }

const reportType = ref(1)
const orderList = ref([])
const currentOrder = ref(null)
const workstationList = ref([])
const availableProcesses = ref([])
const deviceList = ref([])
const userList = ref([])
const materialList = ref([])

const form = ref({
  work_order_id: null, work_order_no: '',
  workstation_id: 0, workstation_name: '',
  process_id: 0, process_name: '',
  device_id: 0, device_name: '', device_code: '',
  task_type: 1, task_description: '',
  quantity: 1, duration: 1.0,
  total_score: 0, calculated_score: 0,
  report_date: today(), remark: '',
  items: [], materials: [], photos: []
})

// 弹窗状态
const orderPickerOpen = ref(false)
const wsPickerOpen = ref(false)
const processPickerOpen = ref(false)
const devicePickerOpen = ref(false)
const memberPickerOpen = ref(false)
const materialPickerOpen = ref(false)
const selectedMemberIds = ref(new Set())
const pendingMaterial = ref(null)
const materialQty = ref(1)
const materialKeyword = ref('')
const saving = ref(false)
const submitting = ref(false)

// ===== 计算属性 =====
const processGroups = computed(() => {
  const seen = []
  availableProcesses.value.forEach(p => { if (p.process_group && !seen.includes(p.process_group)) seen.push(p.process_group) })
  return seen
})
const scoreFormula = computed(() => {
  const p = availableProcesses.value.find(x => x.process_id === form.value.process_id)
  if (!p) return ''
  return `${Number(p.standard_score)} 分 × ${Number(form.value.quantity || 1)} 件 = ${form.value.calculated_score} 分`
})
const allocatedSum = computed(() => form.value.items.reduce((s, i) => s + Number(i.allocated_score || 0), 0))
const filteredMaterialList = computed(() => {
  const kw = materialKeyword.value.trim().toLowerCase()
  if (!kw) return materialList.value
  return materialList.value.filter(m =>
    (m.asset_name || '').toLowerCase().includes(kw) ||
    (m.asset_code || '').toLowerCase().includes(kw) ||
    (m.specification || '').toLowerCase().includes(kw)
  )
})
const balanceErr = computed(() => {
  if (reportType.value !== 2) return ''
  const sum = allocatedSum.value
  if (Math.abs(sum - Number(form.value.total_score)) > 0.001) return `分配工分合计（${sum}）与总工分（${form.value.total_score}）不一致`
  return ''
})

// ===== 工具 =====
function today() {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
}
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

// ===== 数据加载 =====
let presetOrderId = 0
let reportId = 0
onLoad((options) => {
  presetOrderId = Number(options?.order_id || 0)
  reportId = Number(options?.report_id || 0)
  if (reportId) loadReport()
})

/** 编辑模式：加载草稿/已驳回报工详情并回填表单 */
async function loadReport() {
  try {
    const d = await api('/api/production/report/detail/' + reportId)
    if (!d) return
    reportType.value = Number(d.report_type) || 1
    form.value = {
      work_order_id: d.work_order_id || 0,
      work_order_no: d.work_order_no || '',
      workstation_id: d.workstation_id || 0,
      workstation_name: d.workstation_name || '',
      process_id: d.process_id || 0,
      process_name: d.process_name || '',
      device_id: d.device_id || 0,
      device_name: d.device_name || '',
      device_code: d.device_code || '',
      task_type: Number(d.task_type) || 1,
      task_description: d.task_description || '',
      quantity: Number(d.quantity) || 1,
      duration: Number(d.duration) || 1,
      total_score: Number(d.total_score) || 0,
      calculated_score: Number(d.calculated_score) || 0,
      report_date: d.report_date || today(),
      remark: d.remark || '',
      items: (d.items || []).map(i => ({ worker_id: i.worker_id, worker_name: i.worker_name, allocated_score: Number(i.allocated_score) || 0 })),
      materials: (d.materials || []).map(m => ({ personal_asset_id: m.personal_asset_id || 0, material_id: m.material_id, material_code: m.material_code, material_name: m.material_name, specification: m.specification || '', unit: m.unit || '', quantity: m.quantity })),
      photos: d.photos || []
    }
    // 联动加载该工位的工序与设备
    if (form.value.workstation_id) {
      const [rp, rd] = await Promise.all([
        api('/api/production/workstation/available-processes/' + form.value.workstation_id).catch(() => null),
        api('/api/production/workstation/devices/' + form.value.workstation_id).catch(() => null)
      ])
      if (rp) availableProcesses.value = (rp.list) || []
      if (rd) deviceList.value = (rd.list) || []
    }
    // 工单列表加载并选中
    presetOrderId = form.value.work_order_id
    loadOrders()
  } catch (e) {}
}

async function loadOrders() {
  try {
    const r = await api('/api/production/order/available-for-report')
    orderList.value = (r && r.list) || []
    if (orderList.value.length) {
      // 优先选中 URL 传入的工单（详情页"去报工"带入）
      const preset = presetOrderId ? orderList.value.find(o => o.id === presetOrderId) : null
      currentOrder.value = preset || currentOrder.value || orderList.value[0]
      if (currentOrder.value) {
        form.value.work_order_id = currentOrder.value.id
        form.value.work_order_no = currentOrder.value.order_no
      }
    }
  } catch (e) {}
}
async function loadWorkstations() {
  try {
    const r = await api('/api/production/workstation/list?page=1&pageSize=200&status=1')
    workstationList.value = (r && r.list) || []
  } catch (e) { workstationList.value = [] }
}
async function loadUsers() {
  try {
    const r = await api('/api/production/order/users')
    userList.value = (r && r.list) || []
  } catch (e) { userList.value = [] }
}
async function loadMaterials() {
  try {
    const r = await api('/api/personal-assets/my-materials', 'GET', { limit: 50 })
    materialList.value = (r && r.list) || []
  } catch (e) { materialList.value = [] }
}

// ===== 弹窗开关 =====
function openOrderPicker() { if (orderList.value.length) orderPickerOpen.value = true }
function pickOrder(o) {
  currentOrder.value = o
  form.value.work_order_id = o.id
  form.value.work_order_no = o.order_no
  orderPickerOpen.value = false
}

function openWorkstationPicker() { if (workstationList.value.length) wsPickerOpen.value = true }
async function pickWorkstation(w) {
  form.value.workstation_id = w.id
  form.value.workstation_name = w.workstation_name
  form.value.process_id = 0
  form.value.process_name = ''
  form.value.device_id = 0
  form.value.device_name = ''
  form.value.device_code = ''
  availableProcesses.value = []
  deviceList.value = []
  wsPickerOpen.value = false
  // 联动加载工序 + 设备
  try {
    const [rp, rd] = await Promise.all([
      api('/api/production/workstation/available-processes/' + w.id).catch(() => null),
      api('/api/production/workstation/devices/' + w.id).catch(() => null)
    ])
    if (rp) availableProcesses.value = (rp.list) || []
    if (rd) deviceList.value = (rd.list) || []
    if (availableProcesses.value.length === 1) {
      const p = availableProcesses.value[0]
      form.value.process_id = p.process_id
      form.value.process_name = p.process_name
      recalcScore()
    } else if (availableProcesses.value.length > 1) {
      processPickerOpen.value = true
    }
  } catch (e) {}
}

function openProcessPicker() { if (form.value.workstation_id && availableProcesses.value.length) processPickerOpen.value = true }
function pickProcess(p) {
  form.value.process_id = p.process_id
  form.value.process_name = p.process_name
  recalcScore()
  processPickerOpen.value = false
}

function openDevicePicker() { if (form.value.workstation_id && deviceList.value.length) devicePickerOpen.value = true }
function pickDevice(d) {
  form.value.device_id = d.device_id || d.id
  form.value.device_name = d.device_name
  form.value.device_code = d.device_code
  devicePickerOpen.value = false
}

// ===== 数量 / 时长 / 工分 =====
function changeQty(d) { form.value.quantity = Math.max(0, (Number(form.value.quantity) || 0) + d); recalcScore() }
function onQuantityChange() { recalcScore() }
function changeDuration(d) { form.value.duration = Math.max(0, (Number(form.value.duration) || 0) + d) }
function recalcScore() {
  const p = availableProcesses.value.find(x => x.process_id === form.value.process_id)
  const score = p ? Number(p.standard_score) : 0
  form.value.calculated_score = Number((score * Number(form.value.quantity || 1)).toFixed(2))
  form.value.total_score = form.value.calculated_score
}

// ===== 团队分配 =====
function toggleMember(u) {
  const ids = selectedMemberIds.value
  if (ids.has(u.id)) ids.delete(u.id)
  else ids.add(u.id)
}
function confirmAddMembers() {
  if (!selectedMemberIds.value.size) { uni.showToast({ title: '请选择成员', icon: 'none' }); return }
  const existing = form.value.items.map(i => i.worker_id)
  let added = false
  userList.value.forEach(u => {
    if (!selectedMemberIds.value.has(u.id) || existing.includes(u.id)) return
    form.value.items.push({ worker_id: u.id, worker_name: u.real_name || u.username, allocated_score: 0 })
    added = true
  })
  if (!added) uni.showToast({ title: '所选成员已在列表中', icon: 'none' })
  selectedMemberIds.value = new Set()
  memberPickerOpen.value = false
}
function changeMemberScore(i, d) {
  form.value.items[i].allocated_score = Math.max(0, Number((Number(form.value.items[i].allocated_score) || 0) + d).toFixed(2))
}
function removeMember(i) { form.value.items.splice(i, 1) }

// ===== 材料 =====
function selectMaterial(m) { pendingMaterial.value = m; materialQty.value = 1 }
function changeMaterialQty(d) { materialQty.value = Math.max(0, Number((Number(materialQty.value) || 0) + d).toFixed(4)) }
function confirmAddMaterial() {
  if (!pendingMaterial.value) { uni.showToast({ title: '请选择配件', icon: 'none' }); return }
  if (!materialQty.value || materialQty.value <= 0) { uni.showToast({ title: '请输入使用数量', icon: 'none' }); return }
  if (materialQty.value > (pendingMaterial.value.quantity || 0)) { uni.showToast({ title: '使用数量不能超过可用数量（' + pendingMaterial.value.quantity + '）', icon: 'none' }); return }
  const m = pendingMaterial.value
  form.value.materials.push({
    personal_asset_id: m.id,
    material_id: m.id,
    material_code: m.asset_code || '',
    material_name: m.asset_name,
    specification: m.specification || '',
    unit: m.unit || '',
    quantity: materialQty.value
  })
  pendingMaterial.value = null
  materialQty.value = 1
  materialPickerOpen.value = false
}
function removeMaterial(i) { form.value.materials.splice(i, 1) }

// ===== 照片 =====
function choosePhotos() {
  uni.chooseImage({
    count: 6,
    sizeType: ['compressed'],
    success: (res) => {
      const files = res.tempFilePaths || []
      files.forEach(f => uploadPhoto(f))
    }
  })
}
function uploadPhoto(filePath) {
  uni.uploadFile({
    url: uni.$base + '/api/production/report/upload',
    filePath,
    name: 'file',
    header: { 'Authorization': 'Bearer ' + getToken() },
    success: (r) => {
      try {
        const rd = JSON.parse(r.data || '{}')
        if (rd.code === 0 && rd.data?.url) form.value.photos.push(rd.data.url)
        else uni.showToast({ title: rd.msg || '上传失败', icon: 'none' })
      } catch (e) { uni.showToast({ title: '上传失败', icon: 'none' }) }
    },
    fail: () => uni.showToast({ title: '上传失败', icon: 'none' })
  })
}
function removePhoto(url) { form.value.photos = form.value.photos.filter(u => u !== url) }
function previewPhoto(idx) {
  uni.previewImage({ urls: form.value.photos.map(imgUrl), current: idx })
}

// ===== 保存 =====
function validate() {
  const f = form.value
  if (!f.work_order_id) { uni.showToast({ title: '请选择关联工单', icon: 'none' }); return false }
  if (!f.workstation_id) { uni.showToast({ title: '请选择关联工位', icon: 'none' }); return false }
  if (!f.device_id) { uni.showToast({ title: '请选择关联设备', icon: 'none' }); return false }
  if (!f.process_id) { uni.showToast({ title: '请选择关联工序', icon: 'none' }); return false }
  if (!f.task_description) { uni.showToast({ title: '请填写任务描述', icon: 'none' }); return false }
  if (!f.quantity || f.quantity <= 0) { uni.showToast({ title: '完成数量必须大于0', icon: 'none' }); return false }
  if (!f.duration || f.duration <= 0) { uni.showToast({ title: '设备使用时长必须大于0', icon: 'none' }); return false }
  if (!f.total_score || f.total_score <= 0) { uni.showToast({ title: '请输入总工分', icon: 'none' }); return false }
  if (reportType.value === 2) {
    if (!f.items.length) { uni.showToast({ title: '团队协作请至少添加一名成员', icon: 'none' }); return false }
    if (balanceErr.value) { uni.showToast({ title: balanceErr.value, icon: 'none' }); return false }
  }
  return true
}

function buildData() {
  const f = form.value
  const data = {
    report_type: reportType.value,
    work_order_id: f.work_order_id,
    task_type: f.task_type,
    task_description: f.task_description,
    report_date: f.report_date,
    total_score: Number(f.total_score) || 0,
    remark: f.remark,
    process_id: f.process_id,
    process_name: f.process_name,
    workstation_id: f.workstation_id,
    workstation_name: f.workstation_name,
    device_id: f.device_id,
    device_name: f.device_name,
    device_code: f.device_code,
    quantity: Number(f.quantity) || 0,
    duration: Number(f.duration) || 0,
    calculated_score: Number(f.calculated_score) || 0,
    photos: f.photos,
    materials: f.materials.map(m => ({ personal_asset_id: m.personal_asset_id || 0, material_id: m.material_id, material_code: m.material_code, material_name: m.material_name, specification: m.specification, unit: m.unit, quantity: m.quantity })),
    items: reportType.value === 2 ? f.items.map(i => ({ worker_id: i.worker_id, worker_name: i.worker_name, allocated_score: Number(i.allocated_score) || 0 })) : []
  }
  // 编辑模式：带 id 更新草稿
  if (reportId) data.id = reportId
  return data
}

/** 保存报工（草稿）。confirm=true 时先弹确认框 */
function saveReport(confirm = false) {
  if (saving.value) return Promise.resolve(null)
  if (!validate()) return Promise.resolve(null)
  const data = buildData()
  const doSave = async () => {
    saving.value = true
    try {
      return await api('/api/production/report/save', 'POST', data)
    } catch (e) {
      uni.showToast({ title: e.msg || '保存失败', icon: 'none' })
      return null
    } finally {
      saving.value = false
    }
  }
  if (!confirm) return doSave()
  return new Promise((resolve) => {
    uni.showModal({
      title: '确认提交报工',
      content: `工单：${currentOrder.value.order_no}\n模式：${reportType.value === 1 ? '个人报工' : '团队协作'}\n完成数量：${data.quantity} 件\n总工分：${data.total_score} 分`,
      success: async (r) => {
        resolve(r.confirm ? await doSave() : null)
      }
    })
  })
}

/** 保存草稿 */
async function handleSave() {
  const r = await saveReport(false)
  if (r && r.id) uni.showToast({ title: '报工已保存为草稿', icon: 'success' })
}

/** 保存并提交审核 */
async function handleSaveAndSubmit() {
  if (submitting.value) return
  const r = await saveReport(true)
  if (!r || !r.id) return
  submitting.value = true
  try {
    await api('/api/production/report/submit/' + r.id, 'POST')
    uni.showToast({ title: '已提交审核！', icon: 'success' })
    setTimeout(() => uni.navigateBack({ fail: () => uni.reLaunch({ url: '/pages/diy/index?type=home' }) }), 1200)
  } catch (e) {
    uni.showToast({ title: e.msg || '提交审核失败', icon: 'none' })
  }
  submitting.value = false
}

onMounted(() => {
  loadOrders()
  loadWorkstations()
  loadUsers()
  loadMaterials()
})
</script>

<style scoped>
.report-page { min-height: 100vh; background: #F4F6FB; padding: 16px 16px 40px; box-sizing: border-box; }
.card { background: #fff; border-radius:122px; padding: 16px; margin-bottom: 12px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.card-title { font-size: 14px; font-weight: 700; color: #1a2332; margin-bottom: 12px; display: flex; align-items: center; justify-content: space-between; }
.req { color: #e74c5e; }
.add-link { display: flex; align-items: center; gap: 4px; font-size: 13px; color: #4F46E5; font-weight: 500; }
.mode-row { display: flex; gap: 10px; }
.mode-item { flex: 1; display: flex; flex-direction: column; align-items: center; gap: 6px; background: #f8fafc; border-radius:124px; padding: 16px; border: 2px solid transparent; }
.mode-item.active { border-color: #4F46E5; background: #f0f4ff; }
.mode-name { font-size: 13px; color: #8a9aa8; }
.mode-name.active { color: #1a2332; font-weight: 600; }
.pick-row { display: flex; align-items: center; justify-content: space-between; background: #f8fafc; border-radius:24px; padding: 12px 14px; margin-bottom: 8px; }
.pick-row.inner { margin-bottom: 0; }
.pick-row.disabled { opacity: 0.5; }
.pick-left { display: flex; align-items: center; gap: 10px; flex: 1; min-width: 0; }
.pick-text { font-size: 14px; color: #1a2332; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.pick-text.placeholder { color: #b0c0cc; }
.order-meta { display: flex; flex-direction: column; gap: 4px; font-size: 12px; color: #8a9aa8; padding: 4px 4px 0; }
.warn-tip { font-size: 12px; color: #e6a23c; padding: 2px 4px 6px; }
.field { margin-bottom: 14px; }
.field:last-child { margin-bottom: 0; }
.field-row { display: flex; gap: 10px; }
.field.half { flex: 1; }
.field-label { display: block; font-size: 13px; color: #1a2332; margin-bottom: 8px; }
.input-area { width: 100%; height: 76px; background: #f8fafc; border-radius:24px; padding: 12px 14px; font-size: 14px; color: #1a2332; box-sizing: border-box; }
.num-row { display: flex; align-items: center; gap: 8px; background: #f8fafc; border-radius:24px; padding: 6px 10px; }
.num-row.inline { padding: 0; background: transparent; }
.num-btn { width: 30px; height: 30px; border-radius:50%; background: #fff;
  box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
  display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.num-btn.small { width: 26px; height: 26px; }
.num-input { flex: 1; text-align: center; font-size: 16px; font-weight: 700; color: #1a2332; }
.score-row { display: flex; align-items: center; gap: 10px; }
.score-input { flex: 0 0 120px; background: #f8fafc; border-radius:24px; padding: 12px 14px; font-size: 15px; font-weight: 600; }
.score-tip { flex: 1; font-size: 12px; color: #909399; }
.task-tags { display: flex; flex-wrap: wrap; gap: 8px; }
.task-tag { font-size: 12px; color: #606266; background: #F4F6FB; border: 1px solid #e4e7ed; border-radius:24px; padding: 6px 12px; }
.task-tag.active { color: #4F46E5; background: #f0f4ff; border-color: #4F46E5; }
.member-list, .material-list { display: flex; flex-direction: column; gap: 8px; margin-bottom: 10px; }
.member-item, .material-item { display: flex; align-items: center; justify-content: space-between; background: #f8fafc; border-radius:24px; padding: 12px 14px; }
.member-left, .material-left { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.member-name { font-size: 14px; font-weight: 600; color: #1a2332; }
.member-alloc { font-size: 12px; color: #8a9aa8; margin-top: 2px; }
.member-right { display: flex; align-items: center; gap: 6px; }
.member-input { width: 64px; text-align: center; font-size: 14px; font-weight: 600; background: #fff;
  box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
  border-radius:24px; padding: 6px 4px; }
.del-btn { width: 28px; height: 28px; border-radius:50%; background: #fdecea; display: flex; align-items: center; justify-content: center; }
.alloc-stat { font-size: 13px; color: #606266; }
.strong { font-weight: 700; color: #1a2332; }
.strong.err { color: #e74c5e; }
.balance-warn { color: #e74c5e; margin-left: 6px; }
.material-code { font-size: 13px; font-weight: 600; color: #1a2332; }
.material-name { font-size: 12px; color: #8a9aa8; margin-top: 2px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.material-right { display: flex; align-items: center; gap: 10px; }
.material-qty { font-size: 13px; color: #4F46E5; font-weight: 600; }
.empty-tip { font-size: 12px; color: #b0c0cc; padding: 10px 0; }
.photo-grid { display: flex; flex-wrap: wrap; gap: 10px; }
.photo-item { position: relative; width: 80px; height: 80px; }
.photo-img { width: 100%; height: 100%; border-radius:24px; }
.photo-del { position: absolute; top: -6px; right: -6px; width: 20px; height: 20px; border-radius:50%; background: rgba(0,0,0,0.55); display: flex; align-items: center; justify-content: center; }
.btn-row { display: flex; gap: 10px; margin-top: 8px; }
.submit-btn { display: flex; align-items: center; justify-content: center; gap: 6px; background: linear-gradient(135deg, #4F46E5, #7C6FF0); color: #fff; font-size: 16px; font-weight: 700; padding: 16px; border-radius:122px; box-shadow: 0 4px 16px rgba(110,142,251,0.2); flex: 1; }
.submit-btn.ghost { background: #fff; color: #4F46E5; border: 1px solid #4F46E5; box-shadow: none; }
.submit-btn:active { transform: scale(0.97); }
.submit-btn.disabled { opacity: 0.6; }
.mask { position: fixed; inset: 0; background: rgba(0,0,0,0.3); z-index: 100; display: flex; align-items: flex-end; }
.sheet { width: 100%; background: #fff; border-radius:224px 224px 0 0; padding: 20px 20px 30px; max-height: 72vh; display: flex; flex-direction: column;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.sheet-head { display: flex; align-items: center; justify-content: space-between; padding-bottom: 12px; }
.sheet-title { font-size: 17px; font-weight: 700; color: #1a2332; }
.sheet-close { width: 28px; height: 28px; border-radius:50%; background: #EDF0F8; display: flex; align-items: center; justify-content: center; }
.sheet-search { display: flex; align-items: center; gap: 8px; background: #F4F6FB; border-radius:22px; padding: 8px 12px; margin: 4px 4px 10px; }
.sheet-search-input { flex: 1; font-size: 14px; color: #1a2332; }
.sheet-list { flex: 1; max-height: 50vh; }
.sheet-group { display: block; font-size: 12px; color: #8a9aa8; padding: 10px 16px 4px; }
.sheet-item { display: flex; align-items: center; justify-content: space-between; padding: 13px 16px; border-radius:124px; margin-bottom: 4px; }
.sheet-item:active { background: #f0f4ff; }
.sheet-item.active { background: #f0f4ff; border: 1px solid #4F46E5; }
.si-info { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.si-no { font-size: 14px; font-weight: 600; color: #1a2332; }
.si-desc { font-size: 12px; color: #8a9aa8; margin-top: 2px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.sheet-empty { text-align: center; color: #b0c0cc; font-size: 13px; padding: 40px 0; }
.sheet-foot { display: flex; gap: 10px; margin-top: 12px; }
.foot-btn { flex: 1; text-align: center; padding: 12px; border-radius:24px; background: #EDF0F8; color: #606266; font-size: 15px; }
.foot-btn.primary { background: linear-gradient(135deg, #4F46E5, #7C6FF0); color: #fff; font-weight: 600; }
.material-qty-bar { display: flex; align-items: center; gap: 10px; padding: 12px 4px 0; }
.mqlabel { font-size: 13px; color: #1a2332; flex: 1; }
</style>
