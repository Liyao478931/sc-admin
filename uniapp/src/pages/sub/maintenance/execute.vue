<template>
  <view class="execute-page">
    <!-- 任务信息卡片 -->
    <view class="task-info-card">
      <view class="info-row"><text class="info-label">设备</text><text class="info-value">{{ detail.device_name }}</text></view>
      <view class="info-row"><text class="info-label">编码</text><text class="info-value gray">{{ detail.device_code }}</text></view>
      <view class="info-row"><text class="info-label">等级</text><text class="info-value level">{{ detail.level_name }}</text></view>
      <view class="info-row"><text class="info-label">计划日期</text><text class="info-value">{{ detail.plan_execute_date }}</text></view>
      <view class="info-row"><text class="info-label">验收人</text><text class="info-value">{{ detail.acceptor_name || '未指定' }}</text></view>
    </view>

    <!-- 保养项目列表 -->
    <view class="section">
      <view class="section-title">保养项目（{{ items.length }}/{{ templateItems.length }}）</view>
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

        <!-- 异常描述与照片 -->
        <view v-if="getItemResult(idx) === 'abnormal'" class="abnormal-box">
          <u-textarea v-model="itemResults[idx].description" placeholder="请填写异常描述（至少10字）" maxlength="200" />
          <view class="abnormal-photo" @click="takeAbnormalPhoto(idx)"><MIcon name="camera" :size="15" color="#4F46E5" /><text style="margin-left:4px">拍照/上传</text></view>
          <image v-if="itemResults[idx].photo" :src="itemResults[idx].photo" class="abnormal-img" mode="aspectFill" @click="previewImage(itemResults[idx].photo)" />
        </view>
      </view>
    </view>

    <!-- 耗材记录 -->
    <view class="section">
      <view class="section-title">
        <text>耗材使用记录</text>
        <text class="add-btn" @click="showMaterialDialog = true">＋ 添加耗材</text>
      </view>
      <view v-for="(m, idx) in materials" :key="idx" class="material-row">
        <text>{{ m.material_name }} <text class="gray">{{ m.specification }}</text></text>
        <text>× {{ m.quantity }}{{ m.unit }}</text>
        <text class="del-btn" @click="materials.splice(idx, 1)">删除</text>
      </view>
      <view v-if="!materials.length" class="none-text">暂无耗材记录</view>
    </view>

    <!-- 附件上传 -->
    <view class="section">
      <view class="section-title">
        <text>上传附件（{{ attachments.length }}/9）</text>
        <text v-if="attachments.length < 9" class="add-btn" @click="chooseImage">＋ 添加</text>
      </view>
      <view class="attachment-grid">
        <view v-for="(img, idx) in attachments" :key="idx" class="attachment-item">
          <image :src="img" class="attachment-img" mode="aspectFill" @click="previewImage(img)" />
          <text class="attachment-del" @click="attachments.splice(idx, 1)">×</text>
        </view>
      </view>
    </view>

    <!-- 备注 -->
    <view class="section">
      <view class="section-title">备注</view>
      <u-textarea v-model="remark" placeholder="请输入备注信息（选填）" maxlength="500" />
    </view>

    <!-- 底部操作栏 -->
    <view class="bottom-bar">
      <view class="draft-btn" @click="handleDraft">暂存</view>
      <view class="submit-btn" :class="{disabled: submitting}" @click="handleSubmit">{{ submitting ? '提交中...' : '提交验收' }}</view>
    </view>

    <!-- 耗材选择弹窗 -->
    <view v-if="showMaterialDialog" class="dialog-mask" @click="showMaterialDialog = false">
      <view class="dialog" @click.stop>
        <view class="dialog-title">添加耗材</view>
        <scroll-view scroll-y class="material-list">
          <view v-for="m in materialOptions" :key="m.id" class="material-option" @click="selectMaterial(m)">
            <view>{{ m.material_name }} <text class="gray">{{ m.specification }}</text></view>
            <view class="gray">库存 {{ m.stock }}{{ m.unit }}</view>
          </view>
        </scroll-view>
        <view class="dialog-footer"><view class="dialog-cancel" @click="showMaterialDialog = false">取消</view></view>
      </view>
    </view>
  </view>
</template>

<script>
import {
  getMaintenanceTaskDetail, startMaintenanceTask,
  draftMaintenance, submitMaintenance, uploadMaintenanceImage,
  getMaintenanceMaterials
} from '../../../api/index.js'

