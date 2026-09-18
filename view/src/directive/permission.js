import store from '@/store'

function hasPermission(value) {
  const user = store.state.user
  const perms = user?.permissions || []
  const userInfo = user?.userInfo || {}
  // 超级管理员直接放行（与后端 checkPerm / 路由守卫一致）
  if (!!userInfo.is_super_admin || perms.indexOf('super_admin') > -1) return true
  if (!perms.length) return false
  if (typeof value === 'string') return perms.includes(value)
  if (Array.isArray(value)) return value.some(p => perms.includes(p))
  if (typeof value === 'object') {
    if (value.or) return value.or.some(p => perms.includes(p))
    if (value.and) return value.and.every(p => perms.includes(p))
  }
  return false
}

export default {
  install(Vue) {
    Vue.directive('permission', {
      inserted(el, { value }) { if (!hasPermission(value)) el.parentNode?.removeChild(el) },
      update(el, { value }) { if (!hasPermission(value)) el.parentNode?.removeChild(el) }
    })
  }
}
