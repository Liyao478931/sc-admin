-- =====================================================
-- 103_create_attendance_rules.sql
-- 打卡配置管理（人事管理 → 考勤管理 → 打卡管理 → 打卡配置）
--   1. 建表 1 张：attendance_rules（打卡规则配置表）
--   2. 权限：attendance:rule:view（查看）/ attendance:rule:manage（管理）
--   3. 菜单：打卡管理 → 打卡配置
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、打卡规则配置表 ==========
CREATE TABLE IF NOT EXISTS `attendance_rules` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `rule_name` varchar(100) NOT NULL COMMENT '规则名称',
  `rule_type` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0=默认规则 1=自定义规则',
  `department_ids` text DEFAULT NULL COMMENT '关联部门ID列表（JSON数组，空=全部部门）',
  `checkin_count` tinyint(1) NOT NULL DEFAULT 2 COMMENT '每日打卡次数：1/2/4',
  `morning_start` time DEFAULT '08:00:00' COMMENT '上午上班时间',
  `morning_end` time DEFAULT '12:00:00' COMMENT '上午下班时间',
  `afternoon_start` time DEFAULT '13:30:00' COMMENT '下午上班时间',
  `afternoon_end` time DEFAULT '18:00:00' COMMENT '下午下班时间',
  `advance_minutes` int(11) NOT NULL DEFAULT 30 COMMENT '可提前打卡分钟数（上班前）',
  `delay_minutes` int(11) NOT NULL DEFAULT 30 COMMENT '可延迟打卡分钟数（下班后）',
  `grace_late_minutes` int(11) NOT NULL DEFAULT 5 COMMENT '迟到宽限分钟数',
  `grace_early_minutes` int(11) NOT NULL DEFAULT 5 COMMENT '早退宽限分钟数',
  `weekdays` varchar(20) NOT NULL DEFAULT '1,2,3,4,5' COMMENT '适用工作日（1-7）',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '0=停用 1=启用',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序（数字越小越靠前）',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`),
  KEY `idx_sort` (`sort`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='打卡规则配置表';

-- 初始化默认规则
INSERT INTO `attendance_rules` (`rule_name`,`rule_type`,`department_ids`,`checkin_count`,`morning_start`,`morning_end`,`afternoon_start`,`afternoon_end`,`advance_minutes`,`delay_minutes`,`grace_late_minutes`,`grace_early_minutes`,`weekdays`,`status`,`sort`,`created_at`,`updated_at`)
SELECT '标准工作日考勤', 0, NULL, 2, '08:00:00', '12:00:00', '13:30:00', '18:00:00', 30, 30, 5, 5, '1,2,3,4,5', 1, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM attendance_rules WHERE rule_type = 0);

-- ========== 二、权限定义与 super_admin 授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('打卡配置','attendance:rule:view',1,0,'hr','/hr/attendance/checkin/rule','el-icon-time',NULL,51,1,1,'打卡配置-列表查看（菜单）',NOW(),NOW()),
('打卡配置管理','attendance:rule:manage',2,0,'hr',NULL,NULL,NULL,52,1,1,'新增/编辑/删除/设为默认打卡规则',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('attendance:rule:view','attendance:rule:manage');

-- ========== 三、菜单（打卡管理 → 打卡配置） ==========
-- 确保打卡管理菜单存在
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='attendance:checkin:view' AND deleted_at IS NULL AND type=2 LIMIT 1), '打卡管理', '/hr/attendance/checkin', 'el-icon-time', 'attendance:checkin:view', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='attendance:checkin:view' AND deleted_at IS NULL AND type=2);

SET @rule_parent_id = (SELECT id FROM menus WHERE permission='attendance:checkin:view' AND deleted_at IS NULL AND type=2 LIMIT 1);

-- 打卡配置（子菜单，打卡管理下排序 2）
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @rule_parent_id, '打卡配置', '/hr/attendance/checkin/rule', 'el-icon-time', 'attendance:rule:view', 15, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='attendance:rule:view' AND deleted_at IS NULL AND type=2);
