-- =====================================================
-- 063_create_ai_tools.sql
-- AI 智能平台：工具列表功能
--   1. 工具表 ai_tools
--   2. 工具调用日志表 ai_tool_call_logs
--   3. 权限（ai:tools 系列）
--   4. 菜单（AI智能平台 → 工具中心 → 工具列表）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、工具表 ==========
CREATE TABLE IF NOT EXISTS `ai_tools` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `tool_name` varchar(100) NOT NULL DEFAULT '' COMMENT '工具名称（供AI识别调用，唯一）',
  `tool_display_name` varchar(100) NOT NULL DEFAULT '' COMMENT '工具显示名称（前端展示）',
  `category` varchar(30) NOT NULL DEFAULT 'common' COMMENT '分类：device/safety/hr/warehouse/common',
  `description` text COMMENT '工具描述（供AI理解用途）',
  `method` varchar(10) NOT NULL DEFAULT 'GET' COMMENT '请求方法：GET/POST/PUT/DELETE',
  `api_path` varchar(255) NOT NULL DEFAULT '' COMMENT 'API路径',
  `headers` json DEFAULT NULL COMMENT '请求头配置(JSON)',
  `params_schema` json DEFAULT NULL COMMENT '参数定义(JSON Schema)',
  `response_schema` json DEFAULT NULL COMMENT '返回格式定义(JSON)',
  `requires_confirm` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否需要人工确认：1是 0否',
  `timeout` int(11) NOT NULL DEFAULT 30 COMMENT '超时时间（秒）',
  `call_count` int(11) NOT NULL DEFAULT 0 COMMENT '调用次数',
  `last_call_time` datetime DEFAULT NULL COMMENT '最后调用时间',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_tool_name` (`tool_name`),
  KEY `idx_category` (`category`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI工具表';

-- ========== 二、工具调用日志表 ==========
CREATE TABLE IF NOT EXISTS `ai_tool_call_logs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `tool_id` int(11) NOT NULL DEFAULT 0 COMMENT '工具ID',
  `tool_name` varchar(100) NOT NULL DEFAULT '' COMMENT '工具名称',
  `params` text COMMENT '请求参数(JSON)',
  `result` text COMMENT '响应结果',
  `status_code` int(11) DEFAULT NULL COMMENT '状态码',
  `success` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否成功：1成功 0失败',
  `error_msg` varchar(500) NOT NULL DEFAULT '' COMMENT '错误信息',
  `elapsed_ms` int(11) NOT NULL DEFAULT 0 COMMENT '耗时（毫秒）',
  `operator_id` int(11) NOT NULL DEFAULT 0 COMMENT '操作人ID',
  `operator_name` varchar(100) NOT NULL DEFAULT '' COMMENT '操作人名称',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '调用时间',
  PRIMARY KEY (`id`),
  KEY `idx_tool_id` (`tool_id`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI工具调用日志表';

-- ========== 三、权限 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`)
VALUES
  ('AI智能平台', 'ai:platform:view', 1, 0, 'ai', '/ai/dashboard', 'el-icon-cpu', NULL, 0, 1, 1, 'AI智能平台顶级目录'),
  ('工具中心', 'ai:tools:view', 1, 0, 'ai', '/ai/tools/list', 'el-icon-s-tools', NULL, 0, 1, 1, 'AI工具中心目录'),
  ('系统设置', 'ai:settings:view', 1, 0, 'ai', '/ai/settings/model', 'el-icon-setting', NULL, 0, 1, 1, 'AI系统设置目录'),
  ('工具列表', 'ai:tools:list', 1, 0, 'ai', '/ai/tools/list', 'el-icon-s-tools', NULL, 1, 1, 1, 'AI工具列表菜单'),
  ('工具编辑', 'ai:tools:edit', 2, 0, 'ai', '/ai/tools/list', NULL, NULL, 2, 1, 1, '启用/停用工具'),
  ('工具测试', 'ai:tools:test', 2, 0, 'ai', '/ai/tools/list', NULL, NULL, 3, 1, 1, '测试工具连接')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `type`=VALUES(`type`), `module`=VALUES(`module`),
  `path`=VALUES(`path`), `icon`=VALUES(`icon`), `sort`=VALUES(`sort`), `status`=VALUES(`status`), `updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code='super_admin' AND p.code IN ('ai:platform:view','ai:tools:view','ai:settings:view','ai:tools:list','ai:tools:edit','ai:tools:test');

-- ========== 四、菜单 ==========
-- AI智能平台（顶级）
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT 0, 'AI智能平台', '', 'el-icon-cpu', 'ai:platform:view', 60, 1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:platform:view' AND deleted_at IS NULL);

-- 工具中心（目录）
SET @ai_platform_id = (SELECT id FROM menus WHERE permission='ai:platform:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_platform_id, '工具中心', '', 'el-icon-s-tools', 'ai:tools:view', 40, 1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:tools:view' AND deleted_at IS NULL);

-- 工具列表（子菜单）
SET @ai_tools_id = (SELECT id FROM menus WHERE permission='ai:tools:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_tools_id, '工具列表', '/ai/tools/list', 'el-icon-s-tools', 'ai:tools:list', 10, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:tools:list' AND deleted_at IS NULL);
