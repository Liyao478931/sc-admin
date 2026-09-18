-- 120_create_business_dashboard.sql
-- 经营管理 -> 经营总览（数据驾驶舱）
-- 1. 权限：business:dashboard:view（1条）并授权 super_admin
-- 2. 菜单：经营管理 -> 经营总览
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE permission='business:dashboard:view';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code LIKE 'business:dashboard:%');
--   DELETE FROM permissions WHERE code LIKE 'business:dashboard:%';

-- ========== 一、权限定义与 super_admin 授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('经营总览','business:dashboard:view',1,0,'business','/business/dashboard/overview','el-icon-data-board',NULL,5,1,1,'经营总览-查看（菜单/数据驾驶舱）',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('business:dashboard:view');

-- ========== 二、菜单（经营管理 -> 经营总览） ==========
SET @business_id = (SELECT id FROM menus WHERE name='经营管理' AND deleted_at IS NULL AND parent_id=0 LIMIT 1);

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @business_id, '经营总览', '/business/dashboard/overview', 'el-icon-data-board', 'business:dashboard:view', 5, 1, 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='business:dashboard:view' AND deleted_at IS NULL);
