<template>
  <view class="qd-page">
    <!-- 步骤指示 -->
    <view class="qd-steps">
      <view class="qd-step" :class="{ active: step >= 1 }"><text class="qd-step-num">1</text><text class="qd-step-label">选择员工</text></view>
      <view class="qd-step-line" :class="{ active: step >= 2 }"></view>
      <view class="qd-step" :class="{ active: step >= 2 }"><text class="qd-step-num">2</text><text class="qd-step-label">选择指标</text></view>
      <view class="qd-step-line" :class="{ active: step >= 3 }"></view>
      <view class="qd-step" :class="{ active: step >= 3 }"><text class="qd-step-num">3</text><text class="qd-step-label">确认提交</text></view>
    </view>

    <!-- ===== 第一步：选人 ===== -->
    <template v-if="step === 1">
      <view class="qd-search-bar">
        <view class="qd-search">
          <u-input v-model="keyword" placeholder="搜索员工姓名" border="none" :customStyle="{ height: '60rpx', fontSize: '26rpx' }" @confirm="searchEmployees" />
        </view>
        <view class="qd-scan" @click="scanCode"><u-icon name="scan" color="#fff" size="18" /></view>
      </view>

      <!-- 最近考核 -->
      <view v-if="recent.length" class="qd-section">
        <view class="qd-section-title"><text>最近考核</text></view>
        <scroll-view scroll-x class="qd-recent">
          <view class="qd-recent-item" v-for="r in recent" :key="r.employee_id" @click="selectEmployee(r.employee_id)">
            <view class="qd-recent-avatar"><text>{{ r.employee_name.substring(0, 1) }}</text></view>
            <text class="qd-recent-name">{{ r.employee_name }}</text>
          </view>
        </scroll-view>
      </view>

      <!-- 团队列表 -->
      <view class="qd-section">
        <view class="qd-section-title"><text>我的团队（{{ employees.length }} 人）</text></view>
        <view v-if="loading" class="qd-status"><text>加载中...</text></view>
        <u-empty v-else-if="!employees.length" text="暂无团队成员" mode="list" />
        <view v-else class="qd-employee-list">
          <view v-for="e in employees" :key="e.employee_id" class="qd-employee" :class="{ checked: selectedEmpId === e.employee_id }" @click="selectEmployee(e.employee_id)">
            <view class="qd-employee-check"><u-icon v-if="selectedEmpId === e.employee_id" name="checkmark-circle-fill" color="#1e6fff" size="18" /><text v-else class="qd-employee-check-empty"></text></view>
            <view class="qd-employee-info">
              <text class="qd-employee-name">{{ e.employee_name }} <text class="qd-employee-dept">{{ e.department_name }}</text></text>
              <text class="qd-employee-meta">本月得分 {{ e.total_score || '—' }} · 已扣 {{ e.deduction_count }} 次<text v-if="e.pending_count" class="qd-pending"> · {{ e.pending_count }}待确认</text></text>
            </view>
          </view>
        </view>
      </view>
      <view class="qd-foot-wrap">
        <u-button type="primary" :text="'下一步：选择扣分指标'" :disabled="!selectedEmpId" shape="circle" @click="nextStep" />
      </view>
    </template>

    <!-- ===== 第二步：选指标 ===== -->
    <template v-else-if="step === 2">
      <view class="qd-target-bar">
        <text class="qd-target-text">被考核人：<text class="qd-target-name">{{ selectedEmpName }}</text>（{{ selectedEmpDept }}）</text>
        <text class="qd-target-switch" @click="step = 1">切换</text>
      </view>

      <!-- 大类筛选 -->
      <scroll-view scroll-x class="qd-cats">
        <view class="qd-cat" :class="{ active: catFilter === '' }" @click="catFilter = ''">全部</view>
        <view v-for="c in catNames" :key="c" class="qd-cat" :class="{ active: catFilter === c }" @click="catFilter = c">{{ c }}</view>
      </scroll-view>

      <!-- 常用指标 -->
      <view v-if="frequent.length" class="qd-section">
        <view class="qd-section-title"><text>常用指标（最近使用）</text></view>
        <view v-for="f in frequent" :key="f.id" class="qd-ind" @click="selectIndicator(f)">
          <view class="qd-ind-left">
            <text class="qd-ind-name"><MIcon name="file" :size="14" color="#8a9aa8" /><text style="margin-left:4px">{{ f.name }}</text></text>
            <text class="qd-ind-meta">{{ f.category }} · {{ f.score }} 分 · 已扣 {{ f.used_count }} 次</text>
          </view>
          <view class="qd-ind-add" @click.stop="selectIndicator(f)"><text>+</text></view>
        </view>
      </view>

      <!-- 全部指标 -->
      <view class="qd-section">
        <view class="qd-section-title"><text>全部指标</text></view>
        <view v-if="indLoading" class="qd-status"><text>加载中...</text></view>
        <u-empty v-else-if="!filteredCategories.length" text="暂无可用指标" mode="list" />
        <view v-else>
          <view v-for="cat in filteredCategories" :key="cat.name" class="qd-cat-group">
            <view class="qd-cat-group-title"><text>{{ cat.name }}（{{ cat.total_score }} 分）</text></view>
            <view v-for="ind in cat.indicators" :key="ind.id" class="qd-ind" @click="selectIndicator(ind)">
              <view class="qd-ind-left">
                <text class="qd-ind-name"><MIcon name="file" :size="14" color="#8a9aa8" /><text style="margin-left:4px">{{ ind.name }}</text></text>
                <text class="qd-ind-meta">{{ ind.score }} 分<text v-if="ind.used_count"> · 已扣 {{ ind.used_count }} 次</text></text>
              </view>
              <view class="qd-ind-add"><text>+</text></view>
            </view>
          </view>
        </view>
      </view>
      <view class="qd-foot-wrap">
        <u-button type="primary" :text="'下一步：确认提交'" :disabled="!selectedIndId" shape="circle" @click="nextStep" />
      </view>
    </template>

    <!-- ===== 第三步：确认提交 ===== -->
    <template v-else>
      <view class="qd-confirm-card">
        <view class="qd-confirm-row"><text class="qd-confirm-label">被考核人</text><text class="qd-confirm-value">{{ selectedEmpName }}（{{ selectedEmpDept }}）</text></view>
        <view class="qd-confirm-row"><text class="qd-confirm-label">考核指标</text><text class="qd-confirm-value">{{ selectedIndName }}（分值 {{ selectedIndScore }} 分）</text></view>
        <view class="qd-confirm-row">
          <text class="qd-confirm-label">本次扣分</text>
          <view class="qd-score-stepper">
            <view class="qd-score-btn" @click="changeScore(-1)"><text>−</text></view>
            <text class="qd-score-num">{{ deductScore }}</text>
            <view class="qd-score-btn" @click="changeScore(1)"><text>+</text></view>
          </view>
        </view>
      </view>

      <view class="qd-section">
        <view class="qd-section-title"><text>扣分原因 *</text></view>
        <u-textarea v-model="reason" placeholder="请填写扣分原因" maxlength="200" :count="true" />
        <view class="qd-quick-phrases">
          <text v-for="p in quickPhrases" :key="p" class="qd-phrase" @click="reason = p">{{ p }}</text>
        </view>
      </view>

      <view class="qd-section">
        <view class="qd-section-title"><text>现场证据（选填）</text></view>
        <view class="qd-photos">
          <view v-for="(p, i) in photos" :key="i" class="qd-photo">
            <image :src="p" mode="aspectFill" class="qd-photo-img" @click="previewPhoto(i)" />
            <view class="qd-photo-del" @click="photos.splice(i, 1)"><text>×</text></view>
          </view>
          <view v-if="photos.length < 3" class="qd-photo-add" @click="choosePhoto"><MIcon name="camera" :size="18" color="#4F46E5" /><text class="qd-photo-add-text">拍照</text></view>
        </view>
        <text class="qd-tip">支持拍照，最多 3 张（本版照片为本地路径预览）</text>
      </view>

      <view class="qd-section">
        <view class="qd-confirm-row">
          <text class="qd-confirm-label">通知员工</text>
          <u-switch v-model="notify" :active-value="1" :inactive-value="0" size="18" />
        </view>
      </view>

      <view class="qd-submit-bar">
        <u-button text="暂存" shape="circle" @click="saveDraft" />
        <u-button type="error" text="确 认 扣 分" shape="circle" @click="doSubmit" />
      </view>
      <view v-if="draftCount" class="qd-draft-tip" @click="showDrafts"><MIcon name="download" :size="14" color="#f59e0b" /><text style="margin-left:4px">有 {{ draftCount }} 条暂存记录，点击查看</text></view>
    </template>
  </view>