export default {
  data() {
    return {
      taskId: 0,
      detail: {},
      templateItems: [],
      itemResults: {},
      items: [],
      materials: [],
      attachments: [],
      remark: '',
      showMaterialDialog: false,
      materialOptions: [],
      submitting: false,
      started: false
    }
  },
  onLoad(options) {
    this.taskId = Number(options.task_id || 0)
    this.loadDetail()
    this.loadMaterials()
  },
  methods: {
    async loadDetail() {
      try {
        const r = await getMaintenanceTaskDetail(this.taskId)
        if (r.code === 0) {
          this.detail = r.data
          this.templateItems = r.data.template_items || []
        } else {
          uni.showToast({ title: r.msg || '加载失败', icon: 'none' })
        }
      } catch (e) { uni.showToast({ title: '加载失败', icon: 'none' }) }
    },
    async loadMaterials(keyword = '') {
      try { const r = await getMaintenanceMaterials(keyword); if (r.code === 0) this.materialOptions = r.data || [] } catch (e) {}
    },
    getItemResult(idx) { return (this.itemResults[idx] || {}).result || '' },
    setResult(idx, result) {
      if (!this.itemResults[idx]) this.itemResults[idx] = { result: '', description: '', photo: '' }
      this.itemResults[idx].result = result
      if (result === 'normal') { this.itemResults[idx].description = ''; this.itemResults[idx].photo = '' }
      // 同步到 items
      this.syncItems()
    },
    syncItems() {
      this.items = this.templateItems.map((t, idx) => {
        const r = this.itemResults[idx] || {}
        return { item_name: t.item_name, result: r.result || '', description: r.description || '', photo: r.photo || '' }
      })
    },
    async takeAbnormalPhoto(idx) {
      uni.chooseImage({
        count: 1,
        success: async (res) => {
          const path = res.tempFilePaths[0]
          try {
            const up = await uploadMaintenanceImage(path)
            if (up.code === 0 && up.data.url) {
              if (!this.itemResults[idx]) this.itemResults[idx] = { result: '', description: '', photo: '' }
              this.itemResults[idx].photo = up.data.url
            } else { uni.showToast({ title: '上传失败', icon: 'none' }) }
          } catch (e) { uni.showToast({ title: '上传失败', icon: 'none' }) }
        }
      })
    },
    async chooseImage() {
      const remain = 9 - this.attachments.length
      if (remain <= 0) return
      uni.chooseImage({
        count: remain,
        success: async (res) => {
          for (const path of res.tempFilePaths) {
            try {
              const up = await uploadMaintenanceImage(path)
              if (up.code === 0 && up.data.url) this.attachments.push(up.data.url)
              else uni.showToast({ title: '部分图片上传失败', icon: 'none' })
            } catch (e) {}
          }
        }
      })
    },
    previewImage(url) { uni.previewImage({ urls: [url], current: url }) },
    selectMaterial(m) {
      this.materials.push({ material_name: m.material_name, specification: m.specification, unit: m.unit, quantity: 1, id: m.id })
      this.showMaterialDialog = false
    },
    async handleStart() {
      if (this.started) return
      this.started = true
      try { await startMaintenanceTask(this.taskId) } catch (e) {}
    },
    async handleDraft() {
      this.syncItems()
      try {
        // 数组字段由 API 层统一 JSON 序列化传递（form-urlencoded 下 uni 不支持嵌套对象数组）
        const r = await draftMaintenance(this.taskId, { items: this.items, materials: this.materials, remark: this.remark })
        if (r.code === 0) { uni.showToast({ title: '暂存成功', icon: 'success' }); setTimeout(() => uni.navigateBack(), 800) }
        else uni.showToast({ title: r.msg || '暂存失败', icon: 'none' })
      } catch (e) { uni.showToast({ title: '暂存失败', icon: 'none' }) }
    },
    async handleSubmit() {
      // 校验必做项目
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
      this.syncItems()
      this.submitting = true
      try {
        await this.handleStart()
        // 数组字段由 API 层统一 JSON 序列化传递（防止 [object Object]）
        const r = await submitMaintenance(this.taskId, {
          items: this.items, materials: this.materials, attachments: this.attachments, remark: this.remark
        })
        if (r.code === 0) {
          uni.showToast({ title: '提交成功', icon: 'success' })
          setTimeout(() => uni.navigateBack(), 1000)
        } else {
          uni.showToast({ title: r.msg || '提交失败', icon: 'none' })
        }
      } catch (e) { uni.showToast({ title: '提交失败', icon: 'none' }) }
      this.submitting = false
    }
  }
}
</script>

