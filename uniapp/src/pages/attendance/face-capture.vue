<template>
  <view class="fc-page">
    <!-- 摄像头预览（小程序：camera；H5：video） -->
    <!-- #ifdef MP-WEIXIN -->
    <!-- 小程序 camera 前置默认镜像显示，无需翻转；cameraReady 后渲染，key 变化触发重建 -->
    <camera v-if="cameraReady" :key="cameraKey" class="fc-camera" device-position="front" flash="off" frame-size="medium" @error="onCameraError" @initdone="onCameraReady"></camera>
    <!-- #endif -->

    <!-- #ifdef H5 -->
    <view class="fc-camera-h5" id="h5-camera-container">
      <view v-if="!h5Ready" class="fc-camera-empty">
        <text class="fc-empty-tip">摄像头启动中...</text>
      </view>
    </view>
    <!-- #endif -->

    <!-- 顶部信息（钉钉风格） -->
    <view class="fc-header">
      <view class="fc-header-left">
        <text class="fc-company">{{ companyName }}</text>
        <text class="fc-user">{{ userName }}</text>
      </view>
      <view class="fc-header-right">
        <u-avatar v-if="avatar" :src="avatar" size="36" />
        <u-avatar v-else :text="nameInitial" size="36" bg-color="linear-gradient(135deg, #4F46E5, #7C6FF0)" font-size="14" />
      </view>
    </view>

    <!-- 圆形取景框遮罩 -->
    <view class="fc-mask">
      <view class="fc-circle" :class="{ recognizing: isRecognizing, success: isSuccess }">
        <!-- 识别中加载动画 -->
        <view v-if="isRecognizing" class="fc-loading-ring"></view>
        <!-- 成功图标 -->
        <view v-if="isSuccess" class="fc-success-icon">
          <u-icon name="checkmark-circle" size="64" color="#34c759" />
        </view>
      </view>
    </view>

    <!-- 提示文字（居中，钉钉风格） -->
    <view class="fc-hint">
      <text class="fc-hint-text" :class="{ 'hint-success': isSuccess, 'hint-fail': status === 'fail' }">{{ hintText }}</text>
    </view>

    <!-- 底部信息（钉钉风格） -->
    <view class="fc-bottom">
      <text class="fc-group">{{ groupName }}</text>
      <text class="fc-apply" @click="goApply">申请</text>
    </view>

    <!-- 权限失败提示 -->
    <view v-if="status === 'error'" class="fc-error-box">
      <text class="fc-error-text">{{ hintText }}</text>
      <view class="fc-error-btn" @click="goBack">返回</view>
    </view>
  </view>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { onLoad } from '@dcloudio/uni-app'
import { get, post } from '@/utils/request'

// 状态机：init 启动中 / detecting 检测中 / capturing 识别中 / success 成功 / fail 失败 / error 错误
const status = ref('init')
const hintText = ref('摄像头启动中...')
const isRecognizing = ref(false)
const isSuccess = ref(false)

const companyName = ref('')
const userName = ref('')
const groupName = ref('')
const avatar = ref('')
const nameInitial = ref('')

const cameraCtx = ref(null)
const h5Ready = ref(false)
const cameraReady = ref(false) // 小程序：权限就绪后才渲染 camera 组件
const cameraKey = ref(0) // 小程序：camera 组件重建 key
let h5MediaStream = null
let detectTimer = null
let retryCount = 0
let checking = false // 防重入
let initFailCount = 0 // 小程序：camera initdone 未触发计数
let initFallbackTimer = null // 小程序：initdone 兜底定时器

// 检测参数
const DETECT_INTERVAL = 1000 // 小程序 takePhoto 频率不宜过高（500ms 会取到未就绪帧）
const MAX_DETECT_TIME = 30000
const MAX_RETRY = 3

onLoad(async (options) => {
  // 携带打卡所需参数（从打卡页传入）
  checkinParams.pointId = parseInt(options.point_id || 0, 10)
  checkinParams.sequence = parseInt(options.sequence || options.check_sequence || 1, 10)
  checkinParams.isField = options.field === '1'
  checkinParams.lat = parseFloat(options.lat || 0)
  checkinParams.lng = parseFloat(options.lng || 0)
  if (checkinParams.isField) fieldReason = decodeURIComponent(options.reason || '外勤打卡')
  await loadProfile()
  startCamera()
})

const checkinParams = { pointId: 0, sequence: 1, isField: false, lat: 0, lng: 0 }

// #ifdef MP-WEIXIN
async function startCamera () {
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
    // 权限被拒：提示打开设置
    status.value = 'error'
    hintText.value = '需要相机权限才能人脸识别，请在设置中开启'
    return
  }
  // 渲染 camera 组件，等待 @initdone（onCameraReady）后启动检测
  cameraReady.value = true
  status.value = 'detecting'
  hintText.value = '正对屏幕'
  scheduleInitFallback()
}