</template>

<script setup>
import { ref, computed } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { getManageableEmployees, getAvailableIndicators, quickDeduct } from '@/api/assessment.js'

const step = ref(1)
const keyword = ref('')
const employees = ref([])
const recent = ref([])
const loading = ref(false)
const selectedEmpId = ref(0)
const selectedEmpName = ref('')
const selectedEmpDept = ref('')

const categories = ref([])
const frequent = ref([])
const indLoading = ref(false)
const catFilter = ref('')
const selectedIndId = ref(0)
const selectedIndName = ref('')
const selectedIndScore = ref(0)

const deductScore = ref(1)
const reason = ref('')
const photos = ref([])
const notify = ref(1)
const draftCount = ref(0)

const quickPhrases = ['未按规定佩戴防护用品', '上班迟到', '产品不合格', '未按操作规程作业', '工作场所卫生不达标']

const catNames = computed(() => categories.value.map(c => c.name))
const filteredCategories = computed(() => catFilter.value ? categories.value.filter(c => c.name === catFilter.value) : categories.value)

onLoad(async (options) => {
  if (options && options.employee_id && parseInt(options.employee_id) > 0) {
    selectedEmpId.value = parseInt(options.employee_id)
  }
  loadDraftCount()
  await loadEmployees()
  if (selectedEmpId.value) {
    const e = employees.value.find(x => x.employee_id === selectedEmpId.value)
    if (e) { selectedEmpName.value = e.employee_name; selectedEmpDept.value = e.department_name }
    step.value = 2
  }
})

