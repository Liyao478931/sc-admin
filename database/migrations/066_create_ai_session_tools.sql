-- =====================================================
-- 066_create_ai_session_tools.sql
-- AI 智能平台：新建对话升级（工具调用能力）
--   1. 会话可用工具表 ai_session_tools
--   2. ai_chat_messages 新增工具展示/结果/状态字段
--   3. 种子数据：内置业务工具写入 ai_tools（query_device 等 5 个）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、会话可用工具表 ==========
CREATE TABLE IF NOT EXISTS `ai_session_tools` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `session_id` varchar(32) NOT NULL DEFAULT '' COMMENT '会话ID（关联 ai_chat_sessions.session_id）',
  `tool_id` int(11) NOT NULL DEFAULT 0 COMMENT '工具ID（关联 ai_tools.id）',
  `enabled` tinyint(1) NOT NULL DEFAULT 1 COMMENT '是否启用：1启用 0停用',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_session_tool` (`session_id`, `tool_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI会话可用工具表';

-- ========== 二、ai_chat_messages 新增字段（幂等：仅不存在时添加） ==========
SET @has_col1 = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='ai_chat_messages' AND COLUMN_NAME='tool_calls_display');
SET @sql1 = IF(@has_col1 = 0,
  'ALTER TABLE `ai_chat_messages` ADD COLUMN `tool_calls_display` json DEFAULT NULL COMMENT ''工具调用展示数据(JSON)''',
  'SELECT 1');
PREPARE stmt1 FROM @sql1; EXECUTE stmt1; DEALLOCATE PREPARE stmt1;

SET @has_col2 = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='ai_chat_messages' AND COLUMN_NAME='tool_call_results');
SET @sql2 = IF(@has_col2 = 0,
  'ALTER TABLE `ai_chat_messages` ADD COLUMN `tool_call_results` json DEFAULT NULL COMMENT ''工具调用结果(JSON)''',
  'SELECT 1');
PREPARE stmt2 FROM @sql2; EXECUTE stmt2; DEALLOCATE PREPARE stmt2;

SET @has_col3 = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='ai_chat_messages' AND COLUMN_NAME='tool_call_status');
SET @sql3 = IF(@has_col3 = 0,
  'ALTER TABLE `ai_chat_messages` ADD COLUMN `tool_call_status` varchar(20) DEFAULT NULL COMMENT ''工具调用状态：pending/executing/success/failed/cancelled''',
  'SELECT 1');
PREPARE stmt3 FROM @sql3; EXECUTE stmt3; DEALLOCATE PREPARE stmt3;

-- ========== 三、种子数据：内置业务工具写入 ai_tools ==========
INSERT INTO `ai_tools`
  (`tool_name`, `tool_display_name`, `category`, `description`, `method`, `api_path`,
   `headers`, `params_schema`, `response_schema`, `requires_confirm`, `timeout`, `retry_count`, `call_count`, `status`, `sort`)
VALUES
  ('query_device', '查询设备', 'device',
   '根据关键词查询设备信息（设备编码、名称、位置、状态），支持按编码或名称模糊搜索',
   'GET', 'builtin://query_device', NULL,
   '{"type":"object","properties":{"keyword":{"type":"string","title":"关键词","description":"设备编码或名称关键词，留空查询最近10台"}}}',
   NULL, 0, 30, 1, 0, 1, 1),
  ('query_hazard', '查询安全隐患', 'safety',
   '查询安全隐患列表，可按状态筛选（pending待整改/processing整改中/resolved已整改）',
   'GET', 'builtin://query_hazard', NULL,
   '{"type":"object","properties":{"status":{"type":"string","title":"状态","description":"隐患状态，留空查询最近10条"}}}',
   NULL, 0, 30, 1, 0, 1, 2),
  ('create_repair_order', '创建维修工单', 'device',
   '根据设备ID和故障描述创建维修工单（高风险写操作，需用户确认）',
   'POST', 'builtin://create_repair_order', NULL,
   '{"type":"object","required":["device_id","description"],"properties":{"device_id":{"type":"integer","title":"设备ID","description":"目标设备ID"},"description":{"type":"string","title":"故障描述","description":"故障现象描述"}}}',
   NULL, 1, 30, 1, 0, 1, 3),
  ('query_todo', '查询待办事项', 'common',
   '查询当前用户的待办事项统计',
   'GET', 'builtin://query_todo', NULL,
   '{"type":"object","properties":{}}',
   NULL, 0, 30, 1, 0, 1, 4),
  ('query_attendance', '查询考勤记录', 'hr',
   '查询最近N天的考勤打卡记录（日期、时间、结果、类型）',
   'GET', 'builtin://query_attendance', NULL,
   '{"type":"object","properties":{"days":{"type":"integer","title":"天数","description":"查询最近N天，默认7天，最大30天","default":7}}}',
   NULL, 0, 30, 1, 0, 1, 5)
ON DUPLICATE KEY UPDATE
  `tool_display_name`=VALUES(`tool_display_name`), `category`=VALUES(`category`),
  `description`=VALUES(`description`), `method`=VALUES(`method`), `api_path`=VALUES(`api_path`),
  `params_schema`=VALUES(`params_schema`), `requires_confirm`=VALUES(`requires_confirm`),
  `status`=VALUES(`status`), `sort`=VALUES(`sort`), `update_time`=NOW();