function scheduleInitFallback () {
  if (initFallbackTimer) clearTimeout(initFallbackTimer)
  initFallbackTimer = setTimeout(() => {
    if (status.value === 'detecting' || status.value === 'init') {
      // initdone 未触发：自动重建 camera（最多 2 次）
      initFailCount++
      if (initFailCount <= 2) {
        console.log('[fc] camera initdone 未触发，重建 camera，次数:', initFailCount)
        cameraKey.value++
        scheduleInitFallback()
      } else {
        status.value = 'error'
        hintText.value = '摄像头无法启动，请检查权限'
      }
    }
  }, 3000)
}

function onCameraReady () {
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
let h5VideoEl = null // 原生 video 元素

function startCamera () {
  // 微信内置浏览器不支持 getUserMedia 直接调摄像头，提示返回（不提供相册降级）
  try {
    const ua = (navigator.userAgent || '').toLowerCase()
    const isWechat = /micromessenger|wxwork/.test(ua)
    if (isWechat) {
      status.value = 'error'
      hintText.value = '请使用微信小程序打开考勤打卡'
      return
    }
  } catch (e) {}

  if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
    status.value = 'error'
    hintText.value = '当前浏览器不支持摄像头'
    return
  }

  // 摄像头启动超时（8秒）自动提示
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
      console.log('[fc] getUserMedia 成功')
      // 动态创建原生 video 元素（uni-app video 组件对 srcObject 支持不可靠）
      const container = document.getElementById('h5-camera-container')
      if (!container) {
        console.log('[fc] container 不存在')
        return
      }
      h5VideoEl = document.createElement('video')
      h5VideoEl.setAttribute('autoplay', '')
      h5VideoEl.setAttribute('muted', '')
      h5VideoEl.setAttribute('playsinline', '')
      h5VideoEl.className = 'fc-camera-native'
      // 内联样式水平翻转（scoped CSS 对动态创建元素不生效，必须内联）——前置摄像头非镜像，翻转成镜像显示
      h5VideoEl.style.transform = 'scaleX(-1)'
      h5VideoEl.srcObject = stream
      container.appendChild(h5VideoEl)
      console.log('[fc] video 元素已创建，开始播放')
      h5VideoEl.play().catch((e) => {
        console.log('[fc] h5VideoEl.play() 失败:', e)
      })
      // 等待视频流初始化（最多 3 秒）
      let checkCount = 0
      const checkInterval = setInterval(() => {
        checkCount++
        if (h5VideoEl && h5VideoEl.videoWidth > 0) {
          clearInterval(checkInterval)
          console.log('[fc] videoWidth 就绪:', h5VideoEl.videoWidth)
          h5Ready.value = true
          status.value = 'detecting'
          hintText.value = '正对屏幕'
          console.log('[fc] 开始检测')
          startDetection()
        } else if (checkCount >= 30) {
          clearInterval(checkInterval)
          console.log('[fc] videoWidth 未就绪，强制开始检测')
          h5Ready.value = true
          status.value = 'detecting'
          hintText.value = '正对屏幕'
          console.log('[fc] 开始检测')
          startDetection()
        }
      }, 100)
    })
    .catch((e) => {
      clearTimeout(camTimeout)
      console.log('[fc] getUserMedia 失败:', e)
      status.value = 'error'
      hintText.value = '摄像头无法启动，请检查权限'
    })
}
// #endif

// 定时截帧检测（H5 直接截帧；小程序通过 takePhoto 截帧）
function startDetection () {
  if (detectTimer) clearInterval(detectTimer)
  const startTime = Date.now()
  detectTimer = setInterval(async () => {
    if (status.value === 'capturing' || status.value === 'success' || checking) return
    // 超时降级
    if (Date.now() - startTime > MAX_DETECT_TIME) {
      stopDetection()
      hintText.value = '检测超时，请重试'
      status.value = 'fail'
      setTimeout(() => uni.navigateBack(), 1500)
      return
    }
    try {
      const base64 = await captureFrame()
      if (!base64) { console.log('[fc] captureFrame 空'); return }
      console.log('[fc] 截帧成功，长度', base64.length)
      // 调用后端人脸检测（DetectFace），确认框内有人脸
      const detect = await detectFace(base64)
      console.log('[fc] detect 结果', JSON.stringify(detect))
      if (detect && detect.has_face) {
        console.log('[fc] 检测到人脸，开始识别')
        stopDetection()
        await doRecognize(base64)
      }
    } catch (e) {
      console.log('[fc] 检测异常', e)
      // 检测接口异常时静默继续（避免频繁报错）
    }
  }, DETECT_INTERVAL)
}

