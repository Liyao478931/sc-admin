// 通讯录聊天记录本地缓存（统一接口，H5/小程序通用）
// key: chat_msgs_<peer_id>，value: 消息列表（含 text/image/video/file 完整对象，按 id 正序）
const KEY = (peerId) => `chat_msgs_${peerId}`
const MAX_PER_PEER = 200

function norm(list) {
  return (Array.isArray(list) ? list : []).sort((a, b) => (Number(a.id) || 0) - (Number(b.id) || 0))
}

export function getLocalMessages(peerId) {
  if (!peerId) return []
  try {
    const raw = uni.getStorageSync(KEY(peerId))
    return Array.isArray(raw) ? raw : []
  } catch (e) {
    return []
  }
}

export function saveLocalMessages(peerId, list) {
  if (!peerId) return
  try {
    const sorted = norm(list)
    const trimmed = sorted.length > MAX_PER_PEER ? sorted.slice(sorted.length - MAX_PER_PEER) : sorted
    uni.setStorageSync(KEY(peerId), trimmed)
  } catch (e) {
    // 存储满或失败时静默忽略
  }
}

/** 追加或更新单条消息（同 id 去重），保留完整字段（type/file_url/file_name/file_size） */
export function appendLocalMessage(peerId, msg) {
  if (!peerId || !msg) return
  const list = getLocalMessages(peerId)
  const idx = list.findIndex(m => String(m.id) === String(msg.id))
  if (idx >= 0) list[idx] = msg
  else list.push(msg)
  saveLocalMessages(peerId, list)
}

/** 最近使用的表情（跨会话），最多 30 个 */
const RECENT_KEY = 'chat_recent_emojis'
export function getRecentEmojis() {
  try {
    const raw = uni.getStorageSync(RECENT_KEY)
    return Array.isArray(raw) ? raw : []
  } catch (e) {
    return []
  }
}
export function pushRecentEmoji(e) {
  if (!e) return
  try {
    const list = getRecentEmojis().filter(x => x !== e)
    list.unshift(e)
    uni.setStorageSync(RECENT_KEY, list.slice(0, 30))
  } catch (err) {
    // 忽略
  }
}
