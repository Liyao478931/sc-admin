-- =====================================================
-- 076_create_ai_apps.sql
-- AI 智能平台：应用中心（应用列表）
--   1. 应用表 ai_apps
--   2. 权限（ai:app 系列）
--   3. 菜单（AI智能平台 → 应用中心 → 应用列表）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、应用表 ==========
CREATE TABLE IF NOT EXISTS `ai_apps` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `app_id` varchar(32) NOT NULL DEFAULT '' COMMENT '应用唯一标识(UUID)',
  `app_name` varchar(100) NOT NULL DEFAULT '' COMMENT '应用名称',
  `app_type` varchar(20) NOT NULL DEFAULT 'chat' COMMENT '应用类型：agent/workflow/chat',
  `description` varchar(255) NOT NULL DEFAULT '' COMMENT '应用描述',
  `config` json NOT NULL COMMENT '应用配置（agent存agent_id；workflow存workflow_id；chat存model_id/system_prompt等）',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `call_count` int(11) NOT NULL DEFAULT 0 COMMENT '调用次数',
  `last_call_time` datetime DEFAULT NULL COMMENT '最后调用时间',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_app_id` (`app_id`),
  KEY `idx_creator_create` (`created_by`, `create_time`),
  KEY `idx_status` (`status`),
  KEY `idx_app_type` (`app_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI应用表';

-- ========== 二、权限 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`)
VALUES
  ('应用中心', 'ai:app:view', 1, 0, 'ai', '/ai/app/list', 'el-icon-apps', NULL, 0, 1, 1, 'AI应用中心目录'),
  ('应用列表', 'ai:app:list', 1, 0, 'ai', '/ai/app/list', 'el-icon-apps', NULL, 0, 1, 1, 'AI应用列表菜单'),
  ('创建应用', 'ai:app:add', 2, 0, 'ai', '/ai/app/create', NULL, NULL, 1, 1, 1, '创建/复制应用'),
  ('编辑应用', 'ai:app:edit', 2, 0, 'ai', '/ai/app/list', NULL, NULL, 2, 1, 1, '编辑/启停应用'),
  ('删除应用', 'ai:app:delete', 2, 0, 'ai', '/ai/app/list', NULL, NULL, 3, 1, 1, '删除应用')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `type`=VALUES(`type`), `module`=VALUES(`module`),
  `path`=VALUES(`path`), `icon`=VALUES(`icon`), `sort`=VALUES(`sort`), `status`=VALUES(`status`), `updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code='super_admin' AND p.code IN ('ai:app:view','ai:app:list','ai:app:add','ai:app:edit','ai:app:delete');

-- ========== 三、菜单 ==========
-- AI智能平台（顶级，已存在则跳过）
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT 0, 'AI智能平台', '', 'el-icon-cpu', 'ai:platform:view', 60, 1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:platform:view' AND deleted_at IS NULL);

-- 应用中心（目录）
SET @ai_platform_id = (SELECT id FROM menus WHERE permission='ai:platform:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_platform_id, '应用中心', '', 'el-icon-apps', 'ai:app:view', 25, 1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:app:view' AND deleted_at IS NULL);

-- 应用列表（子菜单）
SET @ai_app_id = (SELECT id FROM menus WHERE permission='ai:app:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_app_id, '应用列表', '/ai/app/list', 'el-icon-apps', 'ai:app:list', 10, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:app:list' AND deleted_at IS NULL);

-- 创建应用（预留子菜单）
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_app_id, '创建应用', '/ai/app/create', 'el-icon-plus', 'ai:app:add', 20, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:app:add' AND deleted_at IS NULL AND parent_id=@ai_app_id);
