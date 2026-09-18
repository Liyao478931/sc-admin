<template>
  <view class="diy2-page" :style="{ background: bgColor, paddingTop: statusBarHeight + 'px' }">
    <!-- 工作台（type=home 时直接渲染） -->
    <WorkbenchCenter v-if="currentType === 'home'" :capsuleRight="capsuleRight" />
    <!-- 消息中心（type=messages 时直接渲染，不走 DIY 配置） -->
    <MessagesCenter v-else-if="currentType === 'messages'" :capsuleRight="capsuleRight" />
    <!-- 通讯录（type=contacts 时直接渲染） -->
    <ContactsCenter v-else-if="currentType === 'contacts'" :capsuleRight="capsuleRight" />
    <!-- 个人中心（type=profile 时带头部导航 + DIY 配置渲染） -->
    <template v-else-if="currentType === 'profile'">
      <!-- 顶部导航 -->
      <view class="diy2-nav">
        <view class="diy2-nav-left">
          <text class="diy2-nav-title">我的</text>
        </view>
      </view>
      <!-- 个人信息卡 -->
      <view class="diy2-comp">
        <view class="uc-card">
          <view class="profile-row">
            <view class="avatar" @click="uploadAvatar">
              <image v-if="userInfo.avatar && !avatarErr" :src="imgUrl(userInfo.avatar)" mode="aspectFill" class="avatar-img" @error="avatarErr = true"></image>
              <text v-else class="avatar-text">{{ (userInfo.real_name || '员').substring(0,1) }}</text>
              <view class="avatar-dot" v-if="userInfo.status == 1"></view>
            </view>
            <view class="profile-info">
              <view class="profile-name">
                <text class="profile-name-text">{{ userInfo.real_name || userInfo.username || '未登录' }}</text>
                <text class="profile-tag">{{ userInfo.status == 1 ? '在职' : '离职' }}</text>
              </view>
              <view class="profile-dept">
                <text v-if="userInfo.employee_id">工号 {{ userInfo.employee_id }}</text>
                <text v-if="userInfo.department" class="profile-sep">·</text>
                <text v-if="userInfo.department">{{ userInfo.department }}</text>
                <text v-if="userInfo.join_days" class="profile-sep">·</text>
                <text v-if="userInfo.join_days">{{ workYears }}年</text>
              </view>
            </view>
            <view class="edit-btn" @click="goEditProfile"><MIcon name="edit" :size="13" color="#ffffff" /></view>
          </view>
          <!-- 统计区（4项） -->
          <view class="stats-row">
            <view class="stat-item">
              <text class="stat-num">{{ profileStats.todoCount || 0 }}</text>
              <text class="stat-label">待办</text>
            </view>
            <view class="stat-item">
              <text class="stat-num">{{ profileStats.messageCount || 0 }}</text>
              <text class="stat-label">消息</text>
            </view>
            <view class="stat-item">
              <text class="stat-num">{{ profileStats.attendanceDays || 0 }}<text class="stat-unit">天</text></text>
              <text class="stat-label">出勤</text>
            </view>
            <view class="stat-item">
              <text class="stat-num">{{ profileStats.workHours || 0 }}<text class="stat-unit">h</text></text>
              <text class="stat-label">工时</text>
            </view>
          </view>
        </view>
      </view>
      <!-- 功能中心 -->
      <view class="fn-center">
        <view class="fn-toggle" :class="{ collapsed: !fnCenterOpen }" @click="fnCenterOpen = !fnCenterOpen">
          <view class="fn-toggle-left">
            <view class="fn-toggle-icon"><MIcon name="folder" :size="17" color="#4F46E5" /></view>
            <view class="fn-toggle-info">
              <text class="fn-toggle-title">功能中心</text>
            </view>
          </view>
          <view class="fn-toggle-right">
            <text class="fn-toggle-arrow" :class="{ open: fnCenterOpen }">▾</text>
          </view>
        </view>
        <view class="fn-sub" :class="{ open: fnCenterOpen }">
          <view class="fn-grid-menu">
            <view class="fn-grid-item" v-for="(it, i) in fnItems" :key="i" @click="fnItemClick(it)">
              <view class="fn-grid-icon" :style="{ background: fnIconColor(i) }">
                <image v-if="resolveIcon(it.icon).type === 'img'" :src="resolveIcon(it.icon).val" mode="aspectFit" style="width:22px;height:22px"></image>
                <MIcon v-else-if="resolveIcon(it.icon).type === 'mi'" :name="resolveIcon(it.icon).val" color="#fff" :size="22" :weight="2"></MIcon>
                <u-icon v-else-if="resolveIcon(it.icon).type === 'ui'" :name="resolveIcon(it.icon).val" color="#fff" size="22"></u-icon>
                <text v-else-if="resolveIcon(it.icon).val" style="font-size:24px;color:#fff">{{ resolveIcon(it.icon).val }}</text>
              </view>
              <text class="fn-grid-label">{{ it.name }}</text>
            </view>
          </view>
        </view>
      </view>
      <!-- 更多设置 -->
      <view class="settings-entry">
        <view class="settings-entry-btn" @click="navigate('/pages/profile/settings')">
          <u-icon name="setting" color="#8a9aa8" size="18"></u-icon>
          <text>更多设置</text>
        </view>
      </view>
      <!-- 其他 DIY 组件（从后端配置动态渲染） -->
      <template v-for="(item, key) in otherProfileComps" :key="key">
        <view v-if="item.name === 'banner'" class="diy2-comp" :style="itemStyle(item)">
          <swiper v-if="item.swiperConfig && item.swiperConfig.list" circular :autoplay="item.setUp?.tabVal === 1" :interval="3000" :style="{ height: '160px' }">
            <swiper-item v-for="(img, i) in item.swiperConfig.list" :key="i" @click="navigate(img.link)">
              <view :style="{ margin: '0 ' + (item.imgConfig?.val||0) + 'px', borderRadius: (item.filletImg?.val||0) + 'px', boxShadow: shadowStyle(item.imgShadowConfig) }">
                <image :src="imgUrl(img.img)" mode="aspectFill" style="width:100%;height:160px;border-radius:24px"></image>
              </view>
            </swiper-item>
          </swiper>
          <view v-if="item.swiperConfig.list.length > 1" class="diy2-banner-dots" :style="{ justifyContent: item.docPosition?.tabVal===0?'flex-start':item.docPosition?.tabVal===2?'flex-end':'center' }">
            <view v-for="(img, i) in item.swiperConfig.list" :key="i" class="diy2-banner-dot" :style="{ background: i===0 ? (item.dotColor?.color?.[0]?.item||'#E93323') : (item.dotBgColor?.color?.[0]?.item||'#DDDDDD') }"></view>
          </view>
        </view>
        <view v-else-if="item.name === 'home_menu'" class="diy2-comp" :style="itemStyle(item)">
          <view class="diy2-menu" :style="{ gridTemplateColumns: 'repeat(' + (item.menuConfig?.columns||4) + ',1fr)', borderRadius: (item.filletImg?.val||0)+'px' }">
            <view class="diy2-menu-item" v-for="(m, i) in (item.menuConfig?.list||[]).slice(0,8)" :key="i" @click="navigate(m.link)">
              <view :style="{ boxShadow: shadowStyle(item.imgShadowConfig) }">
                <image v-if="m.img" :src="imgUrl(m.img)" mode="aspectFit" style="width:322px;height:36px"></image>
                <MIcon v-else class="diy2-menu-icon" name="device" :size="20" color="#ffffff" />
              </view>
              <text class="diy2-menu-text" :style="{ color: item.textColor?.color?.[0]?.item || '#333' }">{{ m.title }}</text>
            </view>
          </view>
        </view>
        <view v-else-if="item.name === 'home_title'" class="diy2-comp" :style="itemStyle(item)">
          <view class="diy2-title-row" :style="{ justifyContent: item.titleAlign?.tabVal===0?'flex-start':item.titleAlign?.tabVal===2?'flex-end':'center' }">
            <text class="diy2-title" :style="{ fontSize: (item.titleSize?.val||18)+'px', color: item.titleColor?.color?.[0]?.item || '#282828' }">{{ item.titleConfig?.val || '标题' }}</text>
            <text v-if="item.buttonConfig?.tabVal === 0" class="diy2-title-btn" :style="{ color: item.buttonColor?.color?.[0]?.item || '#4F46E5' }" @click="navigate(item.linkConfig?.val)">{{ item.buttonText?.val || '更多' }}</text>
          </view>
        </view>
        <view v-else-if="item.name === 'richText'" class="diy2-comp" :style="itemStyle(item)">
          <view :style="{ paddingLeft: (item.lrConfig?.val||0)+'px', paddingRight: (item.lrConfig?.val||0)+'px', paddingTop: (item.udConfig?.val||0)+'px', paddingBottom: (item.udConfig?.val||0)+'px' }">
            <rich-text :nodes="item.contentConfig?.val || ''"></rich-text>
          </view>
        </view>
        <view v-else-if="item.name === 'picture_cube'" class="diy2-comp" :style="itemStyle(item)">
          <view class="diy2-cube" :style="{ gap: (item.imgConfig?.val||6)+'px' }">
            <image v-for="(img, i) in (item.cubeConfig?.list||[]).slice(0,4)" :key="i" :src="imgUrl(img.img)" mode="aspectFill" class="diy2-cube-img" :style="{ borderRadius: (item.filletImg?.val||8)+'px', boxShadow: shadowStyle(item.imgShadowConfig) }" @click="navigate(img.link)"></image>
          </view>
        </view>
        <view v-else-if="item.name === 'search_box'" class="diy2-comp" :style="itemStyle(item)">
          <view class="diy2-search" :style="{ justifyContent: 'center' }">
            <image v-if="item.logoConfig?.url" :src="imgUrl(item.logoConfig.url)" mode="aspectFit" class="diy2-search-logo"></image>
            <u-input disabled :placeholder="item.searchTipConfig?.place || '请输入搜索内容'" border="none" :customStyle="{ height: '72rpx', fontSize: '26rpx' }" />
            <text v-if="item.titleSearch?.tabVal === 1" class="diy2-search-btn">{{ item.btnTextConfig?.val || '搜索' }}</text>
          </view>
        </view>
        <view v-else-if="item.name === 'news_roll'" class="diy2-comp" :style="itemStyle(item)">
          <view class="diy2-news">
            <text v-if="item.titleStyle?.tabVal === 0" class="diy2-news-title">{{ item.titleConfig?.val || '公告' }}</text>
            <text class="diy2-news-text"><MIcon name="megaphone" :size="14" color="#f59e0b" /><text style="margin-left:4px">{{ (item.newsConfig?.list||[{val:'公告'}])[0].val }}</text></text>
          </view>
        </view>
        <view v-else-if="item.name === 'z_auxiliary_line'" :style="itemStyle(item)">
          <view :style="{ borderTop: (item.lineHeight?.val||1)+'px '+(item.lineStyle?.tabVal===1?'dashed':item.lineStyle?.tabVal===2?'dotted':'solid')+' '+(item.lineColor?.color?.[0]?.item||'#E8ECF1'), margin: '0 '+(item.lrEdge?.val||12)+'px' }"></view>
        </view>
        <view v-else-if="item.name === 'z_auxiliary_box'" :style="{ height: (item.heightConfig?.val||20)+'px', background: item.bgColor?.color?.[0]?.item || '#fff', margin: '0 '+(item.lrEdge?.val||0)+'px' }"></view>
        <view v-else-if="item.name === 'video'" class="diy2-comp" :style="itemStyle(item)">
          <video :src="item.videoConfig?.url" :poster="item.videoConfig?.poster" :controls="item.videoConfig?.tabVal === 1" class="diy2-video-el"></video>
        </view>
        <view v-else-if="item.name === 'hotspot'" class="diy2-comp" :style="itemStyle(item)">
          <view class="diy2-hotspot">
            <image :src="imgUrl(item.hotspotConfig?.img)" mode="widthFix" class="diy2-hotspot-img"></image>
            <view v-for="(h, i) in (item.hotspotConfig?.list||[])" :key="i" class="diy2-hotspot-area" :style="{ left: h.left, top: h.top, width: h.width, height: h.height }" @click="navigate(h.link)"></view>
          </view>
        </view>
        <view v-else-if="item.name === 'customerService'" class="diy2-comp" :style="itemStyle(item)">
          <view class="diy2-customer-service" :style="{ background: item.bgColor?.color?.[0]?.item || '#fff' }">
            <text class="diy2-cs-text">{{ item.textConfig?.val || '联系客服' }}</text>
          </view>
        </view>
        <view v-else-if="item.name === 'wechat_attention'" class="diy2-comp" :style="itemStyle(item)">
          <view class="diy2-wechat">
            <view class="diy2-wechat-left">
              <image v-if="item.imgConfig?.url" :src="imgUrl(item.imgConfig.url)" mode="aspectFill" class="diy2-wechat-avatar"></image>
              <view v-else class="diy2-wechat-avatar diy2-wechat-avatar-empty"><MIcon name="chat" :size="18" color="#b0c0cc" /></view>
              <text class="diy2-wechat-name">{{ item.nameConfig?.val || '关注公众号' }}</text>
            </view>
            <text class="diy2-wechat-btn" :style="{ color: item.btnColor?.color?.[0]?.item || '#4F46E5' }">{{ item.btnTextConfig?.val || '关注' }}</text>
          </view>
        </view>
        <view v-else-if="item.name === 'tabNav'" class="diy2-comp" :style="itemStyle(item)">
          <scroll-view scroll-x class="diy2-tabnav" :show-scrollbar="false">
            <view class="diy2-tabnav-inner">
              <view v-for="(t, i) in (item.tabList||[])" :key="i" class="diy2-tabnav-item" :class="{ active: activeTab === i }" @click="switchTab(i)">{{ t.title || t.name }}</view>
            </view>
          </scroll-view>
        </view>
        <view v-else-if="item.name === 'pageFoot'"></view>
        <BizDataList v-else-if="item.name === 'device-list'" :item="item" api-url="/api/device/asset/list" />
        <BizDataList v-else-if="item.name === 'repair-list'" :item="item" api-url="/api/device/repair/order/list" />
        <view v-else-if="item.name === 'hazard-list'" class="diy2-comp" :style="itemStyle(item)">
          <BizDataList :item="item" api-url="/api/safety/hazard/list" />
        </view>
        <view v-else-if="item.name === 'inventory-alert'" class="diy2-comp" :style="itemStyle(item)">
          <BizDataList :item="item" api-url="/api/warehouse/inventory/alert/list" />
        </view>
        <view v-else class="diy2-fallback"><MIcon name="puzzle" :size="16" color="#b0c0cc" /><text style="margin-left:4px">{{ item.cname || item.name }}</text></view>
      </template>
    </template>
    <CustomTabBar :currentPath="PAGE_PATHS.DIY_INDEX" :currentType="currentType" />
  </view>
