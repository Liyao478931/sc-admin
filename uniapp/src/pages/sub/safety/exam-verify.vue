<template>
  <view class="ev-page">
    <!-- 步骤一：身份证后6位校验 -->
    <view v-if="step === 1" class="ev-id-step">
      <view class="ev-header">
        <text class="ev-title">实名验证</text>
        <text class="ev-sub">为确保本人参加考试，请先完成身份核验</text>
      </view>

      <view class="ev-card">
        <view class="ev-steps">
          <view class="ev-step active">
            <text class="ev-step-num">1</text>
            <text class="ev-step-label">身份证验证</text>
          </view>
          <view class="ev-step-line"></view>
          <view class="ev-step">
            <text class="ev-step-num">2</text>
            <text class="ev-step-label">人脸识别</text>
          </view>
        </view>

        <view class="ev-form">
          <text class="ev-label">请输入身份证后 6 位</text>
          <view class="ev-code-wrap">
            <view class="ev-code-cell" :class="{ filled: codeArr[idx] }" v-for="(c, idx) in 6" :key="idx">
              <!-- #ifdef MP-WEIXIN -->
              <!-- 小程序：idcard 键盘（数字 + X） -->
              <input
                class="ev-code-input"
                type="idcard"
                :maxlength="1"
                :value="codeArr[idx] || ''"
                :focus="focusIdx === idx"
                @input="onCodeInput(idx, $event)"
                @focus="focusIdx = idx"
              />
              <!-- #endif -->
              <!-- #ifndef MP-WEIXIN -->
              <!-- H5/App：number 数字键盘（浏览器无数字+X 键盘，X 由过滤逻辑保留供桌面输入） -->
              <input
                class="ev-code-input"
                type="number"
                :maxlength="1"
                :value="codeArr[idx] || ''"
                :focus="focusIdx === idx"
                @input="onCodeInput(idx, $event)"
                @focus="focusIdx = idx"
                @keyup.backspace="onCodeBack(idx)"
              />
              <!-- #endif -->
            </view>
          </view>
          <text v-if="idError" class="ev-error">{{ idError }}</text>
          <view class="ev-btn primary" :class="{ disabled: idLoading }" @click="submitId">
            {{ idLoading ? '校验中...' : '确认' }}
          </view>
          <view class="ev-tip">身份证信息由员工档案维护，仅用于考试实名核验</view>
        </view>
      </view>
    </view>

    <!-- 步骤二：人脸识别 -->
    <view v-else class="ev-face-step">
      <!-- 摄像头预览 -->
      <!-- #ifdef MP-WEIXIN -->
      <camera v-if="cameraReady" :key="cameraKey" class="ev-camera" device-position="front" flash="off" frame-size="medium" @error="onCameraError" @initdone="onCameraReady"></camera>
      <!-- #endif -->
      <!-- #ifdef H5 -->
      <view class="ev-camera-h5" id="ev-camera-container">
        <view v-if="!h5Ready" class="ev-camera-empty"><text class="ev-empty-tip">摄像头启动中...</text></view>
      </view>
      <!-- #endif -->

      <!-- 顶部信息 -->
      <view class="ev-face-header">
        <view class="ev-face-title">
          <text class="ev-face-name">人脸识别</text>
          <text class="ev-face-desc">请确保是本人，面向镜头</text>
        </view>
        <view class="ev-face-back" @click="backToId">上一步</view>
      </view>

      <!-- 圆形取景框 -->
      <view class="ev-mask">
        <view class="ev-circle" :class="{ recognizing: isRecognizing, success: isSuccess }">
          <view v-if="isRecognizing" class="ev-loading-ring"></view>
          <view v-if="isSuccess" class="ev-success-icon"><MIcon name="check" :size="40" color="#ffffff" :weight="2.4" /></view>w>
        </view>
      </view>

      <!-- 提示 -->
      <view class="ev-hint">
        <text class="ev-hint-text" :class="{ 'hint-success': isSuccess, 'hint-fail': status === 'fail' }">{{ hintText }}</text>
      </view>

      <!-- 错误降级 -->
      <view v-if="status === 'error'" class="ev-error-box">
        <text class="ev-error-text">{{ hintText }}</text>
        <view class="ev-error-btn" @click="backToId">返回</view>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { post, BASE_URL } from '@/utils/request'
