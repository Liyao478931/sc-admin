-- =====================================================
-- 060_create_ai_chat.sql
-- AI 智能平台：新建对话模块
--   1. 会话表 ai_chat_sessions（含软删除）
--   2. 消息表 ai_chat_messages
--   3. 权限（ai:chat:list/create/delete）
--   4. 菜单（AI智能平台 → 对话中心 → 新建对话 / 对话历史）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、对话会话表 ==========
CREATE TABLE IF NOT EXISTS `ai_chat_sessions` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `session_id` varchar(32) NOT NULL DEFAULT '' COMMENT '会话唯一标识（UUID去横线）',
  `user_id` int(11) NOT NULL DEFAULT 0 COMMENT '用户ID',
  `title` varchar(100) NOT NULL DEFAULT '新对话' COMMENT '会话标题',
  `tool_call_count` int(11) NOT NULL DEFAULT 0 COMMENT '工具调用次数',
  `total_tokens` int(11) NOT NULL DEFAULT 0 COMMENT 'Token消耗总数',
  `status` varchar(20) NOT NULL DEFAULT 'active' COMMENT '状态：active活跃/archived已归档',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_session_id` (`session_id`),
  KEY `idx_user_update` (`user_id`, `update_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI对话会话表';

-- ========== 二、对话消息表 ==========
CREATE TABLE IF NOT EXISTS `ai_chat_messages` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `session_id` varchar(32) NOT NULL DEFAULT '' COMMENT '会话ID',
  `message_id` varchar(32) NOT NULL DEFAULT '' COMMENT '消息唯一标识（UUID去横线）',
  `role` varchar(20) NOT NULL DEFAULT '' COMMENT '角色：user/assistant/system/tool',
  `content` text COMMENT '消息内容',
  `reasoning_content` text NULL COMMENT 'DeepSeek思考内容（需原样回传）',
  `tool_calls` json DEFAULT NULL COMMENT '工具调用记录(JSON)',
  `tool_call_id` varchar(50) DEFAULT NULL COMMENT '工具调用ID',
  `status` varchar(20) NOT NULL DEFAULT 'completed' COMMENT '状态：pending/completed/error',
  `token_count` int(11) NOT NULL DEFAULT 0 COMMENT 'Token消耗数',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_message_id` (`message_id`),
  KEY `idx_session_create` (`session_id`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI对话消息表';

-- ========== 三、权限 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`)
VALUES
  ('对话列表', 'ai:chat:list', 1, 0, 'ai', '/ai/chat/history', 'el-icon-chat-dot-round', NULL, 1, 1, 1, 'AI对话历史菜单'),
  ('新建对话', 'ai:chat:create', 2, 0, 'ai', '/ai/chat/create', NULL, NULL, 2, 1, 1, '发起新对话'),
  ('删除对话', 'ai:chat:delete', 2, 0, 'ai', '/ai/chat/history', NULL, NULL, 3, 1, 1, '删除对话会话')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `type`=VALUES(`type`), `module`=VALUES(`module`),
  `path`=VALUES(`path`), `icon`=VALUES(`icon`), `sort`=VALUES(`sort`), `status`=VALUES(`status`), `updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code='super_admin' AND p.code IN ('ai:chat:list','ai:chat:create','ai:chat:delete');

-- ========== 四、菜单 ==========
-- AI智能平台（顶级目录，已存在则跳过）
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT 0, 'AI智能平台', '', 'el-icon-cpu', 'ai:platform:view', 60, 1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:platform:view' AND deleted_at IS NULL);

-- 对话中心（目录）
SET @ai_platform_id = (SELECT id FROM menus WHERE permission='ai:platform:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_platform_id, '对话中心', '', 'el-icon-chat-dot-round', 'ai:chat:list', 10, 1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:chat:list' AND deleted_at IS NULL);

-- 新建对话（子菜单）
SET @ai_chat_id = (SELECT id FROM menus WHERE permission='ai:chat:list' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_chat_id, '新建对话', '/ai/chat/create', 'el-icon-edit-outline', 'ai:chat:create', 10, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:chat:create' AND deleted_at IS NULL);

-- 对话历史（子菜单）
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_chat_id, '对话历史', '/ai/chat/history', 'el-icon-time', 'ai:chat:list', 20, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:chat:list' AND path='/ai/chat/history' AND deleted_at IS NULL);
