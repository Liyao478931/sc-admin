<template>
  <view class="settings-page">
    <!-- 个人资料 -->
    <view class="section-label">个人资料</view>
    <view class="settings-card">
      <view class="settings-item" @click="go('/pages/profile/edit')">
        <view class="left">
          <view class="icon-wrap" style="background:#3d5a73;"><MIcon name="users" color="#fff" :size="18" /></view>
          <view class="info">
            <text class="title">个人资料</text>
            <text class="desc">头像 · 姓名 · 工号</text>
          </view>
        </view>
        <view class="right"><MIcon name="chevron-right" color="#c0cedc" :size="16" /></view>
      </view>
      <view class="settings-item" @click="go('/pages/profile/password')">
        <view class="left">
          <view class="icon-wrap" style="background:#c97d5a;"><MIcon name="shield" color="#fff" :size="18" /></view>
          <view class="info">
            <text class="title">修改密码</text>
            <text class="desc">定期更换保障安全</text>
          </view>
        </view>
        <view class="right"><MIcon name="chevron-right" color="#c0cedc" :size="16" /></view>
      </view>
    </view>

    <!-- 账号绑定 -->
    <view class="section-label">账号绑定</view>
    <view class="settings-card">
      <view class="settings-item" @click="go('/pages/profile/bind-phone')">
        <view class="left">
          <view class="icon-wrap" style="background:#4a8f8f;"><MIcon name="phone" color="#fff" :size="18" /></view>
          <view class="info">
            <text class="title">绑定手机号</text>
            <text class="desc">{{ maskPhone(user.phone || user.user_phone) || '未绑定' }}</text>
          </view>
        </view>
        <view class="right">
          <text class="value bound" v-if="user.phone || user.user_phone">已绑定</text>
          <text class="value unbound" v-else>未绑定</text>
          <MIcon name="chevron-right" color="#c0cedc" :size="16" />
        </view>
      </view>
      <view class="settings-item" @click="go('/pages/profile/wechat')">
        <view class="left">
          <view class="icon-wrap" style="background:#07c160;"><MIcon name="chat" color="#fff" :size="18" /></view>
          <view class="info">
            <text class="title">绑定微信</text>
            <text class="desc">公众号 · 小程序授权登录</text>
          </view>
        </view>
        <view class="right">
          <text class="value bound" v-if="wechat.mp_bound || wechat.mini_bound">已绑定</text>
          <text class="value unbound" v-else>未绑定</text>
          <MIcon name="chevron-right" color="#c0cedc" :size="16" />
        </view>
      </view>
    </view>

    <!-- 消息通知 -->
    <view class="section-label">消息通知</view>
    <view class="settings-card">
      <view class="settings-item">
        <view class="left">
          <view class="icon-wrap" style="background:#8a7aa8;"><MIcon name="bell" color="#fff" :size="18" /></view>
          <view class="info">
            <text class="title">消息通知</text>
            <text class="desc">接收任务 · 审批 · 公告 · 聊天提醒</text>
          </view>
        </view>
        <view class="right">
          <switch :checked="notifyEnabled" color="#4F46E5" @change="toggleNotify" />
        </view>
      </view>
      <!-- 通知细分 -->
      <view class="settings-item" v-for="sub in notifySubs" :key="sub.key">
        <view class="left">
          <view class="icon-wrap" :style="{ background: sub.bg }"><MIcon :name="sub.icon" color="#fff" :size="16" /></view>
          <view class="info">
            <text class="title">{{ sub.label }}</text>
            <text class="desc">{{ sub.desc }}</text>
          </view>
        </view>
        <view class="right">
          <switch :checked="notifyPrefs[sub.key] !== 0" color="#4F46E5" @change="(e) => toggleNotifySub(sub.key, e)" />
        </view>
      </view>
      <view class="settings-item">
        <view class="left">
          <view class="icon-wrap" style="background:#c99a3a;"><MIcon name="megaphone" color="#fff" :size="18" /></view>
          <view class="info">
            <text class="title">声音与振动</text>
            <text class="desc">通知提示音 · 振动</text>
          </view>
        </view>
        <view class="right">
          <switch :checked="soundEnabled" color="#4F46E5" @change="toggleSound" />
        </view>
      </view>
    </view>

    <!-- 账号与安全 -->
    <view class="section-label">账号与安全</view>
    <view class="settings-card">
      <view class="settings-item" @click="go('/pages/profile/devices')">
        <view class="left">
          <view class="icon-wrap" style="background:#5a8faa;"><MIcon name="gear" color="#fff" :size="18" /></view>
          <view class="info">
            <text class="title">登录设备管理</text>
            <text class="desc">查看并管理已登录的设备</text>
          </view>
        </view>
        <view class="right">
          <text class="value">{{ deviceCount ? deviceCount + ' 台在线' : '' }}</text>
          <MIcon name="chevron-right" color="#c0cedc" :size="16" />
        </view>
      </view>
    </view>

    <!-- 通用设置 -->
    <view class="section-label">通用设置</view>
    <view class="settings-card">
      <view class="settings-item" @click="toast('暂仅支持简体中文')">
        <view class="left">
          <view class="icon-wrap" style="background:#5a8faa;"><MIcon name="book" color="#fff" :size="18" /></view>
          <view class="info">
            <text class="title">语言</text>
            <text class="desc">简体中文</text>
          </view>
        </view>
        <view class="right"><MIcon name="chevron-right" color="#c0cedc" :size="16" /></view>
      </view>
      <view class="settings-item">
        <view class="left">
          <view class="icon-wrap" style="background:#3d5a73;"><MIcon :name="darkMode ? 'moon' : 'sun'" color="#fff" :size="18" /></view>
          <view class="info">
            <text class="title">深色模式</text>
            <text class="desc">夜间护眼 · 全局深色外观</text>
          </view>
        </view>
        <view class="right">
          <switch :checked="darkMode" color="#4F46E5" @change="toggleDark" />
        </view>
      </view>
      <!-- 字体大小 -->
      <view class="settings-item" @click="showFontPicker = true">
        <view class="left">
          <view class="icon-wrap" style="background:#8a7aa8;"><MIcon name="edit" color="#fff" :size="18" /></view>
          <view class="info">
            <text class="title">字体大小</text>
            <text class="desc">{{ fontScaleText }}</text>
          </view>
        </view>
        <view class="right"><MIcon name="chevron-right" color="#c0cedc" :size="16" /></view>
      </view>
      <!-- 省流模式 -->
      <view class="settings-item">
        <view class="left">
          <view class="icon-wrap" style="background:#4a8f8f;"><MIcon name="trend" color="#fff" :size="18" /></view>
          <view class="info">
            <text class="title">省流模式</text>
            <text class="desc">聊天图片需点击后加载，节省流量</text>
          </view>
        </view>
        <view class="right">
          <switch :checked="saveDataMode" color="#4F46E5" @change="toggleSaveData" />
        </view>
      </view>
      <view class="settings-item" @click="clearChatRecords">
        <view class="left">
          <view class="icon-wrap" style="background:#c97d5a;"><MIcon name="chat" color="#fff" :size="18" /></view>
          <view class="info">
            <text class="title">清除聊天记录</text>
            <text class="desc">删除本地所有聊天消息缓存</text>
          </view>
        </view>
        <view class="right"><MIcon name="chevron-right" color="#c0cedc" :size="16" /></view>
      </view>
      <view class="settings-item" @click="clearCache">
        <view class="left">
          <view class="icon-wrap" style="background:#4a8f8f;"><MIcon name="refresh" color="#fff" :size="18" /></view>
          <view class="info">
            <text class="title">清除缓存</text>
            <text class="desc">当前占用 {{ cacheSize }}</text>
          </view>
        </view>
        <view class="right"><MIcon name="chevron-right" color="#c0cedc" :size="16" /></view>
      </view>
    </view>

    <!-- 帮助与反馈 -->
    <view class="section-label">帮助与反馈</view>
    <view class="settings-card">
      <view class="settings-item" @click="go('/pages/profile/help')">
        <view class="left">
          <view class="icon-wrap" style="background:#07c160;"><MIcon name="alert" color="#fff" :size="18" /></view>
          <view class="info">
            <text class="title">帮助中心</text>
            <text class="desc">常见问题与使用指南</text>
          </view>
        </view>
        <view class="right"><MIcon name="chevron-right" color="#c0cedc" :size="16" /></view>
      </view>
      <view class="settings-item" @click="go('/pages/profile/feedback')">
        <view class="left">
          <view class="icon-wrap" style="background:#8a7aa8;"><MIcon name="edit" color="#fff" :size="18" /></view>
          <view class="info">
            <text class="title">意见反馈</text>
            <text class="desc">您的建议是我们改进的动力</text>
          </view>
        </view>
        <view class="right"><MIcon name="chevron-right" color="#c0cedc" :size="16" /></view>
      </view>
    </view>

    <!-- 关于 -->
    <view class="section-label">关于</view>
    <view class="settings-card">
      <view class="settings-item" @click="checkUpdate">
        <view class="left">
          <view class="icon-wrap" style="background:#c99a3a;"><MIcon name="info" color="#fff" :size="18" /></view>
          <view class="info">
            <text class="title">版本</text>
            <text class="desc">{{ appVersion }}{{ checking ? ' · 检查中...' : '' }}</text>
          </view>
        </view>
        <view class="right">
          <text class="value version-text">{{ updateTip }}</text>
          <MIcon name="chevron-right" color="#c0cedc" :size="16" />
        </view>
      </view>
      <view class="settings-item" @click="go('/pages/agreement/index?type=user')">
        <view class="left">
          <view class="icon-wrap" style="background:#5a8faa;"><MIcon name="file" color="#fff" :size="18" /></view>
          <view class="info">
            <text class="title">用户协议</text>
            <text class="desc">平台使用条款</text>
          </view>
        </view>
        <view class="right"><MIcon name="chevron-right" color="#c0cedc" :size="16" /></view>
      </view>
      <view class="settings-item" @click="go('/pages/agreement/index?type=privacy')">
        <view class="left">
          <view class="icon-wrap" style="background:#8a7aa8;"><MIcon name="eye" color="#fff" :size="18" /></view>
          <view class="info">
            <text class="title">隐私政策</text>
            <text class="desc">个人信息保护说明</text>
          </view>
        </view>
        <view class="right"><MIcon name="chevron-right" color="#c0cedc" :size="16" /></view>
      </view>
    </view>

    <!-- 退出登录 -->
    <view class="logout-section">
      <button class="logout-btn" @click="logout">退出登录</button>
    </view>

    <!-- 字体大小选择器 -->
    <picker v-if="showFontPicker" :range="fontOptions" :value="fontIndex" @change="onFontChange" @cancel="showFontPicker = false">
      <view class="font-mask" @click.stop="showFontPicker = false"></view>
    </picker>
    <view v-if="showFontPicker" class="font-picker-panel" @click.stop>
      <view class="font-picker-title">选择字体大小</view>
      <view class="font-picker-options">
        <view
          v-for="(opt, i) in fontOptions"
          :key="i"
          class="font-picker-opt"
          :class="{ active: fontIndex === i }"
          @click="pickFont(i)"
        >
          <text :style="{ fontSize: [16, 18, 21][i] + 'px' }">{{ opt }}</text>
        </view>
      </view>
      <view class="font-picker-cancel" @click="showFontPicker = false">取消</view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed } from 'vue'
