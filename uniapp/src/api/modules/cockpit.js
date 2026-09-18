import { get } from '../../utils/request.js'

// 移动端驾驶舱数据
export function getCockpitOverview() {
  return get('/api/mobile/cockpit/overview')
}
