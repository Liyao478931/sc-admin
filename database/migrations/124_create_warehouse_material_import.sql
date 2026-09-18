-- 124_create_warehouse_material_import.sql
-- 物料管理：新增"导入物料"权限并授权 super_admin
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code='warehouse:setting:material:import');
--   DELETE FROM permissions WHERE code='warehouse:setting:material:import';

INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('物料导入','warehouse:setting:material:import',2,0,'warehouse',NULL,NULL,NULL,24,1,1,'导入物料（批量创建/更新）',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`sort`=VALUES(`sort`),`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code`='warehouse:setting:material:import';
