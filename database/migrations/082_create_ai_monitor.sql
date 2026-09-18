-- =====================================================
-- 082_create_ai_monitor.sql
-- AI 智能平台：运营中心 → 监控告警
--   1. 三张核心表：ai_alert_rules / ai_alert_history / ai_alert_notifications
--   2. 数据字典（监控指标/比较运算符/告警级别/告警状态）
--   3. 系统参数（检查间隔/保留天数/自动恢复窗口/升级时间）
--   4. 权限定义与超级管理员授权
--   5. 菜单（启用 078 预留的「监控告警」子菜单）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、三张核心表 ==========
CREATE TABLE IF NOT EXISTS `ai_alert_rules` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `rule_id` varchar(32) NOT NULL DEFAULT '' COMMENT '规则唯一标识(UUID)',
  `rule_name` varchar(100) NOT NULL DEFAULT '' COMMENT '规则名称',
  `metric` varchar(50) NOT NULL DEFAULT '' COMMENT '监控指标：error_rate/response_time/call_count/token_consumption/service_availability/cpu_usage/memory_usage',
  `operator` varchar(10) NOT NULL DEFAULT '>' COMMENT '比较运算符：>/>=/</<=/==',
  `threshold` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '阈值',
  `duration` int(11) NOT NULL DEFAULT 1 COMMENT '持续时间（分钟），指标持续异常N分钟后触发',
  `level` varchar(20) NOT NULL DEFAULT 'info' COMMENT '告警级别：info/warning/critical/emergency',
  `channels` json NOT NULL COMMENT '通知渠道列表（["inbox","email","dingtalk","workwx"]）',
  `receivers` json DEFAULT NULL COMMENT '接收人ID列表',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `description` varchar(255) DEFAULT NULL COMMENT '描述说明',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_rule_id` (`rule_id`),
  KEY `idx_metric` (`metric`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI告警规则表';

CREATE TABLE IF NOT EXISTS `ai_alert_history` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `alert_id` varchar(32) NOT NULL DEFAULT '' COMMENT '告警唯一标识(UUID)',
  `rule_id` varchar(32) NOT NULL DEFAULT '' COMMENT '规则ID（关联 ai_alert_rules）',
  `rule_name` varchar(100) NOT NULL DEFAULT '' COMMENT '规则名称（冗余）',
  `metric` varchar(50) NOT NULL DEFAULT '' COMMENT '监控指标（冗余）',
  `level` varchar(20) NOT NULL DEFAULT 'info' COMMENT '告警级别',
  `current_value` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '触发时指标值',
  `threshold` decimal(10,2) NOT NULL DEFAULT 0 COMMENT '阈值',
  `message` varchar(500) DEFAULT NULL COMMENT '告警消息',
  `trigger_time` datetime NOT NULL COMMENT '触发时间',
  `recover_time` datetime DEFAULT NULL COMMENT '恢复时间',
  `status` varchar(20) NOT NULL DEFAULT 'triggered' COMMENT '状态：triggered/confirmed/recovered',
  `notified` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否已通知：1是0否',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_alert_id` (`alert_id`),
  KEY `idx_rule_id` (`rule_id`),
  KEY `idx_status_create` (`status`, `create_time`),
  KEY `idx_trigger_time` (`trigger_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI告警历史表';

CREATE TABLE IF NOT EXISTS `ai_alert_notifications` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `alert_id` varchar(32) NOT NULL DEFAULT '' COMMENT '告警ID（关联 ai_alert_history）',
  `channel` varchar(20) NOT NULL DEFAULT 'inbox' COMMENT '通知渠道：inbox/email/dingtalk/workwx',
  `receiver_id` int(11) NOT NULL DEFAULT 0 COMMENT '接收人ID',
  `receiver_name` varchar(50) NOT NULL DEFAULT '' COMMENT '接收人姓名（冗余）',
  `send_time` datetime DEFAULT NULL COMMENT '发送时间',
  `send_status` varchar(20) NOT NULL DEFAULT 'success' COMMENT '发送状态：success/failed',
  `error_message` text COMMENT '错误信息',
  `create_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_alert_id` (`alert_id`),
  KEY `idx_receiver_id` (`receiver_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI告警通知记录表';

-- ========== 二、数据字典 ==========

-- 1. alert_metric 监控指标
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('监控指标','alert_metric','AI监控告警指标',80,1,NOW(),NOW());
SET @dm1 = (SELECT `id` FROM `dictionary_types` WHERE `code`='alert_metric' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dm1,'错误率','error_rate',1,'',1,NOW(),NOW()),
(@dm1,'响应时间','response_time',2,'',1,NOW(),NOW()),
(@dm1,'调用次数','call_count',3,'',1,NOW(),NOW()),
(@dm1,'Token消耗','token_consumption',4,'',1,NOW(),NOW()),
(@dm1,'服务可用性','service_availability',5,'',1,NOW(),NOW()),
(@dm1,'CPU使用率','cpu_usage',6,'',1,NOW(),NOW()),
(@dm1,'内存使用率','memory_usage',7,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 2. alert_operator 比较运算符
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('比较运算符','alert_operator','告警条件比较运算符',81,1,NOW(),NOW());
SET @dm2 = (SELECT `id` FROM `dictionary_types` WHERE `code`='alert_operator' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dm2,'大于','>',1,'',1,NOW(),NOW()),
(@dm2,'大于等于','>=',2,'',1,NOW(),NOW()),
(@dm2,'小于','<',3,'',1,NOW(),NOW()),
(@dm2,'小于等于','<=',4,'',1,NOW(),NOW()),
(@dm2,'等于','==',5,'',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 3. alert_level 告警级别
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('告警级别','alert_level','AI告警级别',82,1,NOW(),NOW());
SET @dm3 = (SELECT `id` FROM `dictionary_types` WHERE `code`='alert_level' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dm3,'提示','info',1,'primary',1,NOW(),NOW()),
(@dm3,'一般','warning',2,'success',1,NOW(),NOW()),
(@dm3,'重要','critical',3,'warning',1,NOW(),NOW()),
(@dm3,'紧急','emergency',4,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 4. alert_status 告警状态
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('告警状态','alert_status','AI告警状态',83,1,NOW(),NOW());
SET @dm4 = (SELECT `id` FROM `dictionary_types` WHERE `code`='alert_status' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dm4,'触发中','triggered',1,'danger',1,NOW(),NOW()),
(@dm4,'已确认','confirmed',2,'warning',1,NOW(),NOW()),
(@dm4,'已恢复','recovered',3,'success',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- ========== 三、系统参数 ==========
INSERT INTO `system_params` (`param_key`,`name`,`param_value`,`param_type`,`param_group`,`description`,`sort`,`status`,`is_sensitive`,`created_at`,`updated_at`) VALUES
('ai_alert_check_interval','告警检查间隔（秒）','60','number','ai','告警检测定时任务执行间隔（秒）',20,1,0,NOW(),NOW()),
('ai_alert_retention_days','告警历史保留天数','90','number','ai','告警历史数据保留天数，超出自动清理',21,1,0,NOW(),NOW()),
('ai_alert_auto_recover_minutes','自动恢复检测窗口（分钟）','5','number','ai','指标恢复正常持续N分钟后自动恢复告警',22,1,0,NOW(),NOW()),
('ai_alert_emergency_escalate_minutes','紧急告警升级时间（分钟）','30','number','ai','紧急告警持续N分钟未处理自动升级通知',23,1,0,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`param_value`=VALUES(`param_value`),`param_type`=VALUES(`param_type`),`param_group`=VALUES(`param_group`),`description`=VALUES(`description`),`sort`=VALUES(`sort`),`updated_at`=NOW();

-- ========== 四、权限定义与授权 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('监控告警','ai:operation:monitor',1,0,'ai','/ai/operation/monitor','el-icon-bell',NULL,1,1,1,'AI监控告警菜单/查看',NOW(),NOW()),
('监控告警编辑','ai:operation:monitor:edit',2,0,'ai',NULL,NULL,NULL,2,1,1,'管理告警规则/确认告警',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('ai:operation:monitor','ai:operation:monitor:edit');

-- ========== 五、菜单（启用 078 预留的「监控告警」子菜单并更新权限） ==========
-- 更新预留菜单：启用 + 更新权限与图标
UPDATE `menus` SET `status`=1, `permission`='ai:operation:monitor', `icon`='el-icon-bell'
WHERE `name`='监控告警' AND `permission`='ai:operation:view' AND `deleted_at` IS NULL;

-- 兜底：若不存在则新建（AI智能平台 → 运营中心 → 监控告警）
SET @ai_operation_id = (SELECT id FROM menus WHERE permission='ai:operation:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @ai_operation_id, '监控告警', '/ai/operation/monitor', 'el-icon-bell', 'ai:operation:monitor', 20, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:operation:monitor' AND deleted_at IS NULL);
