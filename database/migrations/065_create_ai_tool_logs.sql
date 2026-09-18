-- =====================================================
-- 065_create_ai_tool_logs.sql
-- AI 智能平台：调用日志功能
--   1. 重建 ai_tool_call_logs（完整字段：log_id/session/request_size/source/软删除）
--   2. 系统参数（保留天数/自动清理/响应体上限）
--   3. 权限（ai:tools:logs 系列）
--   4. 菜单（工具中心 → 调用日志）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、重建调用日志表 ==========
DROP TABLE IF EXISTS `ai_tool_call_logs`;
CREATE TABLE `ai_tool_call_logs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `log_id` varchar(32) NOT NULL DEFAULT '' COMMENT '日志唯一标识（UUID去横线）',
  `tool_id` int(11) DEFAULT NULL COMMENT '工具ID',
  `tool_name` varchar(100) NOT NULL DEFAULT '' COMMENT '工具名称（冗余）',
  `session_id` varchar(32) DEFAULT NULL COMMENT '会话ID',
  `user_id` int(11) NOT NULL DEFAULT 0 COMMENT '调用人ID',
  `user_name` varchar(50) NOT NULL DEFAULT '' COMMENT '调用人姓名',
  `method` varchar(10) NOT NULL DEFAULT 'GET' COMMENT '请求方法',
  `api_path` varchar(255) NOT NULL DEFAULT '' COMMENT 'API路径',
  `request_headers` json DEFAULT NULL COMMENT '请求头(JSON)',
  `request_params` json DEFAULT NULL COMMENT '请求参数(JSON)',
  `response_status` int(11) DEFAULT NULL COMMENT '响应状态码',
  `response_headers` json DEFAULT NULL COMMENT '响应头(JSON)',
  `response_body` text COMMENT '响应体（超1MB自动截断）',
  `duration` int(11) DEFAULT NULL COMMENT '耗时（毫秒）',
  `request_size` int(11) NOT NULL DEFAULT 0 COMMENT '请求大小（字节）',
  `response_size` int(11) NOT NULL DEFAULT 0 COMMENT '响应大小（字节）',
  `status` varchar(20) NOT NULL DEFAULT 'success' COMMENT '状态：success/error/timeout',
  `error_message` text COMMENT '错误信息',
  `source` varchar(20) NOT NULL DEFAULT 'chat' COMMENT '来源：chat/test/workflow',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_log_id` (`log_id`),
  KEY `idx_tool_create` (`tool_id`, `create_time`),
  KEY `idx_user_create` (`user_id`, `create_time`),
  KEY `idx_status_create` (`status`, `create_time`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI工具调用日志表';

-- ========== 二、系统参数 ==========
INSERT INTO `system_params`
  (`param_key`, `param_value`, `name`, `param_group`, `param_type`, `description`, `sort`, `is_sensitive`, `status`)
VALUES
  ('ai_log_retention_days', '90', '调用日志保留天数', 'ai', 'number', '超过此天数的日志将被自动清理', 10, 0, 1),
  ('ai_log_auto_clean_enabled', 'true', '启用自动清理', 'ai', 'switch', '是否启用定时自动清理日志', 11, 0, 1),
  ('ai_log_response_body_max_size', '1024', '响应体最大存储大小（KB）', 'ai', 'number', '超过此大小的响应体将被截断存储', 12, 0, 1)
ON DUPLICATE KEY UPDATE
  `param_value`=VALUES(`param_value`), `name`=VALUES(`name`), `param_group`=VALUES(`param_group`),
  `param_type`=VALUES(`param_type`), `description`=VALUES(`description`), `sort`=VALUES(`sort`), `status`=VALUES(`status`), `updated_at`=NOW();

-- ========== 三、权限 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`)
VALUES
  ('调用日志', 'ai:tools:logs', 1, 0, 'ai', '/ai/tools/logs', 'el-icon-document', NULL, 1, 1, 1, 'AI工具调用日志菜单'),
  ('调用日志-导出', 'ai:tools:logs:export', 2, 0, 'ai', '/ai/tools/logs', NULL, NULL, 2, 1, 1, '导出日志'),
  ('调用日志-删除', 'ai:tools:logs:delete', 2, 0, 'ai', '/ai/tools/logs', NULL, NULL, 3, 1, 1, '删除日志')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `type`=VALUES(`type`), `module`=VALUES(`module`),
  `path`=VALUES(`path`), `icon`=VALUES(`icon`), `sort`=VALUES(`sort`), `status`=VALUES(`status`), `updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code='super_admin' AND p.code IN ('ai:tools:logs','ai:tools:logs:export','ai:tools:logs:delete');

-- ========== 四、菜单 ==========
-- 工具中心（目录，已存在则跳过）
SET @ai_tools_id = (SELECT id FROM menus WHERE permission='ai:tools:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_tools_id, '调用日志', '/ai/tools/logs', 'el-icon-document', 'ai:tools:logs', 40, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:tools:logs' AND deleted_at IS NULL);
