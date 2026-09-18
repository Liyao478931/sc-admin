-- 162_create_progress.sql
-- 生产进度（生产管理 -> 生产执行 -> 生产进度）：2 权限 + 菜单（无表变更）
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='production:progress:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code IN ('production:progress:view','production:progress:export'));
--   DELETE FROM permissions WHERE code IN ('production:progress:view','production:progress:export');

-- ========== 一、权限（2 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('生产进度','production:progress:view',2,0,'production','/production/execute/progress','el-icon-data-line',NULL,237,1,1,'生产进度-查看（菜单）',NOW(),NOW()),
('导出进度报表','production:progress:export',2,0,'production',NULL,NULL,NULL,238,1,1,'导出生产进度报表',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` IN ('production:progress:view','production:progress:export');

-- ========== 二、菜单：生产执行 -> 生产进度（叶子） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='production:execute' AND deleted_at IS NULL LIMIT 1), '生产进度', '/production/execute/progress', 'el-icon-data-line', 'production:progress:view', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='production:progress:view' AND deleted_at IS NULL);