import { startExam } from '@/api/modules/safety.js'

const examId = ref(0)

// ===== 步骤一：身份证后6位 =====
const step = ref(1)
const codeArr = ref(['', '', '', '', '', ''])
const focusIdx = ref(0)
const idError = ref('')
const idLoading = ref(false)
const ID_MAX_RETRY = 3
let idRetryCount = 0

onLoad((options) => {
  examId.value = Number(options.exam_id || 0)
})

// 单格输入：过滤只允许数字与 X，自动跳到下一格
function onCodeInput(idx, e) {
  let v = (e.detail && e.detail.value) || ''
  v = v.toUpperCase().replace(/[^0-9X]/g, '').slice(0, 1)
  codeArr.value[idx] = v
  if (v && idx < 5) focusIdx.value = idx + 1
  if (idError.value) idError.value = ''
}

// 退格回退（H5 键盘；小程序端可点击格子聚焦）
function onCodeBack(idx) {
  if (!codeArr.value[idx] && idx > 0) focusIdx.value = idx - 1
}

async function submitId() {
  if (idLoading.value) return
  const val = codeArr.value.join('')
  if (!/^[0-9Xx]{6}$/.test(val)) {
    idError.value = '请输入6位身份证后6位（数字，末位可为X）'
    return
  }
  idLoading.value = true
  idError.value = ''
  try {
    const r = await post('/api/mobile/safety/exam/verify-id', { exam_id: examId.value, id_card_last6: val })
    if (r.code === 0) {
      step.value = 2
      // 等步骤二 DOM 渲染后再启动摄像头
      nextTick(() => startCamera())
    } else {
      idRetryCount++
      idError.value = (r.msg || '身份证校验不通过')
      if (idRetryCount >= ID_MAX_RETRY) {
        uni.showToast({ title: '连续校验失败，请返回重试', icon: 'none' })
        setTimeout(() => uni.navigateBack(), 1200)
      }
    }
  } catch (e) {
    idError.value = '网络异常，请重试'
  }
  idLoading.value = false
}

function backToId() {
  stopDetection()
  stopStream()
  if (initFallbackTimer) { clearTimeout(initFallbackTimer); initFallbackTimer = null }
  initFailCount = 0
  step.value = 1
}

// ===== 步骤二：人脸识别（复用考勤人脸采集逻辑） =====
const status = ref('init')
const hintText = ref('摄像头启动中...')
const isRecognizing = ref(false)
const isSuccess = ref(false)

const cameraCtx = ref(null)
const h5Ready = ref(false)
const cameraReady = ref(false) // 小程序：权限就绪后才渲染 camera 组件
const cameraKey = ref(0) // 小程序：camera 组件重建 key
let h5MediaStream = null
let h5VideoEl = null
let detectTimer = null
let retryCount = 0
let checking = false
let capturedBase64 = ''
let initFailCount = 0 // 小程序：camera initdone 未触发计数
let initFallbackTimer = null // 小程序：initdone 兜底定时器

const DETECT_INTERVAL = 1000
const MAX_DETECT_TIME = 30000
const MAX_RETRY = 3

// #ifdef MP-WEIXIN
async function startCamera() {
  // 首次进入先请求相机权限（授权后 camera 组件再渲染，避免未授权黑屏）
  try {
    await new Promise((resolve, reject) => {
      uni.authorize({
        scope: 'scope.camera',
        success: resolve,
        fail: reject
      })
    })
  } catch (e) {
    status.value = 'error'
    hintText.value = '需要相机权限才能人脸识别，请在设置中开启'
    return
  }
  cameraReady.value = true
  status.value = 'detecting'
  hintText.value = '正对屏幕'
  scheduleInitFallback()
}

