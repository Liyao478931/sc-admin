-- =====================================================
-- 050_accident_statistics.sql 事故统计模块（幂等可重复执行）
-- =====================================================
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('事故统计查看','safety:accident:statistics:view',1,0,'事故管理','/safety/accident/statistics','el-icon-data-line',124,1,1,'查看事故统计',NOW(),NOW()),
('事故统计导出','safety:accident:statistics:export',2,0,'事故管理','/safety/accident/statistics',NULL,125,1,1,'导出事故统计',NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`,p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin' AND p.`code` IN ('safety:accident:statistics:view','safety:accident:statistics:export');

INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT m.`id`,'事故统计','/safety/accident/statistics','el-icon-data-line','safety:accident:statistics:view',3,1,2,0,NOW(),NOW()
FROM `menus` m
WHERE m.`permission`='safety:accident:list' AND m.`path`='/safety/accident' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission`='safety:accident:statistics:view' AND x.`deleted_at` IS NULL);
