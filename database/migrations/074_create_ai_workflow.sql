-- =====================================================
-- 074_create_ai_workflow.sql
-- AI 智能平台：工作流编排（工作流列表）
--   1. 工作流表 ai_workflows
--   2. 工作流运行日志表 ai_workflow_logs
--   3. 权限（ai:workflow 系列）
--   4. 菜单（AI智能平台 → 工作流编排 → 工作流列表）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、工作流表 ==========
CREATE TABLE IF NOT EXISTS `ai_workflows` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `workflow_id` varchar(32) NOT NULL DEFAULT '' COMMENT '工作流唯一标识(UUID)',
  `workflow_name` varchar(100) NOT NULL DEFAULT '' COMMENT '工作流名称',
  `description` varchar(255) NOT NULL DEFAULT '' COMMENT '工作流描述',
  `trigger_type` varchar(20) NOT NULL DEFAULT 'manual' COMMENT '触发方式：manual/schedule/webhook/event',
  `trigger_config` json DEFAULT NULL COMMENT '触发配置（定时cron/Webhook配置）',
  `config` json NOT NULL COMMENT '工作流配置（节点配置、连接关系）',
  `node_count` int(11) NOT NULL DEFAULT 0 COMMENT '节点数量',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `last_run_time` datetime DEFAULT NULL COMMENT '最近运行时间',
  `last_run_status` varchar(20) NOT NULL DEFAULT 'idle' COMMENT '最近运行状态：idle/running/success/failed',
  `run_count` int(11) NOT NULL DEFAULT 0 COMMENT '运行次数',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_workflow_id` (`workflow_id`),
  KEY `idx_creator_create` (`created_by`, `create_time`),
  KEY `idx_status` (`status`),
  KEY `idx_trigger_type` (`trigger_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI工作流表';

-- ========== 二、工作流运行日志表 ==========
CREATE TABLE IF NOT EXISTS `ai_workflow_logs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `log_id` varchar(32) NOT NULL DEFAULT '' COMMENT '日志唯一标识(UUID)',
  `workflow_id` varchar(32) NOT NULL DEFAULT '' COMMENT '工作流ID',
  `workflow_name` varchar(100) NOT NULL DEFAULT '' COMMENT '工作流名称（冗余）',
  `trigger_source` varchar(50) NOT NULL DEFAULT '' COMMENT '触发来源：manual/schedule/webhook/event',
  `trigger_user` varchar(50) NOT NULL DEFAULT '' COMMENT '触发人',
  `start_time` datetime DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `duration` int(11) DEFAULT NULL COMMENT '执行耗时（毫秒）',
  `status` varchar(20) NOT NULL DEFAULT 'running' COMMENT '状态：running/success/failed',
  `node_executions` json DEFAULT NULL COMMENT '节点执行记录',
  `error_message` text COMMENT '错误信息',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_log_id` (`log_id`),
  KEY `idx_workflow_create` (`workflow_id`, `create_time`),
  KEY `idx_status_create` (`status`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI工作流运行日志表';

-- ========== 三、权限 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`)
VALUES
  ('工作流编排', 'ai:workflow:view', 1, 0, 'ai', '/ai/workflow/list', 'el-icon-s-operation', NULL, 0, 1, 1, 'AI工作流编排目录'),
  ('工作流列表', 'ai:workflow:list', 1, 0, 'ai', '/ai/workflow/list', 'el-icon-s-operation', NULL, 0, 1, 1, 'AI工作流列表菜单'),
  ('创建工作流', 'ai:workflow:add', 2, 0, 'ai', '/ai/workflow/create', NULL, NULL, 1, 1, 1, '创建/复制工作流'),
  ('编辑工作流', 'ai:workflow:edit', 2, 0, 'ai', '/ai/workflow/list', NULL, NULL, 2, 1, 1, '编辑/启停工作流'),
  ('删除工作流', 'ai:workflow:delete', 2, 0, 'ai', '/ai/workflow/list', NULL, NULL, 3, 1, 1, '删除工作流'),
  ('触发工作流', 'ai:workflow:trigger', 2, 0, 'ai', '/ai/workflow/list', NULL, NULL, 4, 1, 1, '手动触发工作流')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `type`=VALUES(`type`), `module`=VALUES(`module`),
  `path`=VALUES(`path`), `icon`=VALUES(`icon`), `sort`=VALUES(`sort`), `status`=VALUES(`status`), `updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code='super_admin' AND p.code IN ('ai:workflow:view','ai:workflow:list','ai:workflow:add','ai:workflow:edit','ai:workflow:delete','ai:workflow:trigger');

-- ========== 四、菜单 ==========
-- AI智能平台（顶级，已存在则跳过）
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT 0, 'AI智能平台', '', 'el-icon-cpu', 'ai:platform:view', 60, 1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:platform:view' AND deleted_at IS NULL);

-- 工作流编排（目录）
SET @ai_platform_id = (SELECT id FROM menus WHERE permission='ai:platform:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_platform_id, '工作流编排', '', 'el-icon-s-operation', 'ai:workflow:view', 30, 1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:workflow:view' AND deleted_at IS NULL);

-- 工作流列表（子菜单）
SET @ai_workflow_id = (SELECT id FROM menus WHERE permission='ai:workflow:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_workflow_id, '工作流列表', '/ai/workflow/list', 'el-icon-s-operation', 'ai:workflow:list', 10, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:workflow:list' AND deleted_at IS NULL);

-- 创建工作流（预留子菜单）
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_workflow_id, '创建工作流', '/ai/workflow/create', 'el-icon-plus', 'ai:workflow:add', 20, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:workflow:add' AND deleted_at IS NULL);

-- 运行日志（预留子菜单）
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_workflow_id, '运行日志', '/ai/workflow/logs', 'el-icon-document', 'ai:workflow:list', 30, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:workflow:list' AND deleted_at IS NULL AND parent_id=@ai_workflow_id AND name='运行日志');
