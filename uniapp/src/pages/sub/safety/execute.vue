<template>
  <view class="safety-execute-page">
    <!-- 任务信息卡片 -->
    <view class="task-info-card">
      <view class="info-row"><text class="info-label">任务编号</text><text class="info-value">{{ store.currentTask.task_code }}</text></view>
      <view class="info-row"><text class="info-label">计划名称</text><text class="info-value">{{ store.currentTask.plan_name }}</text></view>
      <view class="info-row"><text class="info-label">检查类型</text><text class="info-value level">{{ store.currentTask.inspection_type_name }}</text></view>
      <view class="info-row"><text class="info-label">检查区域</text><text class="info-value">{{ store.currentTask.area || '—' }}</text></view>
      <view class="info-row"><text class="info-label">计划日期</text><text class="info-value">{{ store.currentTask.plan_execute_date }}</text></view>
      <view class="info-row"><text class="info-label">执行人</text><text class="info-value">{{ store.currentTask.executor_name || '我' }}</text></view>
    </view>

    <!-- 检查项目列表 -->
    <view class="section">
      <view class="section-title">
        <text>检查项目</text>
        <text class="stats">合格 {{ store.stats.qualified }} / 不合格 {{ store.stats.unqualified }} / 不适用 {{ store.stats.na }}</text>
      </view>

      <view v-for="(item, idx) in store.templateItems" :key="idx" class="item-card">
        <view class="item-header">
          <text class="item-name"><text v-if="item.is_required" class="required">*</text>{{ item.item_name }}</text>
        </view>
        <view v-if="item.check_standard" class="item-desc">标准：{{ item.check_standard }}</view>
        <view v-if="item.check_method" class="item-desc">方法：{{ item.check_method }}</view>

        <!-- 结果选项 -->
        <view class="item-result">
          <view class="result-btn q" :class="{active: item.result === 'qualified'}" @click="store.setResult(idx, 'qualified')">合格</view>
          <view class="result-btn uq" :class="{active: item.result === 'unqualified'}" @click="store.setResult(idx, 'unqualified')">不合格</view>
          <view class="result-btn na" :class="{active: item.result === 'na'}" @click="store.setResult(idx, 'na')">不适用</view>
        </view>

        <!-- 不合格问题填写区域 -->
        <view v-if="item.result === 'unqualified'" class="issue-box">
          <view class="issue-field">
            <text class="issue-label">问题描述 <text class="required">*</text></text>
            <u-textarea v-model="item.issue_description" placeholder="请描述发现的问题（至少10个字）" maxlength="1000" />
          </view>
          <view class="issue-field">
            <text class="issue-label">整改建议</text>
            <u-textarea v-model="item.suggest" placeholder="整改建议（选填）" maxlength="500" />
          </view>
          <view class="issue-field">
            <text class="issue-label">严重程度</text>
            <view class="severity-options">
              <view v-for="s in severityOptions" :key="s.value" class="severity-item" :class="{active: item.severity === s.value}" @click="item.severity = s.value">{{ s.label }}</view>
            </view>
          </view>
          <view class="issue-field switch-row">
            <text class="issue-label">自动创建隐患</text>
            <switch :checked="item.create_hazard" color="#409EFF" @change="e => item.create_hazard = e.detail.value" />
          </view>
        </view>
      </view>
    </view>

    <!-- 检查总结 -->
    <view class="section">
      <view class="section-title">检查总结</view>
      <u-textarea v-model="store.summary" placeholder="本次检查总结（选填）" maxlength="2000" />
    </view>

    <!-- 底部操作栏 -->
    <view class="bottom-bar">
      <view class="back-btn" @click="handleBack">返回</view>
      <view class="draft-btn" @click="handleDraft">暂存</view>
      <view class="submit-btn" :class="{disabled: submitting}" @click="handleSubmit">{{ submitting ? '提交中...' : '提交' }}</view>
    </view>
  </view>
</template>

