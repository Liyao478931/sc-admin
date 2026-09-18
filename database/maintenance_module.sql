-- ============================================================
-- 设备保养管理模块 · 数据库脚本
-- 包含：三张业务表 + 数据字典 + 系统参数 + 权限数据
-- 数据库：ly478931
-- ============================================================

-- ============================================================
-- 一、保养等级表 device_maintenance_level
-- ============================================================
DROP TABLE IF EXISTS `device_maintenance_level`;
CREATE TABLE `device_maintenance_level` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `level_code` varchar(30) NOT NULL COMMENT '等级编码，如 DAILY、LEVEL1、LEVEL2、LEVEL3',
  `level_name` varchar(50) NOT NULL COMMENT '等级名称，如日常保养、一级保养',
  `executor_role` varchar(50) DEFAULT '' COMMENT '执行人角色',
  `acceptor_role` varchar(50) DEFAULT '' COMMENT '验收人角色',
  `default_cycle_type` varchar(20) DEFAULT '' COMMENT '默认周期类型 day/week/month/quarter/year/hour',
  `default_cycle_value` int(11) DEFAULT 0 COMMENT '默认周期值',
  `description` varchar(255) DEFAULT '' COMMENT '描述说明',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态 1启用 0停用',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_level_code` (`level_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='保养等级表';

-- ============================================================
-- 二、保养项目模板表 device_maintenance_template
-- ============================================================
DROP TABLE IF EXISTS `device_maintenance_template`;
CREATE TABLE `device_maintenance_template` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `template_code` varchar(50) NOT NULL COMMENT '模板编号，格式 TPL-YYYYMMDD-XXXX',
  `template_name` varchar(100) NOT NULL COMMENT '模板名称',
  `device_type_id` int(11) unsigned DEFAULT NULL COMMENT '适用设备类型ID，关联设备分类表，空=通用',
  `level_id` int(11) unsigned NOT NULL COMMENT '保养等级ID，关联保养等级表',
  `items` json NOT NULL COMMENT '保养项目列表',
  `standard_hours` decimal(5,2) NOT NULL DEFAULT 0.00 COMMENT '标准工时（小时）',
  `status` varchar(20) NOT NULL DEFAULT 'active' COMMENT '状态 active启用 inactive停用',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_template_code` (`template_code`),
  KEY `idx_level_id` (`level_id`),
  KEY `idx_device_type_id` (`device_type_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='保养项目模板表';

-- ============================================================
-- 三、保养计划表 device_maintenance_plan
-- ============================================================
DROP TABLE IF EXISTS `device_maintenance_plan`;
CREATE TABLE `device_maintenance_plan` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `plan_code` varchar(50) NOT NULL COMMENT '计划编号，格式 MNT-YYYYMMDD-XXXX',
  `plan_name` varchar(100) NOT NULL COMMENT '计划名称',
  `device_id` int(11) unsigned NOT NULL COMMENT '设备ID，关联设备主表',
  `level_id` int(11) unsigned NOT NULL COMMENT '保养等级ID',
  `template_id` int(11) unsigned DEFAULT NULL COMMENT '模板ID，关联保养模板表',
  `cycle_type` varchar(20) NOT NULL COMMENT '周期类型 day/week/month/quarter/year/hour',
  `cycle_value` int(11) NOT NULL COMMENT '周期值',
  `cycle_unit` varchar(20) DEFAULT '' COMMENT '周期单位 day/week/month/quarter/year/hour',
  `start_date` date DEFAULT NULL COMMENT '计划开始日期',
  `end_date` date DEFAULT NULL COMMENT '计划结束日期',
  `last_maintenance_date` date DEFAULT NULL COMMENT '上次保养日期',
  `next_maintenance_date` date DEFAULT NULL COMMENT '下次保养日期',
  `executor_id` int(11) unsigned DEFAULT NULL COMMENT '执行人ID，关联user表',
  `executor_name` varchar(50) DEFAULT '' COMMENT '执行人姓名',
  `acceptor_id` int(11) unsigned DEFAULT NULL COMMENT '验收人ID，关联user表',
  `acceptor_name` varchar(50) DEFAULT '' COMMENT '验收人姓名',
  `need_approve` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否需要审批 1是 0否',
  `status` varchar(20) NOT NULL DEFAULT 'active' COMMENT '状态 active启用 inactive停用 expired过期',
  `remark` text COMMENT '备注',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_plan_code` (`plan_code`),
  KEY `idx_device_id` (`device_id`),
  KEY `idx_level_id` (`level_id`),
  KEY `idx_status` (`status`),
  KEY `idx_next_date` (`next_maintenance_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='保养计划表';

