<template>
  <view class="execute-page">
    <!-- 工单信息卡片 -->
    <view class="order-card">
      <view class="order-head">
        <text class="order-no">{{ detail.order_code }}</text>
        <text class="urgency-tag" :class="'u-' + detail.emergency_level">{{ detail.emergency_text || '普通' }}</text>
      </view>
      <view class="device-name">{{ detail.device_name }}</view>
      <view class="device-code">编码：{{ detail.device_code }}</view>
      <view class="order-meta">
        <text class="meta-item">故障：{{ detail.fault_type || '-' }}</text>
        <text class="meta-item">报修人：{{ detail.reporter_name || '-' }}</text>
        <text class="meta-item">报修时间：{{ detail.report_time }}</text>
      </view>
      <view v-if="detail.fault_description" class="fault-desc">故障描述：{{ detail.fault_description }}</view>
    </view>

    <!-- 表单内容区 -->
    <scroll-view class="form-scroll" scroll-y>
      <!-- 故障诊断 -->
      <view class="section">
        <view class="section-title">故障诊断</view>
        <view class="form-item">
          <u-textarea v-model="form.diagnosis_cause" placeholder="请分析故障产生的原因（必填）" maxlength="500" />
        </view>
        <view class="form-item">
          <u-textarea v-model="form.diagnosis_conclusion" placeholder="请给出诊断结论（必填）" maxlength="500" />
        </view>
      </view>

      <!-- 维修方案 -->
      <view class="section">
        <view class="section-title">维修方案</view>
        <view class="form-item">
          <u-textarea v-model="form.repair_plan" placeholder="请描述维修方案（必填）" maxlength="1000" />
        </view>
        <view class="material-head">
          <text>备件清单</text>
          <text class="add-material" @click="materialVisible = true">＋ 添加备件</text>
        </view>
        <view v-if="materials.length" class="material-list">
          <view v-for="(m, i) in materials" :key="i" class="material-item">
            <view class="material-info">
              <text class="m-name">{{ m.name }}</text>
              <text class="m-spec">{{ m.spec }}</text>
            </view>
            <text class="m-qty">× {{ m.quantity }}</text>
            <text class="m-del" @click="removeMaterial(i)">删除</text>
          </view>
        </view>
        <view v-else class="material-empty">暂未添加备件</view>
      </view>

      <!-- 维修过程 -->
      <view class="section">
        <view class="section-title">维修过程</view>
        <view class="form-item">
          <u-textarea v-model="form.repair_process" placeholder="请详细记录维修过程（必填）" maxlength="1000" />
        </view>
        <view class="result-row">
          <text class="result-label">维修结果：</text>
          <view class="radio" :class="{active: form.repair_result === 'fixed'}" @click="form.repair_result = 'fixed'">已修复</view>
          <view class="radio danger" :class="{active: form.repair_result === 'unfixable'}" @click="form.repair_result = 'unfixable'">无法修复</view>
        </view>
        <view class="duration">已用时：{{ durationText }}</view>
      </view>

      <!-- 附件上传 -->
      <view class="section">
        <view class="section-title">上传附件 <text class="attach-count">{{ attachments.length }}/9</text></view>
        <view class="attach-grid">
          <view v-for="(img, i) in attachments" :key="i" class="attach-item">
            <image :src="img" mode="aspectFill" @click="previewImage(i)" />
            <text class="attach-del" @click="removeAttachment(i)">×</text>
          </view>
          <view v-if="attachments.length < 9" class="attach-add" @click="chooseImage">＋</view>
        </view>
      </view>
    </scroll-view>

    <!-- 底部操作按钮 -->
    <view class="bottom-bar">
      <button class="btn draft" @click="handleDraft">暂存</button>
      <button class="btn submit" :loading="submitting" @click="handleSubmit">提交验收</button>
    </view>

    <!-- 备件弹窗 -->
    <material-edit-dialog :visible.sync="materialVisible" @confirm="addMaterial" />
  </view>
</template>

<script>
import { getRepairTaskDetail, startRepair, draftRepair, submitRepair, uploadRepairImage } from '../../../api/index.js'
import MaterialEditDialog from './components/MaterialEditDialog.vue'

