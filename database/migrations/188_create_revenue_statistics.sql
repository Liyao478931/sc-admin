-- 188_create_revenue_statistics.sql
-- 经营管理「销售额分析」：2 权限 + 1 菜单（无新增表，基于 business_orders 统计）
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='sales:statistics:revenue:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'sales:statistics:revenue:%');
--   DELETE FROM permissions WHERE code LIKE 'sales:statistics:revenue:%';

-- ========== 一、权限（2 个） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('销售额分析','sales:statistics:revenue:view',2,0,'business','/business/sales/statistics/revenue','el-icon-data-analysis',NULL,295,1,1,'销售额分析-查看（菜单）',NOW(),NOW()),
('导出销售额分析','sales:statistics:revenue:export',2,0,'business',NULL,NULL,NULL,296,1,1,'导出销售额明细',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code` LIKE 'sales:statistics:revenue:%';

-- ========== 二、菜单：销售管理（id=258）-> 销售额分析（叶子） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 258, '销售额分析', '/business/sales/statistics/revenue', 'el-icon-data-analysis', 'sales:statistics:revenue:view', 40, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/business/sales/statistics/revenue' AND deleted_at IS NULL);