</template>

<script setup>
import { ref, computed } from 'vue'
import { onLoad, onReady } from '@dcloudio/uni-app'
import CustomTabBar from '@/components/CustomTabBar.vue'
import WorkbenchCenter from '@/components/WorkbenchCenter.vue'
import MessagesCenter from '@/components/MessagesCenter.vue'
import ContactsCenter from '@/components/ContactsCenter.vue'
import BizDataList from '@/components/diy-biz/BizDataList.vue'
import { getDiyPage } from '@/api/diy.js'
import { PAGE_PATHS } from '@/constants/pages'
import { resolveIcon } from '@/utils/icon'
import { request } from '@/utils/request'

const loading = ref(true)
// 小程序自定义导航：顶部安全占位（状态栏高度，内容区与胶囊按钮同一水平线）
const statusBarHeight = ref(0)
// 胶囊右侧安全区域（避免功能按钮被胶囊遮挡）
const capsuleRight = ref(0)
// #ifdef MP-WEIXIN
try {
  const info = uni.getSystemInfoSync()
  const sb = info.statusBarHeight || 0
  statusBarHeight.value = sb
  if (typeof uni.getMenuButtonBoundingClientRect === 'function') {
    const m = uni.getMenuButtonBoundingClientRect()
    if (m && m.top) {
      statusBarHeight.value = m.top
      // 胶囊右侧安全区域：屏幕宽度 - 胶囊左侧位置 + 10px 间距（确保内容不被胶囊遮挡）
      capsuleRight.value = (info.screenWidth - m.left) + 10
    }
  }
} catch (e) { statusBarHeight.value = 44 }
// #endif
const pageData = ref({})
const compObj = ref({})
const currentType = ref('home')
// 页面状态：none 正常 / not_found / no_permission / need_login
const errorType = ref('none')
// 当前用户信息（个人信息卡片展示）
const userInfo = ref({})
const avatarErr = ref(false)
// 个人统计（出勤率/待办/消息/出勤天数/工时）
const profileStats = ref({ attendanceRate: 0, todoCount: 0, messageCount: 0, attendanceDays: 0, workHours: 0 })
// 功能中心展开状态
const fnCenterOpen = ref(false)
/** 功能中心子菜单项（从后端动态获取） */
const fnItems = ref([])
const fnItemsLoading = ref(false)

