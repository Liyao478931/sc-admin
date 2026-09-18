<template>
  <view class="chat-page">
    <!-- 消息列表（独立滚动） -->
    <scroll-view scroll-y class="chat-list" :scroll-top="scrollTop" :scroll-into-view="lastMsgView" scroll-with-animation>
      <view class="msg-row" :class="m.mine ? 'mine' : 'other'" v-for="m in messages" :key="m.id" :id="m.id < 0 ? 'msg-empty' : 'msg-' + m.id">
        <!-- 头像（点击查看资料） -->
        <view class="msg-avatar" @click="m.mine ? showMyProfile() : showPeerProfile()">
          <image v-if="avatarSrc(m)" class="msg-avatar-img" :src="avatarSrc(m)" mode="aspectFill" />
          <text v-else class="msg-avatar-text">{{ avatarText(m) }}</text>
        </view>
        <view class="msg-body">
          <!-- 发送中/失败占位 -->
          <view class="bubble" v-if="m.type === 'text' || !m.type">{{ m.content }}</view>
          <!-- 图片消息 -->
          <view class="bubble img-bubble" v-else-if="m.type === 'image'" @click="previewImage(m)">
            <image v-if="!saveDataMode || m.img_loaded" class="msg-img" :src="m.file_url" mode="aspectFill" lazy-load />
            <view v-else class="msg-img-placeholder" @click.stop="loadImg(m)">
              <text class="ph-icon">🖼</text>
              <text class="ph-text">点击加载图片</text>
            </view>
          </view>
          <!-- 视频消息 -->
          <view class="bubble video-bubble" v-else-if="m.type === 'video'">
            <video class="msg-video" :src="m.file_url" :poster="m.thumb || ''" controls object-fit="contain" />
          </view>
          <!-- 文件消息 -->
          <view class="bubble file-bubble" v-else-if="m.type === 'file'" @click="openFile(m)">
            <MIcon name="folder" :size="30" color="#4F46E5" />
            <view class="file-info">
              <text class="file-name">{{ m.file_name || '文件' }}</text>
              <text class="file-size">{{ formatSize(m.file_size) }}</text>
            </view>
          </view>
          <text class="msg-time">{{ formatTime(m.created_at) }}</text>
        </view>
      </view>
      <view v-if="!messages.length" class="chat-empty">暂无消息，打个招呼吧～</view>
    </scroll-view>

    <!-- 输入栏（固定底部） -->
    <view class="chat-input-bar">
      <view class="tool-btn" @click="toggleEmoji" :class="{ active: showEmoji }">
        <text class="tool-emoji">😊</text>
      </view>
      <input
        v-model="inputText"
        class="chat-input"
        placeholder="输入消息..."
        confirm-type="send"
        :disabled="sending"
        @confirm="sendText"
        @focus="hidePanels"
      />
      <view class="tool-btn" @click="toggleMore" :class="{ active: showMore }">
        <MIcon name="info" :size="22" color="#5b6b7b" />
      </view>
      <view class="send-btn" @click="sendText" :class="{ disabled: sending || !inputText.trim() }">
        <MIcon name="send" :size="17" color="#ffffff" />
      </view>
    </view>

    <!-- 表情面板（微信风格：分类 tab + 最近使用） -->
    <view class="panel" v-if="showEmoji">
      <view class="emoji-tabs">
        <view
          class="emoji-tab"
          :class="{ active: emojiTab === t.key }"
          v-for="t in emojiTabs"
          :key="t.key"
          @click="switchEmojiTab(t.key)"
        >
          <text class="emoji-tab-icon">{{ t.icon }}</text>
          <text v-if="t.label" class="emoji-tab-label">{{ t.label }}</text>
        </view>
      </view>
      <scroll-view scroll-y class="emoji-scroll">
        <view class="emoji-grid">
          <text class="emoji-item" v-for="e in currentEmojis" :key="e" @click="appendEmoji(e)">{{ e }}</text>
        </view>
      </scroll-view>
    </view>

    <!-- 更多面板 -->
    <view class="panel" v-if="showMore">
      <view class="more-grid">
        <view class="more-item" @click="pickImage">
          <view class="more-icon"><MIcon name="camera" :size="24" color="#4F46E5" /></view>
          <text class="more-label">图片</text>
        </view>
        <view class="more-item" @click="pickVideo">
          <view class="more-icon"><text class="more-emoji">📹</text></view>
          <text class="more-label">视频</text>
        </view>
        <view class="more-item" @click="pickFile">
          <view class="more-icon"><MIcon name="folder" :size="24" color="#10B981" /></view>
          <text class="more-label">文件</text>
        </view>
      </view>
    </view>
  </view>