function stopDetection () {
  if (detectTimer) { clearInterval(detectTimer); detectTimer = null }
}

// 截帧：返回 base64
function captureFrame () {
  return new Promise((resolve) => {
    // #ifdef MP-WEIXIN
    if (!cameraCtx.value) { resolve(''); return }
    cameraCtx.value.takePhoto({
      quality: 'high',
      success: (res) => {
        // 压缩图片（限制尺寸/质量，避免 base64 过大导致 detect 请求失败）
        uni.compressImage({
          src: res.tempImagePath,
          quality: 80,
          compressedWidth: 800,
          success: (cr) => {
            uni.getFileSystemManager().readFile({ filePath: cr.tempFilePath, encoding: 'base64', success: (r) => {
              // 有效帧应有一定长度（JPEG 至少几千字节）；太短说明取到空白/未就绪帧
              if (r.data && r.data.length > 3000) resolve(r.data)
              else resolve('')
            }, fail: () => resolve('') })
          },
          fail: () => {
            // 压缩失败则用原图
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
    // drawImage 绘制 video 原始帧（不受 CSS transform 影响）；显示层已 scaleX(-1) 镜像，截帧保持原始朝向
    ctx.drawImage(video, sx, sy, size, size, 0, 0, size, size)
    resolve(canvas.toDataURL('image/jpeg', 0.8).split(',')[1])
    // #endif
  })
}

// 后端人脸检测（腾讯云 DetectFace，JSON 提交 image 避免 urlencoded 转义损坏）
async function detectFace (base64) {
  try {
    const r = await new Promise((resolve, reject) => {
      const token = uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
      uni.request({
        url: uni.$base + '/api/face/detect',
        method: 'POST',
        data: { image: base64 },
        header: { 'Content-Type': 'application/json', ...(token ? { 'Authorization': 'Bearer ' + token } : {}) },
        success: res => resolve(res.data),
        fail: reject
      })
    })
    if (r.code === 0 && r.data) {
      return { has_face: r.data.has_face, face_count: r.data.face_count }
    }
    console.log('[fc] detect 非0', JSON.stringify(r).slice(0, 100))
  } catch (e) {
    console.log('[fc] detect 请求失败', e && e.errMsg)
  }
  return null
}

// 人脸比对 + 提交打卡
async function doRecognize (base64) {
  if (checking) return
  checking = true
  isRecognizing.value = true
  status.value = 'capturing'
  hintText.value = '人脸识别中..'

  try {
    // 直接提交打卡（后端 checkin 内置人脸比对；JSON 提交避免 Base64 urlencoded 损坏）
    const payload = {
      check_sequence: checkinParams.sequence,
      latitude: checkinParams.lat,
      longitude: checkinParams.lng,
      face_image: base64,
      location_address: ''
    }
    if (checkinParams.isField) {
      const res = await jsonPost('/api/mobile/attendance/field-checkin', { ...payload, reason: fieldReason })
      handleResult(res, true)
    } else {
      payload.point_id = checkinParams.pointId
      const res = await jsonPost('/api/mobile/attendance/checkin', payload)
      handleResult(res, false)
    }
  } catch (e) {
    handleFail('网络异常')
  }
}

// JSON 提交（避免 request.js 默认 urlencoded 对 Base64 转义损坏）
function jsonPost (url, data) {
  return new Promise((resolve, reject) => {
    const token = uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
    uni.request({
      url: uni.$base + url,
      method: 'POST',
      data,
      header: { 'Content-Type': 'application/json', ...(token ? { 'Authorization': 'Bearer ' + token } : {}) },
      success: res => resolve(res.data),
      fail: reject
    })
  })
}

let fieldReason = '外勤打卡'

function handleResult (res, isField) {
  if (res && res.code === 0) {
    // 成功
    isSuccess.value = true
    isRecognizing.value = false
    status.value = 'success'
    hintText.value = '打卡成功'
    // 回传打卡页刷新
    const pages = getCurrentPages()
    const prev = pages.length > 1 ? pages[pages.length - 2] : null
    if (prev && prev.$vm && prev.$vm.onCheckinDone) prev.$vm.onCheckinDone()
    setTimeout(() => uni.navigateBack({ delta: 1 }), 1500)
  } else {
    handleFail((res && res.msg) || '人脸识别失败')
  }
}

function handleFail (msg) {
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
  // 1 秒后重新检测
  setTimeout(() => {
    startDetection()
  }, 1000)
}

function onCameraError () {
  status.value = 'error'
  hintText.value = '摄像头无法启动，请检查权限'
}

function goBack () {
  uni.navigateBack({ delta: 1 })
}

async function loadProfile () {
  try {
    const r = await get('/api/user/profile')
    if (r && r.data) {
      userName.value = r.data.name || r.data.real_name || ''
      avatar.value = r.data.avatar || ''
      nameInitial.value = (r.data.name || r.data.real_name || r.data.username || '?').charAt(0)
    }
  } catch (e) {}
  // 公司/考勤组（简化从 storage 或默认）
  companyName.value = uni.getStorageSync('company_name') || '企业考勤'
  groupName.value = uni.getStorageSync('att_group_name') || '考勤组'
}

function goApply () { uni.navigateTo({ url: '/pages/oa/apply' }) }

onUnmounted(() => {
  stopDetection()
  if (initFallbackTimer) { clearTimeout(initFallbackTimer); initFallbackTimer = null }
  // #ifdef H5
  if (h5MediaStream) {
    h5MediaStream.getTracks().forEach(t => t.stop())
    h5MediaStream = null
  }
  if (h5VideoEl) {
    h5VideoEl.srcObject = null
    h5VideoEl = null
  }
  // #endif
})
</script>

<style scoped>
.fc-page { width: 100vw; height: 100vh; background: #000; position: relative; overflow: hidden; }
.fc-camera { width: 100vw; height: 100vh; object-fit: cover; }
.fc-camera-h5 { width: 100vw; height: 100vh; position: relative; }
.fc-camera-native { position: absolute; top: 0; left: 0; width: 100%; height: 100%; object-fit: cover; }
.fc-camera-empty { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; background: #1a1a1a; }
.fc-empty-tip { color: #8a8a8a; font-size: 14px; }

/* 顶部信息 */
.fc-header { position: absolute; top: calc(env(safe-area-inset-top) + 12px); left: 0; right: 0; display: flex; align-items: center; justify-content: space-between; padding: 0 20px; z-index: 20; }
.fc-header-left { display: flex; flex-direction: column; gap: 2px; }
.fc-company { color: #fff; font-size: 14px; font-weight: 600; text-shadow: 0 1px 4px rgba(0,0,0,0.6); }
.fc-user { color: rgba(255,255,255,0.8); font-size: 12px; }

/* 圆形取景框 */
.fc-mask { position: absolute; top: 0; left: 0; right: 0; bottom: 0; display: flex; align-items: center; justify-content: center; pointer-events: none; z-index: 10; }
.fc-circle { width: 75vw; height: 75vw; max-width: 300px; max-height: 300px; border-radius:50%; border: 3px solid #fff; box-shadow: 0 0 0 9999px rgba(0,0,0,0.55); position: relative; display: flex; align-items: center; justify-content: center; transition: border-color 0.3s; }
.fc-circle.recognizing { border-color: #2979ff; box-shadow: 0 0 0 9999px rgba(0,0,0,0.55), 0 0 30px rgba(41,121,255,0.6); }
.fc-circle.success { border-color: #34c759; box-shadow: 0 0 0 9999px rgba(0,0,0,0.55), 0 0 30px rgba(52,199,89,0.6); }

/* 识别中加载动画（钉钉风格） */
.fc-loading-ring { width: 48px; height: 48px; border: 4px solid rgba(255,255,255,0.25); border-top-color: #fff; border-radius:50%; animation: fc-spin 0.8s linear infinite; }
@keyframes fc-spin { to { transform: rotate(360deg); } }
.fc-success-icon { display: flex; }

/* 提示文字 */
.fc-hint { position: absolute; top: calc(50vh + 40vw); left: 0; right: 0; text-align: center; z-index: 20; pointer-events: none; }
.fc-hint-text { color: #fff; font-size: 16px; font-weight: 500; text-shadow: 0 1px 4px rgba(0,0,0,0.7); }
.fc-hint-text.hint-success { color: #34c759; font-size: 20px; font-weight: 700; }
.fc-hint-text.hint-fail { color: #ff3b30; }

/* 底部信息 */
.fc-bottom { position: absolute; bottom: calc(env(safe-area-inset-bottom) + 24px); left: 0; right: 0; display: flex; align-items: center; justify-content: center; gap: 16px; z-index: 20; }
.fc-group { color: rgba(255,255,255,0.7); font-size: 12px; }
.fc-apply { color: #4a9eff; font-size: 13px; }

/* 错误降级 */
.fc-error-box { position: absolute; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.85); display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 20px; z-index: 30; }
.fc-error-text { color: #fff; font-size: 15px; }
.fc-error-btn { display: flex; align-items: center; gap: 4px; padding: 10px 32px; background: rgba(255,255,255,0.15); border-radius:224px; color: #fff; font-size: 14px; }
</style>