function scheduleInitFallback() {
  if (initFallbackTimer) clearTimeout(initFallbackTimer)
  initFallbackTimer = setTimeout(() => {
    if (status.value === 'detecting' || status.value === 'init') {
      // initdone 未触发：自动重建 camera（最多 2 次）
      initFailCount++
      if (initFailCount <= 2) {
        console.log('[ev] camera initdone 未触发，重建 camera，次数:', initFailCount)
        cameraKey.value++
        scheduleInitFallback()
      } else {
        status.value = 'error'
        hintText.value = '摄像头无法启动，请检查权限'
      }
    }
  }, 3000)
}

function onCameraReady() {
  // 相机初始化完成，创建 context 并开始自动检测
  if (initFallbackTimer) { clearTimeout(initFallbackTimer); initFallbackTimer = null }
  cameraCtx.value = uni.createCameraContext()
  if (status.value === 'detecting' || status.value === 'init') {
    status.value = 'detecting'
    hintText.value = '正对屏幕'
    startDetection()
  }
}
// #endif

// #ifdef H5
function startCamera() {
  try {
    const ua = (navigator.userAgent || '').toLowerCase()
    if (/micromessenger|wxwork/.test(ua)) {
      status.value = 'error'
      hintText.value = '请使用微信小程序参加考试'
      return
    }
  } catch (e) {}
  if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
    status.value = 'error'
    hintText.value = '当前浏览器不支持摄像头'
    return
  }
  const camTimeout = setTimeout(() => {
    if (!h5Ready.value) {
      status.value = 'error'
      hintText.value = '摄像头启动超时，请重试'
    }
  }, 8000)
  navigator.mediaDevices.getUserMedia({ video: { facingMode: 'user', width: { ideal: 640 }, height: { ideal: 480 } }, audio: false })
    .then((stream) => {
      clearTimeout(camTimeout)
      h5MediaStream = stream
      const container = document.getElementById('ev-camera-container')
      if (!container) return
      h5VideoEl = document.createElement('video')
      h5VideoEl.setAttribute('autoplay', '')
      h5VideoEl.setAttribute('muted', '')
      h5VideoEl.setAttribute('playsinline', '')
      h5VideoEl.className = 'ev-camera-native'
      h5VideoEl.style.transform = 'scaleX(-1)'
      h5VideoEl.srcObject = stream
      container.appendChild(h5VideoEl)
      h5VideoEl.play().catch(() => {})
      // 等待 video 元素就绪（最多 3 秒）后开始检测，避免首帧黑屏
      let checkCount = 0
      const checkInterval = setInterval(() => {
        checkCount++
        if (h5VideoEl && h5VideoEl.videoWidth > 0) {
          clearInterval(checkInterval)
          console.log('[ev] videoWidth 就绪:', h5VideoEl.videoWidth)
          h5Ready.value = true
          status.value = 'detecting'
          hintText.value = '正对屏幕'
          startDetection()
        } else if (checkCount >= 30) {
          clearInterval(checkInterval)
          console.log('[ev] videoWidth 未就绪，强制开始检测')
          h5Ready.value = true
          status.value = 'detecting'
          hintText.value = '正对屏幕'
          startDetection()
        }
      }, 100)
    })
    .catch(() => {
      clearTimeout(camTimeout)
      status.value = 'error'
      hintText.value = '摄像头无法启动，请检查权限'
    })
}
// #endif