</template>

<script setup>
import { ref, computed, onUnmounted } from 'vue'
import { onLoad, onShow, onHide } from '@dcloudio/uni-app'
import { getMessages, sendMessage, markRead, uploadChatFile, getContacts } from '@/api/contacts'
import { getLocalMessages, saveLocalMessages, appendLocalMessage, getRecentEmojis, pushRecentEmoji } from '@/utils/contacts-storage'
import { get } from '@/utils/request.js'

const peerId = ref(0)
const peerName = ref('同事')
const myName = ref('我')
const myAvatar = ref('')
const peerAvatar = ref('')
const peerInfo = ref({})
const messages = ref([])
const inputText = ref('')
const scrollTop = ref(0)
const lastMsgView = ref('')
const sending = ref(false)
const showEmoji = ref(false)
const showMore = ref(false)
const saveDataMode = ref(!!uni.getStorageSync('save_data_mode'))
const emojiTab = ref('recent')
let tempId = 0
let currentUid = ref(0)
let pollTimer = null
let sendingSeq = 0
let lastMsgId = 0
let recentEmojis = []

// ===== 微信风格表情全集（按分类） =====
const EMOJI_SMILE = ['😀','😁','😂','🤣','😃','😄','😅','😆','😉','😊','😋','😎','😍','😘','😗','😙','😚','🙂','🤗','🤔','😐','😑','😶','🙄','😏','😣','😥','😮','🤐','😯','😪','😫','😴','😌','😛','😜','😝','🤤','😒','😓','😔','😕','🙃','🤑','😲','☹️','🙁','😖','😞','😟','😤','😢','😭','😦','😧','😨','😩','🤯','😬','😰','😱','😳','🤪','😵','😡','😠','🤬','😷','🤒','🤕','🤢','🤮','🤧','😇','🥳','🥺','🤠','🤡','🤥','🤫','🤭','🧐','🤓','😈','👿','👹','👺','💀','👻','👽','🤖','💩','😺','😸','😹','😻','😼','😽','🙀','😿','😾']
const EMOJI_HAND = ['👋','🤚','🖐️','✋','🖖','👌','🤏','✌️','🤞','🤟','🤘','🤙','👈','👉','👆','👇','☝️','👍','👎','✊','👊','🤛','🤜','👏','🙌','👐','🤲','🤝','🙏','✍️','💪','🦾','👂','🦻','👃','🧠','🦷','👀','👁️','👅','👄']
const EMOJI_HEART = ['❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔','❣️','💕','💞','💓','💗','💖','💘','💝','💟','💋','💌','💍','💎','👑']
const EMOJI_OTHER = ['💯','💢','💥','💫','💦','💨','💬','💤','🔥','✨','⭐','🌟','🌈','☀️','☁️','⛄','🌸','🌹','🍀','🎉','🎊','🎁','🏆','⚽','🚀','✈️','🎵','🎮','🍺','☕','⚡','🚗','🌙','🐶','🐱','🐼','🐯','🦊','🐰','🙈','🙉','🙊','🐷','🐸','🍎','🍉','🍓','🍔','🍟','🎂','🍦']

const emojiTabs = [
  { key: 'recent', icon: '🕐', label: '' },
  { key: 'smile', icon: '😊', label: '' },
  { key: 'hand', icon: '👋', label: '' },
  { key: 'heart', icon: '❤️', label: '' },
  { key: 'other', icon: '✨', label: '' }
]

const currentEmojis = computed(() => {
  if (emojiTab.value === 'recent') {
    return recentEmojis.length ? recentEmojis : EMOJI_SMILE.slice(0, 32)
  }
  if (emojiTab.value === 'smile') return EMOJI_SMILE
  if (emojiTab.value === 'hand') return EMOJI_HAND
  if (emojiTab.value === 'heart') return EMOJI_HEART
  return EMOJI_OTHER
})

function switchEmojiTab(key) {
  emojiTab.value = key
}