<script>
import { useSafetyStore } from '../../../store/modules/safety.js'
import { getSafetyTaskDetail, startSafetyTask, draftSafetyTask, submitSafetyTask } from '../../../api/index.js'

export default {
  data() {
    return {
      safetyStore: null,
      taskId: 0,
      started: false,
      submitting: false,
      hasUnsaved: false,
      severityOptions: [
        { label: '一般', value: 'minor' },
        { label: '严重', value: 'major' },
        { label: '紧急', value: 'critical' }
      ]
    }
  },
  computed: {
    store() { return this.safetyStore }
  },
  onLoad(options) {
    this.taskId = Number(options.task_id || 0)
    this.safetyStore = useSafetyStore()
    this.safetyStore.reset()
    this.loadDetail()
  },
  // 拦截系统返回：有未保存数据时确认
  onBackPress() {
    if (this.hasUnsaved) {
      this.confirmBack()
      return true
    }
    return false
  },
  methods: {
    async loadDetail() {
      try {
        const r = await getSafetyTaskDetail(this.taskId)
        if (r.code !== 0) { uni.showToast({ title: r.msg || '加载失败', icon: 'none' }); return }
        this.safetyStore.setTask(r.data)
        this.safetyStore.initItems(r.data.template_items, r.data.result)
        // 待执行/逾期自动开始
        if (['pending', 'overdue'].indexOf(r.data.status) > -1) this.handleStart()
        this.watchDirty()
      } catch (e) { uni.showToast({ title: '加载失败', icon: 'none' }) }
    },
    watchDirty() {
      // 监听项目结果/总结变化，标记未保存
      this.$watch(() => JSON.stringify(this.safetyStore.templateItems) + this.safetyStore.summary, (val, old) => {
        if (old !== undefined && val !== old && this._loaded) this.hasUnsaved = true
        this._loaded = true
      })
    },
    async handleStart() {
      if (this.started) return
      this.started = true
      try { await startSafetyTask(this.taskId) } catch (e) {}
    },
    handleBack() {
      if (this.hasUnsaved) this.confirmBack()
      else uni.navigateBack()
    },
    confirmBack() {
      uni.showModal({
        title: '提示',
        content: '有未保存的检查数据，确认退出？',
        confirmText: '退出',
        confirmColor: '#F56C6C',
        success: (res) => { if (res.confirm) uni.navigateBack() }
      })
    },
    async handleDraft() {
      this.safetyStore.saveDraft(this.taskId)
      try {
        await this.handleStart()
        const r = await draftSafetyTask(this.taskId, this.safetyStore.buildItems(), this.safetyStore.summary)
        if (r.code === 0) {
          this.hasUnsaved = false
          uni.showToast({ title: '暂存成功', icon: 'success' })
        } else { uni.showToast({ title: r.msg || '暂存失败', icon: 'none' }) }
      } catch (e) { uni.showToast({ title: '暂存失败', icon: 'none' }) }
    },
    validate() {
      for (const it of this.safetyStore.templateItems) {
        if (!it.result) {
          uni.showToast({ title: `请选择「${it.item_name}」结果`, icon: 'none' }); return false
        }
        if (it.result === 'unqualified' && (!it.issue_description || it.issue_description.trim().length < 10)) {
          uni.showToast({ title: `「${it.item_name}」问题描述至少10字`, icon: 'none' }); return false
        }
      }
      return true
    },
    async handleSubmit() {
      if (!this.validate()) return
      uni.showModal({
        title: '确认提交',
        content: '确认提交检查结果？不合格项目将自动创建隐患记录。',
        confirmText: '提交',
        success: async (res) => {
          if (!res.confirm) return
          this.submitting = true
          try {
            await this.handleStart()
            const r = await submitSafetyTask(
              this.taskId,
              this.safetyStore.buildItems(),
              this.safetyStore.summary,
              this.safetyStore.buildIssues()
            )
            if (r.code === 0) {
              this.safetyStore.clearDraft(this.taskId)
              uni.showToast({ title: '提交成功', icon: 'success' })
              setTimeout(() => uni.navigateBack(), 1000)
            } else { uni.showToast({ title: r.msg || '提交失败', icon: 'none' }) }
          } catch (e) { uni.showToast({ title: '提交失败', icon: 'none' }) }
          this.submitting = false
        }
      })
    }
  }
}
</script>

