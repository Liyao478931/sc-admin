-- 173_create_statistics.sql
-- 统一审批「审批统计」：2 权限 + 菜单（无表变更）
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE path='/approval/statistics';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'approval:statistics:%');
--   DELETE FROM permissions WHERE code LIKE 'approval:statistics:%';

-- ========== 一、权限（view + export） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('审批统计','approval:statistics:view',2,0,'approval','/approval/statistics','el-icon-data-analysis',NULL,310,1,1,'审批统计-查看（菜单）',NOW(),NOW()),
('导出审批统计','approval:statistics:export',2,0,'approval',NULL,NULL,NULL,311,1,1,'导出审批统计报表',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'approval:statistics:%';

-- ========== 二、菜单：统一审批 -> 审批统计（叶子，path 幂等） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='approval:view' AND deleted_at IS NULL LIMIT 1), '审批统计', '/approval/statistics', 'el-icon-data-analysis', 'approval:statistics:view', 60, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/approval/statistics' AND deleted_at IS NULL);