// ===== 工具函数 =====
function formatTime(ts) {
  if (!ts) return ''
  const d = new Date(typeof ts === 'string' ? ts.replace(/-/g, '/') : ts)
  if (isNaN(d.getTime())) return ts
  const pad = n => n < 10 ? '0' + n : '' + n
  return pad(d.getHours()) + ':' + pad(d.getMinutes())
}

function formatSize(bytes) {
  if (!bytes) return ''
  const b = Number(bytes)
  if (b < 1024) return b + 'B'
  if (b < 1024 * 1024) return (b / 1024).toFixed(1) + 'KB'
  if (b < 1024 * 1024 * 1024) return (b / 1024 / 1024).toFixed(1) + 'MB'
  return (b / 1024 / 1024 / 1024).toFixed(1) + 'GB'
}

function markMine(list) {
  return (list || []).map(m => ({ ...m, mine: m.sender_id === currentUid.value }))
}

function scrollToBottom() {
  setTimeout(() => {
    if (messages.value.length) {
      const last = messages.value[messages.value.length - 1]
      lastMsgView.value = last.id < 0 ? 'msg-empty' : 'msg-' + last.id
    }
  }, 60)
}

function ensureScroll() {
  // 有新增/变化消息时滚动到底
  const last = messages.value[messages.value.length - 1]
  if (last && last.id !== lastMsgId) {
    lastMsgId = last.id
    scrollToBottom()
  }
}

// ===== 消息加载 =====
async function loadMessages() {
  if (!peerId.value) return
  try {
    const r = await getMessages(peerId.value, 1, 50)
    if (r.code === 0 && r.data) {
      // 本地缓存（含历史已同步消息）与服务器消息合并：本地完整保留，服务器为准更新同 id
      const list = (r.data.list || []).slice().sort((a, b) => a.id - b.id)
      const map = new Map()
      getLocalMessages(peerId.value).forEach(m => map.set(Number(m.id), m))
      markMine(list).forEach(m => map.set(Number(m.id), m))
      const locals = messages.value.filter(m => m.id < 0)
      const merged = [...locals, ...[...map.values()].sort((a, b) => Number(a.id) - Number(b.id))]
      messages.value = merged
      saveLocalMessages(peerId.value, messages.value)
      markRead(peerId.value).catch(() => {})
      ensureScroll()
    }
  } catch (e) {
    if (!messages.value.length) {
      messages.value = getLocalMessages(peerId.value)
      ensureScroll()
    }
    console.error('loadMessages', e)
  }
}

async function refreshMessages() {
  if (!peerId.value) return
  try {
    const r = await getMessages(peerId.value, 1, 50)
    if (r.code === 0 && r.data) {
      // 保留本地未确认（发送中/上传中）的临时消息
      const locals = messages.value.filter(m => m.id < 0)
      // 本地缓存完整保留，服务器消息更新同 id（本地历史不丢失）
      const map = new Map()
      getLocalMessages(peerId.value).forEach(m => map.set(Number(m.id), m))
      markMine((r.data.list || [])).forEach(m => map.set(Number(m.id), m))
      const merged = [...locals, ...[...map.values()].sort((a, b) => Number(a.id) - Number(b.id))]
      messages.value = merged
      saveLocalMessages(peerId.value, messages.value)
      markRead(peerId.value).catch(() => {})
      ensureScroll()
    }
  } catch (e) {
    console.error('refreshMessages', e)
  }
}

function startPolling() {
  stopPolling()
  pollTimer = setInterval(() => {
    if (peerId.value) refreshMessages()
  }, 2000)
}

function stopPolling() {
  if (pollTimer) {
    clearInterval(pollTimer)
    pollTimer = null
  }
}

async function loadUid() {
  try {
    const r = await get('/api/profile')
    const user = r && r.id ? r : (r && r.data ? r.data : null)
    if (user) {
      currentUid.value = user.id || 0
      myName.value = user.real_name || user.username || '我'
      myAvatar.value = user.avatar || ''
    }
  } catch (e) {
    console.error('loadUid', e)
  }
}

async function loadPeerInfo() {
  if (!peerId.value) return
  try {
    const r = await getContacts('')
    const list = (r && r.data && r.data.list) || []
    const peer = list.find(x => Number(x.id) === Number(peerId.value))
    if (peer) {
      peerAvatar.value = peer.avatar || ''
      peerInfo.value = peer
    }
  } catch (e) {
    console.error('loadPeerInfo', e)
  }
}

