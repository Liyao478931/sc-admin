-- 169_create_my_initiated.sql
-- 统一审批管理「我发起的」：1 权限 + 1 菜单（无表变更）
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE path='/approval/my-initiated';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code='approval:task:revoke');
--   DELETE FROM permissions WHERE code='approval:task:revoke';

-- ========== 一、权限（approval:task:revoke） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('撤销申请','approval:task:revoke',2,0,'approval',NULL,NULL,NULL,306,1,1,'撤销审批申请（我发起的）',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`sort`=VALUES(`sort`),`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code`='approval:task:revoke';

-- ========== 二、菜单：统一审批 -> 我发起的（叶子，path 幂等） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='approval:view' AND deleted_at IS NULL LIMIT 1), '我发起的', '/approval/my-initiated', 'el-icon-s-promotion', 'approval:task:view', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/approval/my-initiated' AND deleted_at IS NULL);
