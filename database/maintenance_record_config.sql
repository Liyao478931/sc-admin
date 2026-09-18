-- ============================================================
-- 设备保养 · 保养记录功能 字典/参数/权限 SQL
-- 数据库：ly478931
-- ============================================================

-- 一、系统参数：保养记录编号前缀（若已存在则更新为 REC）
INSERT INTO `system_params` (`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`) VALUES
('maintenance_record_code_prefix','REC','保养记录编号前缀','device','string','保养记录编号前缀',6,0,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `param_value`=VALUES(`param_value`), `name`=VALUES(`name`);

-- 二、数据字典：保养验收状态
INSERT INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`) VALUES
('保养验收状态','maintenance_accept_status','保养记录验收状态',64,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`status`,`created_at`,`updated_at`) VALUES
((SELECT id FROM dictionary_types WHERE code='maintenance_accept_status'),'待验收','pending',1,1,NOW(),NOW()),
((SELECT id FROM dictionary_types WHERE code='maintenance_accept_status'),'已通过','approved',2,1,NOW(),NOW()),
((SELECT id FROM dictionary_types WHERE code='maintenance_accept_status'),'已驳回','rejected',3,1,NOW(),NOW());

-- 三、权限数据（父节点：保养计划管理 device:maintenance:plan:view）
SET @parent_id = (SELECT id FROM permissions WHERE code='device:maintenance:plan:view' LIMIT 1);

INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`sort`,`status`,`platform`,`created_at`,`updated_at`) VALUES
('保养记录列表','device:maintenance:record:list',2,@parent_id,'设备保养',21,1,1,NOW(),NOW()),
('保养记录详情','device:maintenance:record:query',2,@parent_id,'设备保养',22,1,1,NOW(),NOW()),
('验收通过','device:maintenance:record:accept',2,@parent_id,'设备保养',23,1,1,NOW(),NOW()),
('验收驳回','device:maintenance:record:reject',2,@parent_id,'设备保养',24,1,1,NOW(),NOW()),
('导出记录','device:maintenance:record:export',2,@parent_id,'设备保养',25,1,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);
