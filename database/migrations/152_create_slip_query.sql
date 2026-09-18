-- 152_create_slip_query.sql
-- 工资条查询（人事管理 -> 薪酬管理 -> 工资条 -> 工资条查询）：3 权限 + 菜单（无表变更）
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='hr:salary:slip:list:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code IN ('hr:salary:slip:list:view','hr:salary:slip:export','hr:salary:slip:resend'));
--   DELETE FROM permissions WHERE code IN ('hr:salary:slip:list:view','hr:salary:slip:export','hr:salary:slip:resend');

-- ========== 一、权限（3 个，hr:salary:slip:view 已存在复用） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('工资条查询','hr:salary:slip:list:view',2,0,'hr','/hr/salary/slip/list','el-icon-search',NULL,199,1,1,'工资条查询-查看（菜单）',NOW(),NOW()),
('工资条导出','hr:salary:slip:export',2,0,'hr',NULL,NULL,NULL,200,1,1,'导出工资条列表',NOW(),NOW()),
('工资条补发通知','hr:salary:slip:resend',2,0,'hr',NULL,NULL,NULL,201,1,1,'补发工资条通知',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` IN ('hr:salary:slip:list:view','hr:salary:slip:export','hr:salary:slip:resend');

-- ========== 二、菜单：工资条目录 -> 工资条查询（叶子） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='hr:salary:slip' AND deleted_at IS NULL LIMIT 1), '工资条查询', '/hr/salary/slip/list', 'el-icon-search', 'hr:salary:slip:list:view', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='hr:salary:slip:list:view' AND deleted_at IS NULL);
