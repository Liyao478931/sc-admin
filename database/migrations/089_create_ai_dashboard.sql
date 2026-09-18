-- =====================================================
-- 089_create_ai_dashboard.sql
-- AI 智能平台：工作台 → 运营概览
--   1. 权限（ai:dashboard）
--   2. 菜单（AI智能平台 → 工作台 → 运营概览）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、权限 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('运营概览','ai:dashboard',1,0,'ai','/ai/dashboard','el-icon-s-data',NULL,1,1,1,'AI平台运营概览（工作台首页）',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('ai:dashboard');

-- ========== 二、菜单（AI智能平台 → 工作台 → 运营概览） ==========
SET @ai_platform_id = (SELECT id FROM menus WHERE permission='ai:platform:view' AND deleted_at IS NULL LIMIT 1);
-- 工作台目录（预留，已存在则跳过）
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @ai_platform_id, '工作台', '', 'el-icon-s-data', 'ai:dashboard', 1, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:dashboard' AND deleted_at IS NULL AND parent_id=@ai_platform_id AND type=1);

-- 运营概览子菜单
SET @ai_workbench_id = (SELECT id FROM menus WHERE parent_id=@ai_platform_id AND name='工作台' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @ai_workbench_id, '运营概览', '/ai/dashboard', 'el-icon-s-data', 'ai:dashboard', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:dashboard' AND deleted_at IS NULL AND type=2);
