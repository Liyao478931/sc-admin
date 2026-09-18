-- =====================================================
-- 072_create_ai_agents.sql
-- AI 智能平台：智能体列表功能
--   1. 智能体表 ai_agents
--   2. 预置智能体数据（通用/设备/安全/人事 4 个系统智能体）
--   3. 权限（ai:agent 系列）
--   4. 菜单（AI智能平台 → 智能体中心 → 智能体列表）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、智能体表 ==========
CREATE TABLE IF NOT EXISTS `ai_agents` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `agent_id` varchar(32) NOT NULL DEFAULT '' COMMENT '智能体唯一标识',
  `agent_name` varchar(100) NOT NULL DEFAULT '' COMMENT '智能体名称',
  `agent_icon` varchar(255) DEFAULT NULL COMMENT '头像（图标类名或图片URL）',
  `description` varchar(255) DEFAULT NULL COMMENT '描述',
  `system_prompt` text COMMENT '系统提示词（人设）',
  `model_id` int(11) NOT NULL DEFAULT 0 COMMENT '关联模型ID（ai_models.id）',
  `knowledge_base_ids` json DEFAULT NULL COMMENT '绑定的知识库ID列表(JSON数组)',
  `tool_ids` json DEFAULT NULL COMMENT '绑定的工具ID列表(JSON数组)',
  `is_system` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否系统预置：1是 0否',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `sort` int(11) NOT NULL DEFAULT 0 COMMENT '排序',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_agent_id` (`agent_id`),
  KEY `idx_created_create` (`created_by`, `create_time`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI智能体表';

-- ========== 二、预置智能体数据 ==========
-- model_id 取默认模型；tool_ids 按工具名动态解析为 JSON 数组（幂等，依赖工具种子已执行）
INSERT INTO `ai_agents`
  (`agent_id`, `agent_name`, `agent_icon`, `description`, `system_prompt`, `model_id`,
   `knowledge_base_ids`, `tool_ids`, `is_system`, `status`, `sort`, `created_by`, `created_by_name`)
VALUES
  ('sys_agent_general', '通用助手', 'el-icon-s-help',
   '通用的AI助手，可以回答各类问题，调用各类工具',
   '你是一个通用的AI助手，可以帮助用户回答各种问题，调用系统工具获取信息。',
   (SELECT id FROM ai_models WHERE is_default=1 AND status=1 LIMIT 1),
   NULL,
   (SELECT CONCAT('[', GROUP_CONCAT(id ORDER BY sort), ']') FROM ai_tools WHERE status=1),
   1, 1, 1, 0, '系统'),

  ('sys_agent_device', '设备管理助手', 'el-icon-s-tools',
   '专注于设备管理的AI助手，可查询设备信息、维修记录、保养计划等',
   '你是一个专业的设备管理助手，可以帮助用户查询设备信息、维修工单、保养计划等设备相关数据。请用专业、准确的语言回答问题。',
   (SELECT id FROM ai_models WHERE is_default=1 AND status=1 LIMIT 1),
   NULL,
   (SELECT CONCAT('[', GROUP_CONCAT(id ORDER BY sort), ']') FROM ai_tools
     WHERE tool_name IN ('query_device','list_devices','query_device_status','query_repair_orders','create_repair_order','query_maintenance_plans')),
   1, 1, 2, 0, '系统'),

  ('sys_agent_safety', '安全管理助手', 'el-icon-warning',
   '专注于安全管理的AI助手，可查询隐患、检查任务、培训记录等',
   '你是一个专业的安全管理助手，可以帮助用户查询隐患记录、安全检查任务、安全培训记录、事故记录等安全管理数据。请用专业、准确的语言回答问题。',
   (SELECT id FROM ai_models WHERE is_default=1 AND status=1 LIMIT 1),
   NULL,
   (SELECT CONCAT('[', GROUP_CONCAT(id ORDER BY sort), ']') FROM ai_tools
     WHERE tool_name IN ('list_hazards','query_hazard_detail','create_hazard','list_inspection_tasks','list_trainings','list_accidents')),
   1, 1, 3, 0, '系统'),

  ('sys_agent_hr', '人事管理助手', 'el-icon-user',
   '专注于人事管理的AI助手，可查询员工档案、考勤记录、审批记录等',
   '你是一个专业的人事管理助手，可以帮助用户查询员工信息、考勤记录、审批记录等人事管理数据。请用专业、准确的语言回答问题。',
   (SELECT id FROM ai_models WHERE is_default=1 AND status=1 LIMIT 1),
   NULL,
   (SELECT CONCAT('[', GROUP_CONCAT(id ORDER BY sort), ']') FROM ai_tools
     WHERE tool_name IN ('query_employee','list_employees','query_attendance','list_approvals')),
   1, 1, 4, 0, '系统')

ON DUPLICATE KEY UPDATE
  `agent_name`=VALUES(`agent_name`), `agent_icon`=VALUES(`agent_icon`), `description`=VALUES(`description`),
  `system_prompt`=VALUES(`system_prompt`), `model_id`=VALUES(`model_id`),
  `tool_ids`=VALUES(`tool_ids`), `is_system`=VALUES(`is_system`), `status`=VALUES(`status`),
  `sort`=VALUES(`sort`), `update_time`=NOW();

-- ========== 三、权限 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`)
VALUES
  ('智能体中心', 'ai:agent:view', 1, 0, 'ai', '/ai/agent/list', 'el-icon-user', NULL, 0, 1, 1, 'AI智能体中心目录'),
  ('智能体列表', 'ai:agent:list', 1, 0, 'ai', '/ai/agent/list', 'el-icon-user', NULL, 1, 1, 1, 'AI智能体列表菜单'),
  ('智能体创建', 'ai:agent:add', 2, 0, 'ai', '/ai/agent/list', NULL, NULL, 2, 1, 1, '创建智能体'),
  ('智能体编辑', 'ai:agent:edit', 2, 0, 'ai', '/ai/agent/list', NULL, NULL, 3, 1, 1, '编辑/启停智能体'),
  ('智能体删除', 'ai:agent:delete', 2, 0, 'ai', '/ai/agent/list', NULL, NULL, 4, 1, 1, '删除智能体')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `type`=VALUES(`type`), `module`=VALUES(`module`),
  `path`=VALUES(`path`), `icon`=VALUES(`icon`), `sort`=VALUES(`sort`), `status`=VALUES(`status`), `updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code='super_admin' AND p.code IN ('ai:agent:view','ai:agent:list','ai:agent:add','ai:agent:edit','ai:agent:delete');

-- ========== 四、菜单 ==========
-- 智能体中心（目录，挂 AI智能平台 下，位于对话中心与知识库之间 sort=15）
SET @ai_platform_id = (SELECT id FROM menus WHERE permission='ai:platform:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_platform_id, '智能体中心', '', 'el-icon-user', 'ai:agent:view', 15, 1, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:agent:view' AND deleted_at IS NULL);

-- 智能体列表（子菜单）
SET @ai_agent_id = (SELECT id FROM menus WHERE permission='ai:agent:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_agent_id, '智能体列表', '/ai/agent/list', 'el-icon-user', 'ai:agent:list', 10, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:agent:list' AND deleted_at IS NULL);