/** 获取功能中心菜单列表 */
async function loadFnItems() {
  if (fnItemsLoading.value) return
  fnItemsLoading.value = true
  try {
    const r = await request({ url: '/api/app/functions', method: 'GET', data: { location: 'profile' } })
    if (r.code === 0 && r.data && Array.isArray(r.data.list)) {
      fnItems.value = r.data.list.filter(q => q.path !== null).map(q => ({
        name: q.name || '',
        icon: q.icon || '',
        link: q.path ? (q.path.url || q.path.path || '') : ''
      }))
    } else {
      fnItems.value = []
    }
  } catch (e) {
    fnItems.value = []
  }
  fnItemsLoading.value = false
}
try {
  userInfo.value = uni.getStorageSync('userInfo') || {}
} catch (e) {}
// 登录态下拉取真实用户信息
if (uni.getStorageSync('access_token') || uni.getStorageSync('token')) {
  getProfileInfo()
} else {
  // 未登录：清除残留 userInfo，显示"未登录"
  userInfo.value = {}
}
async function getProfileInfo() {
  try {
    const r = await request({ url: '/api/user/profile', method: 'GET' })
    if (r.code === 0 && r.data && r.data.name) {
      const d = r.data
      userInfo.value = {
        username: d.name || d.username || '',
        real_name: d.name || '',
        avatar: d.avatar || '',
        department: d.department || '',
        position: d.position || '',
        employee_id: d.employee_id || '',
        status: d.status !== undefined ? d.status : 1,
        join_days: d.join_days || 0
      }
      avatarErr.value = false
      uni.setStorageSync('userInfo', userInfo.value)
      // 加载个人统计
      loadProfileStats()
    } else {
      // 接口返回未登录/失败：不设置用户信息
      userInfo.value = {}
      uni.removeStorageSync('userInfo')
    }
  } catch (e) {
    userInfo.value = {}
  }
}

