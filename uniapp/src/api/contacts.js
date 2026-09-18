// 通讯录 API（员工间内部消息）
import { get, post } from '@/utils/request'

/** 联系人列表（系统启用用户，可按关键字过滤） */
export function getContacts(keyword = '') {
  return get('/api/mobile/contacts/contacts', { keyword })
}

/** 会话列表（每个 peer 一条最近消息 + 未读数） */
export function getChats() {
  return get('/api/mobile/contacts/chats')
}

/** 与指定 peer 的消息历史（双向，分页） */
export function getMessages(peerId, page = 1, limit = 20) {
  return get('/api/mobile/contacts/messages', { peer: peerId, page, limit })
}

/** 发送消息给指定 peer（text/image/video/file） */
export function sendMessage(peerId, payload) {
  return post('/api/mobile/contacts/messages', Object.assign({ peer_id: peerId }, payload))
}

/** 标记来自指定 peer 的未读消息为已读 */
export function markRead(peerId) {
  return post('/api/mobile/contacts/read', { peer_id: peerId })
}

function getToken() {
  return uni.getStorageSync('access_token') || ''
}

/**
 * 上传聊天文件（图片/视频/资料），返回 { url, name, size, type }
 * @param {string} filePath 本地文件路径（chooseImage/chooseVideo 返回值）
 * @param {string} name 原始文件名
 */
export function uploadChatFile(filePath, name = '') {
  return new Promise((resolve, reject) => {
    uni.uploadFile({
      url: (uni.$base || '') + '/api/mobile/contacts/upload',
      filePath,
      name: 'file',
      formData: { name },
      header: { 'Authorization': 'Bearer ' + getToken() },
      success: (res) => {
        try {
          const data = JSON.parse(res.data)
          if (data.code === 0) resolve(data.data)
          else reject(new Error(data.msg || '上传失败'))
        } catch (e) {
          reject(new Error('上传响应异常'))
        }
      },
      fail: (e) => reject(new Error('上传失败：网络异常'))
    })
  })
}
