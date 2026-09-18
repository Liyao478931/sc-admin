-- =====================================================
-- 100_create_attendance_points.sql
-- 移动端考勤打卡：打卡点配置表 + 权限 + 菜单
--   1. 建表 1 张：attendance_points（打卡点，含经纬度/半径/打卡时间窗）
--   2. 权限：attendance:points:view（菜单）/ attendance:points:manage（按钮）
--   3. 菜单：人事管理 → 考勤管理 → 打卡点设置
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、打卡点配置表 ==========
CREATE TABLE IF NOT EXISTS `attendance_points` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `point_name` varchar(100) NOT NULL COMMENT '打卡点名称',
  `address` varchar(255) NOT NULL DEFAULT '' COMMENT '详细地址',
  `latitude` decimal(10,7) NOT NULL COMMENT '纬度',
  `longitude` decimal(10,7) NOT NULL COMMENT '经度',
  `radius` int(11) NOT NULL DEFAULT 300 COMMENT '有效半径（米），范围100-3000',
  `start_time` time DEFAULT NULL COMMENT '打卡开始时间',
  `end_time` time DEFAULT NULL COMMENT '打卡结束时间',
  `weekdays` varchar(20) NOT NULL DEFAULT '1,2,3,4,5' COMMENT '有效星期：1-7（1=周一）',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='考勤打卡点配置';

-- 初始化一个示例打卡点（默认停用，管理员配置后启用）
INSERT IGNORE INTO `attendance_points` (`id`,`point_name`,`address`,`latitude`,`longitude`,`radius`,`start_time`,`end_time`,`weekdays`,`status`,`create_time`,`update_time`)
VALUES (1,'示例打卡点','请在地图上配置公司位置',39.9042000,116.4074000,300,'08:00:00','18:00:00','1,2,3,4,5',0,NOW(),NOW());

-- ========== 二、权限定义与 super_admin 授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('打卡点设置','attendance:points:view',1,0,'hr','/hr/attendance/points','el-icon-location',NULL,45,1,1,'打卡点设置-列表查看（菜单）',NOW(),NOW()),
('打卡点设置管理','attendance:points:manage',2,0,'hr',NULL,NULL,NULL,46,1,1,'新增/编辑/删除/启停打卡点',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('attendance:points:view','attendance:points:manage');

-- 打卡权限（全员默认拥有，移动端打卡基础功能）
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('考勤打卡','attendance:checkin',2,0,'hr',NULL,NULL,NULL,47,1,1,'移动端上班/下班打卡（全员默认）',NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE p.`code`='attendance:checkin';

-- ========== 三、菜单（人事管理 → 考勤管理 → 打卡点设置） ==========
-- 确保人事管理顶级菜单存在
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 0, '人事管理', '', 'el-icon-user', 'hr:view', 70, 1, 1, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='人事管理' AND parent_id=0 AND deleted_at IS NULL);

-- 确保考勤管理菜单存在（挂在人事管理下）
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE name='人事管理' AND parent_id=0 AND deleted_at IS NULL LIMIT 1), '考勤管理', '/hr/attendance', 'el-icon-time', 'hr:attendance:view', 20, 1, 2, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='考勤管理' AND parent_id=(SELECT id FROM menus WHERE name='人事管理' AND parent_id=0 AND deleted_at IS NULL LIMIT 1) AND deleted_at IS NULL);

SET @att_point_parent_id = (SELECT id FROM menus WHERE name='考勤管理' AND deleted_at IS NULL AND parent_id=(SELECT id FROM menus WHERE name='人事管理' AND parent_id=0 AND deleted_at IS NULL LIMIT 1) LIMIT 1);

-- 打卡点设置页面
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @att_point_parent_id, '打卡点设置', '/hr/attendance/points', 'el-icon-location', 'attendance:points:view', 40, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='attendance:points:view' AND deleted_at IS NULL AND type=2);

-- ========== 四、移动端工作台入口（考勤打卡） ==========
-- 路径：考勤打卡
INSERT INTO `app_paths` (`name`,`path`,`page_key`,`platform`,`page_type`,`require_auth`,`status`,`created_at`,`updated_at`)
SELECT '考勤打卡', '/pages/attendance/index', 'attendance', 0, 1, 1, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_paths WHERE name='考勤打卡' AND deleted_at IS NULL);

SET @att_path_id = (SELECT id FROM app_paths WHERE name='考勤打卡' AND deleted_at IS NULL LIMIT 1);

-- 功能：考勤打卡（工作台 home 显示）
INSERT INTO `app_functions` (`name`,`code`,`icon`,`path_id`,`permission`,`display_location`,`sort`,`status`,`visible_type`,`created_at`,`updated_at`)
SELECT '考勤打卡', 'attendance_checkin', 'attendance', @att_path_id, 'attendance:checkin', 'home', 30, 1, 'all', NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM app_functions WHERE code='attendance_checkin' AND deleted_at IS NULL);
