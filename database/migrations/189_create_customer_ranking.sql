-- 189_create_customer_ranking.sql
-- 经营管理「客户排行」：2 权限 + 1 菜单（无新增表，基于 business_orders + business_customers 统计）
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='sales:statistics:customer:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'sales:statistics:customer:%');
--   DELETE FROM permissions WHERE code LIKE 'sales:statistics:customer:%';

-- ========== 一、权限（2 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('客户排行','sales:statistics:customer:view',2,0,'business','/business/sales/statistics/customer','el-icon-rank',NULL,300,1,1,'客户排行-查看（菜单）',NOW(),NOW()),
('导出客户排行','sales:statistics:customer:export',2,0,'business',NULL,NULL,NULL,301,1,1,'导出客户排行数据',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'sales:statistics:customer:%';

-- ========== 二、菜单：销售管理（id=258）-> 客户排行（叶子） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 258, '客户排行', '/business/sales/statistics/customer', 'el-icon-rank', 'sales:statistics:customer:view', 50, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/business/sales/statistics/customer' AND deleted_at IS NULL);