import { onLoad, onShow } from '@dcloudio/uni-app'
import MIcon from '@/components/MIcon.vue'

const user = ref({})
const wechat = ref({ mp_bound: false, mini_bound: false })
const notifyEnabled = ref(true)
const soundEnabled = ref(true)
const darkMode = ref(false)
const saveDataMode = ref(false)
const appVersion = ref('v1.77.43')
const checking = ref(false)
const updateTip = ref('已是最新')
const deviceCount = ref(0)
const cacheSize = ref('0 KB')

const notifySubs = [
  { key: 'task', label: '任务提醒', desc: '工单 · 巡检 · 维修任务', icon: 'clipboard', bg: '#3d5a73' },
  { key: 'approval', label: '审批提醒', desc: '待办审批 · 审批结果', icon: 'inbox', bg: '#c97d5a' },
  { key: 'announcement', label: '公告提醒', desc: '系统公告 · 通知', icon: 'megaphone', bg: '#8a7aa8' },
  { key: 'chat', label: '聊天提醒', desc: '通讯录新消息', icon: 'chat', bg: '#07c160' },
]
const notifyPrefs = ref({ task: 1, approval: 1, announcement: 1, chat: 1 })

const fontOptions = ['标准', '大', '特大']
const fontScaleMap = ['1', '1.15', '1.3']
const fontIndex = ref(0)
const showFontPicker = ref(false)
const fontScaleText = computed(() => fontOptions[fontIndex.value])