/** 加载个人统计（出勤率/待办/消息/出勤天数/工时） */
async function loadProfileStats() {
  try {
    const [attRes, todoRes, msgRes] = await Promise.all([
      request({ url: '/api/attendance/stats', method: 'GET' }).catch(() => null),
      request({ url: '/api/todos/count', method: 'GET' }).catch(() => null),
      request({ url: '/api/notification/unread-count', method: 'GET' }).catch(() => null)
    ])
    profileStats.value = {
      attendanceRate: attRes?.data?.attendanceRate || 0,
      attendanceDays: attRes?.data?.attend_days || 0,
      workHours: attRes?.data?.work_hours || 0,
      todoCount: todoRes?.data?.count || 0,
      messageCount: msgRes?.data?.count || 0
    }
  } catch (e) {}
}

/** 功能中心图标颜色 */
const FN_ICON_COLORS = ['#4F46E5', '#fb8a6e', '#34c796', '#8a7aa8', '#fbaa50', '#50c8ff', '#e07a5f', '#3d5a73']
function fnIconColor(i) { return FN_ICON_COLORS[i % FN_ICON_COLORS.length] }

/** 点击功能中心子菜单项 */
function fnItemClick(item) {
  if (item.link) {
    uni.navigateTo({ url: item.link })
  } else {
    uni.showToast({ title: '「' + (item.name || '功能') + '」暂未配置路径', icon: 'none' })
  }
}