// ===== 发送文本（乐观更新，实时显示） =====
async function sendText() {
  const text = inputText.value.trim()
  if (!text || sending.value) return
  sending.value = true
  const temp = { id: --tempId, type: 'text', content: text, mine: true, created_at: new Date().toISOString() }
  messages.value.push(temp)
  inputText.value = ''
  ensureScroll()
  try {
    const r = await sendMessage(peerId.value, { type: 'text', content: text })
    if (r.code === 0 && r.data) {
      const confirmed = { ...r.data, mine: true }
      const idx = messages.value.findIndex(m => m.id === temp.id)
      if (idx >= 0) messages.value[idx] = confirmed
      appendLocalMessage(peerId.value, confirmed)
    } else {
      messages.value = messages.value.filter(m => m.id !== temp.id)
      uni.showToast({ title: r.msg || '发送失败', icon: 'none' })
    }
  } catch (e) {
    messages.value = messages.value.filter(m => m.id !== temp.id)
    uni.showToast({ title: '网络异常', icon: 'none' })
  } finally {
    sending.value = false
  }
}

// ===== 发送图片 =====
function pickImage() {
  hidePanels()
  uni.chooseImage({
    count: 9,
    sizeType: ['compressed'],
    success: (res) => {
      const files = res.tempFilePaths || []
      files.forEach(f => uploadAndSend(f, 'image'))
    }
  })
}

// ===== 发送视频 =====
function pickVideo() {
  hidePanels()
  uni.chooseVideo({
    sourceType: ['album', 'camera'],
    maxDuration: 60,
    compressed: true,
    success: (res) => {
      if (res.tempFilePath) uploadAndSend(res.tempFilePath, 'video', res.size)
    }
  })
}

// ===== 发送文件 =====
function pickFile() {
  hidePanels()
  // H5 端选择任意文件
  // #ifdef H5
  const input = document.createElement('input')
  input.type = 'file'
  input.onchange = (e) => {
    const file = e.target.files && e.target.files[0]
    if (!file) return
    const objUrl = URL.createObjectURL(file)
    uploadAndSend(objUrl, 'file', file.size, file.name)
  }
  input.click()
  // #endif
  // #ifndef H5
  uni.chooseFile && uni.chooseFile({
    count: 1,
    success: (res) => {
      const f = res.tempFiles && res.tempFiles[0]
      if (res.tempFilePath) uploadAndSend(res.tempFilePath, 'file', f ? f.size : 0, f ? f.name : '')
    }
  })
  // #endif
}

async function uploadAndSend(filePath, type, size = 0, name = '') {
  const mySeq = ++sendingSeq
  const temp = { id: --tempId, type, content: '', file_url: '', file_name: name, file_size: size, mine: true, uploading: true, created_at: new Date().toISOString() }
  messages.value.push(temp)
  ensureScroll()
  uni.showLoading({ title: '上传中...', mask: true })
  try {
    const up = await uploadChatFile(filePath, name)
    if (mySeq !== sendingSeq) return
    const payload = {
      type: up.type || type,
      file_url: up.url,
      file_name: up.name || name,
      file_size: up.size || size
    }
    const r = await sendMessage(peerId.value, payload)
    uni.hideLoading()
    if (r.code === 0 && r.data) {
      const confirmed = { ...r.data, mine: true }
      const idx = messages.value.findIndex(m => m.id === temp.id)
      if (idx >= 0) messages.value[idx] = confirmed
      appendLocalMessage(peerId.value, confirmed)
    } else {
      messages.value = messages.value.filter(m => m.id !== temp.id)
      uni.showToast({ title: r.msg || '发送失败', icon: 'none' })
    }
  } catch (e) {
    uni.hideLoading()
    if (mySeq === sendingSeq) {
      messages.value = messages.value.filter(m => m.id !== temp.id)
      uni.showToast({ title: e.message || '上传失败', icon: 'none' })
    }
  }
}

// ===== 表情 =====
function toggleEmoji() {
  showEmoji.value = !showEmoji.value
  showMore.value = false
}
function toggleMore() {
  showMore.value = !showMore.value
  showEmoji.value = false
}
function hidePanels() {
  showEmoji.value = false
  showMore.value = false
}
function appendEmoji(e) {
  inputText.value += e
  pushRecentEmoji(e)
  recentEmojis = getRecentEmojis()
}

