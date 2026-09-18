-- 196_voice_interaction.sql
-- v1.68.0 自然语言交互：4 表 + 8 预置模板 + 4 权限 + 菜单

CREATE TABLE IF NOT EXISTS `voice_command_logs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作用户ID',
  `raw_input` varchar(500) NOT NULL DEFAULT '' COMMENT '用户原始输入',
  `intent` varchar(20) DEFAULT NULL COMMENT '识别意图',
  `entities` json DEFAULT NULL COMMENT '提取的实体',
  `confidence` decimal(5,4) DEFAULT NULL COMMENT '置信度',
  `matched_template_id` int(11) DEFAULT NULL COMMENT '匹配的模板ID',
  `execution_status` tinyint(1) NOT NULL DEFAULT 0 COMMENT '0=成功 1=失败',
  `error_message` text COMMENT '错误信息',
  `response_time` int(11) DEFAULT NULL COMMENT '响应时间（毫秒）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_intent` (`intent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='自然语言指令日志表';

CREATE TABLE IF NOT EXISTS `voice_intent_templates` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `trigger_pattern` varchar(200) NOT NULL DEFAULT '' COMMENT '触发语句（支持{参数}占位符）',
  `intent_type` varchar(20) NOT NULL DEFAULT 'query' COMMENT 'query/navigate/operate/analyze/knowledge',
  `target_action` varchar(50) DEFAULT NULL COMMENT '目标动作（工具名或路由）',
  `param_mapping` json DEFAULT NULL COMMENT '参数映射',
  `response_template` text COMMENT '响应模板',
  `use_count` int(11) NOT NULL DEFAULT 0 COMMENT '使用次数',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '0=禁用 1=启用',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='自然语言指令模板表';

CREATE TABLE IF NOT EXISTS `voice_execution_history` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `command_log_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联指令日志ID',
  `tool_name` varchar(50) DEFAULT NULL COMMENT '调用的工具名称',
  `tool_params` json DEFAULT NULL COMMENT '工具参数',
  `tool_result` json DEFAULT NULL COMMENT '工具返回结果',
  `executed_at` datetime NOT NULL COMMENT '执行时间',
  PRIMARY KEY (`id`),
  KEY `idx_command_log_id` (`command_log_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='自然语言执行历史表';

CREATE TABLE IF NOT EXISTS `voice_feedback` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `command_log_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联指令日志ID',
  `user_id` int(11) NOT NULL DEFAULT 0 COMMENT '反馈用户ID',
  `feedback_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1=有用 2=无用',
  `feedback_content` text COMMENT '反馈内容',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_command_log_id` (`command_log_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='自然语言用户反馈表';

-- 预置指令模板
INSERT INTO `voice_intent_templates` (`trigger_pattern`, `intent_type`, `target_action`, `param_mapping`, `response_template`, `status`) VALUES
('查一下设备{device_id}的维修记录', 'query', 'query_repair_orders', '{"device_id": "device_id"}', '已查询设备{device_id}的维修记录，共{n}条：{list}', 1),
('查设备{device_id}', 'query', 'query_device', '{"device_id": "device_id"}', '设备{device_id}信息：{info}', 1),
('查询设备列表', 'query', 'list_devices', '{}', '共{n}台设备：{list}', 1),
('打开{page_name}', 'navigate', NULL, '{"page_name": "page_name"}', '正在跳转到{page_name}...', 1),
('创建一个{priority}维修工单', 'operate', 'create_repair_order', '{"priority": "priority"}', '已创建{priority}维修工单，编号：{order_no}', 1),
('查一下{order_id}订单', 'query', 'query_order', '{"order_id": "order_id"}', '订单{order_id}信息：{info}', 1),
('查询{status}的隐患', 'query', 'list_hazards', '{"status": "status"}', '共{n}条{status}隐患：{list}', 1),
('查一下{customer_name}的客户信息', 'query', 'query_customer', '{"customer_name": "customer_name"}', '客户{customer_name}信息：{info}', 1);

-- 权限
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`, `created_at`, `updated_at`) VALUES
('查看自然语言交互', 'ai:voice:view', 2, 0, 'ai', '', '', '', 0, 1, 1, '快捷指令中心与执行历史', NOW(), NOW()),
('自然语言查询', 'ai:voice:query', 2, 0, 'ai', '', '', '', 0, 1, 1, '查询类指令执行', NOW(), NOW()),
('自然语言操作', 'ai:voice:operate', 2, 0, 'ai', '', '', '', 0, 1, 1, '操作类指令执行', NOW(), NOW()),
('管理指令模板', 'ai:voice:admin', 2, 0, 'ai', '', '', '', 0, 1, 1, '指令模板管理页面', NOW(), NOW());

-- 菜单：AI智能平台下新增「自然语言交互」
SET @ai_top := (SELECT id FROM `menus` WHERE `permission` = 'ai:platform:view' LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`) VALUES
(@ai_top, '自然语言交互', '', 'el-icon-mic', 'ai:voice:view', 16, 1, 1, 0);
SET @vi_dir := LAST_INSERT_ID();
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`) VALUES
(@vi_dir, '快捷指令中心', '/ai/voice/commands', '', 'ai:voice:view', 1, 1, 2, 0),
(@vi_dir, '指令模板管理', '/ai/voice/templates', '', 'ai:voice:admin', 2, 1, 2, 0),
(@vi_dir, '执行历史', '/ai/voice/history', '', 'ai:voice:view', 3, 1, 2, 0);

-- 角色绑定
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code IN ('super_admin', 'admin') AND p.code IN ('ai:voice:view', 'ai:voice:query', 'ai:voice:operate', 'ai:voice:admin');
