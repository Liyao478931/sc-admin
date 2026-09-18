-- 190_create_product_ranking.sql
-- 经营管理「产品排行」：2 权限 + 1 菜单（无新增表，基于 business_sales_order_items + business_orders + business_products 统计）
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='sales:statistics:product:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'sales:statistics:product:%');
--   DELETE FROM permissions WHERE code LIKE 'sales:statistics:product:%';

-- ========== 一、权限（2 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('产品排行','sales:statistics:product:view',2,0,'business','/business/sales/statistics/product','el-icon-goods',NULL,305,1,1,'产品排行-查看（菜单）',NOW(),NOW()),
('导出产品排行','sales:statistics:product:export',2,0,'business',NULL,NULL,NULL,306,1,1,'导出产品排行数据',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'sales:statistics:product:%';

-- ========== 二、菜单：销售管理（id=258）-> 产品排行（叶子） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 258, '产品排行', '/business/sales/statistics/product', 'el-icon-goods', 'sales:statistics:product:view', 60, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/business/sales/statistics/product' AND deleted_at IS NULL);
