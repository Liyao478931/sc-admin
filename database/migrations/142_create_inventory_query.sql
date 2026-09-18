-- 142_create_inventory_query.sql
-- 库存查询（仓储管理 -> 库存管理 -> 库存查询）：2 权限 + 菜单（无数据表变更）
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission IN ('warehouse:inventory:query:view','warehouse:inventory');
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'warehouse:inventory:query:%');
--   DELETE FROM permissions WHERE code LIKE 'warehouse:inventory:query:%';

-- ========== 一、权限（2 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('库存查询','warehouse:inventory:query:view',2,0,'warehouse','/warehouse/inventory/query','el-icon-search',NULL,76,1,1,'库存查询-查看（菜单）',NOW(),NOW()),
('库存查询导出','warehouse:inventory:query:export',2,0,'warehouse',NULL,NULL,NULL,77,1,1,'导出库存数据',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code` LIKE 'warehouse:inventory:query:%';

-- ========== 二、菜单：仓储管理 -> 库存管理（目录）-> 库存查询（内联子查询定位父级，避免跨语句变量） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='warehouse:module' AND deleted_at IS NULL AND parent_id=0 LIMIT 1), '库存管理', '', 'el-icon-data-line', 'warehouse:inventory', 30, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:inventory' AND deleted_at IS NULL);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='warehouse:inventory' AND deleted_at IS NULL LIMIT 1), '库存查询', '/warehouse/inventory/query', 'el-icon-search', 'warehouse:inventory:query:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:inventory:query:view' AND deleted_at IS NULL);
