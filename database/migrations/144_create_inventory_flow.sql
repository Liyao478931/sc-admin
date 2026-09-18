-- 144_create_inventory_flow.sql
-- 库存流水（仓储管理 -> 库存管理 -> 库存流水）：2 权限 + 菜单（无数据表变更，基于 warehouse_stock_flow）
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='warehouse:inventory:flow:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'warehouse:inventory:flow:%');
--   DELETE FROM permissions WHERE code LIKE 'warehouse:inventory:flow:%';

-- ========== 一、权限（2 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('库存流水','warehouse:inventory:flow:view',2,0,'warehouse','/warehouse/inventory/flow','el-icon-s-order',NULL,78,1,1,'库存流水-查看（菜单）',NOW(),NOW()),
('库存流水导出','warehouse:inventory:flow:export',2,0,'warehouse',NULL,NULL,NULL,79,1,1,'导出库存流水',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code` LIKE 'warehouse:inventory:flow:%';

-- ========== 二、菜单：库存管理（warehouse:inventory）-> 库存流水 ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='warehouse:inventory' AND deleted_at IS NULL LIMIT 1), '库存流水', '/warehouse/inventory/flow', 'el-icon-s-order', 'warehouse:inventory:flow:view', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:inventory:flow:view' AND deleted_at IS NULL);
