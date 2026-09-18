-- =====================================================
-- 101_create_face_library.sql
-- 后台人脸录入管理（人事管理 → 考勤管理 → 打卡管理 → 人脸录入）
--   1. 建表 1 张：face_library（人脸库表）
--   2. 权限：attendance:checkin:view（打卡管理菜单）/ face:view（人脸录入）/ face:register（录入管理）
--   3. 菜单：考勤管理 → 打卡管理 → 人脸录入
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、人脸库表 ==========
CREATE TABLE IF NOT EXISTS `face_library` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL COMMENT '用户ID（关联 users.id）',
  `person_id` varchar(64) NOT NULL COMMENT '腾讯云人员ID',
  `person_name` varchar(60) NOT NULL COMMENT '人员名称（员工姓名）',
  `face_image` varchar(255) DEFAULT NULL COMMENT '人脸照片URL（相对路径 /uploads/face/xxx.jpg）',
  `face_id` varchar(64) DEFAULT NULL COMMENT '腾讯云人脸ID',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '0=无效 1=有效',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_id` (`user_id`),
  KEY `idx_person_id` (`person_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='人脸库表（后台人脸录入）';

-- ========== 二、权限定义与 super_admin 授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('打卡管理','attendance:checkin:view',1,0,'hr','/hr/attendance/checkin','el-icon-time',NULL,48,1,1,'打卡管理-菜单',NOW(),NOW()),
('人脸录入','face:view',1,0,'hr','/hr/attendance/checkin/face','el-icon-camera',NULL,49,1,1,'人脸录入-列表查看（菜单）',NOW(),NOW()),
('人脸录入管理','face:register',2,0,'hr',NULL,NULL,NULL,50,1,1,'录入/重新录入/删除人脸',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('attendance:checkin:view','face:view','face:register');

-- ========== 三、菜单（人事管理 → 考勤管理 → 打卡管理 → 人脸录入） ==========
-- 确保人事管理顶级菜单存在
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT 0, '人事管理', '', 'el-icon-user', 'hr:view', 70, 1, 1, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='人事管理' AND parent_id=0 AND deleted_at IS NULL);

-- 确保考勤管理菜单存在（挂在人事管理下）
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE name='人事管理' AND parent_id=0 AND deleted_at IS NULL LIMIT 1), '考勤管理', '/hr/attendance', 'el-icon-time', 'hr:attendance:view', 20, 1, 2, 1, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='考勤管理' AND parent_id=(SELECT id FROM menus WHERE name='人事管理' AND parent_id=0 AND deleted_at IS NULL LIMIT 1) AND deleted_at IS NULL);

SET @ck_parent_id = (SELECT id FROM menus WHERE name='考勤管理' AND deleted_at IS NULL AND parent_id=(SELECT id FROM menus WHERE name='人事管理' AND parent_id=0 AND deleted_at IS NULL LIMIT 1) LIMIT 1);

-- 打卡管理（父菜单）
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @ck_parent_id, '打卡管理', '/hr/attendance/checkin', 'el-icon-time', 'attendance:checkin:view', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='attendance:checkin:view' AND deleted_at IS NULL AND type=2);

SET @face_parent_id = (SELECT id FROM menus WHERE name='打卡管理' AND deleted_at IS NULL AND parent_id=@ck_parent_id LIMIT 1);

-- 人脸录入（子菜单，打卡管理下第 1 项）
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @face_parent_id, '人脸录入', '/hr/attendance/checkin/face', 'el-icon-camera', 'face:view', 10, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='face:view' AND deleted_at IS NULL AND type=2);
