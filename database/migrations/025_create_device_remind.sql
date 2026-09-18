-- =====================================================
-- 025_create_device_remind.sql
-- 设备提醒模块：新增设备字段 + 提醒历史表 + 数据字典 + 系统参数 + 权限 + 菜单
-- =====================================================

-- ========== 一、device_assets 新增字段（年检到期日/保险到期日） ==========
ALTER TABLE `device_assets`
  ADD COLUMN `inspection_expire_date` date DEFAULT NULL COMMENT '年检到期日' AFTER `put_into_use_date`,
  ADD COLUMN `insurance_expire_date` date DEFAULT NULL COMMENT '保险到期日' AFTER `inspection_expire_date`;

-- ========== 二、提醒历史表 ==========
CREATE TABLE IF NOT EXISTS `device_remind_history` (
  `id`           int(11) unsigned NOT NULL AUTO_INCREMENT,
  `remind_type`  varchar(30)  NOT NULL COMMENT '提醒类型：inspection/maintenance/repair/annual_inspection/insurance/special_inspection',
  `device_id`    int(11) unsigned NOT NULL DEFAULT 0 COMMENT '设备ID',
  `device_name`  varchar(100) NOT NULL DEFAULT '' COMMENT '设备名称（冗余）',
  `device_code`  varchar(50)  NOT NULL DEFAULT '' COMMENT '设备编码（冗余）',
  `remind_item`  varchar(255) NOT NULL DEFAULT '' COMMENT '提醒事项',
  `due_date`     date         DEFAULT NULL COMMENT '到期日期',
  `source_id`    int(11) unsigned NOT NULL DEFAULT 0 COMMENT '来源记录ID（任务/工单ID）',
  `handler_id`   int(11) unsigned NOT NULL DEFAULT 0 COMMENT '处理人ID',
  `handler_name` varchar(50)  NOT NULL DEFAULT '' COMMENT '处理人姓名',
  `handled_at`   datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '处理时间',
  `create_time`  datetime     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_remind_type` (`remind_type`),
  KEY `idx_device_id` (`device_id`),
  KEY `idx_handled_at` (`handled_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备提醒历史';

-- ========== 三、数据字典 ==========
-- 1. 提醒状态
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('提醒状态','remind_status','设备提醒状态',70,1,NOW(),NOW());
SET @d1=(SELECT id FROM dictionary_types WHERE code='remind_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d1,'待执行','pending',1,'primary',1,NOW(),NOW()),
(@d1,'即将到期','soon',2,'warning',1,NOW(),NOW()),
(@d1,'已逾期','overdue',3,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 2. 提醒类型
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('提醒类型','remind_type','设备提醒类型',71,1,NOW(),NOW());
SET @d2=(SELECT id FROM dictionary_types WHERE code='remind_type');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d2,'巡检任务','inspection',1,'primary',1,NOW(),NOW()),
(@d2,'保养任务','maintenance',2,'success',1,NOW(),NOW()),
(@d2,'维修工单','repair',3,'warning',1,NOW(),NOW()),
(@d2,'设备年检','annual_inspection',4,'primary',1,NOW(),NOW()),
(@d2,'设备保险','insurance',5,'info',1,NOW(),NOW()),
(@d2,'特种检验','special_inspection',6,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- ========== 四、系统参数（提前提醒天数） ==========
INSERT INTO `settings` (`key`, `value`, `created_at`, `updated_at`) VALUES
('remind_inspection_advance_days',         '3',  NOW(), NOW()),
('remind_maintenance_advance_days',        '7',  NOW(), NOW()),
('remind_annual_inspection_advance_days',  '30', NOW(), NOW()),
('remind_insurance_advance_days',          '30', NOW(), NOW()),
('remind_special_inspection_advance_days', '30', NOW(), NOW())
ON DUPLICATE KEY UPDATE `updated_at` = NOW();

INSERT INTO `system_params`
(`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`)
VALUES
('remind_inspection_advance_days',         '3',  '巡检提前提醒天数', 'device', 'number', '巡检任务提前提醒天数', 30, 0, 1, NOW(), NOW()),
('remind_maintenance_advance_days',        '7',  '保养提前提醒天数', 'device', 'number', '保养任务提前提醒天数', 31, 0, 1, NOW(), NOW()),
('remind_annual_inspection_advance_days',  '30', '年检提前提醒天数', 'device', 'number', '设备年检提前提醒天数', 32, 0, 1, NOW(), NOW()),
('remind_insurance_advance_days',          '30', '保险提前提醒天数', 'device', 'number', '设备保险提前提醒天数', 33, 0, 1, NOW(), NOW()),
('remind_special_inspection_advance_days', '30', '特种检验提前提醒天数', 'device', 'number', '特种设备检验提前提醒天数', 34, 0, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
param_value=VALUES(param_value),name=VALUES(name),param_group=VALUES(param_group),
param_type=VALUES(param_type),description=VALUES(description),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();

-- ========== 五、权限定义 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`, `created_at`, `updated_at`) VALUES
('设备提醒列表', 'device:remind:list',   1, 0, '设备提醒', '/device/remind', 'el-icon-bell', NULL, 30, 1, 1, '查看设备提醒列表', NOW(), NOW()),
('设备提醒配置', 'device:remind:config', 2, 0, '设备提醒', '/device/remind', NULL, NULL, 31, 1, 1, '配置提醒提前天数', NOW(), NOW()),
('设备提醒处理', 'device:remind:handle', 2, 0, '设备提醒', '/device/remind', NULL, NULL, 32, 1, 1, '处理提醒记录', NOW(), NOW())
ON DUPLICATE KEY UPDATE
`name` = VALUES(`name`), `type` = VALUES(`type`), `module` = VALUES(`module`),
`path` = VALUES(`path`), `icon` = VALUES(`icon`), `sort` = VALUES(`sort`),
`status` = VALUES(`status`), `updated_at` = NOW();

-- ========== 六、角色授权（超级管理员） ==========
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` = 'super_admin'
  AND p.`code` IN ('device:remind:list','device:remind:config','device:remind:handle');

-- ========== 七、侧边栏菜单（设备管理下新增"设备提醒"） ==========
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT m.`id`, '设备提醒', '/device/remind', 'el-icon-bell', 'device:remind:list', 76, 1, 2, 0, NOW(), NOW()
FROM `menus` m
WHERE m.`permission` = 'device:manage:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission` = 'device:remind:list' AND x.`deleted_at` IS NULL);
