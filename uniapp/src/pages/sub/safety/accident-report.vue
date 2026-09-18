<template>
  <view class="accident-report-page">
    <!-- 表单 -->
    <scroll-view class="form-scroll" scroll-y>
      <view class="form-card">
        <view class="form-item">
          <view class="label">事故名称 <text class="req">*</text></view>
          <u-input v-model="form.accident_name" placeholder="请输入事故名称" border="none" maxlength="100" :customStyle="{ height: '80rpx', fontSize: '28rpx' }" />
        </view>
        <view class="form-item">
          <view class="label">事故类型 <text class="req">*</text></view>
          <picker :range="typeLabels" @change="onTypeChange">
            <view class="picker" :class="{ placeholder: !form.accident_type }">{{ typeText || '请选择事故类型' }}</view>
          </picker>
        </view>
        <view class="form-item">
          <view class="label">事故等级 <text class="req">*</text></view>
          <picker :range="levelLabels" @change="onLevelChange">
            <view class="picker" :class="{ placeholder: !form.accident_level }">{{ levelText || '请选择事故等级' }}</view>
          </picker>
        </view>
        <view class="form-item">
          <view class="label">发生时间 <text class="req">*</text></view>
          <picker mode="date" :value="form.happen_time" @change="onDateChange">
            <view class="picker">{{ form.happen_time || '请选择发生日期' }}</view>
          </picker>
        </view>
        <view class="form-item">
          <view class="label">发生地点 <text class="req">*</text></view>
          <view class="location-row">
            <u-input v-model="form.happen_location" placeholder="请输入发生地点" border="none" maxlength="200" :customStyle="{ height: '80rpx', fontSize: '28rpx' }" />
            <view class="loc-btn" @click="getLocation">定位</view>
          </view>
        </view>
        <view class="form-item">
          <view class="label">发生部门 <text class="req">*</text></view>
          <picker :range="deptNames" @change="onDeptChange">
            <view class="picker" :class="{ placeholder: !form.happen_department_id }">{{ deptText || '请选择发生部门' }}</view>
          </picker>
        </view>
        <view class="form-item">
          <view class="label">事故经过 <text class="req">*</text></view>
          <u-textarea v-model="form.accident_process" placeholder="请详细描述事故经过（至少20字）" maxlength="1000" />
          <view class="count">{{ form.accident_process.length }}/1000</view>
        </view>

        <view class="form-item">
          <view class="label">伤亡情况</view>
          <view class="num-row">
            <view class="num-col"><view class="num-label">死亡</view><u-input v-model.number="form.death_count" type="number" border="none" :customStyle="{ height: '72rpx', fontSize: '28rpx' }" /></view>
            <view class="num-col"><view class="num-label">重伤</view><u-input v-model.number="form.serious_injury_count" type="number" border="none" :customStyle="{ height: '72rpx', fontSize: '28rpx' }" /></view>
            <view class="num-col"><view class="num-label">轻伤</view><u-input v-model.number="form.minor_injury_count" type="number" border="none" :customStyle="{ height: '72rpx', fontSize: '28rpx' }" /></view>
          </view>
        </view>
        <view class="form-item">
          <view class="label">经济损失（万元）</view>
          <u-input v-model="form.economic_loss" type="number" placeholder="0.00" border="none" :customStyle="{ height: '80rpx', fontSize: '28rpx' }" />
        </view>

        <view class="form-item">
          <view class="label">现场照片（最多9张）</view>
          <view class="img-grid">
            <view v-for="(img, i) in images" :key="i" class="img-cell">
              <image :src="img" class="img" mode="aspectFill" @click="preview(i)" />
              <view class="img-del" @click="images.splice(i, 1)">×</view>
            </view>
            <view v-if="images.length < 9" class="img-add" @click="chooseImage">
              <text class="add-icon">+</text>
            </view>
          </view>
        </view>
        <view class="form-item">
          <view class="label">备注</view>
          <u-textarea v-model="form.remark" placeholder="选填" maxlength="500" />
        </view>
      </view>
    </scroll-view>

    <!-- 底部操作 -->
    <view class="bottom-bar">
      <view class="btn draft" @click="saveDraft">暂存</view>
      <view class="btn submit" @click="submit">提交</view>
    </view>
  </view>
</template>

<script>
import { getAccidentTypes, getAccidentLevels, getAccidentDepartments, reportAccident, draftAccident, uploadAccidentImage } from '@/api/modules/safety.js'