export default {
  components: { MaterialEditDialog },
  data() {
    return {
      taskId: 0,
      detail: {},
      form: { diagnosis_cause: '', diagnosis_conclusion: '', repair_plan: '', repair_process: '', repair_result: '' },
      materials: [],
      attachments: [],
      materialVisible: false,
      submitting: false,
      startTime: null,
      timer: null,
      durationText: '00小时00分钟'
    }
  },
  onLoad(options) {
    this.taskId = parseInt(options.task_id || 0)
    this.loadDetail()
  },
  onUnload() { if (this.timer) clearInterval(this.timer) },
  methods: {
    async loadDetail() {
      if (!this.taskId) { uni.showToast({ title: '参数错误', icon: 'none' }); return }
      uni.showLoading({ title: '加载中' })
      try {
        const r = await getRepairTaskDetail(this.taskId)
        uni.hideLoading()
        if (r.code === 0) {
          this.detail = r.data
          this.form = {
            diagnosis_cause: r.data.diagnosis_cause || '',
            diagnosis_conclusion: r.data.diagnosis_conclusion || '',
            repair_plan: r.data.repair_plan || '',
            repair_process: r.data.repair_process || '',
            repair_result: r.data.repair_result || ''
          }
          this.materials = r.data.materials || []
          this.attachments = r.data.attachments || []
          // 已开始维修 → 按开始时间计时；未开始 → 自动开始
          if (r.data.execute_start_time) {
            this.startTime = r.data.execute_start_time
            this.startTimer()
          } else if (r.data.status === 'assigned') {
            this.autoStart()
          }
        } else { uni.showToast({ title: r.msg || '加载失败', icon: 'none' }) }
      } catch (e) { uni.hideLoading(); uni.showToast({ title: '加载失败', icon: 'none' }) }
    },
    async autoStart() {
      try {
        const r = await startRepair(this.taskId)
        if (r.code === 0) {
          this.startTime = new Date().toLocaleString('zh-CN', { hour12: false })
          this.startTimer()
        }
      } catch (e) {}
    },
    startTimer() {
      this.updateDuration()
      this.timer = setInterval(() => this.updateDuration(), 60000)
    },
    updateDuration() {
      if (!this.startTime) return
      const start = new Date(this.startTime.replace(/-/g, '/')).getTime()
      const diff = Math.max(0, Math.floor((Date.now() - start) / 60000))
      const h = Math.floor(diff / 60), m = diff % 60
      this.durationText = String(h).padStart(2, '0') + '小时' + String(m).padStart(2, '0') + '分钟'
    },
    addMaterial(m) { this.materials.push(m) },
    removeMaterial(i) { this.materials.splice(i, 1) },
    chooseImage() {
      const remain = 9 - this.attachments.length
      uni.chooseImage({
        count: remain,
        sizeType: ['compressed'],
        success: (res) => {
          res.tempFilePaths.forEach((p) => this.uploadImage(p))
        }
      })
    },
    async uploadImage(filePath) {
      uni.showLoading({ title: '上传中' })
      try {
        const r = await uploadRepairImage(filePath)
        uni.hideLoading()
        if (r.code === 0 && r.data && r.data.url) this.attachments.push(r.data.url)
        else uni.showToast({ title: r.msg || '上传失败', icon: 'none' })
      } catch (e) { uni.hideLoading(); uni.showToast({ title: '上传失败', icon: 'none' }) }
    },
    previewImage(i) { uni.previewImage({ urls: this.attachments, current: i }) },
    removeAttachment(i) { this.attachments.splice(i, 1) },
    validate() {
      if (this.form.diagnosis_cause.length < 10) { uni.showToast({ title: '故障原因分析至少10字', icon: 'none' }); return false }
      if (this.form.diagnosis_conclusion.length < 10) { uni.showToast({ title: '诊断结论至少10字', icon: 'none' }); return false }
      if (this.form.repair_plan.length < 10) { uni.showToast({ title: '维修方案至少10字', icon: 'none' }); return false }
      if (this.form.repair_process.length < 10) { uni.showToast({ title: '维修记录至少10字', icon: 'none' }); return false }
      if (!this.form.repair_result) { uni.showToast({ title: '请选择维修结果', icon: 'none' }); return false }
      return true
    },
    async handleDraft() {
      if (!this.validate()) return
      uni.showLoading({ title: '暂存中' })
      try {
        const r = await draftRepair(this.taskId, { ...this.form, materials: this.materials, attachments: this.attachments })
        uni.hideLoading()
        if (r.code === 0) { uni.showToast({ title: '暂存成功', icon: 'success' }); setTimeout(() => this.goList(), 800) }
        else uni.showToast({ title: r.msg || '暂存失败', icon: 'none' })
      } catch (e) { uni.hideLoading(); uni.showToast({ title: '暂存失败', icon: 'none' }) }
    },
    async handleSubmit() {
      if (!this.validate()) return
      this.submitting = true
      uni.showLoading({ title: '提交中' })
      try {
        const r = await submitRepair(this.taskId, { ...this.form, materials: this.materials, attachments: this.attachments })
        uni.hideLoading(); this.submitting = false
        if (r.code === 0) {
          uni.showToast({ title: '提交成功，等待验收', icon: 'success' })
          setTimeout(() => this.goList(), 800)
        } else { uni.showToast({ title: r.msg || '提交失败', icon: 'none' }) }
      } catch (e) { uni.hideLoading(); this.submitting = false; uni.showToast({ title: '提交失败', icon: 'none' }) }
    },
    goList() { uni.redirectTo({ url: '/pages/sub/repair/task-list' }) }
  }
}
</script>

