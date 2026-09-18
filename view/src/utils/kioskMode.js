/**
 * 大屏轮播 / 展示（Kiosk）模式检测
 *
 * 背景：系统存在"大屏轮播模式"——在无人工操作时由定时器自动切换标签页/页面，
 * 用于大厅/会议室大屏轮巡展示。该模式下会经过一些"隐藏深链"路由（如
 * /business/customer/create、/business/order/add 等），这些路由本意是"新增XX"
 * 菜单进入时自动打开新增弹窗，但在轮播模式下被定时导航命中，导致自动打开写弹窗、
 * 自动提交表单等副作用，严重影响数据安全与体验。
 *
 * 规则：轮播/展示模式（无人工操作、定时自动切换）下必须禁用一切写操作自动触发；
 * 手动点击操作不受影响。
 *
 * 判定信号（任一命中即视为轮播/展示模式）：
 *   1. window.__SC_CAROUSEL_MODE__ === true（轮播外壳进入时置位，退出时清除）
 *   2. URL 查询参数 ?carousel=1 / ?screen=1 / ?kiosk=1 / ?demo=1
 */
export function isCarouselMode() {
  try {
    if (typeof window !== 'undefined' && window.__SC_CAROUSEL_MODE__ === true) return true
    if (typeof location !== 'undefined' && location.search) {
      var q = new URLSearchParams(location.search)
      if (['carousel', 'screen', 'kiosk', 'demo'].some(function (k) { return q.get(k) === '1' })) return true
    }
  } catch (e) { /* ignore */ }
  return false
}

export default isCarouselMode