function getToken() {
  return uni.getStorageSync('access_token') || uni.getStorageSync('token') || ''
}

function api(url, method, data) {
  return new Promise((resolve, reject) => {
    uni.request({
      url: uni.$base + url,
      method: method || 'GET',
      data: data || {},
      header: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Bearer ' + getToken()
      },
      success: (r) => r.data?.code === 0 ? resolve(r.data) : reject(r.data || { msg: '请求失败' }),
      fail: () => reject({ msg: '网络异常，请稍后重试' })
    })
  })
}

function applyDark(v) {
  // #ifdef H5
  const el = document.documentElement
  if (v) { el.classList.add('dark-mode') } else { el.classList.remove('dark-mode') }
  // #endif
}

function applyFontScale() {
  // #ifdef H5
  try {
    const scale = uni.getStorageSync('font_scale') || '1'
    document.documentElement.style.setProperty('--font-scale', scale)
  } catch (e) {}
  // #endif
}

function maskPhone(p) {
  return p ? p.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2') : ''
}
function go(url) { uni.navigateTo({ url }) }
function toast(title) { uni.showToast({ title, icon: 'none' }) }

function fmtSize(kb) {
  kb = Number(kb) || 0
  if (kb >= 1024) return (kb / 1024).toFixed(2) + ' MB'
  return kb + ' KB'
}