// ===== 头像 =====
function avatarSrc(m) {
  return m.mine ? (myAvatar.value || '') : (peerAvatar.value || '')
}
function avatarText(m) {
  const name = m.mine ? myName.value : (peerName.value || '?')
  return (name || '?').substring(0, 1)
}
function showMyProfile() {
  uni.navigateTo({ url: '/pages/profile/index' })
}
function showPeerProfile() {
  const p = peerInfo.value
  const d = {
    id: peerId.value,
    name: p.real_name || peerName.value || '同事',
    username: p.username || '',
    phone: p.phone || '',
    email: p.email || '',
    avatar: p.avatar || '',
    status: p.status === undefined ? 1 : p.status
  }
  uni.navigateTo({
    url: '/pages/contacts/detail?d=' + encodeURIComponent(JSON.stringify(d))
  })
}

// ===== 预览/打开 =====
function loadImg(m) {
  m.img_loaded = true
  try {
    const msgs = messages.value
    const idx = msgs.findIndex(x => x.id === m.id)
    if (idx >= 0) msgs[idx].img_loaded = true
  } catch (e) {}
}

function previewImage(m) {
  const urls = messages.value.filter(x => x.type === 'image' && x.file_url).map(x => x.file_url)
  const idx = urls.indexOf(m.file_url)
  uni.previewImage({ urls: urls.length ? urls : [m.file_url], current: idx >= 0 ? idx : 0 })
}

function openFile(m) {
  if (!m.file_url) return
  uni.showLoading({ title: '下载中...' })
  uni.downloadFile({
    url: m.file_url,
    success: (res) => {
      uni.hideLoading()
      if (res.statusCode === 200 && res.tempFilePath) {
        uni.openDocument({ filePath: res.tempFilePath, showMenu: true, fail: () => {
          uni.showToast({ title: '该格式暂不支持预览', icon: 'none' })
        } })
      } else {
        uni.showToast({ title: '下载失败', icon: 'none' })
      }
    },
    fail: () => { uni.hideLoading(); uni.showToast({ title: '下载失败', icon: 'none' }) }
  })
}

onLoad((o) => {
  peerId.value = parseInt(o.peer_id || o.id || 0, 10)
  peerName.value = decodeURIComponent(o.name || '同事')
  uni.setNavigationBarTitle({ title: peerName.value })
  if (peerId.value) {
    recentEmojis = getRecentEmojis()
    loadUid().then(() => {
      messages.value = getLocalMessages(peerId.value)
      if (messages.value.length) ensureScroll()
      loadMessages()
      loadPeerInfo()
      startPolling()
    }).catch(() => {
      messages.value = getLocalMessages(peerId.value)
      loadMessages()
      loadPeerInfo()
      startPolling()
    })
  }
})

onShow(() => {
  if (peerId.value) refreshMessages()
})

onHide(() => {
  stopPolling()
})

onUnmounted(() => {
  stopPolling()
})
</script>

