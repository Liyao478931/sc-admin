// ============================================================================
// 文件路径：src/utils/url.js
// URL 参数工具函数
// ============================================================================

/**
 * 将参数对象转为 URL 查询字符串
 * @param {Object} params 参数对象，如 { id: 1, type: 'home' }
 * @returns {string} 查询字符串，如 '?id=1&type=home'；无参数返回 ''
 */
export function buildQuery(params = {}) {
  const keys = Object.keys(params).filter(k => params[k] !== undefined && params[k] !== null && params[k] !== '')
  if (keys.length === 0) return ''
  const query = keys.map(k => `${encodeURIComponent(k)}=${encodeURIComponent(params[k])}`).join('&')
  return '?' + query
}

/**
 * 解析 URL 查询字符串为参数对象
 * @param {string} query 查询字符串，如 '?id=1&type=home' 或 'id=1&type=home'
 * @returns {Object} 参数对象，如 { id: '1', type: 'home' }
 */
export function parseQuery(query = '') {
  const q = query.startsWith('?') ? query.slice(1) : query
  if (!q) return {}
  const result = {}
  q.split('&').forEach(pair => {
    if (!pair) return
    const [key, value] = pair.split('=')
    if (key) result[decodeURIComponent(key)] = decodeURIComponent(value || '')
  })
  return result
}

/**
 * 将基础路径与参数对象拼接为完整路径
 * @param {string} path 基础路径，如 '/pages/diy/index'
 * @param {Object} params 参数对象
 * @returns {string} 完整路径，如 '/pages/diy/index?type=home'
 */
export function joinPath(path, params = {}) {
  const query = buildQuery(params)
  if (!query) return path
  // path 已含 ? 时用 & 追加，避免 type=home?from=legacy 类错误
  return path + (path.includes('?') ? '&' + query.slice(1) : query)
}
