/**
 * WebAuthn / FIDO2 API
 */
import request from './request'

// ---- 登录流程（公开） ----
export const fido2LoginCheck = (data) => request({ url: '/webauthn/login/check', method: 'post', data })
export const fido2LoginStart = (data) => request({ url: '/webauthn/login/start', method: 'post', data })
export const fido2LoginComplete = (data) => request({ url: '/webauthn/login/complete', method: 'post', data })

// ---- 绑定流程（登录态 或 step 待绑定会话） ----
export const fido2RegisterStart = (data) => request({ url: '/webauthn/register/start', method: 'post', data: data || {} })
export const fido2RegisterComplete = (data) => request({ url: '/webauthn/register/complete', method: 'post', data })

// ---- 扫码绑定（PC 生成二维码、手机完成 Passkey 注册；需登录） ----
export const fido2QRCodeRegisterCreate = (data) => request({ url: '/webauthn/qrcode/register/create', method: 'post', data: data || {} })
export const fido2QRCodeStatus = (params) => request({ url: '/webauthn/qrcode/status', method: 'get', params })

// ---- 个人中心（需登录） ----
export const getFido2UserStatus = () => request({ url: '/user/webauthn/status', method: 'get' })
export const unbindFido2 = (data) => request({ url: '/user/webauthn/unbind', method: 'delete', data })

// ---- 管理端策略（需登录） ----
export const getFido2PolicyConfig = () => request({ url: '/settings/fido2/config', method: 'get' })
export const saveFido2PolicyConfig = (d) => request({ url: '/settings/fido2/config', method: 'put', data: d })
export const getFido2Forced = (params) => request({ url: '/settings/fido2/forced', method: 'get', params })
export const addFido2Forced = (d) => request({ url: '/settings/fido2/forced', method: 'post', data: d })
export const deleteFido2Forced = (d) => request({ url: '/settings/fido2/forced', method: 'delete', data: d })
/** 搜索用户（添加强制用户用） */
export const fido2UserOptions = (params) => request({ url: '/settings/fido2/users', method: 'get', params })
/** 角色下拉（添加强制角色用） */
export const fido2RoleOptions = () => request({ url: '/settings/fido2/roles', method: 'get' })
/** 部门下拉（添加强制部门用） */
export const fido2DepartmentOptions = () => request({ url: '/settings/fido2/departments', method: 'get' })
