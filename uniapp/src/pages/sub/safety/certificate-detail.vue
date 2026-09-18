<template>
  <view class="certificate-detail-page">
    <scroll-view scroll-y class="detail-scroll">
      <!-- 证书展示：H5 内嵌 web-view 加载后台证书（与后台完全一致）；小程序卡片跳转全屏 web-view -->
      <!-- #ifdef H5 -->
      <view class="section cert-web-section">
        <web-view v-if="certViewUrl" :src="certViewUrl" class="cert-web"></web-view>
        <view v-else class="cv-loading">证书加载中...</view>
      </view>
      <!-- #endif -->
      <!-- #ifndef H5 -->
      <view class="section cert-entry-section" @click="openCertWeb">
        <view class="cert-entry">
          <view class="cert-entry-title">{{ certTitle }}</view>
          <view class="cert-entry-code">证书编号：{{ cert.certificate_code }}</view>
          <view class="cert-entry-status">
            <text v-if="cert.status === 'expired'" class="status-tag expired">过期</text>
            <text v-else-if="cert.expiring_soon" class="status-tag soon">即将过期</text>
            <text v-else class="status-tag valid">有效</text>
          </view>
          <view class="cert-entry-tip">点击查看证书（与后台一致）</view>
        </view>
      </view>
      <!-- #endif -->
        <!-- 离屏 canvas（仅用于下载导出） -->
        <canvas canvas-id="certCanvas" id="certCanvas" class="cert-canvas"></canvas>

      <!-- 证书放大弹窗（H5 全屏大图） -->
      <view v-if="fullImage" class="full-mask" @click="fullImage = ''">
        <image :src="fullImage" class="full-img" mode="widthFix" @longpress="saveLongPress" @click.stop />
        <text class="full-tip">点击空白处关闭 · 长按图片保存</text>
      </view>

      <!-- 证书基本信息 -->
      <view class="section">
        <view class="section-title">证书信息</view>
        <view class="info-row"><text class="info-label">证书名称</text><text class="info-value">{{ cert.certificate_name }}</text></view>
        <view class="info-row"><text class="info-label">证书编号</text><text class="info-value">{{ cert.certificate_code }}</text></view>
        <view class="info-row"><text class="info-label">培训名称</text><text class="info-value">{{ cert.training_name }}</text></view>
        <view class="info-row"><text class="info-label">培训类型</text><text class="info-value">{{ cert.training_type_name }}</text></view>
        <view class="info-row"><text class="info-label">颁发日期</text><text class="info-value">{{ cert.issue_date }}</text></view>
        <view class="info-row"><text class="info-label">有效期截止</text><text class="info-value">{{ cert.expire_date || '长期有效' }}</text></view>
        <view class="info-row">
          <text class="info-label">证书状态</text>
          <text v-if="cert.status === 'expired'" class="status-tag expired">过期</text>
          <text v-else-if="cert.expiring_soon" class="status-tag soon">即将过期</text>
          <text v-else class="status-tag valid">有效</text>
        </view>
      </view>

      <!-- 关联培训信息 -->
      <view v-if="cert.training" class="section">
        <view class="section-title">关联培训</view>
        <view class="info-row"><text class="info-label">培训名称</text><text class="info-value">{{ cert.training.plan_name }}</text></view>
        <view class="info-row"><text class="info-label">培训日期</text><text class="info-value">{{ cert.training.training_date || '-' }}</text></view>
        <view class="info-row"><text class="info-label">培训方式</text><text class="info-value">{{ cert.training.mode_text }}</text></view>
      </view>
    </scroll-view>

    <!-- H5 长按保存图片（置于 scroll-view 外，避免触摸拦截长按菜单） -->
    <view v-if="certImageUrl" class="cert-save-box">
      <view class="cert-save-label">长按图片保存到相册</view>
      <!-- #ifdef H5 -->
      <img :src="certImageUrl" class="cert-save-img" @click="openCertImage" />
      <!-- #endif -->
      <!-- #ifndef H5 -->
      <image :src="certImageUrl" class="cert-save-img" mode="widthFix" show-menu-by-longpress />
      <!-- #endif -->
      <view class="cert-save-tip">长按图片，弹出「保存图片」后点击保存</view>
      <view class="cert-open-btn" @click="openCertImage">若长按无反应，点此打开图片保存</view>
    </view>

    <!-- 底部操作按钮 -->
    <view class="bottom-bar">
      <button class="save-btn" :disabled="saving" @click="saveCert">{{ saving ? '保存中...' : '下载证书' }}</button>
      <button class="back-btn" @click="goBack">返回</button>
    </view>
  </view>