<style scoped>
.execute-page { min-height: 100vh; background: #f5f6fa; padding-bottom: 140rpx; }
.order-card { background: #fff; margin: 16rpx 24rpx; border-radius:16rpx; padding: 24rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.order-head { display: flex; align-items: center; justify-content: space-between; }
.order-no { font-size: 26rpx; color: #909399; }
.urgency-tag { font-size: 22rpx; color: #fff; padding: 4rpx 14rpx; border-radius:8rpx; }
.u-critical { background: #F56C6C; }
.u-urgent { background: #E6A23C; }
.u-normal { background: #909399; }
.device-name { font-size: 34rpx; font-weight: 600; margin-top: 12rpx; }
.device-code { font-size: 24rpx; color: #909399; margin-top: 8rpx; }
.order-meta { display: flex; flex-wrap: wrap; margin-top: 16rpx; }
.meta-item { font-size: 24rpx; color: #606266; margin-right: 20rpx; margin-bottom: 8rpx; }
.fault-desc { font-size: 24rpx; color: #303133; background: #F4F6FB; border-radius:8rpx; padding: 16rpx; margin-top: 12rpx; }
.form-scroll { height: calc(100vh - 380rpx); }
.section { background: #fff; margin: 16rpx 24rpx; border-radius:16rpx; padding: 24rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.section-title { font-size: 30rpx; font-weight: 600; margin-bottom: 20rpx; padding-left: 12rpx; border-left: 6rpx solid #409EFF; }
.form-item textarea { width: 100%; height: 160rpx; border: 1rpx solid #dcdfe6; border-radius:8rpx; padding: 16rpx; font-size: 28rpx; box-sizing: border-box; margin-bottom: 16rpx; }
.material-head { display: flex; justify-content: space-between; align-items: center; margin: 8rpx 0; }
.add-material { color: #409EFF; font-size: 26rpx; }
.material-list { margin-top: 8rpx; }
.material-item { display: flex; align-items: center; padding: 16rpx; background: #F4F6FB; border-radius:8rpx; margin-bottom: 12rpx; }
.material-info { flex: 1; }
.m-name { font-size: 28rpx; color: #303133; display: block; }
.m-spec { font-size: 24rpx; color: #909399; }
.m-qty { font-size: 28rpx; color: #303133; margin-right: 20rpx; }
.m-del { color: #F56C6C; font-size: 26rpx; }
.material-empty { color: #909399; font-size: 26rpx; padding: 16rpx 0; }
.result-row { display: flex; align-items: center; margin-top: 8rpx; }
.result-label { font-size: 28rpx; color: #606266; margin-right: 20rpx; }
.radio { font-size: 28rpx; padding: 12rpx 32rpx; border-radius:24rpx; border: 1rpx solid #67C23A; color: #67C23A; margin-right: 20rpx; }
.radio.active { background: #67C23A; color: #fff; }
.radio.danger { border-color: #F56C6C; color: #F56C6C; }
.radio.danger.active { background: #F56C6C; color: #fff; }
.duration { font-size: 26rpx; color: #409EFF; margin-top: 16rpx; }
.attach-count { font-size: 24rpx; color: #909399; font-weight: normal; }
.attach-grid { display: flex; flex-wrap: wrap; }
.attach-item { width: 160rpx; height: 160rpx; margin: 0 16rpx 16rpx 0; position: relative; }
.attach-item image { width: 100%; height: 100%; border-radius:8rpx; }
.attach-del { position: absolute; right: -12rpx; top: -12rpx; width: 40rpx; height: 40rpx; background: #F56C6C; color: #fff; border-radius:50%; text-align: center; line-height: 40rpx; font-size: 28rpx; }
.attach-add { width: 160rpx; height: 160rpx; border: 2rpx dashed #c0c4cc; border-radius:8rpx; display: flex; align-items: center; justify-content: center; font-size: 60rpx; color: #c0c4cc; }
.bottom-bar { position: fixed; bottom: 0; left: 0; right: 0; display: flex; padding: 20rpx 24rpx; background: #fff; box-shadow: 0 -2rpx 8rpx rgba(0,0,0,.05); }
.btn { flex: 1; margin: 0 12rpx; font-size: 32rpx; border-radius:44rpx; }
.btn.draft { background: #f4f4f5; color: #606266; }
.btn.submit { background: #409EFF; color: #fff; }
</style>
