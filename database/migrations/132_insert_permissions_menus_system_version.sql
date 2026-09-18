-- 132_insert_permissions_menus_system_version.sql
-- 系统维护 -> 版本管理：权限 + 菜单 + 角色授权 + 版本检测配置种子
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission IN ('settings:version:view','settings:version:rollback','settings:version:statistics:view');
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'settings:version:%');
--   DELETE FROM permissions WHERE code LIKE 'settings:version:%';
--   DELETE FROM system_version_config WHERE config_key IN ('version_update_enabled','version_update_poll_interval','version_update_auto');

-- ========== 一、权限定义（已存在则更新） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('版本管理查看','settings:version:view',2,0,'version','/settings/version/list','el-icon-collection',NULL,10,1,1,'版本管理-查看（菜单）',NOW(),NOW()),
('版本管理新增','settings:version:add',2,0,'version',NULL,NULL,NULL,11,1,1,'新建版本',NOW(),NOW()),
('版本管理编辑','settings:version:edit',2,0,'version',NULL,NULL,NULL,12,1,1,'编辑版本（草稿）',NOW(),NOW()),
('版本管理删除','settings:version:delete',2,0,'version',NULL,NULL,NULL,13,1,1,'删除版本（草稿）',NOW(),NOW()),
('版本发布','settings:version:release',2,0,'version',NULL,NULL,NULL,14,1,1,'发布版本',NOW(),NOW()),
('设为当前版本','settings:version:set-current',2,0,'version',NULL,NULL,NULL,15,1,1,'设为当前版本',NOW(),NOW()),
('版本回滚','settings:version:rollback',2,0,'version','/settings/version/rollback','el-icon-refresh-left',NULL,20,1,1,'版本回滚（菜单）',NOW(),NOW()),
('版本统计查看','settings:version:statistics:view',2,0,'version','/settings/version/statistics','el-icon-data-analysis',NULL,30,1,1,'版本统计看板-查看（菜单）',NOW(),NOW()),
('版本审批','settings:version:approve',2,0,'version',NULL,NULL,NULL,40,1,1,'版本发布审批',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

-- ========== 二、授权 super_admin ==========
INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` LIKE 'settings:version:%';

-- ========== 三、菜单（系统维护 -> 版本管理） ==========
-- 3.1 系统维护目录（已存在则跳过）
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 0, '系统维护', '', 'el-icon-s-operation', 'maintenance:view', 50, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='maintenance:view' AND deleted_at IS NULL AND parent_id=0);

SET @maint_menu_id = (SELECT id FROM menus WHERE permission='maintenance:view' AND deleted_at IS NULL AND parent_id=0 LIMIT 1);

-- 3.2 版本管理（列表）
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @maint_menu_id, '版本管理', '/settings/version/list', 'el-icon-collection', 'settings:version:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='settings:version:view' AND deleted_at IS NULL AND parent_id=@maint_menu_id);

-- 3.3 版本回滚
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @maint_menu_id, '版本回滚', '/settings/version/rollback', 'el-icon-refresh-left', 'settings:version:rollback', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='settings:version:rollback' AND deleted_at IS NULL AND parent_id=@maint_menu_id);

-- 3.4 版本统计
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @maint_menu_id, '版本统计', '/settings/version/statistics', 'el-icon-data-analysis', 'settings:version:statistics:view', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='settings:version:statistics:view' AND deleted_at IS NULL AND parent_id=@maint_menu_id);

-- ========== 四、版本检测配置种子 ==========
INSERT INTO `system_version_config` (`config_key`,`config_value`,`group_name`,`description`,`status`,`create_time`,`update_time`) VALUES
('version_update_enabled','1','version','是否启用版本检测：1启用 0停用',1,NOW(),NOW()),
('version_update_poll_interval','5','version','版本检测轮询间隔（分钟）：5/15/30/60',1,NOW(),NOW()),
('version_update_auto','0','version','自动更新模式：1开启（检测到新版本自动刷新） 0关闭',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE
`config_value`=VALUES(`config_value`),`group_name`=VALUES(`group_name`),
`description`=VALUES(`description`),`status`=VALUES(`status`),`update_time`=NOW();
