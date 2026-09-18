-- 191_fix_business_permissions.sql
-- 经营管理权限补齐：菜单 176/177/136 引用的权限码缺失，补 permissions + 角色绑定
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code IN ('business:view','business:purchase:statistics:amount','business:purchase:statistics:supplier'));
--   DELETE FROM permissions WHERE code IN ('business:view','business:purchase:statistics:amount','business:purchase:statistics:supplier');

INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('经营管理','business:view',1,0,'business',NULL,'el-icon-suitcase',NULL,10,1,1,'经营管理（根目录）',NOW(),NOW()),
('采购额分析','business:purchase:statistics:amount',2,0,'business',NULL,NULL,NULL,420,1,1,'采购额分析',NOW(),NOW()),
('供应商排行','business:purchase:statistics:supplier',2,0,'business',NULL,NULL,NULL,421,1,1,'供应商排行',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`sort`=VALUES(`sort`),`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` IN ('business:view','business:purchase:statistics:amount','business:purchase:statistics:supplier');
