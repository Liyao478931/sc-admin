-- 147_create_hr_attendance_statistics.sql
-- 考勤统计（人事管理 -> 考勤管理 -> 考勤统计）：3 权限 + 菜单（无新增表）
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='hr:attendance:statistics:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'hr:attendance:statistics:%');
--   DELETE FROM permissions WHERE code LIKE 'hr:attendance:statistics:%';

-- ========== 一、权限（3 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('考勤统计','hr:attendance:statistics:view',2,0,'hr','/hr/attendance/statistics','el-icon-data-analysis',NULL,178,1,1,'考勤统计-查看（菜单）',NOW(),NOW()),
('考勤统计导出','hr:attendance:statistics:export',2,0,'hr',NULL,NULL,NULL,179,1,1,'导出考勤统计报表',NOW(),NOW()),
('考勤批量标记','hr:attendance:statistics:batch',2,0,'hr',NULL,NULL,NULL,180,1,1,'批量标记异常考勤',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin','employee') AND p.`code` LIKE 'hr:attendance:statistics:%';

-- ========== 二、菜单：考勤管理（人事管理 id=21 下）-> 考勤统计 ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE name='考勤管理' AND parent_id=21 AND deleted_at IS NULL LIMIT 1), '考勤统计', '/hr/attendance/statistics', 'el-icon-data-analysis', 'hr:attendance:statistics:view', 6, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='hr:attendance:statistics:view' AND deleted_at IS NULL);