<style scoped>
.safety-execute-page { min-height: 100vh; background: #f5f6fa; padding-bottom: 160rpx; }
.task-info-card { background: #fff; padding: 24rpx; margin: 16rpx; border-radius:16rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.info-row { display: flex; margin-bottom: 12rpx; }
.info-label { width: 150rpx; color: #909399; font-size: 28rpx; }
.info-value { color: #303133; font-size: 28rpx; flex: 1; }
.info-value.level { color: #409EFF; }
.section { background: #fff; margin: 16rpx; padding: 24rpx; border-radius:16rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.section-title { display: flex; align-items: center; justify-content: space-between; font-size: 30rpx; font-weight: 600; margin-bottom: 16rpx; }
.stats { font-size: 24rpx; color: #909399; font-weight: normal; }
.item-card { border: 1rpx solid #eee; border-radius:12rpx; padding: 20rpx; margin-bottom: 16rpx; }
.item-name { font-size: 28rpx; font-weight: 600; }
.required { color: #F56C6C; margin-right: 4rpx; }
.item-desc { font-size: 24rpx; color: #909399; margin-top: 8rpx; }
.item-result { display: flex; gap: 16rpx; margin-top: 16rpx; }
.result-btn { flex: 1; text-align: center; padding: 14rpx 0; border-radius:24rpx; font-size: 26rpx; }
.result-btn.q { background: #f0f9eb; color: #67C23A; }
.result-btn.q.active { background: #67C23A; color: #fff; }
.result-btn.uq { background: #fef0f0; color: #F56C6C; }
.result-btn.uq.active { background: #F56C6C; color: #fff; }
.result-btn.na { background: #f4f4f5; color: #909399; }
.result-btn.na.active { background: #909399; color: #fff; }
.issue-box { margin-top: 16rpx; background: #fdf6ec; border-radius:12rpx; padding: 20rpx; }
.issue-field { margin-bottom: 16rpx; }
.issue-label { font-size: 26rpx; color: #606266; display: block; margin-bottom: 8rpx; }
.issue-input { width: 100%; min-height: 100rpx; border: 1rpx solid #e0c9a8; border-radius:8rpx; padding: 12rpx; box-sizing: border-box; font-size: 26rpx; background: #fff; }
.severity-options { display: flex; gap: 16rpx; }
.severity-item { padding: 10rpx 28rpx; border-radius:24rpx; font-size: 26rpx; background: #f4f4f5; color: #909399; }
.severity-item.active { background: #409EFF; color: #fff; }
.switch-row { display: flex; align-items: center; justify-content: space-between; }
.summary-input { width: 100%; height: 140rpx; border: 1rpx solid #eee; border-radius:8rpx; padding: 12rpx; box-sizing: border-box; font-size: 26rpx; }
.bottom-bar { position: fixed; bottom: 0; left: 0; right: 0; display: flex; padding: 16rpx 24rpx; background: #fff; box-shadow: 0 -2rpx 8rpx rgba(0,0,0,.05); }
.back-btn { flex: 1; text-align: center; padding: 24rpx; border-radius:40rpx; background: #f0f0f0; color: #606266; font-size: 30rpx; margin-right: 16rpx; }
.draft-btn { flex: 1; text-align: center; padding: 24rpx; border-radius:40rpx; background: #fdf6ec; color: #E6A23C; font-size: 30rpx; margin-right: 16rpx; }
.submit-btn { flex: 1.5; text-align: center; padding: 24rpx; border-radius:40rpx; background: #409EFF; color: #fff; font-size: 30rpx; }
.submit-btn.disabled { opacity: .6; }
</style>