</template>

<script>
import { getCertificateDetail, downloadCertificate } from '../../../api/index.js'
import { BASE_URL, get } from '@/utils/request.js'

export default {
  data() {
    return {
      certId: 0,
      cert: {},
      saving: false,
      certImageUrl: '',
      fullImage: ''
    }
  },
  computed: {
    certCompany() {
      // 优先后端返回的系统设置公司名，其次证书数据
      return this.cert.company_name || this.cert.certificate_data?.company || this.cert.certificate_data?.company_name || '华能装备'
    },
    // 证书标题（与后台一致：取证书实际名称，兜底“培训证书”）
    certTitle() {
      const d = this.cert.certificate_data || {}
      return d.title || this.cert.certificate_name || '培训证书'
    },
    // 证书展示 URL（后台纯证书页，与后台完全一致；身份证号已脱敏）
    certViewUrl() {
      const code = this.cert.certificate_code || ''
      if (!code) return ''
      return (BASE_URL || '') + '/api/certificate/view?code=' + encodeURIComponent(code)
    },
    // 证书图片下载 URL（后端 Chromium 渲染 PNG，与后台完全一致）
    certDownloadUrl() {
      const code = this.cert.certificate_code || ''
      if (!code) return ''
      return (BASE_URL || '') + '/api/certificate/image?code=' + encodeURIComponent(code)
    },
    // 公章公司名（环绕圆框用）
    stampChars() {
      const s = this.certCompany || ''
      return s.split('')
    },
    stampDeg() {
      const n = this.stampChars.length || 1
      return (360 / n).toFixed(2)
    },
    // 公章上弧公司全称（与后台一致：175°~365° 大弧，字符沿弧线倾斜，顶部朝外）
    stampArcChars() {
      const chars = this.certCompany.split('')
      const diameter = 124
      const radius = diameter / 2
      const arcRadius = 56
      const start = 175
      const end = 365
      const total = end - start
      const n = chars.length || 1
      return chars.map((ch, i) => {
        const frac = (i + 0.5) / n
        const deg = start + frac * total
        const rad = deg * Math.PI / 180
        return { ch, x: radius + arcRadius * Math.cos(rad), y: radius + arcRadius * Math.sin(rad), rotate: deg + 90 }
      })
    },
    // 公章下弧「仅限公司内部使用」（与后台一致：底部居中，字距与上弧相同，顶部朝圆心）
    stampBottomChars() {
      const chars = '仅限公司内部使用'.split('')
      const diameter = 124
      const radius = diameter / 2
      const arcRadius = 56
      const upCount = this.stampChars.length || 1
      const upTotal = 190
      const upCenterDist = (2 * Math.PI * arcRadius * (upTotal / 360)) / upCount
      const bSpan = (upCenterDist * chars.length * 360) / (2 * Math.PI * arcRadius)
      const bStart = 90 + bSpan / 2
      return chars.map((ch, i) => {
        const frac = (i + 0.5) / chars.length
        const deg = bStart - frac * bSpan
        const rad = (deg * Math.PI) / 180
        return { ch, x: radius + arcRadius * Math.cos(rad), y: radius + arcRadius * Math.sin(rad), rotate: deg - 90 }
      })
    },
    certName() {
      const d = this.cert.certificate_data || {}
      return d.user_name || this.cert.user_name || ''
    },
    certIdcard() {
      const d = this.cert.certificate_data || {}
      return d.user_id_card || d.user_idcard || this.cert.user_id_card || ''
    },
    certEmpNo() {
      const d = this.cert.certificate_data || {}
      return d.user_employee_no || this.cert.user_employee_no || ''
    },
    certDept() {
      const d = this.cert.certificate_data || {}
      return d.user_department || this.cert.user_department || ''
    },
    certPos() {
      const d = this.cert.certificate_data || {}
      return d.user_position || this.cert.user_position || ''
    },
    certTraining() {
      const d = this.cert.certificate_data || {}
      return d.training_name || this.cert.training_name || ''
    },
    certType() {
      const d = this.cert.certificate_data || {}
      return d.training_type_name || this.cert.training_type_name || ''
    },
    certContent() {
      const d = this.cert.certificate_data || {}
      return d.training_content || this.cert.training_content || ''
    },
    certModeDuration() {
      const d = this.cert.certificate_data || {}
      const modeText = { online: '线上', offline: '线下', mixed: '混合' }[(d.training_mode || this.cert.training_mode || '')] || ''
      const duration = d.training_duration || this.cert.training_duration || 0
      let s = ''
      if (modeText) s += '培训方式：' + modeText
      if (duration) s += ' 培训时长：' + duration + ' 小时'
      return s || '培训方式'
    },
    certVerify() {
      const d = this.cert.certificate_data || {}
      return d.verify_url || this.cert.verify_url || ''
    }
  },
  onLoad(options) {
    this.certId = Number(options.id || 0)
    this.loadDetail()
  },
  methods: {
    async loadDetail() {
      try {
        const r = await getCertificateDetail(this.certId)
        if (r.code === 0) {
          this.cert = r.data || {}
        } else { uni.showToast({ title: r.msg || '加载失败', icon: 'none' }) }
      } catch (e) { uni.showToast({ title: '加载失败', icon: 'none' }) }
    },
    /** 用 canvas 绘制证书图片（A5 横版 210×148mm，2100×1480 高清；公章透明底双层红边+上下弧+中央，旋转-18° 覆盖日期） */
    drawCert() {
      const ctx = uni.createCanvasContext('certCanvas', this)
      const d = this.cert.certificate_data || {}
      const company = this.certCompany
      const name = this.certName
      const idcard = this.certIdcard
      const empNo = this.certEmpNo
      const dept = this.certDept
      const pos = this.certPos
      const training = this.certTraining
      const type = this.certType
      const content = this.certContent
      const modeDur = this.certModeDuration
      const modeRaw = d.training_mode || this.cert.training_mode || ''
      const modeTextVal = { online: '线上', offline: '线下', mixed: '混合' }[modeRaw] || '—'
      const durVal = d.training_duration || this.cert.training_duration || 0
      const durationVal = durVal ? durVal + ' 小时' : '—'
      const issue = d.issue_date || this.cert.issue_date || ''
      const expire = d.expire_date || '长期有效'
      const code = this.cert.certificate_code || ''
      const verify = this.certVerify

      const W = 2100
      const H = 1480
      // 背景
      ctx.setFillStyle('#ffffff')
      ctx.fillRect(0, 0, W, H)

      // 外框（深蓝 8px）+ 渐变内边框（50px inset，4px 线）
      ctx.setStrokeStyle('#1a3a5c')
      ctx.setLineWidth(8)
      ctx.strokeRect(4, 4, W - 8, H - 8)
      ctx.setStrokeStyle('#d4dce8')
      ctx.setLineWidth(4)
      ctx.strokeRect(50, 50, W - 100, H - 100)

      // 四角金色菱形（对准内边框四角）
      ctx.setFillStyle('#c9a84c')
      ctx.setFontSize(42)
      ctx.setTextAlign('center')
      ctx.setTextBaseline('middle')
      ctx.fillText('◆', 50, 50)
      ctx.fillText('◆', W - 50, 50)
      ctx.fillText('◆', 50, H - 50)
      ctx.fillText('◆', W - 50, H - 50)

      const center = (text, y, size, color) => {
        ctx.setTextAlign('center')
        ctx.setTextBaseline('middle')
        ctx.setFillStyle(color || '#1a3a5c')
        ctx.setFontSize(size)
        ctx.fillText(text, W / 2, y)
      }

      // 顶部：公司名 / 渐变装饰线 / 标题 / 分隔线 / 编号
      center('★ ' + company + ' ★', 100, 48, '#1a3a5c')
      const grad = ctx.createLinearGradient(40, 0, W - 40, 0)
      grad.addColorStop(0, '#1a3a5c')
      grad.addColorStop(0.25, '#4a7a9c')
      grad.addColorStop(0.5, '#c9a84c')
      grad.addColorStop(0.75, '#4a7a9c')
      grad.addColorStop(1, '#1a3a5c')
      ctx.setFillStyle(grad)
      ctx.fillRect(40, 140, W - 80, 5)
      center(this.certTitle || '培训证书', 205, 58, '#1a3a5c')
      ctx.setFillStyle('#c9a84c')
      ctx.fillRect(W / 2 - 105, 245, 210, 3)
      center('证书编号：' + code, 295, 30, '#999999')

      // 正文（左对齐，姓名加粗，与后台 <b> 一致）
      ctx.setTextAlign('left')
      ctx.setTextBaseline('middle')
      const measure = (t, size) => {
        ctx.setFontSize(size)
        try { const m = ctx.measureText(t); return (m && m.width) || t.length * size } catch (e) { return t.length * size }
      }
      const pre = '兹证明 '
      const suf = ' 已完成本企业安全培训并通过考核，特发此证。'
      const xText = 40
      const wPre = measure(pre, 32)
      const wName = measure(name, 34)
      ctx.setFillStyle('#333333')
      ctx.setFontSize(32)
      ctx.fillText(pre, xText, 355)
      ctx.setFontSize(34)
      ctx.fillText(name, xText + wPre, 355)
      ctx.setFontSize(32)
      ctx.fillText(suf, xText + wPre + wName, 355)

      // 表格
      const colW = (W - 80) / 4
      const rowH = 50
      const cell = (x, y, w, h, label, head) => {
        ctx.setStrokeStyle('#d4dce8')
        ctx.setLineWidth(2)
        ctx.strokeRect(x, y, w, h)
        if (head) { ctx.setFillStyle('#f7f9fc'); ctx.fillRect(x + 1, y + 1, w - 2, h - 2) }
        ctx.setTextAlign('center')
        ctx.setTextBaseline('middle')
        ctx.setFillStyle(head ? '#1a3a5c' : '#333333')
        ctx.setFontSize(32)
        ctx.fillText(label, x + w / 2, y + h / 2)
      }
      const rowText = (text, x, y) => {
        ctx.setTextAlign('center')
        ctx.setTextBaseline('middle')
        ctx.setFillStyle('#333333')
        ctx.setFontSize(32)
        ctx.fillText(text, x, y)
      }
      // 员工信息表
      let y = 415
      cell(40, y, colW, rowH, '姓　名', true); cell(40 + colW, y, colW, rowH, '', false)
      cell(40 + colW * 2, y, colW, rowH, '身份证号', true); cell(40 + colW * 3, y, colW, rowH, '', false)
      rowText(name, 40 + colW * 1.5, y + rowH / 2); rowText(idcard, 40 + colW * 3.5, y + rowH / 2)
      y += rowH
      cell(40, y, colW, rowH, '工　号', true); cell(40 + colW, y, colW, rowH, '', false)
      cell(40 + colW * 2, y, colW, rowH, '所属部门', true); cell(40 + colW * 3, y, colW, rowH, '', false)
      rowText(empNo, 40 + colW * 1.5, y + rowH / 2); rowText(dept, 40 + colW * 3.5, y + rowH / 2)
      y += rowH
      cell(40, y, colW, rowH, '岗　位', true); cell(40 + colW, y, colW * 3, rowH, '', false)
      rowText(pos, 40 + colW * 2.5, y + rowH / 2)
      // 培训信息表（培训方式/培训时长同一排，培训内容一行，与后台一致）
      y += rowH + 40
      cell(40, y, colW, rowH, '培训名称', true); cell(40 + colW, y, colW, rowH, '', false)
      cell(40 + colW * 2, y, colW, rowH, '培训类型', true); cell(40 + colW * 3, y, colW, rowH, '', false)
      rowText(training, 40 + colW * 1.5, y + rowH / 2); rowText(type, 40 + colW * 3.5, y + rowH / 2)
      y += rowH
      cell(40, y, colW, rowH, '培训方式', true); cell(40 + colW, y, colW, rowH, '', false)
      cell(40 + colW * 2, y, colW, rowH, '培训时长', true); cell(40 + colW * 3, y, colW, rowH, '', false)
      rowText(modeTextVal, 40 + colW * 1.5, y + rowH / 2); rowText(durationVal, 40 + colW * 3.5, y + rowH / 2)
      y += rowH
      cell(40, y, colW, rowH, '培训内容', true); cell(40 + colW, y, colW * 3, rowH, '', false)
      ctx.setTextAlign('left')
      ctx.setTextBaseline('middle')
      ctx.setFillStyle('#333333')
      ctx.setFontSize(32)
      ctx.fillText(content, 40 + colW + 16, y + rowH / 2)

      // 底部：颁发日期（右对齐，底层）+ 公章（透明底覆盖，圆心对准两行中间，旋转-18°）
      const cx = 1869
      const cy = 1210
      const r = 200
      ctx.setTextAlign('right')
      ctx.setTextBaseline('middle')
      ctx.setFillStyle('#333333')
      ctx.setFontSize(32)
      const dateRight = 2005
      ctx.fillText('颁发日期：' + issue, dateRight, cy - 33)
      ctx.fillText('有效期限：' + expire, dateRight, cy + 33)

      // 公章（透明底，双层红边，上弧公司名 + 中央培训专用章 + 下弧仅限公司内部使用）
      ctx.save()
      ctx.translate(cx, cy)
      ctx.rotate((-18 * Math.PI) / 180)
      ctx.lineWidth = 8
      ctx.strokeStyle = '#c42e2e'
      ctx.beginPath(); ctx.arc(0, 0, r + 10, 0, 2 * Math.PI); ctx.stroke()
      ctx.strokeStyle = '#ffffff'
      ctx.lineWidth = 4
      ctx.beginPath(); ctx.arc(0, 0, r + 4, 0, 2 * Math.PI); ctx.stroke()
      ctx.strokeStyle = '#c42e2e'
      ctx.lineWidth = 8
      ctx.beginPath(); ctx.arc(0, 0, r - 4, 0, 2 * Math.PI); ctx.stroke()

      ctx.setFillStyle('#c42e2e')
      ctx.setTextAlign('center')
      ctx.setTextBaseline('middle')
      ctx.setFontSize(32)
      // 上弧公司名（175°~365°，顶部朝外）
      const chars = company.split('')
      const n = chars.length || 1
      const arcRadius = 178
      for (let i = 0; i < n; i++) {
        const frac = (i + 0.5) / n
        const deg = 175 + frac * 190
        const rad = (deg * Math.PI) / 180
        const px = arcRadius * Math.cos(rad)
        const py = arcRadius * Math.sin(rad)
        ctx.save()
        ctx.translate(px, py)
        ctx.rotate(((deg + 90) * Math.PI) / 180)
        ctx.fillText(chars[i], 0, 0)
        ctx.restore()
      }
      // 中央「培训专用章」
      ctx.setFontSize(42)
      ctx.fillText('培训专用章', 0, 0)
      // 下弧「仅限公司内部使用」（底部居中，字距与上弧一致，顶部朝圆心）
      const bChars = '仅限公司内部使用'.split('')
      const bn = bChars.length
      const upCenterDist = (2 * Math.PI * arcRadius * (190 / 360)) / n
      const bSpan = (upCenterDist * bn * 360) / (2 * Math.PI * arcRadius)
      const bStart = 90 + bSpan / 2
      ctx.setFontSize(32)
      for (let i = 0; i < bn; i++) {
        const frac = (i + 0.5) / bn
        const deg = bStart - frac * bSpan
        const rad = (deg * Math.PI) / 180
        const px = arcRadius * Math.cos(rad)
        const py = arcRadius * Math.sin(rad)
        ctx.save()
        ctx.translate(px, py)
        ctx.rotate(((deg - 90) * Math.PI) / 180)
        ctx.fillText(bChars[i], 0, 0)
        ctx.restore()
      }
      ctx.restore()

      // 页脚：公司名 + 验证
      center(company, 1330, 32, '#1a3a5c')
      ctx.setFillStyle('#999999')
      ctx.setFontSize(29)
      ctx.setTextAlign('center')
      ctx.setTextBaseline('middle')
      ctx.fillText('证书查询验证：' + verify, W / 2, 1370)
      ctx.draw()
    },
    /** 下载证书：请求后端 Chromium 渲染 PNG（与后台完全一致）；H5 长按保存 / 小程序存相册 */
    saveCert() {
      if (this.saving) return
      this.saving = true
      // 保持后端记录
      downloadCertificate(this.certId).catch(() => {})
      const url = this.certDownloadUrl
      if (!url) { uni.showToast({ title: '证书图片生成失败', icon: 'none' }); this.saving = false; return }
      // #ifdef H5
      // 生成静态证书 PNG（长按静态文件更可靠）+ JS-SDK 官方预览
      const code = this.cert.certificate_code || ''
      if (!code) {
        this.certImageUrl = url
        this.saving = false
        uni.showToast({ title: '长按下方图片保存', icon: 'none' })
        return
      }
      get('/api/certificate/image-url', { code }).then((r) => {
        this.saving = false
        const staticUrl = (r.code === 0 && r.data && r.data.url) ? ((BASE_URL || '') + r.data.url + '?t=' + Date.now()) : url
        this.certImageUrl = staticUrl
        this.wechatPreview(staticUrl)
      }).catch(() => {
        this.saving = false
        this.certImageUrl = url
        this.wechatPreview(url)
      })
      return
      // #endif
      // 小程序端：downloadFile 下载后端 PNG 存相册
      uni.downloadFile({
        url,
        success: (res) => {
          if (res.statusCode !== 200) { uni.showToast({ title: '下载失败', icon: 'none' }); this.saving = false; return }
          this.saveToAlbum(res.tempFilePath)
        },
        fail: () => { uni.showToast({ title: '下载失败，请检查网络', icon: 'none' }); this.saving = false }
      })
    },
    saveToAlbum(filePath) {
      uni.saveImageToPhotosAlbum({
        filePath,
        success: () => { uni.showToast({ title: '证书已保存到相册', icon: 'success' }); this.saving = false },
        fail: (err) => {
          // 首次可能弹出授权框，失败多为未授权
          if (err && err.errMsg && err.errMsg.includes('auth')) {
            uni.showModal({
              title: '需要相册权限',
              content: '请允许保存图片到相册',
              confirmText: '去授权',
              success: (r) => { if (r.confirm) uni.openSetting() }
            })
          } else {
            uni.showToast({ title: '保存失败，请重试', icon: 'none' })
          }
          this.saving = false
        }
      })
    },
    saveLongPress() {
      // 微信长按图片由系统弹"保存图片"菜单，此处仅提示
      uni.showToast({ title: '长按图片即可保存', icon: 'none' })
    },
    /** 微信 JS-SDK 图片预览（官方预览长按必弹保存；动态加载官方 JS，不依赖 npm） */
    wechatPreview(url) {
      // #ifdef H5
      const pageUrl = (location.href || '').split('#')[0]
      if (!pageUrl) { uni.showToast({ title: '长按下方图片保存', icon: 'none' }); return }
      const loadSdk = () => new Promise((resolve) => {
        if (window.wx) { resolve(window.wx); return }
        const s = document.createElement('script')
        s.src = 'https://res.wx.qq.com/open/js/jweixin-1.6.0.js'
        s.onload = () => resolve(window.wx)
        s.onerror = () => resolve(null)
        document.head.appendChild(s)
      })
      loadSdk().then((wx) => {
        if (!wx) { uni.showToast({ title: '长按下方图片保存', icon: 'none' }); return }
        get('/api/mobile/wechat/js-sdk-config', { url: pageUrl }).then((r) => {
          if (r.code !== 0 || !r.data) { uni.showToast({ title: '长按下方图片保存', icon: 'none' }); return }
          wx.config({
            debug: false,
            appId: r.data.appId,
            timestamp: r.data.timestamp,
            nonceStr: r.data.nonceStr,
            signature: r.data.signature,
            jsApiList: ['previewImage']
          })
          wx.ready(() => { wx.previewImage({ current: url, urls: [url] }) })
          wx.error(() => { uni.showToast({ title: '长按下方图片保存', icon: 'none' }) })
        }).catch(() => { uni.showToast({ title: '长按下方图片保存', icon: 'none' }) })
      })
      // #endif
    },
    /** H5 兜底：新窗口打开证书图片（微信内显示图片页可长按保存） */
    openCertImage() {
      const url = this.certImageUrl
      if (!url) return
      // #ifdef H5
      window.open(url, '_blank')
      // #endif
    },
    /** 点击证书放大：canvas 导出证书图并预览（H5 全屏大图 / 小程序 previewImage） */
    previewCert() {
      if (!this._drawn) { this.drawCert(); this._drawn = true }
      setTimeout(() => {
        uni.canvasToTempFilePath({
          canvasId: 'certCanvas',
          destWidth: 2100 * 2,
          destHeight: 1480 * 2,
          success: (res) => {
            // #ifdef H5
            this.fullImage = res.tempFilePath
            // #endif
            // #ifndef H5
            uni.previewImage({ urls: [res.tempFilePath], current: 0 })
            // #endif
          },
          fail: () => { uni.showToast({ title: '生成图片失败', icon: 'none' }) }
        }, this)
      }, 150)
    },
    goBack() { uni.navigateBack({ fail: () => uni.switchTab({ url: '/pages/workbench/index' }) }) },
    /** 小程序：跳转全屏 web-view 查看后台证书（与后台完全一致） */
    openCertWeb() {
      const url = this.certViewUrl
      if (!url) { uni.showToast({ title: '证书加载失败', icon: 'none' }); return }
      uni.navigateTo({ url: '/pages/sub/safety/certificate-webview?url=' + encodeURIComponent(url) })
    }
  }
}
</script>

