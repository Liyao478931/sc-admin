<template>
  <view class="rec-detail-page">
    <view class="head-card">
      <view class="head-row">
        <text class="head-code">{{ rec.record_code }}</text>
        <text class="head-result" :class="{abnormal: rec.result === 'abnormal'}">{{ rec.result_text }}</text>
      </view>
      <view class="head-row2">{{ rec.device_name || '未知设备' }} <text class="gray">{{ rec.device_code }}</text></view>
      <view class="head-row3">执行人：{{ rec.executor_name }} · {{ rec.execute_time }}</view>
      <view class="head-row3">审核状态：<text :class="'au-' + rec.audit_status">{{ rec.audit_status_text }}</text></view>
    </view>

    <view class="section">
      <view class="section-title">检查结果（{{ rec.total_count || 0 }} 项）</view>
      <view v-for="(it, idx) in itemList" :key="idx" class="item-card">
        <view class="item-head">
          <text class="item-name">{{ it.item_name || it.name || ('检查项' + (idx + 1)) }}</text>
          <text class="item-result" :class="{abnormal: it.result === 'abnormal'}">{{ it.result === 'abnormal' ? '异常' : '正常' }}</text>
        </view>
        <view v-if="it.desc || it.description" class="item-desc">{{ it.desc || it.description }}</view>
        <image v-if="it.photo" :src="imgUrl(it.photo)" class="item-photo" mode="aspectFill" @click="preview(it.photo)" />
      </view>
    </view>

    <view v-if="rec.remark" class="section">
      <view class="section-title">备注</view>
      <view class="remark-box">{{ rec.remark }}</view>
    </view>

    <view v-if="rec.audit_remark" class="section">
      <view class="section-title">审核意见</view>
      <view class="remark-box">{{ rec.audit_remark }}</view>
    </view>
  </view>
</template>

<script>
import { getInspectionRecordDetail } from '../../../api/index.js'

export default {
  data() {
    return { recordId: 0, rec: {}, itemList: [] }
  },
  onLoad(options) {
    this.recordId = Number(options.record_id || 0)
    this.load()
  },
  methods: {
    imgUrl(val) {
      if (!val) return ''
      if (val.startsWith('http://') || val.startsWith('https://')) return val
      if (val.startsWith('/')) return uni.$base + val
      return val
    },
    async load() {
      try {
        const r = await getInspectionRecordDetail(this.recordId)
        if (r.code === 0) {
          this.rec = r.data
          this.itemList = (r.data && r.data.items) || []
        } else {
          uni.showToast({ title: r.msg || '加载失败', icon: 'none' })
        }
      } catch (e) { uni.showToast({ title: '加载失败', icon: 'none' }) }
    },
    preview(url) { uni.previewImage({ urls: [url], current: url }) }
  }
}
</script>

<style scoped>
.rec-detail-page { min-height: 100vh; background: #F4F6FB; padding: 12px 16px 30px; box-sizing: border-box; }
.head-card { background: #fff; border-radius: 16px; padding: 16px; }
.head-row { display: flex; align-items: center; justify-content: space-between; }
.head-code { font-size: 16px; font-weight: 700; color: #1a2332; }
.head-result { font-size: 12px; font-weight: 600; color: #1f9d55; background: #eafaf0; padding: 3px 14px; border-radius: 20px; }
.head-result.abnormal { color: #e74c5e; background: #fdecea; }
.head-row2 { font-size: 14px; color: #4a5568; margin-top: 10px; }
.head-row3 { font-size: 12px; color: #9ca3af; margin-top: 6px; }
.gray { font-size: 12px; color: #9ca3af; }
.au-pending { color: #f59e0b; }
.au-approved { color: #1f9d55; }
.au-rejected { color: #e74c5e; }
.section { margin-top: 14px; }
.section-title { font-size: 15px; font-weight: 700; color: #1a2332; margin-bottom: 10px; }
.item-card { background: #fff; border-radius: 14px; padding: 12px 14px; margin-bottom: 8px; }
.item-head { display: flex; align-items: center; justify-content: space-between; }
.item-name { font-size: 14px; font-weight: 600; color: #1a2332; }
.item-result { font-size: 12px; font-weight: 600; color: #1f9d55; }
.item-result.abnormal { color: #e74c5e; }
.item-desc { font-size: 13px; color: #6b7280; margin-top: 6px; }
.item-photo { width: 160px; height: 160px; border-radius: 12px; margin-top: 8px; }
.remark-box { background: #fff; border-radius: 14px; padding: 12px 14px; font-size: 13px; color: #4a5568; }
</style>