function startDetection() {
  if (detectTimer) clearInterval(detectTimer)
  const startTime = Date.now()
  detectTimer = setInterval(async () => {
    if (status.value === 'capturing' || status.value === 'success' || checking) return
    if (Date.now() - startTime > MAX_DETECT_TIME) {
      stopDetection()
      hintText.value = '检测超时，请重试'
      status.value = 'fail'
      setTimeout(() => uni.navigateBack(), 1500)
      return
    }
    try {
      const base64 = await captureFrame()
      if (!base64) return
      const detect = await detectFace(base64)
      if (detect && detect.has_face) {
        stopDetection()
        doRecognize(base64)
      }
    } catch (e) {}
  }, DETECT_INTERVAL)
}

function stopDetection() {
  if (detectTimer) { clearInterval(detectTimer); detectTimer = null }
}

function stopStream() {
  // #ifdef H5
  if (h5MediaStream) {
    h5MediaStream.getTracks().forEach(t => t.stop())
    h5MediaStream = null
  }
  if (h5VideoEl) {
    h5VideoEl.srcObject = null
    h5VideoEl = null
  }
  h5Ready.value = false
  // #endif
}

function captureFrame() {
  return new Promise((resolve) => {
    // #ifdef MP-WEIXIN
    if (!cameraCtx.value) { resolve(''); return }
    cameraCtx.value.takePhoto({
      quality: 'high',
      success: (res) => {
        uni.compressImage({
          src: res.tempImagePath, quality: 80, compressedWidth: 800,
          success: (cr) => {
            uni.getFileSystemManager().readFile({ filePath: cr.tempFilePath, encoding: 'base64', success: (r) => {
              if (r.data && r.data.length > 3000) resolve(r.data)
              else resolve('')
            }, fail: () => resolve('') })
          },
          fail: () => {
            uni.getFileSystemManager().readFile({ filePath: res.tempImagePath, encoding: 'base64', success: (r) => {
              if (r.data && r.data.length > 3000) resolve(r.data)
              else resolve('')
            }, fail: () => resolve('') })
          }
        })
      },
      fail: () => resolve('')
    })
    // #endif
    // #ifdef H5
    const video = h5VideoEl
    if (!video || !video.videoWidth || !video.videoHeight) { resolve(''); return }
    const canvas = document.createElement('canvas')
    const size = Math.min(video.videoWidth, video.videoHeight)
    const sx = (video.videoWidth - size) / 2
    const sy = (video.videoHeight - size) / 2
    canvas.width = size
    canvas.height = size
    const ctx = canvas.getContext('2d')
    ctx.drawImage(video, sx, sy, size, size, 0, 0, size, size)
    resolve(canvas.toDataURL('image/jpeg', 0.8).split(',')[1])
    // #endif
  })
}

// 后端人脸检测（腾讯云 DetectFace，JSON 提交避免 urlencoded 转义损坏）
function detectFace(base64) {
  return new Promise((resolve) => {
    const token = uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
    uni.request({
      url: BASE_URL + '/api/face/detect',
      method: 'POST',
      data: { image: base64 },
      header: { 'Content-Type': 'application/json', ...(token ? { 'Authorization': 'Bearer ' + token } : {}) },
      success: (res) => {
        const r = res.data || {}
        if (r.code === 0 && r.data) resolve({ has_face: r.data.has_face, face_count: r.data.face_count })
        else resolve(null)
      },
      fail: () => resolve(null)
    })
  })
}

// 人脸比对：调用考试实名人脸验证接口（JSON 提交 Base64）
async function doRecognize(base64) {
  if (checking) return
  checking = true
  isRecognizing.value = true
  status.value = 'capturing'
  hintText.value = '人脸识别中..'
  capturedBase64 = base64
  try {
    const r = await new Promise((resolve, reject) => {
      const token = uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
      uni.request({
        url: BASE_URL + '/api/mobile/safety/exam/verify-face',
        method: 'POST',
        data: { exam_id: examId.value, face_image: base64 },
        header: { 'Content-Type': 'application/json', ...(token ? { 'Authorization': 'Bearer ' + token } : {}) },
        success: res => resolve(res.data),
        fail: reject
      })
    })
    handleResult(r)
  } catch (e) {
    handleFail('网络异常')
  }
}

