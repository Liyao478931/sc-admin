-- 133_menu_version_directory.sql
-- 菜单结构调整：新增"版本管理"目录（系统维护下），版本列表/回滚/统计统一挂入
-- 回滚 down：
--   UPDATE menus SET parent_id=3 WHERE permission IN ('settings:version:view','settings:version:rollback','settings:version:statistics:view') AND deleted_at IS NULL;
--   DELETE FROM menus WHERE permission='settings:version' AND deleted_at IS NULL;
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code='settings:version');
--   DELETE FROM permissions WHERE code='settings:version';

-- ========== 一、目录权限（settings:version，type=1 目录） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('版本管理','settings:version',1,0,'version','','el-icon-collection',NULL,9,1,1,'版本管理（目录）',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code`='settings:version';

-- ========== 二、版本管理目录菜单（父=系统维护，已存在则跳过） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 3, '版本管理', '', 'el-icon-collection', 'settings:version', 9, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='settings:version' AND deleted_at IS NULL AND parent_id=3);

SET @version_dir_id = (SELECT id FROM menus WHERE permission='settings:version' AND deleted_at IS NULL LIMIT 1);

-- ========== 三、版本列表/回滚/统计 挂入版本管理目录 ==========
UPDATE `menus` SET `parent_id` = @version_dir_id
WHERE `permission` IN ('settings:version:view','settings:version:rollback','settings:version:statistics:view')
  AND `deleted_at` IS NULL;