function loadCacheSize() {
  try {
    const info = uni.getStorageInfoSync()
    cacheSize.value = fmtSize(info.currentSize || 0)
  } catch (e) {
    cacheSize.value = '未知'
  }
}

async function loadUserInfo() {
  try {
    const r = await api('/api/user/profile')
    user.value = r.data || {}
  } catch (e) {}
}

async function loadWechat() {
  try {
    if (!getToken()) return
    const r = await api('/api/user/wechat/status')
    wechat.value = r.data || { mp_bound: false, mini_bound: false }
  } catch (e) {}
}

async function loadDevices() {
  try {
    const r = await api('/api/mobile/devices/list')
    const list = r.data?.list || []
    deviceCount.value = list.filter(x => x.status === 1).length
  } catch (e) {}
}

function toggleNotify(e) {
  notifyEnabled.value = e.detail.value
  uni.setStorageSync('notify_enabled', notifyEnabled.value ? 1 : 0)
  uni.showToast({ title: notifyEnabled.value ? '已开启消息通知' : '已关闭消息通知', icon: 'none' })
}

function toggleNotifySub(key, e) {
  notifyPrefs.value[key] = e.detail.value ? 1 : 0
  uni.setStorageSync('notify_prefs', JSON.stringify(notifyPrefs.value))
  uni.showToast({ title: e.detail.value ? '已开启' : '已关闭', icon: 'none' })
}

function toggleSound(e) {
  soundEnabled.value = e.detail.value
  uni.setStorageSync('sound_enabled', soundEnabled.value ? 1 : 0)
  uni.showToast({ title: soundEnabled.value ? '已开启声音' : '已关闭声音', icon: 'none' })
}

function toggleDark(e) {
  darkMode.value = e.detail.value
  uni.setStorageSync('dark_mode', darkMode.value ? 1 : 0)
  applyDark(darkMode.value)
  uni.showToast({ title: darkMode.value ? '已切换深色模式' : '已切换浅色模式', icon: 'none' })
}

