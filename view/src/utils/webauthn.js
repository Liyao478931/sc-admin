/**
 * WebAuthn 工具函数
 * base64url 编解码 + 注册/认证参数转换 + 浏览器能力检测
 */

/** base64url → ArrayBuffer（兼容 lbuchs/webauthn 的 RFC2047 风格 `=?BINARY?B?...?=` 包装，注意开头为 `=?`） */
export function base64urlToBuffer (b64) {
  let s = String(b64)
  const wrapped = s.match(/^=\?[^?]*\?B\?([^?]*)\?=$/)
  if (wrapped) s = wrapped[1]
  let base64 = s.replace(/-/g, '+').replace(/_/g, '/')
  while (base64.length % 4) base64 += '='
  const bin = atob(base64)
  const buf = new Uint8Array(bin.length)
  for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i)
  return buf.buffer
}

/** ArrayBuffer → base64url（无 padding） */
export function bufferToBase64url (buf) {
  const bytes = new Uint8Array(buf)
  let bin = ''
  for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i])
  return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

/** 浏览器是否支持 WebAuthn */
export function isWebAuthnSupported () {
  return typeof window !== 'undefined' && !!window.PublicKeyCredential
}

/** 后端注册参数 → navigator.credentials.create 的 publicKey（兼容 {publicKey:{...}} 包装） */
export function toCreatePublicKey (args) {
  const a = args.publicKey || args
  const pk = {
    challenge: base64urlToBuffer(a.challenge),
    rp: { id: a.rp.id, name: a.rp.name || a.rp.id },
    user: {
      id: base64urlToBuffer(a.user.id),
      name: a.user.name,
      displayName: a.user.displayName || a.user.name
    },
    pubKeyCredParams: a.pubKeyCredParams,
    timeout: a.timeout || 60000,
    attestation: 'none', // 固定 none：不要求 attestation 证书，兼容平台/虚拟认证器
    authenticatorSelection: a.authenticatorSelection || { userVerification: 'required' }
  }
  if (a.excludeCredentials && a.excludeCredentials.length) {
    pk.excludeCredentials = a.excludeCredentials.map(c => ({
      id: base64urlToBuffer(c.id),
      type: c.type || 'public-key',
      transports: c.transports || ['usb']
    }))
  }
  return pk
}

/** 后端认证参数 → navigator.credentials.get 的 publicKey（兼容 {publicKey:{...}} 包装） */
export function toGetPublicKey (args) {
  const a = args.publicKey || args
  const pk = {
    challenge: base64urlToBuffer(a.challenge),
    rpId: a.rpId,
    timeout: a.timeout || 60000,
    userVerification: a.userVerification || 'required'
  }
  if (a.allowCredentials && a.allowCredentials.length) {
    pk.allowCredentials = a.allowCredentials.map(c => ({
      id: base64urlToBuffer(c.id),
      type: c.type || 'public-key',
      transports: c.transports || ['usb']
    }))
  }
  return pk
}

/** 发起注册（绑定手机密钥） */
export async function createCredential (args) {
  const credential = await navigator.credentials.create({ publicKey: toCreatePublicKey(args) })
  return {
    rawId: bufferToBase64url(credential.rawId),
    id: credential.id,
    clientDataJSON: bufferToBase64url(credential.response.clientDataJSON),
    attestationObject: bufferToBase64url(credential.response.attestationObject),
    transports: credential.response.getTransports ? credential.response.getTransports() : ['usb']
  }
}

/** 发起认证（登录二次验证） */
export async function getAssertion (args) {
  const assertion = await navigator.credentials.get({ publicKey: toGetPublicKey(args) })
  return {
    rawId: bufferToBase64url(assertion.rawId),
    id: assertion.id,
    clientDataJSON: bufferToBase64url(assertion.response.clientDataJSON),
    authenticatorData: bufferToBase64url(assertion.response.authenticatorData),
    signature: bufferToBase64url(assertion.response.signature),
    userHandle: assertion.response.userHandle ? bufferToBase64url(assertion.response.userHandle) : null
  }
}

/** 将 WebAuthn 异常转为友好提示 */
export function webauthnErrorText (err) {
  const name = err && err.name
  if (name === 'NotAllowedError') return '验证超时或已取消，请重试'
  if (name === 'NotSupportedError') return '当前浏览器不支持 WebAuthn，请使用 Chrome/Edge 浏览器'
  if (name === 'InvalidStateError') return '该认证器已在系统中注册，无需重复绑定'
  if (name === 'SecurityError') return '安全环境校验失败，请确认使用 HTTPS 访问'
  return (err && err.message) ? err.message : '验证失败'
}
