import Vue from 'vue'
import Router from 'vue-router'
import store from '../store'
import { getToken } from '../utils/auth'

Vue.use(Router)

// 全局捕获 vue-router 重复导航错误（NavigationDuplicated），避免控制台未捕获 Promise 告警
// （如已在消息列表页再次点击铃铛"查看全部消息"等场景）
const originalPush = Router.prototype.push
Router.prototype.push = function push (location) {
  return originalPush.call(this, location).catch(err => err)
}

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/auth/Login.vue'),
    meta: { title: '登录', titleKey: 'nav.login', noAuth: true }
  },
  {
    path: '/hr/recruit/apply',
    name: 'RecruitApply',
    component: () => import('../views/hr/recruit/Apply.vue'),
    meta: { title: '加入我们', noAuth: true }
  },
  {
    path: '/diy/list',
    name: 'DiyList',
    component: () => import('../views/diy/CrmebPageList.vue'),
    meta: { title: '页面装修', requireAuth: true }
  },
  {
    path: '/diy/editor/:id?',
    name: 'DiyEditor',
    component: () => import('../views/diy/CrmebPageEditor.vue'),
    meta: { title: '页面装修编辑', requireAuth: true }
  },
  {
    path: '/',
    component: () => import('../layouts/MainLayout.vue'),
    redirect: '/dashboard',
    children: [
      { path: 'dashboard', name: 'Dashboard', component: () => import('../views/dashboard/Index.vue'), meta: { title: '控制台', titleKey: 'nav.dashboard' } },
      { path: 'announcement', name: 'Announcement', component: () => import('../views/system/announcement/index.vue'), meta: { title: '公告管理', permission: 'announcement:view', requireAuth: true } },
      { path: 'profile', name: 'Profile', component: () => import('../views/profile/Index.vue'), meta: { title: '个人中心', titleKey: 'navbar.profile' } },
      { path: 'organization', name: 'Organization', component: () => import('../views/settings/Organization.vue'), meta: { title: '组织架构' } },
      { path: 'profiles', name: 'Profiles', component: () => import('../views/hr/Profiles.vue'), meta: { title: '员工档案' } },
      { path: 'hr/attendance/shift', name: 'AttendanceShift', component: () => import('../views/hr/attendance/shift.vue'), meta: { title: '班次设置', icon: 'el-icon-time', permission: 'hr:attendance:shift:list', requireAuth: true } },
      { path: 'hr/attendance/schedule', name: 'AttendanceSchedule', component: () => import('../views/hr/attendance/schedule.vue'), meta: { title: '排班管理', icon: 'el-icon-date', permission: 'hr:attendance:schedule:list', requireAuth: true } },
      { path: 'hr/attendance/record', name: 'AttendanceRecord', component: () => import('../views/hr/attendance/record.vue'), meta: { title: '打卡记录', icon: 'el-icon-document-copy', permission: 'hr:attendance:record:list', requireAuth: true } },
      { path: 'hr/attendance/approval', name: 'AttendanceApproval', component: () => import('../views/hr/attendance/approval.vue'), meta: { title: '审批记录', icon: 'el-icon-document-checked', permission: 'hr:attendance:approval:list', requireAuth: true } },
      // ---- 考勤-假勤申请 ----
      { path: 'hr/attendance/leave', name: 'HrLeaveList', component: () => import('../views/hr/attendance/leave/List.vue'), meta: { title: '假勤申请', icon: 'el-icon-date', permission: 'hr:attendance:leave:view', requireAuth: true } },
      { path: 'hr/attendance/leave/add', name: 'HrLeaveAdd', component: () => import('../views/hr/attendance/leave/Add.vue'), meta: { title: '新增假勤申请', permission: 'hr:attendance:leave:add', hidden: true, requireAuth: true } },
      { path: 'hr/attendance/leave/edit/:id', name: 'HrLeaveEdit', component: () => import('../views/hr/attendance/leave/Add.vue'), meta: { title: '编辑假勤申请', permission: 'hr:attendance:leave:edit', hidden: true, requireAuth: true } },
      { path: 'hr/attendance/leave/detail/:id', name: 'HrLeaveDetail', component: () => import('../views/hr/attendance/leave/Detail.vue'), meta: { title: '假勤申请详情', permission: 'hr:attendance:leave:view', hidden: true, requireAuth: true } },
      // ---- 考勤-考勤统计 ----
      { path: 'hr/attendance/statistics', name: 'HrAttendanceStatistics', component: () => import('../views/hr/attendance/statistics/Statistics.vue'), meta: { title: '考勤统计', icon: 'el-icon-data-analysis', permission: 'hr:attendance:statistics:view', requireAuth: true } },
      { path: 'hr/attendance/checkin', redirect: '/hr/attendance/checkin/face' },
      { path: 'hr/attendance/checkin/face', name: 'FaceRegister', component: () => import('../views/hr/attendance/checkin/face/index.vue'), meta: { title: '人脸录入', icon: 'el-icon-camera', permission: 'face:view', requireAuth: true } },
      { path: 'hr/attendance/checkin/points', name: 'AttendancePoints', component: () => import('../views/hr/attendance/checkin/points/index.vue'), meta: { title: '打卡点管理', icon: 'el-icon-location', permission: 'attendance:points:view', requireAuth: true } },
      { path: 'hr/attendance/checkin/rule', name: 'AttendanceRule', component: () => import('../views/hr/attendance/checkin/rule/index.vue'), meta: { title: '打卡配置', icon: 'el-icon-time', permission: 'attendance:rule:view', requireAuth: true } },
      // ---- 薪酬-工分汇总 ----
      { path: 'hr/salary/calculate/score', name: 'HrScoreSummary', component: () => import('../views/hr/salary/score/Summary.vue'), meta: { title: '工分汇总', icon: 'el-icon-star-on', permission: 'hr:salary:score:view', requireAuth: true } },
      // ---- 薪酬-工资计算/配置 ----
      { path: 'hr/salary/calculate/payroll', name: 'HrPayrollIndex', component: () => import('../views/hr/salary/calculation/Index.vue'), meta: { title: '工资计算', icon: 'el-icon-money', permission: 'hr:salary:payroll:view', requireAuth: true } },
      { path: 'hr/salary/config', name: 'HrSalaryConfig', component: () => import('../views/hr/salary/config/Index.vue'), meta: { title: '工资配置', icon: 'el-icon-set-up', permission: 'hr:salary:config:view', requireAuth: true } },
      // ---- 薪酬-薪酬标准表 ----
      { path: 'hr/salary/standard', name: 'HrSalaryStandard', component: () => import('../views/hr/salary/standard/Index.vue'), meta: { title: '薪酬标准表', icon: 'el-icon-s-data', permission: 'salary:standard:view', requireAuth: true } },
      // ---- 薪酬-补助标准配置 ----
      { path: 'hr/salary/subsidy', name: 'HrSalarySubsidy', component: () => import('../views/hr/salary/subsidy/Index.vue'), meta: { title: '补助标准配置', icon: 'el-icon-price-tag', permission: 'salary:subsidy:view', requireAuth: true } },
      // ---- 薪酬-工资条 ----
      { path: 'hr/salary/slip/generate', name: 'HrSalarySlipGenerate', component: () => import('../views/hr/salary/slip/Generate.vue'), meta: { title: '生成工资条', icon: 'el-icon-tickets', permission: 'hr:salary:slip:generate:view', requireAuth: true } },
      { path: 'hr/salary/slip/list', name: 'HrSalarySlipList', component: () => import('../views/hr/salary/slip/List.vue'), meta: { title: '工资条查询', icon: 'el-icon-search', permission: 'hr:salary:slip:list:view', requireAuth: true } },
      // ---- 薪酬-薪酬统计 ----
      { path: 'hr/salary/statistics', name: 'HrSalaryStatistics', component: () => import('../views/hr/salary/statistics/Index.vue'), meta: { title: '薪酬统计', icon: 'el-icon-data-analysis', permission: 'hr:salary:statistics:view', requireAuth: true } },
      // ---- 人事-员工异动 ----
      { path: 'hr/transfer/list', name: 'HrTransferList', component: () => import('../views/hr/transfer/List.vue'), meta: { title: '员工异动', icon: 'el-icon-switch-button', permission: 'hr:transfer:view', requireAuth: true } },
      { path: 'hr/transfer/add', name: 'HrTransferAdd', component: () => import('../views/hr/transfer/Add.vue'), meta: { title: '新增员工异动', permission: 'hr:transfer:add', hidden: true, requireAuth: true } },
      { path: 'hr/transfer/edit/:id', name: 'HrTransferEdit', component: () => import('../views/hr/transfer/Add.vue'), meta: { title: '编辑员工异动', permission: 'hr:transfer:edit', hidden: true, requireAuth: true } },
      { path: 'hr/transfer/detail/:id', name: 'HrTransferDetail', component: () => import('../views/hr/transfer/Detail.vue'), meta: { title: '异动详情', permission: 'hr:transfer:view', hidden: true, requireAuth: true } },
      { path: 'hr/assessment/template', name: 'AssessmentTemplate', component: () => import('../views/hr/assessment/template/Index.vue'), meta: { title: '考核模板管理', icon: 'el-icon-document-checked', permission: 'assessment:template:view', requireAuth: true } },
      { path: 'hr/assessment/task', name: 'AssessmentTask', component: () => import('../views/hr/assessment/task/Index.vue'), meta: { title: '考核任务管理', icon: 'el-icon-tickets', permission: 'assessment:task:view', requireAuth: true } },
      { path: 'hr/assessment/dashboard', name: 'AssessmentDashboard', component: () => import('../views/hr/assessment/dashboard/Index.vue'), meta: { title: '考核看板', icon: 'el-icon-data-analysis', permission: 'assessment:dashboard:view', requireAuth: true } },
      { path: 'hr/assessment/appeal', name: 'AssessmentAppeal', component: () => import('../views/hr/assessment/appeal/Index.vue'), meta: { title: '申诉处理中心', icon: 'el-icon-message', permission: 'assessment:appeal:view', requireAuth: true } },
      // ---- 人事-招聘管理 ----
      { path: 'hr/recruit/requirement', name: 'RecruitRequirement', component: () => import('../views/hr/recruit/Requirement.vue'), meta: { title: '招聘需求', icon: 'el-icon-document', permission: 'hr:recruit:view', requireAuth: true } },
      { path: 'hr/recruit/position', name: 'RecruitPosition', component: () => import('../views/hr/recruit/Position.vue'), meta: { title: '职位管理', icon: 'el-icon-office-building', permission: 'hr:recruit:view', requireAuth: true } },
      { path: 'hr/recruit/resume', name: 'RecruitResume', component: () => import('../views/hr/recruit/Resume.vue'), meta: { title: '简历管理', icon: 'el-icon-user', permission: 'hr:recruit:view', requireAuth: true } },
      { path: 'hr/recruit/offer', name: 'RecruitOffer', component: () => import('../views/hr/recruit/Offer.vue'), meta: { title: '录用管理', icon: 'el-icon-s-check', permission: 'hr:recruit:view', requireAuth: true } },
      { path: 'hr/recruit/statistics', name: 'RecruitStatistics', component: () => import('../views/hr/recruit/Statistics.vue'), meta: { title: '招聘统计', icon: 'el-icon-data-analysis', permission: 'hr:recruit:statistics:view', requireAuth: true } },
      // ---- 生产-工单 ----
      { path: 'production/plan/order/list', name: 'ProductionOrderList', component: () => import('../views/production/plan/order/List.vue'), meta: { title: '生产工单', icon: 'el-icon-document', permission: 'production:order:list:view', requireAuth: true } },
      { path: 'production/plan/order/add', name: 'ProductionOrderAdd', component: () => import('../views/production/plan/order/Add.vue'), meta: { title: '新建工单', permission: 'production:order:create', hidden: true, requireAuth: true } },
      { path: 'production/plan/order/edit/:id', name: 'ProductionOrderEdit', component: () => import('../views/production/plan/order/Add.vue'), meta: { title: '编辑工单', permission: 'production:order:edit', hidden: true, requireAuth: true } },
      { path: 'production/plan/order/detail/:id', name: 'ProductionOrderDetail', component: () => import('../views/production/plan/order/Detail.vue'), meta: { title: '工单详情', permission: 'production:order:view', hidden: true, requireAuth: true } },
      // ---- 生产-排程 ----
      { path: 'production/plan/schedule', name: 'ProductionSchedule', component: () => import('../views/production/plan/schedule/Index.vue'), meta: { title: '生产排程', icon: 'el-icon-date', permission: 'production:schedule:view', requireAuth: true } },
      // ---- 生产-质量管理 ----
      { path: 'production/quality/standard', name: 'QualityStandard', component: () => import('../views/production/quality/standard/Index.vue'), meta: { title: '质检标准', icon: 'el-icon-document-checked', permission: 'quality:standard:view', requireAuth: true } },
      { path: 'production/quality/task', name: 'QualityTaskList', component: () => import('../views/production/quality/task/List.vue'), meta: { title: '检验任务', icon: 'el-icon-edit', permission: 'quality:task:view', requireAuth: true } },
      { path: 'production/quality/task/add', name: 'QualityTaskAdd', component: () => import('../views/production/quality/task/Add.vue'), meta: { title: '新增检验', permission: 'quality:task:add', hidden: true, requireAuth: true } },
      { path: 'production/quality/task/detail/:id', name: 'QualityTaskDetail', component: () => import('../views/production/quality/task/Detail.vue'), meta: { title: '检验详情', permission: 'quality:task:view', hidden: true, requireAuth: true } },
      { path: 'production/quality/reject', name: 'QualityReject', component: () => import('../views/production/quality/reject/Index.vue'), meta: { title: '不合格品处理', icon: 'el-icon-warning', permission: 'quality:reject:view', requireAuth: true } },
      { path: 'production/quality/statistics', name: 'QualityStatistics', component: () => import('../views/production/quality/statistics/Index.vue'), meta: { title: '质量统计', icon: 'el-icon-data-analysis', permission: 'quality:statistics:view', requireAuth: true } },
      { path: 'production/quality/trace', name: 'QualityTrace', component: () => import('../views/production/quality/trace/Trace.vue'), meta: { title: '质量追溯', icon: 'el-icon-connection', permission: 'quality:trace:view', requireAuth: true } },
      // ---- 生产-生产看板 ----
      { path: 'production/dashboard', name: 'ProductionDashboard', component: () => import('../views/production/dashboard/Index.vue'), meta: { title: '生产看板', icon: 'el-icon-monitor', permission: 'production:dashboard:view', requireAuth: true } },
      // ---- 生产-报工 ----
      { path: 'production/report/list', name: 'ProductionReportList', component: () => import('../views/production/report/List.vue'), meta: { title: '报工记录', icon: 'el-icon-edit-outline', permission: 'production:report:view', requireAuth: true } },
      { path: 'production/report/add', name: 'ProductionReportAdd', component: () => import('../views/production/report/Add.vue'), meta: { title: '新增报工', permission: 'production:report:add', hidden: true, requireAuth: true } },
      { path: 'production/report/edit/:id', name: 'ProductionReportEdit', component: () => import('../views/production/report/Edit.vue'), meta: { title: '编辑报工', permission: 'production:report:edit', hidden: true, requireAuth: true } },
      { path: 'production/report/detail/:id', name: 'ProductionReportDetail', component: () => import('../views/production/report/Detail.vue'), meta: { title: '报工详情', permission: 'production:report:view', hidden: true, requireAuth: true } },
      { path: 'production/report/audit', name: 'ProductionReportAudit', component: () => import('../views/production/report/Audit.vue'), meta: { title: '报工审核', icon: 'el-icon-document-checked', permission: 'production:report:audit:view', requireAuth: true } },
      // ---- 生产-基础设置 ----
      { path: 'production/setting/process', name: 'ProductionProcess', component: () => import('../views/production/setting/process/Index.vue'), meta: { title: '工序管理', icon: 'el-icon-set-up', permission: 'production:process:view', requireAuth: true } },
      // ---- 生产管理：工艺路线 ----
      { path: 'production/routing', name: 'ProductionRouting', component: () => import('../views/production/routing/List.vue'), meta: { title: '工艺路线', icon: 'el-icon-s-claim', permission: 'production:routing:view', requireAuth: true } },
      { path: 'production/routing/add', name: 'ProductionRoutingAdd', component: () => import('../views/production/routing/Edit.vue'), meta: { title: '新增工艺路线', icon: 'el-icon-plus', permission: 'production:routing:add', hidden: true, requireAuth: true } },
      { path: 'production/routing/edit/:id', name: 'ProductionRoutingEdit', component: () => import('../views/production/routing/Edit.vue'), meta: { title: '编辑工艺路线', icon: 'el-icon-edit', permission: 'production:routing:edit', hidden: true, requireAuth: true } },
      { path: 'production/routing/detail/:id', name: 'ProductionRoutingDetail', component: () => import('../views/production/routing/Detail.vue'), meta: { title: '工艺路线详情', icon: 'el-icon-view', permission: 'production:routing:view', hidden: true, requireAuth: true } },
      // ---- 生产管理：MRP物料需求计划 ----
      { path: 'production/mrp', name: 'ProductionMrp', component: () => import('../views/production/mrp/List.vue'), meta: { title: '物料需求计划', icon: 'el-icon-cpu', permission: 'production:mrp:view', requireAuth: true } },
      { path: 'production/mrp/detail/:id', name: 'ProductionMrpDetail', component: () => import('../views/production/mrp/Detail.vue'), meta: { title: 'MRP批次详情', icon: 'el-icon-view', permission: 'production:mrp:view', hidden: true, requireAuth: true } },
      { path: 'production/setting/workstation', name: 'ProductionWorkstation', component: () => import('../views/production/setting/workstation/Index.vue'), meta: { title: '工位管理', icon: 'el-icon-office-building', permission: 'production:workstation:view', requireAuth: true } },
      // ---- 生产-生产进度 ----
      { path: 'production/execute/progress', name: 'ProductionProgress', component: () => import('../views/production/execute/progress/Index.vue'), meta: { title: '生产进度', icon: 'el-icon-data-line', permission: 'production:progress:view', requireAuth: true } },
      // ---- 生产-工单派工 ----
      { path: 'production/execute/dispatch/list', name: 'ProductionDispatchList', component: () => import('../views/production/execute/dispatch/List.vue'), meta: { title: '工单派工', icon: 'el-icon-paperclip', permission: 'production:dispatch:view', requireAuth: true } },
      { path: 'production/execute/dispatch/add', name: 'ProductionDispatchAdd', component: () => import('../views/production/execute/dispatch/Add.vue'), meta: { title: '新增派工', permission: 'production:dispatch:add', hidden: true, requireAuth: true } },
      { path: 'production/execute/dispatch/edit/:id', name: 'ProductionDispatchEdit', component: () => import('../views/production/execute/dispatch/Edit.vue'), meta: { title: '编辑派工', permission: 'production:dispatch:edit', hidden: true, requireAuth: true } },
      { path: 'production/execute/dispatch/detail/:id', name: 'ProductionDispatchDetail', component: () => import('../views/production/execute/dispatch/Detail.vue'), meta: { title: '派工详情', permission: 'production:dispatch:view', hidden: true, requireAuth: true } },
      { path: 'users', name: 'Users', component: () => import('../views/user/Index.vue'), meta: { title: '用户管理', titleKey: 'nav.user_management' } },
      { path: 'roles', name: 'Roles', component: () => import('../views/role/Index.vue'), meta: { title: '角色管理', titleKey: 'nav.role_management' } },
      { path: 'permissions', name: 'Permissions', component: () => import('../views/permission/Index.vue'), meta: { title: '权限管理', titleKey: 'nav.permission_management' } },
      { path: 'logs', name: 'Logs', component: () => import('../views/log/Index.vue'), meta: { title: '系统日志', titleKey: 'nav.system_logs' } },
      { path: 'services', name: 'Services', component: () => import('../views/service/Index.vue'), meta: { title: '基础服务', titleKey: 'nav.services' } },
      { path: 'settings/services/dingtalk', name: 'ServiceDingtalk', component: () => import('../views/settings/services/dingtalk.vue'), meta: { title: '钉钉服务', icon: 'el-icon-chat-dot-square', permission: 'settings:services:dingtalk', requireAuth: true } },
      { path: 'settings/services/u8', name: 'ServiceU8', component: () => import('../views/settings/services/u8.vue'), meta: { title: 'U8服务', icon: 'el-icon-s-cooperation', permission: 'settings:services:u8', requireAuth: true } },
      { path: 'settings/services/esign', name: 'ServiceEsign', component: () => import('../views/settings/services/esign.vue'), meta: { title: '电子签服务', icon: 'el-icon-document-checked', permission: 'settings:services:esign', requireAuth: true } },
      { path: 'settings/services/face', name: 'ServiceFace', component: () => import('../views/settings/services/face.vue'), meta: { title: '人脸识别服务', icon: 'el-icon-camera', permission: 'settings:services:face', requireAuth: true } },
      { path: 'settings/services/logistics', name: 'ServiceLogistics', component: () => import('../views/settings/services/logistics.vue'), meta: { title: '物流服务', icon: 'el-icon-truck', permission: 'settings:services:logistics:view', requireAuth: true } },
      { path: 'settings/login', name: 'LoginSettings', component: () => import('../views/settings/LoginConfig.vue'), meta: { title: '登录页面配置', titleKey: 'nav.login_settings' } },
      { path: 'settings/theme', name: 'ThemeConfig', component: () => import('../views/settings/ThemeConfig.vue'), meta: { title: '界面配置' } },
      { path: 'settings/params', name: 'SystemParams', component: () => import('../views/settings/SystemParams.vue'), meta: { title: '系统参数' } },
      { path: 'settings/agreement', name: 'AgreementConfig', component: () => import('../views/settings/AgreementConfig.vue'), meta: { title: '协议管理', permission: 'settings:agreement', requireAuth: true } },
      { path: 'settings/company', name: 'CompanySettings', component: () => import('../views/settings/company.vue'), meta: { title: '公司信息', icon: 'el-icon-office-building', permission: 'settings:company', requireAuth: true } },
      { path: 'settings/menus', name: 'MenuManage', component: () => import('../views/settings/MenuManage.vue'), meta: { title: '菜单管理' } },
      { path: 'system/notification/messages', name: 'NotificationMessages', component: () => import('../views/system/notification/messages.vue'), meta: { title: '消息列表', icon: 'el-icon-message', permission: 'notification:list', requireAuth: true } },
      { path: 'system/notification/templates', name: 'NotificationTemplates', component: () => import('../views/system/notification/templates.vue'), meta: { title: '消息模板', icon: 'el-icon-document-copy', permission: 'notification:template:list', requireAuth: true } },
      { path: 'system/notification/settings', name: 'NotificationPreference', component: () => import('../views/system/notification/settings.vue'), meta: { title: '消息设置', icon: 'el-icon-setting', permission: 'notification:preference', requireAuth: true } },
      { path: 'system/notification/logs', name: 'NotificationLogs', component: () => import('../views/system/notification/logs.vue'), meta: { title: '发送记录', icon: 'el-icon-document', permission: 'notification:log:list', requireAuth: true } },
      { path: 'dictionary', name: 'Dictionary', component: () => import('../views/settings/Dictionary.vue'), meta: { title: '数据字典' } },
      { path: 'app/paths', name: 'AppPaths', component: () => import('../views/app/paths.vue'), meta: { title: '路径管理' } },
      { path: 'app/functions', name: 'AppFunctions', component: () => import('../views/app/functions.vue'), meta: { title: '功能配置' } },
      { path: 'app/mobile-config', name: 'MobileConfig', component: () => import('../views/app/MobileConfig.vue'), meta: { title: '移动端配置' } },
      { path: 'settings/tab-config', name: 'TabConfig', component: () => import('../views/settings/tab-config/index.vue'), meta: { title: '底部导航配置' } },
      { path: 'settings/diy-stats', name: 'DiyStats', component: () => import('../views/settings/diy-stats/index.vue'), meta: { title: '页面数据统计' } },
      { path: 'app/login-config', name: 'LoginConfigMgr', component: () => import('../views/app/LoginConfig.vue'), meta: { title: '登录配置' } },
      { path: 'app/login-page', name: 'LoginPageMgr', component: () => import('../views/app/LoginPage.vue'), meta: { title: '登录页面管理' } },
      { path: 'database', name: 'Database', component: () => import('../views/maintenance/Database.vue'), meta: { title: '数据库维护' } },
      { path: 'license', name: 'SystemLicense', component: () => import('../views/maintenance/License.vue'), meta: { title: '授权管理' } },
      { path: 'system-update', name: 'SystemUpdate', component: () => import('../views/maintenance/SystemUpdate.vue'), meta: { title: '系统更新', icon: 'el-icon-refresh', permission: 'system:update:view', requireAuth: true } },
      { path: 'health-check', name: 'SystemHealth', component: () => import('../views/maintenance/HealthCheck.vue'), meta: { title: '健康检查', icon: 'el-icon-first-aid-kit', permission: 'system:health:view', requireAuth: true } },
      { path: 'mp-push', name: 'MpPushConfig', component: () => import('../views/maintenance/MpPushConfig.vue'), meta: { title: '消息推送', icon: 'el-icon-chat-dot-round', permission: 'system:push:view', requireAuth: true } },
      { path: 'monitor', name: 'Monitor', component: () => import('../views/monitor/Index.vue'), meta: { title: '系统监控' } },
      { path: 'device/category', name: 'DeviceCategory', component: () => import('../views/device/category/index.vue'), meta: { title: '设备分类', icon: 'el-icon-s-tree', permission: 'device:category:list', requireAuth: true } },
      { path: 'device/asset', name: 'DeviceAsset', component: () => import('../views/device/asset/index.vue'), meta: { title: '设备台账', icon: 'el-icon-s-goods', permission: 'device:asset:list', requireAuth: true } },
      { path: 'device/status-change', name: 'DeviceStatusChange', component: () => import('../views/device/status-change/index.vue'), meta: { title: '状态变更', icon: 'el-icon-s-flag', permission: 'device:status:list', requireAuth: true } },
      { path: 'device/inspection', name: 'DeviceInspection', component: () => import('../views/device/inspection/index.vue'), meta: { title: '设备巡检', icon: 'el-icon-s-operation', permission: 'device:inspection:plan:list', requireAuth: true } },
      { path: 'device/inspection/execute', name: 'InspectionExecute', component: () => import('../views/device/inspection/execute.vue'), meta: { title: '巡检执行', hidden: true, requireAuth: true } },
      { path: 'safety/hazard/index', name: 'SafetyHazardList', component: () => import('../views/safety/hazard/index.vue'), meta: { title: '隐患列表', icon: 'el-icon-warning-outline', permission: 'safety:hazard:list', requireAuth: true } },
      { path: 'safety/hazard/create', name: 'SafetyHazardCreate', component: () => import('../views/safety/hazard/create.vue'), meta: { title: '隐患登记', permission: 'safety:hazard:add', requireAuth: true } },
      { path: 'safety/hazard/handle', name: 'SafetyHazardHandle', component: () => import('../views/safety/hazard/handle.vue'), meta: { title: '隐患整改', permission: 'safety:hazard:edit', requireAuth: true } },
      { path: 'safety/hazard/verify', name: 'SafetyHazardVerify', component: () => import('../views/safety/hazard/verify.vue'), meta: { title: '验证任务', permission: 'safety:hazard:verify:list', requireAuth: true } },
      { path: 'safety/hazard/detail', name: 'SafetyHazardDetail', component: () => import('../views/safety/hazard/detail.vue'), meta: { title: '隐患详情', hidden: true, permission: 'safety:hazard:query', requireAuth: true } },
      { path: 'safety/inspection/plan', name: 'SafetyInspectionPlan', component: () => import('../views/safety/inspection/plan/index.vue'), meta: { title: '检查计划', icon: 'el-icon-document', permission: 'safety:inspection:plan:list', requireAuth: true } },
      { path: 'safety/inspection/plan/type', name: 'SafetyInspectionType', component: () => import('../views/safety/inspection/plan/type.vue'), meta: { title: '检查类型', permission: 'safety:inspection:plan:list', requireAuth: true } },
      { path: 'safety/inspection/plan/template', name: 'SafetyInspectionTemplate', component: () => import('../views/safety/inspection/plan/template.vue'), meta: { title: '检查模板', permission: 'safety:inspection:plan:list', requireAuth: true } },
      { path: 'safety/inspection/task', name: 'SafetyInspectionTask', component: () => import('../views/safety/inspection/task/index.vue'), meta: { title: '检查任务', icon: 'el-icon-s-order', permission: 'safety:inspection:task:list', requireAuth: true } },
      { path: 'safety/inspection/task/execute', name: 'SafetyInspectionTaskExecute', component: () => import('../views/safety/inspection/task/execute.vue'), meta: { title: '任务执行', hidden: true, permission: 'safety:inspection:task:execute', requireAuth: true } },
      { path: 'safety/inspection/record', name: 'SafetyInspectionRecord', component: () => import('../views/safety/inspection/record/index.vue'), meta: { title: '检查记录', icon: 'el-icon-s-data', permission: 'safety:inspection:record:list', requireAuth: true } },
      { path: 'safety/training/plan', name: 'SafetyTrainingPlan', component: () => import('../views/safety/training/plan/index.vue'), meta: { title: '培训计划', icon: 'el-icon-reading', permission: 'safety:training:plan:list', requireAuth: true } },
      { path: 'safety/training/plan/type', name: 'SafetyTrainingType', component: () => import('../views/safety/training/plan/type.vue'), meta: { title: '培训类型', permission: 'safety:training:plan:list', requireAuth: true } },
      { path: 'safety/training/plan/teacher', name: 'SafetyTrainingTeacher', component: () => import('../views/safety/training/plan/teacher.vue'), meta: { title: '讲师管理', hidden: true, permission: 'safety:training:plan:list', requireAuth: true } },
      { path: 'safety/training/plan/courseware', name: 'SafetyTrainingCourseware', component: () => import('../views/safety/training/plan/courseware.vue'), meta: { title: '课件管理', hidden: true, permission: 'safety:training:plan:list', requireAuth: true } },
      { path: 'safety/training/record', name: 'SafetyTrainingRecord', component: () => import('../views/safety/training/record/index.vue'), meta: { title: '培训记录', icon: 'el-icon-document-copy', permission: 'safety:training:record:list', requireAuth: true } },
      { path: 'safety/training/archive', name: 'SafetyTrainingArchive', component: () => import('../views/safety/training/archive/index.vue'), meta: { title: '培训档案', icon: 'el-icon-files', permission: 'safety:training:archive:list', requireAuth: true } },
      { path: 'safety/training/exam/question', name: 'ExamQuestion', component: () => import('../views/safety/training/exam/question.vue'), meta: { title: '题库管理', icon: 'el-icon-document', permission: 'safety:training:exam:list', requireAuth: true } },
      { path: 'safety/training/exam/paper', name: 'ExamPaper', component: () => import('../views/safety/training/exam/paper.vue'), meta: { title: '试卷配置', icon: 'el-icon-document-checked', permission: 'safety:training:exam:list', requireAuth: true } },
      { path: 'safety/training/exam/record', name: 'ExamRecord', component: () => import('../views/safety/training/exam/record.vue'), meta: { title: '考试管理', icon: 'el-icon-edit', permission: 'safety:training:exam:list', requireAuth: true } },
      { path: 'safety/training/exam/score', name: 'ExamScore', component: () => import('../views/safety/training/exam/score.vue'), meta: { title: '成绩管理', icon: 'el-icon-s-data', permission: 'safety:training:exam:list', requireAuth: true } },
      { path: 'safety/accident', redirect: '/safety/accident/register' },
      { path: 'safety/accident/register', name: 'AccidentRegister', component: () => import('../views/safety/accident/register.vue'), meta: { title: '事故登记', icon: 'el-icon-warning', permission: 'safety:accident:list', requireAuth: true } },
      { path: 'safety/accident/investigate', name: 'AccidentInvestigate', component: () => import('../views/safety/accident/investigate.vue'), meta: { title: '事故调查', icon: 'el-icon-search', permission: 'safety:accident:investigate:list', requireAuth: true } },
      { path: 'safety/accident/statistics', name: 'AccidentStatistics', component: () => import('../views/safety/accident/statistics.vue'), meta: { title: '事故统计', icon: 'el-icon-data-line', permission: 'safety:accident:statistics:view', requireAuth: true } },
      { path: 'safety/risk', redirect: '/safety/risk/identify' },
      { path: 'safety/risk/identify', name: 'RiskIdentify', component: () => import('../views/safety/risk/identify.vue'), meta: { title: '风险辨识', icon: 'el-icon-search', permission: 'safety:risk:identify:list', requireAuth: true } },
      { path: 'safety/risk/assess', name: 'RiskAssess', component: () => import('../views/safety/risk/assess.vue'), meta: { title: '风险评估', icon: 'el-icon-s-data', permission: 'safety:risk:assess:list', requireAuth: true } },
      { path: 'safety/risk/control', name: 'RiskControl', component: () => import('../views/safety/risk/control.vue'), meta: { title: '管控措施', icon: 'el-icon-s-tools', permission: 'safety:risk:control:list', requireAuth: true } },
      { path: 'safety/training/certificate', name: 'SafetyTrainingCertificate', component: () => import('../views/safety/training/certificate/index.vue'), meta: { title: '证书管理', hidden: true, permission: 'safety:training:certificate:list', requireAuth: true } },
      { path: 'safety/training/certificate/template', name: 'SafetyCertificateTemplate', component: () => import('../views/safety/training/certificate/template.vue'), meta: { title: '证书模板', hidden: true, permission: 'safety:training:certificate:config', requireAuth: true } },
      { path: 'safety/dashboard', name: 'SafetyDashboard', component: () => import('../views/safety/dashboard/index.vue'), meta: { title: '安全驾驶舱', icon: 'el-icon-data-board', permission: 'safety:dashboard:view', requireAuth: true } },
      { path: 'device/maintenance/plan', name: 'MaintenancePlan', component: () => import('../views/device/maintenance/plan/index.vue'), meta: { title: '保养计划', icon: 'el-icon-first-aid-kit', permission: 'device:maintenance:plan:list', requireAuth: true } },
      { path: 'device/maintenance/plan/level', name: 'MaintenancePlanLevel', component: () => import('../views/device/maintenance/plan/level.vue'), meta: { title: '保养等级', permission: 'device:maintenance:level:list', requireAuth: true } },
      { path: 'device/maintenance/plan/template', name: 'MaintenancePlanTemplate', component: () => import('../views/device/maintenance/plan/template.vue'), meta: { title: '保养模板', permission: 'device:maintenance:template:list', requireAuth: true } },
      { path: 'device/maintenance/task', name: 'MaintenanceTask', component: () => import('../views/device/maintenance/task.vue'), meta: { title: '保养任务', icon: 'el-icon-s-order', permission: 'device:maintenance:task:list', requireAuth: true } },
      { path: 'device/maintenance/record', name: 'MaintenanceRecord', component: () => import('../views/device/maintenance/record.vue'), meta: { title: '保养记录', icon: 'el-icon-s-data', permission: 'device:maintenance:record:list', requireAuth: true } },
      { path: 'device/maintenance/statistics', name: 'MaintenanceStatistics', component: () => import('../views/device/maintenance/statistics.vue'), meta: { title: '保养统计', icon: 'el-icon-s-marketing', permission: 'device:maintenance:statistics:view', requireAuth: true } },
      { path: 'device/repair/order', name: 'RepairOrder', component: () => import('../views/device/repair/order.vue'), meta: { title: '维修工单', icon: 'el-icon-document', permission: 'device:repair:order:list', requireAuth: true } },
      { path: 'device/repair/record', name: 'RepairRecord', component: () => import('../views/device/repair/record.vue'), meta: { title: '维修记录', icon: 'el-icon-s-data', permission: 'device:repair:record:list', requireAuth: true } },
      { path: 'device/repair/statistics', name: 'RepairStatistics', component: () => import('../views/device/repair/statistics.vue'), meta: { title: '维修统计', icon: 'el-icon-s-marketing', permission: 'device:repair:statistics:view', requireAuth: true } },
      { path: 'device/remind', name: 'DeviceRemind', component: () => import('../views/device/remind/index.vue'), meta: { title: '设备提醒', icon: 'el-icon-bell', permission: 'device:remind:list', requireAuth: true } },
      // ---- 个人资产 ----
      { path: 'personal-assets/my-list', name: 'PersonalAssetsMyList', component: () => import('../views/personal-assets/my-list.vue'), meta: { title: '我的资产', icon: 'el-icon-user', permission: 'asset:personal:view', requireAuth: true } },
      { path: 'personal-assets/dept-list', name: 'PersonalAssetsDeptList', component: () => import('../views/personal-assets/dept-list.vue'), meta: { title: '部门资产', icon: 'el-icon-office-building', permission: 'asset:personal:dept:view', requireAuth: true } },
      { path: 'personal-assets/all-list', name: 'PersonalAssetsAllList', component: () => import('../views/personal-assets/all-list.vue'), meta: { title: '全部资产', icon: 'el-icon-files', permission: 'asset:personal:all:view', requireAuth: true } },
      { path: 'personal-assets/pick-apply/my-list', name: 'PickApplyMyList', component: () => import('../views/personal-assets/pick-apply/my-list.vue'), meta: { title: '配件领用申请', icon: 'el-icon-s-order', permission: 'asset:pick:apply', requireAuth: true } },
      { path: 'personal-assets/pick-apply/create', name: 'PickApplyCreate', component: () => import('../views/personal-assets/pick-apply/create.vue'), meta: { title: '配件领用申请', permission: 'asset:pick:apply', hidden: true, requireAuth: true } },
      // ---- 资产领用申请 ----
      { path: 'personal-assets/asset-apply/my-list', name: 'AssetApplyMyList', component: () => import('../views/personal-assets/asset-apply/my-list.vue'), meta: { title: '资产领用申请', icon: 'el-icon-s-order', permission: 'asset:asset:apply', requireAuth: true } },
      { path: 'personal-assets/asset-apply/create', name: 'AssetApplyCreate', component: () => import('../views/personal-assets/asset-apply/create.vue'), meta: { title: '资产领用申请', permission: 'asset:asset:apply', hidden: true, requireAuth: true } },
      // ---- 领用记录 ----
      { path: 'personal-assets/apply-records', name: 'ApplyRecords', component: () => import('../views/personal-assets/apply-records.vue'), meta: { title: '领用记录', icon: 'el-icon-document', permission: 'asset:apply:view', requireAuth: true } },
      // ---- 可借用资产 ----
      { path: 'personal-assets/borrowable', name: 'BorrowableAssets', component: () => import('../views/personal-assets/borrowable.vue'), meta: { title: '可借用资产', icon: 'el-icon-s-open', permission: 'asset:borrow:view', requireAuth: true } },
      // ---- 资产调拨 ----
      { path: 'personal-assets/transfer-create', name: 'TransferCreate', component: () => import('../views/personal-assets/transfer-create.vue'), meta: { title: '发起调拨', permission: 'asset:transfer:create', hidden: true, requireAuth: true } },
      { path: 'personal-assets/transfer-apply', name: 'TransferApply', component: () => import('../views/personal-assets/transfer-apply.vue'), meta: { title: '申请调拨', permission: 'asset:transfer:apply', hidden: true, requireAuth: true } },
      { path: 'personal-assets/transfer-pending', name: 'TransferPending', component: () => import('../views/personal-assets/transfer-pending.vue'), meta: { title: '待确认调拨', icon: 'el-icon-time', permission: 'asset:transfer:confirm', requireAuth: true } },
      { path: 'personal-assets/transfer-records', name: 'TransferRecords', component: () => import('../views/personal-assets/transfer-records.vue'), meta: { title: '调拨记录', icon: 'el-icon-document-copy', permission: 'asset:transfer:view', requireAuth: true } },
      // ---- 消耗记录 ----
      { path: 'personal-assets/consume-records', name: 'ConsumeRecords', component: () => import('../views/personal-assets/consume-records.vue'), meta: { title: '消耗记录', icon: 'el-icon-finished', permission: 'asset:consume:view', requireAuth: true } },
      // ---- 消耗统计 ----
      { path: 'personal-assets/consume-stats', name: 'ConsumeStats', component: () => import('../views/personal-assets/consume-stats.vue'), meta: { title: '消耗统计', icon: 'el-icon-data-analysis', permission: 'asset:consume:stats:view', requireAuth: true } },
      // ---- 资产退还 ----
      { path: 'personal-assets/return-apply', name: 'ReturnApply', component: () => import('../views/personal-assets/return-apply.vue'), meta: { title: '退还申请', permission: 'asset:return:apply', hidden: true, requireAuth: true } },
      { path: 'personal-assets/return-records', name: 'ReturnRecords', component: () => import('../views/personal-assets/return-records.vue'), meta: { title: '退还记录', icon: 'el-icon-refresh-left', permission: 'asset:return:view', requireAuth: true } },
      // ---- 固定资产管理 ----
      { path: 'personal-assets/asset-archive', name: 'AssetArchiveList', component: () => import('../views/personal-assets/asset-archive.vue'), meta: { title: '资产档案', icon: 'el-icon-collection', permission: 'asset:archive:view', requireAuth: true } },
      { path: 'personal-assets/asset-depreciation', name: 'AssetDepreciation', component: () => import('../views/personal-assets/asset-depreciation.vue'), meta: { title: '资产折旧', icon: 'el-icon-coin', permission: 'asset:depreciation:view', requireAuth: true } },
      { path: 'personal-assets/inventory', name: 'AssetInventory', component: () => import('../views/personal-assets/inventory.vue'), meta: { title: '资产盘点', icon: 'el-icon-s-grid', permission: 'asset:inventory:view', requireAuth: true } },
      { path: 'personal-assets/dispose', name: 'AssetDispose', component: () => import('../views/personal-assets/dispose.vue'), meta: { title: '资产处置', icon: 'el-icon-delete', permission: 'asset:dispose:view', requireAuth: true } },
      { path: 'personal-assets/inventory-execute', name: 'InventoryExecute', component: () => import('../views/personal-assets/inventory-execute.vue'), meta: { title: '执行盘点', permission: 'asset:inventory:execute', hidden: true, requireAuth: true } },
      // ---- 报表统计 ----
      { path: 'personal-assets/report-personal', name: 'ReportPersonal', component: () => import('../views/personal-assets/report-personal.vue'), meta: { title: '个人资产报表', icon: 'el-icon-data-analysis', permission: 'asset:report:personal:view', requireAuth: true } },
      { path: 'personal-assets/report-dept', name: 'ReportDept', component: () => import('../views/personal-assets/report-dept.vue'), meta: { title: '部门资产汇总', icon: 'el-icon-office-building', permission: 'asset:report:dept:view', requireAuth: true } },
      { path: 'personal-assets/report-transfer', name: 'ReportTransfer', component: () => import('../views/personal-assets/report-transfer.vue'), meta: { title: '调拨统计报表', icon: 'el-icon-sort', permission: 'asset:report:transfer:view', requireAuth: true } },
      { path: 'personal-assets/report-cost', name: 'ReportCost', component: () => import('../views/personal-assets/report-cost.vue'), meta: { title: '资产成本核算', icon: 'el-icon-money', permission: 'asset:report:cost:view', requireAuth: true } },
      { path: 'settings/security/my-keys', name: 'MyKeys', component: () => import('../views/settings/security/MyKeys.vue'), meta: { title: '我的手机密钥', hidden: true, requireAuth: true } },
      { path: 'settings/security/fido2', name: 'Fido2Policy', component: () => import('../views/settings/security/Fido2Policy.vue'), meta: { title: 'FIDO2安全策略', icon: 'el-icon-key', permission: 'settings:fido2:config', requireAuth: true } },
      { path: 'settings/security/policy', name: 'SecurityPolicy', component: () => import('../views/settings/security/policy.vue'), meta: { title: '安全策略', icon: 'el-icon-shield', permission: 'settings:security:policy', requireAuth: true } },
      // ---- 经营管理：经营总览 ----
      { path: 'business/dashboard/overview', name: 'BusinessDashboardOverview', component: () => import('../views/business/dashboard/Overview.vue'), meta: { title: '经营总览', icon: 'el-icon-data-board', permission: 'business:dashboard:view', requireAuth: true } },
      // ---- 统一审批：我的待办 ----
      { path: 'approval/my-tasks', name: 'ApprovalMyTasks', component: () => import('../views/approval/MyTasks.vue'), meta: { title: '我的待办', icon: 'el-icon-tickets', permission: 'approval:task:view', requireAuth: true } },
      // ---- 统一审批：我发起的 ----
      { path: 'approval/my-initiated', name: 'ApprovalMyInitiated', component: () => import('../views/approval/MyInitiated.vue'), meta: { title: '我发起的', icon: 'el-icon-s-promotion', permission: 'approval:task:view', requireAuth: true } },
      // ---- 统一审批：审批历史 ----
      { path: 'approval/history', name: 'ApprovalHistory', component: () => import('../views/approval/History.vue'), meta: { title: '审批历史', icon: 'el-icon-time', permission: 'approval:task:view', requireAuth: true } },
      // ---- 统一审批：审批流程配置 ----
      { path: 'approval/settings', name: 'ApprovalSettings', component: () => import('../views/approval/Settings.vue'), meta: { title: '审批流程配置', icon: 'el-icon-set-up', permission: 'approval:settings:manage', requireAuth: true } },
      // ---- 统一审批：审批代理设置 ----
      { path: 'approval/proxy', name: 'ApprovalProxy', component: () => import('../views/approval/Proxy.vue'), meta: { title: '审批代理设置', icon: 'el-icon-user', permission: 'approval:proxy:set', requireAuth: true } },
      // ---- 统一审批：审批统计 ----
      { path: 'approval/statistics', name: 'ApprovalStatistics', component: () => import('../views/approval/Statistics.vue'), meta: { title: '审批统计', icon: 'el-icon-data-analysis', permission: 'approval:statistics:view', requireAuth: true } },
      // ---- 统一审批：常用语管理 ----
      { path: 'approval/phrases', name: 'ApprovalPhrases', component: () => import('../views/approval/Phrases.vue'), meta: { title: '常用语管理', icon: 'el-icon-chat-dot-square', permission: 'approval:task:view', requireAuth: true } },
      // ---- 库存盘点：盘点计划 ----
      { path: 'warehouse/check/plan', name: 'InventoryPlanList', component: () => import('../views/warehouse/check/plan/List.vue'), meta: { title: '盘点计划', icon: 'el-icon-notebook-2', permission: 'warehouse:check:plan:view', requireAuth: true } },
      { path: 'warehouse/check/plan/add', name: 'InventoryPlanAdd', component: () => import('../views/warehouse/check/plan/Add.vue'), meta: { title: '新增盘点计划', permission: 'warehouse:check:plan:add', hidden: true, requireAuth: true } },
      { path: 'warehouse/check/plan/edit/:id', name: 'InventoryPlanEdit', component: () => import('../views/warehouse/check/plan/Edit.vue'), meta: { title: '编辑盘点计划', permission: 'warehouse:check:plan:edit', hidden: true, requireAuth: true } },
      { path: 'warehouse/check/plan/detail/:id', name: 'InventoryPlanDetail', component: () => import('../views/warehouse/check/plan/Detail.vue'), meta: { title: '盘点计划详情', permission: 'warehouse:check:plan:view', hidden: true, requireAuth: true } },
      // ---- 库存盘点：盘点执行 ----
      { path: 'warehouse/check/execute', name: 'InventoryExecute', component: () => import('../views/warehouse/check/execute/Index.vue'), meta: { title: '盘点执行', icon: 'el-icon-s-operation', permission: 'warehouse:check:execute:view', requireAuth: true } },
      // ---- 库存盘点：盘点差异 ----
      { path: 'warehouse/check/diff', name: 'InventoryDiff', component: () => import('../views/warehouse/check/diff/Index.vue'), meta: { title: '盘点差异', icon: 'el-icon-difference', permission: 'warehouse:check:diff:view', requireAuth: true } },
      // ---- 仓储管理：仓库管理 ----
      { path: 'warehouse/setting/warehouse', name: 'WarehouseSettingWarehouse', component: () => import('../views/warehouse/setting/warehouse/List.vue'), meta: { title: '仓库管理', icon: 'el-icon-office-building', permission: 'warehouse:setting:warehouse:view', requireAuth: true } },
      // 货位管理
      { path: 'warehouse/setting/location', name: 'WarehouseSettingLocation', component: () => import('../views/warehouse/setting/location/List.vue'), meta: { title: '货位管理', icon: 'el-icon-map-location', permission: 'warehouse:setting:location:view', requireAuth: true } },
      // 物料管理
      { path: 'warehouse/setting/material', name: 'WarehouseSettingMaterial', component: () => import('../views/warehouse/setting/material/List.vue'), meta: { title: '物料管理', icon: 'el-icon-goods', permission: 'warehouse:setting:material:view', requireAuth: true } },
      // 物料分类管理
      { path: 'warehouse/setting/material/category', name: 'WarehouseSettingMaterialCategory', component: () => import('../views/warehouse/setting/material/category/List.vue'), meta: { title: '物料分类管理', icon: 'el-icon-folder-opened', permission: 'warehouse:setting:material:category:view', requireAuth: true } },
      // 物料详情
      { path: 'warehouse/setting/material/detail/:id', name: 'WarehouseSettingMaterialDetail', component: () => import('../views/warehouse/setting/material/detail/Detail.vue'), meta: { title: '物料详情', icon: 'el-icon-view', permission: 'warehouse:setting:material:view', hidden: true, requireAuth: true } },
      // 编码规则
      { path: 'settings/code-rule/material', name: 'MaterialCodeRule', component: () => import('../views/settings/code-rule/material/CodeRule.vue'), meta: { title: '物料编码规则', icon: 'el-icon-setting', permission: 'warehouse:setting:material:view', requireAuth: true } },
      // 货位编码规则
      { path: 'settings/code-rule/location', name: 'LocationCodeRule', component: () => import('../views/settings/code-rule/location/LocationRule.vue'), meta: { title: '货位编码规则', icon: 'el-icon-setting', permission: 'warehouse:setting:location:view', requireAuth: true } },
      // ---- 仓储管理：采购入库 ----
      { path: 'warehouse/parts/purchase-in/list', name: 'WarehousePurchaseInList', component: () => import('../views/warehouse/parts/purchase-in/List.vue'), meta: { title: '采购入库', icon: 'el-icon-download', permission: 'warehouse:purchase:in:view', requireAuth: true } },
      { path: 'warehouse/parts/purchase-in/add', name: 'WarehousePurchaseInAdd', component: () => import('../views/warehouse/parts/purchase-in/Add.vue'), meta: { title: '新增采购入库单', permission: 'warehouse:purchase:in:add', hidden: true, requireAuth: true } },
      { path: 'warehouse/parts/purchase-in/edit/:id', name: 'WarehousePurchaseInEdit', component: () => import('../views/warehouse/parts/purchase-in/Add.vue'), meta: { title: '编辑采购入库单', permission: 'warehouse:purchase:in:edit', hidden: true, requireAuth: true } },
      { path: 'warehouse/parts/purchase-in/detail/:id', name: 'WarehousePurchaseInDetail', component: () => import('../views/warehouse/parts/purchase-in/Detail.vue'), meta: { title: '采购入库单详情', permission: 'warehouse:purchase:in:view', hidden: true, requireAuth: true } },
      { path: 'warehouse/parts/purchase-in/statistics', name: 'WarehousePurchaseInStatistics', component: () => import('../views/warehouse/parts/purchase-in/Statistics.vue'), meta: { title: '入库统计', icon: 'el-icon-data-analysis', permission: 'warehouse:purchase:in:statistics:view', requireAuth: true } },
      // ---- 仓储管理：配件退库 ----
      { path: 'warehouse/parts/return/list', name: 'WarehouseReturnList', component: () => import('../views/warehouse/parts/return/List.vue'), meta: { title: '配件退库', icon: 'el-icon-refresh-left', permission: 'warehouse:return:view', requireAuth: true } },
      { path: 'warehouse/parts/return/add', name: 'WarehouseReturnAdd', component: () => import('../views/warehouse/parts/return/Add.vue'), meta: { title: '新增退库单', permission: 'warehouse:return:add', hidden: true, requireAuth: true } },
      { path: 'warehouse/parts/return/edit/:id', name: 'WarehouseReturnEdit', component: () => import('../views/warehouse/parts/return/Add.vue'), meta: { title: '编辑退库单', permission: 'warehouse:return:edit', hidden: true, requireAuth: true } },
      { path: 'warehouse/parts/return/detail/:id', name: 'WarehouseReturnDetail', component: () => import('../views/warehouse/parts/return/Detail.vue'), meta: { title: '退库单详情', permission: 'warehouse:return:view', hidden: true, requireAuth: true } },
      // ---- 仓储管理：报废出库 ----
      { path: 'warehouse/parts/scrap/list', name: 'WarehouseScrapList', component: () => import('../views/warehouse/parts/scrap/List.vue'), meta: { title: '报废出库', icon: 'el-icon-delete', permission: 'warehouse:scrap:view', requireAuth: true } },
      { path: 'warehouse/parts/scrap/add', name: 'WarehouseScrapAdd', component: () => import('../views/warehouse/parts/scrap/Add.vue'), meta: { title: '新增报废单', permission: 'warehouse:scrap:add', hidden: true, requireAuth: true } },
      { path: 'warehouse/parts/scrap/edit/:id', name: 'WarehouseScrapEdit', component: () => import('../views/warehouse/parts/scrap/Add.vue'), meta: { title: '编辑报废单', permission: 'warehouse:scrap:edit', hidden: true, requireAuth: true } },
      { path: 'warehouse/parts/scrap/detail/:id', name: 'WarehouseScrapDetail', component: () => import('../views/warehouse/parts/scrap/Detail.vue'), meta: { title: '报废单详情', permission: 'warehouse:scrap:view', hidden: true, requireAuth: true } },
      // ---- 仓储管理：产品接收（设备入库） ----
      { path: 'warehouse/device/receive/list', name: 'WarehouseDeviceReceiptList', component: () => import('../views/warehouse/device/receive/List.vue'), meta: { title: '产品接收', icon: 'el-icon-box', permission: 'warehouse:device:receive:view', requireAuth: true } },
      { path: 'warehouse/device/receive/add', name: 'WarehouseDeviceReceiptAdd', component: () => import('../views/warehouse/device/receive/Add.vue'), meta: { title: '新增入库单', permission: 'warehouse:device:receive:add', hidden: true, requireAuth: true } },
      { path: 'warehouse/device/receive/edit/:id', name: 'WarehouseDeviceReceiptEdit', component: () => import('../views/warehouse/device/receive/Add.vue'), meta: { title: '编辑入库单', permission: 'warehouse:device:receive:edit', hidden: true, requireAuth: true } },
      { path: 'warehouse/device/receive/detail/:id', name: 'WarehouseDeviceReceiptDetail', component: () => import('../views/warehouse/device/receive/Detail.vue'), meta: { title: '入库单详情', permission: 'warehouse:device:receive:view', hidden: true, requireAuth: true } },
      // ---- 仓储管理：产品入库（上架确认） ----
      { path: 'warehouse/product/in/list', name: 'WarehouseProductInList', component: () => import('../views/warehouse/product/in/List.vue'), meta: { title: '产品入库', icon: 'el-icon-sort', permission: 'warehouse:product:in:view', requireAuth: true } },
      { path: 'warehouse/product/in/add', name: 'WarehouseProductInAdd', component: () => import('../views/warehouse/product/in/Add.vue'), meta: { title: '新增产品入库单', permission: 'warehouse:product:in:add', hidden: true, requireAuth: true } },
      { path: 'warehouse/product/in/edit/:id', name: 'WarehouseProductInEdit', component: () => import('../views/warehouse/product/in/Add.vue'), meta: { title: '编辑产品入库单', permission: 'warehouse:product:in:edit', hidden: true, requireAuth: true } },
      { path: 'warehouse/product/in/detail/:id', name: 'WarehouseProductInDetail', component: () => import('../views/warehouse/product/in/Detail.vue'), meta: { title: '入库单详情', permission: 'warehouse:product:in:view', hidden: true, requireAuth: true } },
      // ---- 仓储管理：产品出库 ----
      { path: 'warehouse/product/out/list', name: 'WarehouseProductOutList', component: () => import('../views/warehouse/product/out/List.vue'), meta: { title: '产品出库', icon: 'el-icon-sold-out', permission: 'warehouse:product:out:view', requireAuth: true } },
      { path: 'warehouse/product/out/add', name: 'WarehouseProductOutAdd', component: () => import('../views/warehouse/product/out/Add.vue'), meta: { title: '新增产品出库单', permission: 'warehouse:product:out:add', hidden: true, requireAuth: true } },
      { path: 'warehouse/product/out/edit/:id', name: 'WarehouseProductOutEdit', component: () => import('../views/warehouse/product/out/Add.vue'), meta: { title: '编辑产品出库单', permission: 'warehouse:product:out:edit', hidden: true, requireAuth: true } },
      { path: 'warehouse/product/out/detail/:id', name: 'WarehouseProductOutDetail', component: () => import('../views/warehouse/product/out/Detail.vue'), meta: { title: '出库单详情', permission: 'warehouse:product:out:view', hidden: true, requireAuth: true } },
      // ---- 仓储管理：库存查询 ----
      { path: 'warehouse/inventory/query', name: 'WarehouseInventoryQuery', component: () => import('../views/warehouse/inventory/Query.vue'), meta: { title: '库存查询', icon: 'el-icon-search', permission: 'warehouse:inventory:query:view', requireAuth: true } },
      { path: 'warehouse/inventory/flow', name: 'WarehouseInventoryFlow', component: () => import('../views/warehouse/inventory/Flow.vue'), meta: { title: '库存流水', icon: 'el-icon-s-order', permission: 'warehouse:inventory:flow:view', requireAuth: true } },
      { path: 'warehouse/inventory/alert', name: 'WarehouseInventoryAlert', component: () => import('../views/warehouse/inventory/Alert.vue'), meta: { title: '库存预警', icon: 'el-icon-warning', permission: 'warehouse:inventory:alert:view', requireAuth: true } },       { path: 'warehouse/inventory/analysis', name: 'WarehouseInventoryAnalysis', component: () => import('../views/warehouse/inventory/Analysis.vue'), meta: { title: '库存分析', icon: 'el-icon-data-analysis', permission: 'warehouse:inventory:analysis:view', requireAuth: true } },
      // 入库编号规则
      { path: 'settings/code-rule/purchase-in', name: 'PurchaseInCodeRule', component: () => import('../views/settings/code-rule/purchase-in/PurchaseInRule.vue'), meta: { title: '入库单编号规则', icon: 'el-icon-setting', permission: 'warehouse:purchase:in:view', requireAuth: true } },
      // ---- 仓储管理：配件领用 ----
      { path: 'warehouse/parts/pick/list', name: 'WarehousePickList', component: () => import('../views/warehouse/parts/pick/List.vue'), meta: { title: '配件领用', icon: 'el-icon-sold-out', permission: 'warehouse:pick:view', requireAuth: true } },
      { path: 'warehouse/parts/pick/add', name: 'WarehousePickAdd', component: () => import('../views/warehouse/parts/pick/Add.vue'), meta: { title: '新增领料单', permission: 'warehouse:pick:add', hidden: true, requireAuth: true } },
      { path: 'warehouse/parts/pick/edit/:id', name: 'WarehousePickEdit', component: () => import('../views/warehouse/parts/pick/Add.vue'), meta: { title: '编辑领料单', permission: 'warehouse:pick:edit', hidden: true, requireAuth: true } },
      { path: 'warehouse/parts/pick/detail/:id', name: 'WarehousePickDetail', component: () => import('../views/warehouse/parts/pick/Detail.vue'), meta: { title: '领料单详情', permission: 'warehouse:pick:view', hidden: true, requireAuth: true } },
      // ---- 经营管理：客户管理 ----
      { path: 'business/customer', name: 'BusinessCustomer', component: () => import('../views/business/customer/index.vue'), meta: { title: '客户列表', icon: 'el-icon-user', permission: 'business:customer:list', requireAuth: true } },
      // 新增客户（复用列表页，进入自动打开新增弹窗）
      { path: 'business/customer/create', name: 'BusinessCustomerCreate', component: () => import('../views/business/customer/index.vue'), meta: { title: '新增客户', icon: 'el-icon-plus', permission: 'business:customer:add', hidden: true, requireAuth: true } },
      { path: 'business/customer/category', name: 'BusinessCustomerCategory', component: () => import('../views/business/customer/category.vue'), meta: { title: '客户分类', icon: 'el-icon-s-operation', permission: 'business:customer:category', requireAuth: true } },
      // ---- 经营管理：供应商管理 ----
      { path: 'warehouse/batch', name: 'WarehouseBatch', component: () => import('../views/warehouse/Batch.vue'), meta: { title: '批次管理', permission: 'batch:view', requireAuth: true } },
      { path: 'warehouse/scan', name: 'WarehouseScanIo', component: () => import('../views/warehouse/ScanIo.vue'), meta: { title: '扫码出入库', permission: 'warehouse:scan:view', requireAuth: true } },       { path: 'warehouse/replenish', name: 'WarehouseReplenish', component: () => import('../views/warehouse/Replenish.vue'), meta: { title: '补货建议', permission: 'warehouse:replenish:view', requireAuth: true } },       { path: 'warehouse/stocktake', name: 'WarehouseStocktake', component: () => import('../views/warehouse/Stocktake.vue'), meta: { title: '库存盘点', permission: 'warehouse:check:plan:view', requireAuth: true } },,
      { path: 'production/cost', name: 'ProductionCost', component: () => import('../views/production/Cost.vue'), meta: { title: '成本核算', permission: 'production:cost:view', requireAuth: true } },
      { path: 'production/andon', name: 'ProductionAndon', component: () => import('../views/production/Andon.vue'), meta: { title: '生产异常呼叫', permission: 'production:andon:view', requireAuth: true } },
      { path: 'production/ecn', name: 'ProductionEcn', component: () => import('../views/production/Ecn.vue'), meta: { title: 'ECN变更', permission: 'production:ecn:view', requireAuth: true } },
      { path: 'device/oee', name: 'DeviceOee', component: () => import('../views/device/Oee.vue'), meta: { title: 'OEE分析', permission: 'device:oee:view', requireAuth: true } },
      { path: 'business/crm/leads', name: 'CrmLeads', component: () => import('../views/business/crm/Leads.vue'), meta: { title: '销售线索', permission: 'business:crm:view', requireAuth: true } },
      { path: 'business/crm/funnel', name: 'CrmFunnel', component: () => import('../views/business/crm/Funnel.vue'), meta: { title: '商机漏斗', permission: 'business:crm:view', requireAuth: true } },
      { path: 'business/crm/opportunities', name: 'CrmOpportunities', component: () => import('../views/business/crm/Opportunities.vue'), meta: { title: '商机列表', permission: 'business:crm:view', requireAuth: true } },
      { path: 'business/project', name: 'BusinessProject', component: () => import('../views/business/Project.vue'), meta: { title: '项目管理', permission: 'business:project:view', requireAuth: true } },
      { path: 'bi/reports', name: 'BiReports', component: () => import('../views/bi/Reports.vue'), meta: { title: 'BI报表', permission: 'bi:report:view', requireAuth: true } },
      { path: 'drive/files', name: 'DriveFiles', component: () => import('../views/drive/Files.vue'), meta: { title: '企业网盘', permission: 'drive:file:view', requireAuth: true } },
      { path: 'business/supplier', name: 'BusinessSupplier', component: () => import('../views/business/supplier/index.vue'), meta: { title: '供应商列表', icon: 'el-icon-truck', permission: 'business:supplier:list', requireAuth: true } },
      // 新增供应商（复用列表页，进入自动打开新增弹窗）
      { path: 'business/supplier/create', name: 'BusinessSupplierCreate', component: () => import('../views/business/supplier/index.vue'), meta: { title: '新增供应商', icon: 'el-icon-plus', permission: 'business:supplier:add', hidden: true, requireAuth: true } },
      { path: 'business/supplier/category', name: 'BusinessSupplierCategory', component: () => import('../views/business/supplier/category.vue'), meta: { title: '供应商分类', icon: 'el-icon-s-operation', permission: 'business:supplier:category', requireAuth: true } },
      // ---- 经营管理：订单中心 ----
      { path: 'business/order', name: 'BusinessOrder', component: () => import('../views/business/order/index.vue'), meta: { title: '订单列表', icon: 'el-icon-document', permission: 'business:order:list', requireAuth: true } },
      // 新增订单（复用列表页，进入自动打开新增弹窗）
      { path: 'business/order/add', name: 'BusinessOrderAdd', component: () => import('../views/business/order/index.vue'), meta: { title: '新增订单', icon: 'el-icon-plus', permission: 'business:order:add', hidden: true, requireAuth: true } },
      // 订单评审（复用列表页，进入自动切评审 Tab）
      { path: 'business/order/review', name: 'BusinessOrderReview', component: () => import('../views/business/order/index.vue'), meta: { title: '订单评审', icon: 'el-icon-check', permission: 'business:order:review', requireAuth: true } },
      // ---- 销售管理-销售出库 ----
      { path: 'business/sales/out/list', name: 'SalesOutList', component: () => import('../views/business/sales/out/List.vue'), meta: { title: '出库单列表', icon: 'el-icon-box', permission: 'sales:out:list:view', requireAuth: true } },
      { path: 'business/sales/out/add', name: 'SalesOutAdd', component: () => import('../views/business/sales/out/Add.vue'), meta: { title: '新增出库单', permission: 'sales:out:add', hidden: true, requireAuth: true } },
      { path: 'business/sales/out/edit/:id', name: 'SalesOutEdit', component: () => import('../views/business/sales/out/Add.vue'), meta: { title: '编辑出库单', permission: 'sales:out:edit', hidden: true, requireAuth: true } },
      { path: 'business/sales/out/detail/:id', name: 'SalesOutDetail', component: () => import('../views/business/sales/out/Detail.vue'), meta: { title: '出库单详情', permission: 'sales:out:list:view', hidden: true, requireAuth: true } },
      // ---- 销售管理-发货通知 ----
      { path: 'business/sales/ship/notice', name: 'ShipNoticeList', component: () => import('../views/business/sales/ship/notice/List.vue'), meta: { title: '发货通知', icon: 'el-icon-truck', permission: 'sales:ship:notice:view', requireAuth: true } },
      { path: 'business/sales/ship/notice/add', name: 'ShipNoticeAdd', component: () => import('../views/business/sales/ship/notice/Add.vue'), meta: { title: '新增通知', permission: 'sales:ship:notice:add', hidden: true, requireAuth: true } },
      { path: 'business/sales/ship/notice/edit/:id', name: 'ShipNoticeEdit', component: () => import('../views/business/sales/ship/notice/Add.vue'), meta: { title: '编辑通知', permission: 'sales:ship:notice:edit', hidden: true, requireAuth: true } },
      { path: 'business/sales/ship/notice/detail/:id', name: 'ShipNoticeDetail', component: () => import('../views/business/sales/ship/notice/Detail.vue'), meta: { title: '通知详情', permission: 'sales:ship:notice:view', hidden: true, requireAuth: true } },
      // ---- 销售管理-发货单 ----
      { path: 'business/sales/ship/list', name: 'ShipOrderList', component: () => import('../views/business/sales/ship/List.vue'), meta: { title: '发货单列表', icon: 'el-icon-ship', permission: 'sales:ship:list:view', requireAuth: true } },
      { path: 'business/sales/ship/detail/:id', name: 'ShipOrderDetail', component: () => import('../views/business/sales/ship/List.vue'), meta: { title: '发货单详情', permission: 'sales:ship:list:view', hidden: true, requireAuth: true } },
      // ---- 销售管理-物流跟踪 ----
      { path: 'business/sales/ship/track', name: 'SalesShipTrack', component: () => import('../views/business/sales/ship/Track.vue'), meta: { title: '物流跟踪', icon: 'el-icon-truck', permission: 'sales:track:view', requireAuth: true } },
      // ---- 销售管理-销售额分析 ----
      { path: 'business/sales/statistics/revenue', name: 'SalesStatisticsRevenue', component: () => import('../views/business/sales/statistics/Revenue.vue'), meta: { title: '销售额分析', icon: 'el-icon-data-analysis', permission: 'sales:statistics:revenue:view', requireAuth: true } },
      // ---- 销售管理-客户排行 ----
      { path: 'business/sales/statistics/customer', name: 'SalesStatisticsCustomer', component: () => import('../views/business/sales/statistics/Customer.vue'), meta: { title: '客户排行', icon: 'el-icon-rank', permission: 'sales:statistics:customer:view', requireAuth: true } },
      // ---- 销售管理-产品排行 ----
      { path: 'business/sales/statistics/product', name: 'SalesStatisticsProduct', component: () => import('../views/business/sales/statistics/Product.vue'), meta: { title: '产品排行', icon: 'el-icon-goods', permission: 'sales:statistics:product:view', requireAuth: true } },
      // ---- 经营管理：报价管理 ----
      { path: 'business/quotation', name: 'BusinessQuotation', component: () => import('../views/business/quotation/index.vue'), meta: { title: '报价单列表', icon: 'el-icon-document-copy', permission: 'business:quotation:list', requireAuth: true } },
      // 新增报价单（复用列表页，进入自动打开新增弹窗）
      { path: 'business/quotation/add', name: 'BusinessQuotationAdd', component: () => import('../views/business/quotation/index.vue'), meta: { title: '新增报价单', icon: 'el-icon-plus', permission: 'business:quotation:add', hidden: true, requireAuth: true } },
      // 报价单审核（复用列表页，进入自动切审核 Tab）
      { path: 'business/quotation/review', name: 'BusinessQuotationReview', component: () => import('../views/business/quotation/index.vue'), meta: { title: '报价单审核', icon: 'el-icon-check', permission: 'business:quotation:review', requireAuth: true } },
      // ---- 经营管理：合同管理 ----
      { path: 'business/contract', name: 'BusinessContract', component: () => import('../views/business/contract/index.vue'), meta: { title: '合同列表', icon: 'el-icon-document', permission: 'business:contract:list', requireAuth: true } },
      // 新增合同（复用列表页，进入自动打开新增弹窗）
      { path: 'business/contract/add', name: 'BusinessContractAdd', component: () => import('../views/business/contract/index.vue'), meta: { title: '新增合同', icon: 'el-icon-plus', permission: 'business:contract:add', hidden: true, requireAuth: true } },
      // 合同到期提醒
      { path: 'business/contract/remind', name: 'BusinessContractRemind', component: () => import('../views/business/contract/remind.vue'), meta: { title: '合同到期提醒', icon: 'el-icon-bell', permission: 'business:contract:remind', requireAuth: true } },
      // 合同模板管理
      { path: 'budget', name: 'Budget', component: () => import('../views/business/Budget.vue'), meta: { title: '预算管理', icon: 'el-icon-coin', permission: 'budget:view', requireAuth: true } },
      // ---- 经营管理：财务管理 ----
      { path: 'finance', name: 'Finance', component: () => import('../views/business/Finance.vue'), meta: { title: '财务管理', icon: 'el-icon-money', permission: 'finance:view', requireAuth: true } },
      // ---- 财务管理：凭证总账 ----
      { path: 'finance/voucher', name: 'FinanceVoucher', component: () => import('../views/finance/Voucher.vue'), meta: { title: '财务总账', icon: 'el-icon-notebook-2', permission: 'finance:voucher:view', requireAuth: true } },
      { path: 'finance/statement', name: 'FinanceStatement', component: () => import('../views/finance/Statement.vue'), meta: { title: '财务报表', icon: 'el-icon-data-analysis', permission: 'finance:statement:view', requireAuth: true } },
      { path: 'finance/aging', name: 'FinanceAging', component: () => import('../views/finance/Aging.vue'), meta: { title: '账龄分析', icon: 'el-icon-time', permission: 'finance:aging:view', requireAuth: true } },       { path: 'finance/ledger', name: 'FinanceLedger', component: () => import('../views/finance/Voucher.vue'), meta: { title: '总账查询', initialTab: 'ledger-detail', permission: 'finance:voucher:view', requireAuth: true } },       { path: 'finance/subject', name: 'FinanceSubject', component: () => import('../views/finance/Voucher.vue'), meta: { title: '会计科目', initialTab: 'subject', permission: 'finance:subject:manage', requireAuth: true } },       { path: 'safety/training/exam', name: 'SafetyTrainingExamRedirect', redirect: '/safety/training/exam/record' },
      { path: 'business/contract/template', name: 'BusinessContractTemplate', component: () => import('../views/business/contract/template/index.vue'), meta: { title: '合同模板管理', icon: 'el-icon-document-copy', permission: 'business:contract:template', requireAuth: true } },
      // ---- 经营管理：产品管理 ----
      { path: 'business/product/list', name: 'BusinessProductList', component: () => import('../views/business/product/List.vue'), meta: { title: '产品列表', icon: 'el-icon-goods', permission: 'business:product:list', requireAuth: true } },
      // 新增产品
      { path: 'business/product/add', name: 'BusinessProductAdd', component: () => import('../views/business/product/Add.vue'), meta: { title: '新增产品', icon: 'el-icon-plus', permission: 'business:product:add', hidden: true, requireAuth: true } },
      // 编辑产品
      { path: 'business/product/edit/:id', name: 'BusinessProductEdit', component: () => import('../views/business/product/Edit.vue'), meta: { title: '编辑产品', icon: 'el-icon-edit', permission: 'business:product:edit', hidden: true, requireAuth: true } },
      // 产品详情
      { path: 'business/product/detail/:id', name: 'BusinessProductDetail', component: () => import('../views/business/product/Detail.vue'), meta: { title: '产品详情', icon: 'el-icon-view', permission: 'business:product:list', hidden: true, requireAuth: true } },
      // 产品分类
      { path: 'business/product/category', name: 'BusinessProductCategory', component: () => import('../views/business/product/Category.vue'), meta: { title: '产品分类', icon: 'el-icon-s-operation', permission: 'business:product:category', requireAuth: true } },
      // ---- 经营管理：产品BOM管理 ----
      { path: 'business/product/bom', name: 'BusinessProductBom', component: () => import('../views/business/product/bom/List.vue'), meta: { title: 'BOM管理', icon: 'el-icon-share', permission: 'business:product:bom:list', requireAuth: true } },
      // 新增BOM
      { path: 'business/product/bom/add', name: 'BusinessProductBomAdd', component: () => import('../views/business/product/bom/Add.vue'), meta: { title: '新增BOM', icon: 'el-icon-plus', permission: 'business:product:bom:add', hidden: true, requireAuth: true } },
      // 编辑BOM
      { path: 'business/product/bom/edit/:id', name: 'BusinessProductBomEdit', component: () => import('../views/business/product/bom/Edit.vue'), meta: { title: '编辑BOM', icon: 'el-icon-edit', permission: 'business:product:bom:edit', hidden: true, requireAuth: true } },
      // BOM详情
      { path: 'business/product/bom/detail/:id', name: 'BusinessProductBomDetail', component: () => import('../views/business/product/bom/Detail.vue'), meta: { title: 'BOM详情', icon: 'el-icon-view', permission: 'business:product:bom:list', hidden: true, requireAuth: true } },
      // ---- 经营管理：产品图纸管理 ----
      { path: 'business/product/drawing/list', name: 'BusinessProductDrawingList', component: () => import('../views/business/product/drawing/List.vue'), meta: { title: '图纸管理', icon: 'el-icon-document', permission: 'business:product:drawing:list', requireAuth: true } },
      // 上传图纸
      { path: 'business/product/drawing/upload', name: 'BusinessProductDrawingUpload', component: () => import('../views/business/product/drawing/Upload.vue'), meta: { title: '上传图纸', icon: 'el-icon-upload2', permission: 'business:product:drawing:add', hidden: true, requireAuth: true } },
      // 编辑图纸（复用 Upload）
      { path: 'business/product/drawing/edit/:id', name: 'BusinessProductDrawingEdit', component: () => import('../views/business/product/drawing/Upload.vue'), meta: { title: '编辑图纸', icon: 'el-icon-edit', permission: 'business:product:drawing:edit', hidden: true, requireAuth: true } },
      // 图纸详情
      { path: 'business/product/drawing/detail/:id', name: 'BusinessProductDrawingDetail', component: () => import('../views/business/product/drawing/Detail.vue'), meta: { title: '图纸详情', icon: 'el-icon-view', permission: 'business:product:drawing:list', hidden: true, requireAuth: true } },
      // 图纸分类
      { path: 'business/product/drawing/category', name: 'BusinessProductDrawingCategory', component: () => import('../views/business/product/drawing/Category.vue'), meta: { title: '图纸分类管理', icon: 'el-icon-s-operation', permission: 'business:product:drawing:category:list', requireAuth: true } },
      // ---- 经营管理：采购申请 ----
      { path: 'business/purchase/request/list', name: 'BusinessPurchaseRequestList', component: () => import('../views/business/purchase/request/List.vue'), meta: { title: '采购申请管理', icon: 'el-icon-shopping-cart-2', permission: 'business:purchase:request:list', requireAuth: true } },
      { path: 'purchase/inquiry', name: 'PurchaseInquiry', component: () => import('../views/purchase/Inquiry.vue'), meta: { title: '询比价管理', icon: 'el-icon-data-analysis', permission: 'purchase:inquiry:view', requireAuth: true } },
      // 新增采购申请
      { path: 'business/purchase/request/add', name: 'BusinessPurchaseRequestAdd', component: () => import('../views/business/purchase/request/Add.vue'), meta: { title: '新增采购申请', icon: 'el-icon-plus', permission: 'business:purchase:request:add', hidden: true, requireAuth: true } },
      // 编辑采购申请
      { path: 'business/purchase/request/edit/:id', name: 'BusinessPurchaseRequestEdit', component: () => import('../views/business/purchase/request/Edit.vue'), meta: { title: '编辑采购申请', icon: 'el-icon-edit', permission: 'business:purchase:request:edit', hidden: true, requireAuth: true } },
      // 采购申请详情
      { path: 'business/purchase/request/detail/:id', name: 'BusinessPurchaseRequestDetail', component: () => import('../views/business/purchase/request/Detail.vue'), meta: { title: '采购申请详情', icon: 'el-icon-view', permission: 'business:purchase:request:list', hidden: true, requireAuth: true } },
      // ---- 经营管理：采购订单 ----
      { path: 'business/purchase/order/list', name: 'BusinessPurchaseOrderList', component: () => import('../views/business/purchase/order/List.vue'), meta: { title: '采购订单管理', icon: 'el-icon-s-order', permission: 'business:purchase:order:list', requireAuth: true } },
      // 新增采购订单
      { path: 'business/purchase/order/add', name: 'BusinessPurchaseOrderAdd', component: () => import('../views/business/purchase/order/Add.vue'), meta: { title: '新增采购订单', icon: 'el-icon-plus', permission: 'business:purchase:order:add', hidden: true, requireAuth: true } },
      // 编辑采购订单
      { path: 'business/purchase/order/edit/:id', name: 'BusinessPurchaseOrderEdit', component: () => import('../views/business/purchase/order/Add.vue'), meta: { title: '编辑采购订单', icon: 'el-icon-edit', permission: 'business:purchase:order:edit', hidden: true, requireAuth: true } },
      // 采购订单详情
      { path: 'business/purchase/order/detail/:id', name: 'BusinessPurchaseOrderDetail', component: () => import('../views/business/purchase/order/Detail.vue'), meta: { title: '采购订单详情', icon: 'el-icon-view', permission: 'business:purchase:order:list', hidden: true, requireAuth: true } },
      { path: 'business/purchase/order/track', name: 'BusinessPurchaseOrderTrack', component: () => import('../views/business/purchase/order/Track.vue'), meta: { title: '采购订单跟踪', icon: 'el-icon-monitor', permission: 'business:purchase:order:track:view', requireAuth: true } },
      { path: 'business/purchase/arrival/list', name: 'BusinessPurchaseArrivalList', component: () => import('../views/business/purchase/arrival/List.vue'), meta: { title: '采购到货', icon: 'el-icon-van', permission: 'business:purchase:arrival:view', requireAuth: true } },
      { path: 'business/purchase/arrival/add', name: 'BusinessPurchaseArrivalAdd', component: () => import('../views/business/purchase/arrival/Add.vue'), meta: { title: '新增到货登记', icon: 'el-icon-plus', permission: 'business:purchase:arrival:add', hidden: true, requireAuth: true } },
      { path: 'business/purchase/arrival/detail/:id', name: 'BusinessPurchaseArrivalDetail', component: () => import('../views/business/purchase/arrival/Detail.vue'), meta: { title: '到货单详情', icon: 'el-icon-view', permission: 'business:purchase:arrival:view', hidden: true, requireAuth: true } },
      { path: 'business/purchase/arrival/record', name: 'BusinessPurchaseArrivalRecord', component: () => import('../views/business/purchase/arrival/Record.vue'), meta: { title: '到货记录', icon: 'el-icon-notebook-2', permission: 'business:purchase:arrival:record:view', requireAuth: true } },
      { path: 'business/purchase/statistics/overview', name: 'BusinessPurchaseStatsOverview', component: () => import('../views/business/purchase/statistics/Overview.vue'), meta: { title: '采购统计总览', icon: 'el-icon-data-line', permission: 'business:purchase:statistics:view', requireAuth: true } },
      { path: 'business/purchase/statistics/amount', name: 'BusinessPurchaseStatsAmount', component: () => import('../views/business/purchase/statistics/Amount.vue'), meta: { title: '采购额分析', icon: 'el-icon-trend-charts', permission: 'business:purchase:statistics:view', requireAuth: true } },
      { path: 'business/purchase/statistics/supplier', name: 'BusinessPurchaseStatsSupplier', component: () => import('../views/business/purchase/statistics/Supplier.vue'), meta: { title: '供应商排行', icon: 'el-icon-medal', permission: 'business:purchase:statistics:view', requireAuth: true } },
      { path: 'business/receive/list', name: 'BusinessReceiveList', component: () => import('../views/business/receive/List.vue'), meta: { title: '接收单列表', icon: 'el-icon-box', permission: 'business:receive:list', requireAuth: true } },
      { path: 'business/receive/add', name: 'BusinessReceiveAdd', component: () => import('../views/business/receive/Add.vue'), meta: { title: '新增接收单', icon: 'el-icon-plus', permission: 'business:receive:add', hidden: true, requireAuth: true } },
      { path: 'business/receive/edit/:id', name: 'BusinessReceiveEdit', component: () => import('../views/business/receive/Add.vue'), meta: { title: '编辑接收单', icon: 'el-icon-edit', permission: 'business:receive:edit', hidden: true, requireAuth: true } },
      { path: 'business/receive/detail/:id', name: 'BusinessReceiveDetail', component: () => import('../views/business/receive/Detail.vue'), meta: { title: '接收单详情', icon: 'el-icon-view', permission: 'business:receive:list', hidden: true, requireAuth: true } },
      { path: 'business/receive/archive', name: 'BusinessReceiveArchive', component: () => import('../views/business/receive/Archive.vue'), meta: { title: '产品档案', icon: 'el-icon-collection', permission: 'business:receive:archive:view', requireAuth: true } },
      { path: 'business/receive/archive/detail/:id', name: 'BusinessReceiveArchiveDetail', component: () => import('../views/business/receive/ArchiveDetail.vue'), meta: { title: '产品档案详情', icon: 'el-icon-view', permission: 'business:receive:archive:view', hidden: true, requireAuth: true } },
      // 运输管理（产品接收）
      { path: 'business/receive/transport', name: 'BusinessReceiveTransport', component: () => import('../views/business/receive/Transport.vue'), meta: { title: '运输管理', icon: 'el-icon-truck', permission: 'business:receive:transport:view', requireAuth: true } },
      // ---- AI 智能平台 ----
      { path: 'ai/dashboard', name: 'AiDashboard', component: () => import('../views/ai/dashboard/index.vue'), meta: { title: '运营概览', icon: 'el-icon-s-data', permission: 'ai:dashboard', requireAuth: true } },
      // 系统状态监控（工作台 → 系统状态）
      { path: 'ai/status', name: 'AiStatus', component: () => import('../views/ai/status/index.vue'), meta: { title: '系统状态', icon: 'el-icon-monitor', permission: 'ai:status', requireAuth: true } },
      { path: 'ai/settings/model', name: 'AiModelConfig', component: () => import('../views/ai/settings/model.vue'), meta: { title: '模型配置', icon: 'el-icon-s-data', permission: 'ai:settings:model', requireAuth: true } },
      { path: 'ai/chat/create', name: 'AiChatCreate', component: () => import('../views/ai/chat/create.vue'), meta: { title: '新建对话', icon: 'el-icon-chat-dot-round', permission: 'ai:chat:create', requireAuth: true } },
      { path: 'ai/chat/history', name: 'AiChatHistory', component: () => import('../views/ai/chat/history.vue'), meta: { title: '对话历史', icon: 'el-icon-document-copy', permission: 'ai:chat:history', requireAuth: true } },
      { path: 'ai/chat/favorites', name: 'AiChatFavorites', component: () => import('../views/ai/chat/favorites.vue'), meta: { title: '收藏问答', icon: 'el-icon-star-on', permission: 'ai:chat:favorites', requireAuth: true } },
      { path: 'ai/tools/list', name: 'AiToolList', component: () => import('../views/ai/tools/list.vue'), meta: { title: '工具列表', icon: 'el-icon-s-tools', permission: 'ai:tools:list', requireAuth: true } },
      { path: 'ai/tools/category', name: 'AiToolCategory', component: () => import('../views/ai/tools/category.vue'), meta: { title: '工具分类', icon: 'el-icon-s-grid', permission: 'ai:tools:category', requireAuth: true } },
      { path: 'ai/tools/approval', name: 'AiToolApproval', component: () => import('../views/ai/tools/approval.vue'), meta: { title: '工具审批', icon: 'el-icon-document-checked', permission: 'ai:tools:approval', requireAuth: true } },
      { path: 'ai/tools/create', name: 'AiToolCreate', component: () => import('../views/ai/tools/create.vue'), meta: { title: '新增工具', icon: 'el-icon-plus', permission: 'ai:tools:add', hidden: true, requireAuth: true } },
      { path: 'ai/tools/test', name: 'AiToolTest', component: () => import('../views/ai/tools/test.vue'), meta: { title: '工具测试', icon: 'el-icon-s-promotion', permission: 'ai:tools:test', hidden: true, requireAuth: true } },
      { path: 'ai/tools/logs', name: 'AiToolLogs', component: () => import('../views/ai/tools/logs.vue'), meta: { title: '调用日志', icon: 'el-icon-document', permission: 'ai:tools:logs', requireAuth: true } },
      { path: 'ai/knowledge/list', name: 'AiKnowledgeList', component: () => import('../views/ai/knowledge/list.vue'), meta: { title: '知识库列表', icon: 'el-icon-collection', permission: 'ai:knowledge:list', requireAuth: true } },
      { path: 'ai/knowledge/datasource', name: 'AiDatasource', component: () => import('../views/ai/knowledge/datasource.vue'), meta: { title: '数据源管理', icon: 'el-icon-connection', permission: 'ai:knowledge:datasource', requireAuth: true } },
      { path: 'ai/knowledge/search-test', name: 'AiSearchTest', component: () => import('../views/ai/knowledge/search-test.vue'), meta: { title: '检索测试', icon: 'el-icon-search', permission: 'ai:knowledge:search-test', requireAuth: true } },
      { path: 'ai/knowledge/upload', name: 'AiKnowledgeUpload', component: () => import('../views/ai/knowledge/upload.vue'), meta: { title: '文档上传', icon: 'el-icon-upload', permission: 'ai:knowledge:upload', hidden: true, requireAuth: true } },
      { path: 'ai/agent/list', name: 'AiAgentList', component: () => import('../views/ai/agent/list.vue'), meta: { title: '智能体列表', icon: 'el-icon-user', permission: 'ai:agent:list', requireAuth: true } },
      { path: 'ai/agent/evaluate', name: 'AiAgentEvaluate', component: () => import('../views/ai/agent/evaluate.vue'), meta: { title: '智能体评测', icon: 'el-icon-s-marketing', permission: 'ai:agent:evaluate', requireAuth: true, hidden: true } },
      { path: 'ai/agent/publish', name: 'AiAgentPublish', component: () => import('../views/ai/agent/publish.vue'), meta: { title: '智能体发布', icon: 'el-icon-s-promotion', permission: 'ai:agent:publish', requireAuth: true, hidden: true } },
      // ---- AI 工作流编排 ----
      { path: 'ai/workflow/list', name: 'AiWorkflowList', component: () => import('../views/ai/workflow/list.vue'), meta: { title: '工作流列表', icon: 'el-icon-s-operation', permission: 'ai:workflow:list', requireAuth: true } },
      // 创建工作流页（可视化编排）
      { path: 'ai/workflow/create', name: 'AiWorkflowCreate', component: () => import('../views/ai/workflow/create.vue'), meta: { title: '创建工作流', icon: 'el-icon-plus', permission: 'ai:workflow:add', hidden: true, requireAuth: true } },
      // 运行日志页
      { path: 'ai/workflow/logs', name: 'AiWorkflowLogs', component: () => import('../views/ai/workflow/logs.vue'), meta: { title: '运行日志', icon: 'el-icon-document', permission: 'ai:workflow:logs', hidden: true, requireAuth: true } },
      // ---- AI 应用中心 ----
      { path: 'ai/app/list', name: 'AiAppList', component: () => import('../views/ai/app/list.vue'), meta: { title: '应用列表', icon: 'el-icon-apps', permission: 'ai:app:list', requireAuth: true } },
      // 创建应用页
      { path: 'ai/app/create', name: 'AiAppCreate', component: () => import('../views/ai/app/create.vue'), meta: { title: '创建应用', icon: 'el-icon-plus', permission: 'ai:app:add', hidden: true, requireAuth: true } },
      // API密钥管理页
      { path: 'ai/app/apikey', name: 'AiApiKeyList', component: () => import('../views/ai/app/apikey.vue'), meta: { title: 'API密钥管理', icon: 'el-icon-key', permission: 'ai:app:apikey', requireAuth: true } },
      // ---- AI 运营中心 ----
      { path: 'ai/operation/usage', name: 'AiUsageStats', component: () => import('../views/ai/operation/usage.vue'), meta: { title: '用量统计', icon: 'el-icon-data-line', permission: 'ai:operation:usage', requireAuth: true } },
      { path: 'ai/operation/audit', name: 'AiOperationAudit', component: () => import('../views/ai/operation/audit.vue'), meta: { title: '操作审计', icon: 'el-icon-document-checked', permission: 'ai:operation:audit', requireAuth: true } },
      { path: 'ai/operation/monitor', name: 'AiOperationMonitor', component: () => import('../views/ai/operation/monitor.vue'), meta: { title: '监控告警', icon: 'el-icon-bell', permission: 'ai:operation:monitor', requireAuth: true } },
      // ---- AI 智能报告（v1.65.0） ----
      { path: 'ai/reports/generate', name: 'AiReportGenerate', component: () => import('../views/ai/reports/generate.vue'), meta: { title: '报告生成', icon: 'el-icon-document-add', permission: 'ai:reports:generate', requireAuth: true } },
      { path: 'ai/reports/list', name: 'AiReportList', component: () => import('../views/ai/reports/list.vue'), meta: { title: '报告列表', icon: 'el-icon-document', permission: 'ai:reports:view', requireAuth: true } },
      // ---- AI 销售预测（v1.65.0） ----
      { path: 'ai/forecast/sales', name: 'AiForecastSales', component: () => import('../views/ai/forecast/sales.vue'), meta: { title: '预测看板', icon: 'el-icon-data-line', permission: 'ai:forecast:view', requireAuth: true } },
      // ---- AI 客户智能（v1.66.0） ----
      { path: 'ai/customer/value', name: 'AiCustomerValue', component: () => import('../views/ai/customer/value.vue'), meta: { title: '客户价值分析', icon: 'el-icon-user', permission: 'ai:customer:value:view', requireAuth: true } },
      { path: 'ai/customer/churn', name: 'AiCustomerChurn', component: () => import('../views/ai/customer/churn.vue'), meta: { title: '流失预警', icon: 'el-icon-warning', permission: 'ai:customer:churn:view', requireAuth: true } },
      // ---- AI 业务智能体（v1.67.0） ----
      { path: 'ai/agents/dashboard', name: 'AiAgentDashboard', component: () => import('../views/ai/agents/dashboard.vue'), meta: { title: '智能体总览', icon: 'el-icon-cpu', permission: 'ai:agent:view', requireAuth: true } },
      { path: 'ai/agents/approval', name: 'AiAgentApproval', component: () => import('../views/ai/agents/approval.vue'), meta: { title: '审批助手', icon: 'el-icon-document-checked', permission: 'ai:agent:approval', requireAuth: true } },
      { path: 'ai/agents/churn', name: 'AiAgentChurn', component: () => import('../views/ai/agents/churn.vue'), meta: { title: '催办智能体', icon: 'el-icon-alarm-clock', permission: 'ai:agent:churn', requireAuth: true } },
      { path: 'ai/agents/order', name: 'AiAgentOrder', component: () => import('../views/ai/agents/order.vue'), meta: { title: '订单处理智能体', icon: 'el-icon-box', permission: 'ai:agent:order', requireAuth: true } },
      // ---- AI 自然语言交互（v1.68.0） ----
      { path: 'ai/voice/commands', name: 'AiVoiceCommands', component: () => import('../views/ai/voice/commands.vue'), meta: { title: '快捷指令中心', icon: 'el-icon-mic', permission: 'ai:voice:view', requireAuth: true } },
      { path: 'ai/voice/templates', name: 'AiVoiceTemplates', component: () => import('../views/ai/voice/templates.vue'), meta: { title: '指令模板管理', icon: 'el-icon-document', permission: 'ai:voice:admin', requireAuth: true } },
      { path: 'ai/voice/history', name: 'AiVoiceHistory', component: () => import('../views/ai/voice/history.vue'), meta: { title: '执行历史', icon: 'el-icon-time', permission: 'ai:voice:view', requireAuth: true } },
    ]
  }
]

