-- =====================================================
-- 078_create_ai_usage.sql
-- AI 智能平台：运营中心（用量统计）
--   1. 应用调用日志表 ai_app_call_logs
--   2. API密钥调用日志表 ai_api_key_call_logs
--   3. 权限（ai:operation 系列）
--   4. 菜单（AI智能平台 → 运营中心 → 用量统计）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、应用调用日志表 ==========
CREATE TABLE IF NOT EXISTS `ai_app_call_logs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `log_id` varchar(32) NOT NULL DEFAULT '' COMMENT '日志唯一标识(UUID)',
  `app_id` varchar(32) NOT NULL DEFAULT '' COMMENT '应用ID',
  `app_name` varchar(100) NOT NULL DEFAULT '' COMMENT '应用名称（冗余）',
  `api_key_id` int(11) DEFAULT NULL COMMENT 'API密钥ID',
  `caller_id` int(11) DEFAULT NULL COMMENT '调用人ID',
  `caller_ip` varchar(50) NOT NULL DEFAULT '' COMMENT '调用人IP',
  `request_path` varchar(255) NOT NULL DEFAULT '' COMMENT '请求路径',
  `duration` int(11) DEFAULT NULL COMMENT '耗时（毫秒）',
  `status` varchar(20) NOT NULL DEFAULT 'success' COMMENT '状态：success/error',
  `error_message` text COMMENT '错误信息',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_log_id` (`log_id`),
  KEY `idx_app_create` (`app_id`, `create_time`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI应用调用日志表';

-- ========== 二、API密钥调用日志表 ==========
CREATE TABLE IF NOT EXISTS `ai_api_key_call_logs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `log_id` varchar(32) NOT NULL DEFAULT '' COMMENT '日志唯一标识(UUID)',
  `key_id` int(11) NOT NULL DEFAULT 0 COMMENT 'API密钥ID',
  `key_name` varchar(100) NOT NULL DEFAULT '' COMMENT '密钥名称（冗余）',
  `app_id` varchar(32) NOT NULL DEFAULT '' COMMENT '应用ID',
  `caller_ip` varchar(50) NOT NULL DEFAULT '' COMMENT '调用人IP',
  `request_path` varchar(255) NOT NULL DEFAULT '' COMMENT '请求路径',
  `duration` int(11) DEFAULT NULL COMMENT '耗时（毫秒）',
  `status` varchar(20) NOT NULL DEFAULT 'success' COMMENT '状态：success/error',
  `error_message` text COMMENT '错误信息',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_log_id` (`log_id`),
  KEY `idx_key_create` (`key_id`, `create_time`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI API密钥调用日志表';

-- ========== 三、权限 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`)
VALUES
  ('运营中心', 'ai:operation:view', 1, 0, 'ai', '/ai/operation/usage', 'el-icon-data-line', NULL, 0, 1, 1, 'AI运营中心目录'),
  ('用量统计', 'ai:operation:usage', 1, 0, 'ai', '/ai/operation/usage', 'el-icon-data-line', NULL, 0, 1, 1, 'AI用量统计菜单/查看'),
  ('用量统计导出', 'ai:operation:usage:export', 2, 0, 'ai', '/ai/operation/usage', NULL, NULL, 1, 1, 1, '导出用量统计报表')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `type`=VALUES(`type`), `module`=VALUES(`module`),
  `path`=VALUES(`path`), `icon`=VALUES(`icon`), `sort`=VALUES(`sort`), `status`=VALUES(`status`), `updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code='super_admin' AND p.code IN ('ai:operation:view','ai:operation:usage','ai:operation:usage:export');

-- ========== 四、菜单 ==========
-- AI智能平台（顶级，已存在则跳过）
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT 0, 'AI智能平台', '', 'el-icon-cpu', 'ai:platform:view', 60, 1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:platform:view' AND deleted_at IS NULL);

-- 运营中心（目录）
SET @ai_platform_id = (SELECT id FROM menus WHERE permission='ai:platform:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_platform_id, '运营中心', '', 'el-icon-data-line', 'ai:operation:view', 20, 1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:operation:view' AND deleted_at IS NULL);

-- 用量统计（子菜单）
SET @ai_operation_id = (SELECT id FROM menus WHERE permission='ai:operation:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_operation_id, '用量统计', '/ai/operation/usage', 'el-icon-data-line', 'ai:operation:usage', 10, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:operation:usage' AND deleted_at IS NULL);

-- 监控告警（预留）
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_operation_id, '监控告警', '/ai/operation/monitor', 'el-icon-monitor', 'ai:operation:view', 20, 0, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='监控告警' AND parent_id=@ai_operation_id AND deleted_at IS NULL);

-- 操作审计（预留）
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_operation_id, '操作审计', '/ai/operation/audit', 'el-icon-document-copy', 'ai:operation:view', 30, 0, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE name='操作审计' AND parent_id=@ai_operation_id AND deleted_at IS NULL);
