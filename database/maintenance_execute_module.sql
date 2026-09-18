-- ============================================================
-- 设备保养 · 员工端保养执行功能 数据库脚本
-- 数据库：ly478931
-- ============================================================

-- ============================================================
-- 一、保养耗材表 device_maintenance_material
-- ============================================================
DROP TABLE IF EXISTS `device_maintenance_material`;
CREATE TABLE `device_maintenance_material` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `material_code` varchar(50) NOT NULL COMMENT '耗材编码',
  `material_name` varchar(100) NOT NULL COMMENT '耗材名称',
  `specification` varchar(100) DEFAULT '' COMMENT '规格型号',
  `unit` varchar(20) DEFAULT '' COMMENT '单位（个/瓶/升/米等）',
  `stock` int(11) NOT NULL DEFAULT 0 COMMENT '库存数量',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态 1启用 0停用',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_material_code` (`material_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='保养耗材表';

-- ============================================================
-- 二、保养记录表 device_maintenance_record
-- ============================================================
DROP TABLE IF EXISTS `device_maintenance_record`;
CREATE TABLE `device_maintenance_record` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `record_code` varchar(50) NOT NULL COMMENT '记录编号，格式 MNT-REC-YYYYMMDD-XXXX',
  `task_id` int(11) unsigned NOT NULL COMMENT '任务ID',
  `plan_id` int(11) unsigned NOT NULL COMMENT '计划ID',
  `device_id` int(11) unsigned NOT NULL COMMENT '设备ID',
  `device_code` varchar(50) NOT NULL DEFAULT '' COMMENT '设备编码',
  `device_name` varchar(100) NOT NULL DEFAULT '' COMMENT '设备名称',
  `level_id` int(11) unsigned NOT NULL COMMENT '保养等级ID',
  `level_name` varchar(50) NOT NULL DEFAULT '' COMMENT '保养等级名称',
  `executor_id` int(11) unsigned NOT NULL COMMENT '执行人ID',
  `executor_name` varchar(50) DEFAULT '' COMMENT '执行人姓名',
  `acceptor_id` int(11) unsigned DEFAULT NULL COMMENT '验收人ID',
  `acceptor_name` varchar(50) DEFAULT '' COMMENT '验收人姓名',
  `items` json NOT NULL COMMENT '保养项目结果',
  `materials` json DEFAULT NULL COMMENT '耗材使用记录',
  `attachments` json DEFAULT NULL COMMENT '附件图片URL数组',
  `remark` text COMMENT '备注',
  `normal_count` int(11) NOT NULL DEFAULT 0 COMMENT '正常项数',
  `abnormal_count` int(11) NOT NULL DEFAULT 0 COMMENT '异常项数',
  `status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '状态 pending待验收/passed已通过/rejected已驳回',
  `reject_reason` varchar(255) DEFAULT '' COMMENT '驳回原因',
  `execute_start_time` datetime DEFAULT NULL COMMENT '执行开始时间',
  `execute_end_time` datetime DEFAULT NULL COMMENT '执行结束时间',
  `execute_duration` int(11) DEFAULT NULL COMMENT '执行耗时（分钟）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_record_code` (`record_code`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_device_id` (`device_id`),
  KEY `idx_executor_id` (`executor_id`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='保养记录表';

-- 种子耗材数据
INSERT INTO `device_maintenance_material` (`material_code`,`material_name`,`specification`,`unit`,`stock`,`status`) VALUES
('MTRL-001','润滑油','10W-40','升',50,1),
('MTRL-002','清洁剂','通用型','瓶',30,1),
('MTRL-003','抹布','工业抹布','包',100,1),
('MTRL-004','滤芯','标准滤芯','个',20,1),
('MTRL-005','密封圈','通用','个',40,1)
ON DUPLICATE KEY UPDATE `material_name`=VALUES(`material_name`);

-- ============================================================
-- 三、系统参数：保养记录编号前缀
-- ============================================================
INSERT INTO `system_params` (`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`) VALUES
('maintenance_record_code_prefix','MNT-REC','保养记录编号前缀','device','string','保养记录编号前缀',6,0,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);
