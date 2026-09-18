<template>
  <view class="training-detail-page">
    <!-- 培训信息卡片 -->
    <view class="info-card">
      <view class="info-row"><text class="info-label">培训名称</text><text class="info-value">{{ detail.plan_name }}</text></view>
      <view class="info-row"><text class="info-label">培训类型</text><text class="info-value">{{ detail.training_type_name }}</text></view>
      <view class="info-row"><text class="info-label">培训方式</text><text class="info-value level">{{ detail.mode_text }}</text></view>
      <view class="info-row"><text class="info-label">培训日期</text><text class="info-value">{{ detail.training_date || '-' }}</text></view>
      <view v-if="detail.is_online !== 1" class="info-row"><text class="info-label">培训地点</text><text class="info-value">{{ detail.location || '-' }}</text></view>
      <view v-if="detail.is_online !== 1" class="info-row"><text class="info-label">签到地点</text><text class="info-value">{{ detail.checkin_location || '-' }}</text></view>
      <view v-if="detail.is_online !== 1" class="info-row"><text class="info-label">签到范围</text><text class="info-value">{{ detail.checkin_radius || 100 }} 米</text></view>
      <view v-if="detail.content" class="info-row"><text class="info-label">培训内容</text><text class="info-value">{{ detail.content }}</text></view>
    </view>

    <!-- ===== 线上培训：课件学习 ===== -->
    <template v-if="detail.is_online === 1">
      <view class="section">
        <view class="section-title">
          <text>学习进度</text>
          <text class="progress-num">{{ detail.overall_progress || 0 }}%</text>
        </view>
        <view class="progress-bar"><view class="progress-inner" :style="{width: (detail.overall_progress || 0) + '%'}"></view></view>
        <view v-if="detail.my_status && detail.my_status.is_trained === 1" class="trained-tip"><MIcon name="check" :size="14" color="#059669" /><text style="margin-left:4px">培训已完成（{{ detail.my_status.complete_time }}）</text></view>
      </view>

      <view class="section">
        <view class="section-title">培训课件（{{ (detail.coursewares || []).length }}）</view>
        <view v-for="(cw, idx) in detail.coursewares" :key="cw.id" class="cw-card">
          <view class="cw-head">
            <text class="cw-name">{{ cw.courseware_name }}</text>
            <text class="cw-tag" :class="cw.watch_status">{{ watchStatusText(cw.watch_status) }}</text>
          </view>
          <view v-if="cw.file_type === 'video'" class="video-box">
            <video v-if="playingCw === cw.id" :src="fileUrl(cw.file_path)" class="video-player" controls @timeupdate="e => onVideoTime(e, cw)" @ended="onVideoEnded(cw)" @error="() => showVideoError()" />
            <view v-else class="video-placeholder" @click="playVideo(cw)">▶ 点击播放视频</view>
          </view>
          <view v-else class="preview-row">
            <text class="preview-btn" @click="previewCw(cw)">预览课件</text>
          </view>
          <view class="cw-progress">
            <view class="progress-bar small"><view class="progress-inner" :style="{width: (cw.watch_percent || 0) + '%'}"></view></view>
            <text class="cw-percent">{{ cw.watch_percent || 0 }}%</text>
          </view>
        </view>
        <view v-if="!(detail.coursewares || []).length" class="empty">暂无课件</view>
      </view>

      <!-- 完成培训 -->
      <view class="bottom-bar">
        <button class="submit-btn" :class="{disabled: (detail.overall_progress || 0) < 100 || detail.my_status && detail.my_status.is_trained === 1}" @click="completeOnline">
          {{ detail.my_status && detail.my_status.is_trained === 1 ? '已完成' : '完成培训' }}
        </button>
      </view>
    </template>

    <!-- ===== 线下培训：签到 ===== -->
    <template v-else>
      <view class="section">
        <view class="section-title">签到状态</view>
        <view class="checkin-status">
          <view v-if="detail.my_status && detail.my_status.checkin_status === 'signed'" class="signed" style="display:flex;align-items:center"><MIcon name="check" :size="13" color="#059669" /><text style="margin-left:4px">已签到</text></view>
          <text v-else class="unsigned">未签到</text>
        </view>
        <view v-if="detail.my_status && detail.my_status.checkin_status === 'signed'" class="checkin-info">
          <view>签到时间：{{ detail.my_status.checkin_time }}</view>
          <view v-if="detail.my_status.checkin_address">签到地点：{{ detail.my_status.checkin_address }}</view>
          <view v-if="detail.my_status.checkin_deviation != null">偏差距离：{{ detail.my_status.checkin_deviation }} 米</view>
        </view>
        <view v-else-if="detail.status === 'completed'" class="checkin-info">该培训已结束</view>
      </view>

      <!-- 签到按钮 -->
      <view class="bottom-bar">
        <button v-if="detail.status !== 'completed' && !(detail.my_status && detail.my_status.checkin_status === 'signed')" class="submit-btn" :disabled="signing" @click="doCheckin">{{ signing ? '签到中...' : '签到' }}</button>
        <button v-else class="submit-btn disabled">已签到</button>
      </view>
    </template>
  </view>