-- ============================================================
-- 四、数据字典
-- ============================================================
-- 字典类型：保养等级
INSERT INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`) VALUES
('保养等级','maintenance_level','设备保养等级',60,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 字典条目：保养等级
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`status`,`created_at`,`updated_at`) VALUES
((SELECT id FROM dictionary_types WHERE code='maintenance_level'),'日常保养','daily',1,1,NOW(),NOW()),
((SELECT id FROM dictionary_types WHERE code='maintenance_level'),'一级保养','level1',2,1,NOW(),NOW()),
((SELECT id FROM dictionary_types WHERE code='maintenance_level'),'二级保养','level2',3,1,NOW(),NOW()),
((SELECT id FROM dictionary_types WHERE code='maintenance_level'),'三级保养(大修)','level3',4,1,NOW(),NOW());

-- 字典类型：保养周期类型
INSERT INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`) VALUES
('保养周期类型','maintenance_cycle_type','保养计划周期类型',61,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 字典条目：保养周期类型
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`status`,`created_at`,`updated_at`) VALUES
((SELECT id FROM dictionary_types WHERE code='maintenance_cycle_type'),'每日','day',1,1,NOW(),NOW()),
((SELECT id FROM dictionary_types WHERE code='maintenance_cycle_type'),'每周','week',2,1,NOW(),NOW()),
((SELECT id FROM dictionary_types WHERE code='maintenance_cycle_type'),'每月','month',3,1,NOW(),NOW()),
((SELECT id FROM dictionary_types WHERE code='maintenance_cycle_type'),'每季','quarter',4,1,NOW(),NOW()),
((SELECT id FROM dictionary_types WHERE code='maintenance_cycle_type'),'每年','year',5,1,NOW(),NOW()),
((SELECT id FROM dictionary_types WHERE code='maintenance_cycle_type'),'按运行时长','hour',6,1,NOW(),NOW());

-- 字典类型：保养计划状态
INSERT INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`) VALUES
('保养计划状态','maintenance_plan_status','保养计划状态',62,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 字典条目：保养计划状态
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`status`,`created_at`,`updated_at`) VALUES
((SELECT id FROM dictionary_types WHERE code='maintenance_plan_status'),'启用','active',1,1,NOW(),NOW()),
((SELECT id FROM dictionary_types WHERE code='maintenance_plan_status'),'停用','inactive',2,1,NOW(),NOW()),
((SELECT id FROM dictionary_types WHERE code='maintenance_plan_status'),'过期','expired',3,1,NOW(),NOW());

-- ============================================================
-- 五、系统参数
-- ============================================================
INSERT INTO `system_params` (`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`) VALUES
('maintenance_plan_code_prefix','MNT','保养计划编号前缀','device','string','保养计划编号前缀',1,0,1,NOW(),NOW()),
('maintenance_template_code_prefix','TPL','保养模板编号前缀','device','string','保养模板编号前缀',2,0,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- ============================================================
-- 六、权限数据
-- 权限父节点：保养计划管理（type=1 菜单）
-- ============================================================
-- 父节点：保养计划管理
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`sort`,`status`,`platform`,`created_at`,`updated_at`) VALUES
('保养计划管理','device:maintenance:plan:view',1,0,'设备保养',50,1,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 保养等级权限
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`sort`,`status`,`platform`,`created_at`,`updated_at`) VALUES
('保养等级列表','device:maintenance:level:list',2,(SELECT id FROM permissions WHERE code='device:maintenance:plan:view'),'设备保养',1,1,1,NOW(),NOW()),
('保养等级详情','device:maintenance:level:query',2,(SELECT id FROM permissions WHERE code='device:maintenance:plan:view'),'设备保养',2,1,1,NOW(),NOW()),
('新增保养等级','device:maintenance:level:add',2,(SELECT id FROM permissions WHERE code='device:maintenance:plan:view'),'设备保养',3,1,1,NOW(),NOW()),
('编辑保养等级','device:maintenance:level:edit',2,(SELECT id FROM permissions WHERE code='device:maintenance:plan:view'),'设备保养',4,1,1,NOW(),NOW()),
('删除保养等级','device:maintenance:level:delete',2,(SELECT id FROM permissions WHERE code='device:maintenance:plan:view'),'设备保养',5,1,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 保养模板权限
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`sort`,`status`,`platform`,`created_at`,`updated_at`) VALUES
('保养模板列表','device:maintenance:template:list',2,(SELECT id FROM permissions WHERE code='device:maintenance:plan:view'),'设备保养',6,1,1,NOW(),NOW()),
('保养模板详情','device:maintenance:template:query',2,(SELECT id FROM permissions WHERE code='device:maintenance:plan:view'),'设备保养',7,1,1,NOW(),NOW()),
('新增保养模板','device:maintenance:template:add',2,(SELECT id FROM permissions WHERE code='device:maintenance:plan:view'),'设备保养',8,1,1,NOW(),NOW()),
('编辑保养模板','device:maintenance:template:edit',2,(SELECT id FROM permissions WHERE code='device:maintenance:plan:view'),'设备保养',9,1,1,NOW(),NOW()),
('删除保养模板','device:maintenance:template:delete',2,(SELECT id FROM permissions WHERE code='device:maintenance:plan:view'),'设备保养',10,1,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 保养计划权限
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`sort`,`status`,`platform`,`created_at`,`updated_at`) VALUES
('保养计划列表','device:maintenance:plan:list',2,(SELECT id FROM permissions WHERE code='device:maintenance:plan:view'),'设备保养',11,1,1,NOW(),NOW()),
('保养计划详情','device:maintenance:plan:query',2,(SELECT id FROM permissions WHERE code='device:maintenance:plan:view'),'设备保养',12,1,1,NOW(),NOW()),
('新增保养计划','device:maintenance:plan:add',2,(SELECT id FROM permissions WHERE code='device:maintenance:plan:view'),'设备保养',13,1,1,NOW(),NOW()),
('编辑保养计划','device:maintenance:plan:edit',2,(SELECT id FROM permissions WHERE code='device:maintenance:plan:view'),'设备保养',14,1,1,NOW(),NOW()),
('删除保养计划','device:maintenance:plan:delete',2,(SELECT id FROM permissions WHERE code='device:maintenance:plan:view'),'设备保养',15,1,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);