function handleResult(res) {
  if (res && res.code === 0) {
    isSuccess.value = true
    isRecognizing.value = false
    status.value = 'success'
    hintText.value = '验证通过，进入考试'
    // 开始考试（实名缓存已被消费，写入答卷实名记录）
    doStartExam()
  } else {
    handleFail((res && res.msg) || '人脸识别失败')
  }
}

async function doStartExam() {
  try {
    const r = await startExam(examId.value)
    if (r.code === 0) {
      setTimeout(() => {
        uni.redirectTo({ url: '/pages/sub/safety/exam-do?exam_id=' + examId.value })
      }, 800)
    } else {
      uni.showToast({ title: (r.msg || '开始考试失败') + '，请重试', icon: 'none' })
      backToId()
    }
  } catch (e) {
    uni.showToast({ title: '开始考试失败，请重试', icon: 'none' })
    backToId()
  }
}

function handleFail(msg) {
  isRecognizing.value = false
  retryCount++
  if (retryCount >= MAX_RETRY) {
    status.value = 'fail'
    hintText.value = '人脸识别多次失败，请联系管理员'
    setTimeout(() => uni.navigateBack(), 2000)
    return
  }
  status.value = 'detecting'
  hintText.value = '人脸识别失败，重试中'
  checking = false
  setTimeout(() => { startDetection() }, 1000)
}

function onCameraError() {
  status.value = 'error'
  hintText.value = '摄像头无法启动，请检查权限'
}

onUnmounted(() => {
  stopDetection()
  stopStream()
  if (initFallbackTimer) { clearTimeout(initFallbackTimer); initFallbackTimer = null }
})
</script>

