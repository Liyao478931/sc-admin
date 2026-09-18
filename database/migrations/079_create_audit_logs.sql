-- =====================================================
-- 079_create_audit_logs.sql
-- AI 智能平台：运营中心（操作审计）
--   1. 审计日志表 system_audit_logs
--   2. 权限（ai:operation:audit 系列）
--   3. 菜单（运营中心 → 操作审计）
--   4. 数据字典（audit_module/audit_action/audit_result）
--   5. 系统参数（保留/清理/导出/敏感字段）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、审计日志表 ==========
CREATE TABLE IF NOT EXISTS `system_audit_logs` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `log_id` varchar(32) NOT NULL DEFAULT '' COMMENT '日志唯一标识(UUID)',
  `user_id` int(11) DEFAULT NULL COMMENT '操作人ID',
  `user_name` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人姓名（冗余）',
  `user_ip` varchar(50) NOT NULL DEFAULT '' COMMENT '操作人IP',
  `user_agent` varchar(500) NOT NULL DEFAULT '' COMMENT 'User-Agent',
  `module` varchar(30) NOT NULL DEFAULT 'other' COMMENT '操作模块：system/chat/agent/knowledge/tool/workflow/app/apikey/user/role/permission/menu/device/safety/hr/warehouse/other',
  `action` varchar(20) NOT NULL DEFAULT 'other' COMMENT '操作类型：create/update/delete/query/login/logout/export/import/approve/other',
  `resource_type` varchar(50) NOT NULL DEFAULT '' COMMENT '资源类型',
  `resource_id` varchar(50) NOT NULL DEFAULT '' COMMENT '资源ID',
  `resource_name` varchar(255) NOT NULL DEFAULT '' COMMENT '资源名称',
  `description` varchar(500) NOT NULL DEFAULT '' COMMENT '操作描述',
  `request_method` varchar(10) NOT NULL DEFAULT '' COMMENT '请求方法',
  `request_path` varchar(255) NOT NULL DEFAULT '' COMMENT '请求路径',
  `request_params` json DEFAULT NULL COMMENT '请求参数（敏感字段脱敏）',
  `old_data` json DEFAULT NULL COMMENT '变更前数据',
  `new_data` json DEFAULT NULL COMMENT '变更后数据',
  `result` varchar(20) NOT NULL DEFAULT 'success' COMMENT '操作结果：success/error',
  `error_message` text COMMENT '错误信息',
  `duration` int(11) DEFAULT NULL COMMENT '耗时（毫秒）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_log_id` (`log_id`),
  KEY `idx_user_create` (`user_id`, `create_time`),
  KEY `idx_module_create` (`module`, `create_time`),
  KEY `idx_action_create` (`action`, `create_time`),
  KEY `idx_result_create` (`result`, `create_time`),
  KEY `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统操作审计日志表';

-- ========== 二、权限 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`)
VALUES
  ('操作审计', 'ai:operation:audit', 1, 0, 'ai', '/ai/operation/audit', 'el-icon-document-checked', NULL, 0, 1, 1, 'AI操作审计菜单/查看'),
  ('审计日志导出', 'ai:operation:audit:export', 2, 0, 'ai', '/ai/operation/audit', NULL, NULL, 1, 1, 1, '导出审计日志'),
  ('审计日志删除', 'ai:operation:audit:delete', 2, 0, 'ai', '/ai/operation/audit', NULL, NULL, 2, 1, 1, '删除审计日志')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `type`=VALUES(`type`), `module`=VALUES(`module`),
  `path`=VALUES(`path`), `icon`=VALUES(`icon`), `sort`=VALUES(`sort`), `status`=VALUES(`status`), `updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code='super_admin' AND p.code IN ('ai:operation:audit','ai:operation:audit:export','ai:operation:audit:delete');

-- ========== 三、菜单（运营中心 → 操作审计） ==========
SET @ai_operation_id = (SELECT id FROM menus WHERE permission='ai:operation:view' AND type=1 AND deleted_at IS NULL LIMIT 1);
-- 复用 078 预留的操作审计菜单（permission ai:operation:view → ai:operation:audit 并启用）
UPDATE `menus` SET `status`=1, `icon`='el-icon-document-checked', `permission`='ai:operation:audit'
WHERE `name`='操作审计' AND `permission`='ai:operation:view' AND `deleted_at` IS NULL;
-- 兜底：若不存在则新建
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_operation_id, '操作审计', '/ai/operation/audit', 'el-icon-document-checked', 'ai:operation:audit', 30, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:operation:audit' AND deleted_at IS NULL);

-- ========== 四、数据字典 ==========
INSERT INTO `dictionary_types` (`name`, `code`, `description`, `sort`, `status`)
VALUES ('操作模块', 'audit_module', '审计日志操作模块', 1, 1),
       ('操作类型', 'audit_action', '审计日志操作类型', 2, 1),
       ('操作结果', 'audit_result', '审计日志操作结果', 3, 1)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `description`=VALUES(`description`), `status`=VALUES(`status`);

SET @dt_module = (SELECT id FROM dictionary_types WHERE code='audit_module' AND deleted_at IS NULL);
INSERT INTO `dictionary_entries` (`type_id`, `label`, `value`, `sort`, `style`, `status`) VALUES
(@dt_module, '系统', 'system', 1, 'primary', 1), (@dt_module, '对话', 'chat', 2, 'primary', 1),
(@dt_module, '智能体', 'agent', 3, 'primary', 1), (@dt_module, '知识库', 'knowledge', 4, 'primary', 1),
(@dt_module, '工具', 'tool', 5, 'primary', 1), (@dt_module, '工作流', 'workflow', 6, 'primary', 1),
(@dt_module, '应用', 'app', 7, 'primary', 1), (@dt_module, 'API密钥', 'apikey', 8, 'primary', 1),
(@dt_module, '用户', 'user', 9, 'primary', 1), (@dt_module, '角色', 'role', 10, 'primary', 1),
(@dt_module, '权限', 'permission', 11, 'primary', 1), (@dt_module, '菜单', 'menu', 12, 'primary', 1),
(@dt_module, '设备', 'device', 13, 'primary', 1), (@dt_module, '安全', 'safety', 14, 'primary', 1),
(@dt_module, '人事', 'hr', 15, 'primary', 1), (@dt_module, '仓储', 'warehouse', 16, 'primary', 1),
(@dt_module, '其他', 'other', 17, 'info', 1)
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`), `sort`=VALUES(`sort`), `style`=VALUES(`style`), `status`=VALUES(`status`);

