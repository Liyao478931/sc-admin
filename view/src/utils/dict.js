/**
 * 字典工具函数
 * 提供前端字典数据获取和转换方法
 * 使用方式：
 *   import { getDictionary, getDictLabel } from '@/utils/dict'
 *   const items = await getDictionary('user_type')
 *   const label = getDictLabel(items, 'backend')
 */
import store from '@/store'

/**
 * 获取字典数据（优先走 Vuex 缓存）
 * @param {string} code 字典类型编码
 * @returns {Promise<Array>} 字典条目数组 [{label, value, style, extra}]
 */
export async function getDictionary(code) {
  try {
    return await store.dispatch('dictionary/getDictionary', code)
  } catch (e) {
    return []
  }
}

/**
 * 批量获取字典数据
 * @param {string[]} codes 字典类型编码数组
 * @returns {Promise<Object>} { code: items[] }
 */
export async function getDictionaryBatch(codes) {
  try {
    return await store.dispatch('dictionary/getDictionaryBatch', codes)
  } catch (e) {
    const result = {}
    codes.forEach(c => { result[c] = [] })
    return result
  }
}

/**
 * 根据字典值和条目列表获取对应的标签
 * @param {Array} items 字典条目列表
 * @param {string|number} value 字典值
 * @returns {string} 字典标签
 */
export function getDictLabel(items, value) {
  if (!items || !items.length) return value
  const item = items.find(i => String(i.value) === String(value))
  return item ? item.label : value
}

/**
 * 根据字典值和条目列表获取对应的样式类型
 * @param {Array} items 字典条目列表
 * @param {string|number} value 字典值
 * @returns {string} 样式类型
 */
export function getDictStyle(items, value) {
  if (!items || !items.length) return ''
  const item = items.find(i => String(i.value) === String(value))
  return item ? (item.style || '') : ''
}

/**
 * 清除字典缓存
 * @param {string} [code] 指定编码，不传则清除全部
 */
export function clearDictCache(code) {
  store.commit('dictionary/CLEAR_DICT', code || null)
}
