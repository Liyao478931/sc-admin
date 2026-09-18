import request from './request'

// ============ CRMEB 风格 DIY 接口 ============

/** 页面列表 */
export function diyLst(params) {
  return request({ url: '/admin/diy2/lst', method: 'get', params })
}

/** 页面详情 */
export function diyDetail(id) {
  return request({ url: `/admin/diy2/detail/${id}`, method: 'get' })
}

/** 保存页面（新建 id=0 / 更新 id>0） */
export function diySave(id, data) {
  return request({ url: id ? `/admin/diy2/create/${id}` : '/admin/diy2/create', method: 'post', data })
}

/** 删除页面 */
export function diyDel(id) {
  return request({ url: `/admin/diy2/delete/${id}`, method: 'delete' })
}

/** 使用页面 */
export function diyStatus(id) {
  return request({ url: `/admin/diy2/status/${id}`, method: 'post' })
}

/** 复制页面 */
export function diyCopy(id) {
  return request({ url: `/admin/diy2/copy/${id}`, method: 'get' })
}

/** 设置默认数据 */
export function diySetDefault(id) {
  return request({ url: `/admin/diy2/set_default_data/${id}`, method: 'post' })
}

/** 恢复默认数据 */
export function diyRecovery(id) {
  return request({ url: `/admin/diy2/recovery/${id}`, method: 'get' })
}

/** 公开渲染接口（预览用） */
export function diyPageData(type) {
  return request({ url: `/diy2/pages/${type}`, method: 'get' })
}

/** 获取路径管理全部链接（DIY 链接选择器用） */
export function getPathOptions() {
  return request({ url: '/admin/paths/options', method: 'get' })
}

/** 角色下拉选项（DIY 页面权限配置用） */
export function getRoleOptions() {
  return request({ url: '/admin/roles/options', method: 'get' })
}

/** 用户下拉选项（DIY 页面权限配置用） */
export function getUserOptions() {
  return request({ url: '/admin/users/options', method: 'get' })
}

// ============ 底部导航配置（D方案） ============
export function tabList(params) { return request({ url: '/admin/tab-config/list', method: 'get', params }) }
export function tabDetail(id) { return request({ url: `/admin/tab-config/detail/${id}`, method: 'get' }) }
export function tabCreate(data) { return request({ url: '/admin/tab-config/create', method: 'post', data }) }
export function tabUpdate(id, data) { return request({ url: `/admin/tab-config/update/${id}`, method: 'put', data }) }
export function tabDelete(id) { return request({ url: `/admin/tab-config/delete/${id}`, method: 'delete' }) }
export function tabSort(items) { return request({ url: '/admin/tab-config/sort', method: 'put', data: { items } }) }