</template>

<script>
import { getTrainingDetail, updateWatchProgress, completeOnlineTraining, offlineCheckin } from '../../../api/index.js'

export default {
  data() {
    return {
      recordId: 0,
      detail: {},
      playingCw: 0,
      lastReport: 0,
      signing: false,
      loaded: false
    }
  },
  onLoad(options) {
    this.recordId = Number(options.record_id || 0)
    this.loadDetail()
  },
  onUnload() { this.loaded = false },
  methods: {
    async loadDetail() {
      try {
        const r = await getTrainingDetail(this.recordId)
        if (r.code === 0) this.detail = r.data || {}
        else uni.showToast({ title: r.msg || '加载失败', icon: 'none' })
      } catch (e) { uni.showToast({ title: '加载失败', icon: 'none' }) }
    },
    watchStatusText(s) { return { pending: '未开始', watching: '观看中', completed: '已完成' }[s] || '未开始' },
    fileUrl(p) {
      if (!p) return ''
      return p.startsWith('http') ? p : uni.$base + p
    },
    playVideo(cw) { this.playingCw = cw.id },
    showVideoError() { uni.showToast({ title: '视频播放失败', icon: 'none' }) },
    // 视频播放进度上报（节流 3 秒）
    onVideoTime(e, cw) {
      const ctx = e.detail || e
      const current = ctx.currentTime || 0
      const duration = ctx.duration || 0
      if (!duration) return
      const percent = Math.min(100, Math.round(current / duration * 100))
      const now = Date.now()
      if (now - this.lastReport < 3000) return
      this.lastReport = now
      this.reportProgress(cw, Math.round(current), Math.round(duration), percent)
    },
    onVideoEnded(cw) { this.reportProgress(cw, 9999, 100, 100) },
    async reportProgress(cw, watchDuration, totalDuration, percent) {
      try {
        const r = await updateWatchProgress(this.recordId, cw.id, { watch_duration: watchDuration, total_duration: totalDuration, watch_percent: percent })
        if (r.code === 0) {
          cw.watch_percent = r.data.watch_percent
          cw.watch_status = percent >= 100 ? 'completed' : 'watching'
          this.detail.overall_progress = r.data.overall_progress
        }
      } catch (e) {}
    },
    previewCw(cw) {
      // PDF 用 web-view 打开；其他格式提示
      if (cw.file_type === 'pdf') {
        uni.navigateTo({ url: '/pages/sub/safety/courseware-preview?url=' + encodeURIComponent(this.fileUrl(cw.file_path)) })
      } else {
        uni.showToast({ title: '该格式暂不支持在线预览', icon: 'none' })
      }
    },
    async completeOnline() {
      const my = this.detail.my_status || {}
      if (my.is_trained === 1) return
      if ((this.detail.overall_progress || 0) < 100) { uni.showToast({ title: '请先完成所有课件学习', icon: 'none' }); return }
      uni.showModal({
        title: '确认完成',
        content: '确认已完成全部课件学习？',
        success: async (res) => {
          if (!res.confirm) return
          try {
            const r = await completeOnlineTraining(this.recordId)
            if (r.code === 0) { uni.showToast({ title: '培训已完成', icon: 'success' }); this.loadDetail(); setTimeout(() => uni.navigateBack(), 800) }
            else uni.showToast({ title: r.msg || '操作失败', icon: 'none' })
          } catch (e) { uni.showToast({ title: '操作失败', icon: 'none' }) }
        }
      })
    },
    async doCheckin() {
      uni.showModal({
        title: '签到确认',
        content: '将获取您当前 GPS 位置进行签到，请允许定位权限。',
        success: async (res) => {
          if (!res.confirm) return
          this.signing = true
          try {
            const pos = await this.getLocation()
            const r = await offlineCheckin(this.recordId, pos.lat, pos.lng, '')
            if (r.code === 0) { uni.showToast({ title: '签到成功', icon: 'success' }); this.loadDetail() }
            else uni.showToast({ title: r.msg || '签到失败', icon: 'none' })
          } catch (e) { uni.showToast({ title: (e && e.message) || '签到失败', icon: 'none' }) }
          this.signing = false
        }
      })
    },
    /** WGS-84 转 GCJ-02（火星坐标）——H5 端 uni.getLocation 固定返回 WGS-84，需手动转换 */
    wgs84ToGcj02(lng, lat) {
      const PI = 3.1415926535897932384626
      const a = 6378245.0
      const ee = 0.00669342162296594323
      if (lng < 72.004 || lng > 137.8347 || lat < 0.8293 || lat > 55.8271) return { lng, lat }
      const tLat = (x, y) => {
        let r = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * Math.sqrt(Math.abs(x))
        r += (20.0 * Math.sin(6.0 * x * PI) + 20.0 * Math.sin(2.0 * x * PI)) * 2.0 / 3.0
        r += (20.0 * Math.sin(y * PI) + 40.0 * Math.sin(y / 3.0 * PI)) * 2.0 / 3.0
        r += (160.0 * Math.sin(y / 12.0 * PI) + 320 * Math.sin(y * PI / 30.0)) * 2.0 / 3.0
        return r
      }
      const tLng = (x, y) => {
        let r = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * Math.sqrt(Math.abs(x))
        r += (20.0 * Math.sin(6.0 * x * PI) + 20.0 * Math.sin(2.0 * x * PI)) * 2.0 / 3.0
        r += (20.0 * Math.sin(x * PI) + 40.0 * Math.sin(x / 3.0 * PI)) * 2.0 / 3.0
        r += (150.0 * Math.sin(x / 12.0 * PI) + 300.0 * Math.sin(x / 30.0 * PI)) * 2.0 / 3.0
        return r
      }
      let dLat = tLat(lng - 105.0, lat - 35.0)
      let dLng = tLng(lng - 105.0, lat - 35.0)
      const radLat = lat / 180.0 * PI
      let magic = Math.sin(radLat)
      magic = 1 - ee * magic * magic
      const sqrtMagic = Math.sqrt(magic)
      dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * PI)
      dLng = (dLng * 180.0) / (a / sqrtMagic * Math.cos(radLat) * PI)
      return { lng: lng + dLng, lat: lat + dLat }
    },
    getLocation() {
      return new Promise((resolve, reject) => {
        if (!uni.getLocation) { reject(new Error('当前环境不支持定位')); return }
        uni.getLocation({
          type: 'gcj02',
          success: (res) => {
            // H5 端 type 不生效返回 WGS-84，手动转换为 GCJ-02 与后台签到地点统一
            const g = this.wgs84ToGcj02(res.longitude, res.latitude)
            resolve({ lat: g.lat, lng: g.lng })
          },
          fail: () => reject(new Error('定位失败，请开启定位权限')),
          timeout: 10000
        })
      })
    }
  }
}
</script>

