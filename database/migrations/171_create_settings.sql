-- 171_create_settings.sql
-- 统一审批「审批流程配置」：approval_flow 增加 module_name + 预置流程升级（模式/节点）+ 权限 + 菜单
-- 幂等写法，可重复执行
-- 回滚 down：
--   DELETE FROM menus WHERE path='/approval/settings';
--   DELETE FROM role_permissions WHERE permission_id IN (SELECT id FROM permissions WHERE code='approval:settings:manage');
--   DELETE FROM permissions WHERE code='approval:settings:manage';
--   ALTER TABLE approval_flow DROP COLUMN module_name;
--   （预置流程的模式/节点可按需恢复）

-- ========== 一、approval_flow 增加 module_name 列（幂等） ==========
SET @c := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='approval_flow' AND COLUMN_NAME='module_name');
SET @sql := IF(@c = 0, 'ALTER TABLE `approval_flow` ADD COLUMN `module_name` varchar(50) NOT NULL DEFAULT '''' COMMENT ''所属模块名称'' AFTER `biz_name`', 'SELECT 1');
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ========== 二、预置流程升级（模式 + 节点结构 + 模块） ==========
UPDATE `approval_flow` SET `module_name`='采购管理', `approval_mode`=4, `node_config`='[{"node_name":"部门负责人","approver_type":"role","approver_value":"department_head","approver_name":"部门负责人","timeout_hours":48,"timeout_action":"remind"},{"node_name":"采购经理","approver_type":"role","approver_value":"purchase_manager","approver_name":"采购经理","timeout_hours":24,"timeout_action":"remind"},{"node_name":"财务","approver_type":"role","approver_value":"finance","approver_name":"财务","timeout_hours":24,"timeout_action":"remind"}]', `updated_at`=NOW() WHERE `biz_type`='purchase_request' AND `deleted_at` IS NULL;

UPDATE `approval_flow` SET `module_name`='生产管理', `approval_mode`=1, `node_config`='[{"node_name":"车间主任","approver_type":"role","approver_value":"workshop_manager","approver_name":"车间主任","timeout_hours":24,"timeout_action":"remind"}]', `updated_at`=NOW() WHERE `biz_type`='report' AND `deleted_at` IS NULL;

UPDATE `approval_flow` SET `module_name`='人事管理', `approval_mode`=4, `node_config`='[{"node_name":"部门负责人","approver_type":"role","approver_value":"department_head","approver_name":"部门负责人","timeout_hours":48,"timeout_action":"remind"},{"node_name":"人事","approver_type":"role","approver_value":"hr","approver_name":"人事","timeout_hours":24,"timeout_action":"remind"}]', `updated_at`=NOW() WHERE `biz_type`='leave' AND `deleted_at` IS NULL;

UPDATE `approval_flow` SET `module_name`='安全管理', `approval_mode`=1, `node_config`='[{"node_name":"安全主管","approver_type":"role","approver_value":"safety_manager","approver_name":"安全主管","timeout_hours":24,"timeout_action":"remind"}]', `updated_at`=NOW() WHERE `biz_type`='hazard' AND `deleted_at` IS NULL;

UPDATE `approval_flow` SET `module_name`='采购管理', `approval_mode`=4, `node_config`='[{"node_name":"采购经理","approver_type":"role","approver_value":"purchase_manager","approver_name":"采购经理","timeout_hours":24,"timeout_action":"remind"},{"node_name":"财务","approver_type":"role","approver_value":"finance","approver_name":"财务","timeout_hours":24,"timeout_action":"remind"}]', `updated_at`=NOW() WHERE `biz_type`='purchase_order' AND `deleted_at` IS NULL;

UPDATE `approval_flow` SET `module_name`='经营管理', `approval_mode`=2, `node_config`='[{"node_name":"法务","approver_type":"role","approver_value":"legal","approver_name":"法务","timeout_hours":48,"timeout_action":"remind"},{"node_name":"财务","approver_type":"role","approver_value":"finance","approver_name":"财务","timeout_hours":48,"timeout_action":"remind"},{"node_name":"总经理","approver_type":"role","approver_value":"general_manager","approver_name":"总经理","timeout_hours":48,"timeout_action":"remind"}]', `updated_at`=NOW() WHERE `biz_type`='contract' AND `deleted_at` IS NULL;

-- ========== 三、权限（approval:settings:manage） ==========
INSERT INTO `permissions` (`name`,`code`,`type`,`parent_id`,`module`,`path`,`icon`,`api_url`,`sort`,`status`,`platform`,`description`,`created_at`,`updated_at`) VALUES
('审批流程配置','approval:settings:manage',2,0,'approval','/approval/settings','el-icon-set-up',NULL,308,1,1,'管理审批流程配置（查看/新增/编辑/启用停用）',NOW(),NOW())
ON DUPLICATE KEY UPDATE
`name`=VALUES(`name`),`type`=VALUES(`type`),`module`=VALUES(`module`),
`path`=VALUES(`path`),`icon`=VALUES(`icon`),`sort`=VALUES(`sort`),
`status`=VALUES(`status`),`updated_at`=NOW();

INSERT IGNORE INTO `role_permissions` (`role_id`,`permission_id`)
SELECT r.`id`, p.`id` FROM `roles` r CROSS JOIN `permissions` p
WHERE r.`code` IN ('super_admin','admin') AND p.`code`='approval:settings:manage';

-- ========== 四、菜单：统一审批 -> 审批流程配置（叶子，path 幂等） ==========
INSERT INTO `menus` (`parent_id`,`name`,`path`,`icon`,`permission`,`sort`,`status`,`type`,`is_system`,`created_at`,`updated_at`)
SELECT (SELECT id FROM menus WHERE permission='approval:view' AND deleted_at IS NULL LIMIT 1), '审批流程配置', '/approval/settings', 'el-icon-set-up', 'approval:settings:manage', 40, 1, 2, 0, NOW(), NOW()
WHERE NOT EXISTS (SELECT 1 FROM menus WHERE path='/approval/settings' AND deleted_at IS NULL);
