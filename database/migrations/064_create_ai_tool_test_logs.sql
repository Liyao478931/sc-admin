-- =====================================================
-- 064_create_ai_tool_test_logs.sql
-- AI 智能平台：工具测试功能
--   1. 工具测试日志表 ai_tool_test_logs（独立于调用日志，用于测试历史）
-- 幂等写法，可重复执行
-- =====================================================

CREATE TABLE IF NOT EXISTS `ai_tool_test_logs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `tool_id` int(11) NOT NULL DEFAULT 0 COMMENT '工具ID',
  `tool_name` varchar(100) NOT NULL DEFAULT '' COMMENT '工具名称（冗余）',
  `request_params` json DEFAULT NULL COMMENT '请求参数(JSON)',
  `request_headers` json DEFAULT NULL COMMENT '请求头(JSON)',
  `response_status` int(11) DEFAULT NULL COMMENT '响应状态码',
  `response_time` int(11) NOT NULL DEFAULT 0 COMMENT '响应时间（毫秒）',
  `response_body` text COMMENT '响应体（完整内容）',
  `response_headers` json DEFAULT NULL COMMENT '响应头(JSON)',
  `error_message` text COMMENT '错误信息',
  `status` varchar(20) NOT NULL DEFAULT 'success' COMMENT '状态：success成功/error错误/timeout超时',
  `tester_id` int(11) NOT NULL DEFAULT 0 COMMENT '测试人ID',
  `tester_name` varchar(50) NOT NULL DEFAULT '' COMMENT '测试人姓名',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  KEY `idx_tool_id` (`tool_id`),
  KEY `idx_tool_create` (`tool_id`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI工具测试日志表';