<style scoped>
.training-detail-page { min-height: 100vh; background: #f5f6fa; padding-bottom: 140rpx; }
.info-card { background: #fff; padding: 24rpx; margin: 16rpx; border-radius:16rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.info-row { display: flex; margin-bottom: 12rpx; }
.info-label { width: 150rpx; color: #909399; font-size: 28rpx; flex-shrink: 0; }
.info-value { color: #303133; font-size: 28rpx; flex: 1; }
.info-value.level { color: #409EFF; }
.section { background: #fff; margin: 16rpx; padding: 24rpx; border-radius:16rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.section-title { display: flex; align-items: center; justify-content: space-between; font-size: 30rpx; font-weight: 600; margin-bottom: 16rpx; }
.progress-num { font-size: 26rpx; color: #409EFF; font-weight: 600; }
.progress-bar { height: 14rpx; background: #eef0f4; border-radius:8rpx; overflow: hidden; }
.progress-bar.small { flex: 1; height: 12rpx; }
.progress-inner { height: 100%; background: #409EFF; border-radius:8rpx; transition: width .3s; }
.trained-tip { margin-top: 16rpx; color: #67C23A; font-size: 26rpx; text-align: center; }
.cw-card { border: 1rpx solid #eee; border-radius:12rpx; padding: 20rpx; margin-bottom: 16rpx; }
.cw-head { display: flex; align-items: center; justify-content: space-between; }
.cw-name { font-size: 28rpx; font-weight: 600; flex: 1; }
.cw-tag { font-size: 22rpx; padding: 4rpx 12rpx; border-radius:8rpx; }
.cw-tag.pending { background: #f4f4f5; color: #909399; }
.cw-tag.watching { background: #fdf6ec; color: #E6A23C; }
.cw-tag.completed { background: #f0f9eb; color: #67C23A; }
.video-box { margin-top: 16rpx; }
.video-player { width: 100%; height: 320rpx; border-radius:8rpx; }
.video-placeholder { height: 160rpx; background: #F4F6FB; border-radius:8rpx; display: flex; align-items: center; justify-content: center; color: #409EFF; font-size: 28rpx; margin-top: 16rpx; }
.preview-row { margin-top: 16rpx; }
.preview-btn { color: #409EFF; font-size: 26rpx; }
.cw-progress { display: flex; align-items: center; gap: 12rpx; margin-top: 16rpx; }
.cw-percent { font-size: 24rpx; color: #909399; }
.checkin-status { text-align: center; padding: 30rpx 0; }
.checkin-status .signed { color: #67C23A; font-size: 32rpx; font-weight: 600; }
.checkin-status .unsigned { color: #909399; font-size: 30rpx; }
.checkin-info { font-size: 26rpx; color: #606266; line-height: 1.8; }
.empty { text-align: center; color: #909399; font-size: 26rpx; padding: 30rpx 0; }
.bottom-bar { position: fixed; bottom: 0; left: 0; right: 0; padding: 16rpx 24rpx; background: #fff; box-shadow: 0 -2rpx 8rpx rgba(0,0,0,.05); }
.submit-btn { width: 100%; padding: 24rpx; border-radius:40rpx; background: #409EFF; color: #fff; font-size: 30rpx; }
.submit-btn.disabled { opacity: .6; }
</style>
