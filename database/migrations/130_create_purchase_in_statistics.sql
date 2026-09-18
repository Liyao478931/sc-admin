-- 130_create_purchase_in_statistics.sql
-- 入库统计看板：权限 + 菜单（配件出入库 -> 入库统计）
-- 回滚 down：
--   DELETE FROM menus WHERE permission='warehouse:purchase:in:statistics:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code='warehouse:purchase:in:statistics:view');
--   DELETE FROM permissions WHERE code='warehouse:purchase:in:statistics:view';

INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('入库统计查看','warehouse:purchase:in:statistics:view',2,0,'warehouse','/warehouse/purchase/in/statistics','el-icon-data-analysis',NULL,44,1,1,'入库统计看板-查看（菜单）',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code`='warehouse:purchase:in:statistics:view';

-- 菜单：配件出入库 -> 入库统计
SET @parts_menu_id = (SELECT id FROM menus WHERE permission='warehouse:parts' AND deleted_at IS NULL LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @parts_menu_id, '入库统计', '/warehouse/purchase/in/statistics', 'el-icon-data-analysis', 'warehouse:purchase:in:statistics:view', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='warehouse:purchase:in:statistics:view' AND deleted_at IS NULL AND parent_id=@parts_menu_id);