/** 工龄（年） */
const workYears = computed(() => Math.floor((userInfo.value.join_days || 0) / 365))
/** 编辑个人档案 */
function goEditProfile() { uni.navigateTo({ url: '/pages/profile/edit' }) }

/** 点击头像上传 */
function uploadAvatar() {
  // #ifndef MP-WEIXIN
  uni.chooseImage({ count: 1, success: (res) => {
    if (!res.tempFilePaths?.length) return
    uni.uploadFile({
      url: uni.$base + '/api/user/avatar',
      filePath: res.tempFilePaths[0],
      name: 'file',
      header: { 'Authorization': 'Bearer ' + (uni.getStorageSync('access_token') || uni.getStorageSync('token') || '') },
      success: (r) => {
        try {
          const rd = JSON.parse(r.data || '{}')
          if (rd.code === 0 && rd.data?.url) {
            userInfo.value.avatar = rd.data.url
            uni.setStorageSync('userInfo', userInfo.value)
            uni.showToast({ title: '头像更新成功', icon: 'success' })
          } else {
            uni.showToast({ title: rd.msg || '头像上传失败', icon: 'none' })
          }
        } catch (e) { uni.showToast({ title: '头像上传失败', icon: 'none' }) }
      },
      fail: () => uni.showToast({ title: '头像上传失败', icon: 'none' })
    })
  } })
  // #endif
  // #ifdef MP-WEIXIN
  uni.showToast({ title: '请在H5端修改头像', icon: 'none' })
  // #endif
}

const bgColor = computed(() => pageData.value.page?.bgColor || '#f5f5f5')
// CRMEB 结构：以 key 为序的对象
const compList = computed(() => {
  const obj = compObj.value || {}
  return Object.keys(obj).map(k => ({ ...obj[k], __key: k }))
})

/** profile 页面：核心组件始终渲染（不依赖后端 DIY 配置），其余按后端数据动态渲染 */
const otherProfileComps = computed(() => compList.value.filter(item => !['profile_menu', 'fn_center', 'profile_footer'].includes(item.name)))

onLoad((options) => {
  const t = options?.type || 'home'
  currentType.value = t
  loadPage(t)
  // 加载功能中心菜单（仅 profile 页面）
  if (t === 'profile') loadFnItems()
  // #ifdef H5
  // 监听编辑器 iframe 预览数据变化（localStorage 同域共享）
  window.addEventListener('storage', (e) => {
    if (e.key === 'diy_preview_data') {
      loadPage(t, true)
    }
  })
  // #endif
})

// ===== E方案：访问埋点上报（onReady 异步上报，静默失败不阻塞渲染） =====
let statReported = false
onReady(() => {
  if (statReported) return
  statReported = true
  try {
    const diyId = (pageData.value && pageData.value.diy_id) || 0
    if (!diyId && !currentType.value) return
    let deviceId = uni.getStorageSync('diy_device_id')
    if (!deviceId) { deviceId = 'd_' + Date.now() + '_' + Math.random().toString(36).slice(2, 10); uni.setStorageSync('diy_device_id', deviceId) }
    let sessionId = uni.getStorageSync('diy_session_id')
    if (!sessionId) { sessionId = 's_' + Date.now() + '_' + Math.random().toString(36).slice(2, 10); uni.setStorageSync('diy_session_id', sessionId) }
    let source = 'link'
    let referer = ''
    // #ifdef H5
    const hash = window.location.hash || ''
    const sm = hash.match(/[?&]source=([^&]+)/)
    if (sm) source = decodeURIComponent(sm[1])
    referer = document.referrer || ''
    // #endif
    let platform = 'h5'
    // #ifdef MP-WEIXIN
    platform = 'miniprogram'
    // #endif
    // #ifdef APP-PLUS
    platform = 'app'
    // #endif
    uni.request({
      url: (import.meta.env.DEV ? '' : uni.$base) + '/api/mobile/diy/stats/report',
      method: 'POST',
      data: {
        diy_id: diyId,
        page_name: currentType.value,
        device_id: deviceId,
        session_id: sessionId,
        source: source,
        referer: referer,
        platform: platform
      },
      header: { 'Content-Type': 'application/x-www-form-urlencoded' },
      success: () => {},
      fail: () => {}
    })
  } catch (e) {}
})