<style scoped>
.certificate-detail-page { min-height: 100vh; background: #f5f6fa; padding-bottom: 140rpx; }
.detail-scroll { padding: 16rpx 24rpx; }
.section { background: #fff; border-radius:16rpx; padding: 24rpx; margin-bottom: 16rpx;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.section-title { font-size: 30rpx; font-weight: 600; margin-bottom: 16rpx; }
.cert-canvas-box { text-align: center; }
/* 证书展示：H5 内嵌 web-view（后台证书页，与后台完全一致，A5 比例高度） */
.cert-web-section { padding: 0; }
.cert-web { width: 100%; height: 510rpx; display: block; }
.cv-loading { text-align: center; padding: 60rpx 0; font-size: 26rpx; color: #909399; }
/* 小程序证书入口卡片 */
.cert-entry-section { padding: 0; }
.cert-entry { padding: 34rpx 24rpx; background: linear-gradient(135deg, #1a3a5c, #2d5470); border-radius:16rpx; text-align: center; }
.cert-entry-title { font-size: 32rpx; font-weight: 700; color: #fff; letter-spacing: 2rpx; }
.cert-entry-code { font-size: 24rpx; color: rgba(255,255,255,.75); margin-top: 12rpx; }
.cert-entry-status { margin-top: 16rpx; }
.cert-entry-tip { font-size: 24rpx; color: #E6A23C; margin-top: 16rpx; }
/* canvas：双端统一离屏 2100×1480（逻辑坐标=画布尺寸，保证导出完整不裁切） */
.cert-canvas { position: fixed; left: -9999px; top: 0; width: 2100px; height: 1480px; }
/* H5 长按保存（页面级，scroll-view 外） */
.cert-save-box { margin-top: 20rpx; text-align: center; padding: 0 24rpx 140rpx; }
.cert-save-label { font-size: 28rpx; font-weight: 700; color: #E6A23C; margin-bottom: 12rpx; }
.cert-save-img { width: 100%; border-radius:12rpx; display: block; }
.cert-save-tip { display: block; font-size: 24rpx; color: #909399; margin-top: 12rpx; }
.cert-open-btn { display: inline-block; margin-top: 20rpx; padding: 14rpx 32rpx; border-radius:36rpx; background: #409EFF; color: #fff; font-size: 26rpx; }
.cert-zoom-tip { text-align: center; font-size: 22rpx; color: #409EFF; margin-top: 10rpx; }
/* 证书放大弹窗 */
.full-mask { position: fixed; inset: 0; background: rgba(0,0,0,0.9); z-index: 200; display: flex; flex-direction: column; align-items: center; justify-content: center; }
.full-img { width: 92%; border-radius:8rpx; }
.full-tip { color: #ccc; font-size: 22rpx; margin-top: 20rpx; }
.info-row { display: flex; margin-bottom: 12rpx; }
.info-label { width: 160rpx; color: #909399; font-size: 28rpx; flex-shrink: 0; }
.info-value { color: #303133; font-size: 28rpx; flex: 1; }
.status-tag { display: inline-block; font-size: 24rpx; padding: 4rpx 16rpx; border-radius:8rpx; }
.status-tag.valid { background: #f0f9eb; color: #67C23A; }
.status-tag.expired { background: #fef0f0; color: #F56C6C; }
.status-tag.soon { background: #fdf6ec; color: #E6A23C; }
.bottom-bar { position: fixed; bottom: 0; left: 0; right: 0; display: flex; gap: 16rpx; padding: 16rpx 24rpx; background: #fff; box-shadow: 0 -2rpx 8rpx rgba(0,0,0,.05); }
.save-btn { flex: 2; padding: 22rpx; border-radius:40rpx; background: #409EFF; color: #fff; font-size: 30rpx; }
.save-btn[disabled] { opacity: .6; }
.back-btn { flex: 1; padding: 22rpx; border-radius:40rpx; background: #f0f0f0; color: #606266; font-size: 30rpx; }
</style>
