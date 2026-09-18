-- 166_create_dashboard.sql
-- 生产看板（生产管理 -> 生产看板）：1 权限 + 菜单（无表变更）
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='production:dashboard:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code='production:dashboard:view');
--   DELETE FROM permissions WHERE code='production:dashboard:view';

-- ========== 一、权限（1 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('生产看板','production:dashboard:view',2,0,'production','/production/dashboard','el-icon-monitor',NULL,260,1,1,'生产看板-查看（菜单）',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` = 'production:dashboard:view';

-- ========== 二、菜单：生产管理 -> 生产看板（叶子） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='production:view' AND deleted_at IS NULL LIMIT 1), '生产看板', '/production/dashboard', 'el-icon-monitor', 'production:dashboard:view', 40, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='production:dashboard:view' AND deleted_at IS NULL);
