/**
 * 腾讯云人脸识别服务配置 API
 * 路由前缀：/services/face
 */
import request from './request'

/** 获取人脸识别服务配置 */
export const getFaceConfig = () => request({ url: '/services/face/config', method: 'get' })

/** 保存人脸识别服务配置 */
export const saveFaceConfig = (d) => request({ url: '/services/face/config', method: 'put', data: d })

/** 测试连接（探测人员库鉴权） */
export const testFace = () => request({ url: '/services/face/test', method: 'post' })

/** 获取服务状态 */
export const getFaceStatus = () => request({ url: '/services/face/status', method: 'get' })

/** 人脸录入 */
export const faceCreate = (d) => request({ url: '/face/create', method: 'post', data: d })

/** 人脸搜索（1:N 匹配） */
export const faceSearch = (d) => request({ url: '/face/search', method: 'post', data: d })

/** 删除人员 */
export const faceDelete = (d) => request({ url: '/face/delete', method: 'post', data: d })

/** 获取人员信息 */
export const faceInfo = (personId) => request({ url: '/face/info', method: 'get', params: { person_id: personId } })

/** 人脸检测 */
export const faceDetect = (d) => request({ url: '/face/detect', method: 'post', data: d })

/** 获取服务配置（调试） */
export const getFaceSvcConfig = () => request({ url: '/face/config', method: 'get' })
