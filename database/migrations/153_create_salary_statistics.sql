-- 153_create_salary_statistics.sql
-- 薪酬统计（人事管理 -> 薪酬管理 -> 薪酬统计）：2 权限 + 菜单（无表变更）
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='hr:salary:statistics:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code IN ('hr:salary:statistics:view','hr:salary:statistics:export'));
--   DELETE FROM permissions WHERE code IN ('hr:salary:statistics:view','hr:salary:statistics:export');

-- ========== 一、权限（2 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('薪酬统计','hr:salary:statistics:view',2,0,'hr','/hr/salary/statistics','el-icon-data-analysis',NULL,202,1,1,'薪酬统计-查看（菜单）',NOW(),NOW()),
('薪酬统计导出','hr:salary:statistics:export',2,0,'hr',NULL,NULL,NULL,203,1,1,'导出薪酬统计报表',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` IN ('hr:salary:statistics:view','hr:salary:statistics:export');

-- ========== 二、菜单：薪酬管理（hr:salary）-> 薪酬统计（叶子） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='hr:salary' AND deleted_at IS NULL AND parent_id=21 LIMIT 1), '薪酬统计', '/hr/salary/statistics', 'el-icon-data-analysis', 'hr:salary:statistics:view', 50, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='hr:salary:statistics:view' AND deleted_at IS NULL);
