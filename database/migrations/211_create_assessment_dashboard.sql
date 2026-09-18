-- 211_create_assessment_dashboard.sql
-- 考核看板（人事管理 -> 绩效考核 -> 考核看板）
-- 仅新增权限 + 菜单，不新增业务表
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='assessment:dashboard:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'assessment:dashboard:%');
--   DELETE FROM permissions WHERE code LIKE 'assessment:dashboard:%';

-- ========== 权限（4 个，幂等） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '考核看板','assessment:dashboard:view',2,0,'hr','/hr/assessment/dashboard','el-icon-data-analysis',NULL,320,1,1,'考核看板-查看（菜单）',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:dashboard:view');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '考核看板-查看全部部门','assessment:dashboard:view_all',2,0,'hr',NULL,NULL,NULL,321,1,1,'考核看板-查看全部部门数据',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:dashboard:view_all');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '考核看板-查看本部门','assessment:dashboard:view_dept',2,0,'hr',NULL,NULL,NULL,322,1,1,'考核看板-仅查看本部门数据',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:dashboard:view_dept');
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`)
SELECT '考核看板-穿透明细','assessment:dashboard:drill_down',2,0,'hr',NULL,NULL,NULL,323,1,1,'考核看板-穿透查看明细',NOW(),NOW()
WHERE NOT EXISTS (SELECT 1 FROM `permissions` WHERE `code`='assessment:dashboard:drill_down');

-- 角色关联：super_admin/admin 全部；production_manager 给查看/本部门/穿透
INSERT INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'assessment:dashboard:%'
AND NOT EXISTS (SELECT 1 FROM `role_permissions` rp WHERE rp.role_id=r.`id` AND rp.permission_id=p.`id`);

INSERT INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('production_manager') AND p.`code` IN ('assessment:dashboard:view','assessment:dashboard:view_dept','assessment:dashboard:drill_down')
AND NOT EXISTS (SELECT 1 FROM `role_permissions` rp WHERE rp.role_id=r.`id` AND rp.permission_id=p.`id`);

-- ========== 菜单链：绩效考核目录 -> 考核看板（叶子） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='hr:assessment' AND deleted_at IS NULL LIMIT 1), '考核看板', '/hr/assessment/dashboard', 'el-icon-data-analysis', 'assessment:dashboard:view', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='assessment:dashboard:view' AND deleted_at IS NULL);
