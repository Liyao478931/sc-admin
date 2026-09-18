-- 167_fix_dashboard_menu.sql
-- 经营总览菜单规范化：新增「经营看板」目录（经营看板->经营总览），经营总览改为叶子(type=2)
-- 幂等写法，可重复执行
-- 回滚 down：
--   UPDATE menus SET parent_id=(SELECT id FROM menus WHERE permission='business:view' AND deleted_at IS NULL LIMIT 1), type=1, sort=0 WHERE permission='business:dashboard:view' AND deleted_at IS NULL;
--   DELETE FROM menus WHERE permission='business:dashboard';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code='business:dashboard');
--   DELETE FROM permissions WHERE code='business:dashboard';

-- ========== 一、经营看板目录权限（type=1 目录） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('经营看板','business:dashboard',1,0,'business',NULL,'el-icon-data-board',NULL,261,1,1,'经营看板-目录',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code`='business:dashboard';

-- ========== 二、经营看板目录菜单（挂在经营管理下） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='business:view' AND deleted_at IS NULL LIMIT 1), '经营看板', '', 'el-icon-data-board', 'business:dashboard', 90, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:dashboard' AND deleted_at IS NULL);

-- ========== 三、经营总览移到经营看板下并改为叶子(type=2) ==========
UPDATE `menus` SET
  `parent_id` = (SELECT id FROM (SELECT id FROM menus WHERE permission='business:dashboard' AND deleted_at IS NULL LIMIT 1) t),
  `type` = 2,
  `sort` = 10
WHERE `permission`='business:dashboard:view' AND `deleted_at` IS NULL;
