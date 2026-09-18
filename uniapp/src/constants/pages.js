// ============================================================================
// 文件路径：src/constants/pages.js
// 页面路径常量统一管理 - 消除硬编码，一处维护
// ============================================================================

/**
 * 所有页面路径常量
 */
export const PAGE_PATHS = {
  // ---- 主包核心页面 ----
  LOGIN: '/pages/login/index',        // 登录页
  SPLASH: '/pages/splash/index',      // 启动页
  DIY_INDEX: '/pages/diy/index',      // DIY 通用入口

  // ---- 旧页面（保留兼容，将被重定向）----
  WORKBENCH: '/pages/workbench/index',
  CONTACTS: '/pages/contacts/index',
  MESSAGES: '/pages/messages/index',
  PROFILE: '/pages/profile/index',

  // ---- 个人中心子页面 ----
  PROFILE_ARCHIVE: '/pages/profile/archive',      // 个人档案
  PROFILE_SETTINGS: '/pages/profile/settings',    // 系统设置
  PROFILE_PASSWORD: '/pages/profile/password',    // 修改密码
  PROFILE_WECHAT: '/pages/profile/wechat',        // 微信绑定
  PROFILE_ABOUT: '/pages/profile/about',          // 关于系统
  PROFILE_HELP: '/pages/profile/help',            // 使用帮助
  PROFILE_FEEDBACK: '/pages/profile/feedback',    // 意见反馈

  // ---- 考核管理（管理者版）----
  ASSESSMENT: '/pages/assessment/index',              // 考核管理首页
  ASSESSMENT_QUICK: '/pages/assessment/quick-deduct', // 快速考核
  ASSESSMENT_TEAM: '/pages/assessment/team-dashboard', // 团队考核看板
  ASSESSMENT_EMPLOYEE: '/pages/assessment/employee-detail', // 员工考核详情
  ASSESSMENT_TODO: '/pages/assessment/todo-list',     // 待办审批
}

/**
 * DIY 页面类型常量
 */
export const DIY_TYPES = {
  HOME: 'home',           // 工作台
  CONTACTS: 'contacts',   // 通讯录
  MESSAGES: 'messages',   // 消息
  PROFILE: 'profile',     // 我的
}

/**
 * DIY 页面完整路径（统一入口 + type 参数）
 */
export const DIY_PATHS = {
  HOME: `${PAGE_PATHS.DIY_INDEX}?type=${DIY_TYPES.HOME}`,
  CONTACTS: `${PAGE_PATHS.DIY_INDEX}?type=${DIY_TYPES.CONTACTS}`,
  MESSAGES: `${PAGE_PATHS.DIY_INDEX}?type=${DIY_TYPES.MESSAGES}`,
  PROFILE: `${PAGE_PATHS.DIY_INDEX}?type=${DIY_TYPES.PROFILE}`,
}

/**
 * Tab 路径对象（底部导航使用）
 */
export const TAB_PATHS = {
  HOME: DIY_PATHS.HOME,
  CONTACTS: DIY_PATHS.CONTACTS,
  MESSAGES: DIY_PATHS.MESSAGES,
  PROFILE: DIY_PATHS.PROFILE,
}