async function loadEmployees () {
  loading.value = true
  try {
    const r = await getManageableEmployees({ keyword: keyword.value, sort: 'score_desc' })
    if (r.code === 0 && r.data) {
      employees.value = r.data.list || []
      recent.value = r.data.recent || []
    }
  } catch (e) {} finally { loading.value = false }
}

function searchEmployees () { loadEmployees() }

function scanCode () {
  uni.scanCode({
    success: (res) => {
      const result = (res.result || '').trim()
      // 扫码结果作为关键词搜索（工牌码可能含姓名/工号）
      keyword.value = result
      loadEmployees()
    },
    fail: () => uni.showToast({ title: '取消扫码', icon: 'none' })
  })
}

function selectEmployee (id) {
  selectedEmpId.value = id
  const e = employees.value.find(x => x.employee_id === id)
  if (e) { selectedEmpName.value = e.employee_name; selectedEmpDept.value = e.department_name }
}

function nextStep () {
  if (step.value === 1 && !selectedEmpId.value) { uni.showToast({ title: '请先选择员工', icon: 'none' }); return }
  if (step.value === 2 && !selectedIndId.value) { uni.showToast({ title: '请选择考核指标', icon: 'none' }); return }
  if (step.value === 2) loadIndicators()
  step.value++
}

async function loadIndicators () {
  indLoading.value = true
  try {
    const r = await getAvailableIndicators({ employee_id: selectedEmpId.value })
    if (r.code === 0 && r.data) {
      categories.value = r.data.categories || []
      frequent.value = r.data.frequent || []
    }
  } catch (e) {} finally { indLoading.value = false }
}

function selectIndicator (ind) {
  selectedIndId.value = ind.id
  selectedIndName.value = ind.name
  selectedIndScore.value = ind.score
  deductScore.value = Math.min(1, ind.score || 1)
}

function changeScore (delta) {
  let v = deductScore.value + delta
  if (v < 1) v = 1
  if (selectedIndScore.value > 0 && v > selectedIndScore.value) v = selectedIndScore.value
  deductScore.value = v
}

function choosePhoto () {
  uni.chooseImage({
    count: 3 - photos.value.length,
    success: (res) => {
      photos.value = photos.value.concat(res.tempFilePaths)
    }
  })
}

function previewPhoto (i) {
  uni.previewImage({ urls: photos.value, current: photos.value[i] })
}

async function doSubmit () {
  if (!reason.value.trim()) { uni.showToast({ title: '请填写扣分原因', icon: 'none' }); return }
  uni.showModal({
    title: '确认扣分',
    content: `确认对 ${selectedEmpName.value} 扣 ${deductScore.value} 分（${selectedIndName.value}）？`,
    success: async (res) => {
      if (!res.confirm) return
      try {
        const r = await quickDeduct({
          employee_id: selectedEmpId.value,
          indicator_id: selectedIndId.value,
          deduct_score: deductScore.value,
          reason: reason.value.trim(),
          attachments: photos.value,
          notify: notify.value
        })
        if (r.code === 0) {
          uni.showToast({ title: '扣分成功', icon: 'success' })
          setTimeout(() => uni.navigateBack(), 800)
        } else {
          uni.showToast({ title: r.msg || '扣分失败', icon: 'none' })
        }
      } catch (e) { uni.showToast({ title: '提交失败', icon: 'none' }) }
    }
  })
}

