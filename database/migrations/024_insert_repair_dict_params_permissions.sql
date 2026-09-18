-- =====================================================
-- 024_insert_repair_dict_params_permissions.sql
-- 设备维修模块：数据字典 + 系统参数 + 权限 + 菜单
-- =====================================================

-- ========== 一、数据字典 ==========
-- 1. 维修故障类型
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('维修故障类型','repair_fault_type','维修工单故障类型',60,1,NOW(),NOW());
SET @d1=(SELECT id FROM dictionary_types WHERE code='repair_fault_type');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d1,'机械故障','mechanical',1,'info',1,NOW(),NOW()),
(@d1,'电气故障','electrical',2,'warning',1,NOW(),NOW()),
(@d1,'液压故障','hydraulic',3,'danger',1,NOW(),NOW()),
(@d1,'气动故障','pneumatic',4,'primary',1,NOW(),NOW()),
(@d1,'软件故障','software',5,'success',1,NOW(),NOW()),
(@d1,'其他','other',6,'info',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 2. 维修紧急程度
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('维修紧急程度','repair_emergency_level','维修工单紧急程度',61,1,NOW(),NOW());
SET @d2=(SELECT id FROM dictionary_types WHERE code='repair_emergency_level');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d2,'普通','normal',1,'info',1,NOW(),NOW()),
(@d2,'紧急','urgent',2,'warning',1,NOW(),NOW()),
(@d2,'特急','critical',3,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 3. 维修来源类型
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('维修来源类型','repair_source_type','维修工单来源类型',62,1,NOW(),NOW());
SET @d3=(SELECT id FROM dictionary_types WHERE code='repair_source_type');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d3,'人工报修','manual',1,'primary',1,NOW(),NOW()),
(@d3,'巡检转维修','inspection',2,'warning',1,NOW(),NOW()),
(@d3,'保养转维修','maintenance',3,'success',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- 4. 维修工单状态
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('维修工单状态','repair_order_status','维修工单状态',63,1,NOW(),NOW());
SET @d4=(SELECT id FROM dictionary_types WHERE code='repair_order_status');
INSERT INTO dictionary_entries (type_id,label,value,sort,style,status,created_at,updated_at) VALUES
(@d4,'待派单','pending',1,'info',1,NOW(),NOW()),
(@d4,'已派单','assigned',2,'primary',1,NOW(),NOW()),
(@d4,'维修中','repairing',3,'warning',1,NOW(),NOW()),
(@d4,'待验收','accepted',4,'warning',1,NOW(),NOW()),
(@d4,'已验收','approved',5,'success',1,NOW(),NOW()),
(@d4,'已关闭','closed',6,'info',1,NOW(),NOW()),
(@d4,'已驳回','rejected',7,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE label=VALUES(label),sort=VALUES(sort),style=VALUES(style),status=VALUES(status),deleted_at=NULL,updated_at=NOW();

-- ========== 二、系统参数（settings 表供 SettingsService 读取 + system_params 表供管理页面展示） ==========
INSERT INTO `settings` (`key`, `value`, `created_at`, `updated_at`) VALUES
('repair_order_code_prefix',    'REP', NOW(), NOW()),
('repair_auto_close_days',      '7',   NOW(), NOW()),
('repair_urgent_remind_hours',  '2',   NOW(), NOW())
ON DUPLICATE KEY UPDATE `updated_at` = NOW();

INSERT INTO `system_params`
(`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`)
VALUES
('repair_order_code_prefix',   'REP', '维修工单编号前缀',   'device', 'string', '维修工单编号前缀（REP-YYYYMMDD-XXXX）', 20, 0, 1, NOW(), NOW()),
('repair_auto_close_days',     '7',   '自动关闭天数',       'device', 'number', '已验收后自动关闭工单的天数', 21, 0, 1, NOW(), NOW()),
('repair_urgent_remind_hours', '2',   '紧急工单提醒小时数', 'device', 'number', '特急工单提醒响应时长（小时）', 22, 0, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE
param_value=VALUES(param_value),name=VALUES(name),param_group=VALUES(param_group),
param_type=VALUES(param_type),description=VALUES(description),sort=VALUES(sort),status=VALUES(status),updated_at=NOW();

-- ========== 三、权限定义 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`, `created_at`, `updated_at`) VALUES
('设备维修',       'device:repair:view',        1, 0, '设备维修', '/device/repair/order', 'el-icon-s-tools', NULL, 28, 1, 1, '设备维修模块', NOW(), NOW()),
('维修工单列表',   'device:repair:order:list',  2, 0, '维修工单', '/device/repair/order', NULL, NULL, 1, 1, 1, '查看工单列表', NOW(), NOW()),
('维修工单详情',   'device:repair:order:query', 2, 0, '维修工单', '/device/repair/order', NULL, NULL, 2, 1, 1, '查看工单详情', NOW(), NOW()),
('维修工单新增',   'device:repair:order:add',   2, 0, '维修工单', '/device/repair/order', NULL, NULL, 3, 1, 1, '新增工单', NOW(), NOW()),
('维修工单编辑',   'device:repair:order:edit',  2, 0, '维修工单', '/device/repair/order', NULL, NULL, 4, 1, 1, '编辑工单', NOW(), NOW()),
('维修工单删除',   'device:repair:order:delete', 2, 0, '维修工单', '/device/repair/order', NULL, NULL, 5, 1, 1, '删除工单', NOW(), NOW()),
('维修工单派单',   'device:repair:order:assign', 2, 0, '维修工单', '/device/repair/order', NULL, NULL, 6, 1, 1, '派单/转派', NOW(), NOW()),
('维修工单验收通过', 'device:repair:order:accept', 2, 0, '维修工单', '/device/repair/order', NULL, NULL, 7, 1, 1, '验收通过', NOW(), NOW()),
('维修工单验收驳回', 'device:repair:order:reject', 2, 0, '维修工单', '/device/repair/order', NULL, NULL, 8, 1, 1, '验收驳回', NOW(), NOW()),
('维修工单导出',   'device:repair:order:export', 2, 0, '维修工单', '/device/repair/order', NULL, NULL, 9, 1, 1, '导出工单', NOW(), NOW())
ON DUPLICATE KEY UPDATE
`name` = VALUES(`name`), `type` = VALUES(`type`), `module` = VALUES(`module`),
`path` = VALUES(`path`), `icon` = VALUES(`icon`), `sort` = VALUES(`sort`),
`status` = VALUES(`status`), `updated_at` = NOW();

-- ========== 四、角色授权（超级管理员） ==========
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` = 'super_admin'
  AND p.`code` IN ('device:repair:view','device:repair:order:list','device:repair:order:query','device:repair:order:add',
                   'device:repair:order:edit','device:repair:order:delete','device:repair:order:assign',
                   'device:repair:order:accept','device:repair:order:reject','device:repair:order:export');

-- ========== 五、侧边栏菜单（设备管理下新增"设备维修"，其下"维修工单"） ==========
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT m.`id`, '设备维修', '/device/repair/order', 'el-icon-s-tools', 'device:repair:view', 75, 1, 2, 0, NOW(), NOW()
FROM `menus` m
WHERE m.`permission` = 'device:manage:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission` = 'device:repair:view' AND x.`deleted_at` IS NULL);

INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`, `created_at`, `updated_at`)
SELECT m.`id`, '维修工单', '/device/repair/order', 'el-icon-document', 'device:repair:order:list', 1, 1, 2, 0, NOW(), NOW()
FROM `menus` m
WHERE m.`permission` = 'device:repair:view' AND m.`deleted_at` IS NULL
  AND NOT EXISTS (SELECT 1 FROM `menus` x WHERE x.`permission` = 'device:repair:order:list' AND x.`deleted_at` IS NULL);
