-- 157_create_report_audit.sql
-- 报工审核（生产管理 -> 生产执行 -> 报工审核）：1 权限 + 菜单（无表变更）
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='production:report:audit:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code='production:report:audit:view');
--   DELETE FROM permissions WHERE code='production:report:audit:view';

-- ========== 一、权限（audit 已存在，仅新增 audit:view） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('报工审核','production:report:audit:view',2,0,'production','/production/report/audit','el-icon-document-checked',NULL,226,1,1,'报工审核-查看（菜单）',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code`='production:report:audit:view';

-- ========== 二、菜单：生产执行 -> 报工审核（叶子） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='production:execute' AND deleted_at IS NULL LIMIT 1), '报工审核', '/production/report/audit', 'el-icon-document-checked', 'production:report:audit:view', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='production:report:audit:view' AND deleted_at IS NULL);