SET @dt_action = (SELECT id FROM dictionary_types WHERE code='audit_action' AND deleted_at IS NULL);
INSERT INTO `dictionary_entries` (`type_id`, `label`, `value`, `sort`, `style`, `status`) VALUES
(@dt_action, '新增', 'create', 1, 'success', 1), (@dt_action, '修改', 'update', 2, 'warning', 1),
(@dt_action, '删除', 'delete', 3, 'danger', 1), (@dt_action, '查询', 'query', 4, 'primary', 1),
(@dt_action, '登录', 'login', 5, 'primary', 1), (@dt_action, '登出', 'logout', 6, 'info', 1),
(@dt_action, '导出', 'export', 7, 'warning', 1), (@dt_action, '导入', 'import', 8, 'warning', 1),
(@dt_action, '审批', 'approve', 9, 'primary', 1), (@dt_action, '其他', 'other', 10, 'info', 1)
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`), `sort`=VALUES(`sort`), `style`=VALUES(`style`), `status`=VALUES(`status`);

SET @dt_result = (SELECT id FROM dictionary_types WHERE code='audit_result' AND deleted_at IS NULL);
INSERT INTO `dictionary_entries` (`type_id`, `label`, `value`, `sort`, `style`, `status`) VALUES
(@dt_result, '成功', 'success', 1, 'success', 1), (@dt_result, '失败', 'error', 2, 'danger', 1)
ON DUPLICATE KEY UPDATE `label`=VALUES(`label`), `sort`=VALUES(`sort`), `style`=VALUES(`style`), `status`=VALUES(`status`);

-- ========== 五、系统参数 ==========
INSERT INTO `system_params`
  (`param_key`, `param_value`, `name`, `param_group`, `param_type`, `description`, `sort`, `is_sensitive`, `status`)
VALUES
  ('audit_log_retention_days', '180',  '审计日志保留天数',       'system', 'number',  '超过此天数的日志将被自动清理', 1, 0, 1),
  ('audit_log_auto_clean_enabled', 'true', '启用自动清理审计日志', 'system', 'boolean', '是否启用定时自动清理审计日志', 2, 0, 1),
  ('audit_log_max_export_rows', '10000', '单次导出最大条数',     'system', 'number',  '审计日志导出单次最大条数',     3, 0, 1),
  ('audit_log_sensitive_fields', 'password,password_confirm,old_password,new_password,api_key,app_secret,secret,authorization,bearer,token', '敏感字段列表', 'system', 'string', '请求参数中的敏感字段将自动脱敏', 4, 0, 1)
ON DUPLICATE KEY UPDATE
  `param_value`=VALUES(`param_value`), `name`=VALUES(`name`), `param_group`=VALUES(`param_group`),
  `param_type`=VALUES(`param_type`), `description`=VALUES(`description`), `sort`=VALUES(`sort`),
  `status`=VALUES(`status`), `updated_at`=NOW();