<style scoped>
.execute-page { min-height: 100vh; background: #f5f6fa; padding-bottom: 140rpx; }
.task-info-card { background: #fff; padding: 24rpx; margin: 16rpx; border-radius:16rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.info-row { display: flex; margin-bottom: 12rpx; }
.info-label { width: 140rpx; color: #909399; font-size: 28rpx; }
.info-value { color: #303133; font-size: 28rpx; }
.info-value.gray { color: #909399; }
.info-value.level { color: #409EFF; }
.section { background: #fff; margin: 16rpx; padding: 24rpx; border-radius:16rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.section-title { display: flex; align-items: center; justify-content: space-between; font-size: 30rpx; font-weight: 600; margin-bottom: 16rpx; }
.add-btn { color: #409EFF; font-size: 26rpx; font-weight: normal; }
.item-card { border: 1rpx solid #eee; border-radius:12rpx; padding: 20rpx; margin-bottom: 16rpx; }
.item-header { display: flex; align-items: center; justify-content: space-between; }
.item-name { font-size: 28rpx; font-weight: 600; }
.required { color: #F56C6C; margin-right: 4rpx; }
.item-result { display: flex; gap: 12rpx; }
.result-btn { padding: 8rpx 24rpx; border-radius:24rpx; font-size: 26rpx; }
.result-btn.normal { background: #f0f9eb; color: #67C23A; }
.result-btn.normal.active { background: #67C23A; color: #fff; }
.result-btn.abnormal { background: #fef0f0; color: #F56C6C; }
.result-btn.abnormal.active { background: #F56C6C; color: #fff; }
.item-desc { font-size: 24rpx; color: #909399; margin-top: 8rpx; }
.abnormal-box { margin-top: 12rpx; }
.abnormal-input { width: 100%; height: 100rpx; border: 1rpx solid #F56C6C; border-radius:8rpx; padding: 12rpx; box-sizing: border-box; font-size: 26rpx; }
.abnormal-photo { display: inline-block; background: #fef0f0; color: #F56C6C; padding: 8rpx 20rpx; border-radius:8rpx; font-size: 24rpx; margin-top: 8rpx; }
.abnormal-img { width: 200rpx; height: 150rpx; border-radius:8rpx; margin-top: 8rpx; }
.material-row { display: flex; align-items: center; justify-content: space-between; padding: 12rpx 0; border-bottom: 1rpx solid #f0f0f0; }
.del-btn { color: #F56C6C; font-size: 26rpx; }
.none-text, .gray { color: #909399; font-size: 24rpx; }
.attachment-grid { display: flex; flex-wrap: wrap; gap: 12rpx; }
.attachment-item { width: 160rpx; height: 160rpx; position: relative; }
.attachment-img { width: 100%; height: 100%; border-radius:8rpx; }
.attachment-del { position: absolute; top: -10rpx; right: -10rpx; background: rgba(0,0,0,.5); color: #fff; width: 36rpx; height: 36rpx; text-align: center; line-height: 36rpx; border-radius:50%; font-size: 24rpx; }
.remark-input { width: 100%; height: 120rpx; border: 1rpx solid #eee; border-radius:8rpx; padding: 12rpx; box-sizing: border-box; font-size: 26rpx; }
.bottom-bar { position: fixed; bottom: 0; left: 0; right: 0; display: flex; padding: 16rpx 24rpx; background: #fff; box-shadow: 0 -2rpx 8rpx rgba(0,0,0,.05); }
.draft-btn { flex: 1; text-align: center; padding: 24rpx; border-radius:40rpx; background: #f0f0f0; color: #606266; font-size: 30rpx; margin-right: 16rpx; }
.submit-btn { flex: 2; text-align: center; padding: 24rpx; border-radius:40rpx; background: #409EFF; color: #fff; font-size: 30rpx; }
.submit-btn.disabled { opacity: .6; }
.dialog-mask { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,.5); display: flex; align-items: flex-end; }
.dialog { width: 100%; background: #fff; border-radius:20rpx 20rpx 0 0; max-height: 60vh; padding: 24rpx; box-sizing: border-box;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.dialog-title { font-size: 32rpx; font-weight: 600; margin-bottom: 16rpx; }
.material-list { max-height: 40vh; }
.material-option { padding: 20rpx 0; border-bottom: 1rpx solid #f0f0f0; }
.dialog-footer { padding-top: 16rpx; }
.dialog-cancel { text-align: center; color: #909399; padding: 20rpx; }
</style>
