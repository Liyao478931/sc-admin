-- =====================================================
-- 090_create_ai_system_status.sql
-- AI 智能平台：工作台 → 系统状态
--   1. 权限（ai:status）
--   2. 菜单（AI智能平台 → 工作台 → 系统状态）
--   3. super_admin 授权
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、权限 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('系统状态','ai:status',1,0,'ai','/ai/status','el-icon-monitor',NULL,2,1,1,'AI平台系统状态监控（工作台）',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('ai:status');

-- ========== 二、菜单（AI智能平台 → 工作台 → 系统状态） ==========
SET @ai_platform_id = (SELECT id FROM menus WHERE permission='ai:platform:view' AND deleted_at IS NULL LIMIT 1);

-- 工作台目录（089 已创建，兜底创建）
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @ai_platform_id, '工作台', '', 'el-icon-s-data', 'ai:dashboard', 1, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:dashboard' AND deleted_at IS NULL AND parent_id=@ai_platform_id AND type=1);

-- 系统状态子菜单（挂在工作台下）
SET @ai_workbench_id = (SELECT id FROM menus WHERE parent_id=@ai_platform_id AND name='工作台' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @ai_workbench_id, '系统状态', '/ai/status', 'el-icon-monitor', 'ai:status', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:status' AND deleted_at IS NULL AND type=2);

-- ========== 三、角色授权（按需，可选） ==========
-- 若需将「系统状态」授权给其他角色，可在此追加，例如：
-- INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
-- SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
-- WHERE r.`code`='admin' AND p.`code`='ai:status';