export default {
  data() {
    return {
      typeOptions: [], levelOptions: [], deptOptions: [],
      images: [], uploading: false, submitting: false,
      form: {
        accident_name: '', accident_type: '', accident_level: '',
        happen_time: this.formatNow(), happen_location: '', happen_department_id: 0,
        accident_process: '', death_count: 0, serious_injury_count: 0, minor_injury_count: 0,
        economic_loss: 0, remark: '',
      },
    }
  },
  computed: {
    typeLabels() { return this.typeOptions.map(x => x.label) },
    levelLabels() { return this.levelOptions.map(x => x.label) },
    deptNames() { return this.deptOptions.map(x => x.name) },
    typeText() { const t = this.typeOptions.find(x => x.value === this.form.accident_type); return t ? t.label : '' },
    levelText() { const l = this.levelOptions.find(x => x.value === this.form.accident_level); return l ? l.label : '' },
    deptText() { const d = this.deptOptions.find(x => x.id === this.form.happen_department_id); return d ? d.name : '' },
  },
  onLoad() { this.loadOptions() },
  methods: {
    formatNow() {
      const d = new Date()
      const p = (n) => String(n).padStart(2, '0')
      return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}:${p(d.getSeconds())}`
    },
    async loadOptions() {
      try {
        const [t, l, d] = await Promise.all([getAccidentTypes(), getAccidentLevels(), getAccidentDepartments()])
        this.typeOptions = t.data || []
        this.levelOptions = l.data || []
        this.deptOptions = d.data || []
      } catch (e) {}
    },
    onTypeChange(e) { this.form.accident_type = this.typeOptions[Number(e.detail.value)].value },
    onLevelChange(e) { this.form.accident_level = this.levelOptions[Number(e.detail.value)].value },
    onDateChange(e) { this.form.happen_time = e.detail.value + ' ' + this.form.happen_time.split(' ')[1] || '' },
    onDeptChange(e) { this.form.happen_department_id = this.deptOptions[Number(e.detail.value)].id },
    getLocation() {
      uni.showLoading({ title: '定位中...' })
      uni.getLocation({
        type: 'wgs84',
        success: (res) => {
          uni.hideLoading()
          this.form.happen_location = `经度${res.longitude.toFixed(6)}，纬度${res.latitude.toFixed(6)}`
          uni.showToast({ title: '定位成功，请核对地点', icon: 'none' })
        },
        fail: () => {
          uni.hideLoading()
          uni.showToast({ title: '定位失败，请手动输入地点', icon: 'none' })
        },
      })
    },
    chooseImage() {
      uni.chooseImage({
        count: 9 - this.images.length,
        sizeType: ['compressed'],
        success: async (res) => {
          for (const path of res.tempFilePaths) {
            if (this.images.length >= 9) break
            this.uploading = true
            try {
              const r = await uploadAccidentImage(path)
              if (r.code === 0 && r.data && r.data.url) this.images.push(r.data.url)
              else uni.showToast({ title: r.msg || '上传失败', icon: 'none' })
            } catch (e) { uni.showToast({ title: '上传失败', icon: 'none' }) }
            this.uploading = false
          }
        },
      })
    },
    preview(i) {
      uni.previewImage({ urls: this.images, current: this.images[i] })
    },
    validate() {
      const f = this.form
      const nl = f.accident_name.trim().length
      if (nl < 2 || nl > 100) return '事故名称需2-100字符'
      if (!f.accident_type) return '请选择事故类型'
      if (!f.accident_level) return '请选择事故等级'
      if (!f.happen_time) return '请选择发生时间'
      if (new Date(f.happen_time.replace(/-/g, '/')).getTime() > Date.now() + 60000) return '发生时间不能晚于当前时间'
      const ll = f.happen_location.trim().length
      if (ll < 2 || ll > 200) return '发生地点需2-200字符'
      if (!f.happen_department_id) return '请选择发生部门'
      const pl = f.accident_process.trim().length
      if (pl < 20 || pl > 1000) return '事故经过需20-1000字符'
      return ''
    },
    buildPayload() {
      return {
        accident_name: this.form.accident_name.trim(),
        accident_type: this.form.accident_type,
        accident_level: this.form.accident_level,
        happen_time: this.form.happen_time,
        happen_location: this.form.happen_location.trim(),
        happen_department_id: this.form.happen_department_id,
        accident_process: this.form.accident_process.trim(),
        death_count: Number(this.form.death_count) || 0,
        serious_injury_count: Number(this.form.serious_injury_count) || 0,
        minor_injury_count: Number(this.form.minor_injury_count) || 0,
        economic_loss: Number(this.form.economic_loss) || 0,
        images: this.images,
        remark: this.form.remark.trim(),
      }
    },
    async submit() {
      if (this.submitting || this.uploading) return
      const msg = this.validate()
      if (msg) { uni.showToast({ title: msg, icon: 'none' }); return }
      this.submitting = true
      uni.showLoading({ title: '提交中...' })
      try {
        const r = await reportAccident(this.buildPayload())
        uni.hideLoading()
        if (r.code === 0) {
          uni.showToast({ title: '事故上报成功，等待安全部门处理', icon: 'none' })
          setTimeout(() => uni.redirectTo({ url: '/pages/sub/safety/accident-list' }), 1200)
        }
      } catch (e) { uni.hideLoading() }
      this.submitting = false
    },
    async saveDraft() {
      if (!this.form.accident_name.trim()) { uni.showToast({ title: '请填写事故名称', icon: 'none' }); return }
      if (this.form.accident_name.length > 100) { uni.showToast({ title: '事故名称最长100字符', icon: 'none' }); return }
      try {
        const r = await draftAccident(this.buildPayload())
        if (r.code === 0) {
          uni.showToast({ title: '草稿已保存', icon: 'none' })
          setTimeout(() => uni.redirectTo({ url: '/pages/sub/safety/accident-list' }), 1000)
        }
      } catch (e) {}
    },
  },
}
</script>

<style scoped>
.accident-report-page { min-height: 100vh; background: #f5f6fa; padding-bottom: 140rpx; box-sizing: border-box; }
.form-scroll { padding: 24rpx; box-sizing: border-box; }
.form-card { background: #fff; border-radius:16rpx; padding: 24rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.form-item { margin-bottom: 28rpx; }
.label { font-size: 28rpx; color: #303133; margin-bottom: 12rpx; }
.req { color: #F56C6C; }
.input { font-size: 28rpx; color: #303133; background: #F4F6FB; border-radius:10rpx; padding: 18rpx 20rpx; }
.textarea { width: 100%; min-height: 160rpx; font-size: 28rpx; background: #F4F6FB; border-radius:10rpx; padding: 18rpx; box-sizing: border-box; }
.count { text-align: right; font-size: 22rpx; color: #909399; margin-top: 6rpx; }
.picker { font-size: 28rpx; color: #303133; background: #F4F6FB; border-radius:10rpx; padding: 18rpx 20rpx; }
.picker.placeholder { color: #c0c4cc; }
.location-row { display: flex; gap: 12rpx; }
.location-row .input { flex: 1; }
.loc-btn { width: 110rpx; text-align: center; background: #409EFF; color: #fff; font-size: 26rpx; border-radius:10rpx; display: flex; align-items: center; justify-content: center; }
.num-row { display: flex; gap: 16rpx; }
.num-col { flex: 1; }
.num-label { font-size: 24rpx; color: #909399; margin-bottom: 8rpx; }
.num-input { font-size: 28rpx; background: #F4F6FB; border-radius:10rpx; padding: 14rpx 16rpx; text-align: center; }
.img-grid { display: flex; flex-wrap: wrap; gap: 14rpx; }
.img-cell { width: 150rpx; height: 150rpx; position: relative; }
.img { width: 150rpx; height: 150rpx; border-radius:10rpx; }
.img-del { position: absolute; top: -12rpx; right: -12rpx; width: 40rpx; height: 40rpx; background: rgba(0,0,0,.6); color: #fff; border-radius:50%; text-align: center; line-height: 40rpx; font-size: 28rpx; }
.img-add { width: 150rpx; height: 150rpx; border: 2rpx dashed #c0c4cc; border-radius:10rpx; display: flex; align-items: center; justify-content: center; background: #F4F6FB; }
.add-icon { font-size: 60rpx; color: #c0c4cc; }
.bottom-bar { position: fixed; left: 0; right: 0; bottom: 0; display: flex; padding: 20rpx 24rpx calc(20rpx + env(safe-area-inset-bottom)); background: #fff; }
.btn { flex: 1; text-align: center; font-size: 30rpx; padding: 22rpx 0; border-radius:40rpx; margin: 0 10rpx; }
.btn.draft { background: #f4f4f5; color: #606266; }
.btn.submit { background: #F56C6C; color: #fff; }
</style>
