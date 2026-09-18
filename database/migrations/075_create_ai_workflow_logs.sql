-- =====================================================
-- 075_create_ai_workflow_logs.sql
-- AI 智能平台：工作流运行日志（完整版）
--   1. 权限（ai:workflow:logs 系列）
--   2. 更新「运行日志」菜单权限与图标
--   3. 系统参数（日志保留/自动清理/导出上限）
-- 幂等写法，可重复执行
-- =====================================================

-- ========== 一、权限 ==========
INSERT INTO `permissions` (`name`, `code`, `type`, `parent_id`, `module`, `path`, `icon`, `api_url`, `sort`, `status`, `platform`, `description`)
VALUES
  ('运行日志', 'ai:workflow:logs', 1, 0, 'ai', '/ai/workflow/logs', 'el-icon-document-copy', NULL, 0, 1, 1, '工作流运行日志菜单/查看'),
  ('运行日志导出', 'ai:workflow:logs:export', 2, 0, 'ai', '/ai/workflow/logs', NULL, NULL, 1, 1, 1, '导出运行日志'),
  ('运行日志删除', 'ai:workflow:logs:delete', 2, 0, 'ai', '/ai/workflow/logs', NULL, NULL, 2, 1, 1, '删除运行日志')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`), `type`=VALUES(`type`), `module`=VALUES(`module`),
  `path`=VALUES(`path`), `icon`=VALUES(`icon`), `sort`=VALUES(`sort`), `status`=VALUES(`status`), `updated_at`=NOW();

-- super_admin 授权
INSERT IGNORE INTO `role_permissions` (`role_id`, `permission_id`)
SELECT r.id, p.id FROM `roles` r CROSS JOIN `permissions` p
WHERE r.code='super_admin' AND p.code IN ('ai:workflow:logs','ai:workflow:logs:export','ai:workflow:logs:delete');

-- ========== 二、更新「运行日志」菜单权限与图标（原为 ai:workflow:list） ==========
UPDATE `menus` SET `permission`='ai:workflow:logs', `icon`='el-icon-document-copy'
WHERE `name`='运行日志' AND `permission`='ai:workflow:list' AND `deleted_at` IS NULL;

-- 若运行日志菜单尚未创建（兜底创建）
SET @ai_workflow_id = (SELECT id FROM menus WHERE permission='ai:workflow:view' AND deleted_at IS NULL LIMIT 1);
INSERT INTO `menus` (`parent_id`, `name`, `path`, `icon`, `permission`, `sort`, `status`, `type`, `is_system`)
SELECT @ai_workflow_id, '运行日志', '/ai/workflow/logs', 'el-icon-document-copy', 'ai:workflow:logs', 30, 1, 2, 0
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE permission='ai:workflow:logs' AND deleted_at IS NULL);

-- ========== 三、系统参数 ==========
INSERT INTO `system_params`
  (`param_key`, `param_value`, `name`, `param_group`, `param_type`, `description`, `sort`, `is_sensitive`, `status`)
VALUES
  ('ai_workflow_log_retention_days', '90',   '运行日志保留天数',       'ai', 'number',  '超过此天数的日志将被自动清理', 10, 0, 1),
  ('ai_workflow_log_auto_clean_enabled', 'true', '启用自动清理日志',   'ai', 'boolean', '是否启用定时自动清理日志',      11, 0, 1),
  ('ai_workflow_log_max_export_rows', '10000', '单次导出最大条数',     'ai', 'number',  '日志导出单次最大条数',          12, 0, 1)
ON DUPLICATE KEY UPDATE
  `param_value`=VALUES(`param_value`), `name`=VALUES(`name`), `param_group`=VALUES(`param_group`),
  `param_type`=VALUES(`param_type`), `description`=VALUES(`description`), `sort`=VALUES(`sort`),
  `status`=VALUES(`status`), `updated_at`=NOW();
