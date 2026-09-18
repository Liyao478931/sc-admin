-- 999_add_license_permission.sql
-- 授权管理菜单权限（license:view）：补 permissions + 授权超级管理员/管理员
-- 幂等：已存在则跳过
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '授权管理','license:view',1,0,'系统维护','/license',NULL,'/api/system/license/*',0,1,1,'授权管理',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='license:view');

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code`='license:view';
