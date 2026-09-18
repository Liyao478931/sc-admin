-- 195_agent_business.sql
-- v1.67.0 业务智能体（审批助手 + 催办智能体 + 订单处理智能体）：5 表 + 4 权限 + 菜单 + 3 智能体记录

CREATE TABLE IF NOT EXISTS `ai_agent_executions` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `agent_id` int(11) DEFAULT NULL COMMENT '智能体ID',
  `agent_code` varchar(30) NOT NULL DEFAULT '' COMMENT '智能体编码',
  `trigger_type` varchar(20) NOT NULL DEFAULT 'manual' COMMENT 'event/timer/manual',
  `input_data` json DEFAULT NULL COMMENT '输入数据',
  `decision_result` varchar(20) DEFAULT NULL COMMENT 'approved/rejected/pending',
  `execution_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0=待执行 1=执行中 2=成功 3=失败 4=需人工介入',
  `output_data` json DEFAULT NULL COMMENT '输出数据',
  `error_message` text COMMENT '错误信息',
  `executed_at` datetime DEFAULT NULL COMMENT '执行时间',
  `completed_at` datetime DEFAULT NULL COMMENT '完成时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_agent_code` (`agent_code`),
  KEY `idx_status` (`execution_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='智能体执行记录表';

CREATE TABLE IF NOT EXISTS `ai_agent_tasks` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `agent_id` int(11) DEFAULT NULL COMMENT '智能体ID',
  `task_type` varchar(30) NOT NULL DEFAULT '' COMMENT 'approval/churn/order',
  `task_target_id` int(11) NOT NULL DEFAULT 0 COMMENT '目标业务ID',
  `task_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0=待处理 1=处理中 2=已完成 3=失败',
  `priority` tinyint(1) NOT NULL DEFAULT 2 COMMENT '1=低 2=中 3=高',
  `assigned_to` int(11) DEFAULT NULL COMMENT '指派给',
  `processed_at` datetime DEFAULT NULL COMMENT '处理时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_task_type` (`task_type`),
  KEY `idx_task_status` (`task_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='智能体任务表';

CREATE TABLE IF NOT EXISTS `ai_approval_recommendations` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `approval_instance_id` int(11) NOT NULL DEFAULT 0 COMMENT '审批实例ID',
  `recommendation` varchar(10) NOT NULL DEFAULT '' COMMENT 'pass/reject/transfer',
  `confidence` varchar(10) DEFAULT NULL COMMENT 'high/medium/low',
  `reason` text COMMENT '建议理由',
  `user_accepted` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0=否 1=是',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_approval_instance_id` (`approval_instance_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='审批建议表';

CREATE TABLE IF NOT EXISTS `ai_churn_records` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `task_type` varchar(30) NOT NULL DEFAULT '' COMMENT '任务类型',
  `task_id` int(11) NOT NULL DEFAULT 0 COMMENT '任务ID',
  `task_title` varchar(200) DEFAULT '' COMMENT '任务标题（冗余）',
  `target_user_id` int(11) NOT NULL DEFAULT 0 COMMENT '目标用户ID',
  `churn_count` int(11) NOT NULL DEFAULT 1 COMMENT '催办次数',
  `churn_channel` varchar(20) DEFAULT NULL COMMENT 'inbox/sms/email',
  `churn_content` text COMMENT '催办内容',
  `is_read` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0=否 1=是',
  `is_handled` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0=否 1=是',
  `escalated_at` datetime DEFAULT NULL COMMENT '升级时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_task` (`task_type`, `task_id`),
  KEY `idx_target_user` (`target_user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='催办记录表';

CREATE TABLE IF NOT EXISTS `ai_order_process_logs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL DEFAULT 0 COMMENT '订单ID',
  `step` varchar(20) NOT NULL DEFAULT '' COMMENT 'credit_check/inventory_check/create_notice',
  `status` varchar(20) NOT NULL DEFAULT '' COMMENT 'pass/fail/pending',
  `detail` json DEFAULT NULL COMMENT '处理详情',
  `processed_at` datetime NOT NULL COMMENT '处理时间',
  PRIMARY KEY (`id`),
  KEY `idx_order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单处理日志表';

-- 权限（ai:agent:view 已存在，复用为总览权限）
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`, `created_at`, `updated_at`) VALUES
('使用审批助手', 'ai:agent:approval', 2, 0, 'ai', '', '', '', 0, 1, 1, '审批助手页面与审批操作', NOW(), NOW()),
('使用催办智能体', 'ai:agent:churn', 2, 0, 'ai', '', '', '', 0, 1, 1, '催办智能体页面与催办操作', NOW(), NOW()),
('使用订单处理智能体', 'ai:agent:order', 2, 0, 'ai', '', '', '', 0, 1, 1, '订单处理智能体页面与处理操作', NOW(), NOW()),
('配置智能体规则', 'ai:agent:configure', 2, 0, 'ai', '', '', '', 0, 1, 1, '业务智能体规则配置', NOW(), NOW());

-- 菜单：AI智能平台下新增「业务智能体」
SET @ai_top := (SELECT id FROM `menus` WHERE `permission` = 'ai:platform:view' LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`) VALUES
(@ai_top, '业务智能体', '', 'el-icon-cpu', 'ai:agent:view', 15, 1, 1, 0);
SET @ab_dir := LAST_INSERT_ID();
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`) VALUES
(@ab_dir, '智能体总览', '/ai/agents/dashboard', '', 'ai:agent:view', 1, 1, 2, 0),
(@ab_dir, '审批助手', '/ai/agents/approval', '', 'ai:agent:approval', 2, 1, 2, 0),
(@ab_dir, '催办智能体', '/ai/agents/churn', '', 'ai:agent:churn', 3, 1, 2, 0),
(@ab_dir, '订单处理智能体', '/ai/agents/order', '', 'ai:agent:order', 4, 1, 2, 0);

-- 角色绑定
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code IN ('super_admin', 'admin') AND p.code IN ('ai:agent:approval', 'ai:agent:churn', 'ai:agent:order', 'ai:agent:configure');

-- 3 个业务智能体记录（ai_agents）
INSERT INTO `ai_agents` (`agent_id`, `agent_name`, `agent_icon`, `description`, `system_prompt`, `tool_ids`, `is_system`, `status`, `sort`, `created_by`, `create_time`, `update_time`) VALUES
('sys_agent_approval', '审批助手', '📋', '自动识别待办审批紧急度，基于历史数据推荐审批意见，支持批量审批建议与超时提醒', '你是审批助手，帮助审批人快速决策：分析审批紧急度（等待时间/金额），基于历史通过率推荐意见（通过/驳回/转办），给出依据。', '[24,40,36,10,29]', 1, 1, 1, 0, NOW(), NOW()),
('sys_agent_churn', '催办智能体', '⏰', '自动检测超时任务（维修/巡检/采购/审批/发货），判断紧急度，多渠道推送催办并跟踪效果', '你是催办智能体，检测超时任务并生成催办通知，判断紧急程度，记录催办次数并在达阈值时升级。', '[14,19,49,24,29]', 1, 1, 2, 0, NOW(), NOW()),
('sys_agent_order', '订单处理智能体', '📦', '自动完成新订单信用审核、库存检查、生成发货通知，异常订单标记并通知', '你是订单处理智能体，对新订单自动执行信用审核（额度使用率<80%通过）、库存检查（充足锁定/不足待补货）、生成发货通知。', '[41,36,25,22,29]', 1, 1, 3, 0, NOW(), NOW());
