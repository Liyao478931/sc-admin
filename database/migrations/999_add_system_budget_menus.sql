-- 999_add_system_budget_menus.sql
-- 补全客户安装缺失的菜单与权限：系统更新/健康检查/消息推送/预算管理/财务管理
-- 幂等：已存在则跳过

-- 1) 权限
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '系统更新','system:update:view',1,0,'系统维护','/system-update','el-icon-refresh','/api/system/update/*',0,1,1,'系统更新',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='system:update:view');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '健康检查','system:health:view',1,0,'系统维护','/health-check','el-icon-first-aid-kit','/api/system/health/*',0,1,1,'健康检查',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='system:health:view');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '消息推送','system:push:view',1,0,'系统维护','/mp-push','el-icon-chat-dot-round','/api/mp-push/*',0,1,1,'消息推送',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='system:push:view');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '预算管理','budget:view',1,0,'经营管理','/budget','el-icon-coin','/api/budget/*',0,1,1,'预算管理',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='budget:view');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '财务管理','finance:view',1,0,'经营管理','/finance','el-icon-money','/api/finance/*',0,1,1,'财务管理',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='finance:view');

-- 2) 菜单（挂系统维护 id=3 / 经营管理 id=136）
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 3,'系统更新','/system-update','el-icon-refresh','system:update:view',20,1,2,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `menus` WHERE `permission`='system:update:view' AND `deleted_at` IS NULL);
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 3,'健康检查','/health-check','el-icon-first-aid-kit','system:health:view',30,1,2,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `menus` WHERE `permission`='system:health:view' AND `deleted_at` IS NULL);
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 3,'消息推送','/mp-push','el-icon-chat-dot-round','system:push:view',40,1,2,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `menus` WHERE `permission`='system:push:view' AND `deleted_at` IS NULL);
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 136,'预算管理','/budget','el-icon-coin','budget:view',99,1,2,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `menus` WHERE `permission`='budget:view' AND `deleted_at` IS NULL);
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 136,'财务管理','/finance','el-icon-money','finance:view',100,1,2,0,NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `menus` WHERE `permission`='finance:view' AND `deleted_at` IS NULL);

-- 3) 角色授权（超级管理员/管理员）
INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin')
  AND p.`code` IN ('system:update:view','system:health:view','system:push:view','budget:view','finance:view');