function toggleSaveData(e) {
  saveDataMode.value = e.detail.value
  uni.setStorageSync('save_data_mode', saveDataMode.value ? 1 : 0)
  uni.showToast({ title: saveDataMode.value ? '已开启省流模式' : '已关闭省流模式', icon: 'none' })
}

function onFontChange(e) {
  pickFont(Number(e.detail.value))
}
function pickFont(i) {
  fontIndex.value = i
  uni.setStorageSync('font_scale', fontScaleMap[i])
  applyFontScale()
  showFontPicker.value = false
  uni.showToast({ title: '字体大小已调整为「' + fontOptions[i] + '」', icon: 'none' })
}

function clearChatRecords() {
  uni.showModal({
    title: '清除聊天记录',
    content: '将删除本机保存的全部聊天消息缓存（不影响服务器消息记录），确定继续吗？',
    confirmColor: '#e74c5e',
    success: (r) => {
      if (!r.confirm) return
      try {
        const info = uni.getStorageInfoSync()
        const keys = info.keys || []
        let removed = 0
        keys.forEach(k => {
          if (String(k).indexOf('chat_msgs_') === 0) {
            uni.removeStorageSync(k)
            removed++
          }
        })
        loadCacheSize()
        uni.showToast({ title: removed ? '已清除 ' + removed + ' 个会话缓存' : '暂无聊天缓存', icon: 'none' })
      } catch (e) {
        uni.showToast({ title: '清除失败', icon: 'none' })
      }
    }
  })
}

function clearCache() {
  uni.showModal({
    title: '清除缓存',
    content: '将清除本地缓存数据（含登录状态），确定继续吗？',
    success: (r) => {
      if (r.confirm) {
        uni.clearStorageSync()
        uni.showToast({ title: '缓存已清除', icon: 'success' })
        setTimeout(() => uni.reLaunch({ url: '/pages/login/index' }), 800)
      }
    }
  })
}

async function loadVersion() {
  try {
    const r = await api('/api/mobile/version', 'GET')
    if (r.data && r.data.version) appVersion.value = r.data.version
  } catch (e) {}
}

async function checkUpdate() {
  if (checking.value) return
  checking.value = true
  updateTip.value = '检查中...'
  try {
    const r = await api('/api/mobile/version', 'GET')
    if (r.data && r.data.version) appVersion.value = r.data.version
    // 获取最近更新记录
    let historyText = 'H5 应用由服务器统一发布，当前已是最新版本。'
    try {
      const hr = await new Promise((resolve, reject) => {
        uni.request({
          url: uni.$base + '/api/public/versions',
          method: 'GET',
          success: (res) => res.data?.code === 0 ? resolve(res.data) : reject(res),
          fail: reject
        })
      })
      const list = hr.data?.list || []
      if (list.length) {
        const recent = list.slice(0, 3).map(v => v.version_no + ' · ' + (v.version_name || '') + '\n' + ((v.release_note || '').slice(0, 50))).join('\n\n')
        historyText = '最近更新：\n\n' + recent
      }
    } catch (e) {}
    checking.value = false
    updateTip.value = '已是最新'
    uni.showModal({
      title: '当前版本 ' + appVersion.value,
      content: historyText,
      showCancel: false,
      confirmText: '知道了',
      confirmColor: '#4F46E5'
    })
  } catch (e) {
    checking.value = false
    updateTip.value = '检查失败'
    uni.showToast({ title: '检查更新失败，请稍后重试', icon: 'none' })
  }
}

function logout() {
  uni.showModal({
    title: '退出登录',
    content: '确定退出登录吗？',
    success: (r) => {
      if (r.confirm) {
        uni.removeStorageSync('token')
        uni.removeStorageSync('access_token')
        uni.removeStorageSync('userInfo')
        uni.reLaunch({ url: '/pages/login/index' })
      }
    }
  })
}

