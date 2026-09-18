-- ============================================================
-- 设备保养管理模块 · 保养任务功能 数据库脚本
-- 数据库：ly478931
-- ============================================================

-- ============================================================
-- 一、保养任务表 device_maintenance_task
-- ============================================================
DROP TABLE IF EXISTS `device_maintenance_task`;
CREATE TABLE `device_maintenance_task` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `task_code` varchar(50) NOT NULL COMMENT '任务编号，格式 MNT-TASK-YYYYMMDD-XXXX',
  `plan_id` int(11) unsigned NOT NULL COMMENT '计划ID',
  `device_id` int(11) unsigned NOT NULL COMMENT '设备ID',
  `device_code` varchar(50) NOT NULL DEFAULT '' COMMENT '设备编码（冗余）',
  `device_name` varchar(100) NOT NULL DEFAULT '' COMMENT '设备名称（冗余）',
  `level_id` int(11) unsigned NOT NULL COMMENT '保养等级ID',
  `level_name` varchar(50) NOT NULL DEFAULT '' COMMENT '保养等级名称（冗余）',
  `template_id` int(11) unsigned DEFAULT NULL COMMENT '模板ID',
  `executor_id` int(11) unsigned DEFAULT NULL COMMENT '执行人ID',
  `executor_name` varchar(50) DEFAULT '' COMMENT '执行人姓名',
  `acceptor_id` int(11) unsigned DEFAULT NULL COMMENT '验收人ID',
  `acceptor_name` varchar(50) DEFAULT '' COMMENT '验收人姓名',
  `plan_execute_date` date NOT NULL COMMENT '计划执行日期',
  `actual_execute_date` datetime DEFAULT NULL COMMENT '实际执行日期',
  `status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '状态 pending待执行/in_progress执行中/completed已完成/overdue已逾期/cancelled已取消',
  `execute_start_time` datetime DEFAULT NULL COMMENT '执行开始时间',
  `execute_end_time` datetime DEFAULT NULL COMMENT '执行结束时间',
  `execute_duration` int(11) DEFAULT NULL COMMENT '执行耗时（分钟）',
  `is_notified` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否已发送到期提醒',
  `remind_count` int(11) NOT NULL DEFAULT 0 COMMENT '提醒次数',
  `cancel_reason` varchar(255) DEFAULT '' COMMENT '取消原因',
  `remark` text COMMENT '备注',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_code` (`task_code`),
  KEY `idx_plan_id` (`plan_id`),
  KEY `idx_device_id` (`device_id`),
  KEY `idx_executor_id` (`executor_id`),
  KEY `idx_status` (`status`),
  KEY `idx_plan_execute_date` (`plan_execute_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='保养任务表';

-- ============================================================
-- 二、系统参数
-- ============================================================
INSERT INTO `system_params` (`param_key`,`param_value`,`name`,`param_group`,`param_type`,`description`,`sort`,`is_sensitive`,`status`,`created_at`,`updated_at`) VALUES
('maintenance_task_advance_days','1','任务提前生成天数','device','number','任务提前生成天数',3,0,1,NOW(),NOW()),
('maintenance_remind_days','3','保养到期提醒天数','device','number','保养到期提醒天数',4,0,1,NOW(),NOW()),
('maintenance_auto_generate_time','02:00','自动生成任务时间','device','string','自动生成任务时间',5,0,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- ============================================================
-- 三、数据字典
-- ============================================================
-- 字典类型：保养任务状态
INSERT INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`) VALUES
('保养任务状态','maintenance_task_status','保养任务状态',63,1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- 字典条目：保养任务状态
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`status`,`created_at`,`updated_at`) VALUES
((SELECT id FROM dictionary_types WHERE code='maintenance_task_status'),'待执行','pending',1,1,NOW(),NOW()),
((SELECT id FROM dictionary_types WHERE code='maintenance_task_status'),'执行中','in_progress',2,1,NOW(),NOW()),
((SELECT id FROM dictionary_types WHERE code='maintenance_task_status'),'已完成','completed',3,1,NOW(),NOW()),
((SELECT id FROM dictionary_types WHERE code='maintenance_task_status'),'已逾期','overdue',4,1,NOW(),NOW()),
((SELECT id FROM dictionary_types WHERE code='maintenance_task_status'),'已取消','cancelled',5,1,NOW(),NOW());