const router = new Router({ routes, mode: 'hash', base: '/admin/' })

// 权限刷新标记：守卫权限不足时仅自动重新拉取一次（避免死循环）
let permRefreshed = false

router.beforeEach(async (to, from, next) => {
  const pageTitle = to.meta.title || '加载中...'
  window.__pageTitle = pageTitle
  document.title = pageTitle
  if (to.meta.noAuth) { next(); return }
  const token = getToken()
  // 待绑定会话：强制未绑定用户经登录页 step 进入"我的手机密钥"绑定页，允许未登录访问
  const isBindStep = to.name === 'MyKeys' && to.query && to.query.step
  if (!token && !isBindStep) { next({ path: '/login' }); return }
  try {
    if (!store.state.user.userInfo) {
      const userInfo = await store.dispatch('user/getUserInfo')
      if (!userInfo) { next({ path: '/login' }); return }
    }
    // 确保权限已加载完成后再渲染页面（v-permission / hasPerm 依赖 permissions）
    if (!store.state.user.permissions || !store.state.user.permissions.length) {
      await store.dispatch('user/loadPermissions')
    }
    // 校验路由级权限（meta.permission）：无权限则跳转控制台
    // 超级管理员（users.is_super_admin 字段 或 super_admin 角色）直接放行，与后端 checkPerm 一致
    const userInfo = store.state.user.userInfo || {}
    const perms = store.state.user.permissions || []
    const isSuperAdmin = !!userInfo.is_super_admin || perms.indexOf('super_admin') > -1
    const required = to.meta.permission
    if (required && !isSuperAdmin && !perms.includes(required)) {
      // 权限可能因后端权限变更/缓存清理而未同步到本会话：自动重新拉取一次后重试
      if (!permRefreshed) {
        permRefreshed = true
        await store.dispatch('user/loadPermissions')
        const perms2 = store.state.user.permissions || []
        if (perms2.includes(required)) { next(); return }
      }
      next({ path: '/dashboard' })
      return
    }
  } catch (e) { next({ path: '/login' }); return }
  next()
})

// 路由切换后更新 AI 页面上下文（v1.63.0 上下文感知）
router.afterEach((to) => {
  store.dispatch('ai/updatePageContext', { route: to.path })
})

export default router