async function loadPage(type, fromStorage = false) {
  // 直接渲染组件页（工作台/通讯录/消息），不依赖 DIY 配置，避免未登录触发跳转
  if (['home', 'contacts', 'messages'].includes(type)) {
    loading.value = false
    errorType.value = 'none'
    return
  }
  console.log('[DIY] 开始加载页面:', type)
  try {
    // #ifdef H5
    const previewData = uni.getStorageSync('diy_preview_data')
    if (previewData) {
      const pd = typeof previewData === 'string' ? JSON.parse(previewData) : previewData
      if (pd && pd.items) {
        console.log('[DIY] 从 localStorage 加载成功')
        errorType.value = 'none'
        pageData.value = pd
        const items = pd.items || []
        const obj = {}
        items.forEach(item => {
          obj['c' + (item.timestamp || Date.now())] = item
        })
        compObj.value = obj
        loading.value = false
        return
      }
    }
    // #endif
    console.log('[DIY] 调用 API:', '/api/diy2/pages/' + type)
    const res = await getDiyPage(type)
    console.log('[DIY] API 响应:', res)
    if (res.code === 0 && res.data) {
      if (res.data.has_access === false) {
        loading.value = false
        if (res.data.need_login) {
          errorType.value = 'need_login'
          uni.showToast({ title: '请先登录', icon: 'none' })
          setTimeout(() => {
            const redirect = encodeURIComponent('/pages/diy/index?type=' + encodeURIComponent(type))
            uni.navigateTo({
              url: '/pages/login/index?redirect=' + redirect,
              fail: () => {
                // #ifdef H5
                window.location.hash = '#/pages/login/index?redirect=' + redirect
                // #endif
              }
            })
          }, 1500)
        } else {
          errorType.value = 'no_permission'
        }
        return
      }
      errorType.value = 'none'
      pageData.value = res.data
      const items = pageData.value.items || []
      const obj = {}
      items.forEach(item => {
        obj['c' + (item.timestamp || Date.now())] = item
      })
      compObj.value = obj
    } else {
      console.error('[DIY] API 返回错误:', res)
      errorType.value = 'not_found'
    }
  } catch (e) {
    console.error('[DIY] 加载失败:', e)
    errorType.value = 'not_found'
  }
  loading.value = false
  console.log('[DIY] loading 设为 false，最终 errorType:', errorType.value)
}

/** 无权限页返回首页 */
function goHome() {
  uni.reLaunch({ url: '/pages/diy/index?type=home' })
}

function itemStyle(item) {
  const s = {}
  const mb = item.mbConfig?.val || 0
  const offset = item.offsetYConfig?.val || 0
  if (offset) s.marginTop = -offset + 'px'
  else if (mb) s.marginTop = mb + 'px'
  if (item.topConfig?.val) s.paddingTop = item.topConfig.val + 'px'
  if (item.bottomConfig?.val) s.paddingBottom = item.bottomConfig.val + 'px'
  if (item.prConfig?.val) { s.paddingLeft = item.prConfig.val + 'px'; s.paddingRight = item.prConfig.val + 'px' }
  if (item.fillet?.val) s.borderRadius = item.fillet.val + 'px'
  if (item.shadowConfig && item.shadowConfig.visible) {
    const sh = item.shadowConfig
    s.boxShadow = `${sh.x||0}px ${sh.y||0}px ${sh.blur||0}px ${sh.spread||0}px ${sh.color||'#888'}`
  }
  if (item.bgColor?.color?.[0]?.item && item.name !== 'z_auxiliary_box') s.background = item.bgColor.color[0].item
  return s
}

function shadowStyle(config) {
  if (!config) return 'none'
  if (config.visible == 0 || (config.x == 0 && config.y == 0 && config.blur == 0 && config.spread == 0)) return 'none'
  return `${config.x||0}px ${config.y||0}px ${config.blur||0}px ${config.spread||0}px ${config.color||'#888'}`
}

function imgUrl(val) {
  if (!val) return ''
  if (val.startsWith('http://') || val.startsWith('https://') || val.startsWith('data:')) return val
  if (val.startsWith('//')) return 'https:' + val
  if (val.startsWith('/')) return uni.$base + val
  return val
}

function navigate(url) {
  if (!url) return
  if (url.startsWith('/pages')) {
    // #ifdef H5
    uni.navigateTo({
      url,
      fail: (err) => {
        if (window.location.hash !== '#/' + url.slice(1)) {
          window.location.hash = '#/' + url.slice(1)
        }
      }
    })
    // #endif
    // #ifndef H5
    uni.navigateTo({ url, fail: (err) => console.error('navigateTo失败', url, err) })
    // #endif
  } else if (url.startsWith('http')) {
    // #ifdef H5
    window.open ? window.open(url) : (location.href = url)
    // #endif
  }
}
</script>

