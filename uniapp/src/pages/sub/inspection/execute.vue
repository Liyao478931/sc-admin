<template>
  <view class="ins-exec-page">
    <!-- 任务信息 -->
    <view class="task-info-card">
      <view class="info-row"><text class="info-label">设备</text><text class="info-value">{{ detail.device_name }}</text></view>
      <view class="info-row"><text class="info-label">编码</text><text class="info-value gray">{{ detail.device_code }}</text></view>
      <view class="info-row"><text class="info-label">任务编号</text><text class="info-value">{{ detail.task_code }}</text></view>
      <view class="info-row"><text class="info-label">计划日期</text><text class="info-value">{{ detail.plan_execute_date }}</text></view>
    </view>

    <!-- 检查项 -->
    <view class="section">
      <view class="section-title">检查项（{{ itemResultsCount }}/{{ templateItems.length }}）</view>
      <view v-for="(item, idx) in templateItems" :key="idx" class="item-card">
        <view class="item-header">
          <text class="item-name"><text v-if="item.is_required" class="required">*</text>{{ item.item_name }}</text>
          <view class="item-result">
            <view class="result-btn normal" :class="{active: getItemResult(idx) === 'normal'}" @click="setResult(idx, 'normal')">正常</view>
            <view class="result-btn abnormal" :class="{active: getItemResult(idx) === 'abnormal'}" @click="setResult(idx, 'abnormal')">异常</view>
          </view>
        </view>
        <view v-if="item.operation_content" class="item-desc">操作：{{ item.operation_content }}</view>
        <view v-if="item.check_standard" class="item-desc">标准：{{ item.check_standard }}</view>

        <view v-if="getItemResult(idx) === 'abnormal'" class="abnormal-box">
          <u-textarea v-model="itemResults[idx].description" placeholder="请填写异常描述（至少10字）" maxlength="200" />
          <view class="abnormal-photo" @click="takeAbnormalPhoto(idx)"><MIcon name="camera" :size="15" color="#4F46E5" /><text style="margin-left:4px">拍照/上传</text></view>
          <image v-if="itemResults[idx].photo" :src="imgUrl(itemResults[idx].photo)" class="abnormal-img" mode="aspectFill" @click="previewImage(itemResults[idx].photo)" />
        </view>
      </view>
      <u-empty v-if="!templateItems.length && !loading" text="该任务暂未配置检查项" mode="list" />
    </view>

    <!-- 备注 -->
    <view class="section">
      <view class="section-title">备注</view>
      <u-textarea v-model="remark" placeholder="请输入巡检备注（选填）" maxlength="500" />
    </view>

    <!-- 底部操作 -->
    <view class="bottom-bar">
      <view class="submit-btn" :class="{disabled: submitting}" @click="handleSubmit">{{ submitting ? '提交中...' : '提交巡检结果' }}</view>
    </view>
  </view>
</template>

<script>
import {
  getInspectionTaskDetail, getInspectionCheckItems,
  startInspectionTask, submitInspection, uploadInspectionImage
} from '../../../api/index.js'