onLoad(() => {
  notifyEnabled.value = !!uni.getStorageSync('notify_enabled')
  soundEnabled.value = !!uni.getStorageSync('sound_enabled')
  darkMode.value = !!uni.getStorageSync('dark_mode')
  saveDataMode.value = !!uni.getStorageSync('save_data_mode')
  try {
    const raw = uni.getStorageSync('notify_prefs')
    if (raw) notifyPrefs.value = Object.assign({ task: 1, approval: 1, announcement: 1, chat: 1 }, JSON.parse(raw))
  } catch (e) {}
  const fs = uni.getStorageSync('font_scale') || '1'
  fontIndex.value = Math.max(0, fontScaleMap.indexOf(String(fs)))
  applyDark(darkMode.value)
  applyFontScale()
  loadCacheSize()
  loadUserInfo()
  loadWechat()
  loadDevices()
  loadVersion()
})

onShow(() => {
  loadCacheSize()
  loadDevices()
})
</script>

<style scoped>
.settings-page { min-height: 100vh; background: var(--bg-color, #F4F6FB); padding: 16px 16px 30px; box-sizing: border-box; }
.section-label { font-size: 12px; color: var(--text-sub, #9aabba); font-weight: 500; padding: 0 4px 10px; letter-spacing: 0.3px; }
.settings-card { background: var(--card-color, #fff); border-radius: 16px; overflow: hidden; margin-bottom: 16px; box-shadow: 0 1px 4px rgba(0,0,0,0.04); border: 1px solid var(--divider-color, rgba(0,0,0,0.04)); }
.settings-item { display: flex; align-items: center; padding: 14px 18px; border-bottom: 1px solid var(--divider-color, #F4F6FB); background: transparent; width: 100%; text-align: left; }
.settings-item:last-child { border-bottom: none; }
.settings-item:active { background: var(--active-bg, #EDF0F8); }
.settings-item .left { display: flex; align-items: center; gap: 14px; flex: 1; min-width: 0; }
.settings-item .left .icon-wrap { width: 36px; height: 36px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; font-size: 16px; color: #fff; }
.settings-item .left .info { display: flex; flex-direction: column; }
.settings-item .left .info .title { font-size: 15px; font-weight: 500; color: var(--text-main, #1a2332); }
.settings-item .left .info .desc { font-size: 12px; color: var(--text-sub, #9aabba); margin-top: 1px; }
.settings-item .right { display: flex; align-items: center; gap: 8px; flex-shrink: 0; }
.settings-item .right .value { font-size: 14px; color: var(--text-mute, #8a9aa8); }
.settings-item .right .value.bound { color: var(--accent, #3d5a73); font-weight: 500; }
.settings-item .right .value.unbound { color: #c97d5a; font-weight: 500; }
.settings-item .right .chevron { color: #c0cedc; font-size: 16px; }
.version-text { color: var(--accent, #3d5a73); font-weight: 500; }
.logout-section { padding: 8px 0 4px; }
.logout-btn { width: 100%; padding: 16px; border-radius: 14px; background: var(--card-color, #fff); color: #e74c5e; font-size: 16px; font-weight: 500; border: 1px solid var(--divider-color, #EDF0F8); }
.logout-btn:active { background: var(--active-bg, #fff5f5); }

.font-mask { position: fixed; left: 0; top: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.35); z-index: 998; }
.font-picker-panel { position: fixed; left: 16px; right: 16px; bottom: 30px; background: #fff; border-radius: 18px; padding: 20px 16px; z-index: 999; box-shadow: 0 8px 32px rgba(0,0,0,0.18); }
.font-picker-title { text-align: center; font-size: 16px; font-weight: 600; color: #1a2332; margin-bottom: 16px; }
.font-picker-options { display: flex; gap: 12px; }
.font-picker-opt { flex: 1; height: 60px; border-radius: 12px; background: #F4F6FB; display: flex; align-items: center; justify-content: center; color: #5b6b7b; border: 2px solid transparent; }
.font-picker-opt.active { background: #EEF0FE; border-color: #4F46E5; color: #4F46E5; font-weight: 600; }
.font-picker-cancel { margin-top: 14px; text-align: center; color: #9aabba; font-size: 14px; padding: 8px; }
</style>
