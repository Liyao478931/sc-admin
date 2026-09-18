/**
 * 消息偏好设置 API
 * 路由前缀：/notification/preference（需登录）
 */
import request from './request'

/** 获取当前用户偏好设置 */
export const getNotificationPreference = () => request({ url: '/notification/preference', method: 'get' })

/** 保存偏好设置 */
export const saveNotificationPreference = (d) => request({ url: '/notification/preference', method: 'put', data: d })