// 暂存（本地）
function saveDraft () {
  if (!reason.value.trim()) { uni.showToast({ title: '请填写扣分原因', icon: 'none' }); return }
  const drafts = uni.getStorageSync('assessment_drafts') || []
  drafts.push({
    employee_id: selectedEmpId.value, employee_name: selectedEmpName.value,
    indicator_id: selectedIndId.value, indicator_name: selectedIndName.value,
    deduct_score: deductScore.value, reason: reason.value.trim(),
    created_at: new Date().toLocaleString()
  })
  uni.setStorageSync('assessment_drafts', drafts)
  draftCount.value = drafts.length
  uni.showToast({ title: '已暂存', icon: 'success' })
}

function loadDraftCount () {
  const drafts = uni.getStorageSync('assessment_drafts') || []
  draftCount.value = drafts.length
}

function showDrafts () {
  const drafts = uni.getStorageSync('assessment_drafts') || []
  uni.showActionSheet({
    itemList: drafts.map(d => `${d.employee_name} ${d.indicator_name} -${d.deduct_score}分`),
    success: () => {}
  })
}
</script>

<style scoped>
.qd-page { min-height: 100vh; background: #f5f6fa; padding: 20rpx 24rpx 60rpx; }
.qd-steps { display: flex; align-items: center; padding: 24rpx 8rpx 30rpx; }
.qd-step { display: flex; align-items: center; gap: 8rpx; }
.qd-step-num { width: 40rpx; height: 40rpx; border-radius:50%; background: #e5e9f0; color: #8a9aa8; display: flex; align-items: center; justify-content: center; font-size: 24rpx; }
.qd-step.active .qd-step-num { background: #1e6fff; color: #fff; }
.qd-step-label { font-size: 24rpx; color: #8a9aa8; }
.qd-step.active .qd-step-label { color: #1e6fff; font-weight: 600; }
.qd-step-line { flex: 1; height: 4rpx; background: #e5e9f0; margin: 0 12rpx; }
.qd-step-line.active { background: #1e6fff; }
.qd-search-bar { display: flex; gap: 16rpx; align-items: center; }
.qd-search { flex: 1; background: #fff; border-radius:40rpx; padding: 16rpx 24rpx; display: flex; align-items: center; gap: 12rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.qd-search-input { flex: 1; font-size: 26rpx; }
.qd-scan { width: 76rpx; height: 76rpx; border-radius:50%; background: #1e6fff; display: flex; align-items: center; justify-content: center; }
.qd-section { background: #fff; border-radius:20rpx; padding: 24rpx; margin-top: 20rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.qd-section-title { font-size: 28rpx; font-weight: 600; color: #1d2129; margin-bottom: 16rpx; }
.qd-recent { white-space: nowrap; }
.qd-recent-item { display: inline-flex; flex-direction: column; align-items: center; margin-right: 24rpx; }
.qd-recent-avatar { width: 76rpx; height: 76rpx; border-radius:50%; background: #e8f3ff; color: #1e6fff; display: flex; align-items: center; justify-content: center; font-size: 28rpx; }
.qd-recent-name { font-size: 22rpx; color: #4e5a6b; margin-top: 8rpx; }
.qd-employee-list { }
.qd-employee { display: flex; align-items: center; padding: 20rpx 8rpx; border-bottom: 1rpx solid #EDF0F8; }
.qd-employee.checked { background: #f0f7ff; border-radius:12rpx; }
.qd-employee-check { width: 44rpx; }
.qd-employee-check-empty { display: inline-block; width: 30rpx; height: 30rpx; border: 2rpx solid #c9ced6; border-radius:50%; }
.qd-employee-info { flex: 1; }
.qd-employee-name { font-size: 28rpx; color: #1d2129; font-weight: 500; }
.qd-employee-dept { font-size: 22rpx; color: #8a9aa8; margin-left: 8rpx; }
.qd-employee-meta { display: block; font-size: 22rpx; color: #8a9aa8; margin-top: 4rpx; }
.qd-pending { color: #f53f3f; }
.qd-status { text-align: center; color: #8a9aa8; padding: 40rpx 0; font-size: 24rpx; }
.qd-foot-wrap { margin-top: 24rpx; }
.qd-foot-btn { margin-top: 24rpx; background: #1e6fff; color: #fff; text-align: center; padding: 24rpx; border-radius:44rpx; font-size: 28rpx; font-weight: 600; }
.qd-foot-btn.disabled { background: #c9ced6; }
.qd-target-bar { display: flex; justify-content: space-between; align-items: center; background: #fff; border-radius:20rpx; padding: 24rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.qd-target-text { font-size: 26rpx; color: #4e5a6b; }
.qd-target-name { font-weight: 700; color: #1d2129; }
.qd-target-switch { color: #1e6fff; font-size: 26rpx; }
.qd-cats { white-space: nowrap; margin-top: 20rpx; }
.qd-cat { display: inline-block; background: #fff; padding: 12rpx 28rpx; border-radius:32rpx; font-size: 24rpx; color: #4e5a6b; margin-right: 12rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.qd-cat.active { background: #1e6fff; color: #fff; }
.qd-cat-group { margin-bottom: 12rpx; }
.qd-cat-group-title { font-size: 24rpx; color: #8a9aa8; font-weight: 600; padding: 12rpx 8rpx; }
.qd-ind { display: flex; align-items: center; justify-content: space-between; padding: 18rpx 8rpx; border-bottom: 1rpx solid #EDF0F8; }
.qd-ind-left { flex: 1; }
.qd-ind-name { font-size: 27rpx; color: #1d2129; }
.qd-ind-meta { display: block; font-size: 21rpx; color: #8a9aa8; margin-top: 4rpx; }
.qd-ind-add { width: 48rpx; height: 48rpx; border-radius:50%; background: #e8f3ff; color: #1e6fff; display: flex; align-items: center; justify-content: center; font-size: 30rpx; }
.qd-confirm-card { background: #fff; border-radius:20rpx; padding: 24rpx; margin-top: 20rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.qd-confirm-row { display: flex; justify-content: space-between; align-items: center; padding: 14rpx 0; }
.qd-confirm-label { font-size: 26rpx; color: #8a9aa8; }
.qd-confirm-value { font-size: 27rpx; color: #1d2129; font-weight: 500; }
.qd-score-stepper { display: flex; align-items: center; gap: 24rpx; }
.qd-score-btn { width: 56rpx; height: 56rpx; border-radius:50%; background: #EDF0F8; display: flex; align-items: center; justify-content: center; font-size: 32rpx; color: #1d2129; }
.qd-score-num { font-size: 40rpx; font-weight: 700; color: #f53f3f; min-width: 60rpx; text-align: center; }
.qd-reason { width: 100%; min-height: 140rpx; background: #f7f9fc; border-radius:16rpx; padding: 20rpx; font-size: 26rpx; }
.qd-quick-phrases { display: flex; flex-wrap: wrap; gap: 12rpx; margin-top: 14rpx; }
.qd-phrase { background: #f0f7ff; color: #1e6fff; font-size: 22rpx; padding: 8rpx 20rpx; border-radius:28rpx; }
.qd-photos { display: flex; gap: 16rpx; flex-wrap: wrap; }
.qd-photo { position: relative; }
.qd-photo-img { width: 140rpx; height: 140rpx; border-radius:12rpx; }
.qd-photo-del { position: absolute; top: -12rpx; right: -12rpx; width: 36rpx; height: 36rpx; border-radius:50%; background: #f53f3f; color: #fff; display: flex; align-items: center; justify-content: center; font-size: 24rpx; }
.qd-photo-add { width: 140rpx; height: 140rpx; border-radius:12rpx; background: #f7f9fc; border: 2rpx dashed #d5dce4; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 6rpx; }
.qd-photo-add-text { font-size: 20rpx; color: #8a9aa8; }
.qd-tip { display: block; font-size: 20rpx; color: #b0c0cc; margin-top: 12rpx; }
.qd-switch { width: 88rpx; height: 48rpx; border-radius:24rpx; background: #d5dce4; position: relative; transition: .2s; }
.qd-switch.on { background: #1e6fff; }
.qd-switch-dot { position: absolute; top: 4rpx; left: 4rpx; width: 40rpx; height: 40rpx; border-radius:50%; background: #fff; transition: .2s; }
.qd-switch.on .qd-switch-dot { left: 44rpx; }
.qd-submit-bar { display: flex; gap: 20rpx; margin-top: 24rpx; }
.qd-btn { flex: 1; text-align: center; padding: 24rpx; border-radius:44rpx; font-size: 28rpx; font-weight: 600; }
.qd-btn.draft { background: #fff; color: #4e5a6b; }
.qd-btn.submit { background: #f53f3f; color: #fff; }
.qd-draft-tip { text-align: center; color: #1e6fff; font-size: 24rpx; margin-top: 20rpx; }
</style>