<style scoped>
.ev-page { width: 100vw; height: 100vh; background: #f5f6fa; position: relative; overflow: hidden; }

/* ===== 步骤一 ===== */
.ev-id-step { padding: 0 32rpx; box-sizing: border-box; }
.ev-header { padding: 80rpx 8rpx 40rpx; }
.ev-title { display: block; font-size: 44rpx; font-weight: 700; color: #1a2332; }
.ev-sub { display: block; font-size: 26rpx; color: #8a9aa8; margin-top: 12rpx; }
.ev-card { background: #fff; border-radius:24rpx; padding: 36rpx 32rpx; box-shadow: 0 4rpx 24rpx rgba(0,0,0,0.04); }
.ev-steps { display: flex; align-items: center; justify-content: center; margin-bottom: 40rpx; }
.ev-step { display: flex; align-items: center; gap: 10rpx; }
.ev-step-num { width: 40rpx; height: 40rpx; border-radius:50%; background: #EEF0FE; color: #409EFF; font-size: 24rpx; display: flex; align-items: center; justify-content: center; font-weight: 600; }
.ev-step.active .ev-step-num { background: #409EFF; color: #fff; }
.ev-step-label { font-size: 24rpx; color: #909399; }
.ev-step.active .ev-step-label { color: #409EFF; font-weight: 600; }
.ev-step-line { width: 80rpx; height: 2rpx; background: #e4e7ed; margin: 0 20rpx; }
.ev-form { }
.ev-label { display: block; font-size: 28rpx; color: #303133; font-weight: 500; margin-bottom: 20rpx; }
.ev-code-wrap { display: flex; gap: 12rpx; justify-content: space-between; margin-bottom: 12rpx; }
.ev-code-cell { flex: 1; height: 100rpx; border: 2rpx solid #e4e7ed; border-radius:16rpx; display: flex; align-items: center; justify-content: center; background: #fff; transition: border-color .2s; }
.ev-code-cell.filled { border-color: #409EFF; background: #ecf5ff; }
.ev-code-input { width: 100%; height: 100%; text-align: center; font-size: 40rpx; font-weight: 600; color: #303133; }
.ev-error { display: block; color: #F56C6C; font-size: 24rpx; margin-bottom: 12rpx; }
.ev-btn { height: 92rpx; border-radius:46rpx; display: flex; align-items: center; justify-content: center; font-size: 30rpx; font-weight: 600; margin-top: 16rpx; }
.ev-btn.primary { background: linear-gradient(135deg, #409EFF, #4F46E5); color: #fff; }
.ev-btn.disabled { opacity: 0.6; }
.ev-tip { text-align: center; font-size: 22rpx; color: #c0cedc; margin-top: 24rpx; }

/* ===== 步骤二 ===== */
.ev-face-step { width: 100vw; height: 100vh; background: #000; position: relative; }
.ev-camera { width: 100vw; height: 100vh; object-fit: cover; }
.ev-camera-h5 { width: 100vw; height: 100vh; position: relative; }
.ev-camera-native { position: absolute; top: 0; left: 0; width: 100%; height: 100%; object-fit: cover; }
.ev-camera-empty { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; background: #1a1a1a; }
.ev-empty-tip { color: #8a8a8a; font-size: 14px; }
.ev-face-header { position: absolute; top: calc(env(safe-area-inset-top) + 12px); left: 0; right: 0; display: flex; align-items: center; justify-content: space-between; padding: 0 20px; z-index: 20; }
.ev-face-title { display: flex; flex-direction: column; gap: 2px; }
.ev-face-name { color: #fff; font-size: 15px; font-weight: 600; text-shadow: 0 1px 4px rgba(0,0,0,0.6); }
.ev-face-desc { color: rgba(255,255,255,0.8); font-size: 12px; }
.ev-face-back { color: #4a9eff; font-size: 14px; padding: 8px 4px; }
.ev-mask { position: absolute; top: 0; left: 0; right: 0; bottom: 0; display: flex; align-items: center; justify-content: center; pointer-events: none; z-index: 10; }
.ev-circle { width: 75vw; height: 75vw; max-width: 300px; max-height: 300px; border-radius:50%; border: 3px solid #fff; box-shadow: 0 0 0 9999px rgba(0,0,0,0.55); position: relative; display: flex; align-items: center; justify-content: center; transition: border-color 0.3s; }
.ev-circle.recognizing { border-color: #2979ff; box-shadow: 0 0 0 9999px rgba(0,0,0,0.55), 0 0 30px rgba(41,121,255,0.6); }
.ev-circle.success { border-color: #34c759; box-shadow: 0 0 0 9999px rgba(0,0,0,0.55), 0 0 30px rgba(52,199,89,0.6); }
.ev-loading-ring { width: 48px; height: 48px; border: 4px solid rgba(255,255,255,0.25); border-top-color: #fff; border-radius:50%; animation: ev-spin 0.8s linear infinite; }
@keyframes ev-spin { to { transform: rotate(360deg); } }
.ev-success-icon { display: flex; }
.ev-success-text { font-size: 64px; color: #34c759; font-weight: 700; }
.ev-hint { position: absolute; top: calc(50vh + 40vw); left: 0; right: 0; text-align: center; z-index: 20; pointer-events: none; }
.ev-hint-text { color: #fff; font-size: 16px; font-weight: 500; text-shadow: 0 1px 4px rgba(0,0,0,0.7); }
.ev-hint-text.hint-success { color: #34c759; font-size: 20px; font-weight: 700; }
.ev-hint-text.hint-fail { color: #ff3b30; }
.ev-error-box { position: absolute; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.85); display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 20px; z-index: 30; }
.ev-error-text { color: #fff; font-size: 15px; }
.ev-error-btn { display: flex; align-items: center; gap: 4px; padding: 10px 32px; background: rgba(255,255,255,0.15); border-radius:224px; color: #fff; font-size: 14px; }
</style>