<style scoped>
/* ===== 布局：页面不滚动，消息区独立滚动，输入栏固定底部 ===== */
.chat-page {
  height: calc(100vh - var(--window-top, 0px) - var(--window-bottom, 0px));
  overflow: hidden;
  background: #F4F6FB;
  display: flex;
  flex-direction: column;
}
.chat-empty { text-align: center; color: #b0c0cc; padding: 60px 0; font-size: 13px; }
.chat-list {
  flex: 1;
  min-height: 0;
  height: 0;
  padding: 16px 14px 12px;
  box-sizing: border-box;
}
.msg-row { display: flex; align-items: flex-start; gap: 8px; margin-bottom: 16px; }
.msg-row.mine { flex-direction: row-reverse; }
.msg-row.other { flex-direction: row; }
.msg-avatar {
  width: 40px; height: 40px; border-radius: 50%; flex-shrink: 0;
  overflow: hidden; background: #3d5a73; display: flex; align-items: center; justify-content: center;
}
.msg-avatar-img { width: 100%; height: 100%; display: block; background: #e8edf3; }
.msg-avatar-text { color: #fff; font-size: 15px; font-weight: 500; }
.msg-body { display: flex; flex-direction: column; max-width: 75%; }
.msg-row.mine .msg-body { align-items: flex-end; }
.msg-row.other .msg-body { align-items: flex-start; }
.bubble { max-width: 100%; padding: 10px 14px; border-radius: 18px; font-size: calc(14px * var(--font-scale, 1)); line-height: 1.6; word-break: break-word; }
.msg-row.mine .bubble { background: linear-gradient(135deg, #4F46E5, #7C6FF0); color: #fff; border-bottom-right-radius: 4px; }
.msg-row.other .bubble { background: #fff; color: #2a3a4a; border-bottom-left-radius: 4px; box-shadow: 0 2px 8px rgba(31, 45, 61, 0.05); }
.bubble.img-bubble { padding: 4px; border-radius: 14px; overflow: hidden; }
.msg-img-placeholder { width: 160px; height: 120px; border-radius: 10px; background: #F1F4F8; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 6px; }
.msg-img-placeholder .ph-icon { font-size: 28px; }
.msg-img-placeholder .ph-text { font-size: 12px; color: #9aabba; }
.msg-img { width: 160px; height: 160px; border-radius: 10px; display: block; background: #eef1f6; }
.video-bubble { padding: 4px; border-radius: 14px; overflow: hidden; }
.msg-video { width: 220px; height: 160px; border-radius: 10px; background: #000; }
.file-bubble { display: flex; align-items: center; gap: 10px; min-width: 150px; }
.file-info { display: flex; flex-direction: column; }
.file-name { font-size: 13px; max-width: 160px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.file-size { font-size: 11px; opacity: 0.7; margin-top: 2px; }
.msg-row.mine .file-name, .msg-row.mine .file-size { color: #fff; }
.msg-time { font-size: 11px; color: #b0c0cc; margin-top: 4px; }

/* 输入栏：不参与滚动，始终贴底 */
.chat-input-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 12px;
  background: #fff;
  border-top: 1px solid #EDF0F8;
  padding-bottom: calc(10px + env(safe-area-inset-bottom));
  flex-shrink: 0;
}
.tool-btn { width: 38px; height: 38px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; transition: background 0.2s; }
.tool-btn.active { background: #EEF0FE; }
.tool-emoji { font-size: 22px; line-height: 1; }
.chat-input { flex: 1; height: 40px; background: #EDF0F8; border-radius: 20px; padding: 0 16px; font-size: 14px; }
.send-btn { width: 40px; height: 40px; border-radius: 50%; background: linear-gradient(135deg, #4F46E5, #7C6FF0); color: #fff; display: flex; align-items: center; justify-content: center; flex-shrink: 0; transition: all 0.2s; }
.send-btn.disabled { opacity: 0.45; }
.send-btn:active { transform: scale(0.9); }

/* 面板：贴输入栏下方，不参与页面滚动 */
.panel {
  background: #fff;
  border-top: 1px solid #EDF0F8;
  flex-shrink: 0;
}
/* 表情面板（微信风格） */
.emoji-tabs {
  display: flex;
  border-bottom: 1px solid #F0F2F7;
  padding: 6px 8px 0;
}
.emoji-tab {
  flex: 1;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 10px 10px 0 0;
  position: relative;
}
.emoji-tab.active { background: #F7F8FC; }
.emoji-tab.active::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 50%;
  transform: translateX(-50%);
  width: 24px;
  height: 3px;
  border-radius: 2px;
  background: linear-gradient(135deg, #4F46E5, #7C6FF0);
}
.emoji-tab-icon { font-size: 22px; line-height: 1; }
.emoji-tab-label { font-size: 12px; color: #5b6b7b; }
.emoji-scroll {
  height: 220px;
  padding: 10px 8px calc(10px + env(safe-area-inset-bottom));
  box-sizing: border-box;
}
.emoji-grid { display: flex; flex-wrap: wrap; }
.emoji-item { width: 12.5%; height: 46px; display: flex; align-items: center; justify-content: center; font-size: 27px; }
.emoji-item:active { background: #F4F6FB; border-radius: 8px; }
/* 更多面板 */
.more-grid { display: flex; padding: 14px 12px calc(14px + env(safe-area-inset-bottom)); }
.more-item { display: flex; flex-direction: column; align-items: center; gap: 6px; width: 70px; }
.more-icon { width: 50px; height: 50px; border-radius: 14px; background: #F4F6FB; display: flex; align-items: center; justify-content: center; }
.more-emoji { font-size: 24px; line-height: 1; }
.more-label { font-size: 12px; color: #5b6b7b; }
</style>
