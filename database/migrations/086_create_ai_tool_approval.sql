-- =====================================================
-- 086_create_ai_tool_approval.sql
-- AI 智能平台：工具审批
--   1. 审批表 ai_tool_approvals + 审批规则配置表 ai_approval_config
--   2. ai_tools 补充 approval_status 字段（draft/approval_pending/active，不改动现有 status）
--   3. 数据字典（审批操作类型/审批状态）
--   4. 系统参数（审批开关/审批人/免审批用户/免审批操作/自动审批阈值）
--   5. 权限（ai:tools:approval 系列）
--   6. 菜单（工具中心 → 工具审批）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、两张核心表 ==========
CREATE TABLE IF NOT EXISTS `ai_tool_approvals` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `approval_id` varchar(32) NOT NULL DEFAULT '' COMMENT '审批唯一标识(UUID)',
  `tool_id` int(11) DEFAULT NULL COMMENT '工具ID（关联 ai_tools，删除操作可为空）',
  `tool_name` varchar(100) NOT NULL DEFAULT '' COMMENT '工具名称（冗余）',
  `action_type` varchar(20) NOT NULL DEFAULT '' COMMENT '操作类型：create/update/delete',
  `tool_snapshot` json NOT NULL COMMENT '工具快照（申请时完整配置）',
  `applicant_id` int(11) NOT NULL DEFAULT 0 COMMENT '申请人ID',
  `applicant_name` varchar(50) NOT NULL DEFAULT '' COMMENT '申请人姓名（冗余）',
  `apply_time` datetime NOT NULL COMMENT '申请时间',
  `apply_remark` varchar(500) DEFAULT NULL COMMENT '申请说明',
  `approver_id` int(11) DEFAULT NULL COMMENT '审批人ID',
  `approver_name` varchar(50) DEFAULT NULL COMMENT '审批人姓名',
  `approval_time` datetime DEFAULT NULL COMMENT '审批时间',
  `approval_status` varchar(20) NOT NULL DEFAULT 'pending' COMMENT '审批状态：pending/processing/approved/rejected',
  `approval_comment` varchar(500) DEFAULT NULL COMMENT '审批意见',
  `reject_reason` varchar(500) DEFAULT NULL COMMENT '驳回原因',
  `notified` tinyint(1) NOT NULL DEFAULT 0 COMMENT '是否已通知：1是0否',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `delete_time` datetime DEFAULT NULL COMMENT '软删除时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_approval_id` (`approval_id`),
  KEY `idx_tool_id` (`tool_id`),
  KEY `idx_status_create` (`approval_status`, `create_time`),
  KEY `idx_applicant_create` (`applicant_id`, `create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI工具审批表';

CREATE TABLE IF NOT EXISTS `ai_approval_config` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `config_key` varchar(50) NOT NULL DEFAULT '' COMMENT '配置键',
  `config_value` text COMMENT '配置值',
  `description` varchar(255) DEFAULT NULL COMMENT '描述说明',
  `create_time` datetime DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_config_key` (`config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI审批规则配置表';

-- ========== 二、ai_tools 补充审批状态字段（幂等） ==========
SET @ta_ex := (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'ai_tools' AND column_name = 'approval_status');
SET @ta_sql := IF(@ta_ex = 0, 'ALTER TABLE `ai_tools` ADD COLUMN `approval_status` varchar(20) NOT NULL DEFAULT ''active'' COMMENT ''审批状态：draft/approval_pending/active'' AFTER `status`', 'SELECT 1');
PREPARE ta_stmt FROM @ta_sql; EXECUTE ta_stmt; DEALLOCATE PREPARE ta_stmt;

-- ========== 三、数据字典 ==========

-- 1. tool_approval_action 审批操作类型
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('审批操作类型','tool_approval_action','AI工具审批操作类型',89,1,NOW(),NOW());
SET @dt1 = (SELECT `id` FROM `dictionary_types` WHERE `code`='tool_approval_action' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt1,'新增','create',1,'success',1,NOW(),NOW()),
(@dt1,'修改','update',2,'warning',1,NOW(),NOW()),
(@dt1,'删除','delete',3,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- 2. tool_approval_status 审批状态
INSERT IGNORE INTO `dictionary_types` (`name`,`code`,`description`,`sort`,`status`,`created_at`,`updated_at`)
VALUES ('审批状态','tool_approval_status','AI工具审批状态',90,1,NOW(),NOW());
SET @dt2 = (SELECT `id` FROM `dictionary_types` WHERE `code`='tool_approval_status' LIMIT 1);
INSERT INTO `dictionary_entries` (`type_id`,`label`,`value`,`sort`,`style`,`status`,`created_at`,`updated_at`) VALUES
(@dt2,'待审批','pending',1,'warning',1,NOW(),NOW()),
(@dt2,'审批中','processing',2,'primary',1,NOW(),NOW()),
(@dt2,'已通过','approved',3,'success',1,NOW(),NOW()),
(@dt2,'已驳回','rejected',4,'danger',1,NOW(),NOW())
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`),`sort`=VALUES(`sort`),`style`=VALUES(`style`),`status`=VALUES(`status`),`deleted_at`=NULL,`updated_at`=NOW();

-- ========== 四、系统参数 ==========
INSERT INTO `system_params` (`param_key`,`name`,`param_value`,`param_type`,`param_group`,`description`,`sort`,`status`,`is_sensitive`,`created_at`,`updated_at`) VALUES
('tool_approval_enabled','启用工具审批','true','boolean','ai','是否启用工具审批功能',40,1,0,NOW(),NOW()),
('tool_approval_default_approvers','默认审批人ID列表','[]','json','ai','默认审批人ID列表',41,1,0,NOW(),NOW()),
('tool_approval_exempt_users','免审批用户ID列表','[]','json','ai','免审批用户ID列表',42,1,0,NOW(),NOW()),
('tool_approval_exempt_actions','免审批操作类型列表','["create"]','json','ai','免审批操作类型列表',43,1,0,NOW(),NOW()),
('tool_approval_auto_approve_threshold','自动审批评分阈值','80','number','ai','工具评分达到阈值自动通过审批',44,1,0,NOW(),NOW())
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`),`param_value`=VALUES(`param_value`),`param_type`=VALUES(`param_type`),`param_group`=VALUES(`param_group`),`description`=VALUES(`description`),`sort`=VALUES(`sort`),`updated_at`=NOW();

-- ========== 五、权限 ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('工具审批','ai:tools:approval',1,0,'ai','/ai/tools/approval','el-icon-document-checked',NULL,9,1,1,'工具审批查看',NOW(),NOW()),
('工具审批提交','ai:tools:approval:add',2,0,'ai',NULL,NULL,NULL,10,1,1,'提交审批/取消审批',NOW(),NOW()),
('工具审批处理','ai:tools:approval:process',2,0,'ai',NULL,NULL,NULL,11,1,1,'审批通过/驳回/批量审批',NOW(),NOW()),
('工具审批配置','ai:tools:approval:config',2,0,'ai',NULL,NULL,NULL,12,1,1,'审批规则配置',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code`='super_admin'
  AND p.`code` IN ('ai:tools:approval','ai:tools:approval:add','ai:tools:approval:process','ai:tools:approval:config');

-- ========== 六、菜单（工具中心 → 工具审批） ==========
SET @ai_tools_id = (SELECT id FROM menus WHERE permission='ai:tools:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT @ai_tools_id, '工具审批', '/ai/tools/approval', 'el-icon-document-checked', 'ai:tools:approval', 30, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:tools:approval' AND deleted_at IS NULL);
