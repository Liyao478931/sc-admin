import { get } from '../utils/request.js'

/**
 * 获取装修页面数据（CRMEB 风格新接口）
 * @param {string|number} type - 页面类型: home/index/自定义页面名或id
 */
export function getDiyPage(type = 'home') {
  return get('/api/diy2/pages/' + type)
}
