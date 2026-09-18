-- 118_create_purchase_statistics.sql
-- 经营管理 -> 采购管理 -> 采购统计（总览 / 采购额分析 / 供应商排行）
-- 1. 权限：business:purchase:statistics:view / export（2条）并授权 super_admin
-- 2. 菜单：采购管理 -> 采购统计（分组）-> 总览 / 采购额分析 / 供应商排行
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission IN ('business:purchase:statistics:view','business:purchase:statistics:overview','business:purchase:statistics:amount','business:purchase:statistics:supplier');
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'business:purchase:statistics:%');
--   DELETE FROM permissions WHERE code LIKE 'business:purchase:statistics:%';

-- ========== 一、权限定义与 super_admin 授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('采购统计','business:purchase:statistics:view',1,0,'business','/business/purchase/statistics/overview','el-icon-data-analysis',NULL,70,1,1,'采购统计-查看（菜单/总览/分析/排行）',NOW(),NOW()),
('采购统计导出','business:purchase:statistics:export',2,0,'business',NULL,NULL,NULL,71,1,1,'导出采购统计数据',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('business:purchase:statistics:view','business:purchase:statistics:export');

-- ========== 二、菜单（采购管理 -> 采购统计 -> 3 页面） ==========
SET @business_id = (SELECT id FROM menus WHERE name='经营管理' AND deleted_at IS NULL AND parent_id=0 LIMIT 1);
SET @purchase_menu_id = (SELECT id FROM menus WHERE parent_id=@business_id AND name='采购管理' AND deleted_at IS NULL AND type=1 LIMIT 1);

-- 采购统计分组
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @purchase_menu_id, '采购统计', '/business/purchase/statistics/overview', 'el-icon-data-analysis', 'business:purchase:statistics:view', 60, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:purchase:statistics:view' AND deleted_at IS NULL AND type=1);

SET @stats_parent_id = (SELECT id FROM menus WHERE permission='business:purchase:statistics:view' AND deleted_at IS NULL AND type=1 LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @stats_parent_id, '统计总览', '/business/purchase/statistics/overview', 'el-icon-data-line', 'business:purchase:statistics:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:purchase:statistics:overview' AND deleted_at IS NULL AND type=2);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @stats_parent_id, '采购额分析', '/business/purchase/statistics/amount', 'el-icon-trend-charts', 'business:purchase:statistics:amount', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:purchase:statistics:amount' AND deleted_at IS NULL AND type=2);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @stats_parent_id, '供应商排行', '/business/purchase/statistics/supplier', 'el-icon-medal', 'business:purchase:statistics:supplier', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:purchase:statistics:supplier' AND deleted_at IS NULL AND type=2);
