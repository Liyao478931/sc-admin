import request from './request'

/** 获取路径选项（供页面编辑器使用） */
export function getPathOptions() {
  return request({ url: '/admin/paths/options', method: 'get' })
}
