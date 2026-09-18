-- 179_create_execute.sql
-- 仓储管理「库存盘点 - 盘点执行」：3 权限 + 1 菜单（无表变更，复用 inventory_task/inventory_result）
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE path='/warehouse/check/execute';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'warehouse:check:execute:%');
--   DELETE FROM permissions WHERE code LIKE 'warehouse:check:execute:%';

-- ========== 一、权限（3 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('盘点执行','warehouse:check:execute:view',2,0,'warehouse','/warehouse/check/execute','el-icon-s-operation',NULL,57,1,1,'盘点执行-查看（菜单）',NOW(),NOW()),
('执行盘点','warehouse:check:execute:execute',2,0,'warehouse',NULL,NULL,NULL,58,1,1,'执行盘点（开始/录入数据）',NOW(),NOW()),
('提交盘点','warehouse:check:execute:submit',2,0,'warehouse',NULL,NULL,NULL,59,1,1,'提交盘点任务',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'warehouse:check:execute:%';

-- ========== 二、菜单（库存盘点 -> 盘点执行，path 幂等） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='warehouse:check:plan:module' AND deleted_at IS NULL LIMIT 1), '盘点执行', '/warehouse/check/execute', 'el-icon-s-operation', 'warehouse:check:execute:view', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/warehouse/check/execute' AND deleted_at IS NULL);