<style scoped>
.diy2-page { min-height: 100vh; padding-bottom: 60px; display: flex; flex-direction: column; }
.diy2-nav { padding: 10px 16px 8px; background: #fff; }
.diy2-nav-left { display: flex; align-items: center; gap: 10px; }
.diy2-nav-title { font-size: 18px; font-weight: 700; color: #1a2332; }
.loading { display: flex; justify-content: center; align-items: center; min-height: 60vh; color: #999; }
.diy2-comp { margin: 0; }
.diy2-banner-dots { display: flex; align-items: center; gap: 4px; padding: 6px 10px; }
.diy2-banner-dot { width: 12px; height: 4px; border-radius:2px; }
.diy2-menu { display: grid; gap: 8px; padding: 16px 12px; background: #fff; border-radius:122px; margin: 0 12px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.diy2-menu-item { display: flex; flex-direction: column; align-items: center; gap: 4px; }
.diy2-menu-icon { font-size: 26px; }
.diy2-menu-text { font-size: 12px; color: #333; }
.diy2-title { display: block; padding: 12px 16px; line-height: 1.4; }
.diy2-title-row { display: flex; align-items: center; padding: 0 12px; }
.diy2-title-btn { font-size: 13px; margin-left: 12px; flex-shrink: 0; }
.diy2-cube { display: grid; grid-template-columns: 1fr 1fr; gap: 6px; padding: 0 12px; }
.diy2-cube-img { width: 100%; height: 90px; border-radius:24px; }
.diy2-search { display: flex; align-items: center; gap: 8px; padding: 8px 12px; }
.diy2-search input { flex: 1; height: 36px; border: 1px solid #ddd; border-radius:24px; padding: 0 12px; font-size: 14px; background: #F4F6FB; }
.diy2-search-logo { width: 24px; height: 24px; }
.diy2-search-btn { padding: 6px 14px; background: #4F46E5; color: #fff; font-size: 13px; border-radius:24px; }
.diy2-news { display: flex; align-items: center; gap: 6px; padding: 10px 14px; background: #FFF8E1; color: #F59E0B; font-size: 13px; border-radius:24px; margin: 0 12px; }
.diy2-news-title { flex-shrink: 0; color: #F59E0B; font-weight: 600; }
.diy2-news-text { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.diy2-video-el { width: 100%; height: 200px; border-radius:24px; background: #000; }
.diy2-hotspot { position: relative; margin: 0 12px; }
.diy2-hotspot-img { width: 100%; display: block; border-radius:24px; }
.diy2-hotspot-area { position: absolute; border: 1px solid rgba(255,255,255,0.4); background: rgba(64,158,255,0.06); box-sizing: border-box; }
.diy2-service { display: flex; padding: 0 12px; }
.diy2-service-btn { display: inline-flex; align-items: center; gap: 6px; padding: 10px 18px; border-radius:224px; box-shadow: 0 4px 12px rgba(0,0,0,0.15); }
.diy2-service-icon { width: 22px; height: 22px; }
.diy2-service-text { font-size: 20px; line-height: 22px; }
.diy2-service-label { font-size: 13px; line-height: 1; }
.diy2-wechat { display: flex; align-items: center; justify-content: space-between; margin: 0 12px; padding: 10px 12px; background: #fff; border-radius:24px;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
.diy2-wechat-left { display: flex; align-items: center; gap: 10px; }
.diy2-wechat-avatar { width: 36px; height: 36px; border-radius:50%; overflow: hidden; }
.diy2-wechat-avatar-empty { display: flex; align-items: center; justify-content: center; background: #F4F6FB; font-size: 18px; }
.diy2-wechat-name { font-size: 14px; color: #333; }
.diy2-wechat-btn { font-size: 13px; padding: 5px 16px; border: 1px solid currentColor; border-radius:24px; }
.diy2-tabnav { width: 100%; white-space: nowrap; }
.diy2-tabnav-inner { display: inline-flex; }
.diy2-tabnav-item { display: inline-flex; align-items: center; padding: 12px 18px; font-size: 14px; color: #666; border-bottom: 2px solid transparent; }
.diy2-tabnav-item.active { font-weight: 600; }
.diy2-fallback { margin: 8px 12px; padding: 16px; background: #fff; border: 1px dashed #ddd; border-radius:24px; text-align: center; color: #909399;   box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06);
}
/* 个人信息卡 */
.uc-card { margin: 16px; padding: 20px; border-radius:24rpx; background: #fff; box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06); }
.profile-row { display: flex; align-items: center; gap: 14px; }
.avatar { width: 64px; height: 64px; border-radius:50%; background: linear-gradient(135deg, #4F46E5, #7C6FF0); display: flex; align-items: center; justify-content: center; font-size: 26px; font-weight: 600; color: #fff; flex-shrink: 0; position: relative; overflow: visible; }
.avatar-img { width: 100%; height: 100%; border-radius:50%; }
.avatar-text { color: #fff; font-weight: 600; font-size: 26px; }
.avatar-dot { position: absolute; bottom: 2px; right: 2px; width: 14px; height: 14px; border-radius:50%; background: #34c759; border: 2px solid #fff; }
.profile-info { flex: 1; min-width: 0; }
.profile-name { display: flex; align-items: center; gap: 8px; }
.profile-name-text { font-size: 19px; font-weight: 600; color: #1a2332; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.profile-tag { font-size: 10px; color: #4F46E5; background: #EEF0FE; padding: 0 12px; border-radius:30px; line-height: 22px; flex-shrink: 0; }
.profile-dept { font-size: 13px; color: #8a9aa8; margin-top: 4px; display: flex; align-items: center; flex-wrap: wrap; }
.profile-sep { margin: 0 4px; color: #d5dce4; }
.edit-btn { flex-shrink: 0; width: 38px; height: 38px; border-radius:50%; background: #EDF0F8; display: flex; align-items: center; justify-content: center; }
.edit-btn-icon { font-size: 16px; color: #3d5a73; }
.stats-row { display: grid; grid-template-columns: repeat(4, 1fr); gap: 4px; margin-top: 16px; padding-top: 16px; border-top: 1px solid #EDF0F8; }
.stat-item { text-align: center; }
.stat-num { font-size: 20px; font-weight: 700; color: #4F46E5; display: block; }
.stat-unit { font-size: 11px; font-weight: 400; color: #b0c0cc; }
.stat-label { font-size: 11px; color: #9aabba; margin-top: 2px; display: block; }
.settings-entry { margin: 12px 16px; display: flex; align-items: center; justify-content: center; gap: 8px; padding: 14px; border: none; border-radius:24rpx; background: #fff; box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06); color: #8a9aa8; font-size: 14px; }
.settings-entry-btn { display: flex; align-items: center; gap: 10px; width: 100%; cursor: pointer; }
.settings-entry-btn:active { transform: scale(0.98); }
/* 功能中心 */
.fn-center { margin: 12px 16px; overflow: hidden; border-radius:24rpx; background: #fff; box-shadow: 0 8rpx 24rpx rgba(79,70,229,0.06); }
.fn-toggle { width: 100%; background: #fff; border: none; padding: 14px 16px; display: flex; align-items: center; justify-content: space-between; cursor: pointer; transition: 0.2s; }
.fn-toggle.collapsed { border-radius:24rpx; }
.fn-toggle:not(.collapsed) { border-radius:24rpx 24rpx 0 0; }
.fn-toggle:active { transform: scale(0.98); }
.fn-toggle-left { display: flex; align-items: center; gap: 14px; }
.fn-toggle-icon { width: 44px; height: 44px; border-radius:124px; background: rgba(79, 70, 229, 0.08); display: flex; align-items: center; justify-content: center; }
.fn-toggle-info .fn-toggle-title { font-size: 16px; font-weight: 600; color: #1a2332; }
.fn-toggle-right { display: flex; align-items: center; gap: 12px; }
.fn-toggle-arrow { color: #b0c0cc; font-size: 18px; transition: transform 0.35s ease; }
.fn-toggle-arrow.open { transform: rotate(180deg); }
.fn-sub { max-height: 0; overflow: hidden; transition: max-height 0.4s ease, opacity 0.3s ease, margin 0.3s ease; opacity: 0; margin-top: 0; }
.fn-sub.open { max-height: 500px; opacity: 1; margin-top: 0; overflow: visible; }
.fn-grid-menu { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; padding: 16px; background: rgba(255,255,255,0.5); backdrop-filter: blur(8px); border: 1px solid #EDF0F8; border-top: none; border-radius:0 0 124px 124px; }
.fn-grid-item { display: flex; flex-direction: column; align-items: center; gap: 6px; padding: 8px 4px; cursor: pointer; transition: 0.2s; }
.fn-grid-item:active { transform: scale(0.92); }
.fn-grid-icon { width: 44px; height: 44px; border-radius:16rpx; display: flex; align-items: center; justify-content: center; flex-shrink: 0; font-size: 20px; box-shadow: 0 6px 16rpx rgba(79,70,229,0.2); }
.fn-grid-label { font-size: 12px; color: #333; text-align: center; line-height: 1.3; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 100%; }
/* 状态页 */
.diy2-status-page { display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 70vh; padding: 0 40px; text-align: center; }
.diy2-status-icon { font-size: 64px; line-height: 1; }
.diy2-status-title { margin-top: 20px; font-size: 18px; color: #333; font-weight: 600; }
.diy2-status-sub { margin-top: 10px; font-size: 14px; color: #999; line-height: 1.6; }
.diy2-status-btn { margin-top: 28px; padding: 10px 36px; background: #4F46E5; color: #fff; font-size: 15px; border-radius:224px; }
</style>