export default {
  data() {
    return {
      taskId: 0,
      detail: {},
      templateItems: [],
      itemResults: {},
      remark: '',
      submitting: false,
      loading: true
    }
  },
  computed: {
    itemResultsCount() {
      return this.templateItems.filter((t, i) => this.getItemResult(i)).length
    }
  },
  onLoad(options) {
    this.taskId = Number(options.task_id || 0)
    this.loadDetail()
  },
  methods: {
    imgUrl(val) {
      if (!val) return ''
      if (val.startsWith('http://') || val.startsWith('https://')) return val
      if (val.startsWith('/')) return uni.$base + val
      return val
    },
    async loadDetail() {
      try {
        const [d, c] = await Promise.all([
          getInspectionTaskDetail(this.taskId),
          getInspectionCheckItems(this.taskId)
        ])
        if (d.code === 0) this.detail = d.data
        if (c.code === 0) {
          this.templateItems = (c.data && c.data.items) || []
          const saved = (c.data && c.data.saved_result) || []
          if (saved.length) {
            saved.forEach((it, i) => {
              this.itemResults[i] = {
                result: it.result || '',
                description: it.desc || it.description || '',
                photo: it.photo || ''
              }
            })
          }
        }
      } catch (e) { uni.showToast({ title: '加载失败', icon: 'none' }) }
      this.loading = false
    },
    getItemResult(idx) { return (this.itemResults[idx] || {}).result || '' },
    setResult(idx, result) {
      if (!this.itemResults[idx]) this.itemResults[idx] = { result: '', description: '', photo: '' }
      this.itemResults[idx].result = result
      if (result === 'normal') { this.itemResults[idx].description = ''; this.itemResults[idx].photo = '' }
    },
    async takeAbnormalPhoto(idx) {
      uni.chooseImage({
        count: 1,
        success: async (res) => {
          const path = res.tempFilePaths[0]
          try {
            const up = await uploadInspectionImage(path)
            if (up.code === 0 && up.data && up.data.url) {
              if (!this.itemResults[idx]) this.itemResults[idx] = { result: '', description: '', photo: '' }
              this.itemResults[idx].photo = up.data.url
            } else { uni.showToast({ title: '上传失败', icon: 'none' }) }
          } catch (e) { uni.showToast({ title: '上传失败', icon: 'none' }) }
        }
      })
    },
    previewImage(url) { uni.previewImage({ urls: [url], current: url }) },
    buildItems() {
      return this.templateItems.map((t, idx) => {
        const r = this.itemResults[idx] || {}
        return {
          item_name: t.item_name || '',
          name: t.item_name || '',
          is_required: t.is_required ? 1 : 0,
          result: r.result || 'normal',
          desc: r.description || '',
          photo: r.photo || ''
        }
      })
    },
    async handleSubmit() {
      // 校验必填
      for (let i = 0; i < this.templateItems.length; i++) {
        const t = this.templateItems[i]
        const r = this.itemResults[i] || {}
        if (t.is_required && !r.result) {
          uni.showToast({ title: `请填写「${t.item_name}」结果`, icon: 'none' }); return
        }
        if (r.result === 'abnormal' && (!r.description || r.description.length < 10)) {
          uni.showToast({ title: `「${t.item_name}」异常描述至少10字`, icon: 'none' }); return
        }
      }
      this.submitting = true
      try {
        try { await startInspectionTask(this.taskId) } catch (e) {}
        const items = this.buildItems()
        const r = await submitInspection(this.taskId, { items, remark: this.remark })
        if (r.code === 0) {
          const cnt = r.data ? r.data.abnormal_count : 0
          uni.showToast({ title: cnt > 0 ? `提交成功，发现${cnt}项异常` : '提交成功', icon: 'success' })
          setTimeout(() => uni.navigateBack(), 900)
        } else {
          uni.showToast({ title: r.msg || '提交失败', icon: 'none' })
        }
      } catch (e) {
        uni.showToast({ title: (e && e.msg) || '提交失败', icon: 'none' })
      }
      this.submitting = false
    }
  }
}
</script>

<style scoped>
.ins-exec-page { min-height: 100vh; background: #F4F6FB; padding-bottom: 100px; }
.task-info-card { margin: 12px 16px; background: #fff; border-radius: 16px; padding: 14px 16px; }
.info-row { display: flex; padding: 5px 0; }
.info-label { width: 72px; font-size: 13px; color: #9ca3af; }
.info-value { flex: 1; font-size: 14px; color: #1a2332; font-weight: 600; }
.info-value.gray { color: #6b7280; font-weight: 400; }
.section { margin: 12px 16px; }
.section-title { font-size: 15px; font-weight: 700; color: #1a2332; margin-bottom: 10px; }
.item-card { background: #fff; border-radius: 16px; padding: 14px; margin-bottom: 10px; }
.item-header { display: flex; align-items: center; justify-content: space-between; }
.item-name { font-size: 15px; font-weight: 600; color: #1a2332; flex: 1; }
.required { color: #e74c5e; margin-right: 4px; }
.item-result { display: flex; gap: 8px; }
.result-btn { padding: 5px 16px; border-radius: 20px; font-size: 13px; border: 1px solid #E7ECF4; color: #9ca3af; }
.result-btn.normal.active { background: #eafaf0; color: #1f9d55; border-color: #b5e8cd; }
.result-btn.abnormal.active { background: #fdecea; color: #e74c5e; border-color: #fbc4c4; }
.item-desc { font-size: 12px; color: #9ca3af; margin-top: 6px; }
.abnormal-box { margin-top: 10px; }
.abnormal-photo { display: inline-block; font-size: 13px; color: #4F46E5; background: #f0f4ff; padding: 6px 14px; border-radius: 20px; margin-top: 8px; }
.abnormal-img { width: 120px; height: 120px; border-radius: 12px; margin-top: 8px; display: block; }
.bottom-bar { position: fixed; left: 0; right: 0; bottom: 0; padding: 12px 16px calc(14px + env(safe-area-inset-bottom)); background: #fff; box-shadow: 0 -4rpx 20rpx rgba(0,0,0,0.05); }
.submit-btn { text-align: center; padding: 14px; border-radius: 24px; font-size: 16px; font-weight: 700; color: #fff; background: linear-gradient(135deg, #4F46E5, #7c6cf0); }
.submit-btn.disabled { opacity: 0.6; }
</style>
