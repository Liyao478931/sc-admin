/**
 * 后台人脸录入管理 API
 * 路由前缀：/admin/face
 */
import request from './request'

/** 获取员工人脸状态列表 */
export const getFaceList = (params) => request({ url: '/admin/face/list', method: 'get', params })

/** 录入/重新录入人脸（大 Base64 图片用 JSON 提交，避免 urlencoded 转义膨胀） */
export const registerFace = (data) => request({
  url: '/admin/face/register',
  method: 'post',
  data,
  headers: { 'Content-Type': 'application/json' }
})

/** 删除人脸 */
export const deleteFace = (userId) => request({ url: `/admin/face/delete/${userId}`, method: 'delete' })

/** 获取人脸信息（查看照片） */
export const getFaceInfo = (userId) => request({ url: `/admin/face/info/${userId}`, method: 'get' })
