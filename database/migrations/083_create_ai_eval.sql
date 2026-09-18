-- =====================================================
-- 083_create_ai_eval.sql
-- AI 智能平台：智能体评测
--   1. 两张核心表：ai_eval_cases（测试用例）/ ai_eval_tasks（评测任务）
--   2. 权限（ai:agent:evaluate 系列）
--   3. 菜单（智能体中心 → 智能体评测，hidden 通过前端路由控制）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、两张核心表 ==========
CREATE TABLE IF NOT EXISTS `ai_eval_cases` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `case_id` varchar(32) NOT NULL DEFAULT '' COMMENT '用例唯一标识(UUID)',
  `case_name` varchar(100) NOT NULL DEFAULT '' COMMENT '用例名称',
  `input` text NOT NULL COMMENT '输入内容',
  `expected_output` text COMMENT '期望输出',
  `expected_tools` json DEFAULT NULL COMMENT '期望调用的工具ID列表(JSON数组)',
  `tags` json DEFAULT NULL COMMENT '标签列表(JSON数组)',
  `status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '状态：1启用 0停用',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_case_id` (`case_id`),
  KEY `idx_creator_create` (`created_by`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI评测测试用例表';

CREATE TABLE IF NOT EXISTS `ai_eval_tasks` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `task_id` varchar(32) NOT NULL DEFAULT '' COMMENT '任务唯一标识(UUID)',
  `agent_id` varchar(32) NOT NULL DEFAULT '' COMMENT '智能体ID（关联 ai_agents）',
  `agent_name` varchar(100) NOT NULL DEFAULT '' COMMENT '智能体名称（冗余）',
  `task_name` varchar(100) DEFAULT NULL COMMENT '任务名称',
  `case_ids` json NOT NULL COMMENT '测试用例ID列表(JSON数组)',
  `total_count` int(11) NOT NULL DEFAULT 0 COMMENT '总用例数',
  `passed_count` int(11) NOT NULL DEFAULT 0 COMMENT '通过数',
  `failed_count` int(11) NOT NULL DEFAULT 0 COMMENT '失败数',
  `pass_rate` decimal(5,2) NOT NULL DEFAULT 0 COMMENT '通过率(%)',
  `avg_score` decimal(5,2) NOT NULL DEFAULT 0 COMMENT '平均匹配度评分',
  `tool_accuracy` decimal(5,2) NOT NULL DEFAULT 0 COMMENT '工具调用准确率(%)',
  `knowledge_recall` decimal(5,2) NOT NULL DEFAULT 0 COMMENT '知识库召回率(%)',
  `avg_response_time` int(11) NOT NULL DEFAULT 0 COMMENT '平均响应时间(ms)',
  `total_tokens` int(11) NOT NULL DEFAULT 0 COMMENT 'Token消耗总量',
  `status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '状态：pending/running/completed/failed',
  `result` json DEFAULT NULL COMMENT '评测结果（每个用例的详细结果）',
  `report_path` varchar(500) DEFAULT NULL COMMENT '报告文件路径',
  `created_by` int(11) NOT NULL DEFAULT 0 COMMENT '创建人ID',
  `created_by_name` varchar(50) NOT NULL DEFAULT '' COMMENT '创建人姓名（冗余）',
  `start_time` datetime DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_id` (`task_id`),
  KEY `idx_agent_id` (`agent_id`),
  KEY `idx_creator_create` (`created_by`, `create_time`),
  KEY `idx_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI评测任务表';

-- ========== 二、权限 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('智能体评测','ai:agent:evaluate',1,0,'ai','/ai/agent/evaluate','el-icon-s-marketing',NULL,5,1,1,'智能体评测查看',NOW(),NOW()),
('智能体评测编辑','ai:agent:evaluate:edit',2,0,'ai',NULL,NULL,NULL,6,1,1,'增删改用例/执行评测',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('ai:agent:evaluate','ai:agent:evaluate:edit');

-- ========== 三、菜单（智能体中心 → 智能体评测，hidden 由前端路由控制） ==========
SET @ai_agent_id = (SELECT id FROM menus WHERE permission='ai:agent:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @ai_agent_id, '智能体评测', '/ai/agent/evaluate', 'el-icon-s-marketing', 'ai:agent:evaluate', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:agent:evaluate' AND deleted_at IS NULL);
